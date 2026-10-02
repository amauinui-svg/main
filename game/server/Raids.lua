-- Raids (Kash 1 Oct 2026). You can only attack people in YOUR server, plus 3 AI nations that every server has.
-- The list cannot be refreshed. Winner takes 10% of the defender's cash on hand (the bank is safe), capped at about an
-- hour of the defender's own law income. The same target can be raided again after 1 minute.
-- Soldiers die on both sides by how lopsided the fight was (cheapest first). AI nations raid real players too, and
-- every raid notice offers REVENGE. No "bank your cash" hint: players discover the bank on their own.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local R = require(RS.Shared.Rules)
local M = require(RS.Shared.Military)
local Config = require(RS.Shared.Config)
local RC = Config.Raid

local RA = {}
local PS
local lastHit = {} -- [targetId] = os.time() of the last successful raid on it
RA.AI = {}

function RA.Init(ps) PS = ps; PS.Raids = RA end

local AI_NAMES = { "Republic of Varnia", "Kingdom of Ostrava", "Federation of Kelmar", "Free State of Duvessa", "Empire of Tarsis",
	"Union of Morvane", "Duchy of Belgrast", "Commonwealth of Quellan", "Kingdom of Halvard", "Republic of Zenthia",
	"Free State of Ilyria", "Empire of Cordova", "Union of Norvik", "Duchy of Saltreach", "Republic of Brannock" }

local function now() return os.time() end
local function avgLevel()
	local sum, n = 0, 0
	for _, p in pairs(PS.Profiles) do if p.data.onboarded then sum += p.data.lv; n += 1 end end
	return n > 0 and sum / n or 5
end

