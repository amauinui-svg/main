-- PlayerService: owns every player's profile. The client only asks; every rule is checked on the server.
-- Profile v2 (1 Oct 2026) with a session lock and a one-time migration from the v1 prototype save.
-- LESSONS: Studio playtests write the LIVE DataStore. Set workspace attribute IC_TestProfile = true to play on a
-- throwaway "test_" profile instead (safe for destructive tests).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local D = require(RS.Shared.GameData)
local R = require(RS.Shared.Rules)
local T = require(RS.Shared.Trade)
local M = require(RS.Shared.Military)
local World = require(RS.Shared.World)
local Config = require(RS.Shared.Config)
local Store = require(script.Parent.Store)
local WS = require(script.Parent.WorldService)

local PS = {}
PS.Profiles = {} -- [player] = { data, canSave, gp = {pass=true}, lastAct, dirty, rivals }
local STORE = "IC_Player_v2"
local OLD_STORE = "IdleCountry_Player_v1"
local Remotes = RS:WaitForChild("Remotes")

local function now() return os.time() end

---------------------------------------------------------------- profile shape
function PS.Fresh()
	return {
		v = 2, created = now(), last = now(), onboarded = false,
		name = "", flag = { l = "h3", c = { "1f3a93", "ecf0f1", "c0392b" } }, ideo = "republic", home = 12,
		cash = 500, gold = 20, lv = 1, xp = 0, inf = R.MaxInfluence(1, {}), infT = 0, sup = R.MaxSupply(1, {}), supT = 0,
		passes = {}, lots = {}, sk = { inf = 0, sup = 0, atk = 0, def = 0, lot = 0 }, units = {},
		convoys = {}, boss = nil, tasks = nil, loan = nil, alliance = nil,
		stats = { laws = 0, trips = 0, earned = 0, wins = 0, battles = 0, bosses = 0, hits = 0, built = 0 },
		receipts = {}, rivals = nil, stipendT = 0,
	}
end

local function sanitize(d)
	local f = PS.Fresh()
	for k, v in pairs(f) do if d[k] == nil then d[k] = v end end
	for k, v in pairs(f.sk) do if d.sk[k] == nil then d.sk[k] = v end end
	for k, v in pairs(f.stats) do if d.stats[k] == nil then d.stats[k] = v end end
	if not World.Cities[d.home] then d.home = 12 end
	for _, c in ipairs(d.convoys) do if not World.Cities[c.at] then c.at = d.home end end
	return d
end

-- v1 prototype save -> v2. Keeps cash, level, XP and law mastery; properties become lots (best first),
-- anything that no longer fits is refunded at its base price.
local function migrate(old)
	local d = PS.Fresh()
	d.cash = math.max(500, old.cash or 0); d.lv = old.lv or 1; d.xp = old.xp or 0
	d.passes = old.passes or {}
	local owned = {}
	for k, n in pairs(old.props or {}) do for _ = 1, n do table.insert(owned, tonumber(k)) end end
	table.sort(owned, function(a, b) return a > b end)
	local lots = R.Lots(d.sk, false)
	for _, p in ipairs(owned) do
		if #d.lots < lots then table.insert(d.lots, p) else d.cash += D.Props[p].cost end
	end
	d.migrated = now()
	return d
end

---------------------------------------------------------------- modifiers
function PS.Mods(p)
	local d = p.data
	local ideo = (R.IdeologyByKey[d.ideo] or R.Ideologies[1]).mod
	local perks = WS.Perks(d.alliance)
	local a = d.alliance and WS.Alliances[d.alliance]
	local war = a and a.up and a.up.war or 0
	return {
		law = 1 + (ideo.law or 0) + perks.law, props = 1 + (ideo.props or 0) + perks.props,
		convoy = 1 + (ideo.convoy or 0) + perks.convoy, regen = 1 + perks.regen,
		attack = (ideo.attack or 0) + perks.attack, defense = (ideo.defense or 0) + perks.defense,
		siege = (ideo.attack or 0) + perks.attack + 0.05 * war, countries = perks.countries,
	}
