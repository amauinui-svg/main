-- WorldService: the ONE shared world (Kash, 1 Oct 2026): every server sees the same cities and owners.
-- Cities live in MemoryStore (fast, shared, safe for many attackers) and are backed up to a DataStore.
-- Alliances live in a DataStore. Servers tell each other about changes over MessagingService.
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local TextService = game:GetService("TextService")
local RS = game:GetService("ReplicatedStorage")
local World = require(RS.Shared.World)
local Config = require(RS.Shared.Config)
local Military = require(RS.Shared.Military)
local Store = require(script.Parent.Store)

local WS = {}
-- Studio test mode (workspace attribute IC_TestProfile) uses separate stores so tests never touch the live world.
local SUFFIX = (Store.IsStudio and workspace:GetAttribute("IC_TestProfile")) and "_test" or ""
local CITY_MAP = "IC_Cities_v1" .. SUFFIX
local ALLY_DS = "IC_Alliances_v1" .. SUFFIX
local WORLD_DS = "IC_World_v1" .. SUFFIX
WS.TestMode = SUFFIX ~= ""
local AC = Config.Alliance

WS.Cities = {} -- [i] = { owner, tax, hp, maxHp, prot, taxSet }
WS.Alliances = {} -- [id] = record (cache)
WS.Index = {} -- [id] = { name, tag, color, members, cities }
WS.Changed = Instance.new("BindableEvent") -- fires (kind, id) after any refresh

local function now() return os.time() end

---------------------------------------------------------------- perks
-- each city grants its owner a perk; size by tier. Only the strongest 2 of each type count (Idle Mafia rule).
WS.PerkNames = { law = "law cash", props = "property income", convoy = "convoy pay", regen = "Influence regen", attack = "attack", defense = "defense" }
WS.PerkSize = { 3, 5, 8, 12 }
-- countries with 2+ cities: own them all for a +10% bonus to law cash, property income and convoy pay
WS.Countries = {}
for i, c in ipairs(World.Cities) do
	WS.Countries[c.country] = WS.Countries[c.country] or {}
	table.insert(WS.Countries[c.country], i)
end
WS.Upgrades = {
	{ key = "stipend", name = "STATE STIPEND", icon = "icon_coins", max = 10, desc = "Every member earns an hourly wage" },
	{ key = "trade", name = "TRADE NETWORK", icon = "icon_globe", max = 5, desc = "+3% convoy pay for every member" },
	{ key = "war", name = "WAR COLLEGE", icon = "icon_attack", max = 5, desc = "+5% siege damage per level" },
	{ key = "fort", name = "FORTIFICATIONS", icon = "icon_castle", max = 5, desc = "+10% garrison per level on captured cities" },
}
function WS.UpgradeCost(level) return math.floor(2.5e6 * 4 ^ level + 0.5) end

function WS.CityGarrison(i) return Military.NeutralGarrison[World.Cities[i].tier] end

-- perks for an alliance id: { law=.., props=.., convoy=.., regen=.., attack=.., defense=.., countries={...} }
function WS.Perks(aid)
	local out = { law = 0, props = 0, convoy = 0, regen = 0, attack = 0, defense = 0, countries = {}, cities = 0 }
	if not aid then return out end
	local byType = {}
	for i, c in pairs(WS.Cities) do
		if c.owner == aid then
			out.cities += 1
			local p = World.Cities[i].perk
			byType[p] = byType[p] or {}
			table.insert(byType[p], WS.PerkSize[World.Cities[i].tier] / 100)
		end
	end
	for p, list in pairs(byType) do
		table.sort(list, function(a, b) return a > b end)
		out[p] += (list[1] or 0) + (list[2] or 0)
	end
	for country, list in pairs(WS.Countries) do
		if #list >= 2 then
			local all = true
			for _, i in ipairs(list) do if not (WS.Cities[i] and WS.Cities[i].owner == aid) then all = false end end
			if all then
				table.insert(out.countries, country)
				out.law += 0.10; out.props += 0.10; out.convoy += 0.10
			end
		end
	end
	local a = WS.Alliances[aid]
	if a and a.up then out.convoy += 0.03 * (a.up.trade or 0) end
	local lb = WS.LevelBonus(a and a.level)
	out.law += lb; out.props += lb; out.convoy += lb
	out.levelBonus = lb
	return out
end

---------------------------------------------------------------- cities
local function defaultCity(i) local g = WS.CityGarrison(i); return { owner = nil, tax = 0, hp = g, maxHp = g, prot = 0, taxSet = 0 } end