-- AI nations: one weaker, one even, one stronger than the server's average player
local SHAPE = { { -3, 0.8 }, { 0, 1.0 }, { 4, 1.25 } }
function RA.MakeAI()
	local rng = Random.new(os.clock() * 1000)
	local names = table.clone(AI_NAMES)
	RA.AI = {}
	for i = 1, RC.AICount do
		local name = table.remove(names, rng:NextInteger(1, #names))
		RA.AI[i] = {
			id = "ai" .. i, name = name, ai = true, shape = SHAPE[i] or SHAPE[2],
			flag = { l = R.FlagLayouts[rng:NextInteger(1, #R.FlagLayouts)], c = { R.FlagColors[rng:NextInteger(1, 12)], R.FlagColors[rng:NextInteger(1, 12)], R.FlagColors[rng:NextInteger(1, 12)] } },
			cash = 0, soldiers = 1, lv = 1,
		}
	end
	RA.TuneAI(true)
end
-- keep AI levels following the server; their treasury grows like a player's
function RA.TuneAI(reset)
	local avg = avgLevel()
	for _, a in ipairs(RA.AI) do
		local lv = math.max(1, math.floor(avg + a.shape[1] + 0.5))
		if reset or lv ~= a.lv then
			a.lv = lv
			if reset then a.cash = R.MinuteValue(lv) * 45 end
		end
		a.cash = math.min(a.cash + R.MinuteValue(a.lv) * 0.5 / 60, R.MinuteValue(a.lv) * 240) -- grows to ~4h of laws
		a.soldiers = math.min(1, a.soldiers + 0.02 / 60) -- army rebuilds after losses (1 = full)
	end
end
local function aiPower(a)
	local base = 5 + 2 * a.lv
	local units = M.UnitCap(a.lv) * 0.7 * a.soldiers
	-- AI armies use the best unit of their era
	local best = M.Units[1]
	for _, u in ipairs(M.Units) do if u.lvl <= a.lv then best = u end end
	local atk = (base + best.atk * units) * a.shape[2]
	local def = (base + best.def * units) * a.shape[2]
	return math.floor(atk), math.floor(def)
end

local function stealCap(lv) return R.MinuteValue(lv) * RC.CapLawMinutes end

-- everyone you can raid: other onboarded players in this server and the AI nations
function RA.Targets(p)
	local list = {}
	local t = now()
	for plr, q in pairs(PS.Profiles) do
		if q ~= p and q.data.onboarded then
			local _, def = PS.Power(q)
			local id = "u" .. plr.UserId
			table.insert(list, {
				id = id, name = q.data.name, flag = q.data.flag, lv = q.data.lv, def = def,
				cash = math.floor(q.data.cash), cooldown = math.max(0, (lastHit[id] or 0) + RC.Cooldown - t),
				shield = math.max(0, (q.data.shield or 0) - t), tag = q.data.alliance,
			})
		end
	end
	for _, a in ipairs(RA.AI) do
		local _, def = aiPower(a)
		table.insert(list, { id = a.id, name = a.name, flag = a.flag, lv = a.lv, def = def, cash = math.floor(a.cash), ai = true,
			cooldown = math.max(0, (lastHit[a.id] or 0) + RC.Cooldown - t), shield = 0 })
	end
	table.sort(list, function(x, y) return x.def < y.def end)
	return list
end

local function margin(atk, def)
	local r = atk / math.max(1, atk + def)
	local m = math.abs(r - 0.5)
	if m > 0.2 then return "sweep" elseif m > 0.07 then return "clear" end
	return "close"
end
RA.Margin = margin

-- kill pct of a units table, cheapest first. losses trait reduces deaths. Returns { [unitIndex] = killed }, total
local function kill(units, pct, lossesBonus)
	pct = pct * (1 - math.clamp(lossesBonus or 0, 0, 0.6))
	local total = M.UnitCount(units)
	local toKill = math.floor(total * pct + 0.5)
	if toKill <= 0 then return {}, 0 end
	local order = {}
	for k in pairs(units) do table.insert(order, tonumber(k)) end
	table.sort(order, function(a, b) return M.Units[a].cost < M.Units[b].cost end)
	local dead, n = {}, 0
	for _, i in ipairs(order) do
		if toKill <= 0 then break end
		local have = units[tostring(i)] or 0
		local k = math.min(have, toKill)
		if k > 0 then
			units[tostring(i)] = have - k
			if units[tostring(i)] <= 0 then units[tostring(i)] = nil end
			dead[M.Units[i].name] = k; n += k; toKill -= k
		end
	end
	return dead, n
end

local function findTarget(id)
	if type(id) ~= "string" then return nil end
	for _, a in ipairs(RA.AI) do if a.id == id then return nil, a end end
	local uid = tonumber(id:match("^u(%d+)$"))
	local plr = uid and Players:GetPlayerByUserId(uid)
	local q = plr and PS.Profiles[plr]
	if q and q.data.onboarded then return q, nil, plr end
	return nil
end

-- attacker p raids target id. guaranteed = Revenge Strike product
function RA.Attack(plr, p, id, guaranteed)
	local d = p.data
	local q, ai, qplr = findTarget(id)
	if not q and not ai then return { ok = false, msg = "That nation is no longer in this server" } end
	if q == p then return { ok = false, msg = "You cannot raid yourself" } end
	local t = now()
	if (lastHit[id] or 0) + RC.Cooldown > t then return { ok = false, msg = "They were just raided. Try again in " .. ((lastHit[id] or 0) + RC.Cooldown - t) .. "s" } end
	if q and (q.data.shield or 0) > t then return { ok = false, msg = "They are under a raid shield" } end
	if not guaranteed then
		if d.sup < RC.Supply then return { ok = false, msg = "Not enough Supply (" .. RC.Supply .. " needed)" } end
		d.sup -= RC.Supply
		PS.TaskProgress(p, "supply", RC.Supply)
	end
	local mods = PS.Mods(p)
	local atk = PS.Power(p, mods)
	local def, defName, defLv, defLosses
	if q then
		local qm = PS.Mods(q)
		local _, dd = PS.Power(q, qm)
		def, defName, defLv, defLosses = dd, q.data.name, q.data.lv, qm.losses
	else
		local _, dd = aiPower(ai)
		def, defName, defLv, defLosses = dd, ai.name, ai.lv, 0
	end
	local chance = M.WinChance(atk, def)
	local win = guaranteed or math.random() < chance
	local m = margin(atk, def)
	if guaranteed and m == "close" then m = "clear" end
	local L = RC.Losses[m]
	local myLoss = win and L[1] or L[2]
	local theirLoss = win and L[2] or L[1]
	local myDead, myN = kill(d.units, myLoss, mods.losses)
	local theirDead, theirN = {}, 0
	if q then theirDead, theirN = kill(q.data.units, theirLoss, defLosses)
	else ai.soldiers = math.max(0.2, ai.soldiers - theirLoss) end
	d.stats.battles += 1
	local res = { ok = true, win = win, chance = chance, margin = m, lost = myDead, lostN = myN, killed = theirN, target = defName }
	if win then
		lastHit[id] = t
		local onHand = q and q.data.cash or ai.cash
		local steal = math.floor(math.min(onHand * RC.StealPct * (1 + (mods.loot or 0)), stealCap(defLv)))
		steal = math.max(0, math.min(steal, onHand))
		if q then q.data.cash -= steal; q.data.stats.lost += steal; q.data.stats.raided += 1 else ai.cash -= steal end
		local got = PS.Earn(p, steal, "raid")
		local xp = math.max(1, math.floor(R.MinuteXp(d.lv) * 0.6 + 0.5))
		PS.AddXp(p, xp)
		d.stats.wins += 1; d.stats.stolen += got
		PS.TaskProgress(p, "raids", 1)
		res.cash = got; res.xp = xp
	end
	-- the defender hears about it, with a REVENGE button
	if q then
		q.data.revenge = { id = "u" .. plr.UserId, name = d.name, t = t }
		PS.Note(q, { kind = "raided", by = d.name, byId = "u" .. plr.UserId, win = win, cash = res.cash or 0, lost = theirN })
		q.dirty = true
	end
	return res
end

-- an AI nation raids a real player (no Supply; same rules)
local function aiRaid()
	local candidates = {}
	local t = now()
	for plr, q in pairs(PS.Profiles) do
		local d = q.data
		if d.onboarded and d.lv >= RC.AIMinTargetLevel and (d.shield or 0) <= t and (lastHit["u" .. plr.UserId] or 0) + RC.Cooldown <= t
			and d.cash > R.MinuteValue(d.lv) * 10 then
			table.insert(candidates, { plr, q })
		end
	end
	if #candidates == 0 or #RA.AI == 0 then return end
	local pick = candidates[math.random(1, #candidates)]
	local plr, q = pick[1], pick[2]
	local ai = RA.AI[math.random(1, #RA.AI)]
	local atk = aiPower(ai)
	local qm = PS.Mods(q)
	local _, def = PS.Power(q, qm)
	local win = math.random() < M.WinChance(atk, def)
	local m = margin(atk, def)
	local L = RC.Losses[m]
	local _, lostN = kill(q.data.units, win and L[2] or L[1], qm.losses)
	ai.soldiers = math.max(0.2, ai.soldiers - (win and L[1] or L[2]))
	local steal = 0
	if win then
		lastHit["u" .. plr.UserId] = t
		steal = math.floor(math.min(q.data.cash * RC.StealPct, stealCap(q.data.lv)))
		q.data.cash -= steal
		q.data.stats.lost += steal; q.data.stats.raided += 1
		ai.cash += steal
	end
	q.data.revenge = { id = ai.id, name = ai.name, t = t }
	PS.Note(q, { kind = "raided", by = ai.name, byId = ai.id, win = win, cash = steal, lost = lostN })
	q.dirty = true
end

function RA.Start()
	RA.MakeAI()
	task.spawn(function()
		local nextRaid = os.clock() + math.random(RC.AIRaidEvery[1], RC.AIRaidEvery[2])
		while true do
			task.wait(5)
			RA.TuneAI(false)
			for _ = 1, 4 do RA.TuneAI(false) end -- 5 s of growth (TuneAI adds one second's worth)
			if os.clock() >= nextRaid then
				nextRaid = os.clock() + math.random(RC.AIRaidEvery[1], RC.AIRaidEvery[2])
				pcall(aiRaid)
			end
		end
	end)
end
return RA
