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
local Events = require(RS.Shared.Events)
local Config = require(RS.Shared.Config)
local O = require(RS.Shared.Officers)
local TK = require(RS.Shared.Tasks)
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
		stats = { laws = 0, trips = 0, earned = 0, wins = 0, battles = 0, bosses = 0, hits = 0, built = 0, raided = 0, lost = 0, stolen = 0 },
		receipts = {}, stipendT = 0,
		-- 1 Oct (Kash feedback round 2)
		bank = 0, shield = 0, revenge = nil,
		inv = { gear = {}, officers = {} }, cab = { slots = {}, bought = 0, player = {} },
		crates = { limited = 0, basic = 0 }, login = { idx = 1, last = 0 },
		refresh = { day = 0, tokens = 0 }, weekly = nil, bundle = false,
		-- 1 Oct evening: seals (task currency) and takedown tickets
		convoyBought = 0,
		seals = 0, tickets = 0, -- tickets: legacy, always 0
	}
end

local function sanitize(d)
	-- convoys became a purchase (2 Oct): saves from before keep every convoy their level had already given them
	if d.convoyBought == nil then d.convoyBought = d.onboarded and R.ConvoyGatesReached(d.lv or 1) or 0 end
	local f = PS.Fresh()
	for k, v in pairs(f) do if d[k] == nil then d[k] = v end end
	for k, v in pairs(f.sk) do if d.sk[k] == nil then d.sk[k] = v end end
	for k, v in pairs(f.stats) do if d.stats[k] == nil then d.stats[k] = v end end
	for _, k in ipairs({ "inv", "cab", "crates", "login", "refresh" }) do
		for k2, v in pairs(f[k]) do if d[k][k2] == nil then d[k][k2] = v end end
	end
	d.rivals = nil
	-- Takedown removed (2 Oct, Kash): unused tickets are refunded as Merits (2 each, their shop price)
	if (d.tickets or 0) > 0 then d.seals = (d.seals or 0) + d.tickets * 2 end
	d.tickets = 0; d.td = nil
	-- paid eras (2 Oct): saves from before keep the era their level already gave them
	if type(d.era) ~= "number" then d.era = R.EraOf(d.lv or 1) end
	d.era = math.clamp(math.floor(d.era), 1, #D.Eras)
	if not World.Cities[d.home] then d.home = 12 end
	local keep = {}
	for _, pi in ipairs(d.lots) do if type(pi) == "number" and (pi == 0 or D.Props[pi]) then table.insert(keep, pi) end end
	d.lots = keep
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
	for k, n in pairs(old.props or {}) do local pi = tonumber(k)
		if pi and D.Props[pi] then for _ = 1, n do table.insert(owned, pi) end end end
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
	local b = O.Bonuses(d.cab, d.inv, PS.OfficerSlots(p)) -- slotted officers + worn gear (only slots you own)
	local vt = PS.VipTier(p)
	local vip = (vt and vt.cash or 0) + (p.premium and Config.PremiumBonus or 0) + (p.inGroup and Config.Group.Bonus or 0)
	local vipRegen = vt and vt.regen or 0
	local regenPass = PS.Has(p, "FastInfluence") and 2 or 1 -- 2x Influence Regen pass doubles the whole rate
	return {
		law = 1 + (ideo.law or 0) + perks.law + b.law + vip, props = 1 + (ideo.props or 0) + perks.props + b.props + vip + R.WonderBonus(d.wonder),
		convoy = 1 + (ideo.convoy or 0) + perks.convoy + b.convoy + vip, regen = (1 + (ideo.regen or 0) + perks.regen + b.regen + vipRegen) * regenPass,
		supRegen = (1 + (ideo.regen or 0)) * (PS.Has(p, "FastSupply") and 2 or 1),
		xp = 1 + (ideo.xp or 0) + b.xp + vip,
		attack = (ideo.attack or 0) + perks.attack + b.attack + b.gearAtk, defense = (ideo.defense or 0) + perks.defense + b.defense + b.gearDef,
		siege = (ideo.attack or 0) + perks.attack + 0.05 * war + b.siege, boss = b.boss,
		loot = b.loot, losses = b.losses, interest = b.interest,
		countries = perks.countries, bonus = b,
	}
end
function PS.RegenSec(mods) return R.RegenSec / (mods and mods.regen or 1) end
function PS.SupplySec(mods) return R.SupplyRegenSec / (mods and mods.supRegen or 1) end
function PS.Has(p, pass) return p.gp[pass] == true end
-- silent rent on property income to the alliance holding your home capital (Kash 18:49: never notified)
function PS.PayRent(p, inc)
	local rate, owner = WS.RentFor(p.data, p.userId)
	if rate <= 0 or not owner or inc <= 0 then return inc end
	local cut = inc * rate
	WS.Credit(owner, cut)
	return inc - cut
end
function PS.AllianceTag(aid) local s = WS.Index[aid]; return s and s.tag or nil end
function PS.VipTier(p)
	if PS.Has(p, "MegaVIP") then return Config.VIP.MegaVIP end
	if PS.Has(p, "VIP") then return Config.VIP.VIP end
	return nil
end
-- Mega VIP owners get their unique limited officer once (benched if no free slot)
function PS.GrantVipOfficer(p)
	local d = p.data
	if not PS.Has(p, "MegaVIP") or d.vipOfficer then return end
	d.vipOfficer = true
	local o = O.VIPOfficer()
	PS.AddOfficer(p, o)
	PS.Note(p, { kind = "toast", text = "Mega VIP: " .. o.name .. " joined your cabinet", tone = "gold" })
end
function PS.IncHr(p, mods) return R.IncomePerHour(p.data.lots, (mods or PS.Mods(p)).props) end
function PS.LotsMax(p) return R.Lots(p.data.sk, PS.Has(p, "ExtraLots")) end
function PS.Slots(p) return R.ConvoySlots(p.data.lv, PS.Has(p, "ExtraConvoys"), p.data.convoyBought or 0) end
function PS.Power(p, mods)
	mods = mods or PS.Mods(p)
	return M.Power(p.data.lv, p.data.sk, p.data.units, mods, p.data.elite)
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
	if amount ~= amount or amount <= 0 or amount == math.huge then return 0 end
	if d.loan and d.loan.owed > 0 then
		local cut = math.min(d.loan.owed, amount * 0.2)
		d.loan.owed -= cut; amount -= cut
		if d.loan.owed <= 0.5 then d.loan = nil; PS.Note(p, { kind = "toast", text = "Loan fully repaid", tone = "good" }) end
	end
	-- alliance dues: a % of everything you earn goes to your alliance's treasury
	local rate = PS.DuesRate(p)
	if rate > 0 then
		local cut = amount * rate
		amount -= cut
		WS.Credit(d.alliance, cut)
		p.duesPaid = (p.duesPaid or 0) + cut
	end
	d.cash += amount
	d.stats.earned += amount
	PS.TaskProgress(p, "earn", amount / math.max(1, R.MinuteValue(d.lv)))
	return amount
end

-- money out that the player did not choose (raid losses, rent): never below zero, returns what was actually taken
function PS.Era(p) return R.PlayerEra(p.data) end

function PS.Spend(p, amount)
	local d = p.data
	amount = tonumber(amount) or 0
	if amount ~= amount or amount <= 0 or amount == math.huge then return 0 end
	amount = math.min(amount, math.max(0, d.cash))
	d.cash -= amount
	return amount
end

-- Kash 1 Oct: dues are a % of earnings. Style: flat, prog (higher levels pay more), regr (lower levels pay more).
-- Each member's rate scales from half to double the base by their level vs the alliance average.
function PS.DuesRate(p)
	local d = p.data
	local a = d.alliance and WS.Alliances[d.alliance]
	local dues = a and a.dues
	if not dues or (dues.pct or 0) <= 0 then return 0 end
	local base = dues.pct / 100
	if dues.style == "prog" or dues.style == "regr" then
		local sum, n = 0, 0
		for _, m in pairs(a.members) do if m.lv then sum += m.lv; n += 1 end end
		local avg = n > 0 and sum / n or d.lv
		local ratio = d.lv / math.max(1, avg)
		if dues.style == "regr" then ratio = 1 / math.max(0.01, ratio) end
		base *= math.clamp(ratio, 0.5, 2)
	end
	return math.min(base, Config.Alliance.DuesCap / 100)
end

-- alliance progress from anything a member does (WS batches it; see WorldService "alliance progression")
function PS.AllyProgress(p, kind, n)
	local d = p.data
	if d.alliance and WS.IsMember(d.alliance, p.userId) then WS.AddProgress(d.alliance, p.userId, kind, n) end
end
-- what this member can claim from the alliance: levels reached since they last claimed, and finished quests they helped
function PS.AllyClaimable(p)
	local d = p.data
	local a = d.alliance and WS.IsMember(d.alliance, p.userId) and WS.Alliances[d.alliance]
	if not a then return nil end
	local ac = d.allyClaim
	if type(ac) ~= "table" or ac.id ~= a.id then return nil end
	local out = { levels = math.max(0, (a.level or 1) - (ac.lv or a.level or 1)), quests = {} }
	for _, q in ipairs(a.quests or {}) do
		local k = tostring(a.qweek) .. ":" .. q.key
		if q.done and (q.by[tostring(p.userId)] or 0) > 0 and not (ac.q and ac.q[k]) then table.insert(out.quests, q.key) end
	end
	return out
end

function PS.AllyInfo(p, a)
	if not a then return nil end
	local lv = a.level or 1
	return { level = lv, xp = a.xp or 0, xpReq = WS.LevelXp(lv), maxLevel = WS.MaxLevel, cap = WS.MemberCap(a), bonus = WS.LevelBonus(lv),
		nextBonus = WS.LevelBonus(lv + 1), nextCap = WS.MemberCap({ level = lv + 1, up = a.up }), nextReward = WS.LevelReward(lv + 1),
		claim = PS.AllyClaimable(p), questXp = WS.QuestXp, week = WS.Week(), weekEnds = (WS.Week() + 1) * 604800 - 3 * 86400,
		xpPer = WS.AllyXp }
end

---------------------------------------------------------------- XP and levels (a level-up refills Influence and Supply)
function PS.AddXp(p, xp, quiet)
	local d = p.data
	xp = math.floor(xp * (p.xpMult or 1) + 0.5)
	d.xp += xp
	local levelled = false
	while d.xp >= R.XpReq(d.lv) do
		d.xp -= R.XpReq(d.lv)
		d.lv += 1
		levelled = true
		if not quiet then
			local laws, props, units = {}, {}, {}
			local pe = R.PlayerEra(d)
			for _, L in ipairs(D.Laws) do if L.lvl == d.lv and L.era <= pe then table.insert(laws, L.n) end end
			for _, P in ipairs(D.Props) do if P.lvl == d.lv and P.era <= pe then table.insert(props, P.n) end end
			for _, u in ipairs(M.Units) do if u.lvl == d.lv and u.era <= pe then table.insert(units, u.name) end end
			local era, eraCost
			for e, E in ipairs(D.Eras) do if E.start == d.lv and d.lv > 1 then era = E.name; eraCost = R.EraCost(e) end end
			local slot = table.find(R.ConvoySlotLevels, d.lv) and d.lv > 1
			if PS.AN then pcall(PS.AN.Level, p, d.lv) end
			PS.Note(p, { kind = "level", lv = d.lv, laws = laws, props = props, units = units, era = era, eraCost = eraCost, slot = slot, points = R.SkillPerLevel })
		end
	end
	if levelled then
		PS.TaskProgress(p, "level", 1)
		PS.MemberLevel(p)
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
	-- a lost pass (or a Studio test grant) leaves extra convoys: drop them once they are parked
	for i = #d.convoys, slots + 1, -1 do
		if not d.convoys[i].to then table.remove(d.convoys, i) end
	end
end

function PS.TradeCtx(p, mods)
	mods = mods or PS.Mods(p)
	return { lv = p.data.lv, era = R.PlayerEra(p.data), incHr = PS.IncHr(p, mods), day = R.Day(), convoyMult = mods.convoy }
end
-- tax for delivering into city b: 0 if your own alliance holds it
function PS.TaxFor(p, b)
	local c = WS.Cities[b]
	if not c or not c.owner then return 0, nil end
	if c.owner == p.data.alliance and WS.IsMember(p.data.alliance, p.userId) then return 0, nil end
	return c.tax or 0, c.owner
end
-- withEvent: only a convoy the player sends by hand can claim a world event bonus (not Auto Dispatch)
function PS.LoadsFor(p, a, b, mods, withEvent)
	local ctx = PS.TradeCtx(p, mods)
	ctx.taxPct = PS.TaxFor(p, b)
	ctx.wants = WS.WantsOf(b)
	local ev = Events.Active(os.time())
	if withEvent and ev and ev.city == b and p.data.wev ~= ev.id then ctx.event = ev end
	return T.Loads(a, b, ctx)
end

-- convoy i arrives. `when` = arrival time (offline catch-up passes the past time)
function PS.Arrive(p, c, when, quiet)
	local d = p.data
	local load = c.load
	-- a recalled convoy got home: refund the cargo it was carrying (Actions act.recall)
	if c.recall and type(c.orig) == "table" and c.orig.load then
		local cost = math.floor(c.orig.load.cost or 0)
		if cost > 0 then d.cash += cost end
		if c.orig.load.ev and d.wev == c.orig.load.ev then d.wev = nil end
		if not quiet then PS.Note(p, { kind = "toast", text = "Convoy back home · cargo refunded " .. R.Money(cost), tone = "info" }) end
	end
	c.at = c.to; c.to = nil; c.t0 = nil; c.t1 = nil; c.load = nil; c.empty = nil; c.recall = nil; c.orig = nil
	if load then
		local got = PS.Earn(p, load.pay - load.tax, "convoy")
		if load.owner and load.tax > 0 then WS.Credit(load.owner, load.tax) end
		PS.AddXp(p, load.xp, quiet)
		d.stats.trips += 1
		if PS.AN and d.stats.trips == 1 then pcall(PS.AN.Step, p, "First convoy") end
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
	local era = R.PlayerEra(d)
	local fast = PS.Has(p, "FastConvoys")
	local secs = T.TripSeconds(c.at, b, era, fast)
	c.from = c.at; c.to = b; c.t0 = startAt or now(); c.t1 = c.t0 + secs; c.load = load; c.empty = load == nil or nil; c.recall = nil; c.orig = nil
	c.kind = T.RouteKind(c.from, b)
	if load and load.good and (not startAt or startAt >= now() - 5) then WS.TickWant(b, load.good) end -- live sends only, not offline catch-up
	return true
end

-- best load anywhere from city a (Auto Dispatch). Scores net pay per second of travel.
function PS.BestRoute(p, a, budget, mods)
	local era = R.PlayerEra(p.data)
	local fast = PS.Has(p, "FastConvoys")
	local bestScore, bestB, bestLoad
	-- spread the fleet: every other convoy already heading to a city makes it 20% less attractive
	local heading = {}
	for _, c in ipairs(p.data.convoys) do if c.to then heading[c.to] = (heading[c.to] or 0) + 1 end end
	for b = 1, #World.Cities do
		if b ~= a then
			local loads = PS.LoadsFor(p, a, b, mods)
			local L = loads[1]
			if L and L.cost <= budget then
				local score = L.net / T.TripSeconds(a, b, era, fast) * 0.8 ^ (heading[b] or 0)
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
	local slots = PS.Slots(p)
	for i, c in ipairs(p.data.convoys) do
		local guard = 0
		while c.to and c.t1 <= t and guard < 1500 do
			guard += 1
			local when = c.t1
			local loaded = c.load ~= nil
			PS.Arrive(p, c, when, quiet)
			if loaded then n += 1 end
			if i <= slots then PS.AutoDispatch(p, c, when, mods) end
		end
		if not c.to and i <= slots then PS.AutoDispatch(p, c, t, mods) end
	end
	PS.EnsureConvoys(p)
	return n
end

---------------------------------------------------------------- daily orders + weekly challenges (Tasks.lua)
local function pickDistinct(rng, pool, count, exclude)
	local idx = {}
	for i in ipairs(pool) do if not (exclude and exclude[i]) then table.insert(idx, i) end end
	local out = {}
	while #out < count and #idx > 0 do table.insert(out, table.remove(idx, rng:NextInteger(1, #idx))) end
	return out
end
local function makeTask(def, i, src)
	return { src = src, i = i, key = def.key, n = def.n, have = 0, done = false, big = def.big, text = def.text, icon = def.icon, diff = src == "weekly" and "weekly" or def.diff or "easy" }
end
function PS.EnsureTasks(p)
	local d = p.data
	local day = R.Day()
	if not (d.tasks and d.tasks.day == day and d.tasks.v == 3) then
		local rng = Random.new(day * 7919 + (p.userId or 0))
		local list = {}
		local keys = {}
		for _, i in ipairs(pickDistinct(rng, TK.Daily, #TK.Daily)) do
			local def = TK.Daily[i]
			if not keys[def.key] and #list < TK.DailyCount then keys[def.key] = true; table.insert(list, makeTask(def, i, "daily")) end
		end
		d.tasks = { v = 3, day = day, list = list, bonus = false }
	end
	local week = TK.Week()
	if not (d.weekly and d.weekly.week == week and d.weekly.v == 3) then
		local list = {}
		for i, def in ipairs(TK.Weekly) do table.insert(list, makeTask(def, i, "weekly")) end
		d.weekly = { v = 3, week = week, list = list, chest = false }
	end
	if d.refresh.day ~= day then d.refresh.day = day; d.refresh.free = 1 end
	return d.tasks
end
local ALLY_KIND = { laws = "law", trips = "convoy", raids = "raid", siege = "hit", boss = "boss" }
function PS.TaskProgress(p, key, amount)
	local d = p.data
	if ALLY_KIND[key] then PS.AllyProgress(p, ALLY_KIND[key], amount) end -- alliance XP + quests credit live
	if not d.tasks then return end
	for _, list in ipairs({ d.tasks.list, d.weekly and d.weekly.list or {} }) do
		for _, task in ipairs(list) do
			if task.key == key and not task.done then task.have = math.min(task.n, task.have + amount) end
		end
	end
end
-- swap one order for a new one (1 free a day, then Challenge Refresh tokens)
function PS.RefreshTask(p, src, i)
	local d = p.data
	PS.EnsureTasks(p)
	local list = src == "weekly" and d.weekly.list or d.tasks.list
	local task = list[i]
	if not task or task.done then return false, "Pick an unfinished order" end
	local useFree = (d.refresh.free or 0) > 0
	if not useFree and (d.refresh.tokens or 0) <= 0 then return false, "no_refresh" end
	local pool = src == "weekly" and TK.WeeklyPool or TK.Daily
	local used = {}
	for _, t in ipairs(list) do if t.src == src or src == "daily" then used[t.key] = true end end
	local options = {}
	for j, def in ipairs(pool) do if not used[def.key] then table.insert(options, j) end end
	if src == "weekly" then
		options = {}
		local have = {}
		for _, t in ipairs(list) do have[t.text] = true end
		for j, def in ipairs(TK.WeeklyPool) do if not have[def.text] then table.insert(options, j) end end
		for j, def in ipairs(TK.Weekly) do if not have[def.text] then table.insert(options, -j) end end
	end
	if #options == 0 then return false, "No other orders available" end
	local pick = options[math.random(1, #options)]
	local def = pick < 0 and TK.Weekly[-pick] or pool[pick]
	list[i] = makeTask(def, math.abs(pick), src)
	if useFree then d.refresh.free -= 1 else d.refresh.tokens -= 1 end
	return true
end
function PS.TaskReward(p, task)
	local lv = p.data.lv
	if task and task.src == "weekly" then return { seals = TK.WeeklyReward.seals, cash = math.floor(R.MinuteValue(lv) * TK.WeeklyReward.lawMinutes) } end
	local r = TK.Diff[task and task.diff or "easy"] or TK.Diff.easy
	return { seals = r.seals, cash = math.floor(R.MinuteValue(lv) * r.lawMinutes) }
end

---------------------------------------------------------------- bosses
function PS.EnsureBoss(p)
	local d = p.data
	local era = R.PlayerEra(d)
	if not d.boss or (d.boss.era < era and (d.boss.next or 0) <= now()) then
		d.boss = { era = era, hp = M.BossHp(era), next = d.boss and d.boss.next or 0 }
	end
	return d.boss
end

---------------------------------------------------------------- officers / gear helpers
function PS.OfficerSlots(p)
	return Config.Officers.StartSlots + (p.data.cab.bought or 0) + (PS.Has(p, "BonusOfficer") and 1 or 0)
end
function PS.NextSlotCost(p)
	return Config.Officers.SlotCosts[(p.data.cab.bought or 0) + 1]
end
-- Kash 2 Oct: NO BENCH. An officer can only join into an open slot. Limited officers (Mega VIP, bundle) get their own
-- exclusive slot on top of the normal ones. Returns "slot"/"limited", or nil when there is no room (nothing added).
function PS.FreeSlot(p)
	local d = p.data
	for i = 1, PS.OfficerSlots(p) do if not d.cab.slots[i] then return i end end
	return nil
end
function PS.AddOfficer(p, o)
	local d = p.data
	d.cab.ltd = d.cab.ltd or {}
	if o.limited then
		d.inv.officers[o.id] = o
		if not table.find(d.cab.ltd, o.id) then table.insert(d.cab.ltd, o.id) end
		return "limited"
	end
	local i = PS.FreeSlot(p)
	if not i then return nil end
	for k = 1, i - 1 do if d.cab.slots[k] == nil then d.cab.slots[k] = false end end
	d.inv.officers[o.id] = o
	d.cab.slots[i] = o.id
	return "slot"
end
-- old saves: limited officers move to their exclusive slots; officers left on the retired bench are paid out in gold
local BENCH_REFUND = { common = 2, uncommon = 4, rare = 8, epic = 15, legendary = 30, mythic = 60, secret = 120, forbidden = 250 }
function PS.MigrateOfficers(p)
	local d = p.data
	d.cab.ltd = d.cab.ltd or {}
	for i, oid in pairs(d.cab.slots) do
		local o = oid and d.inv.officers[oid]
		if o and o.limited then d.cab.slots[i] = false end
	end
	local gold, n = 0, 0
	for oid, o in pairs(d.inv.officers) do
		if o.limited then
			if not table.find(d.cab.ltd, oid) then table.insert(d.cab.ltd, oid) end
		elseif not table.find(d.cab.slots, oid) then
			gold += BENCH_REFUND[o.rarity] or 2; n += 1
			d.inv.officers[oid] = nil
		end
	end
	if n > 0 then
		d.gold += gold
		PS.Note(p, { kind = "toast", text = n .. " officer" .. (n > 1 and "s" or "") .. " retired with honors: +" .. gold .. " gold!", tone = "gold" })
	end
end
function PS.AddGear(p, g)
	local n = 0
	for _ in pairs(p.data.inv.gear) do n += 1 end
	if n >= Config.InventoryMax then return false end
	p.data.inv.gear[g.id] = g
	return true
end
function PS.Rng(p) p.rng = p.rng or Random.new(os.clock() * 1e6 + (p.userId or 0)); return p.rng end
-- record this member's level on the alliance (for Progressive/Regressive dues), at most every 5 minutes
function PS.MemberLevel(p)
	local d = p.data
	if not d.alliance or (p.lvPush or 0) > os.clock() - 300 then return end
	p.lvPush = os.clock()
	local uid = tostring(p.userId)
	-- MEMBERS tab (Kash 3 Oct): also the member's strength (attack + defense) and when they were last active
	local okP, atk, def = pcall(PS.Power, p)
	local pw = okP and math.floor((atk or 0) + (def or 0)) or nil
	task.spawn(function()
		WS.MutateAlliance(d.alliance, function(x)
			local m = x.members[uid]
			if not m then return nil, "Not a member" end
			m.lv = d.lv; m.active = os.time()
			if pw then m.pw = pw end
			return x, true
		end)
	end)
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
		cash = d.cash, gold = d.gold, seals = d.seals, lv = d.lv, era = R.PlayerEra(d), eraCost = R.EraCost((d.era or 1) + 1), xp = d.xp, xpReq = R.XpReq(d.lv),
		inf = d.inf, infMax = R.MaxInfluence(d.lv, d.sk), infT = d.infT, regenSec = PS.RegenSec(mods),
		sup = d.sup, supMax = R.MaxSupply(d.lv, d.sk), supT = d.supT, supSec = PS.SupplySec(mods),
		passes = d.passes, lots = d.lots, lotsMax = PS.LotsMax(p), sk = d.sk, skillFree = PS.SkillFree(d), goldLaws = PS.GoldLaws(d),
		units = d.units, atk = atk, def = def, siege = M.SiegeDamage(d.lv, d.sk, d.units, { attack = mods.siege }),
		convoys = d.convoys, slots = PS.Slots(p), boss = boss, tasks = tasks, loan = d.loan,
		taskRewards = { easy = PS.TaskReward(p, { diff = "easy" }), medium = PS.TaskReward(p, { diff = "medium" }), hard = PS.TaskReward(p, { diff = "hard" }), weekly = PS.TaskReward(p, { src = "weekly" }) },
		loanMax = PS.LoanMax(p, mods), alliance = d.alliance, alliance_rec = a, stats = d.stats, allyInfo = PS.AllyInfo(p, a),
		gp = p.gp, mods = mods, incHr = PS.IncHr(p, mods), serverTime = now(), autoOff = d.autoOff, studio = Store.IsStudio,
		online = Store.Online, capitalCredit = d.capitalCredit or 0,
		bank = d.bank, bankRate = Config.Bank.InterestPerHour * (1 + (mods.interest or 0)), bankCap = R.MinuteValue(d.lv) * R.BankCapMinutes, shield = d.shield, revenge = d.revenge,
		inv = d.inv, cab = d.cab, officerSlots = PS.OfficerSlots(p), nextSlotCost = PS.NextSlotCost(p),
		crates = d.crates, basicCratePrice = PS.BasicCratePrice(p), login = d.login, loginReady = PS.LoginReady(p),
		weekly = d.weekly, refresh = d.refresh, bundle = d.bundle, starter = d.starter, wev = d.wev, wonder = d.wonder or 0, admin = PS.Admin and PS.Admin.IsAdmin(p.player) or nil, title = d.title, created = d.created, elite = d.elite, govCredit = d.govCredit, pity = d.pity or {}, tut = d.tut, convoyBought = d.convoyBought or 0, convoyNext = R.ConvoyCost((d.convoyBought or 0) + 1), groupGift = d.groupGift or false, duesRate = PS.DuesRate(p),
		targets = PS.Raids and PS.Raids.Targets(p) or {},
		raidLog = d.raidLog,
		targetsLow = PS.Raids and PS.Raids.ProtectedCount and PS.Raids.ProtectedCount(p) or 0,
		firstRefill = d.firstRefill or false, settings = d.settings or {}, meta = d.meta or {}, inGroup = p.inGroup or false, premium = p.premium or false, groupId = Config.Group.Id,
		vip = (PS.VipTier(p) or {}).tag, version = Config.Version,
	}
end
function PS.BasicCratePrice(p) return math.floor(R.MinuteValue(p.data.lv) * Config.Crates.Basic.lawMinutes) end
function PS.LoginReady(p) return (p.data.login.last or 0) < R.Day() end
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
	Remotes.Sync:FireClient(plr, "tick", { cash = d.cash, gold = d.gold, seals = d.seals, bank = d.bank, inf = d.inf, infT = d.infT, sup = d.sup, supT = d.supT, t = now() })
	if #p.notes > 0 then Remotes.Sync:FireClient(plr, "notes", p.notes); p.notes = {} end
end

---------------------------------------------------------------- load / save with a session lock
local function key(plr)
	if Store.IsStudio and workspace:GetAttribute("IC_TestProfile") then return "test_" .. plr.UserId end
	return "u" .. plr.UserId
end

-- saves for one player never overlap (audit M2): a save waits for the one in flight; nothing re-locks after the release
function PS.Save(plr, release)
	local p = PS.Profiles[plr]
	if not (p and p.canSave) or p.released then return end
	local waited = 0
	while p.saving and waited < 30 do task.wait(0.1); waited += 0.1 end
	if p.released then return end
	p.saving = true
	local okS, res = pcall(PS._save, plr, p, release)
	p.saving = nil
	if release then p.released = true end
	if not okS then warn("[Idle Country] save error for " .. plr.Name .. ": " .. tostring(res)); return false end
	return res
end
function PS._save(plr, p, release)
	p.data.last = now()
	p.data.lock = (not release) and { job = Store.JobId, t = now() } or nil
	local data = p.data
	local wrote = false
	local ok = Store.Update(Store.DS(STORE), key(plr), function(old)
		if old and old.lock and old.lock.job ~= Store.JobId and now() - (old.lock.t or 0) < 90 then
			wrote = false
			return nil -- another server took over this profile; never overwrite it
		end
		wrote = true
		return data
	end)
	if not ok then warn("[Idle Country] save failed for " .. plr.Name)
	elseif not wrote then
		warn("[Idle Country] save skipped for " .. plr.Name .. ": another server holds the profile. This session will not save.")
		p.canSave = false
		PS.Note(p, { kind = "toast", text = "You joined from another server. Progress here is no longer saved; please rejoin.", tone = "bad" })
	end
	return ok and wrote
end

-- a load that errors must never leave the player stuck on "Still loading" holding the lock (audit M8)
function PS.Load(plr)
	local ok, err = pcall(PS._load, plr)
	if ok then return err end
	warn("[Idle Country] load failed for " .. plr.Name .. ": " .. tostring(err))
	local store = Store.DS(STORE)
	if store then
		Store.Update(store, key(plr), function(old)
			if old and old.lock and old.lock.job == Store.JobId then old.lock = nil; return old end
			return nil
		end)
	end
	PS.Profiles[plr] = nil
	if plr.Parent then plr:Kick("Your save could not be loaded. Please rejoin in a moment.") end
end
function PS._load(plr)
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
	if not plr.Parent then
		-- left while loading: release the lock we just took
		if store and canSave then Store.Update(store, key(plr), function(old) if old and old.lock and old.lock.job == Store.JobId then old.lock = nil; return old end; return nil end) end
		return
	end
	data = sanitize(data)
	local p = { data = data, canSave = canSave and Store.Online, gp = {}, notes = {}, lastAct = 0, userId = plr.UserId, player = plr, pending = {}, loading = true }
	local lastSeen = data.last -- captured before any yield: Step must not overwrite it before CatchUp (review #1)
	PS.Profiles[plr] = p
	if data.alliance then
		local a, readOk = WS.LoadAlliance(data.alliance)
		if readOk and (not a or a.disbanded or not a.members[tostring(plr.UserId)]) then data.alliance = nil end
		-- members from before alliance levels existed start claiming from the current level
		if data.alliance and a and (type(data.allyClaim) ~= "table" or data.allyClaim.id ~= data.alliance) then
			data.allyClaim = { id = data.alliance, lv = a.level or 1, q = {} }
		end
	end
	PS.MigrateOfficers(p)
	if PS.AN then pcall(PS.AN.Step, p, "Joined") end
	PS.Market.CheckPasses(plr, p)
	p.xpMult = PS.Mods(p).xp
	PS.EnsureTasks(p)
	PS.MemberLevel(p)
	PS.EnsureConvoys(p)
	data.last = lastSeen or data.last
	PS.CatchUp(p)
	p.loading = nil
	PS.Sync(plr)
	if PS.Raids then task.spawn(PS.Raids.ApplyHits, plr, p); task.spawn(PS.Raids.PublishCard, plr, p) end -- raids from other servers while away
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
	-- convoys only count the capped window: a trip that ended before it is moved up to its start
	local cut = now() - away
	for _, c in ipairs(d.convoys) do
		if c.to and c.t1 < cut then local dur = c.t1 - c.t0; c.t1 = cut; c.t0 = cut - dur end
	end
	local inc = PS.IncHr(p, mods) / 3600 * away * R.OfflinePropShare
	inc = PS.PayRent(p, inc)
	PS.Earn(p, inc, "props")
	local regen = PS.RegenSec(mods)
	local maxInf = R.MaxInfluence(d.lv, d.sk)
	if d.inf < maxInf then
		local gain = math.floor((d.infT + away) / regen)
		d.inf = math.min(maxInf, d.inf + gain); d.infT = 0
	end
	local maxSup = R.MaxSupply(d.lv, d.sk)
	if d.sup < maxSup then
		local gain = math.floor((d.supT + away) / PS.SupplySec(mods))
		d.sup = math.min(maxSup, d.sup + gain); d.supT = 0
	end
	local trips = PS.AdvanceConvoys(p, now(), true)
	local stipend = PS.StipendRate(p) * away * 0.5
	if stipend > 0 then PS.Earn(p, stipend, "stipend") end
	-- bank interest at half rate while away (simple interest over the capped window)
	local interest = 0
	if (d.bank or 0) > 0 then
		interest = R.BankInterestBase(d.bank, d.lv) * Config.Bank.InterestPerHour * (1 + (mods.interest or 0)) * Config.Bank.OfflineShare * away / 3600
		d.bank += interest
	end
	PS.Note(p, { kind = "offline", away = away, cash = d.cash - cash0, props = inc, trips = trips, levels = d.lv - lv0, stipend = stipend, interest = interest })
end

-- alliance stipend: (level) x 3% of a minute of law value per minute, per member. Active members (online) get it in full,
-- offline catch-up pays half. Funded by the STATE STIPEND upgrade bought from the treasury.
function PS.StipendRate(p)
	local d = p.data
	local a = d.alliance and WS.IsMember(d.alliance, p.userId) and WS.Alliances[d.alliance]
	local lvl = a and a.up and a.up.stipend or 0
	if lvl <= 0 then return 0 end
	return R.MinuteValue(d.lv) * 0.03 * lvl / 60 -- per second
end

---------------------------------------------------------------- one-second heartbeat
function PS.Step(plr, p)
	local d = p.data
	if d.alliance then PS.MemberLevel(p) end -- throttled to once every 5 minutes inside
	local mods = PS.Mods(p)
	p.xpMult = mods.xp
	PS.TaskProgress(p, "online", 1 / 60) -- playtime orders (minutes)
	if (d.bank or 0) > 0 then d.bank += R.BankInterestBase(d.bank, d.lv) * Config.Bank.InterestPerHour * (1 + (mods.interest or 0)) / 3600 end
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
		local supSec = PS.SupplySec(mods)
		while d.supT >= supSec and d.sup < maxSup do d.sup += 1; d.supT -= supSec end
		if d.sup >= maxSup then d.supT = 0 end
	else d.supT = 0 end
	PS.Earn(p, PS.PayRent(p, PS.IncHr(p, mods) / 3600), "props")
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
		local p = PS.Profiles[plr]
		if p then
			if PS.Raids and p.data.onboarded then task.spawn(PS.Raids.PublishCard, plr, p) end -- fresh war card for while they're offline
			p.leaving = true; PS.Save(plr, true)
		end
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
				if p.loading or p.leaving then continue end
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
local nameCache = {}
function PS.Rank(plr, p)
	if not Store.Online or key(plr):find("^test_") or not p.data.onboarded then return end
	local d = p.data
	pcall(function()
		Store.ODS("IC_Rank_Level"):SetAsync(tostring(plr.UserId), d.lv * 100000 + math.floor(d.xp / math.max(1, R.XpReq(d.lv)) * 99999))
		Store.ODS("IC_Rank_Wealth"):SetAsync(tostring(plr.UserId), math.floor(math.log10(math.max(1, d.stats.earned)) * 1e6))
		Store.DS("IC_Names"):SetAsync(tostring(plr.UserId), { n = d.name, f = d.flag, a = d.alliance and WS.Index[d.alliance] and WS.Index[d.alliance].tag })
	end)
end
local robloxNames = {} -- [userId] = { dn, un }, kept for the server's life (names rarely change)
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
				-- names are cached for 10 minutes so a board costs 50 reads at most every 10 minutes (audit L8)
				local c = nameCache[e.key]
				local okN, info
				if c and os.clock() - c.t < 600 then okN, info = true, c.v
				else
					okN, info = pcall(function() return names:GetAsync(e.key) end)
					if okN then nameCache[e.key] = { t = os.clock(), v = info } end
				end
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
		for i = #list, 1, -1 do
			if list[i].uid and Config.HiddenFromRankings and Config.HiddenFromRankings[list[i].uid] then table.remove(list, i) end
		end
		-- Kash 3 Oct: the boards show Roblox names (display name + @username) and avatars; the country is on the profile
		local need = {}
		for _, e in ipairs(list) do
			local c = e.uid and robloxNames[e.uid]
			if c then e.dn, e.un = c.dn, c.un elseif e.uid and e.uid > 0 then table.insert(need, e.uid) end
		end
		if #need > 0 then
			local okU, infos = pcall(function() return game:GetService("UserService"):GetUserInfosByUserIdsAsync(need) end)
			if okU and type(infos) == "table" then
				for _, info in ipairs(infos) do robloxNames[info.Id] = { dn = info.DisplayName, un = info.Username } end
			end
			for _, e in ipairs(list) do
				local c = e.uid and robloxNames[e.uid]
				if c then e.dn, e.un = c.dn, c.un end
			end
		end
	end
	rankCache[kind] = { t = os.clock(), list = list }
	return list
end

PS._sanitize = sanitize
return PS