local function publicCity(i, c)
	return { owner = c.owner, tax = c.tax or 0, hp = c.hp, maxHp = c.maxHp, prot = c.prot or 0, rent = c.rent or 0 }
end

function WS.RefreshCity(i)
	local c = Store.MapGet(CITY_MAP, "c" .. i)
	WS.Cities[i] = c or WS.Cities[i] or defaultCity(i)
end

function WS.RefreshAllCities()
	local left = #World.Cities
	for i = 1, #World.Cities do
		task.spawn(function()
			local ok = pcall(WS.RefreshCity, i)
			if not ok then WS.Cities[i] = WS.Cities[i] or defaultCity(i) end
			left -= 1
		end)
	end
	local t = os.clock()
	while left > 0 and os.clock() - t < 10 do task.wait() end
end

-- restore city state from the DataStore backup if MemoryStore has lost it
local function restoreCities()
	local ok, backup = Store.Get(Store.DS(WORLD_DS), "cities")
	if ok and type(backup) == "table" then
		for i, c in pairs(backup) do
			local idx = tonumber(i)
			if idx and World.Cities[idx] then
				Store.MapUpdate(CITY_MAP, "c" .. idx, function(old) if old then return nil end; return c end)
			end
		end
	end
end
local function backupCities()
	if not Store.MemOnline then return end -- a server cut off from the shared map must never overwrite its backup (audit M9)
	local snap = {}
	for i, c in pairs(WS.Cities) do if c.owner then snap[tostring(i)] = c end end
	Store.Update(Store.DS(WORLD_DS), "cities", function() return snap end)
end

---------------------------------------------------------------- alliances
local function summary(a)
	return { name = a.name, tag = a.tag, color = a.color, members = a.count or 0, level = a.level or 1, cap = WS.MemberCap(a), open = a.open ~= false, leader = a.leaderName,
		fee = a.joinFee or 0, dues = a.dues and a.dues.pct or 0, style = a.dues and a.dues.style or "flat" }
end
-- returns record, readOk (readOk=false means the DataStore could not be reached: do not act on a missing record)
function WS.LoadAlliance(id)
	if not id then return nil, true end
	local ok, a = Store.Get(Store.DS(ALLY_DS), "a_" .. id)
	-- never step back to an older copy (DataStore reads can be cached for a few seconds): the stage rollback bug
	local cur = WS.Alliances[id]
	if ok and a and cur and (a.rev or 0) < (cur.rev or 0) then return cur, true end
	if ok and a then WS.Alliances[id] = a; WS.Index[id] = summary(a) end
	if ok and not a then WS.Alliances[id] = nil end
	return WS.Alliances[id], ok
end
function WS.RefreshIndex()
	local ok, idx = Store.Get(Store.DS(ALLY_DS), "index")
	if ok and type(idx) == "table" then
		for id, s in pairs(idx) do WS.Index[id] = s end
		for id in pairs(WS.Index) do if not idx[id] and not WS.Alliances[id] then WS.Index[id] = nil end end
	end
end
local function writeIndex(id, s)
	Store.Update(Store.DS(ALLY_DS), "index", function(old)
		old = old or {}
		old[id] = s
		return old
	end)
end
local function publish(kind, id, rev)
	if Store.Online then
		local ok, err = pcall(function() MessagingService:PublishAsync("IC_World" .. SUFFIX, { k = kind, id = id, r = rev }) end)
		if not ok then warn("[Idle Country] world publish failed: " .. tostring(err)) end
	end
	WS.Changed:Fire(kind, id)
end
-- set by GameServer: does anyone in THIS server belong to alliance id? (audit M5: other servers skip the read)
WS.Interest = function(id) return false end

