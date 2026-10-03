-- Raids (Kash 1 Oct 2026). The RAIDS list shows people in YOUR server, plus 3 AI nations that every server has.
-- Kash 2 Oct: anyone in ANY server (or offline) can be attacked from RANKINGS. Those fights use the target's war card
-- (published every 2 min and on leave); the loss is queued in a DataStore and applied by whichever server holds them
-- (instantly over MessagingService, else on their next login). The list cannot be refreshed. Winner takes 10% of the defender's cash on hand (the bank is safe), capped at about an
-- hour of the defender's own law income. The same target can be raided again after 1 minute.
-- Soldiers die on both sides by how lopsided the fight was (cheapest first). AI nations raid real players too, and
-- every raid notice offers REVENGE. No "bank your cash" hint: players discover the bank on their own.
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local RunService = game:GetService("RunService")
local Store = require(script.Parent.Store)
local RS = game:GetService("ReplicatedStorage")
local R = require(RS.Shared.Rules)
local M = require(RS.Shared.Military)
local Config = require(RS.Shared.Config)
local RC = Config.Raid
-- nobody (bots or players) can raid a country before it has the RAIDS tab itself (Kash 2 Oct 23:38)
local function protectedLv() return math.max(RC.AIMinTargetLevel or 1, (Config.NavUnlock and Config.NavUnlock.battle) or 1) end

local O = require(RS.Shared.Officers)
local RA = {}
local findTargetPublic -- set below (findTarget is defined after the spy code)
local remoteUid -- set below (audit H3: was a nil global inside RA.Spy)
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

---------------------------------------------------------------- the fight (Kash 18:47)
-- Three exchanges: attacker, defender, attacker, defender, attacker, (defender). The winner is decided first by the
-- win chance; the hits are then rolled so the fight ends on the third blow: either the attacker's 3rd hit finishes
-- the defender, or the defender's 3rd hit finishes the attacker. Each hit rolls inside a range (shown on screen) and
-- may crit (x1.5).
RA.RollLo, RA.RollHi, RA.Crit, RA.CritMult = 0.75, 1.15, 0.12, 1.5
local function roll(pw)
	local r = RA.RollLo + math.random() * (RA.RollHi - RA.RollLo)
	local crit = math.random() < RA.Crit
	return math.max(1, math.floor(pw * r * (crit and RA.CritMult or 1) + 0.5)), crit, r
end
function RA.Fight(aPow, dPow, attackerWins)
	local A, D = {}, {}
	for k = 1, 3 do
		local v, c, r = roll(aPow); A[k] = { dmg = v, crit = c, r = r }
		v, c, r = roll(dPow); D[k] = { dmg = v, crit = c, r = r }
	end
	local aHp, dHp
	if attackerWins then
		dHp = math.max(1, math.floor((A[1].dmg + A[2].dmg + A[3].dmg) * 0.97))
		dHp = math.max(dHp, A[1].dmg + A[2].dmg + 1)
		aHp = math.floor((D[1].dmg + D[2].dmg) * (1.15 + math.random() * 0.6)) + 1
	else
		aHp = math.max(1, math.floor((D[1].dmg + D[2].dmg + D[3].dmg) * 0.97))
		aHp = math.max(aHp, D[1].dmg + D[2].dmg + 1)
		dHp = math.floor((A[1].dmg + A[2].dmg + A[3].dmg) * (1.15 + math.random() * 0.6)) + 1
	end
	local hits, ha, hd = {}, aHp, dHp
	for k = 1, 3 do
		hd = math.max(0, hd - A[k].dmg)
		table.insert(hits, { who = "a", dmg = A[k].dmg, crit = A[k].crit, r = A[k].r, hp = hd })
		if hd <= 0 then break end
		ha = math.max(0, ha - D[k].dmg)
		table.insert(hits, { who = "d", dmg = D[k].dmg, crit = D[k].crit, r = D[k].r, hp = ha })
		if ha <= 0 then break end
	end
	return {
		hits = hits, aHp = aHp, dHp = dHp,
		aRange = { math.floor(aPow * RA.RollLo), math.ceil(aPow * RA.RollHi) },
		dRange = { math.floor(dPow * RA.RollLo), math.ceil(dPow * RA.RollHi) },
	}