end
function PS.RegenSec(mods) return R.RegenSec / (mods and mods.regen or 1) end
function PS.Has(p, pass) return p.gp[pass] == true end
function PS.IncHr(p, mods) return R.IncomePerHour(p.data.lots, (mods or PS.Mods(p)).props) end
function PS.LotsMax(p) return R.Lots(p.data.sk, PS.Has(p, "ExtraLots")) end
function PS.Slots(p) return R.ConvoySlots(p.data.lv, PS.Has(p, "ExtraConvoys")) end
function PS.Power(p, mods)
	mods = mods or PS.Mods(p)
	return M.Power(p.data.lv, p.data.sk, p.data.units, mods)
end
function PS.GoldLaws(d)
	local n = 0
	for _, c in pairs(d.passes) do if c >= R.MasteryAt[3] then n += 1 end end
	return n
end
function PS.SkillFree(d) return R.SkillEarned(d.lv, PS.GoldLaws(d)) - R.SkillSpent(d.sk) end

---------------------------------------------------------------- money in (loan auto-repay takes 20%)
function PS.Earn(p, amount, src)
	local d = p.data
	if amount <= 0 then return amount end
	if d.loan and d.loan.owed > 0 then
		local cut = math.min(d.loan.owed, amount * 0.2)
		d.loan.owed -= cut; amount -= cut
		if d.loan.owed <= 0.5 then d.loan = nil; PS.Note(p, { kind = "toast", text = "Loan fully repaid", tone = "good" }) end
	end
	d.cash += amount
	d.stats.earned += amount
	return amount
end

---------------------------------------------------------------- XP and levels (a level-up refills Influence and Supply)
function PS.AddXp(p, xp, quiet)
	local d = p.data
	d.xp += xp
	local levelled = false
	while d.xp >= R.XpReq(d.lv) do
		d.xp -= R.XpReq(d.lv)
		d.lv += 1
		levelled = true
		if not quiet then
			local laws, props, units = {}, {}, {}
			for _, L in ipairs(D.Laws) do if L.lvl == d.lv then table.insert(laws, L.n) end end
			for _, P in ipairs(D.Props) do if P.lvl == d.lv then table.insert(props, P.n) end end
			for _, u in ipairs(M.Units) do if u.lvl == d.lv then table.insert(units, u.name) end end
			local era
			for _, E in ipairs(D.Eras) do if E.start == d.lv and d.lv > 1 then era = E.name end end
			local slot = table.find(R.ConvoySlotLevels, d.lv) and d.lv > 1
			PS.Note(p, { kind = "level", lv = d.lv, laws = laws, props = props, units = units, era = era, slot = slot, points = R.SkillPerLevel })
		end
	end
	if levelled then
		d.inf = math.max(d.inf, R.MaxInfluence(d.lv, d.sk)); d.infT = 0
		d.sup = math.max(d.sup, R.MaxSupply(d.lv, d.sk)); d.supT = 0
		PS.EnsureConvoys(p)
	end
	return levelled
end

---------------------------------------------------------------- convoys
function PS.EnsureConvoys(p)
	local d = p.data
	local slots = PS.Slots(p)
	while #d.convoys < slots do table.insert(d.convoys, { at = d.home }) end
end

function PS.TradeCtx(p, mods)
	mods = mods or PS.Mods(p)
	return { lv = p.data.lv, incHr = PS.IncHr(p, mods), day = R.Day(), convoyMult = mods.convoy }
end
-- tax for delivering into city b: 0 if your own alliance holds it
function PS.TaxFor(p, b)
	local c = WS.Cities[b]
	if not c or not c.owner then return 0, nil end
	if c.owner == p.data.alliance then return 0, nil end
	return c.tax or 0, c.owner
end
function PS.LoadsFor(p, a, b, mods)
	local ctx = PS.TradeCtx(p, mods)
	ctx.taxPct = PS.TaxFor(p, b)
	return T.Loads(a, b, ctx)
end