-- mutate an alliance record atomically. fn(a) returns (a, result) or (nil, errorMessage).
-- quiet = true: no cross-server message (treasury/progress flushes; other servers pick it up on the periodic refresh)
function WS.MutateAlliance(id, fn, quiet)
	local result, err
	local ok, a = Store.Update(Store.DS(ALLY_DS), "a_" .. id, function(old)
		old = old or (not Store.Online and WS.Alliances[id]) or nil
		if not old then err = "Alliance not found"; return nil end
		local new, r = fn(old)
		if not new then err = r; return nil end
		new.rev = (new.rev or 0) + 1
		result = r
		return new
	end)
	if not ok then return nil, "Could not reach the alliance records. Try again." end
	if err then return nil, err end
	if a then
		a.count = 0; for _ in pairs(a.members) do a.count += 1 end
		WS.Alliances[id] = a
		if a.disbanded then
			-- nobody left: drop it from the list and free its cities
			WS.Index[id] = nil
			writeIndex(id, nil)
			for i, c in pairs(WS.Cities) do
				if c.owner == id then
					Store.MapUpdate(CITY_MAP, "c" .. i, function(old)
						if not old or old.owner ~= id then return nil end
						local g = WS.CityGarrison(i)
						return { owner = nil, tax = 0, hp = g, maxHp = g, prot = 0, taxSet = 0 }
					end)
					WS.RefreshCity(i)
					publish("c", i)
				end
			end
		else
			local s = summary(a)
			local old = WS.Index[id]
			WS.Index[id] = s
			-- skip the shared index write when nothing in the summary changed (review #5)
			if not old or HttpService:JSONEncode(old) ~= HttpService:JSONEncode(s) then writeIndex(id, s) end
		end
		if not quiet or a.disbanded then publish("a", id, a.rev) else WS.Changed:Fire("a", id) end
	end
	return a, result
end

function WS.Filter(text, userId)
	local ok, r = pcall(function()
		local f = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)
		return f:GetNonChatStringForBroadcastAsync()
	end)
	if not ok then return nil end
	return r
end

function WS.CreateAlliance(plr, name, tag, color, who)
	name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	tag = tostring(tag or ""):upper():gsub("[^A-Z0-9]", "")
	if #name < 3 or #name > 24 then return nil, "Name must be 3 to 24 letters" end
	if #tag < 2 or #tag > 4 then return nil, "Tag must be 2 to 4 letters or numbers" end
	if not table.find(AC.Colors, color) then color = AC.Colors[1] end
	local fname = WS.Filter(name, plr.UserId)
	local ftag = WS.Filter(tag, plr.UserId)
	if not fname or fname ~= name or not ftag or ftag ~= tag then return nil, "That name is not allowed" end
	for _, s in pairs(WS.Index) do
		if s.name and s.name:lower() == name:lower() then return nil, "That name is taken" end
		if s.tag and s.tag == tag then return nil, "That tag is taken" end
	end
	local id = HttpService:GenerateGUID(false):sub(1, 8)
	-- names and tags are reserved in their own keys so two servers cannot found the same one (audit L3)
	local okN, why = WS.ReserveName(name, tag, id)
	if not okN then return nil, why end
	local a = {
		id = id, name = name, tag = tag, color = color, created = now(), open = true,
		leader = plr.UserId, leaderName = who or plr.Name,
		members = { [tostring(plr.UserId)] = { name = who or plr.Name, role = "leader", joined = now(), active = now() } },
		treasury = 0, up = { stipend = 0, trade = 0, war = 0, fort = 0 }, log = {}, count = 1,
	}
	table.insert(a.log, { t = now(), m = (who or plr.Name) .. " founded the alliance" })
	local ok = Store.Update(Store.DS(ALLY_DS), "a_" .. id, function() return a end)
	if not ok then WS.ReleaseName(a); return nil, "Could not save the alliance. Try again." end
	WS.Alliances[id] = a
	WS.Index[id] = summary(a)
	writeIndex(id, WS.Index[id])
	publish("a", id)
	return a
end

local function reserveKey(k, id)
	local taken
	local ok = Store.Update(Store.DS(ALLY_DS), k, function(old)
		taken = nil
		if old and old ~= id then
			-- a reservation by an alliance that no longer exists is free again
			if WS.Index[old] then taken = true; return nil end
		end
		return id
	end)
	return ok and not taken
end
function WS.ReserveName(name, tag, id)
	if not Store.Online then return true end
	if not reserveKey("nm_" .. name:lower(), id) then return false, "That name is taken" end
	if not reserveKey("tg_" .. tag, id) then
		Store.Update(Store.DS(ALLY_DS), "nm_" .. name:lower(), function(old) if old == id then return "" end; return nil end)
		return false, "That tag is taken"
	end
	return true
end
function WS.ReleaseName(a)
	if not Store.Online or not a or not a.name then return end
	task.spawn(function()
		Store.Update(Store.DS(ALLY_DS), "nm_" .. a.name:lower(), function(old) if old == a.id then return "" end; return nil end)
		Store.Update(Store.DS(ALLY_DS), "tg_" .. tostring(a.tag), function(old) if old == a.id then return "" end; return nil end)
	end)
end

