-- Actions: every request a client can make. Each one re-checks the rules; the client is never trusted.
local RS = game:GetService("ReplicatedStorage")
local D = require(RS.Shared.GameData)
local R = require(RS.Shared.Rules)
local T = require(RS.Shared.Trade)
local M = require(RS.Shared.Military)
local World = require(RS.Shared.World)
local Config = require(RS.Shared.Config)
local WS = require(script.Parent.WorldService)

local A = {}
local PS, MK
function A.Init(ps, mk) PS, MK = ps, mk end

local function ok(t) t = t or {}; t.ok = true; return t end
local function no(msg) return { ok = false, msg = msg } end
local function int(x, lo, hi)
	x = tonumber(x)
	if not x or x ~= x or x % 1 ~= 0 then return nil end
	if (lo and x < lo) or (hi and x > hi) then return nil end
	return x
end
local function now() return os.time() end

A.list = {}
local act = A.list

function act.sync(plr, p)
	RS.Remotes.Sync:FireClient(plr, "world", WS.PublicState())
	return ok()
end

---------------------------------------------------------------- onboarding (name, flag, ideology, home capital)
function act.onboard(plr, p, a)
	local d = p.data
	if d.onboarded then return no("Already set up") end
	local name = tostring(a.name or ""):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
	if #name < 3 or #name > 22 then return no("Country name must be 3 to 22 letters") end
	if name:find("[^%w %-'%.]") then return no("Use letters, numbers, spaces, - ' . only") end
	local f = WS.Filter(name, plr.UserId)
	if not f or f ~= name then return no("That name is not allowed. Try another.") end
	local flag = type(a.flag) == "table" and a.flag or {}
	local layout = table.find(R.FlagLayouts, flag.l) and flag.l or "h3"
	local cols = {}
	for i = 1, 3 do
		local c = type(flag.c) == "table" and flag.c[i]
		cols[i] = table.find(R.FlagColors, c) and c or R.FlagColors[i]
	end
	local ideo = R.IdeologyByKey[a.ideo] and a.ideo or "republic"
	local home = int(a.home, 1, #World.Cities)
	if not home then return no("Pick a home capital") end
	d.name, d.flag, d.ideo, d.home, d.onboarded = name, { l = layout, c = cols }, ideo, home, true
	for _, c in ipairs(d.convoys) do if not c.to then c.at = home end end
	PS.EnsureConvoys(p)
	return ok()
end

---------------------------------------------------------------- laws
function act.passLaw(plr, p, a)
	local d = p.data
	local i = int(a.i, 1, #D.Laws)
	if not i then return no("Unknown law") end
	local L = D.Laws[i]
	if d.lv < L.lvl then return no("Unlocks at level " .. L.lvl) end
	if d.inf < L.cost then return no("Not enough Influence") end
	local t = os.clock()
	if t - p.lastAct < 0.06 then return no("Too fast") end
	p.lastAct = t
	local key = tostring(i)
	local before = d.passes[key] or 0
	local mods = PS.Mods(p)
	d.inf -= L.cost
	local cash = PS.Earn(p, R.LawCash(i, before, mods.law) * (0.9 + math.random() * 0.2), "law")
	local xp = R.LawXp(i, before)
	d.passes[key] = before + 1
	d.stats.laws += 1
	PS.TaskProgress(p, "laws", 1)
	local tb, ta = R.MasteryTier(before), R.MasteryTier(before + 1)
	if ta > tb then
		PS.Note(p, { kind = "mastery", law = L.n, tier = ta, pct = R.MasteryPct[ta + 1], point = ta == 3 })
	end
	PS.AddXp(p, xp)
	return ok({ cash = cash, xp = xp })
end

---------------------------------------------------------------- properties (Your Block + Build)
function act.build(plr, p, a)
	local d = p.data
	local i = int(a.i, 1, #D.Props)
	if not i then return no("Unknown property") end
	local P = D.Props[i]
	if d.lv < P.lvl then return no("Unlocks at level " .. P.lvl) end
	local lot = int(a.lot, 1, PS.LotsMax(p))
	if lot and d.lots[lot] and d.lots[lot] > 0 then return no("That lot is taken. Demolish it first.") end
	if not lot then
		for k = 1, PS.LotsMax(p) do if not d.lots[k] or d.lots[k] == 0 then lot = k; break end end
	end
	if not lot then return no("Every lot is full. Demolish a building or get more lots in Skill Points.") end
	local owned = R.CountProps(d.lots)[i] or 0
	local cost = R.PropCost(i, owned)
	if d.cash < cost then return no("Not enough cash") end
	d.cash -= cost
	for k = #d.lots + 1, lot - 1 do d.lots[k] = 0 end
	d.lots[lot] = i
	d.stats.built += 1
	PS.TaskProgress(p, "build", 1)
	return ok({ cost = cost, lot = lot })
end

function act.demolish(plr, p, a)
	local d = p.data
	local lot = int(a.lot, 1, #d.lots)
	if not lot or not d.lots[lot] or d.lots[lot] == 0 then return no("That lot is empty") end
	local i = d.lots[lot]
	local owned = R.CountProps(d.lots)[i] or 1
	local refund = math.floor(R.PropCost(i, owned - 1) * R.DemolishRefund)
	d.lots[lot] = 0
	d.cash += refund
	return ok({ refund = refund })
end

---------------------------------------------------------------- skill points
function act.skill(plr, p, a)
	local d = p.data
	local s = R.SkillByKey[a.key]
	if not s then return no("Unknown skill") end
	local n = d.sk[s.key] or 0
	local cost = s.cost(n)
	if PS.SkillFree(d) < cost then return no("Not enough skill points") end
	d.sk[s.key] = n + 1
	if s.key == "lot" then PS.EnsureConvoys(p) end
	return ok()
end

---------------------------------------------------------------- military
function act.unit(plr, p, a)
	local d = p.data
	local i = int(a.i, 1, #M.Units)
	local n = int(a.n or 1, 1, 100)
	if not i or not n then return no("Unknown unit") end
	local u = M.Units[i]
	if d.lv < u.lvl then return no("Unlocks at level " .. u.lvl) end
	local bought, spent = 0, 0
	for _ = 1, n do
		if M.UnitCount(d.units) >= M.UnitCap(d.lv) then break end
		local cost = M.UnitCost(i, d.units[tostring(i)] or 0)
		if d.cash < cost then break end
		d.cash -= cost; spent += cost
		d.units[tostring(i)] = (d.units[tostring(i)] or 0) + 1
		bought += 1
	end
	if bought == 0 then
		if M.UnitCount(d.units) >= M.UnitCap(d.lv) then return no("Army is full (" .. M.UnitCap(d.lv) .. "). Level up for more room or disband a unit.") end
		return no("Not enough cash")
	end
	PS.TaskProgress(p, "units", bought)
	return ok({ bought = bought, spent = spent })
end

function act.disband(plr, p, a)
	local d = p.data
	local i = int(a.i, 1, #M.Units)
	if not i or (d.units[tostring(i)] or 0) <= 0 then return no("You have none of those") end
	d.units[tostring(i)] -= 1
	if d.units[tostring(i)] == 0 then d.units[tostring(i)] = nil end
	return ok()
end

---------------------------------------------------------------- battle (rival nations; winning pays, losing only costs Supply)
function act.rivals(plr, p, a)
	local d = p.data
	if a.refresh or not d.rivals or now() - d.rivals.t > 600 then PS.MakeRivals(p) end
	return ok()
end

function act.battle(plr, p, a)
	local d = p.data
	if not d.rivals then PS.MakeRivals(p) end
	local i = int(a.i, 1, #d.rivals.list)
	if not i then return no("Pick a rival") end
	local rv = d.rivals.list[i]
	if rv.beaten then return no("Already defeated. Refresh for new rivals.") end
	if d.sup < M.BattleSupply then return no("Not enough Supply (" .. M.BattleSupply .. " needed)") end
	d.sup -= M.BattleSupply
	local atk = PS.Power(p)
	local chance = M.WinChance(atk, rv.def)
	d.stats.battles += 1
	if math.random() < chance then
		rv.beaten = true
		d.stats.wins += 1
		local cash = PS.Earn(p, rv.reward, "battle")
		local xp = math.max(1, math.floor(R.MinuteXp(d.lv) * 0.6 + 0.5))
		PS.AddXp(p, xp)
		PS.TaskProgress(p, "wins", 1)
		return ok({ win = true, cash = cash, xp = xp, chance = chance })
	end
	return ok({ win = false, chance = chance })
end

---------------------------------------------------------------- bosses
function act.bossHit(plr, p, a)
	local d = p.data
	local boss = PS.EnsureBoss(p)
	if (boss.next or 0) > now() then return no("The next boss arrives in " .. R.Duration(boss.next - now())) end
	local n = int(a.n or 1, 1, 50) or 1
	n = math.min(n, d.sup)
	if n <= 0 then return no("Not enough Supply") end
	local atk = PS.Power(p)
	local dmg = 0
	for _ = 1, n do
		if boss.hp <= 0 then break end
		d.sup -= M.BossSupply
		local hit = math.floor(M.BossDamage(atk) * (0.85 + math.random() * 0.3))
		boss.hp = math.max(0, boss.hp - hit); dmg += hit
		d.stats.hits += 1
		PS.TaskProgress(p, "hits", 1)
	end
	if boss.hp <= 0 then
		local e = boss.era
		local gold = M.BossGold[e]
		local cash = PS.Earn(p, R.MinuteValue(d.lv) * 20, "boss")
		local xp = math.floor(R.MinuteXp(d.lv) * 5 + 0.5)
		d.gold += gold
		d.stats.bosses += 1
		d.boss = { era = R.EraOf(d.lv), hp = M.BossHp(R.EraOf(d.lv)), next = now() + M.BossCooldown }
		PS.AddXp(p, xp)
		PS.Note(p, { kind = "boss", name = M.Bosses[e][1], gold = gold, cash = cash, xp = xp })
		return ok({ dmg = dmg, killed = true })
	end
	return ok({ dmg = dmg })
end

---------------------------------------------------------------- gold
A.GoldPrices = { inf = 10, sup = 5, boss = 3 }
function act.goldInf(plr, p)
	local d = p.data
	if d.gold < A.GoldPrices.inf then return no("Not enough gold") end
	local max = R.MaxInfluence(d.lv, d.sk)
	if d.inf >= max then return no("Influence is already full") end
	d.gold -= A.GoldPrices.inf; d.inf = max; d.infT = 0
	return ok()
end
function act.goldSup(plr, p)
	local d = p.data
	if d.gold < A.GoldPrices.sup then return no("Not enough gold") end
	local max = R.MaxSupply(d.lv, d.sk)
	if d.sup >= max then return no("Supply is already full") end
	d.gold -= A.GoldPrices.sup; d.sup = max; d.supT = 0
	return ok()
end
function act.bossSkip(plr, p)
	local d = p.data
	local boss = PS.EnsureBoss(p)
	if (boss.next or 0) <= now() then return no("The boss is already here") end
	if d.gold < A.GoldPrices.boss then return no("Not enough gold") end
	d.gold -= A.GoldPrices.boss; boss.next = 0
	return ok()
end

---------------------------------------------------------------- convoys
local function getConvoy(p, a)
	local i = int(a.c, 1, #p.data.convoys)
	return i and p.data.convoys[i], i
end

function act.send(plr, p, a)
	local d = p.data
	local c = getConvoy(p, a)
	local b = int(a.b, 1, #World.Cities)
	if not c or not b then return no("Bad request") end
	if c.to then return no("That convoy is on the road") end
	if c.at == b then return no("The convoy is already here") end
	local loads = PS.LoadsFor(p, c.at, b)
	local L
	for _, x in ipairs(loads) do if x.good == a.good then L = x end end
	if not L then return no("That load is gone. Pick another.") end
	if d.cash < L.cost then return no("Not enough cash for this load") end
	local taxPct, owner = PS.TaxFor(p, b)
	d.cash -= L.cost
	PS.Dispatch(p, c, b, { good = L.good, cost = L.cost, pay = L.pay, tax = L.tax, xp = L.xp, owner = owner, taxPct = taxPct })
	return ok()
end

function act.move(plr, p, a)
	local d = p.data
	local c = getConvoy(p, a)
	local b = int(a.b, 1, #World.Cities)
	if not c or not b then return no("Bad request") end
	if c.to then return no("That convoy is on the road") end
	if c.at == b then return no("The convoy is already here") end
	local fee = T.MoveFee(c.at, b, d.lv, PS.IncHr(p))
	if d.cash < fee then return no("Not enough cash for the trip") end
	d.cash -= fee
	PS.Dispatch(p, c, b, nil)
	return ok({ fee = fee })
end

function A.FinishGold(c) return math.max(1, math.ceil((c.t1 - now()) / 600)) end
function act.finishGold(plr, p, a)
	local d = p.data
	local c = getConvoy(p, a)
	if not c or not c.to then return no("That convoy is not travelling") end
	local cost = A.FinishGold(c)
	if d.gold < cost then return no("Not enough gold (" .. cost .. " needed)") end
	d.gold -= cost
	c.t1 = now()
	PS.AdvanceConvoys(p, now(), false)
	return ok()
end

function act.finishRobux(plr, p, a)
	local c, i = getConvoy(p, a)
	if not c or not c.to then return no("That convoy is not travelling") end
	local mins = (c.t1 - now()) / 60
	for _, key in ipairs({ "FinishConvoy1", "FinishConvoy2", "FinishConvoy3", "FinishConvoy4" }) do
		if mins <= Config.Products[key].maxMinutes then return MK.PromptProduct(plr, key, i) end
	end
	return no("Bad request")
end

function act.toggleAuto(plr, p)
	if not PS.Has(p, "AutoDispatch") then return no("Needs the Auto Dispatch pass") end
	p.data.autoOff = not p.data.autoOff or nil
	return ok()
end

---------------------------------------------------------------- daily tasks
function act.taskClaim(plr, p, a)
	local d = p.data
	local t = PS.EnsureTasks(p)
	local i = int(a.i, 1, #t.list)
	local task = i and t.list[i]
	if not task then return no("Unknown task") end
	if task.done then return no("Already claimed") end
	if task.have < task.n then return no("Not finished yet") end
	task.done = true
	local r = PS.TaskReward(p)
	d.gold += r.gold
	PS.Earn(p, r.cash, "task")
	return ok(r)
end
function act.taskBonus(plr, p)
	local d = p.data
	local t = PS.EnsureTasks(p)
	if t.bonus then return no("Already claimed") end
	for _, task in ipairs(t.list) do if not task.done then return no("Claim all three tasks first") end end
	t.bonus = true
	d.gold += 5
	return ok({ gold = 5 })
end

---------------------------------------------------------------- bank
function act.loanTake(plr, p)
	local d = p.data
	if d.loan then return no("Repay your current loan first") end
	if d.lv < 3 then return no("The bank lends from level 3") end
	local amt = PS.LoanMax(p)
	d.loan = { amt = amt, owed = math.floor(amt * 1.1), t = now() }
	d.cash += amt
	return ok({ amt = amt })
end
function act.loanRepay(plr, p)
	local d = p.data
	if not d.loan then return no("No loan to repay") end
	local pay = math.min(d.cash, d.loan.owed)
	if pay <= 0 then return no("No cash to repay with") end
	d.cash -= pay; d.loan.owed -= pay
	if d.loan.owed <= 0.5 then d.loan = nil end
	return ok({ paid = pay })
end

---------------------------------------------------------------- Robux
function act.buyPass(plr, p, a) return MK.PromptPass(plr, a.key) end
function act.buyGold(plr, p, a)
	if a.key ~= "GoldSmall" and a.key ~= "GoldBig" then return no("Unknown pack") end
	return MK.PromptProduct(plr, a.key)
end
function act.moveCapital(plr, p, a)
	local b = int(a.city, 1, #World.Cities)
	if not b then return no("Pick a city") end
	if b == p.data.home then return no("That is already your capital") end
	return MK.PromptProduct(plr, "MoveCapital", b)
end

---------------------------------------------------------------- alliances
local AC = Config.Alliance
local function myAlliance(p)
	local id = p.data.alliance
	return id and WS.Alliances[id], id
end
local function canManage(a, uid) local r = WS.Role(a, uid); return r == "leader" or r == "officer" end

function act.allyList(plr, p)
	local list = {}
	for id, s in pairs(WS.Index) do
		local cities = 0
		for _, c in pairs(WS.Cities) do if c.owner == id then cities += 1 end end
		table.insert(list, { id = id, name = s.name, tag = s.tag, color = s.color, members = s.members, open = s.open, cities = cities })
	end
	table.sort(list, function(x, y) if x.cities ~= y.cities then return x.cities > y.cities end; return (x.members or 0) > (y.members or 0) end)
	return ok({ list = list })
end

function act.allyCreate(plr, p, a)
	local d = p.data
	if d.alliance then return no("Leave your alliance first") end
	if d.lv < AC.MinLevel then return no("Founding an alliance needs level " .. AC.MinLevel) end
	if d.cash < AC.CreateCost then return no("Founding costs " .. R.Money(AC.CreateCost)) end
	local rec, err = WS.CreateAlliance(plr, a.name, a.tag, a.color, d.name)
	if not rec then return no(err) end
	d.cash -= AC.CreateCost
	d.alliance = rec.id
	return ok()
end
function act.allyJoin(plr, p, a)
	local d = p.data
	if d.alliance then return no("Leave your alliance first") end
	if type(a.id) ~= "string" or not WS.Index[a.id] then return no("Alliance not found") end
	if not WS.Alliances[a.id] then WS.LoadAlliance(a.id) end
	local rec, err = WS.Join(plr, a.id, d.name)
	if not rec then return no(err) end
	d.alliance = a.id
	return ok()
end
function act.allyLeave(plr, p)
	local d = p.data
	local _, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	WS.Leave(plr, id, d.name)
	d.alliance = nil
	return ok()
end
function act.allyDonate(plr, p, a)
	local d = p.data
	local _, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	local amt = math.floor(tonumber(a.amount) or 0)
	if amt <= 0 or amt ~= amt then return no("Bad amount") end
	amt = math.min(amt, math.floor(d.cash))
	if amt <= 0 then return no("No cash to donate") end
	local rec, err = WS.MutateAlliance(id, function(x)
		x.treasury = (x.treasury or 0) + amt
		local m = x.members[tostring(plr.UserId)]
		if m then m.donated = (m.donated or 0) + amt; m.active = now() end
		WS.AddLog(x, d.name ~= "" and (d.name .. " donated " .. R.Money(amt)) or (plr.Name .. " donated " .. R.Money(amt)))
		return x, true
	end)
	if not rec then return no(err) end
	d.cash -= amt
	return ok({ amount = amt })
end
function act.allyUpgrade(plr, p, a)
	local rec, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	if not canManage(rec, plr.UserId) then return no("Only the leader and officers can upgrade") end
	local up
	for _, u in ipairs(WS.Upgrades) do if u.key == a.key then up = u end end
	if not up then return no("Unknown upgrade") end
	local rec2, err = WS.MutateAlliance(id, function(x)
		local lvl = x.up[up.key] or 0
		if lvl >= up.max then return nil, "Already at max level" end
		local cost = WS.UpgradeCost(lvl)
		if (x.treasury or 0) < cost then return nil, "The treasury needs " .. R.Money(cost) end
		x.treasury -= cost
		x.up[up.key] = lvl + 1
		WS.AddLog(x, up.name .. " raised to level " .. (lvl + 1))
		return x, true
	end)
	if not rec2 then return no(err) end
	return ok()
end
function act.allyRole(plr, p, a)
	local rec, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	if WS.Role(rec, plr.UserId) ~= "leader" then return no("Only the leader can change roles") end
	local target = tostring(a.uid or "")
	local role = a.role
	if role ~= "officer" and role ~= "member" and role ~= "leader" then return no("Bad role") end
	if target == tostring(plr.UserId) then return no("Pick another member") end
	local rec2, err = WS.MutateAlliance(id, function(x)
		local m = x.members[target]
		if not m then return nil, "Not a member" end
		if role == "leader" then
			x.members[tostring(plr.UserId)].role = "officer"
			x.leader = tonumber(target); x.leaderName = m.name
		end
		m.role = role
		WS.AddLog(x, m.name .. " is now " .. role)
		return x, true
	end)
	if not rec2 then return no(err) end
	return ok()
end
function act.allyKick(plr, p, a)
	local rec, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	local myRole = WS.Role(rec, plr.UserId)
	local target = tostring(a.uid or "")
	local rec2, err = WS.MutateAlliance(id, function(x)
		local m = x.members[target]
		if not m then return nil, "Not a member" end
		if m.role == "leader" or (m.role == "officer" and myRole ~= "leader") or (myRole ~= "leader" and myRole ~= "officer") then
			return nil, "You cannot remove that member"
		end
		x.members[target] = nil
		WS.AddLog(x, m.name .. " was removed")
		return x, true
	end)
	if not rec2 then return no(err) end
	return ok()
end
function act.allyOpen(plr, p, a)
	local rec, id = myAlliance(p)
	if not id or WS.Role(rec, plr.UserId) ~= "leader" then return no("Only the leader can change this") end
	local rec2, err = WS.MutateAlliance(id, function(x) x.open = a.open and true or false; return x, true end)
	if not rec2 then return no(err) end
	return ok()
end

---------------------------------------------------------------- sieges (Supply is the energy)
function act.siege(plr, p, a)
	local d = p.data
	local _, id = myAlliance(p)
	if not id then return no("Join an alliance to fight for cities") end
	local i = int(a.city, 1, #World.Cities)
	if not i then return no("Bad city") end
	local n = math.min(int(a.n or 1, 1, 50) or 1, d.sup)
	if n <= 0 then return no("Not enough Supply") end
	local mods = PS.Mods(p)
	local dmg = M.SiegeDamage(d.lv, d.sk, d.units, { attack = mods.siege }) * n
	local res, err = WS.Attack(i, id, dmg, d.name)
	if not res then return no(err) end
	d.sup -= n
	d.stats.hits += n
	PS.TaskProgress(p, "hits", n)
	PS.AddXp(p, math.max(1, math.floor(R.MinuteXp(d.lv) * 0.25 * n + 0.5)))
	if res.captured then
		PS.Note(p, { kind = "toast", text = res.winner == id and ("Your alliance captured " .. World.Cities[i].name .. "!") or (World.Cities[i].name .. " fell to another alliance"), tone = "good" })
	end
	return ok({ dmg = dmg, hp = res.hp, captured = res.captured })
end
function act.reinforce(plr, p, a)
	local d = p.data
	local _, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	local i = int(a.city, 1, #World.Cities)
	if not i then return no("Bad city") end
	local n = math.min(int(a.n or 1, 1, 50) or 1, d.sup)
	if n <= 0 then return no("Not enough Supply") end
	local mods = PS.Mods(p)
	local amount = math.floor(M.SiegeDamage(d.lv, d.sk, d.units, { attack = mods.defense }) * n)
	local res, err = WS.Reinforce(i, id, amount)
	if not res then return no(err) end
	d.sup -= n
	return ok({ added = amount })
end
function act.setTax(plr, p, a)
	local rec, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	if not canManage(rec, plr.UserId) then return no("Only the leader and officers set tax") end
	local i = int(a.city, 1, #World.Cities)
	if not i then return no("Bad city") end
	local res, err = WS.SetTax(i, id, a.pct)
	if not res then return no(err) end
	return ok(res)
end

function act.rankings(plr, p, a)
	local kind = (a.kind == "wealth" or a.kind == "alliances") and a.kind or "level"
	return ok({ list = PS.Rankings(kind), kind = kind })
end

-- requests that return data the client shows, without needing a full resync
A.NoSync = { allyList = true, rankings = true }
-- requests allowed before onboarding finishes
A.PreOnboard = { sync = true, onboard = true, rankings = true }
return A