end
-- the weapon a fighter shows: the player's equipped weapon, or fists; AI nations carry their era's weapon
local ERA_WEAPON = { "gear_spear", "gear_sword", "gear_halberd", "gear_musket", "gear_rifle", "gear_rifle", "gear_rifle", "gear_rifle" }
local function weaponOf(d)
	local g = d.cab and d.cab.player and d.cab.player.weapon and d.inv and d.inv.gear[d.cab.player.weapon]
	if g then return { icon = g.icon, name = g.name, rarity = g.rarity } end
	return { icon = "gear_fists", name = "Fists", rarity = "common" }
end

local function stealCap(lv) return R.MinuteValue(lv) * RC.CapLawMinutes end

-- spying (Kash 18:51): stats and cash of other nations are hidden until you spy (1 Supply). The target is told.
RA.SpySupply = 1
RA.SpyMinutes = 15
function RA.Spy(plr, p, id)
	local d = p.data
	local q, ai, qplr = findTargetPublic(id)
	if not q and not ai then
		local uid = remoteUid(id)
		if uid and uid ~= plr.UserId then return RA._remoteSpy(plr, p, id, uid) end
		return { ok = false, msg = "That nation is no longer in this server" }
	end
	if q == p then return { ok = false, msg = "You cannot spy on yourself" } end
	if d.sup < RA.SpySupply then return { ok = false, msg = "Not enough Supply (" .. RA.SpySupply .. " needed)" } end
	d.sup -= RA.SpySupply
	p.spied = p.spied or {}
	p.spied[id] = os.time()
	if q then
		PS.Note(q, { kind = "spied", by = d.name ~= "" and d.name or plr.Name, lv = d.lv })
	end
	return { ok = true, intel = RA.Intel(id) }
end
function RA.Intel(id)
	local q, ai = findTargetPublic(id)
	if q then
		local qm = PS.Mods(q)
		local atk, def = PS.Power(q, qm)
		local units = 0
		for _, n in pairs(q.data.units) do units += n end
		return { cash = math.floor(q.data.cash), atk = atk, def = def, lv = q.data.lv, units = units, shield = math.max(0, (q.data.shield or 0) - os.time()) }
	elseif ai then
		local atk, def = aiPower(ai)
		return { cash = math.floor(ai.cash), atk = atk, def = def, lv = ai.lv, ai = true }
	end
end

-- everyone you can raid: other onboarded players in this server and the AI nations
function RA.Targets(p)
	local list = {}
	local t = now()
	for plr, q in pairs(PS.Profiles) do
		if q ~= p and q.data.onboarded and not q.loading and not q.leaving and q.data.lv >= protectedLv() then
			local _, def = PS.Power(q)
			local id = "u" .. plr.UserId
			table.insert(list, {
				id = id, name = q.data.name, flag = q.data.flag, lv = q.data.lv, def = def,
				cash = math.floor(q.data.cash), cooldown = math.max(0, (lastHit[id] or 0) + RC.Cooldown - t),
				shield = math.max(0, (q.data.shield or 0) - t), tag = q.data.alliance and PS.AllianceTag and PS.AllianceTag(q.data.alliance) or nil,
			})
		end
	end
	for _, a in ipairs(RA.AI) do
		local _, def = aiPower(a)
		table.insert(list, { id = a.id, name = a.name, flag = a.flag, lv = a.lv, def = def, cash = math.floor(a.cash), ai = true,
			cooldown = math.max(0, (lastHit[a.id] or 0) + RC.Cooldown - t), shield = 0 })
	end
	-- the button also shows YOUR own cooldown on that target (Kash 2 Oct: some raided targets showed no timer)
	local mine = p.raidCd or {}
	for _, e in ipairs(list) do
		e.cooldown = math.max(e.cooldown or 0, (mine[e.id] or 0) + RC.Cooldown - t)
	end
	-- hide what you have not spied on (fresh intel lasts RA.SpyMinutes)
	for _, e in ipairs(list) do
		local seen = p.spied and p.spied[e.id]
		if seen and os.time() - seen <= RA.SpyMinutes * 60 then
			e.intel = true; e.spiedAgo = os.time() - seen
		else
			e.sortDef = e.def
			e.def, e.cash = nil, nil
		end
	end
	table.sort(list, function(x, y) return x.lv < y.lv end)
	for _, e in ipairs(list) do e.sortDef = nil end
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
	if q and q.data.onboarded and not q.loading and not q.leaving then return q, nil, plr end
	return nil
