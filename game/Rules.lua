-- Rules: every formula the server and client share. One place to tune the game.
-- Numbers for laws and properties come from GameData (ported from the Idle Mafia-style prototype).
local D = require(script.Parent.GameData)
local R = {}

---------------------------------------------------------------- core timers
R.RegenSec = 30 -- one Influence every 30 s
R.SupplyRegenSec = 60 -- one Supply every 60 s
R.OfflineCapSec = 12 * 3600 -- offline catch-up stops after 12 h
R.OfflinePropShare = 0.5 -- properties earn 50% while you are offline

---------------------------------------------------------------- mastery
R.MasteryAt = { 25, 50, 100 }
R.MasteryPct = { 0, 5, 10, 15 } -- index = tier + 1
R.MasteryName = { "", "BRONZE", "SILVER", "GOLD" }
R.MasteryDiscount = 0.05 -- Silver+ : 5% less Influence per law
function R.MasteryTier(passes)
	passes = passes or 0
	if passes >= 100 then return 3 elseif passes >= 50 then return 2 elseif passes >= 25 then return 1 end
	return 0
end
function R.NextMastery(passes) return R.MasteryAt[R.MasteryTier(passes) + 1] end

---------------------------------------------------------------- skill points (Idle Mafia style)
-- Earned: +3 per level, +1 for every law taken to Gold mastery.
R.SkillPerLevel = 3
R.SkillPerGold = 1
R.Skills = {
	{ key = "inf", name = "MAX INFLUENCE", icon = "icon_influence", per = 2, unit = "", desc = "+2 max Influence per upgrade", cost = function(n) return 2 end },
	{ key = "sup", name = "MAX SUPPLY", icon = "icon_supply", per = 1, unit = "", desc = "+1 max Supply per upgrade", cost = function(n) return 2 end },
	{ key = "atk", name = "ATTACK", icon = "icon_attack", per = 4, unit = "", desc = "+4 attack per upgrade", cost = function(n) return 1 end },
	{ key = "def", name = "DEFENSE", icon = "icon_defense", per = 4, unit = "", desc = "+4 defense per upgrade", cost = function(n) return 1 end },
	{ key = "lot", name = "BUILDING LOTS", icon = "icon_properties", per = 1, unit = "", desc = "+1 lot (cost doubles each time)", cost = function(n) return 2 ^ (n + 1) end },
}
R.SkillByKey = {}
for _, s in ipairs(R.Skills) do R.SkillByKey[s.key] = s end
function R.SkillEarned(lv, goldLaws) return (lv - 1) * R.SkillPerLevel + (goldLaws or 0) * R.SkillPerGold end
function R.SkillSpent(sk)
	local t = 0
	for _, s in ipairs(R.Skills) do
		for n = 0, (sk[s.key] or 0) - 1 do t += s.cost(n) end
	end
	return t
end

---------------------------------------------------------------- stats
function R.MaxInfluence(lv, sk) return 20 + 2 * (lv - 1) + 2 * ((sk and sk.inf) or 0) end
function R.MaxSupply(lv, sk) return 10 + math.floor(lv / 4) + ((sk and sk.sup) or 0) end
R.BaseLots = 4
function R.Lots(sk, extraPass) return R.BaseLots + ((sk and sk.lot) or 0) + (extraPass and 3 or 0) end
function R.ConvoySlots(lv, extraPass)
	local n = 1
	for _, gate in ipairs({ 5, 12, 20, 30, 45 }) do if lv >= gate then n += 1 end end
	return n + (extraPass and 2 or 0)
end
R.ConvoySlotLevels = { 1, 5, 12, 20, 30, 45 }

---------------------------------------------------------------- XP curve (26 Sep 2026)
-- A level costs a multiple of what one FULL Influence bar earns at that level with the best law you have,
-- so the refill on level-up can never chain into the next level by itself.
R.XpFirst, R.XpBase, R.XpStep, R.XpCap = 0.75, 1.3, 0.2, 5
local bestXp, bestCash = {}, {}
function R.BestXpPerInfluence(lv)
	if bestXp[lv] then return bestXp[lv] end
	local best = 1
	for _, L in ipairs(D.Laws) do if L.lvl <= lv then best = math.max(best, L.xp / L.cost) end end
	bestXp[lv] = best
	return best
end
function R.BestCashPerInfluence(lv)
	if bestCash[lv] then return bestCash[lv] end
	local best = 1
	for _, L in ipairs(D.Laws) do if L.lvl <= lv then best = math.max(best, L.cash / L.cost) end end
	bestCash[lv] = best
	return best
end
function R.XpReq(lv)
	local mult = lv == 1 and R.XpFirst or math.min(R.XpCap, R.XpBase + R.XpStep * (lv - 2))
	return math.floor(R.BestXpPerInfluence(lv) * R.MaxInfluence(lv) * mult + 0.5)
end
-- Value of one minute of Influence regen at this level: the yardstick convoys, battles and bosses pay against,
-- so every activity stays in proportion as the player moves through the eras.
function R.MinuteValue(lv) return R.BestCashPerInfluence(lv) * (60 / R.RegenSec) end
function R.MinuteXp(lv) return R.BestXpPerInfluence(lv) * (60 / R.RegenSec) end

