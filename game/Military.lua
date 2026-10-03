-- Military: units (Military tab), player power, bosses and battle odds. Shared by server and client.
local Rules = require(script.Parent.Rules)
local D = require(script.Parent.GameData)
local M = {}

local ERA_UNITS = {
	{ "Spearmen", "War Chariots", "Archers" },
	{ "Legionaries", "Cavalry", "Catapults" },
	{ "Men-at-Arms", "Knights", "Trebuchets" },
	{ "Musketeers", "Dragoons", "Cannon Battery" },
	{ "Riflemen", "Ironclads", "Field Artillery" },
	{ "Infantry Squad", "Tank Platoon", "Air Defense" },
	{ "Special Forces", "Strike Drones", "Missile Battery" },
	{ "Exo Troopers", "Hover Tanks", "Shield Array" },
}
-- tier 1 balanced, tier 2 attack, tier 3 defense
local SHAPE = { { 4, 4, 300, "icon_users" }, { 9, 3, 900, "icon_attack" }, { 3, 9, 900, "icon_defense" } }
M.Units = {}
for e, names in ipairs(ERA_UNITS) do
	for t = 1, 3 do
		local s = SHAPE[t]
		local g = 2.6 ^ (e - 1)
		table.insert(M.Units, {
			name = names[t], era = e, tier = t, icon = s[4],
			atk = math.floor(s[1] * g + 0.5), def = math.floor(s[2] * g + 0.5),
			cost = math.floor(s[3] * 35 ^ (e - 1) + 0.5),
			lvl = (e == 1) and ({ 1, 4, 6 })[t] or (D.Eras[e].start + (t - 1) * 3),
		})
	end
end
-- ELITE troops (Kash 2 Oct): only from the Founder's Crate. One elite unit per era, much stronger than that era's
-- regulars. Kept in their own table (d.elite[era] = count): they never die in raids and do not use army capacity.
M.Elite = {}
local ELITE_NAMES = { "Royal Guard", "Praetorians", "Templar Knights", "Grenadier Guard", "Imperial Hussars", "Commandos", "Ghost Operatives", "Star Legion" }
for e, n in ipairs(ELITE_NAMES) do
	local g = 2.6 ^ (e - 1)
	M.Elite[e] = { name = n, era = e, atk = math.floor(14 * g + 0.5), def = math.floor(14 * g + 0.5), icon = "icon_crown" }
end
function M.EliteCount(elite) local n = 0; for _, c in pairs(elite or {}) do n += (tonumber(c) or 0) end; return n end
M.UnitGrowth = 1.06 -- each copy of a unit costs 6% more
function M.UnitCost(i, owned) return math.floor(M.Units[i].cost * M.UnitGrowth ^ (owned or 0) + 0.5) end
function M.UnitCap(lv) return 10 + lv end
function M.UnitCount(units) local n = 0; for _, c in pairs(units or {}) do n += c end; return n end

-- player power. mods = { attack = 0.1, defense = 0.1 } from ideology + alliance cities
function M.Power(lv, sk, units, mods, elite)
	local atk, def = 5 + 2 * lv + 4 * ((sk and sk.atk) or 0), 5 + 2 * lv + 4 * ((sk and sk.def) or 0)
	for k, c in pairs(units or {}) do
		local u = M.Units[tonumber(k)]
		if u then atk += u.atk * c; def += u.def * c end
	end
	for k, c in pairs(elite or {}) do
		local u = M.Elite[tonumber(k)]
		if u then atk += u.atk * c; def += u.def * c end
	end
	atk = math.floor(atk * (1 + ((mods and mods.attack) or 0)))
	def = math.floor(def * (1 + ((mods and mods.defense) or 0)))
	return atk, def
end

function M.WinChance(atk, def) return math.clamp(0.5 + (atk - def) / math.max(1, atk + def) * 1.3, 0.05, 0.95) end

M.Bosses = {
	{ "The Bandit King", "Raids the river villages" }, { "Barbarian Warlord", "Masses at the frontier" },
	{ "The Black Baron", "Holds the mountain pass" }, { "Pirate Admiral", "Blockades the trade lanes" },
	{ "Robber Baron", "Owns the railways and the police" }, { "Rogue General", "Seized the northern provinces" },
	{ "Cyber Syndicate", "Holds the grid to ransom" }, { "The Void Fleet", "Orbits the capital" },
}
function M.BossHp(era) return math.floor(2500 * 3.2 ^ (era - 1) + 0.5) end
M.BossCooldown = 3600
M.BossGold = { 3, 4, 5, 6, 8, 10, 12, 15 }

-- SIEGES. Damage is era-neutral on purpose: a level-150 player must not one-shot a city, so siege damage grows with
-- level, Attack skill and army size, not with unit stats (which grow 2.6x per era).
-- 1 Supply = 1 hit. Reinforcing spends Supply the same way and adds the same amount of garrison.
M.NeutralGarrison = { 3000, 8000, 20000, 45000 } -- tier 4 = global cities (Kash 18:49)
function M.SiegeDamage(lv, sk, units, mods)
	local base = 50 + 5 * lv + 10 * ((sk and sk.atk) or 0) + 2 * M.UnitCount(units)
	return math.floor(base * (1 + ((mods and mods.attack) or 0)) + 0.5)
end
-- battles against rival nations (Battle tab) and boss hits
M.BattleSupply = 2
M.BossSupply = 1
M.SiegeSupply = 1
function M.BossDamage(atk) return atk * 3 end
M.GarrisonCapMult = 3 -- reinforcing can raise a garrison to 3x its neutral size
return M
