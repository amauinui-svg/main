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
	{ key = "stipend", name = "STATE STIPEND", icon = "icon_coins", max = 10, desc = "Every member is paid an hourly wage (more for active members)" },
	{ key = "trade", name = "TRADE NETWORK", icon = "icon_globe", max = 5, desc = "+3% convoy pay per level for all members" },
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
	local snap = {}
	for i, c in pairs(WS.Cities) do if c.owner then snap[tostring(i)] = c end end
	Store.Update(Store.DS(WORLD_DS), "cities", function() return snap end)
end

---------------------------------------------------------------- alliances
local function summary(a)
	return { name = a.name, tag = a.tag, color = a.color, members = a.count or 0, level = a.level or 1, open = a.open ~= false, leader = a.leaderName,
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
local function publish(kind, id)
	if Store.Online then pcall(function() MessagingService:PublishAsync("IC_World" .. SUFFIX, { k = kind, id = id }) end) end
	WS.Changed:Fire(kind, id)
end

-- mutate an alliance record atomically. fn(a) returns (a, result) or (nil, errorMessage)
function WS.MutateAlliance(id, fn)
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
		publish("a", id)
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
	end
	local id = HttpService:GenerateGUID(false):sub(1, 8)
	local a = {
		id = id, name = name, tag = tag, color = color, created = now(), open = true,
		leader = plr.UserId, leaderName = who or plr.Name,
		members = { [tostring(plr.UserId)] = { name = who or plr.Name, role = "leader", joined = now(), active = now() } },
		treasury = 0, up = { stipend = 0, trade = 0, war = 0, fort = 0 }, log = {}, count = 1,
	}
	table.insert(a.log, { t = now(), m = (who or plr.Name) .. " founded the alliance" })
	local ok = Store.Update(Store.DS(ALLY_DS), "a_" .. id, function() return a end)
	if not ok then return nil, "Could not save the alliance. Try again." end
	WS.Alliances[id] = a
	WS.Index[id] = summary(a)
	writeIndex(id, WS.Index[id])
	publish("a", id)
	return a
end

local function addLog(a, m)
	a.log = a.log or {}
	table.insert(a.log, 1, { t = now(), m = m })
	while #a.log > 40 do table.remove(a.log) end
end
WS.AddLog = addLog

function WS.Join(plr, id, who, fee, lv)
	return WS.MutateAlliance(id, function(a)
		if (a.joinFee or 0) > (fee or 0) then return nil, "The join fee just went up. Check it and try again." end
		local n = 0; for _ in pairs(a.members) do n += 1 end
		if a.disbanded then return nil, "That alliance has disbanded" end
		if n >= AC.MaxMembers then return nil, "That alliance is full" end
		if a.open == false then return nil, "That alliance is invite only" end
		a.members[tostring(plr.UserId)] = { name = who or plr.Name, role = "member", joined = now(), active = now(), lv = lv }
		if (fee or 0) > 0 then a.treasury = (a.treasury or 0) + fee end
		addLog(a, (who or plr.Name) .. " joined")
		return a, true
	end)
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

---------------------------------------------------------------- treasury (batched per server)
local pendingTreasury = {} -- [aid] = amount
function WS.Credit(aid, amount)
	if not aid or amount ~= amount or amount <= 0 or amount == math.huge then return end
	pendingTreasury[aid] = (pendingTreasury[aid] or 0) + amount
end
function WS.FlushTreasury()
	local batch = pendingTreasury
	pendingTreasury = {}
	for aid, amt in pairs(batch) do
		local rec, err = WS.MutateAlliance(aid, function(a) a.treasury = (a.treasury or 0) + amt; return a, true end)
		if not rec and err ~= "Alliance not found" then pendingTreasury[aid] = (pendingTreasury[aid] or 0) + amt end
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
function WS.RentFor(d)
	local c = d.home and WS.Cities[d.home]
	if not c or not c.owner or (c.rent or 0) <= 0 then return 0, nil end
	if c.owner == d.alliance then return 0, nil end
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
function WS.TickWant(i, good)
	local w = WS.Wants[i]
	if not w or not table.find(w.list, good) then return end
	w.ticks[good] = (w.ticks[good] or 0) + 1
	if w.ticks[good] < Trade.WantTicks then return end
	w.ticks[good] = nil
	-- pick a new good this city does not export and does not already want
	local C = World.Cities[i]
	local pool = {}
	for k, g in pairs(Trade.Goods) do
		if k ~= "mixed" and not table.find(C.exports, k) and not table.find(w.list, k) then table.insert(pool, k) end
	end
	table.sort(pool)
	if #pool == 0 then return end
	local idx = table.find(w.list, good)
	w.list[idx] = pool[math.random(1, #pool)]
	WS.Changed:Fire("w", i)
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
	return { cities = cities, alliances = index, t = now() }
end

---------------------------------------------------------------- start
function WS.Start()
	for i = 1, #World.Cities do WS.Cities[i] = defaultCity(i) end
	initWants()
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
				elseif d.k == "a" and d.id then pcall(WS.LoadAlliance, d.id); WS.Changed:Fire("a", d.id) end
			end)
		end)
	end
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