---------------------------------------------------------------- laws and properties
function R.LawCash(i, passes, mult) return D.Laws[i].cash * (1 + R.MasteryPct[R.MasteryTier(passes) + 1] / 100) * (mult or 1) end
function R.LawXp(i, passes) return math.max(1, math.floor(D.Laws[i].xp * (1 + R.MasteryPct[R.MasteryTier(passes) + 1] / 100) + 0.5)) end
R.PropGrowth = 1.1 -- each copy of the same building costs 10% more
R.DemolishRefund = 0.25
function R.PropCost(i, owned) return math.floor(D.Props[i].cost * R.PropGrowth ^ (owned or 0) + 0.5) end
function R.CountProps(lots)
	local c = {}
	for _, p in ipairs(lots or {}) do if p and p > 0 then c[p] = (c[p] or 0) + 1 end end
	return c
end
function R.IncomePerHour(lots, mult)
	local t = 0
	for _, p in ipairs(lots or {}) do if p and p > 0 then t += D.Props[p].inc end end
	return t * (mult or 1)
end
-- Bank (audit H2): interest only on the first BankCapMinutes of law income at your level, so an idle balance cannot
-- compound forever. Rate per hour comes from Config.Bank.InterestPerHour x (1 + interest bonus, capped at +100%).
R.BankCapMinutes = 720
function R.BankInterestBase(bank, lv) return math.min(math.max(0, bank or 0), R.MinuteValue(lv) * R.BankCapMinutes) end
function R.EraOf(lv) local e = 1; for i, E in ipairs(D.Eras) do if lv >= E.start then e = i end end; return e end
-- Paid eras (2 Oct, Kash): reaching an era's level only unlocks the option; the player advances by paying cash.
-- d.era is the paid era; the effective era can never be above what the level allows.
function R.PlayerEra(d) if not d then return 1 end; return math.clamp(math.min(R.EraOf(d.lv or 1), d.era or 1), 1, #D.Eras) end
-- price to advance into era e: about two hours of law income at that era's starting level
function R.EraCost(e) local E = D.Eras[e]; if not E then return nil end; return math.floor(R.MinuteValue(E.start) * 120 / 1000 + 0.5) * 1000 end

---------------------------------------------------------------- ideologies (onboarding)
R.Ideologies = {
	{ key = "republic", name = "REPUBLIC", desc = "+10% property income", mod = { props = 0.10 } },
	{ key = "monarchy", name = "MONARCHY", desc = "+10% law cash", mod = { law = 0.10 } },
	{ key = "federation", name = "FEDERATION", desc = "+10% convoy pay", mod = { convoy = 0.10 } },
	{ key = "junta", name = "MILITARY JUNTA", desc = "+10% attack and defense", mod = { attack = 0.10, defense = 0.10 } },
}
R.IdeologyByKey = {}
for _, d in ipairs(R.Ideologies) do R.IdeologyByKey[d.key] = d end

R.FlagColors = { "c0392b", "e67e22", "f1c40f", "27ae60", "16a085", "2980b9", "1f3a93", "8e44ad", "ecf0f1", "1b1b1b", "7f5539", "e84393" }
R.FlagLayouts = { "h3", "v3", "h2", "v2", "cross", "diag", "canton", "border" }
-- Custom Flag pass (Kash 19:24): more layouts, colours and emblems
R.FlagLayoutsAll = { "h3", "v3", "h2", "v2", "cross", "diag", "canton", "border", "nordic", "saltire", "tri", "quad", "band", "disc" }
R.FlagColorsAll = { "c0392b", "e67e22", "f1c40f", "27ae60", "16a085", "2980b9", "1f3a93", "8e44ad", "ecf0f1", "1b1b1b", "7f5539", "e84393",
	"7b1e1e", "ff8c42", "d4af37", "0b6623", "00a7b5", "4fa3e0", "0a1f44", "5b2a86", "c0c0c0", "4a4a4a", "f5deb3", "ff69b4" }
R.FlagEmblems = { "icon_crown", "icon_sparkles", "icon_castle", "icon_flame", "icon_anvil", "icon_globe", "icon_gem", "icon_defense", "icon_leaf", "icon_rocket" }

---------------------------------------------------------------- formatting
local SUFFIX = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc" }
function R.Commas(n)
	local s = tostring(math.floor(math.abs(n) + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return (n < 0 and "-" or "") .. out
end
function R.Short(n)
	local neg = n < 0; n = math.abs(n)
	if n < 1e6 then return (neg and "-" or "") .. R.Commas(n) end
	local i = 1
	while n >= 1000 and i < #SUFFIX do n /= 1000; i += 1 end
	return (neg and "-" or "") .. string.format(n >= 100 and "%.1f%s" or "%.2f%s", n, SUFFIX[i])
end
function R.Money(n) return (n < 0 and "-$" or "$") .. R.Short(math.abs(n)) end
function R.Clock(sec)
	sec = math.max(0, math.floor(sec))
	if sec >= 3600 then return string.format("%d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60) end
	return string.format("%d:%02d", sec // 60, sec % 60)
end
function R.Duration(sec)
	sec = math.max(0, math.floor(sec))
	if sec >= 3600 then
		local h, m = sec // 3600, (sec % 3600) // 60
		return m > 0 and (h .. "h " .. m .. "m") or (h .. "h")
	end
	if sec >= 60 then return (sec // 60) .. "m" end
	return sec .. "s"
end
function R.Day(t) return math.floor((t or os.time()) / 86400) end
return R
