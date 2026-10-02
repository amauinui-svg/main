-- Officers, gear and crates (Kash 1 Oct 2026). Shared so the client shows exactly what the server rolls.
-- Officers: every hire is unique (own name, rarity, random traits). No duplicates, no merging. Firing gives nothing.
-- Gear: weapons (+attack %) and armor (+defense %), worn by the player or an officer. Legendary+ gear has a bonus perk.
local O = {}

O.Rarities = {
	{ key = "common", name = "COMMON", color = "b9bdc3", traits = 1, range = { 2, 4 }, gear = 3 },
	{ key = "rare", name = "RARE", color = "4f9be8", traits = 2, range = { 4, 7 }, gear = 6 },
	{ key = "epic", name = "EPIC", color = "b06ef0", traits = 2, range = { 7, 11 }, gear = 10 },
	{ key = "legendary", name = "LEGENDARY", color = "f0c75a", traits = 3, range = { 11, 16 }, gear = 15 },
	{ key = "mythic", name = "MYTHIC", color = "ff5a7a", traits = 4, range = { 16, 24 }, gear = 22 },
	{ key = "limited", name = "LIMITED", color = "3fe8d0", traits = 4, range = { 20, 28 }, gear = 30 },
}
O.RarityByKey = {}
for i, r in ipairs(O.Rarities) do r.index = i; O.RarityByKey[r.key] = r end

-- trait key -> what it boosts (all are percentages)
O.Traits = {
	{ key = "law", name = "law cash", title = "Treasurer", icon = "icon_laws" },
	{ key = "props", name = "property income", title = "Minister of Works", icon = "icon_properties" },
	{ key = "convoy", name = "convoy pay", title = "Quartermaster", icon = "icon_package" },
	{ key = "xp", name = "XP", title = "Chancellor", icon = "icon_xp" },
	{ key = "attack", name = "attack", title = "General", icon = "icon_attack" },
	{ key = "defense", name = "defense", title = "Marshal", icon = "icon_defense" },
	{ key = "loot", name = "raid loot", title = "Spymaster", icon = "icon_crosshair" },
	{ key = "losses", name = "fewer soldier deaths", title = "Surgeon General", icon = "icon_users" },
	{ key = "interest", name = "bank interest", title = "Central Banker", icon = "icon_bank" },
	{ key = "regen", name = "Influence regen", title = "Chief Whip", icon = "icon_influence" },
	{ key = "siege", name = "siege damage", title = "Siegemaster", icon = "icon_castle" },
	{ key = "boss", name = "boss damage", title = "Champion", icon = "icon_bosses" },
}
O.TraitByKey = {}
for _, t in ipairs(O.Traits) do O.TraitByKey[t.key] = t end
O.Caps = { losses = 60, regen = 100 } -- totals never go above these

local FIRST = { "Ada", "Marek", "Ines", "Tobias", "Yara", "Kenji", "Amara", "Viktor", "Lucia", "Omar", "Freya", "Dmitri", "Noor",
	"Hugo", "Sana", "Elias", "Mira", "Rafael", "Ilse", "Kwame", "Anya", "Teodor", "Leila", "Bastian", "Zofia", "Idris", "Clara",
	"Matteo", "Saoirse", "Arjun", "Helene", "Joaquin", "Ingrid", "Tariq", "Odette", "Pavel", "Rosa", "Emil", "Nadia", "Casimir" }
local LAST = { "Varga", "Okafor", "Lindqvist", "Moreau", "Castellanos", "Halloran", "Ivanova", "Ferreira", "Nakamura", "Brandt",
	"Ostrowski", "Mensah", "Delacroix", "Rahimi", "Kowalski", "Sorensen", "Albescu", "Thorne", "Quintero", "Vasquez", "Adeyemi",
	"Grimaldi", "Hartmann", "Novak", "Laurent", "Petrov", "Achterberg", "Silva", "Draycott", "Mbeki", "Rasmussen", "Calloway" }
O.Portraits = 8

-- odds (percent) by source: common, rare, epic, legendary, mythic
O.HireOdds = {
	cheap = { 70, 24, 5, 0.9, 0.1 },
	medium = { 35, 40, 18, 6, 1 },
	expensive = { 0, 30, 40, 22, 8 },
	crate_officer = { 0, 45, 35, 15, 5 },
	basic_officer = { 60, 32, 7, 1, 0 },
}
O.GearOdds = {
	limited = { 0, 50, 30, 15, 5 }, -- the Founder's Crate
	basic = { 62, 30, 7, 1, 0 },
}

function O.Roll(rng, odds, luck)
	local w = table.clone(odds)
	if luck then w[4] *= 2; w[5] *= 2 end -- 2x Crate Luck pass
	local total = 0
	for _, v in ipairs(w) do total += v end
	local x = rng:NextNumber() * total
	for i, v in ipairs(w) do
		x -= v
		if x <= 0 then return i end
	end
	return 1
end

