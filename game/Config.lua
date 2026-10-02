-- Config: everything Kash may want to tune without touching game logic.
-- Robux items were created on the Creator Dashboard on 1 Oct 2026 (universe 10768253986), managed pricing OFF so the
-- prices stay exactly as approved (charm prices ending in 9, bigger packs cheaper per item).
local C = {}

C.Version = "Alpha 0.2"

C.Passes = {
	FastConvoys = { id = 2006396309, name = "Express Logistics", desc = "Every convoy travels 2x faster.", price = 249 },
	AutoDispatch = { id = 2005532295, name = "Auto Dispatch", desc = "Convoys pick the best load and keep trading while you are offline.", price = 399 },
	ExtraConvoys = { id = 2005070299, name = "+2 Convoy Slots", desc = "Run two more convoys at once.", price = 199 },
	ExtraLots = { id = 2004536361, name = "+3 Building Lots", desc = "Three more lots for properties.", price = 149 },
	BonusOfficer = { id = 2007026302, name = "Bonus Officer Slot", desc = "One extra officer slot on top of the ones you buy.", price = 299 },
	VIP = { id = 2008088291, name = "VIP", desc = "+10% law cash, property income, convoy pay and XP. VIP tag and map pin.", price = 499 },
	CrateLuck = { id = 2006090287, name = "2x Crate Luck", desc = "Double the odds of Legendary and better from every crate.", price = 349 },
}
C.PassOrder = { "FastConvoys", "AutoDispatch", "ExtraConvoys", "ExtraLots", "BonusOfficer", "VIP", "CrateLuck" }

C.Products = {
	Crate1 = { id = 3715911170, robux = 29, crates = 1 },
	Crate3 = { id = 3715911208, robux = 79, crates = 3 },
	Crate10 = { id = 3715911255, robux = 229, crates = 10 },
	GoldSmall = { id = 3715911284, robux = 49, gold = 50 },
	GoldBig = { id = 3715911319, robux = 199, gold = 250 },
	GoldHuge = { id = 3715911358, robux = 699, gold = 1000 },
	TreasuryGrant = { id = 3715911479, robux = 49 },
	InfluenceRefill = { id = 3715911506, robux = 19 },
	SupplyRefill = { id = 3715911507, robux = 19 },
	RaidShield = { id = 3715911508, robux = 39, hours = 4 },
	InstantArmy = { id = 3715911510, robux = 49 },
	RevengeStrike = { id = 3715911512, robux = 49 },
	FinishConvoy1 = { id = 3715911514, robux = 9, maxMinutes = 10 },
	FinishConvoy2 = { id = 3715911516, robux = 19, maxMinutes = 60 },
	FinishConvoy3 = { id = 3715911518, robux = 29, maxMinutes = 240 },
	FinishConvoy4 = { id = 3715911519, robux = 49, maxMinutes = math.huge },
	ChallengeRefresh = { id = 3715911521, robux = 19 },
	MoveCapital = { id = 3715911522, robux = 99 },
	LimitedBundle = { id = 3715911526, robux = 999 },
}

-- Studio testing: owners get every gamepass in Studio so the paid paths can be tested
-- (workspace attribute IC_NoPasses turns this off).
C.StudioGrantsPasses = true

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
	Limited = { key = "limited", name = "FOUNDER'S CRATE", gold = 150, ends = 1793145600 }, -- 2026-10-29 00:00 UTC
	-- free-to-play crate bought with in-game cash: price is this many minutes of law income at your level
	Basic = { key = "basic", name = "SUPPLY CRATE", lawMinutes = 30 },
}

C.InventoryMax = 200
return C
