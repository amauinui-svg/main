-- Config: everything Kash may want to tune without touching game logic.
-- Robux IDs are 0 until the products/passes are created on the Creator Dashboard
-- (Monetization > Passes / Developer Products). While an ID is 0 its button says "COMING SOON".
local C = {}

C.Version = "Alpha 0.1"

C.Passes = {
	FastConvoys = { id = 0, name = "Express Logistics", desc = "Every convoy travels 2x faster.", price = 249 },
	AutoDispatch = { id = 0, name = "Auto Dispatch", desc = "Convoys pick the best load and keep trading while you are offline.", price = 399 },
	ExtraConvoys = { id = 0, name = "+2 Convoy Slots", desc = "Run two more convoys at once.", price = 199 },
	ExtraLots = { id = 0, name = "+3 Building Lots", desc = "Three more lots for properties.", price = 149 },
}

C.Products = {
	FinishConvoy1 = { id = 0, robux = 5, maxMinutes = 10 },
	FinishConvoy2 = { id = 0, robux = 15, maxMinutes = 60 },
	FinishConvoy3 = { id = 0, robux = 29, maxMinutes = 240 },
	FinishConvoy4 = { id = 0, robux = 49, maxMinutes = math.huge },
	MoveCapital = { id = 0, robux = 99 },
	GoldSmall = { id = 0, robux = 49, gold = 50 },
	GoldBig = { id = 0, robux = 199, gold = 250 },
}

-- Studio testing: owners get every gamepass in Studio so the paid paths can be tested.
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
}

return C
