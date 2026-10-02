-- Actions: every request a client can make. Each one re-checks the rules; the client is never trusted.
local RS = game:GetService("ReplicatedStorage")
local D = require(RS.Shared.GameData)
local R = require(RS.Shared.Rules)
local T = require(RS.Shared.Trade)
local M = require(RS.Shared.Military)
local World = require(RS.Shared.World)
local Config = require(RS.Shared.Config)
local WS = require(script.Parent.WorldService)
local O = require(RS.Shared.Officers)
local TK = require(RS.Shared.Tasks)

local A = {}
local PS, MK, RA
function A.Init(ps, mk, ra) PS, MK, RA = ps, mk, ra end

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
	PS.TaskProgress(p, "influence", L.cost)
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

---------------------------------------------------------------- raids (Raids.lua): players in your server + 3 AI nations
function act.raid(plr, p, a)
	return RA.Attack(plr, p, a.id, false)
end

---------------------------------------------------------------- bosses
function act.bossHit(plr, p, a)
	local d = p.data
	local boss = PS.EnsureBoss(p)
	if (boss.next or 0) > now() then return no("The next boss arrives in " .. R.Duration(boss.next - now())) end
	local n = int(a.n or 1, 1, 50) or 1
	n = math.min(n, d.sup)
	if n <= 0 then return no("Not enough Supply") end
	local mods = PS.Mods(p)
	local atk = PS.Power(p, mods) * (1 + (mods.boss or 0))
	local dmg = 0
	PS.TaskProgress(p, "supply", n)
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
		PS.TaskProgress(p, "boss", 1)
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
	local i = int(a.c, 1, math.min(#p.data.convoys, PS.Slots(p)))
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
	-- the map showed a price; if tax or the day's hot good changed since, ask the player to look again
	local shown = tonumber(a.cost)
	if shown and shown == shown and math.abs(shown - L.cost) > math.max(1, L.cost * 0.01) then return no("Prices just changed. Check the new numbers and send again.") end
	local shownTax = tonumber(a.tax)
	if shownTax and shownTax == shownTax and L.tax > shownTax + math.max(1, L.pay * 0.005) then return no("The city's tax just went up. Check the new numbers and send again.") end
	if d.cash < L.cost then return no("Not enough cash for this load") end
	local taxPct, owner = PS.TaxFor(p, b)
	d.cash -= L.cost
	PS.Dispatch(p, c, b, { good = L.good, cost = L.cost, pay = L.pay, tax = L.tax, xp = L.xp, owner = owner, taxPct = taxPct })
	p.sentTo = p.sentTo or {}
	if not p.sentTo[b] then p.sentTo[b] = true; PS.TaskProgress(p, "moves", 1) end
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

---------------------------------------------------------------- daily orders + weekly challenges
local function grantReward(p, r)
	local d = p.data
	if r.gold then d.gold += r.gold end
	if r.cash then PS.Earn(p, r.cash, "task") end
	if r.basicCrates then d.crates.basic += r.basicCrates end
	if r.limitedCrates then d.crates.limited += r.limitedCrates end
end
function act.taskClaim(plr, p, a)
	PS.EnsureTasks(p)
	local d = p.data
	local list = a.src == "weekly" and d.weekly.list or d.tasks.list
	local i = int(a.i, 1, #list)
	local task = i and list[i]
	if not task then return no("Unknown order") end
	if task.done then return no("Already claimed") end
	if task.have < task.n then return no("Not finished yet") end
	task.done = true
	local r = PS.TaskReward(p, task)
	grantReward(p, r)
	return ok(r)
end
function act.taskBonus(plr, p)
	local d = p.data
	local t = PS.EnsureTasks(p)
	if t.bonus then return no("Already claimed") end
	for _, task in ipairs(t.list) do if not task.done then return no("Claim all of today's orders first") end end
	t.bonus = true
	d.gold += TK.DailyBonus.gold
	return ok({ gold = TK.DailyBonus.gold })
end
function act.weeklyChest(plr, p)
	local d = p.data
	PS.EnsureTasks(p)
	if d.weekly.chest then return no("Already opened this week") end
	for _, task in ipairs(d.weekly.list) do if not task.done then return no("Claim all 5 weekly challenges first") end end
	d.weekly.chest = true
	d.crates.limited += TK.WeeklyChest.limitedCrates
	local rng = PS.Rng(p)
	local g = O.NewGear(rng, math.max(TK.WeeklyChest.gearMinRarity, O.Roll(rng, O.GearOdds.limited, PS.Has(p, "CrateLuck"))))
	PS.AddGear(p, g)
	return ok({ gear = g })
end
function act.taskRefresh(plr, p, a)
	local okR, err = PS.RefreshTask(p, a.src == "weekly" and "weekly" or "daily", int(a.i, 1, 10))
	if not okR then
		if err == "no_refresh" then
			-- no free refresh left today: offer the 19 Robux Challenge Refresh
			return MK.PromptProduct(plr, "ChallengeRefresh", { src = a.src, i = a.i })
		end
		return no(err)
	end
	return ok()
end

---------------------------------------------------------------- login sheet (pauses, never resets)
function act.loginClaim(plr, p)
	local d = p.data
	if not PS.LoginReady(p) then return no("Come back tomorrow for the next reward") end
	local idx = math.clamp(d.login.idx or 1, 1, #TK.Login)
	local r = TK.Login[idx]
	if r.lawMinutes then PS.Earn(p, R.MinuteValue(d.lv) * r.lawMinutes, "login") end
	if r.gold then d.gold += r.gold end
	if r.refill then d.inf = math.max(d.inf, R.MaxInfluence(d.lv, d.sk)); d.sup = math.max(d.sup, R.MaxSupply(d.lv, d.sk)) end
	if r.basicCrates then d.crates.basic += r.basicCrates end
	if r.limitedCrates then d.crates.limited += r.limitedCrates end
	d.login.last = R.Day()
	d.login.idx = idx % #TK.Login + 1
	d.login.streak = (d.login.streak or 0) + 1
	return ok({ idx = idx })
end

---------------------------------------------------------------- bank (deposits cost 10%, withdrawals free, 1.5%/h interest)
local function amountArg(x, max)
	x = tonumber(x)
	if not x or x ~= x or x == math.huge then return nil end
	return math.floor(math.min(x, max))
end
function act.deposit(plr, p, a)
	local d = p.data
	local amt = amountArg(a.amount, d.cash)
	if not amt or amt <= 0 then return no("No cash to deposit") end
	local fee = math.floor(amt * Config.Bank.DepositFee)
	d.cash -= amt
	d.bank += amt - fee
	PS.TaskProgress(p, "deposit", 1)
	return ok({ deposited = amt - fee, fee = fee })
end
function act.withdraw(plr, p, a)
	local d = p.data
	local amt = amountArg(a.amount, d.bank)
	if not amt or amt <= 0 then return no("Nothing in the bank") end
	d.bank -= amt
	d.cash += amt
	return ok({ withdrawn = amt })
end
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
local BUYABLE = { GoldSmall = true, GoldBig = true, GoldHuge = true, Crate1 = true, Crate3 = true, Crate10 = true,
	TreasuryGrant = true, InfluenceRefill = true, SupplyRefill = true, RaidShield = true, InstantArmy = true,
	ChallengeRefresh = true, LimitedBundle = true }
function act.buyProduct(plr, p, a)
	if not BUYABLE[a.key] then return no("Unknown item") end
	if a.key == "LimitedBundle" and p.data.bundle then return no("You already own the Limited Bundle") end
	return MK.PromptProduct(plr, a.key)
end
act.buyGold = act.buyProduct
function act.revengeStrike(plr, p, a)
	local r = p.data.revenge
	if not r then return no("Nobody has raided you yet") end
	local q, ai = nil, nil
	for _, x in ipairs(RA.AI) do if x.id == r.id then ai = x end end
	if not ai then
		local uid = tonumber(tostring(r.id):match("^u(%d+)$"))
		q = uid and game:GetService("Players"):GetPlayerByUserId(uid)
	end
	if not ai and not q then return no(r.name .. " has left this server") end
	return MK.PromptProduct(plr, "RevengeStrike", r.id)
end
function act.moveCapital(plr, p, a)
	local b = int(a.city, 1, #World.Cities)
	if not b then return no("Pick a city") end
	if b == p.data.home then return no("That is already your capital") end
	if (p.data.capitalCredit or 0) > 0 then
		p.data.capitalCredit -= 1
		p.data.home = b
		return ok({ moved = true })
	end
	return MK.PromptProduct(plr, "MoveCapital", b)
end

---------------------------------------------------------------- officers (Kash 1 Oct): panels, slots for cash, 3 hire tiers
function act.buySlot(plr, p)
	local d = p.data
	local cost = PS.NextSlotCost(p)
	if not cost then return no("All officer slots are open") end
	if d.cash < cost then return no("A new slot costs " .. R.Money(cost)) end
	d.cash -= cost
	d.cab.bought = (d.cab.bought or 0) + 1
	return ok({ cost = cost })
end
function act.hire(plr, p, a)
	local d = p.data
	local tier
	for _, h in ipairs(Config.Officers.Hire) do if h.key == a.tier then tier = h end end
	if not tier then return no("Pick a hiring office") end
	local benched = 0
	for id in pairs(d.inv.officers) do if not table.find(d.cab.slots, id) then benched += 1 end end
	if benched >= Config.Officers.BenchMax then return no("Your bench is full. Fire someone first.") end
	if d.cash < tier.cost then return no(tier.name .. " costs " .. R.Money(tier.cost)) end
	d.cash -= tier.cost
	local rng = PS.Rng(p)
	local o = O.NewOfficer(rng, O.Roll(rng, O.HireOdds[tier.key], PS.Has(p, "CrateLuck")), d.lastHireTrait)
	d.lastHireTrait = o.traits[1].k
	local where = PS.AddOfficer(p, o)
	PS.TaskProgress(p, "hire", 1)
	return ok({ officer = o, where = where })
end
local function officerSlotIndex(d, id) for i = 1, 20 do if d.cab.slots[i] == id then return i end end end
function act.fire(plr, p, a)
	local d = p.data
	local o = type(a.id) == "string" and d.inv.officers[a.id]
	if not o then return no("Unknown officer") end
	-- their gear goes back to the inventory
	o.weapon, o.armor = nil, nil
	local i = officerSlotIndex(d, a.id)
	if i then d.cab.slots[i] = false end
	d.inv.officers[a.id] = nil
	return ok()
end
-- move an officer into slot i (swapping with whoever is there), or to the bench (slot 0)
function act.seat(plr, p, a)
	local d = p.data
	local o = type(a.id) == "string" and d.inv.officers[a.id]
	if not o then return no("Unknown officer") end
	local target = int(a.slot, 0, PS.OfficerSlots(p))
	if not target then return no("That slot is locked") end
	local from = officerSlotIndex(d, a.id)
	if target == 0 then if from then d.cab.slots[from] = false end; return ok() end
	local other = d.cab.slots[target]
	d.cab.slots[target] = a.id
	if from then d.cab.slots[from] = other or false end
	for i = 1, 20 do if i > PS.OfficerSlots(p) and d.cab.slots[i] then d.cab.slots[i] = false end end
	return ok()
end
-- gear onto the player ("player") or an officer id; slot = "weapon" / "armor"
function act.equip(plr, p, a)
	local d = p.data
	local g = type(a.gear) == "string" and d.inv.gear[a.gear]
	if not g then return no("Unknown gear") end
	local holder = a.holder == "player" and d.cab.player or (type(a.holder) == "string" and d.inv.officers[a.holder])
	if not holder then return no("Pick who wears it") end
	-- take it off whoever wears it now
	local function strip(h) if h.weapon == g.id then h.weapon = nil end; if h.armor == g.id then h.armor = nil end end
	strip(d.cab.player)
	for _, o in pairs(d.inv.officers) do strip(o) end
	holder[g.kind] = g.id
	return ok()
end
function act.unequip(plr, p, a)
	local d = p.data
	local holder = a.holder == "player" and d.cab.player or (type(a.holder) == "string" and d.inv.officers[a.holder])
	if not holder or (a.slot ~= "weapon" and a.slot ~= "armor") then return no("Bad request") end
	holder[a.slot] = nil
	return ok()
end
function act.discard(plr, p, a)
	local d = p.data
	local g = type(a.gear) == "string" and d.inv.gear[a.gear]
	if not g then return no("Unknown gear") end
	if g.limited then return no("Limited items cannot be thrown away") end
	local function strip(h) if h.weapon == g.id then h.weapon = nil end; if h.armor == g.id then h.armor = nil end end
	strip(d.cab.player)
	for _, o in pairs(d.inv.officers) do strip(o) end
	d.inv.gear[a.gear] = nil
	return ok()
end

---------------------------------------------------------------- crates (one crate, two prices: gold or Robux; basic crate for cash)
function A.OpenCrates(p, kind, n)
	local d = p.data
	local rng = PS.Rng(p)
	local results = {}
	local luck = PS.Has(p, "CrateLuck")
	local gotEpic = false
	for k = 1, n do
		-- a 10-pack guarantees at least one Epic or better
		local force = (kind == "limited" and n >= 10 and k == n and not gotEpic)
		local r = O.OpenCrate(rng, kind, luck, force)
		if O.RarityByKey[r.item.rarity].index >= 3 then gotEpic = true end
		if r.type == "officer" then r.where = PS.AddOfficer(p, r.item)
		elseif not PS.AddGear(p, r.item) then r.lost = true end
		table.insert(results, r)
	end
	PS.TaskProgress(p, "crate", n)
	return results
end
function act.openCrate(plr, p, a)
	local d = p.data
	local kind = a.kind == "basic" and "basic" or "limited"
	local n = int(a.n or 1, 1, 10) or 1
	if (d.crates[kind] or 0) < n then return no("You have no " .. (kind == "basic" and "Supply" or "Founder's") .. " crates to open") end
	d.crates[kind] -= n
	return ok({ results = A.OpenCrates(p, kind, n), kind = kind })
end
function act.buyCrate(plr, p, a)
	local d = p.data
	if a.kind == "basic" then
		local price = PS.BasicCratePrice(p)
		if d.cash < price then return no("A Supply Crate costs " .. R.Money(price)) end
		d.cash -= price
		return ok({ results = A.OpenCrates(p, "basic", 1), kind = "basic" })
	end
	local L = Config.Crates.Limited
	if os.time() > L.ends then return no("This crate has left the shop") end
	if d.gold < L.gold then return no("The " .. L.name .. " costs " .. L.gold .. " gold") end
	d.gold -= L.gold
	return ok({ results = A.OpenCrates(p, "limited", 1), kind = "limited" })
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
		table.insert(list, { id = id, name = s.name, tag = s.tag, color = s.color, members = s.members, open = s.open, cities = cities,
			fee = s.fee or 0, dues = s.dues or 0, style = s.style or "flat" })
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
	local fee = (WS.Alliances[a.id] and WS.Alliances[a.id].joinFee) or 0
	if d.cash < fee then return no("Joining costs " .. R.Money(fee)) end
	local rec, err = WS.Join(plr, a.id, d.name, fee, d.lv)
	if not rec then return no(err) end
	d.cash -= fee
	d.alliance = a.id
	return ok({ fee = fee })
end
function act.allyLeave(plr, p)
	local d = p.data
	local _, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	local rec2, err = WS.Leave(plr, id, d.name)
	if not rec2 and err ~= "Alliance not found" then return no(err) end
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
	PS.TaskProgress(p, "donate", 1)
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
		local r = WS.Role(x, plr.UserId)
		if r ~= "leader" and r ~= "officer" then return nil, "Only the leader and officers can upgrade" end
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
		local mine = x.members[tostring(plr.UserId)]
		if not mine or mine.role ~= "leader" then return nil, "Only the leader can change roles" end
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
	local target = tostring(a.uid or "")
	local rec2, err = WS.MutateAlliance(id, function(x)
		local myRole = WS.Role(x, plr.UserId)
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
	local rec2, err = WS.MutateAlliance(id, function(x)
		if WS.Role(x, plr.UserId) ~= "leader" then return nil, "Only the leader can change this" end
		x.open = a.open and true or false
		return x, true
	end)
	if not rec2 then return no(err) end
	return ok()
end

-- leader sets the join fee and dues (once a day)
function act.allySettings(plr, p, a)
	local rec, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	local fee = tonumber(a.fee) or 0
	local pct = tonumber(a.pct) or 0
	if fee ~= fee or pct ~= pct then return no("Bad numbers") end
	fee = math.clamp(math.floor(fee), 0, AC.FeeMax)
	pct = math.clamp(math.floor(pct), 0, AC.DuesMax)
	local style = (a.style == "prog" or a.style == "regr") and a.style or "flat"
	local rec2, err = WS.MutateAlliance(id, function(x)
		if WS.Role(x, plr.UserId) ~= "leader" then return nil, "Only the leader can set fees and dues" end
		if (x.settingsT or 0) + AC.SettingsCooldown > os.time() then
			return nil, "Fees and dues can change once a day. Next change in " .. R.Duration(x.settingsT + AC.SettingsCooldown - os.time())
		end
		x.joinFee = fee
		x.dues = { pct = pct, style = style }
		x.settingsT = os.time()
		WS.AddLog(x, "Join fee " .. R.Money(fee) .. ", dues " .. pct .. "% (" .. style .. ")")
		return x, true
	end)
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
	PS.TaskProgress(p, "siege", n)
	PS.TaskProgress(p, "supply", n)
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