end

findTargetPublic = findTarget

---------------------------------------------------------------- cross-server raids (Kash 2 Oct)
local SUFFIX = (RunService:IsStudio() and workspace:GetAttribute("IC_TestProfile")) and "_test" or ""
local CARD_DS, HITS_DS, TOPIC = "IC_WarCard_v1" .. SUFFIX, "IC_WarHits_v1" .. SUFFIX, "IC_Hit" .. SUFFIX
local cardCache = {} -- [uid] = { t = os.clock(), card = card }

-- what other servers need to fight you: published every 2 min and when you leave
function RA.PublishCard(plr, p)
	if not Store.Online or not p.data.onboarded then return end
	local d = p.data
	local qm = PS.Mods(p)
	local atk, def = PS.Power(p, qm)
	local card = { n = d.name, f = d.flag, lv = d.lv, atk = atk, def = def, cash = math.floor(d.cash), sh = d.shield or 0, w = weaponOf(d),
		u = M.UnitCount(d.units), loss = qm.losses or 0, t = now(), ht = d.hitApplied or 0, pf = RA.ProfileOf(p) }
	local ok, err = pcall(function() Store.DS(CARD_DS):SetAsync(tostring(plr.UserId), card) end)
	if ok then cardCache[plr.UserId] = { t = os.clock(), card = card } else warn("[Idle Country] war card publish failed: " .. tostring(err)) end