local function pickTraits(rng, rar, avoid)
	local pool = {}
	for _, t in ipairs(O.Traits) do table.insert(pool, t.key) end
	local out = {}
	for n = 1, rar.traits do
		local i = rng:NextInteger(1, #pool)
		-- the first trait of a new hire differs from the previous hire's (Kash: "different traits than the last one")
		if n == 1 and avoid and #pool > 1 then
			local guard = 0
			while pool[i] == avoid and guard < 10 do i = rng:NextInteger(1, #pool); guard += 1 end
		end
		local key = table.remove(pool, i)
		table.insert(out, { k = key, v = rng:NextInteger(rar.range[1], rar.range[2]) })
	end
	table.sort(out, function(a, b) return a.v > b.v end)
	return out
end

function O.NewOfficer(rng, rarityIndex, avoidTrait)
	local rar = O.Rarities[rarityIndex]
	local traits = pickTraits(rng, rar, avoidTrait)
	return {
		id = string.format("o%x%04x", os.time(), rng:NextInteger(0, 65535)),
		name = FIRST[rng:NextInteger(1, #FIRST)] .. " " .. LAST[rng:NextInteger(1, #LAST)],
		rarity = rar.key, traits = traits, title = O.TraitByKey[traits[1].k].title,
		portrait = rng:NextInteger(1, O.Portraits), hired = os.time(),
	}
end

---------------------------------------------------------------- gear
O.WeaponTypes = { { "Sword", "gear_sword" }, { "Spear", "gear_spear" }, { "Musket", "gear_musket" }, { "Saber", "gear_saber" }, { "Rifle", "gear_rifle" }, { "Halberd", "gear_halberd" } }
O.ArmorTypes = { { "Helm", "gear_helm" }, { "Cuirass", "gear_cuirass" }, { "Greatcoat", "gear_coat" }, { "Shield", "gear_shield" }, { "Plate", "gear_plate" } }
local ADJ = {
	{ "Iron", "Worn", "Plain" }, { "Steel", "Fine", "Tempered" }, { "Damascus", "Masterwork", "Engraved" },
	{ "Gilded", "Royal", "Imperial" }, { "Celestial", "Dragonbone", "Stormforged" }, { "Founder's" },
}

function O.NewGear(rng, rarityIndex, kind)
	kind = kind or (rng:NextNumber() < 0.5 and "weapon" or "armor")
	local types = kind == "weapon" and O.WeaponTypes or O.ArmorTypes
	local t = types[rng:NextInteger(1, #types)]
	local adj = ADJ[rarityIndex]
	local rar = O.Rarities[rarityIndex]
	local g = {
		id = string.format("g%x%04x", os.time(), rng:NextInteger(0, 65535)),
		kind = kind, type = t[1], icon = t[2], rarity = rar.key,
		name = adj[rng:NextInteger(1, #adj)] .. " " .. t[1], power = rar.gear,
	}
	if rarityIndex >= 4 then
		-- Legendary and better roll a bonus perk
		local perkRange = { 4, 6, 8 }
		local trait = O.Traits[rng:NextInteger(1, #O.Traits)]
		g.perk = { k = trait.key, v = perkRange[math.min(3, rarityIndex - 3)] + rng:NextInteger(0, 3) }
	end
	return g
end

-- the 999 Robux Limited Bundle (Kash 1 Oct): a limited officer and a limited weapon with strong buffs
function O.BundleOfficer()
	return {
		id = "o_founder", name = "Empress Valeria Thorne", rarity = "limited", title = "Founder",
		traits = { { k = "law", v = 25 }, { k = "attack", v = 25 }, { k = "loot", v = 20 }, { k = "losses", v = 20 } },
		portrait = 0, hired = os.time(), limited = true,
	}
end
function O.BundleGear()
	return { id = "g_founder", kind = "weapon", type = "Saber", icon = "gear_saber", rarity = "limited",
		name = "Founder's Saber", power = 30, perk = { k = "loot", v = 15 }, limited = true }
end

---------------------------------------------------------------- crates
-- Founder's Crate: mostly gear, sometimes an officer. Basic Supply Crate: mostly common gear.
function O.OpenCrate(rng, kind, luck, forceEpic)
	if kind == "limited" then
		if rng:NextNumber() < 0.25 then
			local r = O.Roll(rng, O.HireOdds.crate_officer, luck)
			if forceEpic then r = math.max(r, 3) end
			return { type = "officer", item = O.NewOfficer(rng, r) }
		end
		local r = O.Roll(rng, O.GearOdds.limited, luck)
		if forceEpic then r = math.max(r, 3) end
		return { type = "gear", item = O.NewGear(rng, r) }
	end
	if rng:NextNumber() < 0.08 then
		return { type = "officer", item = O.NewOfficer(rng, O.Roll(rng, O.HireOdds.basic_officer, luck)) }
	end
	return { type = "gear", item = O.NewGear(rng, O.Roll(rng, O.GearOdds.basic, luck)) }
end

---------------------------------------------------------------- bonuses
-- sum of every slotted officer's traits plus the gear worn by the player and slotted officers
-- returns { law=0.12, attack=0.3, ... } as fractions, plus atkGear/defGear
function O.Bonuses(cab, inv)
	local b = {}
	for _, t in ipairs(O.Traits) do b[t.key] = 0 end
	b.gearAtk, b.gearDef = 0, 0
	if not cab or not inv then return b end
	local function wear(holder)
		for _, slot in ipairs({ "weapon", "armor" }) do
			local g = holder and holder[slot] and inv.gear[holder[slot]]
			if g then
				if g.kind == "weapon" then b.gearAtk += g.power else b.gearDef += g.power end
				if g.perk then b[g.perk.k] += g.perk.v end
			end
		end
	end
	wear(cab.player)
	for _, oid in ipairs(cab.slots or {}) do
		local o = oid and inv.officers[oid]
		if o then
			for _, t in ipairs(o.traits) do b[t.k] += t.v end
			wear(o)
		end
	end
	for k, cap in pairs(O.Caps) do b[k] = math.min(b[k], cap) end
	for k, v in pairs(b) do b[k] = v / 100 end
	return b
end
return O
