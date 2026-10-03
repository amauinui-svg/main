-- Officers, gear and crates (Kash 1 Oct 2026). Shared so the client shows exactly what the server rolls.
-- Officers: every hire is unique (own name, rarity, random traits). No duplicates, no merging. Firing gives nothing.
-- Gear: weapons (+attack %) and armor (+defense %), worn by the player or an officer. Legendary+ gear has a bonus perk.
local O = {}

-- 8 tiers like the reference game (Kash 1 Oct 16:45), plus LIMITED for bundle/VIP exclusives
O.Rarities = {
	{ key = "common", name = "COMMON", color = "c9ccd1", traits = 1, range = { 2, 3 }, gear = 2 },
	{ key = "uncommon", name = "UNCOMMON", color = "6fcf6a", traits = 1, range = { 3, 5 }, gear = 4 },
	{ key = "rare", name = "RARE", color = "5b9be6", traits = 2, range = { 4, 7 }, gear = 6 },
	{ key = "epic", name = "EPIC", color = "b06ef0", traits = 2, range = { 7, 11 }, gear = 10 },
	{ key = "legendary", name = "LEGENDARY", color = "e9b949", traits = 3, range = { 11, 16 }, gear = 15 },
	{ key = "mythic", name = "MYTHIC", color = "ff4f8b", traits = 3, range = { 16, 22 }, gear = 22 },
	{ key = "secret", name = "SECRET", color = "3fe0d0", traits = 4, range = { 22, 30 }, gear = 30 },
	{ key = "forbidden", name = "FORBIDDEN", color = "ff3b30", traits = 4, range = { 30, 40 }, gear = 40 },
	{ key = "limited", name = "LIMITED", color = "ff9a2e", traits = 4, range = { 20, 28 }, gear = 30 },
}
O.RollTiers = 8 -- limited is never rolled
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
O.Caps = { losses = 60, regen = 100, interest = 100 } -- totals never go above these

local FIRST = { "Ada", "Marek", "Ines", "Tobias", "Yara", "Kenji", "Amara", "Viktor", "Lucia", "Omar", "Freya", "Dmitri", "Noor",
	"Hugo", "Sana", "Elias", "Mira", "Rafael", "Ilse", "Kwame", "Anya", "Teodor", "Leila", "Bastian", "Zofia", "Idris", "Clara",
	"Matteo", "Saoirse", "Arjun", "Helene", "Joaquin", "Ingrid", "Tariq", "Odette", "Pavel", "Rosa", "Emil", "Nadia", "Casimir" }
local LAST = { "Varga", "Okafor", "Lindqvist", "Moreau", "Castellanos", "Halloran", "Ivanova", "Ferreira", "Nakamura", "Brandt",
	"Ostrowski", "Mensah", "Delacroix", "Rahimi", "Kowalski", "Sorensen", "Albescu", "Thorne", "Quintero", "Vasquez", "Adeyemi",
	"Grimaldi", "Hartmann", "Novak", "Laurent", "Petrov", "Achterberg", "Silva", "Draycott", "Mbeki", "Rasmussen", "Calloway" }
O.Portraits = 8

-- odds (percent) by source: common, rare, epic, legendary, mythic
-- odds in percent: common, uncommon, rare, epic, legendary, mythic, secret, forbidden (copied from the reference)
O.HireOdds = {
	cheap = { 44.85, 26.9, 16.6, 8.5, 2.5, 0.6, 0.05, 0 },
	medium = { 0, 0, 58.75, 28, 11, 2, 0.25, 0 },
	expensive = { 0, 0, 0, 50.2, 37, 10, 2.6, 0.2 },
	crate_officer = { 0, 30, 35, 22, 9, 3.5, 0.45, 0.05 },
	basic_officer = { 50, 30, 14, 5, 1, 0, 0, 0 },
}
O.GearOdds = {
	limited = { 0, 30, 35, 22, 9, 3.5, 0.45, 0.05 }, -- the Founder's Crate
	basic = { 45, 30, 17, 6, 1.7, 0.3, 0, 0 },
}