end
-- public profile (Kash 2 Oct: player profiles like the competitor's). Small: it rides on the war card.
function RA.ProfileOf(p)
	local d = p.data
	local st = d.stats or {}
	local atk, def = PS.Power(p)
	return {
		n = d.name, f = d.flag, lv = d.lv, era = R.PlayerEra(d), title = R.TitleOf(d), ach = R.AchievementsOf(d),
		tag = d.alliance and PS.AllianceTag(d.alliance) or nil, wonder = d.wonder or 0, home = d.home, ideo = d.ideo,
		atk = atk, def = def, inc = math.floor(PS.IncHr(p)),
		st = { laws = st.laws or 0, trips = st.trips or 0, wins = st.wins or 0, battles = st.battles or 0, bosses = st.bosses or 0,
			built = st.built or 0, earned = st.earned or 0, stolen = st.stolen or 0 },
		since = d.created,
	}
end
local function getCard(uid)
	local c = cardCache[uid]
	if c and os.clock() - c.t < 20 then return c.card end
	if not Store.Online then return nil end
	local ok, card = Store.Get(Store.DS(CARD_DS), tostring(uid))
	if ok and type(card) == "table" then cardCache[uid] = { t = os.clock(), card = card }; return card end
	return nil
end
remoteUid = function(id)
	local uid = type(id) == "string" and tonumber(id:match("^u(%d+)$"))
	if not uid or Players:GetPlayerByUserId(uid) then return nil end
	return uid
end
function RA.Profile(uid)
	uid = tonumber(uid)
	if not uid then return nil end
	local plr = Players:GetPlayerByUserId(uid)
	local p = plr and PS.Profiles[plr]
	if p and p.data and p.data.onboarded then local pf = RA.ProfileOf(p); pf.online = true; pf.here = true; return pf end
	local card = getCard(uid)
	if not card then return nil end
	local pf = card.pf or { n = card.n, f = card.f, lv = card.lv, atk = card.atk, def = card.def }
	pf.lastSeen = card.t
	return pf
end
function RA.RemoteOk(id)
	local uid = remoteUid(id)
	return uid ~= nil and getCard(uid) ~= nil
end
local function ping(uid)
	local ok, err = pcall(function() MessagingService:PublishAsync(TOPIC, { u = uid }) end)
	if not ok then warn("[Idle Country] hit ping failed: " .. tostring(err)) end
end

-- The hit record is an ESCROW (audit C1): every raid stays in rec.q until the defender's own server has applied it
-- exactly once (ids remembered in the profile). Nothing is pruned by time or count, so an offline war card can only
-- be robbed down, never refilled. At most RA.MaxUnpaid raids may wait unpaid; spies live in their own short list.
RA.MaxUnpaid = 8
local HttpService = game:GetService("HttpService")
local function queueHit(uid, fn)
	local veto
	local ok = Store.Update(Store.DS(HITS_DS), tostring(uid), function(rec)
		veto = nil
		rec = type(rec) == "table" and rec or {}
		rec.q = rec.q or {}; rec.sp = rec.sp or {}
		rec.recent = nil -- old format
		local entry
		entry, veto = fn(rec)
		if veto then return nil end
		entry.id = HttpService:GenerateGUID(false)
		if entry.k == "spied" then
			table.insert(rec.sp, entry)
			while #rec.sp > 10 do table.remove(rec.sp, 1) end
		else
			table.insert(rec.q, entry)
		end
		return rec
	end)
	if not ok then return false, "The war office is busy. Try again in a moment" end
	if veto then return false, veto end
	ping(uid)
	return true
end
-- cash the defender still holds: the war card minus every raid that is still waiting to be paid
local function cashOnHand(card, rec)
	local taken = 0
	for _, r in ipairs(rec and rec.q or {}) do if r.k == "raided" and (r.t or 0) > (card.ht or 0) then taken += (r.steal or 0) end end
	return math.max(0, (card.cash or 0) - taken)
end
local function unpaid(rec)
	local n = 0
	for _, r in ipairs(rec and rec.q or {}) do if r.k == "raided" then n += 1 end end
	return n
end
-- a shield bought anywhere is written into the hit record so other servers refuse new hits at once (audit H4)
function RA.SetShield(uid, untilT)
	if not Store.Online then return end
	task.spawn(function()
		Store.Update(Store.DS(HITS_DS), tostring(uid), function(rec)
			rec = type(rec) == "table" and rec or {}
			rec.sh = math.max(rec.sh or 0, untilT)
			return rec
		end)
	end)
end

local function remoteSpy(plr, p, id, uid)
	local d = p.data
	local card = getCard(uid)
	if not card then return { ok = false, msg = "No war records for that nation yet" } end
	if d.sup < RA.SpySupply then return { ok = false, msg = "Not enough Supply (" .. RA.SpySupply .. " needed)" } end
	if p.remoteBusy then return { ok = false, msg = "Still sending your last order" } end
	p.remoteBusy = true
	local avail, sh = card.cash, card.sh or 0
	local ok, err = queueHit(uid, function(rec)
		avail = cashOnHand(card, rec)
		sh = math.max(sh, rec.sh or 0)
		return { k = "spied", by = d.name ~= "" and d.name or plr.Name, lv = d.lv, t = now() }
	end)
	p.remoteBusy = nil
	if not ok then return { ok = false, msg = err } end
	if PS.Profiles[plr] ~= p or p.leaving then return { ok = false, msg = "Left" } end
	d.sup = math.max(0, d.sup - RA.SpySupply)
	p.spied = p.spied or {}
	p.spied[id] = now()
	return { ok = true, intel = { cash = math.floor(avail), atk = card.atk, def = card.def, lv = card.lv, units = card.u, shield = math.max(0, sh - now()), remote = true } }
end

local function remoteAttack(plr, p, id, uid, guaranteed)
	local d = p.data
	local card = getCard(uid)
	if not card or not card.def then return { ok = false, msg = "No war records for that nation yet" } end
	local t = now()
	if (card.sh or 0) > t then return { ok = false, msg = "They are under a raid shield" } end
	if (card.lv or 0) < protectedLv() then return { ok = false, msg = "That nation is too new to be raided" } end
	p.raidCd = p.raidCd or {}
	if not guaranteed and (p.raidCd[id] or 0) + RC.Cooldown > t then return { ok = false, msg = "You just attacked them. Try again in " .. ((p.raidCd[id] or 0) + RC.Cooldown - t) .. "s" } end
	if not guaranteed and d.sup < RC.Supply then return { ok = false, msg = "Not enough Supply (" .. RC.Supply .. " needed)" } end
	if p.remoteBusy then return { ok = false, msg = "Still sending your last order" } end
	local mods = PS.Mods(p)
	local atk = PS.Power(p, mods)
	local def = card.def
	local chance = M.WinChance(atk, def)
	local win = guaranteed or math.random() < chance
	local m = margin(atk, def)
	if guaranteed and m == "close" then m = "clear" end
	local L = RC.Losses[m]
	local myLoss, theirLoss = win and L[1] or L[2], win and L[2] or L[1]
	local steal = 0
	p.remoteBusy = true
	local ok, err = queueHit(uid, function(rec)
		steal = 0
		if (rec.sh or 0) > t then return nil, "They are under a raid shield" end
		if unpaid(rec) >= RA.MaxUnpaid then return nil, "They have been raided too often. Try again later" end
		if win then
			if (rec.last or 0) + RC.Cooldown > t then return nil, "They were just raided. Try again in " .. ((rec.last or 0) + RC.Cooldown - t) .. "s" end
			local onHand = cashOnHand(card, rec)
			steal = math.floor(math.min(onHand * RC.StealPct * (1 + (mods.loot or 0)), stealCap(card.lv or 1)))
			steal = math.max(0, math.min(steal, onHand))
			rec.last = t
		end
		return { k = "raided", by = d.name, byId = "u" .. plr.UserId, win = win, steal = steal, loss = theirLoss, t = t }
	end)
	p.remoteBusy = nil
	if not ok then return { ok = false, msg = err } end
	if PS.Profiles[plr] ~= p or p.leaving then return { ok = false, msg = "Left" } end
	if not guaranteed then
		p.raidCd[id] = t
		d.sup = math.max(0, d.sup - RC.Supply)
		PS.TaskProgress(p, "supply", RC.Supply)
	end
	local myDead, myN = kill(d.units, myLoss, mods.losses)
	local theirN = math.floor((card.u or 0) * theirLoss * (1 - math.clamp(card.loss or 0, 0, 0.6)) + 0.5)
	d.stats.battles += 1
	local res = { ok = true, win = win, chance = chance, margin = m, lost = myDead, lostN = myN, killed = theirN, target = card.n, remote = true }
	res.fight = RA.Fight(atk, def, win)
	res.fight.a = { name = d.name, lv = d.lv, userId = plr.UserId, pow = atk, weapon = weaponOf(d), flag = d.flag }
	res.fight.d = { name = card.n, lv = card.lv, userId = uid, pow = def, weapon = card.w or { icon = "gear_fists", name = "Fists", rarity = "common" }, flag = card.f }
	if win then
		local got = PS.Earn(p, steal, "raid")
		local xp = math.max(1, math.floor(R.MinuteXp(d.lv) * 0.6 + 0.5))
		PS.AddXp(p, xp)
		d.stats.wins += 1; d.stats.stolen += got
		PS.TaskProgress(p, "raids", 1)
		res.cash = got; res.xp = xp
		if d.revenge and d.revenge.id == id then d.revenge = nil end
	end
	p.dirty = true
	return res
end
RA._remoteSpy = remoteSpy

-- The defender's side, applied exactly once (audit C1/H4): read the queue, apply only ids this profile has not seen,
-- remember those ids in the profile, SAVE, then remove them from the queue. A crash at any point either re-applies
-- nothing (ids remembered) or leaves the entries to be applied next time.
function RA.ApplyHits(plr, p)
	if not Store.Online or not p or p.applying or p.loading or p.leaving or not p.data.onboarded then return end
	p.applying = true
	local okG, rec = Store.Get(Store.DS(HITS_DS), tostring(plr.UserId))
	if not okG or type(rec) ~= "table" or ((not rec.q or #rec.q == 0) and (not rec.sp or #rec.sp == 0)) then p.applying = nil; return end
	if PS.Profiles[plr] ~= p or p.leaving then p.applying = nil; return end
	local d = p.data
	d.appliedHits = type(d.appliedHits) == "table" and d.appliedHits or {}
	local seen = {}
	for _, id in ipairs(d.appliedHits) do seen[id] = true end
	local done = {}
	local raids = { n = 0, cash = 0, lost = 0, win = false }
	for _, e in ipairs(rec.sp or {}) do
		if e.id and not seen[e.id] then
			seen[e.id] = true; table.insert(done, e.id)
			PS.Note(p, { kind = "spied", by = e.by, lv = e.lv })
		end
	end
	for _, e in ipairs(rec.q or {}) do
		if e.id and not seen[e.id] and e.k == "raided" then
			seen[e.id] = true; table.insert(done, e.id)
			local shielded = d.shieldFrom and (e.t or 0) >= d.shieldFrom and (e.t or 0) <= (d.shield or 0)
			if not shielded then
				local steal = math.floor(math.min(tonumber(e.steal) or 0, math.max(0, d.cash)))
				PS.Spend(p, steal)
				d.stats.lost += steal
				if e.win then d.stats.raided += 1 end
				local _, n = kill(d.units, math.clamp(tonumber(e.loss) or 0, 0, 0.5), PS.Mods(p).losses)
				d.revenge = { id = e.byId, name = e.by, t = e.t }
				raids.n += 1; raids.cash += steal; raids.lost += n; raids.win = raids.win or e.win
				raids.by, raids.byId = e.by, e.byId
			end
			d.hitApplied = math.max(d.hitApplied or 0, e.t or 0)
		end
	end
	for _, id in ipairs(done) do table.insert(d.appliedHits, id) end
	while #d.appliedHits > 120 do table.remove(d.appliedHits, 1) end
	if raids.n > 0 then
		PS.Note(p, { kind = "raided", by = raids.by, byId = raids.byId, win = raids.win, cash = raids.cash, lost = raids.lost })
		if raids.n > 1 then PS.Note(p, { kind = "toast", text = "You were raided " .. raids.n .. " times. The last attacker was " .. tostring(raids.by) .. ".", tone = "bad" }) end
	end
	p.dirty = true
	if #done > 0 and PS.Save(plr) then
		local gone = {}
		for _, id in ipairs(done) do gone[id] = true end
		Store.Update(Store.DS(HITS_DS), tostring(plr.UserId), function(r)
			if type(r) ~= "table" then return nil end
			local q, sp = {}, {}
			for _, e in ipairs(r.q or {}) do if not gone[e.id] then table.insert(q, e) end end
			for _, e in ipairs(r.sp or {}) do if not gone[e.id] then table.insert(sp, e) end end
			r.q, r.sp = q, sp
			return r
		end)
		task.spawn(RA.PublishCard, plr, p)
	end
	p.applying = nil
end

-- attacker p raids target id. guaranteed = Revenge Strike product
function RA.Attack(plr, p, id, guaranteed)
	local d = p.data
	local q, ai, qplr = findTarget(id)
	if not q and not ai then
		local uid = remoteUid(id)
		if uid and uid ~= plr.UserId then return remoteAttack(plr, p, id, uid, guaranteed) end
		return { ok = false, msg = "That nation is no longer in this server" }
	end
	if q == p then return { ok = false, msg = "You cannot raid yourself" } end
	if q and q.data.lv < protectedLv() then return { ok = false, msg = "That nation is too new to be raided" } end
	local t = now()
	if (lastHit[id] or 0) + RC.Cooldown > t then return { ok = false, msg = "They were just raided. Try again in " .. ((lastHit[id] or 0) + RC.Cooldown - t) .. "s" } end
	-- you can't hammer the same target: one attack per target per cooldown, win or lose (review #7)
	p.raidCd = p.raidCd or {}
	if not guaranteed and (p.raidCd[id] or 0) + RC.Cooldown > t then return { ok = false, msg = "You just attacked them. Try again in " .. ((p.raidCd[id] or 0) + RC.Cooldown - t) .. "s" } end
	if q and (q.data.shield or 0) > t then return { ok = false, msg = "They are under a raid shield" } end
	if not guaranteed then
		if d.sup < RC.Supply then return { ok = false, msg = "Not enough Supply (" .. RC.Supply .. " needed)" } end
		p.raidCd[id] = t -- set only once the raid really happens (audit L9)
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
	res.fight = RA.Fight(atk, def, win)
	res.fight.a = { name = d.name, lv = d.lv, userId = plr.UserId, pow = atk, weapon = weaponOf(d), flag = d.flag }
	if q then
		res.fight.d = { name = q.data.name, lv = q.data.lv, userId = qplr and qplr.UserId, pow = def, weapon = weaponOf(q.data), flag = q.data.flag }
	else
		local era = R.EraOf(ai.lv)
		res.fight.d = { name = ai.name, lv = ai.lv, ai = true, pow = def, flag = ai.flag,
			weapon = { icon = ERA_WEAPON[math.clamp(era, 1, 8)], name = "Army issue", rarity = "uncommon" } }
	end
	if win then
		lastHit[id] = t
		local onHand = q and q.data.cash or ai.cash
		local steal = math.floor(math.min(onHand * RC.StealPct * (1 + (mods.loot or 0)), stealCap(defLv)))
		steal = math.max(0, math.min(steal, onHand))
		if q then steal = PS.Spend(q, steal); q.data.stats.lost += steal; q.data.stats.raided += 1 else ai.cash -= steal end
		local got = PS.Earn(p, steal, "raid")
		local xp = math.max(1, math.floor(R.MinuteXp(d.lv) * 0.6 + 0.5))
		PS.AddXp(p, xp)
		d.stats.wins += 1; d.stats.stolen += got
		PS.TaskProgress(p, "raids", 1)
		res.cash = got; res.xp = xp
		if d.revenge and d.revenge.id == id then d.revenge = nil end -- revenge taken
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
		if d.onboarded and not q.loading and not q.leaving and d.lv >= protectedLv() and (d.shield or 0) <= t and (lastHit["u" .. plr.UserId] or 0) + RC.Cooldown <= t
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
		steal = PS.Spend(q, steal)
		q.data.stats.lost += steal; q.data.stats.raided += 1
		ai.cash += steal
	end
	q.data.revenge = { id = ai.id, name = ai.name, t = t }
	PS.Note(q, { kind = "raided", by = ai.name, byId = ai.id, win = win, cash = steal, lost = lostN })
	q.dirty = true
end

function RA.Start()
	RA.MakeAI()
	if Store.Online then
		task.spawn(function()
			local okS, errS = pcall(function()
				MessagingService:SubscribeAsync(TOPIC, function(msg)
					local uid = type(msg.Data) == "table" and tonumber(msg.Data.u)
					local plr = uid and Players:GetPlayerByUserId(uid)
					if plr and PS.Profiles[plr] then RA.ApplyHits(plr, PS.Profiles[plr]) end
				end)
			end)
			if not okS then warn("[Idle Country] hit subscription failed (the 90 s poll still applies hits): " .. tostring(errS)) end
		end)
		-- fallback poll + war cards
		task.spawn(function()
			local k = 0
			while true do
				task.wait(30)
				k += 1
				for plr, p in pairs(PS.Profiles) do
					if k % 3 == 0 then task.spawn(RA.ApplyHits, plr, p) end
					if k % 4 == 0 then task.spawn(RA.PublishCard, plr, p) end
				end
			end
		end)
	end
	task.spawn(function()
		local nextRaid = os.clock() + math.random(RC.AIRaidEvery[1], RC.AIRaidEvery[2])
		while true do
			task.wait(5)
			RA.TuneAI(false)
			for _ = 1, 4 do RA.TuneAI(false) end -- 5 s of growth (TuneAI adds one second's worth)
			if os.clock() >= nextRaid then
				nextRaid = os.clock() + math.random(RC.AIRaidEvery[1], RC.AIRaidEvery[2])
				local okA, errA = pcall(aiRaid)
				if not okA then warn("[Idle Country] AI raid: " .. tostring(errA)) end
			end
		end
	end)
end
return RA
