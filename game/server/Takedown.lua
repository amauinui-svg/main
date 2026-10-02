-- Alliance Weekly Takedown (Kash 1 Oct 16:47, modelled on the reference game's Family > Takedown).
-- Every alliance attacks the same weekly enemy stronghold: 5 stages, 3 enemies each (stage 5 is a single boss).
-- Each member gets 10 free attacks (+1 per hour, max 10); Takedown Tickets (Seals shop) are used after that.
-- Damage, the leaderboard and the recent attacks log are shared through the alliance record. Hits are batched per
-- server and flushed every few seconds so many players hitting at once never fights over the DataStore.
local RS = game:GetService("ReplicatedStorage")
local R = require(RS.Shared.Rules)
local TK = require(RS.Shared.Tasks)

local TD = {}
local PS, WS

TD.FreeMax = 10
TD.FreeEvery = 3600
TD.BigHitChance = 0.1
TD.HitsPerEnemyPerMember = 1.9 -- tuned so the free attacks clear about 2/3 of the stronghold
TD.StageGrowth = 1.25

TD.Targets = {
	{ name = "Iron Citadel of Varnia", stages = { "Outer Gate", "Barracks Yard", "The Armory", "War Room", "Warlord Kessel" } },
	{ name = "Castellan Fortress", stages = { "Fortress Gates", "Rose Courtyard", "Grand Hall", "The Treasury Vault", "Duke Castellan" } },
	{ name = "Red Harbor Stronghold", stages = { "Dockside Gate", "Customs House", "Cannon Battery", "Admiralty", "Admiral Morvane" } },
	{ name = "The Black Palace", stages = { "Palace Gates", "Guard Barracks", "Hall of Mirrors", "Throne Antechamber", "The Usurper Queen" } },
}
-- enemy line-up per stage: {name, image}
TD.Enemies = {
	{ { "Gate Guard", "enemy_guard" }, { "Street Soldier", "enemy_soldier" }, { "Gate Guard", "enemy_guard" } },
	{ { "Rifleman", "enemy_soldier" }, { "Sergeant", "enemy_guard" }, { "Rifleman", "enemy_soldier" } },
	{ { "Elite Guard", "enemy_guard" }, { "Grenadier", "enemy_soldier" }, { "Elite Guard", "enemy_guard" } },
	{ { "Royal Guard", "enemy_guard" }, { "Colonel", "enemy_general" }, { "Royal Guard", "enemy_guard" } },
	{ { "", "enemy_general" } }, -- the boss uses the stage name
}
TD.StageRewards = {
	{ seals = 3 },
	{ seals = 4, basicCrates = 1 },
	{ seals = 5, basicCrates = 2 },
	{ seals = 6, basicCrates = 2 },
	{ seals = 10, limitedCrates = 1 },
}

local pending = {} -- [aid] = { hits = { {e, dmg, who, uid, big} } }

function TD.Init(ps, ws) PS, WS = ps, ws end

local function week() return TK.Week() end
function TD.Target(w) local n = #TD.Targets; return TD.Targets[((w or week()) % n) + 1] end

local function enemyHp(td, stage, members)
	local base = math.max(6, members * TD.HitsPerEnemyPerMember) * td.ref * TD.StageGrowth ^ (stage - 1)
	if stage == 5 then base *= 3 end
	return math.floor(base)
end
local function newStage(td, stage, members)
	td.stage = stage
	td.hp, td.max = {}, {}
	for i = 1, #TD.Enemies[stage] do
		local h = enemyHp(td, stage, members)
		td.hp[i] = h; td.max[i] = h
	end
end
-- the alliance's takedown for this week (creates or rolls over inside a MutateAlliance)
local function ensure(a, refAtk)
	local w = week()
	if not a.td or a.td.week ~= w then
		a.td = { week = w, ref = math.max(10, refAtk or 10), dmg = {}, log = {}, cleared = 0 }
		newStage(a.td, 1, a.count or 1)
	end
	return a.td
end

-- applies a batch of hits to the record. Hits on dead enemies roll over to the next living one, then the next stage.
local function apply(a, hits)
	local td = ensure(a, hits[1] and hits[1].ref)
	for _, h in ipairs(hits) do
		if td.stage > 5 then break end
		local e = h.e
		if not td.hp[e] or td.hp[e] <= 0 then
			e = nil
			for i, hp in ipairs(td.hp) do if hp > 0 then e = i; break end end
		end
		if e then
			local dealt = math.min(td.hp[e], h.dmg)
			td.hp[e] -= dealt
			td.dmg[h.uid] = (td.dmg[h.uid] or 0) + h.dmg
			local who = TD.Enemies[td.stage][e][1]
			if who == "" then who = TD.Target(td.week).stages[5] end
			table.insert(td.log, 1, { t = h.t, who = h.who, e = who, dmg = h.dmg, big = h.big })
			while #td.log > 50 do table.remove(td.log) end
			local alive = false
			for _, hp in ipairs(td.hp) do if hp > 0 then alive = true end end
			if not alive then
				td.cleared = td.stage
				WS.AddLog(a, "Takedown stage " .. td.stage .. " cleared: " .. TD.Target(td.week).stages[td.stage])
				if td.stage < 5 then newStage(td, td.stage + 1, a.count or 1) else td.stage = 6 end
			end
		end
	end
	return a
end

function TD.Flush()
	for aid, q in pairs(pending) do
		pending[aid] = nil
		local hits = q.hits
		local rec, err = WS.MutateAlliance(aid, function(a) return apply(a, hits), true end)
		if not rec and err ~= "Alliance not found" then
			pending[aid] = pending[aid] or { hits = {} }
			for _, h in ipairs(hits) do table.insert(pending[aid].hits, h) end
		end
	end
end

-- free attacks regenerate 1 per hour
local function regen(d)
	local t = os.time()
	d.td = d.td or { free = TD.FreeMax, t = t, claimed = 0, week = week() }
	if d.td.week ~= week() then d.td.week = week(); d.td.claimed = 0 end
	if d.td.free >= TD.FreeMax then d.td.t = t; return d.td end
	local n = math.floor((t - d.td.t) / TD.FreeEvery)
	if n > 0 then d.td.free = math.min(TD.FreeMax, d.td.free + n); d.td.t += n * TD.FreeEvery end
	return d.td
end
TD.Regen = regen

-- the view the client draws: record state + this server's unflushed hits
function TD.View(p)
	local d = p.data
	local mine = regen(d)
	local a = d.alliance and WS.Alliances[d.alliance]
	local v = { week = week(), free = mine.free, freeMax = TD.FreeMax, nextFree = mine.free < TD.FreeMax and (mine.t + TD.FreeEvery - os.time()) or 0,
		tickets = d.tickets or 0, claimed = mine.claimed, endsIn = (week() + 1) * 7 * 86400 - 3 * 86400 - os.time() }
	v.target = TD.Target()
	if not a then return v end
	local copy = { td = a.td and table.clone(a.td) or nil, count = a.count }
	if copy.td then copy.td = { week = a.td.week, ref = a.td.ref, dmg = table.clone(a.td.dmg), log = table.clone(a.td.log), cleared = a.td.cleared,
		stage = a.td.stage, hp = table.clone(a.td.hp), max = table.clone(a.td.max) } end
	if pending[d.alliance] and copy.td then apply(copy, pending[d.alliance].hits) end
	local td = copy.td
	if not td or td.week ~= week() then
		v.stage, v.cleared, v.enemies, v.log, v.board = 1, 0, nil, {}, {}
		return v
	end
	v.stage, v.cleared, v.log = td.stage, td.cleared, td.log
	if td.stage <= 5 then
		v.enemies = {}
		for i, e in ipairs(TD.Enemies[td.stage]) do
			v.enemies[i] = { name = e[1] ~= "" and e[1] or v.target.stages[5], img = e[2], hp = td.hp[i], max = td.max[i] }
		end
		local tot, have = 0, 0
		for i in ipairs(td.max) do tot += td.max[i]; have += td.hp[i] end
		v.stageHp, v.stageMax = have, tot
	end
	local board = {}
	for uid, dmg in pairs(td.dmg) do
		local m = a.members[uid]
		table.insert(board, { uid = uid, name = m and m.name or "Former member", dmg = math.floor(dmg) })
	end
	table.sort(board, function(x, y) return x.dmg > y.dmg end)
	v.board = board
	v.myDmg = math.floor(td.dmg[tostring(p.userId)] or 0)
	for i, b in ipairs(board) do if b.uid == tostring(p.userId) then v.myRank = i end end
	return v
end

-- one attack. e = enemy index the player clicked
function TD.Attack(plr, p, e)
	local d = p.data
	if not d.alliance or not WS.Alliances[d.alliance] then return { ok = false, msg = "Join an alliance to take part in the Takedown" } end
	local mine = regen(d)
	local useTicket = false
	if mine.free <= 0 then
		if (d.tickets or 0) <= 0 then return { ok = false, msg = "no_attacks" } end
		useTicket = true
	end
	local view = TD.View(p)
	if not view.enemies then
		if view.stage and view.stage > 5 then return { ok = false, msg = "Your alliance cleared the whole Takedown this week!" } end
	end
	if useTicket then d.tickets -= 1 else
		if mine.free >= TD.FreeMax then mine.t = os.time() end
		mine.free -= 1
	end
	local atk = PS.Power(p)
	local big = math.random() < TD.BigHitChance
	local dmg = math.floor(atk * (0.85 + math.random() * 0.3) * (big and 2.2 or 1))
	pending[d.alliance] = pending[d.alliance] or { hits = {} }
	table.insert(pending[d.alliance].hits, { e = tonumber(e) or 1, dmg = dmg, who = d.name ~= "" and d.name or plr.Name, uid = tostring(plr.UserId), big = big, t = os.time(), ref = atk })
	PS.TaskProgress(p, "hits", 1)
	PS.TaskProgress(p, "siege", 1)
	return { ok = true, dmg = dmg, big = big, ticket = useTicket }
end

-- claim rewards for every stage the alliance has cleared (only if you hit at least once this week)
function TD.Claim(plr, p)
	local d = p.data
	local mine = regen(d)
	local view = TD.View(p)
	if (view.myDmg or 0) <= 0 then return { ok = false, msg = "Attack at least once this week to earn Takedown rewards" } end
	local got = { seals = 0, basicCrates = 0, limitedCrates = 0 }
	local any = false
	for s = (mine.claimed or 0) + 1, view.cleared or 0 do
		local r = TD.StageRewards[s]
		got.seals += r.seals or 0; got.basicCrates += r.basicCrates or 0; got.limitedCrates += r.limitedCrates or 0
		any = true
	end
	if not any then return { ok = false, msg = "Clear the next stage with your alliance to earn more" } end
	mine.claimed = view.cleared
	d.seals += got.seals; d.crates.basic += got.basicCrates; d.crates.limited += got.limitedCrates
	return { ok = true, reward = got }
end

function TD.Start()
	task.spawn(function()
		while true do
			task.wait(5)
			pcall(TD.Flush)
		end
	end)
end
return TD