-- convoy i arrives. `when` = arrival time (offline catch-up passes the past time)
function PS.Arrive(p, c, when, quiet)
	local d = p.data
	local load = c.load
	c.at = c.to; c.to = nil; c.t0 = nil; c.t1 = nil; c.load = nil; c.empty = nil
	if load then
		local got = PS.Earn(p, load.pay - load.tax, "convoy")
		if load.owner and load.tax > 0 then WS.Credit(load.owner, load.tax) end
		PS.AddXp(p, load.xp, quiet)
		d.stats.trips += 1
		PS.TaskProgress(p, "trips", 1)
		if not quiet then
			PS.Note(p, { kind = "arrive", city = c.at, cash = got, xp = load.xp, good = load.good, tax = load.tax })
		end
	end
	return when
end

-- start a trip. load = nil for an empty move. Returns ok, msg
function PS.Dispatch(p, c, b, load, startAt)
	local d = p.data
	local era = R.EraOf(d.lv)
	local fast = PS.Has(p, "FastConvoys")
	local secs = T.TripSeconds(c.at, b, era, fast)
	c.from = c.at; c.to = b; c.t0 = startAt or now(); c.t1 = c.t0 + secs; c.load = load; c.empty = load == nil or nil
	c.kind = T.RouteKind(c.from, b)
	return true
end

-- best load anywhere from city a (Auto Dispatch). Scores net pay per second of travel.
function PS.BestRoute(p, a, budget, mods)
	local era = R.EraOf(p.data.lv)
	local fast = PS.Has(p, "FastConvoys")
	local bestScore, bestB, bestLoad
	for b = 1, #World.Cities do
		if b ~= a then
			local loads = PS.LoadsFor(p, a, b, mods)
			local L = loads[1]
			if L and L.cost <= budget then
				local score = L.net / T.TripSeconds(a, b, era, fast)
				if not bestScore or score > bestScore then bestScore, bestB, bestLoad = score, b, L end
			end
		end
	end
	return bestB, bestLoad
end

function PS.AutoDispatch(p, c, startAt, mods)
	if not PS.Has(p, "AutoDispatch") or c.to or p.data.autoOff or not p.data.onboarded then return false end
	-- never spends more than half of your cash on one load, so building and units are not starved
	local b, L = PS.BestRoute(p, c.at, p.data.cash * 0.5, mods)
	if not b then return false end
	local tax, owner = PS.TaxFor(p, b)
	p.data.cash -= L.cost
	PS.Dispatch(p, c, b, { good = L.good, cost = L.cost, pay = L.pay, tax = L.tax, xp = L.xp, owner = owner, taxPct = tax }, startAt)
	return true
end

-- run every convoy forward to time t (arrivals, then auto-dispatch). Returns number of deliveries.
function PS.AdvanceConvoys(p, t, quiet)
	local n = 0
	local mods = PS.Mods(p)
	for _, c in ipairs(p.data.convoys) do
		local guard = 0
		while c.to and c.t1 <= t and guard < 400 do
			guard += 1
			local when = c.t1
			local loaded = c.load ~= nil
			PS.Arrive(p, c, when, quiet)
			if loaded then n += 1 end
			PS.AutoDispatch(p, c, when, mods)
		end
		if not c.to then PS.AutoDispatch(p, c, t, mods) end
	end
	return n
end

---------------------------------------------------------------- daily tasks
PS.TaskPool = {
	{ key = "laws", n = 40, text = "Pass 40 laws", icon = "icon_laws" },
	{ key = "trips", n = 4, text = "Deliver 4 convoy loads", icon = "icon_package" },
	{ key = "wins", n = 3, text = "Win 3 battles", icon = "icon_battle" },
	{ key = "build", n = 2, text = "Build 2 properties", icon = "icon_properties" },
	{ key = "hits", n = 8, text = "Hit a boss or city 8 times", icon = "icon_attack" },
	{ key = "units", n = 5, text = "Recruit 5 units", icon = "icon_military" },
}
function PS.EnsureTasks(p)
	local d = p.data
	local day = R.Day()
	if d.tasks and d.tasks.day == day then return d.tasks end
	local picks, used = {}, {}
	local seed = (day * 31 + (p.userId or 0)) % 1000003
	while #picks < 3 do
		seed = (seed * 1103515245 + 12345) % 2147483648
		local i = seed % #PS.TaskPool + 1
		if not used[i] then used[i] = true; table.insert(picks, { key = PS.TaskPool[i].key, n = PS.TaskPool[i].n, have = 0, done = false }) end
	end
	d.tasks = { day = day, list = picks, bonus = false }
	return d.tasks