local function addLog(a, m)
	a.log = a.log or {}
	table.insert(a.log, 1, { t = now(), m = m })
	while #a.log > 40 do table.remove(a.log) end
end
WS.AddLog = addLog

-- maxFee: the most the joiner agreed to pay. Returns record, feeCharged (audit L2: charge the record's fee, never twice)
function WS.Join(plr, id, who, maxFee, lv)
	local charged = 0
	local rec, err = WS.MutateAlliance(id, function(a)
		charged = 0
		local key = tostring(plr.UserId)
		if a.members[key] then return a, true end -- already in (a retried write): nothing to charge again
		local fee = a.joinFee or 0
		if fee > (maxFee or 0) then return nil, "The join fee just went up. Check it and try again." end
		local n = 0; for _ in pairs(a.members) do n += 1 end
		if a.disbanded then return nil, "That alliance has disbanded" end
		if n >= WS.MemberCap(a) then return nil, "That alliance is full" end
		if a.open == false then return nil, "That alliance is invite only" end
		a.members[key] = { name = who or plr.Name, role = "member", joined = now(), active = now(), lv = lv, wk = 0, tot = 0 }
		if fee > 0 then a.treasury = (a.treasury or 0) + fee end
		charged = fee
		addLog(a, (who or plr.Name) .. " joined")
		return a, true
	end)
	if not rec then return nil, err end
	return rec, charged
end

function WS.Leave(plr, id, who)
	return WS.MutateAlliance(id, function(a)
		local key = tostring(plr.UserId)
		local me = a.members[key]
		if not me then return a, true end
		a.members[key] = nil
		addLog(a, (who or plr.Name) .. " left")
		if me.role == "leader" then
			-- hand leadership to the longest-serving officer, else the longest-serving member
			local best, bestKey
			for k, m in pairs(a.members) do
				local score = (m.role == "officer" and 0 or 1e12) + (m.joined or 0)
				if not best or score < best then best, bestKey = score, k end
			end
			if bestKey then
				a.members[bestKey].role = "leader"; a.leader = tonumber(bestKey); a.leaderName = a.members[bestKey].name
				addLog(a, a.leaderName .. " now leads the alliance")
			else
				a.disbanded = true
				a.open = false
			end
		end
		return a, true
	end)
end

function WS.Role(a, userId) local m = a and a.members[tostring(userId)]; return m and m.role end
function WS.IsMember(aid, userId)
	local a = aid and WS.Alliances[aid]
	return a ~= nil and not a.disbanded and a.members[tostring(userId)] ~= nil
end

---------------------------------------------------------------- alliance progression (Kash 2 Oct: levels, rewards, quests)
-- Members earn alliance XP just by playing (laws, convoys, raids, sieges, bosses, donations). XP raises the alliance
-- LEVEL: more member slots, a cash bonus for everyone, and a reward each member claims for every level. Each week the
-- alliance gets 3 QUESTS sized to its member count; finishing one gives alliance XP and every member who helped a reward.
WS.AllyXp = { law = 1, convoy = 2, raid = 3, hit = 1, boss = 6, donate = 1 } -- XP per unit
WS.QuestPool = {
	{ key = "law", name = "Pass laws", per = 120 },
	{ key = "convoy", name = "Deliver convoys", per = 30 },
	{ key = "raid", name = "Win raids", per = 12 },
	{ key = "hit", name = "Land siege hits", per = 25 },
	{ key = "boss", name = "Defeat bosses", per = 2 },
	{ key = "donate", name = "Donate to the treasury", per = 40 },
}
WS.QuestXp = 600
WS.MaxLevel = 30
function WS.LevelXp(level) return math.floor(400 * level ^ 1.6 + 0.5) end
function WS.MemberCap(a) return math.min(40, AC.MaxMembers - 10 + 2 * ((a and a.level) or 1)) end -- 22 at level 1, 40 at 10
function WS.LevelBonus(level) return math.min(0.10, 0.01 * ((level or 1) - 1)) end -- +1% cash per level after 1, max +10%
function WS.LevelReward(level) return { gold = 5 + 3 * level, basic = (level % 5 == 0) and 1 or 0 } end
function WS.Week(t) return math.floor(((t or now()) + 3 * 86400) / 604800) end -- weeks start Monday 00:00 UTC

local function genQuests(a, week)
	local rng = Random.new(week * 7919 + #tostring(a.id or "") * 131 + (string.byte(a.id or "a") or 1))
	local pool = table.clone(WS.QuestPool)
	local n = math.max(5, a.count or 1)
	local list = {}
	for _ = 1, 3 do
		local q = table.remove(pool, rng:NextInteger(1, #pool))
		table.insert(list, { key = q.key, name = q.name, goal = q.per * n, prog = 0, by = {} })
	end
	return list
end
-- make sure the record is on this week's quests (called inside a mutation)
function WS.EnsureWeek(a)
	local w = WS.Week()
	if a.qweek ~= w then
		a.qweek = w
		a.count = 0; for _ in pairs(a.members or {}) do a.count += 1 end
		a.quests = genQuests(a, w)
		for _, m in pairs(a.members or {}) do m.wk = 0 end
	end
	a.level = a.level or 1
	a.xp = a.xp or 0
end

local pendingTreasury = {} -- [aid] = amount
local pendingProg = {} -- [aid] = { xp = n, mem = { [uid] = pts }, q = { [kind] = { n = n, by = { [uid] = n } } } }
function WS.Credit(aid, amount)
	if not aid or amount ~= amount or amount <= 0 or amount == math.huge then return end
	pendingTreasury[aid] = (pendingTreasury[aid] or 0) + amount
end
function WS.AddProgress(aid, uid, kind, n)
	n = tonumber(n) or 0
	if not aid or n ~= n or n <= 0 or n == math.huge or not WS.AllyXp[kind] then return end
	local pp = pendingProg[aid] or { xp = 0, mem = {}, q = {} }
	pendingProg[aid] = pp
	local pts = n * WS.AllyXp[kind]
	uid = tostring(uid)
	pp.xp += pts
	pp.mem[uid] = (pp.mem[uid] or 0) + pts
	local qk = pp.q[kind] or { n = 0, by = {} }
	pp.q[kind] = qk
	qk.n += n
	qk.by[uid] = (qk.by[uid] or 0) + n
end
-- apply a progress batch to a record (inside a mutation). Returns true when something worth announcing happened.
local function applyProg(a, pp)
	WS.EnsureWeek(a)
	local loud = false
	a.xp += pp.xp
	while a.level < WS.MaxLevel and a.xp >= WS.LevelXp(a.level) do
		a.xp -= WS.LevelXp(a.level)
		a.level += 1
		addLog(a, "The alliance reached LEVEL " .. a.level .. "!")
		loud = true
	end
	for uid, pts in pairs(pp.mem) do
		local m = a.members[uid]
		if m then m.wk = (m.wk or 0) + pts; m.tot = (m.tot or 0) + pts; m.active = now() end
	end
	for _, q in ipairs(a.quests or {}) do
		local add = pp.q[q.key]
		if add and not q.done then
			q.prog = math.min(q.goal, q.prog + add.n)
			for uid, n in pairs(add.by) do if a.members[uid] then q.by[uid] = (q.by[uid] or 0) + n end end
			if q.prog >= q.goal then
				q.done = now()
				a.xp += WS.QuestXp
				addLog(a, "Quest complete: " .. q.name .. "!")
				loud = true
				while a.level < WS.MaxLevel and a.xp >= WS.LevelXp(a.level) do
					a.xp -= WS.LevelXp(a.level); a.level += 1
					addLog(a, "The alliance reached LEVEL " .. a.level .. "!")
				end
			end
		end
	end
	return loud
end

function WS.FlushTreasury()
	local batch, prog = pendingTreasury, pendingProg
	pendingTreasury, pendingProg = {}, {}
	local ids = {}
	for aid in pairs(batch) do ids[aid] = true end
	for aid in pairs(prog) do ids[aid] = true end
	for aid in pairs(ids) do
		local amt, pp = batch[aid] or 0, prog[aid]
		local loud = false
		local rec, err = WS.MutateAlliance(aid, function(a)
			loud = false
			a.treasury = (a.treasury or 0) + amt
			if pp then loud = applyProg(a, pp) else WS.EnsureWeek(a) end
			return a, true
		end, true)
		if not rec and err ~= "Alliance not found" then
			if amt > 0 then pendingTreasury[aid] = (pendingTreasury[aid] or 0) + amt end
			if pp then
				local cur = pendingProg[aid]
				if not cur then pendingProg[aid] = pp
				else cur.xp += pp.xp
					for u, v in pairs(pp.mem) do cur.mem[u] = (cur.mem[u] or 0) + v end
					for k, q in pairs(pp.q) do local c = cur.q[k] or { n = 0, by = {} }; cur.q[k] = c; c.n += q.n; for u, v in pairs(q.by) do c.by[u] = (c.by[u] or 0) + v end end
				end
			end
		elseif rec and loud then
			publish("a", aid, rec.rev) -- level-ups and finished quests reach every server at once
		end
	end
end

---------------------------------------------------------------- sieges
-- attacker hits city i for dmg; returns result table or nil, message
function WS.Attack(i, aid, dmg, plrName)
	local a = WS.Alliances[aid]
	if not a then return nil, "Join an alliance to fight for cities" end
	local held = 0
	for _, c in pairs(WS.Cities) do if c.owner == aid then held += 1 end end
	local result
	local saved = Store.MapUpdate(CITY_MAP, "c" .. i, function(c)
		c = c or defaultCity(i)
		if c.owner == aid then result = { err = "Your alliance already holds this city" }; return nil end
		if (c.prot or 0) > now() then result = { err = "This city is protected for " .. math.ceil((c.prot - now()) / 60) .. " more minutes" }; return nil end
		if held >= AC.MaxCities then result = { err = "Your alliance already holds " .. AC.MaxCities .. " cities, the most allowed" }; return nil end
		c.contrib = c.contrib or {}
		local mine = c.contrib[aid]
		if mine and now() - mine.t > AC.ContributionResetSeconds then mine = nil end
		mine = mine or { d = 0, t = now(), n = a.name }
		mine.d += dmg; mine.t = now(); mine.n = a.name
		c.contrib[aid] = mine
		c.hp = math.max(0, (c.hp or WS.CityGarrison(i)) - dmg)
		result = { hp = c.hp, maxHp = c.maxHp, captured = false }
		if c.hp <= 0 then
			local best, bestId = -1, nil
			for id, v in pairs(c.contrib) do
				if id ~= c.owner and now() - v.t <= AC.ContributionResetSeconds and v.d > best then best, bestId = v.d, id end
			end
			local winner = WS.Alliances[bestId]
			local fort = (winner and winner.up and winner.up.fort) or 0
			local g = math.floor(WS.CityGarrison(i) * (1 + 0.10 * fort))
			result.captured = true; result.winner = bestId; result.prevOwner = c.owner
			c.owner = bestId; c.hp = g; c.maxHp = g; c.prot = now() + AC.ProtectSeconds; c.contrib = {}; c.tax = 5; c.taxSet = 0; c.rent = 0; c.rentSet = 0
		end
		return c
	end)
	if not result then return nil, "The city could not be reached. Try again." end
	if result.err then return nil, result.err end
	if saved == nil then return nil, "The city could not be reached. Try again." end
	WS.RefreshCity(i)
	publish("c", i)
	if result.captured then
		local cityName = World.Cities[i].name
		if result.winner then WS.MutateAlliance(result.winner, function(x) addLog(x, "Captured " .. cityName .. "!"); return x, true end) end
		if result.prevOwner then WS.MutateAlliance(result.prevOwner, function(x) addLog(x, "Lost " .. cityName); return x, true end) end
		backupCities()
	end
	return result
end

function WS.Reinforce(i, aid, amount)
	local result
	local saved = Store.MapUpdate(CITY_MAP, "c" .. i, function(c)
		if not c or c.owner ~= aid then result = { err = "Your alliance does not hold this city" }; return nil end
		local cap = WS.CityGarrison(i) * Military.GarrisonCapMult
		if c.hp >= cap then result = { err = "The garrison is already at full strength" }; return nil end
		c.hp = math.min(cap, c.hp + amount); c.maxHp = math.max(c.maxHp or 0, c.hp)
		result = { hp = c.hp, cap = cap }
		return c
	end)
	if not result then return nil, "The city could not be reached. Try again." end
	if result.err then return nil, result.err end
	if saved == nil then return nil, "The city could not be reached. Try again." end
	WS.RefreshCity(i)
	publish("c", i)
	return result
end

function WS.SetTax(i, aid, pct)
	pct = tonumber(pct) or 0
	if pct ~= pct then pct = 0 end
	pct = math.clamp(math.floor(pct), 0, AC.TaxMax)
	local result
	local saved = Store.MapUpdate(CITY_MAP, "c" .. i, function(c)
		if not c or c.owner ~= aid then result = { err = "Your alliance does not hold this city" }; return nil end
		if (c.taxSet or 0) + AC.TaxChangeCooldown > now() then
			result = { err = "Tax can change once a day. Next change in " .. math.ceil(((c.taxSet or 0) + AC.TaxChangeCooldown - now()) / 3600) .. "h" }
			return nil
		end
		c.tax = pct; c.taxSet = now()
		result = { tax = pct }
		return c
	end)
	if not result then return nil, "The city could not be reached. Try again." end
	if result.err then return nil, result.err end
	if saved == nil then return nil, "The city could not be reached. Try again." end
	WS.RefreshCity(i)
	publish("c", i)
	return result
end

---------------------------------------------------------------- rent (Kash 18:49)
-- The alliance holding a capital sets a rent: a % of the property income of everyone who lives there (their home).
-- Max rent grows with the city's tier. It is silent: residents are never told.
function WS.SetRent(i, aid, pct)
	pct = tonumber(pct) or 0
	if pct ~= pct then pct = 0 end
	local cap = Config.Rent.Max[World.Cities[i].tier] or 0
	pct = math.clamp(math.floor(pct), 0, cap)
	local result
	local saved = Store.MapUpdate(CITY_MAP, "c" .. i, function(c)
		if not c or c.owner ~= aid then result = { err = "Your alliance does not hold this city" }; return nil end
		if (c.rentSet or 0) + AC.TaxChangeCooldown > now() then
			result = { err = "Rent can change once a day. Next change in " .. math.ceil(((c.rentSet or 0) + AC.TaxChangeCooldown - now()) / 3600) .. "h" }
			return nil
		end
		c.rent = pct; c.rentSet = now()
		result = { rent = pct }
		return c
	end)
	if not result then return nil, "The city could not be reached. Try again." end
	if result.err then return nil, result.err end
	if saved == nil then return nil, "The city could not be reached. Try again." end
	WS.RefreshCity(i)
	publish("c", i)
	return result
end
-- rent rate a player pays (fraction), 0 for new players, their own alliance's cities and unowned cities
function WS.RentFor(d, uid)
	local c = d.home and WS.Cities[d.home]
	if not c or not c.owner or (c.rent or 0) <= 0 then return 0, nil end
	if c.owner == d.alliance and (not uid or WS.IsMember(d.alliance, uid)) then return 0, nil end
	if os.time() - (d.created or os.time()) < Config.Rent.GraceHours * 3600 then return 0, nil end
	return c.rent / 100, c.owner
end

---------------------------------------------------------------- city wants (Kash 17:22)
-- Each capital wants 3 goods. Every convoy sent there with a wanted good is a tick; after T.WantTicks ticks the city
-- has enough of it and asks for something else. Pay is locked when the convoy leaves, so it never changes en route.
WS.Wants = {}
local Trade = require(RS.Shared.Trade)
local function initWants()
	for i, C in ipairs(World.Cities) do WS.Wants[i] = { list = table.clone(C.demand), ticks = {} } end
end
function WS.WantsOf(i) return WS.Wants[i] and WS.Wants[i].list or World.Cities[i].demand end
-- Wants are game wide (Kash 2 Oct 23:31): every server shares one copy in a MemoryStore hash map; a server that
-- changes a want tells the others through MessagingService, and every server re-reads all wants each minute.
local WANT_MAP = "IC_Wants_v1" .. SUFFIX
local function wantDefault(i) return { list = table.clone(World.Cities[i].demand), ticks = {} } end
function WS.RefreshWant(i)
	local w = Store.MapGet(WANT_MAP, "w" .. i)
	if type(w) == "table" and type(w.list) == "table" then
		local old = WS.Wants[i] and table.concat(WS.Wants[i].list, ",")
		WS.Wants[i] = w
		w.ticks = w.ticks or {}
		if old ~= table.concat(w.list, ",") then WS.Changed:Fire("w", i) end
	end
end
function WS.TickWant(i, good)
	local w = WS.Wants[i]
	if not w or not table.find(w.list, good) then return end
	local C = World.Cities[i]
	task.spawn(function()
		local changed = false
		local new = Store.MapUpdate(WANT_MAP, "w" .. i, function(old)
			local cur = (type(old) == "table" and type(old.list) == "table") and old or wantDefault(i)
			cur.ticks = cur.ticks or {}
			changed = false
			if not table.find(cur.list, good) then return cur end
			cur.ticks[good] = (cur.ticks[good] or 0) + 1
			if cur.ticks[good] >= Trade.WantTicks then
				cur.ticks[good] = nil
				-- pick a new good this city does not export and does not already want
				local pool = {}
				for k in pairs(Trade.Goods) do
					if k ~= "mixed" and not table.find(C.exports, k) and not table.find(cur.list, k) then table.insert(pool, k) end
				end
				table.sort(pool)
				if #pool > 0 then cur.list[table.find(cur.list, good)] = pool[math.random(1, #pool)]; changed = true end
			end
			return cur
		end)
		if type(new) == "table" then WS.Wants[i] = new end
		if changed then publish("w", i) end
	end)
end

---------------------------------------------------------------- popular capitals (Kash 2 Oct)
-- counts of players per home capital in an OrderedDataStore; the top 6 are recommended in onboarding
local Config = require(RS.Shared.Config)
WS.Popular = table.clone(Config.PopularCapitals)
local function popStore() return Store.ODS("IC_HomePop" .. SUFFIX) end
function WS.HomeMoved(old, new)
	if not Store.Online then return end
	task.spawn(function()
		local ods = popStore()
		if new and World.Cities[new] then pcall(ods.IncrementAsync, ods, tostring(new), 1) end
		if old and old ~= new and World.Cities[old] then pcall(ods.IncrementAsync, ods, tostring(old), -1) end
	end)
end
function WS.RefreshPopular()
	if not Store.Online then return end
	local ods = popStore()
	local ok, pages = pcall(function() return ods:GetSortedAsync(false, 6) end)
	if not ok then return end
	local list, total = {}, 0
	for _, e in ipairs(pages:GetCurrentPage()) do
		local i = tonumber(e.key)
		if i and World.Cities[i] and e.value > 0 then table.insert(list, i); total += e.value end
	end
	if total < (Config.PopularMinPlayers or 30) then return end -- too few players yet: keep the starting list
	for _, i in ipairs(Config.PopularCapitals) do if #list >= 6 then break end; if not table.find(list, i) then table.insert(list, i) end end
	WS.Popular = list
end

---------------------------------------------------------------- snapshot for clients
function WS.PublicState()
	local cities = {}
	for i = 1, #World.Cities do
		local c = WS.Cities[i] or defaultCity(i)
		cities[i] = publicCity(i, c)
		cities[i].wants = WS.WantsOf(i)
	end
	local index = {}
	for id, s in pairs(WS.Index) do index[id] = s end
	return { cities = cities, alliances = index, t = now(), popular = WS.Popular }
end

---------------------------------------------------------------- start
function WS.Start()
	for i = 1, #World.Cities do WS.Cities[i] = defaultCity(i) end
	initWants()
	task.spawn(function()
		while true do
			for i = 1, #World.Cities do task.spawn(pcall, WS.RefreshWant, i) end
			task.wait(60)
		end
	end)
	task.spawn(function() while true do pcall(WS.RefreshPopular); task.wait(600) end end)
	task.spawn(function()
		restoreCities()
		WS.RefreshAllCities()
		WS.RefreshIndex()
		WS.Changed:Fire("all")
	end)
	if Store.Online then
		pcall(function()
			MessagingService:SubscribeAsync("IC_World" .. SUFFIX, function(msg)
				local d = msg.Data
				if type(d) ~= "table" then return end
				if d.k == "c" and tonumber(d.id) then pcall(WS.RefreshCity, tonumber(d.id)); WS.Changed:Fire("c", d.id)
				elseif d.k == "w" and tonumber(d.id) and World.Cities[tonumber(d.id)] then pcall(WS.RefreshWant, tonumber(d.id))
				elseif d.k == "a" and type(d.id) == "string" then
					-- only read alliances someone here belongs to, and only when the message is newer (audit M5)
					local cur = WS.Alliances[d.id]
					if (cur or WS.Interest(d.id)) and not (cur and d.r and (cur.rev or 0) >= d.r) then pcall(WS.LoadAlliance, d.id) end
					WS.Changed:Fire("a", d.id)
				end
			end)
		end)
	end
	-- every 90 s re-read the alliances people in this server belong to: a dropped message never leaves a kicked
	-- member with stipend, perks or rent exemptions for the rest of the session (audit M4)
	task.spawn(function()
		while true do
			task.wait(90)
			for id in pairs(WS.Alliances) do
				if WS.Interest(id) then
					local ok = pcall(WS.LoadAlliance, id)
					if ok then WS.Changed:Fire("a", id) end
				end
			end
		end
	end)
	task.spawn(function()
		local t = 0
		while true do
			task.wait(AC.TreasuryFlushSeconds)
			t += AC.TreasuryFlushSeconds
			WS.FlushTreasury()
			WS.RefreshAllCities()
			if t % 120 == 0 then WS.RefreshIndex(); WS.Changed:Fire("all") end
			if t % 600 == 0 then backupCities() end
		end
	end)
end
return WS
