-- Market: Robux. Game passes and developer products. IDs live in Shared.Config (0 = not created yet).
-- Products that need a target (finish WHICH convoy, move capital WHERE) store the intent server-side before the prompt.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Store = require(script.Parent.Store)

local MK = {}
local PS -- set by Init

function MK.Init(playerService) PS = playerService; PS.Market = MK end

function MK.CheckPasses(plr, p)
	for key, pass in pairs(Config.Passes) do
		local owned = false
		if Store.IsStudio and Config.StudioGrantsPasses and not workspace:GetAttribute("IC_NoPasses") then owned = true
		elseif pass.id ~= 0 then
			local ok, r = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, plr.UserId, pass.id)
			owned = ok and r or false
		end
		p.gp[key] = owned or nil
	end
end

function MK.PromptPass(plr, key)
	local pass = Config.Passes[key]
	if not pass then return { ok = false, msg = "Unknown pass" } end
	if pass.id == 0 then return { ok = false, msg = "Coming soon" } end
	MarketplaceService:PromptGamePassPurchase(plr, pass.id)
	return { ok = true }
end

function MK.PromptProduct(plr, key, intent)
	local prod = Config.Products[key]
	if not prod then return { ok = false, msg = "Unknown product" } end
	if prod.id == 0 then return { ok = false, msg = "Coming soon" } end
	local p = PS.Profiles[plr]
	if p then p.pending[key] = intent end
	MarketplaceService:PromptProductPurchase(plr, prod.id)
	return { ok = true }
end

-- product effects. Return true when granted.
local grant = {}
local function finishConvoy(p, i)
	local c = p.data.convoys[i or 0]
	if not c or not c.to then
		-- the convoy already arrived: refund as gold so the purchase is never wasted
		p.data.gold += 5
		PS.Note(p, { kind = "toast", text = "That convoy had already arrived. You got 5 gold instead.", tone = "good" })
		return true
	end
	c.t1 = os.time()
	return true
end
grant.FinishConvoy1 = finishConvoy
grant.FinishConvoy2 = finishConvoy
grant.FinishConvoy3 = finishConvoy
grant.FinishConvoy4 = finishConvoy
function grant.MoveCapital(p, city)
	if type(city) ~= "number" or city < 1 or city > 41 then return false end
	p.data.home = city
	PS.Note(p, { kind = "toast", text = "Your capital has moved.", tone = "good" })
	return true
end
function grant.GoldSmall(p) p.data.gold += Config.Products.GoldSmall.gold; return true end
function grant.GoldBig(p) p.data.gold += Config.Products.GoldBig.gold; return true end

local byId = {}
for key, prod in pairs(Config.Products) do if prod.id ~= 0 then byId[prod.id] = key end end

function MK.ProcessReceipt(info)
	local plr = Players:GetPlayerByUserId(info.PlayerId)
	local p = plr and PS.Profiles[plr]
	if not p then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local d = p.data
	d.receipts = d.receipts or {}
	if table.find(d.receipts, info.PurchaseId) then return Enum.ProductPurchaseDecision.PurchaseGranted end
	local key = byId[info.ProductId]
	if not key or not grant[key] then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local intent = p.pending[key]
	if not grant[key](p, intent) then return Enum.ProductPurchaseDecision.NotProcessedYet end
	p.pending[key] = nil
	table.insert(d.receipts, info.PurchaseId)
	while #d.receipts > 50 do table.remove(d.receipts, 1) end
	PS.Save(plr) -- save before telling Roblox the purchase is granted
	PS.Sync(plr)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MK.Start()
	MarketplaceService.ProcessReceipt = MK.ProcessReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, id, bought)
		if not bought then return end
		local p = PS.Profiles[plr]
		if not p then return end
		for key, pass in pairs(Config.Passes) do
			if pass.id == id then p.gp[key] = true; PS.Note(p, { kind = "toast", text = pass.name .. " unlocked!", tone = "good" }) end
		end
		PS.EnsureConvoys(p)
		PS.Sync(plr)
	end)
end
return MK