end
function PS.TaskProgress(p, key, amount)
	local t = PS.EnsureTasks(p)
	for _, task in ipairs(t.list) do
		if task.key == key and not task.done then task.have = math.min(task.n, task.have + amount) end
	end
end
function PS.TaskReward(p) return { gold = 2, cash = math.floor(R.MinuteValue(p.data.lv) * 15) } end

---------------------------------------------------------------- bosses
function PS.EnsureBoss(p)
	local d = p.data
	local era = R.EraOf(d.lv)
	if not d.boss or (d.boss.era < era and (d.boss.next or 0) <= now()) then
		d.boss = { era = era, hp = M.BossHp(era), next = d.boss and d.boss.next or 0 }
	end
	return d.boss
end

---------------------------------------------------------------- rival nations (Battle tab)
local RIVAL_A = { "Varnia", "Ostrava", "Kelmar", "Duvessa", "Tarsis", "Morvane", "Belgrast", "Quellan", "Sorrow Isles", "Halvard",
	"Zenthia", "Marrow Coast", "Ilyria", "Cordova", "Pellwick", "Ashgrove", "Norvik", "Saltreach", "Vey", "Brannock" }
local RIVAL_B = { "Republic of", "Kingdom of", "Federation of", "Free State of", "Union of", "Empire of", "Duchy of", "Commonwealth of" }
function PS.MakeRivals(p, mods)
	local d = p.data
	local atk = PS.Power(p, mods)
	local list = {}
	local rng = Random.new(now() + (p.userId or 0))
	for i = 1, 5 do
		local strength = ({ 0.55, 0.75, 0.95, 1.15, 1.4 })[i] * rng:NextNumber(0.9, 1.1)
		table.insert(list, {
			name = RIVAL_B[rng:NextInteger(1, #RIVAL_B)] .. " " .. RIVAL_A[rng:NextInteger(1, #RIVAL_A)],
			lv = math.max(1, d.lv + rng:NextInteger(-3, 3)), def = math.max(5, math.floor(atk * strength)),
			flag = { l = R.FlagLayouts[rng:NextInteger(1, #R.FlagLayouts)], c = { R.FlagColors[rng:NextInteger(1, 12)], R.FlagColors[rng:NextInteger(1, 12)], R.FlagColors[rng:NextInteger(1, 12)] } },
			reward = math.floor(R.MinuteValue(d.lv) * 1.5 * (0.7 + strength * 0.5)),
		})
	end
	d.rivals = { list = list, t = now() }
	return d.rivals
end

---------------------------------------------------------------- notes + sync
function PS.Note(p, note) table.insert(p.notes, note) end

function PS.Snapshot(p)
	local d = p.data
	local mods = PS.Mods(p)
	local atk, def = PS.Power(p, mods)
	local a = d.alliance and WS.Alliances[d.alliance]
	local tasks = PS.EnsureTasks(p)
	local boss = PS.EnsureBoss(p)
	return {
		name = d.name, flag = d.flag, ideo = d.ideo, home = d.home, onboarded = d.onboarded,
		cash = d.cash, gold = d.gold, lv = d.lv, xp = d.xp, xpReq = R.XpReq(d.lv),
		inf = d.inf, infMax = R.MaxInfluence(d.lv, d.sk), infT = d.infT, regenSec = PS.RegenSec(mods),
		sup = d.sup, supMax = R.MaxSupply(d.lv, d.sk), supT = d.supT,
		passes = d.passes, lots = d.lots, lotsMax = PS.LotsMax(p), sk = d.sk, skillFree = PS.SkillFree(d), goldLaws = PS.GoldLaws(d),
		units = d.units, atk = atk, def = def, siege = M.SiegeDamage(d.lv, d.sk, d.units, { attack = mods.siege }),
		convoys = d.convoys, slots = PS.Slots(p), boss = boss, tasks = tasks, taskReward = PS.TaskReward(p), loan = d.loan,
		loanMax = PS.LoanMax(p, mods), alliance = d.alliance, alliance_rec = a, stats = d.stats, rivals = d.rivals,
		gp = p.gp, mods = mods, incHr = PS.IncHr(p, mods), serverTime = now(), autoOff = d.autoOff, studio = Store.IsStudio,
		online = Store.Online,
	}
end
function PS.LoanMax(p, mods)
	return math.floor(R.MinuteValue(p.data.lv) * 60 + PS.IncHr(p, mods) * 2)
end

function PS.Sync(plr)
	local p = PS.Profiles[plr]
	if not p then return end
	Remotes.Sync:FireClient(plr, "full", PS.Snapshot(p))
	if #p.notes > 0 then Remotes.Sync:FireClient(plr, "notes", p.notes); p.notes = {} end
end
function PS.Tick(plr)
	local p = PS.Profiles[plr]
	if not p then return end
	local d = p.data
	Remotes.Sync:FireClient(plr, "tick", { cash = d.cash, gold = d.gold, inf = d.inf, infT = d.infT, sup = d.sup, supT = d.supT, t = now() })
	if #p.notes > 0 then Remotes.Sync:FireClient(plr, "notes", p.notes); p.notes = {} end
end

---------------------------------------------------------------- load / save with a session lock
local function key(plr)
	if Store.IsStudio and workspace:GetAttribute("IC_TestProfile") then return "test_" .. plr.UserId end
	return "u" .. plr.UserId
end

function PS.Save(plr, release)
	local p = PS.Profiles[plr]
	if not (p and p.canSave) then return end
	p.data.last = now()
	p.data.lock = (not release) and { job = Store.JobId, t = now() } or nil
	local data = p.data
	local ok = Store.Update(Store.DS(STORE), key(plr), function(old)
		if old and old.lock and old.lock.job ~= Store.JobId and now() - (old.lock.t or 0) < 90 then
			return nil -- another server took over this profile; never overwrite it
		end
		return data
	end)
	if not ok then warn("[Idle Country] save failed for " .. plr.Name) end
end

function PS.Load(plr)
	local store = Store.DS(STORE)
	local data, canSave = nil, true
	if store then
		for attempt = 1, 5 do
			local blocked = false
			local ok, res = Store.Update(store, key(plr), function(old)
				if old and old.lock and old.lock.job ~= Store.JobId and now() - (old.lock.t or 0) < 90 and attempt < 5 then
					blocked = true
					return nil
				end
				old = old or { fresh = true }
				old.lock = { job = Store.JobId, t = now() }
				return old
			end)
			if not ok then canSave = false; break end
			if not blocked then data = res; break end
			task.wait(3)
		end
	end
	if not plr.Parent then return end
	if not data or data.fresh then
		local old
		if store and not key(plr):find("^test_") then
			local ok, o = Store.Get(Store.DS(OLD_STORE), "u" .. plr.UserId)
			if ok then old = o else canSave = false end
		end
		data = old and migrate(old) or PS.Fresh()
	end
	data = sanitize(data)
	local p = { data = data, canSave = canSave and Store.Online, gp = {}, notes = {}, lastAct = 0, userId = plr.UserId, player = plr, pending = {} }
	PS.Profiles[plr] = p
	if data.alliance then
		local a = WS.LoadAlliance(data.alliance)
		if not a or not a.members[tostring(plr.UserId)] then data.alliance = nil end
	end
	PS.Market.CheckPasses(plr, p)
	PS.EnsureConvoys(p)
	PS.CatchUp(p)
	PS.Sync(plr)
	if not canSave then PS.Note(p, { kind = "toast", text = "Your save could not be loaded. Progress this session will NOT be saved. Rejoin to retry.", tone = "bad" }) end
	return p
end

-- time away: Influence + Supply regen, 50% property income, convoys keep travelling (Auto Dispatch keeps trading)
function PS.CatchUp(p)
	local d = p.data
	local away = math.clamp(now() - (d.last or now()), 0, R.OfflineCapSec)
	if away < 30 then return end
	local mods = PS.Mods(p)
	local cash0, lv0 = d.cash, d.lv
	local inc = PS.IncHr(p, mods) / 3600 * away * R.OfflinePropShare
	PS.Earn(p, inc, "props")
	local regen = PS.RegenSec(mods)
	local maxInf = R.MaxInfluence(d.lv, d.sk)
	if d.inf < maxInf then
		local gain = math.floor((d.infT + away) / regen)
		d.inf = math.min(maxInf, d.inf + gain); d.infT = 0
	end
	local maxSup = R.MaxSupply(d.lv, d.sk)
	if d.sup < maxSup then
		local gain = math.floor((d.supT + away) / R.SupplyRegenSec)
		d.sup = math.min(maxSup, d.sup + gain); d.supT = 0
	end
	local trips = PS.AdvanceConvoys(p, now(), true)
	local stipend = PS.StipendRate(p) * away * 0.5
	if stipend > 0 then PS.Earn(p, stipend, "stipend") end
	PS.Note(p, { kind = "offline", away = away, cash = d.cash - cash0, props = inc, trips = trips, levels = d.lv - lv0, stipend = stipend })
end

-- alliance stipend: (level) x 3% of a minute of law value per minute, per member. Active members (online) get it in full,
-- offline catch-up pays half. Funded by the STATE STIPEND upgrade bought from the treasury.
function PS.StipendRate(p)
	local d = p.data
	local a = d.alliance and WS.Alliances[d.alliance]
	local lvl = a and a.up and a.up.stipend or 0
	if lvl <= 0 then return 0 end
	return R.MinuteValue(d.lv) * 0.03 * lvl / 60 -- per second
end

---------------------------------------------------------------- one-second heartbeat
function PS.Step(plr, p)
	local d = p.data
	local mods = PS.Mods(p)
	local regen = PS.RegenSec(mods)
	local maxInf = R.MaxInfluence(d.lv, d.sk)
	if d.inf < maxInf then
		d.infT += 1
		while d.infT >= regen and d.inf < maxInf do d.inf += 1; d.infT -= regen end
		if d.inf >= maxInf then d.infT = 0 end
	else d.infT = 0 end
	local maxSup = R.MaxSupply(d.lv, d.sk)
	if d.sup < maxSup then
		d.supT += 1
		while d.supT >= R.SupplyRegenSec and d.sup < maxSup do d.sup += 1; d.supT -= R.SupplyRegenSec end
		if d.sup >= maxSup then d.supT = 0 end
	else d.supT = 0 end
	PS.Earn(p, PS.IncHr(p, mods) / 3600, "props")
	local st = PS.StipendRate(p)
	if st > 0 then PS.Earn(p, st, "stipend") end
	local lvBefore = d.lv
	local arrived = 0
	for _, c in ipairs(d.convoys) do if c.to and c.t1 <= now() then arrived += 1 end end
	if arrived > 0 or PS.Has(p, "AutoDispatch") then
		local idle = 0
		for _, c in ipairs(d.convoys) do if not c.to then idle += 1 end end
		if arrived > 0 or idle > 0 then
			local before = {}
			for i, c in ipairs(d.convoys) do before[i] = c.to end
			PS.AdvanceConvoys(p, now(), false)
			local changed = arrived > 0
			for i, c in ipairs(d.convoys) do if c.to ~= before[i] then changed = true end end
			if changed then p.dirty = true end
		end
	end
	if d.lv ~= lvBefore then p.dirty = true end
	d.last = now()
	if p.dirty then p.dirty = false; PS.Sync(plr) else PS.Tick(plr) end
end

function PS.Start()
	Players.PlayerAdded:Connect(PS.Load)
	for _, plr in ipairs(Players:GetPlayers()) do task.spawn(PS.Load, plr) end
	Players.PlayerRemoving:Connect(function(plr)
		if PS.Profiles[plr] then PS.Save(plr, true) end
		PS.Profiles[plr] = nil
	end)
	game:BindToClose(function()
		local n = 0
		for plr in pairs(PS.Profiles) do n += 1; task.spawn(function() PS.Save(plr, true); n -= 1 end) end
		local t = os.clock()
		while n > 0 and os.clock() - t < 25 do task.wait(0.1) end
	end)
	task.spawn(function()
		local clock = 0
		while true do
			task.wait(1)
			clock += 1
			for plr, p in pairs(PS.Profiles) do
				local ok, err = pcall(PS.Step, plr, p)
				if not ok then warn("[Idle Country] tick " .. plr.Name .. ": " .. tostring(err)) end
			end
			if clock % 60 == 0 then for plr in pairs(PS.Profiles) do task.spawn(PS.Save, plr) end end
			if clock % 120 == 0 then for plr, p in pairs(PS.Profiles) do task.spawn(PS.Rank, plr, p) end end
		end
	end)
end

---------------------------------------------------------------- rankings (OrderedDataStores)
local rankCache = {}
function PS.Rank(plr, p)
	if not Store.Online or key(plr):find("^test_") or not p.data.onboarded then return end
	local d = p.data
	pcall(function()
		Store.ODS("IC_Rank_Level"):SetAsync(tostring(plr.UserId), d.lv * 100000 + math.floor(d.xp / math.max(1, R.XpReq(d.lv)) * 99999))
		Store.ODS("IC_Rank_Wealth"):SetAsync(tostring(plr.UserId), math.floor(math.log10(math.max(1, d.stats.earned)) * 1e6))
		Store.DS("IC_Names"):SetAsync(tostring(plr.UserId), { n = d.name, f = d.flag, a = d.alliance and WS.Index[d.alliance] and WS.Index[d.alliance].tag })
	end)
end
function PS.Rankings(kind)
	local c = rankCache[kind]
	if c and os.clock() - c.t < 60 then return c.list end
	local list = {}
	if kind == "alliances" then
		for id, s in pairs(WS.Index) do
			local cities = 0
			for _, city in pairs(WS.Cities) do if city.owner == id then cities += 1 end end
			table.insert(list, { name = s.name, tag = s.tag, color = s.color, value = cities, members = s.members })
		end
		table.sort(list, function(a, b) if a.value ~= b.value then return a.value > b.value end; return (a.members or 0) > (b.members or 0) end)
		while #list > 50 do table.remove(list) end
	elseif Store.Online then
		local ods = Store.ODS(kind == "level" and "IC_Rank_Level" or "IC_Rank_Wealth")
		local ok, pages = pcall(function() return ods:GetSortedAsync(false, 50) end)
		if ok then
			local names = Store.DS("IC_Names")
			for _, e in ipairs(pages:GetCurrentPage()) do
				local okN, info = pcall(function() return names:GetAsync(e.key) end)
				local value = kind == "level" and math.floor(e.value / 100000) or 10 ^ (e.value / 1e6)
				table.insert(list, { name = okN and info and info.n or ("Player " .. e.key), flag = okN and info and info.f, tag = okN and info and info.a, value = value, uid = tonumber(e.key) })
			end
		end
	end
	if kind ~= "alliances" then
		-- always include players in this server so the board is never empty in Studio
		for plr, p in pairs(PS.Profiles) do
			local found = false
			for _, e in ipairs(list) do if e.uid == plr.UserId then found = true end end
			if not found and p.data.onboarded then
				table.insert(list, { name = p.data.name, flag = p.data.flag, uid = plr.UserId, value = kind == "level" and p.data.lv or p.data.stats.earned, tag = p.data.alliance and WS.Index[p.data.alliance] and WS.Index[p.data.alliance].tag })
			end
		end
		table.sort(list, function(a, b) return a.value > b.value end)
	end
	rankCache[kind] = { t = os.clock(), list = list }
	return list
end

return PS