function O.Roll(rng, odds, luck)
	local w = table.clone(odds)
	if luck then for i = 5, #w do w[i] *= 2 end end -- 2x Crate Luck pass: legendary and up
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
		id = string.format("o%x%06x", os.time(), rng:NextInteger(0, 16777215)),
		name = FIRST[rng:NextInteger(1, #FIRST)] .. " " .. LAST[rng:NextInteger(1, #LAST)],
		rarity = rar.key, traits = traits, title = O.TraitByKey[traits[1].k].title,
		portrait = rng:NextInteger(1, O.Portraits), hired = os.time(),
	}
end

---------------------------------------------------------------- gear
O.WeaponTypes = { { "Sword", "gear_sword" }, { "Spear", "gear_spear" }, { "Musket", "gear_musket" }, { "Saber", "gear_saber" }, { "Rifle", "gear_rifle" }, { "Halberd", "gear_halberd" } }
O.ArmorTypes = { { "Helm", "gear_helm" }, { "Cuirass", "gear_cuirass" }, { "Greatcoat", "gear_coat" }, { "Shield", "gear_shield" }, { "Plate", "gear_plate" } }
local ADJ = {
	{ "Iron", "Worn", "Plain" }, { "Steel", "Sturdy", "Fine" }, { "Tempered", "Veteran's", "Polished" },
	{ "Damascus", "Masterwork", "Engraved" }, { "Gilded", "Royal", "Imperial" }, { "Celestial", "Dragonbone", "Stormforged" },
	{ "Phantom", "Eclipse", "Voidforged" }, { "Forbidden", "Cursed", "Doomsday" }, { "Founder's" },
}

function O.NewGear(rng, rarityIndex, kind)
	kind = kind or (rng:NextNumber() < 0.5 and "weapon" or "armor")
	local types = kind == "weapon" and O.WeaponTypes or O.ArmorTypes
	local t = types[rng:NextInteger(1, #types)]
	local adj = ADJ[rarityIndex]
	local rar = O.Rarities[rarityIndex]
	local g = {
		id = string.format("g%x%06x", os.time(), rng:NextInteger(0, 16777215)),
		kind = kind, type = t[1], icon = t[2], rarity = rar.key,
		name = adj[rng:NextInteger(1, #adj)] .. " " .. t[1], power = rar.gear,
	}
	if rarityIndex >= 5 then
		-- Legendary and better roll a bonus perk
		local perkRange = { 4, 6, 8, 10, 12 }
		local trait = O.Traits[rng:NextInteger(1, #O.Traits)]
		g.perk = { k = trait.key, v = perkRange[math.min(5, rarityIndex - 4)] + rng:NextInteger(0, 3) }
	end
	return g
end

-- the 999 Robux Limited Bundle (Kash 1 Oct): a limited officer and a limited weapon with strong buffs
function O.BundleOfficer()
	return {
		id = "o_founder", name = "Empress Valeria Thorne", rarity = "limited", title = "Founder",
		traits = { { k = "law", v = 25 }, { k = "attack", v = 25 }, { k = "loot", v = 20 }, { k = "losses", v = 20 } },
		portrait = 0, img = "officer_founder", hired = os.time(), limited = true,
	}
end
-- the Mega VIP pass officer (Kash 16:54): unique, limited
function O.VIPOfficer()
	return {
		id = "o_megavip", name = "Marshal Aurelio Vance", rarity = "limited", title = "Mega VIP",
		traits = { { k = "law", v = 20 }, { k = "props", v = 20 }, { k = "defense", v = 20 }, { k = "regen", v = 15 } },
		portrait = 1, img = "officer_megavip", hired = os.time(), limited = true,
	}
end
function O.BundleGear()
	return { id = "g_founder", kind = "weapon", type = "Saber", icon = "gear_saber", rarity = "limited",
		name = "Founder's Saber", power = 30, perk = { k = "loot", v = 15 }, limited = true }
end

---------------------------------------------------------------- crates (Kash 2 Oct)
-- Founder's Crate: gear or ELITE TROOPS, never officers. Supply Crate: mostly gear, sometimes an officer, but only when
-- you have an open officer slot (no bench). Every box shows these exact numbers in its info popup.
O.EliteChance = 0.25
O.EliteSize = { 2, 3, 4, 6, 9, 13, 18, 25 } -- elite troops per pack by rolled rarity (common .. forbidden)
O.BasicOfficerChance = 0.08
O.CrateInfo = {
	limited = {
		{ label = "Gear (weapon or armor)", pct = 75, odds = O.GearOdds.limited },
		{ label = "Elite troops (pack size by rarity)", pct = 25, odds = O.GearOdds.limited },
	},
	basic = {
		{ label = "Gear (weapon or armor)", pct = 92, odds = O.GearOdds.basic },
		{ label = "Officer (only with an open slot, else gear)", pct = 8, odds = O.HireOdds.basic_officer },
	},
}
-- ctx = { era = your era, slotFree = true/false }
-- minRarity: nil, true (Epic, the 10-pack guarantee) or a rarity index (the pity guarantee). Rolls below it are raised to it.
function O.OpenCrate(rng, kind, luck, minRarity, ctx)
	ctx = ctx or {}
	local floor = minRarity == true and 4 or (tonumber(minRarity) or 1)
	local function roll(odds) return math.max(O.Roll(rng, odds, luck), floor) end
	if kind == "limited" then
		if rng:NextNumber() < O.EliteChance then
			local rar = O.Rarities[roll(O.GearOdds.limited)]
			return { type = "troops", item = { era = math.clamp(ctx.era or 1, 1, 8), n = O.EliteSize[rar.index], rarity = rar.key } }
		end
		return { type = "gear", item = O.NewGear(rng, roll(O.GearOdds.limited)) }
	end
	if ctx.slotFree and rng:NextNumber() < O.BasicOfficerChance then
		return { type = "officer", item = O.NewOfficer(rng, roll(O.HireOdds.basic_officer)) }
	end
	return { type = "gear", item = O.NewGear(rng, roll(O.GearOdds.basic)) }
end

-- PITY (Kash 2 Oct, visible): every crate without a Legendary or better fills the meter; when it is full the next
-- crate is guaranteed Legendary or better, and any Legendary+ drop empties it.
O.Pity = { limited = 30, basic = 50 }
O.PityRarity = 5 -- legendary

---------------------------------------------------------------- bonuses
-- sum of every slotted officer's traits plus the gear worn by the player and slotted officers
-- returns { law=0.12, attack=0.3, ... } as fractions, plus atkGear/defGear
function O.Bonuses(cab, inv, maxSlots)
	local b = {}
	for _, t in ipairs(O.Traits) do b[t.key] = 0 end
	b.gearAtk, b.gearDef = 0, 0
	if not cab or not inv then return b end
	local function wear(holder)
		for _, slot in ipairs({ "weapon", "armor" }) do
			local g = holder and holder[slot] and inv.gear[holder[slot]]
			if g then
				if g.kind == "weapon" then b.gearAtk += g.power else b.gearDef += g.power end
				if g.perk and b[g.perk.k] then b[g.perk.k] += g.perk.v end -- unknown keys ignored (audit L10)
			end
		end
	end
	wear(cab.player)
	-- limited officers sit in their own exclusive slots and always count (Kash 2 Oct)
	for _, oid in ipairs(cab.ltd or {}) do
		local o = inv.officers[oid]
		if o then
			for _, t in ipairs(o.traits or {}) do if b[t.k] then b[t.k] += t.v end end
			wear(o)
		end
	end
	for si, oid in ipairs(cab.slots or {}) do
		local o = oid and (not maxSlots or si <= maxSlots) and inv.officers[oid]
		if o then
			for _, t in ipairs(o.traits or {}) do if b[t.k] then b[t.k] += t.v end end
			wear(o)
		end
	end
	for k, cap in pairs(O.Caps) do b[k] = math.min(b[k], cap) end
	for k, v in pairs(b) do b[k] = v / 100 end
	return b
end
return O
