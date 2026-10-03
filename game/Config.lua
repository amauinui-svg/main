-- Config: everything Kash may want to tune without touching game logic.
-- Robux items were created on the Creator Dashboard on 1 Oct 2026 (universe 10768253986). 2 Oct 22:55: game copied to universe 10769117926 (owned by Kash's account) and every pass/product recreated there; ids below are the new ones, managed pricing OFF so the
-- prices stay exactly as approved (charm prices ending in 9, bigger packs cheaper per item).
local C = {}

C.Version = "Alpha 0.3"

C.Passes = {
	FastConvoys = { id = 2005160720, name = "Express Logistics", desc = "Every convoy travels 2x faster.", price = 249 },
	AutoDispatch = { id = 2005970704, name = "Auto Dispatch", desc = "Convoys pick the best load and keep trading while you are offline.", price = 399 },
	ExtraConvoys = { id = 2006912670, name = "+2 Convoy Slots", desc = "Run two more convoys at once.", price = 199 },
	ExtraLots = { id = 2006660680, name = "+3 Building Lots", desc = "Three more lots for properties.", price = 149 },
	BonusOfficer = { id = 2005112703, name = "Bonus Officer Slot", desc = "One extra officer slot on top of the ones you buy.", price = 299 },
	VIP = { id = 2006120681, name = "VIP", desc = "+10% cash from everything, +10% faster Influence regen and the VIP chat tag.", price = 499 },
	MegaVIP = { id = 2006588683, name = "Mega VIP", desc = "+25% cash, +25% faster Influence regen, a unique LIMITED officer and the MEGA VIP chat tag.", price = 899 },
	CustomFlag = { id = 2005754689, name = "Custom Flag", desc = "Design your own flag: extra layouts, emblems and colours, or use your own image.", price = 99 },
	CrateLuck = { id = 2006210718, name = "2x Crate Luck", desc = "Double the odds of Legendary and better from every crate.", price = 349 },
}
C.PassOrder = { "FastConvoys", "AutoDispatch", "ExtraConvoys", "ExtraLots", "BonusOfficer", "VIP", "MegaVIP", "CrateLuck", "CustomFlag" }

-- Popular capitals (Kash 2 Oct): shown first in onboarding. Live list comes from where players actually live;
-- this is the starting list until enough players have picked (New York, London, Sao Paulo, Los Angeles, Mexico City, Jakarta).
C.PopularCapitals = { 1, 12, 9, 2, 6, 33 }
C.PopularMinPlayers = 30

-- Tabs unlock by level (Kash 2 Oct): new players see only WORLD and LAWS, the rest open up as they level.
C.NavUnlock = { map = 1, laws = 1, properties = 2, shop = 3, country = 4, tasks = 5, military = 6, inventory = 7, bank = 8,
	battle = 10, bosses = 12, rankings = 12, alliance = 15 }

C.Products = {
	-- Founder's Crate: 49 R$ each (Kash 2 Oct), bulk cheaper per crate
	Crate1 = { id = 3716173429, robux = 49, crates = 1 },
	Crate3 = { id = 3716173492, robux = 129, crates = 3 },
	Crate10 = { id = 3716173495, robux = 399, crates = 10 },
	-- Starter Pack (Kash 2 Oct): one time, new players only. A strong property for your era + elite troops + gold.
	StarterPack = { id = 3716173499, robux = 99, gold = 100, troops = 4, maxLevel = 40 },
	GoldSmall = { id = 3716173503, robux = 49, gold = 50 },
	GoldBig = { id = 3716173507, robux = 199, gold = 250 },
	GoldHuge = { id = 3716173510, robux = 699, gold = 1000 },
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
C.GroupGift = { gold = 100, limitedCrates = 1 }
-- Watch an ad to refill Influence (rewarded video ads; the reward is the 9 R$ refill product, within Roblox's 3-10 R$ rule)
C.AdRefill = { product = "InfluenceRefillFirst", cooldown = 300 }
-- purchase shout-outs in chat (Kash 2 Oct)
C.ProductNames = { Crate1 = "a Founder's Crate", Crate3 = "3 Founder's Crates", Crate10 = "10 Founder's Crates", StarterPack = "the Starter Pack",
	GoldSmall = "50 Gold", GoldBig = "250 Gold", GoldHuge = "1,000 Gold", TreasuryGrant = "a Treasury Grant", InfluenceRefill = "an Influence Refill",
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
	Limited = { key = "limited", name = "FOUNDER'S CRATE", gold = 150, ends = 1791522000 }, -- 7 days (Kash 19:19): 2026-10-09 05:00 UTC
	-- free-to-play crate bought with in-game cash: price is this many minutes of law income at your level
	Basic = { key = "basic", name = "SUPPLY CRATE", lawMinutes = 30 },
}

C.InventoryMax = 200
return C
