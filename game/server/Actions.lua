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
local PS, MK, RA, AD
function A.Init(ps, mk, ra, ad) PS, MK, RA, AD = ps, mk, ra, ad end

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
	local cleanFlag, ferr = A.CleanFlag(p, a.flag)
	if not cleanFlag then cleanFlag = { l = "h3", c = { R.FlagColors[1], R.FlagColors[2], R.FlagColors[3] } } end
	local ideo = R.IdeologyByKey[a.ideo] and a.ideo or "republic"
	local home = int(a.home, 1, #World.Cities)
	if not home then return no("Pick a home capital") end
	WS.HomeMoved(nil, home)
	if PS.AN then PS.AN.Step(p, "Founded country") end
	d.name, d.flag, d.ideo, d.home, d.onboarded = name, cleanFlag, ideo, home, true
	for _, c in ipairs(d.convoys) do if not c.to then c.at = home end end
	PS.EnsureConvoys(p)
	PS.GrantVipOfficer(p)
	return ok()
end

local function eraGate(d, e)
	if e and e > R.PlayerEra(d) then return no("Advance to the " .. D.Eras[e].name .. " Era first") end
end

-- Paid eras (Kash 2 Oct): the level unlocks the option, cash pays for the advance. One era at a time.
function act.eraUp(plr, p)
	local d = p.data
	local cur = d.era or 1
	local nxt = cur + 1
	local E = D.Eras[nxt]
	if not E then return no("You are already in the last era") end
	if d.lv < E.start then return no("Reach level " .. E.start .. " to advance") end
	local cost = R.EraCost(nxt)
	if not PS.Spend(p, cost) then return no("Need " .. R.Money(cost) .. " to advance") end
	d.era = nxt
	if PS.AN then PS.AN.Era(p, nxt, E.name) end
	PS.Note(p, { kind = "toast", text = "Welcome to the " .. E.name .. " Era! New laws, properties and units unlocked", tone = "gold" })
	return ok({ era = nxt })
end

-- build the next stage of your Wonder
function act.wonderBuild(plr, p)
	local d = p.data
	local era = R.PlayerEra(d)
	if era < 2 then return no("Advance to the " .. D.Eras[2].name .. " Era to unlock your Wonder") end
	local k = (d.wonder or 0) + 1
	if k > R.WonderMax(era) then return no("Advance to the next era to keep building") end
	local cost = R.WonderCost(k, d.lv)
	if not PS.Spend(p, cost) then return no("Need " .. R.Money(cost)) end
	d.wonder = k
	PS.AddXp(p, math.floor(R.MinuteXp(d.lv) * 10))
	return ok({ wonder = k })
end

---------------------------------------------------------------- laws
function act.passLaw(plr, p, a)
	local d = p.data
	local i = int(a.i, 1, #D.Laws)
	if not i then return no("Unknown law") end
	local L = D.Laws[i]
	if d.lv < L.lvl then return no("Unlocks at level " .. L.lvl) end
	local eg = eraGate(d, L.era); if eg then return eg end
	if d.inf < L.cost then return no("Not enough Influence") end
	local t = os.clock()
	if t - p.lastAct < 0.06 then return no("Too fast") end
	p.lastAct = t
	local key = tostring(i)
	local before = d.passes[key] or 0
	local mods = PS.Mods(p)
	d.inf -= L.cost
	-- Silver and Gold mastery: 5% less Influence (Kash 16:50). Costs are small whole numbers, so the saving
	-- accumulates and refunds a whole point whenever it adds up to one.
	if R.MasteryTier(before) >= 2 then
		d.infSaved = (d.infSaved or 0) + L.cost * R.MasteryDiscount
		if d.infSaved >= 1 then local r = math.floor(d.infSaved); d.inf += r; d.infSaved -= r end
	end
	local cash = PS.Earn(p, R.LawCash(i, before, mods.law) * (0.9 + math.random() * 0.2), "law")
	local xp = R.LawXp(i, before)
	d.passes[key] = before + 1
	d.stats.laws += 1
	if d.stats.laws == 1 and PS.AN then PS.AN.Step(p, "First law") end
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
	local eg = eraGate(d, P.era); if eg then return eg end
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
	if d.stats.built == 1 and PS.AN then PS.AN.Step(p, "First property") end
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
	local eg = eraGate(d, u.era); if eg then return eg end
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

---------------------------------------------------------------- raids (Raids.lua): list = your server + 3 AI nations; RANKINGS can hit anyone (Kash 2 Oct)
function act.raid(plr, p, a)
	return RA.Attack(plr, p, a.id, false)
end
function act.spy(plr, p, a) return RA.Spy(plr, p, a.id) end


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
		d.boss = { era = R.PlayerEra(d), hp = M.BossHp(R.PlayerEra(d)), next = now() + M.BossCooldown }
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
	local loads = PS.LoadsFor(p, c.at, b, nil, true)
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
	PS.Dispatch(p, c, b, { good = L.good, cost = L.cost, pay = L.pay, tax = L.tax, xp = L.xp, owner = owner, taxPct = taxPct, ev = L.ev })
	if L.ev then d.wev = L.ev; PS.Note(p, { kind = "toast", text = "World event bonus locked in! This convoy pays big.", tone = "gold" }) end
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
		if mins <= Config.Products[key].maxMinutes then return MK.PromptProduct(plr, key, { i = i, t1 = c.t1 }) end
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
	if r.seals then d.seals += r.seals end
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
	d.seals += TK.DailyBonus.seals
	if TK.DailyBonus.refill then d.inf = math.max(d.inf, R.MaxInfluence(d.lv, d.sk)) end
	return ok({ seals = TK.DailyBonus.seals })
end
function act.weeklyChest(plr, p)
	local d = p.data
	PS.EnsureTasks(p)
	if d.weekly.chest then return no("Already opened this week") end
	local have = 0
	for _ in pairs(d.inv.gear) do have += 1 end
	if have >= Config.InventoryMax then return no("Inventory full. Discard some gear first.") end
	for _, task in ipairs(d.weekly.list) do if not task.done then return no("Claim all 5 weekly challenges first") end end
	d.weekly.chest = true
	d.seals += TK.WeeklyChest.seals
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
			return MK.PromptProduct(plr, "ChallengeRefresh", { src = a.src == "weekly" and "weekly" or "daily", i = int(a.i, 1, 10) or 1 })
		end
		return no(err)
	end
	return ok()
end

---------------------------------------------------------------- settings + meta prompts
local SETTINGS = { music = "bool", sfx = "bool", toasts = "bool", confirmBig = "bool", shortNumbers = "bool", autoClaim = "bool", reduceMotion = "bool", mapLabels = "bool",
	musicVol = "vol", sfxVol = "vol" }
function act.saveSettings(plr, p, a)
	local kind = type(a.key) == "string" and SETTINGS[a.key]
	if not kind then return no("Unknown setting") end
	if kind == "vol" then
		-- volume slider: a number from 0 to 1 (NaN fails both comparisons)
		local v = a.value
		if type(v) ~= "number" or not (v >= 0 and v <= 1) then return no("Bad value") end
		a.value = math.floor(v * 100 + 0.5) / 100
	elseif type(a.value) ~= "boolean" then return no("Bad value") end
	p.data.settings = p.data.settings or {}
	p.data.settings[a.key] = a.value
	return ok()
end
-- the favorite prompt (shown after a big moment, once per session) reports back so it never shows again once favorited
function act.favResult(plr, p, a)
	local d = p.data
	d.meta = d.meta or {}
	d.meta.favShown = (d.meta.favShown or 0) + 1
	if a.favorited == true then d.meta.favorited = true end
	return ok()
end

-- Seals shop
function act.sealBuy(plr, p, a)
	local d = p.data
	local it = TK.ShopByKey[a.key]
	if not it then return no("Unknown item") end
	if d.seals < it.cost then return no("Not enough Merits (" .. it.cost .. " needed)") end
	if it.refill == "inf" and d.inf >= R.MaxInfluence(d.lv, d.sk) then return no("Influence is already full") end
	if it.refill == "sup" and d.sup >= R.MaxSupply(d.lv, d.sk) then return no("Supply is already full") end
	d.seals -= it.cost
	if it.refill == "inf" then d.inf = R.MaxInfluence(d.lv, d.sk) end
	if it.refill == "sup" then d.sup = R.MaxSupply(d.lv, d.sk) end
	if it.basicCrates then d.crates.basic += it.basicCrates end
	if it.limitedCrates then d.crates.limited += it.limitedCrates end
	if it.shieldHours then
		if (d.shield or 0) < os.time() then d.shieldFrom = os.time() end
		d.shield = math.max(d.shield or 0, os.time()) + it.shieldHours * 3600
		RA.SetShield(plr.UserId, d.shield)
	end
	return ok({ item = it.key })
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
	local fee = math.ceil(amt * Config.Bank.DepositFee) -- ceil: tiny deposits pay the fee too (audit L4)
	if fee >= amt then return no("Deposit more than that") end
	d.cash -= amt
	d.bank += amt - fee
	if amt >= R.MinuteValue(d.lv) then PS.TaskProgress(p, "deposit", 1) end
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
	ChallengeRefresh = true, LimitedBundle = true, StarterPack = true }
function act.buyProduct(plr, p, a)
	if not BUYABLE[a.key] then return no("Unknown item") end
	if a.key == "LimitedBundle" and p.data.bundle then return no("You already own the Limited Bundle") end
	if a.key == "StarterPack" then
		if p.data.starter then return no("You already own the Starter Pack") end
		if p.data.lv > Config.Products.StarterPack.maxLevel then return no("The Starter Pack is for new players") end
		if Config.Products.StarterPack.id == 0 then return no("Coming soon") end
	end
	if (a.key == "LimitedBundle" or a.key == "Crate1" or a.key == "Crate3" or a.key == "Crate10") and os.time() > Config.Crates.Limited.ends then
		return no("This limited offer has ended")
	end
	return MK.PromptProduct(plr, a.key)
end
act.buyGold = act.buyProduct
-- out-of-Influence popup (Kash 19:19): the first Robux refill ever costs 9, then the normal price
function act.refillInfluence(plr, p, a)
	local d = p.data
	if d.inf >= R.MaxInfluence(d.lv, d.sk) then return no("Influence is already full") end
	if a.method == "gold" then return act.goldInf(plr, p, a) end
	return MK.PromptProduct(plr, d.firstRefill and "InfluenceRefill" or "InfluenceRefillFirst")
end
-- flags: everyone can pick the basic layouts/colours; the Custom Flag pass adds more layouts, colours, an emblem
-- and your own image (an asset id; Roblox moderates every uploaded image)
function act.setFlag(plr, p, a)
	local flag, err = A.CleanFlag(p, a.flag)
	if not flag then return no(err) end
	p.data.flag = flag
	return ok({ flag = flag })
end
-- shared flag validation (setFlag and onboarding). Returns flag or nil, message
function A.CleanFlag(p, f)
	local function no(m) return nil, m end
	f = type(f) == "table" and f or {}
	local pass = PS.Has(p, "CustomFlag")
	local layouts = pass and R.FlagLayoutsAll or R.FlagLayouts
	local colors = pass and R.FlagColorsAll or R.FlagColors
	if not table.find(layouts, f.l) then return no("That layout needs the Custom Flag pass") end
	if type(f.c) ~= "table" then return no("Bad colours") end
	local c = {}
	for k = 1, 3 do
		if not table.find(colors, f.c[k]) then return no("That colour needs the Custom Flag pass") end
		c[k] = f.c[k]
	end
	local flag = { l = f.l, c = c }
	if f.e ~= nil then
		if not pass then return no("Emblems need the Custom Flag pass") end
		if not table.find(R.FlagEmblems, f.e) then return no("Unknown emblem") end
		flag.e = f.e
	end
	if f.img ~= nil then
		if not pass then return no("Custom images need the Custom Flag pass") end
		local id = tonumber(f.img)
		if not id or id < 1 or id > 1e15 or id ~= math.floor(id) then return no("Paste an image or decal id (numbers only)") end
		flag.img = string.format("%d", id)
	end
	return flag
end
function act.revengeStrike(plr, p, a)
	local r = p.data.revenge
	if not r then return no("Nobody has raided you yet") end
	local q, ai = nil, nil
	for _, x in ipairs(RA.AI) do if x.id == r.id then ai = x end end
	if not ai then
		local uid = tonumber(tostring(r.id):match("^u(%d+)$"))
		q = uid and game:GetService("Players"):GetPlayerByUserId(uid)
	end
	if not ai and not q and not RA.RemoteOk(r.id) then return no(r.name .. " can't be found right now") end
	return MK.PromptProduct(plr, "RevengeStrike", r.id)
end
function act.changeGov(plr, p, a)
	local key = a and a.ideo
	if type(key) ~= "string" or not R.IdeologyByKey[key] then return no("Pick a government") end
	if key == p.data.ideo then return no("That is already your government") end
	if (p.data.govCredit or 0) > 0 then
		p.data.govCredit -= 1
		p.data.ideo = key
		p.xpMult = PS.Mods(p).xp
		return ok({ changed = true })
	end
	return MK.PromptProduct(plr, "ChangeGovernment", key)
end

function act.moveCapital(plr, p, a)
	local b = int(a.city, 1, #World.Cities)
	if not b then return no("Pick a city") end
	if b == p.data.home then return no("That is already your capital") end
	if (p.data.capitalCredit or 0) > 0 then
		p.data.capitalCredit -= 1
		WS.HomeMoved(p.data.home, b)
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
	if not PS.FreeSlot(p) then return no("Every officer slot is full. Fire someone or unlock a slot first.") end -- no bench (Kash 2 Oct)
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
	if o.limited then return no("Limited officers stay in their own slot and can't be fired.") end
	-- their gear goes back to the inventory
	o.weapon, o.armor = nil, nil
	local i = officerSlotIndex(d, a.id)
	if i then d.cab.slots[i] = false end
	d.inv.officers[a.id] = nil
	return ok()
end
-- move an officer into slot i, swapping with whoever is there (there is no bench any more)
function act.seat(plr, p, a)
	local d = p.data
	local o = type(a.id) == "string" and d.inv.officers[a.id]
	if not o then return no("Unknown officer") end
	if o.limited then return no("Limited officers have their own slot") end
	local target = int(a.slot, 1, PS.OfficerSlots(p))
	if not target then return no("That slot is locked") end
	local from = officerSlotIndex(d, a.id)
	if not from then return no("Unknown officer") end
	local other = d.cab.slots[target]
	for k = 1, target - 1 do if d.cab.slots[k] == nil then d.cab.slots[k] = false end end -- no holes (audit L1)
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
	d.pity = type(d.pity) == "table" and d.pity or {}
	for k = 1, n do
		-- a 10-pack guarantees at least one Epic or better
		local force = (kind == "limited" and n >= 10 and k == n and not gotEpic) or nil
		-- pity: the crate that fills the meter is Legendary or better
		local pityAt = O.Pity[kind] or 50
		if (d.pity[kind] or 0) + 1 >= pityAt then force = O.PityRarity end
		local r = O.OpenCrate(rng, kind, luck, force, { era = PS.Era(p), slotFree = PS.FreeSlot(p) ~= nil })
		local ri = O.RarityByKey[r.item.rarity].index
		if ri >= 4 then gotEpic = true end
		if ri >= O.PityRarity then d.pity[kind] = 0; r.pity = force == O.PityRarity or nil else d.pity[kind] = (d.pity[kind] or 0) + 1 end
		if r.type == "officer" then
			r.where = PS.AddOfficer(p, r.item)
			if not r.where then -- no room after all: turn it into gear so nothing is lost
				r = { type = "gear", item = O.NewGear(rng, O.RarityByKey[r.item.rarity].index) }
				if not PS.AddGear(p, r.item) then r.lost = true end
			end
		elseif r.type == "troops" then
			d.elite = d.elite or {}
			local key = tostring(r.item.era)
			d.elite[key] = (d.elite[key] or 0) + r.item.n
			r.item.name = M.Elite[r.item.era].name
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
	local have = 0
	for _ in pairs(d.inv.gear) do have += 1 end
	if have + n > Config.InventoryMax then return no("Inventory full (" .. have .. "/" .. Config.InventoryMax .. "). Discard some gear first.") end
	d.crates[kind] -= n
	return ok({ results = A.OpenCrates(p, kind, n), kind = kind, left = d.crates[kind] })
end
local function invFull(d, n)
	local have = 0
	for _ in pairs(d.inv.gear) do have += 1 end
	return have + (n or 1) > Config.InventoryMax
end
function act.buyCrate(plr, p, a)
	local d = p.data
	if invFull(d, 1) then return no("Inventory full. Discard some gear first.") end
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

-- per-player cooldowns on alliance writes (audit M6): join/leave/create 30 s, everything else 2 s
local function allyCd(p, kind, secs)
	p.allyCd = p.allyCd or {}
	local t = os.clock()
	if (p.allyCd[kind] or -1e9) + secs > t then return "Slow down a little (" .. math.ceil(p.allyCd[kind] + secs - t) .. "s)" end
	p.allyCd[kind] = t
	return nil
end
local function gone(plr, p) return PS.Profiles[plr] ~= p or p.leaving end
local function startClaims(p, rec)
	-- a new member starts claiming from the level the alliance is at now (no back pay for levels before they joined)
	p.data.allyClaim = { id = rec.id, lv = rec.level or 1, q = {} }
end

function act.allyCreate(plr, p, a)
	local d = p.data
	if d.alliance then return no("Leave your alliance first") end
	if d.lv < AC.MinLevel then return no("Founding an alliance needs level " .. AC.MinLevel) end
	if d.cash < AC.CreateCost then return no("Founding costs " .. R.Money(AC.CreateCost)) end
	local cd = allyCd(p, "join", 30); if cd then return no(cd) end
	d.cash -= AC.CreateCost -- charged before the yield, refunded on failure (audit M3)
	local rec, err = WS.CreateAlliance(plr, a.name, a.tag, a.color, d.name)
	if not rec then d.cash += AC.CreateCost; return no(err) end
	if gone(plr, p) then WS.Leave(plr, rec.id, d.name); return no("Left") end
	d.alliance = rec.id
	startClaims(p, rec)
	if PS.AN then PS.AN.Step(p, "Joined an alliance") end
	return ok()
end
function act.allyJoin(plr, p, a)
	local d = p.data
	if d.alliance then return no("Leave your alliance first") end
	if type(a.id) ~= "string" or not WS.Index[a.id] then return no("Alliance not found") end
	local cd = allyCd(p, "join", 30); if cd then return no(cd) end
	if not WS.Alliances[a.id] then WS.LoadAlliance(a.id) end
	local fee = math.floor((WS.Alliances[a.id] and WS.Alliances[a.id].joinFee) or 0)
	if d.cash < fee then return no("Joining costs " .. R.Money(fee)) end
	d.cash -= fee -- the most we agreed to pay, held before the yield; the difference is refunded (audit L2/M3)
	local rec, charged = WS.Join(plr, a.id, d.name, fee, d.lv)
	if not rec then d.cash += fee; return no(charged) end
	d.cash += fee - (tonumber(charged) or 0)
	if gone(plr, p) then WS.Leave(plr, a.id, d.name); return no("Left") end
	d.alliance = a.id
	startClaims(p, rec)
	if PS.AN then PS.AN.Step(p, "Joined an alliance") end
	return ok({ fee = charged })
end
function act.allyLeave(plr, p)
	local d = p.data
	local _, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	local cd = allyCd(p, "join", 30); if cd then return no(cd) end
	local rec2, err = WS.Leave(plr, id, d.name)
	if not rec2 and err ~= "Alliance not found" then return no(err) end
	d.alliance = nil
	d.allyClaim = nil
	return ok()
end
function act.allyDonate(plr, p, a)
	local d = p.data
	local _, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	local cd = allyCd(p, "donate", 2); if cd then return no(cd) end
	local amt = math.floor(tonumber(a.amount) or 0)
	if amt <= 0 or amt ~= amt then return no("Bad amount") end
	amt = math.min(amt, math.floor(d.cash))
	local minute = math.max(1, math.floor(R.MinuteValue(d.lv)))
	if amt < minute then return no("Donate at least " .. R.Money(minute)) end -- no $1 spam into the log (audit M6/L4)
	d.cash -= amt -- taken before the yield, refunded if the write fails (review #11)
	local rec, err = WS.MutateAlliance(id, function(x)
		local m = x.members[tostring(plr.UserId)]
		if not m then return nil, "You are not in that alliance" end
		x.treasury = (x.treasury or 0) + amt
		m.donated = (m.donated or 0) + amt; m.active = now()
		WS.AddLog(x, d.name ~= "" and (d.name .. " donated " .. R.Money(amt)) or (plr.Name .. " donated " .. R.Money(amt)))
		return x, true
	end)
	if not rec then d.cash += amt; return no(err) end
	PS.TaskProgress(p, "donate", 1)
	PS.AllyProgress(p, "donate", math.min(120, amt / minute))
	return ok({ amount = amt })
end
-- claim alliance level rewards and finished-quest rewards (Kash 2 Oct)
function act.allyClaim(plr, p)
	local d = p.data
	local rec, id = myAlliance(p)
	if not id or not rec then return no("You are not in an alliance") end
	local c = PS.AllyClaimable(p)
	if not c or (c.levels <= 0 and #c.quests == 0) then return no("Nothing to claim yet") end
	local ac = d.allyClaim
	local gold, basic, seals = 0, 0, 0
	for lv = (ac.lv or 1) + 1, rec.level or 1 do
		local r = WS.LevelReward(lv)
		gold += r.gold; basic += r.basic
	end
	ac.lv = rec.level or 1
	ac.q = ac.q or {}
	for _, key in ipairs(c.quests) do
		ac.q[tostring(rec.qweek) .. ":" .. key] = true
		gold += 15; seals += 3
	end
	-- forget claims from older weeks so the record stays small
	for k in pairs(ac.q) do if not k:find("^" .. tostring(rec.qweek) .. ":") then ac.q[k] = nil end end
	d.gold += gold
	d.seals = (d.seals or 0) + seals
	d.crates.basic = (d.crates.basic or 0) + basic
	return ok({ gold = gold, seals = seals, basic = basic })
end
function act.allyUpgrade(plr, p, a)
	do local cd = allyCd(p, "manage", 2); if cd then return no(cd) end end
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
	do local cd = allyCd(p, "manage", 2); if cd then return no(cd) end end
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
	do local cd = allyCd(p, "manage", 2); if cd then return no(cd) end end
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
	do local cd = allyCd(p, "manage", 2); if cd then return no(cd) end end
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
	do local cd = allyCd(p, "manage", 2); if cd then return no(cd) end end
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

function act.setRent(plr, p, a)
	local rec, id = myAlliance(p)
	if not id then return no("You are not in an alliance") end
	if not canManage(rec, plr.UserId) then return no("Only the leader and officers set rent") end
	local i = int(a.city, 1, #World.Cities)
	if not i then return no("Bad city") end
	local res, err = WS.SetRent(i, id, a.pct)
	if not res then return no(err) end
	return ok(res)
end

function act.rankings(plr, p, a)
	local kind = (a.kind == "wealth" or a.kind == "alliances") and a.kind or "level"
	return ok({ list = PS.Rankings(kind), kind = kind })
end

-- requests that return data the client shows, without needing a full resync
-- FREE GIFT (Kash 2 Oct): join the group, claim once. Checked fresh with GroupService (IsInGroup caches per session).
function act.groupGift(plr, p)
	local d = p.data
	if d.groupGift then return no("You already claimed your gift") end
	local cd = allyCd(p, "gift", 3); if cd then return no(cd) end
	local gid = Config.Group.Id
	local inGroup = false
	local okG, groups = pcall(function() return game:GetService("GroupService"):GetGroupsAsync(plr.UserId) end)
	if okG and type(groups) == "table" then for _, g in ipairs(groups) do if g.Id == gid then inGroup = true end end end
	if not inGroup then local okI, r = pcall(plr.IsInGroup, plr, gid); inGroup = okI and r or false end
	if not inGroup then return no("Join the group first, then claim") end
	p.inGroup = true
	d.groupGift = true
	d.gold += Config.GroupGift.gold
	d.crates.limited += Config.GroupGift.limitedCrates
	return ok({ gold = Config.GroupGift.gold, crates = Config.GroupGift.limitedCrates })
end

-- watch an ad to refill Influence. The reward arrives through ProcessReceipt (rewarded video ads).
function act.adRefill(plr, p)
	local d = p.data
	if d.inf >= R.MaxInfluence(d.lv, d.sk) then return no("Influence is already full") end
	if (p.adNext or 0) > os.clock() then return no("Next ad in " .. math.ceil(p.adNext - os.clock()) .. "s") end
	local prod = Config.Products[Config.AdRefill.product]
	if not prod or prod.id == 0 then return no("Ads are not available") end
	p.adNext = os.clock() + Config.AdRefill.cooldown
	p.adAt = os.clock()
	task.spawn(function()
		local AdService = game:GetService("AdService")
		local okA, err = pcall(function()
			local reward = AdService:CreateAdRewardFromDevProductId(prod.id)
			return AdService:ShowRewardedVideoAdAsync(plr, reward)
		end)
		if not okA then
			p.adNext = 0
			warn("[Idle Country] rewarded ad failed: " .. tostring(err))
			PS.Note(p, { kind = "toast", text = "No ad available right now. Try again later.", tone = "bad" })
			PS.Sync(plr)
		end
	end)
	return ok()
end

-- GEAR SHOP: a stock of 3 items per rarity, rolled from the 5 minute window and the player id (same for the whole
-- window, new every restock). d.gshop = { w = window, b = { [index] = true } } remembers what was bought this window.
local function gearStock(p, w)
	local GS = Config.GearShop
	local list = {}
	for r = 1, #GS.Levels do
		for k = 1, GS.PerRarity do
			local rng = Random.new((w * 7919 + (p.userId % 1000003) * 104729 + r * 131 + k * 17) % 2147483647)
			local g = O.NewGear(rng, r, k == 1 and "weapon" or (k == 2 and "armor" or nil))
			g.id = nil
			table.insert(list, { g = g, r = r, lvl = GS.Levels[r], cost = math.floor(R.MinuteValue(math.max(p.data.lv, GS.Levels[r])) * GS.Minutes[r] / 10 + 0.5) * 10 })
		end
	end
	return list
end
function act.gearShop(plr, p)
	local w = os.time() // Config.GearShop.Restock
	local d = p.data
	if type(d.gshop) ~= "table" or d.gshop.w ~= w then d.gshop = { w = w, b = {} } end
	local out = {}
	for i, e in ipairs(gearStock(p, w)) do
		table.insert(out, { i = i, gear = e.g, lvl = e.lvl, cost = e.cost, bought = d.gshop.b[tostring(i)] == true })
	end
	return ok({ w = w, ends = (w + 1) * Config.GearShop.Restock, items = out })
end
function act.gearBuy(plr, p, a)
	local d = p.data
	local w = os.time() // Config.GearShop.Restock
	if tonumber(a.w) ~= w then return no("The shop just restocked. Take a look at the new items!") end
	local i = int(a.i, 1, #Config.GearShop.Levels * Config.GearShop.PerRarity)
	if not i then return no("Unknown item") end
	if type(d.gshop) ~= "table" or d.gshop.w ~= w then d.gshop = { w = w, b = {} } end
	if d.gshop.b[tostring(i)] then return no("You already bought this one. More in the next restock.") end
	local e = gearStock(p, w)[i]
	if d.lv < e.lvl then return no("Unlocks at level " .. e.lvl) end
	if invFull(d, 1) then return no("Inventory full. Discard some gear first.") end
	if not PS.Spend(p, e.cost) then return no("Need " .. R.Money(e.cost)) end
	local g = e.g
	g.id = string.format("g%x%06x", os.time(), math.random(0, 16777215))
	PS.AddGear(p, g)
	d.gshop.b[tostring(i)] = true
	if PS.AN then PS.AN.Custom(p, "GearShopBuy", e.r) end
	return ok({ gear = g })
end

function act.globalChat(plr, p, a) return PS.Chat and PS.Chat.Send(plr, p, a and a.text) or no("Chat is offline") end

-- buy the next convoy (cash). The level gate must be reached first.
function act.buyConvoy(plr, p)
	local d = p.data
	local k = (d.convoyBought or 0) + 1
	local gate = R.ConvoyGates[k]
	if not gate then return no("You own every convoy") end
	if d.lv < gate then return no("The next convoy unlocks at level " .. gate) end
	local cost = R.ConvoyCost(k)
	if not PS.Spend(p, cost) then return no("Need " .. R.Money(cost)) end
	d.convoyBought = k
	PS.EnsureConvoys(p)
	if PS.AN then PS.AN.Custom(p, "ConvoyBought", k) end
	return ok({ convoys = PS.Slots(p) })
end

-- onboarding funnel steps reported by the onboarding screens (analytics only)
local FUNNEL_UI = { name = "Named country", flag = "Designed flag", gov = "Chose government" }
function act.funnel(plr, p, a)
	local s = FUNNEL_UI[a and a.step]
	if s and PS.AN and not p.data.onboarded then PS.AN.Step(p, s) end
	return ok()
end

-- tutorial progress (Kash 2 Oct): step number, or -1 when skipped or finished
function act.tutorial(plr, p, a)
	local step = tonumber(a and a.step)
	if not step or step ~= step or step < -1 or step > 50 then return no("Bad step") end
	if PS.AN then
		if step == 0 or (step == -1 and p.data.tut == nil) then PS.AN.Step(p, "Answered tutorial"); PS.AN.Custom(p, step == 0 and "TutorialYes" or "TutorialNo") end
		if step == -1 and type(p.data.tut) == "number" and p.data.tut >= 0 then PS.AN.Custom(p, "TutorialEnded", p.data.tut) end
	end
	p.data.tut = math.floor(step)
	return ok()
end

-- player profiles
function act.profile(plr, p, a)
	local uid = tonumber(a and a.uid) or plr.UserId
	local cd = allyCd(p, "profile", 0.5); if cd then return no(cd) end
	local pf = RA.Profile(uid)
	if not pf then return no("That player has no profile yet") end
	pf.uid = uid
	return ok({ profile = pf })
end
function act.setTitle(plr, p, a)
	local key = a and a.key
	if key ~= nil and (type(key) ~= "string" or not R.AchByKey[key] or not table.find(R.AchievementsOf(p.data), key)) then return no("You have not earned that title") end
	p.data.title = key
	return ok()
end

-- tester panel (owner only; AD.Run checks again)
function act.admin(plr, p, a)
	if not AD or not AD.IsAdmin(plr) then return no("Not allowed") end
	return AD.Run(plr, p, a and a.cmd)
end
function act.adminList(plr, p)
	if not AD or not AD.IsAdmin(plr) then return no("Not allowed") end
	return ok({ list = AD.List() })
end

A.NoSync = { globalChat = true, gearShop = true, funnel = true, tutorial = true, adRefill = true, allyList = true, rankings = true, profile = true, adminList = true }
-- requests allowed before onboarding finishes
A.PreOnboard = { buyPass = true, sync = true, onboard = true, rankings = true, admin = true, adminList = true, funnel = true }
return A
