-- Config: everything Kash may want to tune without touching game logic.
-- Robux items were created on the Creator Dashboard on 1 Oct 2026 (universe 10768253986). 2 Oct 22:55: game copied to universe 10769117926 (owned by Kash's account) and every pass/product recreated there; ids below are the new ones, managed pricing OFF so the
-- prices stay exactly as approved (charm prices ending in 9, bigger packs cheaper per item).
local C = {}

C.Version = "Alpha 0.4"

C.Passes = {
	FastConvoys = { id = 2005160720, name = "2x Convoy Speed", desc = "Every convoy travels 2x faster.", price = 499 }, -- Kash 00:36: R$499
	AutoDispatch = { id = 2005970704, name = "Auto Dispatch", desc = "Convoys pick the best load and keep trading while you are offline.", price = 399 },
	ExtraConvoys = { id = 2006912670, name = "+2 Convoy Slots", desc = "Run two more convoys at once.", price = 199 },
	ExtraLots = { id = 2006660680, name = "+3 Building Lots", desc = "Three more lots for properties.", price = 149 },
	BonusOfficer = { id = 2005112703, name = "Bonus Officer Slot", desc = "One extra officer slot, forever.", price = 299 },
	VIP = { id = 2006120681, name = "VIP", desc = "+10% cash from everything, +10% faster Influence regen and the VIP chat tag.", price = 499 },
	MegaVIP = { id = 2006588683, name = "Mega VIP", desc = "+25% cash, +25% faster Influence regen, a unique LIMITED officer and the MEGA VIP chat tag.", price = 899 },
	CustomFlag = { id = 2005754689, name = "Custom Flag", desc = "Design your own flag: extra layouts, emblems and colours, or use your own image.", price = 99 },
	FastInfluence = { id = 2005478758, name = "2x Influence Regen", desc = "Influence refills twice as fast.", price = 499 }, -- Kash 00:39
	FastSupply = { id = 2006054752, name = "2x Supply Regen", desc = "Supply refills twice as fast.", price = 199 }, -- Kash 00:39
	CrateLuck = { id = 2006210718, name = "2x Crate Luck", desc = "Double the odds of Legendary and better from every crate.", price = 349 },
}
C.PassOrder = { "FastInfluence", "FastConvoys", "FastSupply", "AutoDispatch", "ExtraConvoys", "ExtraLots", "BonusOfficer", "VIP", "MegaVIP", "CrateLuck", "CustomFlag" }

-- Popular capitals (Kash 2 Oct): shown first in onboarding. Live list comes from where players actually live;
-- this is the starting list until enough players have picked (New York, London, Sao Paulo, Los Angeles, Mexico City, Jakarta).
C.PopularCapitals = { 1, 12, 9, 2, 6, 33 }
C.PopularMinPlayers = 30

-- Tabs unlock by level (Kash 2 Oct): new players see only WORLD and LAWS, the rest open up as they level.
-- 2 Oct 23:38: lowered so every tab is open by level 9
-- 3 Oct 00:37 (Kash): army training and attacking other players arrive together with the shop, at level 3
C.NavUnlock = { map = 1, laws = 1, properties = 2, shop = 3, country = 3, military = 3, battle = 3, tasks = 4, inventory = 5, bank = 5,
	bosses = 7, rankings = 8, alliance = 8 } -- alliance opens at the level founding one needs (Alliance.MinLevel)

-- BADGES (Kash 2 Oct): one easy welcome badge, the rest are very hard goals. id 0 = not created yet (skipped).
C.Badges = {
	{ key = "welcome", id = 4068262154068106, name = "Founding Father", desc = "Found your own country." },
	{ key = "wonder", id = 416601157522836, name = "Wonder of the World", desc = "Complete every stage of your Wonder." },
	{ key = "stars", id = 4268395977849754, name = "To the Stars", desc = "Advance your nation to the Space Age." },
	{ key = "warlord", id = 166011714527263, name = "Warlord", desc = "Win 1,000 raids." },
	{ key = "trade", id = 1516037670244518, name = "Trade Empire", desc = "Deliver 10,000 convoys." },
	{ key = "quadrillion", id = 0, name = "Richest Nation on Earth", desc = "Earn $1 Quadrillion in total." },
	{ key = "lawgiver", id = 0, name = "Supreme Lawgiver", desc = "Reach Gold mastery on 100 laws." },
	{ key = "slayer", id = 0, name = "Tyrant Slayer", desc = "Defeat 500 bosses." },
	{ key = "alliance", id = 0, name = "Legendary Alliance", desc = "Be in an alliance that reaches level 30." },
	{ key = "forbidden", id = 0, name = "Forbidden Power", desc = "Own a FORBIDDEN officer." },
}

-- GEAR SHOP (Kash 2 Oct 23:26): restocks every 5 minutes with 3 random items of every rarity; 1 of each per player.
-- Higher rarities need high levels. Price = minutes of law income at your level (never below the unlock level).
C.GearShop = {
	Restock = 300,
	PerRarity = 3,
	Levels = { 1, 10, 25, 50, 80, 110, 140, 170 },        -- common .. forbidden
	Minutes = { 4, 10, 25, 60, 150, 360, 900, 2400 },    -- price in minutes of law income
}

-- AFK CHAMBER (Kash 3 Oct): idle 15 min -> full-screen chamber. Every 60 s a small chance to find gear.
-- Odds per minute: Find = chance anything is found; Rarity = weights for common .. forbidden (lottery-low above rare).
C.Afk = {
	IdleSeconds = 900,
	Find = 0.08,
	Rarity = { 75, 20, 4.9, 0.09, 0.009, 0.0009, 0.00009, 0.000009 },
}

-- gold prices = the Robux price of the same thing (1 gold = 1 R$, Kash 3 Oct)
C.GoldPrices = { inf = 19, sup = 19, boss = 9 }
-- finishing a convoy with gold costs the same as the Robux tier for the time left
function C.FinishGold(secondsLeft)
	local m = math.max(0, secondsLeft) / 60
	if m <= 10 then return 9 elseif m <= 60 then return 19 elseif m <= 240 then return 29 end
	return 49
end

C.Products = {
	-- Founder's Crate: 49 R$ each (Kash 2 Oct), bulk cheaper per crate
	Crate1 = { id = 3716173429, robux = 49, crates = 1 },
	Crate3 = { id = 3716173492, robux = 129, crates = 3 },
	Crate10 = { id = 3716173495, robux = 399, crates = 10 },
	-- Starter Pack (Kash 2 Oct): one time, new players only. A strong property for your era + elite troops + gold.
	StarterPack = { id = 3716173499, robux = 99, gold = 100, troops = 4, maxLevel = 40 },
	-- Gold is 1:1 with Robux (Kash 3 Oct): 1 gold = 1 R$
	GoldSmall = { id = 3716173503, robux = 49, gold = 49 },
	GoldBig = { id = 3716173507, robux = 199, gold = 210 }, -- bulk bonus (Kash 00:23)
	GoldHuge = { id = 3716173510, robux = 699, gold = 775 },
	TreasuryGrant = { id = 3716173516, robux = 49 },
	InfluenceRefill = { id = 3716173520, robux = 19 },
	InfluenceRefillFirst = { id = 3716173525, robux = 9 }, -- first refill ever is cheap (Kash 19:19)
	SupplyRefill = { id = 3716173528, robux = 19 },
	RaidShield = { id = 3716173531, robux = 39, hours = 4 },
	InstantArmy = { id = 3716173538, robux = 49 },
	RevengeStrike = { id = 3716173541, robux = 49 },
	FinishConvoy1 = { id = 3716173545, robux = 9, maxMinutes = 10 },
	FinishConvoy2 = { id = 3716173550, robux = 19, maxMinutes = 60 },
	FinishConvoy3 = { id = 3716173552, robux = 29, maxMinutes = 240 },
	FinishConvoy4 = { id = 3716173557, robux = 49, maxMinutes = math.huge },
	ChallengeRefresh = { id = 3716173558, robux = 19 },
	MoveCapital = { id = 3716173563, robux = 99 },
	-- Change Government (Kash 2 Oct): pick a different government later on. id 0 until the product is created.
	ChangeGovernment = { id = 3716173564, robux = 99 },
	LimitedBundle = { id = 3716173567, robux = 999 },
}

-- Studio testing: owners get every gamepass in Studio so the paid paths can be tested
-- (workspace attribute IC_NoPasses turns this off).
C.StudioGrantsPasses = true

-- Roblox Premium members: +5% cash. Group members: +10% cash (GroupId 0 = no group yet; Kash to provide).
C.PremiumBonus = 0.05
C.Group = { Id = 3735672, Bonus = 0.10 }
-- FREE GIFT button (Kash 2 Oct): stays on the Laws screen until the player is in the group. One time gift on claim.
C.HiddenFromRankings = { [250229074] = true } -- Kash 3 Oct: the owner never appears on the leaderboards
C.GroupGift = { gold = 100, limitedCrates = 1 }
-- Watch an ad to refill Influence (rewarded video ads; the reward is the 9 R$ refill product, within Roblox's 3-10 R$ rule)
C.AdRefill = { product = "InfluenceRefillFirst", cooldown = 300 }
-- purchase shout-outs in chat (Kash 2 Oct)
C.ProductNames = { Crate1 = "a Founder's Crate", Crate3 = "3 Founder's Crates", Crate10 = "10 Founder's Crates", StarterPack = "the Starter Pack",
	GoldSmall = "49 Gold", GoldBig = "210 Gold", GoldHuge = "775 Gold", TreasuryGrant = "a Treasury Grant", InfluenceRefill = "an Influence Refill",
	InfluenceRefillFirst = "an Influence Refill", SupplyRefill = "a Supply Refill", RaidShield = "a Raid Shield", InstantArmy = "an Instant Army",
	RevengeStrike = "a Revenge Strike", FinishConvoy1 = "an instant convoy", FinishConvoy2 = "an instant convoy", FinishConvoy3 = "an instant convoy",
	FinishConvoy4 = "an instant convoy", ChallengeRefresh = "a Challenge Refresh", MoveCapital = "a Capital Move", LimitedBundle = "the Limited Bundle",
	ChangeGovernment = "a new Government" }

-- Rent (Kash 18:49): the alliance holding a capital may charge its residents this % of their property income.
-- Max by city tier (city, capital, major capital, global city). New players pay nothing for 48 hours. Silent.
C.Rent = { Max = { 2, 4, 6, 8 }, GraceHours = 48 }

-- VIP tiers (Kash 16:54): Mega VIP replaces VIP (they do not stack)
C.VIP = { VIP = { cash = 0.10, regen = 0.10, tag = "VIP", color = "f0c75a" }, MegaVIP = { cash = 0.25, regen = 0.25, tag = "MEGA VIP", color = "ff4f8b" } }

C.Alliance = {
	MinLevel = 8,
	CreateCost = 50000,
	MaxMembers = 30,
	MaxCities = 10,
	Colors = { "c0392b", "d35400", "d4a017", "27ae60", "16a085", "2980b9", "2c3e91", "8e44ad", "c2185b", "6d4c41", "546e7a", "1b1b1b" },
	TaxMax = 15,
	TaxChangeCooldown = 24 * 3600,
	ProtectSeconds = 3600,
	ContributionResetSeconds = 30 * 60,
	TreasuryFlushSeconds = 30,
	-- Kash 1 Oct: leaders may charge a join fee and dues (% of every member's earnings, to the treasury).
	-- Dues style: flat (everyone pays the base), prog (higher levels pay more), regr (lower levels pay more);
	-- each member's rate scales from half to double the base by their level vs the alliance average, never above DuesCap.
	DuesMax = 10,
	DuesCap = 15,
	FeeMax = 1e15,
	SettingsCooldown = 24 * 3600,
}

-- Bank (Kash 1 Oct): deposits cost 10%, withdrawals are free, 1.5% interest per hour on the balance,
-- paid every second online and at half rate while offline (offline is capped at 12 h like everything else).
C.Bank = { DepositFee = 0.10, InterestPerHour = 0.015, OfflineShare = 0.5 }

-- Raids (Kash 1 Oct): only people in your server plus 3 AI nations. Winner takes 10% of the defender's cash ON HAND
-- (banked cash is safe), capped at about an hour of the defender's own law income. The same player can be raided
-- again after 1 minute. Soldiers die on both sides depending on how lopsided the fight was.
C.Raid = {
	Supply = 2,
	StealPct = 0.10,
	CapLawMinutes = 60,
	Cooldown = 60,
	AICount = 3,
	AIMinTargetLevel = 5, -- AI nations leave brand-new countries alone until level 5
	AIRaidEvery = { 150, 330 }, -- seconds between AI raids in a server (random in range)
	-- {winner loss, loser loss} by margin
	Losses = { sweep = { 0.02, 0.20 }, clear = { 0.05, 0.15 }, close = { 0.10, 0.12 } },
}

C.Officers = {
	StartSlots = 1,
	-- cash price of each extra slot (slot 2, 3, ...): every slot costs more than the last. Same for every player.
	SlotCosts = { 50e3, 5e6, 500e6, 50e9, 5e12, 500e12 },
	-- three hire options, the same for every player (not level-scaled). Expensive is very late game.
	Hire = {
		{ key = "cheap", name = "LOCAL RECRUITER", cost = 20e3 },
		{ key = "medium", name = "NATIONAL ACADEMY", cost = 25e6 },
		{ key = "expensive", name = "WORLD SUMMIT", cost = 10e12 },
	},
	BenchMax = 40, -- hired officers not in a slot wait on the bench (Inventory)
}

C.Crates = {
	-- the first limited crate (rotates later). Same crate, two prices: gold or Robux.
	Limited = { key = "limited", name = "FOUNDER'S CRATE", gold = 49, ends = 1791627808 }, -- 7 days from the 3 Oct 2026 launch reset (Kash 00:23): 2026-10-10 10:23 UTC
	-- free-to-play crate bought with in-game cash: price is this many minutes of law income at your level
	Basic = { key = "basic", name = "SUPPLY CRATE", lawMinutes = 30 },
}

C.InventoryMax = 200
return C
