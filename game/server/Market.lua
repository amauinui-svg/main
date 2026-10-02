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
	-- Premium players get a small bonus too (Kash 17:22)
	p.premium = plr.MembershipType == Enum.MembershipType.Premium or nil
	if Config.Group.Id ~= 0 then
		local okG, inG = pcall(plr.IsInGroup, plr, Config.Group.Id)
		p.inGroup = okG and inG or nil
	end
	if p.data.onboarded then PS.GrantVipOfficer(p) end
	plr:SetAttribute("IC_Vip", (p.gp.MegaVIP and "MEGA VIP") or (p.gp.VIP and "VIP") or nil)
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
	-- intents are saved with the profile so a receipt processed in a later session still knows what to do
	if p then p.data.pending = p.data.pending or {}; p.data.pending[key] = intent end
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
function grant.GoldHuge(p) p.data.gold += Config.Products.GoldHuge.gold; return true end
local function crates(n) return function(p)
	p.data.crates.limited += n
	PS.Note(p, { kind = "crates", n = n })
	return true
end end
grant.Crate1 = crates(1)
grant.Crate3 = crates(3)
grant.Crate10 = crates(10)
function grant.TreasuryGrant(p)
	local R = require(game:GetService("ReplicatedStorage").Shared.Rules)
	local amt = math.floor(R.MinuteValue(p.data.lv) * 120 + PS.IncHr(p) * 2)
	p.data.cash += amt
	PS.Note(p, { kind = "toast", text = "Treasury Grant: +" .. R.Money(amt), tone = "good" })
	return true
end
function grant.InfluenceRefill(p)
	local R = require(game:GetService("ReplicatedStorage").Shared.Rules)
	p.data.inf = math.max(p.data.inf, R.MaxInfluence(p.data.lv, p.data.sk)); p.data.infT = 0
	return true
end
function grant.SupplyRefill(p)
	local R = require(game:GetService("ReplicatedStorage").Shared.Rules)
	p.data.sup = math.max(p.data.sup, R.MaxSupply(p.data.lv, p.data.sk)); p.data.supT = 0
	return true
end
function grant.RaidShield(p)
	p.data.shield = math.max(os.time(), p.data.shield or 0) + Config.Products.RaidShield.hours * 3600
	PS.Note(p, { kind = "toast", text = "Raid shield up for " .. Config.Products.RaidShield.hours .. " hours", tone = "good" })
	return true
end
function grant.InstantArmy(p)
	local M = require(game:GetService("ReplicatedStorage").Shared.Military)
	local d = p.data
	local best = 1
	for i, u in ipairs(M.Units) do if u.lvl <= d.lv then best = i end end
	local room = M.UnitCap(d.lv) - M.UnitCount(d.units)
	if room <= 0 then
		d.gold += 25
		PS.Note(p, { kind = "toast", text = "Your army was already full. You got 25 gold instead.", tone = "good" })
		return true
	end
	d.units[tostring(best)] = (d.units[tostring(best)] or 0) + room
	PS.Note(p, { kind = "toast", text = "+" .. room .. " " .. M.Units[best].name .. " joined your army", tone = "good" })
	return true
end
function grant.RevengeStrike(p, target)
	local res = PS.Raids.Attack(p.player, p, target, true)
	if not res.ok then
		p.data.gold += 50
		PS.Note(p, { kind = "toast", text = "Your target escaped. You got 50 gold instead.", tone = "good" })
		return true
	end
	PS.Note(p, { kind = "raidResult", res = res })
	return true
end
function grant.ChallengeRefresh(p, intent)
	p.data.refresh.tokens = (p.data.refresh.tokens or 0) + 1
	if type(intent) == "table" then PS.RefreshTask(p, intent.src == "weekly" and "weekly" or "daily", tonumber(intent.i)) end
	return true
end
function grant.LimitedBundle(p)
	local O = require(game:GetService("ReplicatedStorage").Shared.Officers)
	local d = p.data
	if d.bundle then
		d.gold += 500
		PS.Note(p, { kind = "toast", text = "You already own the Limited Bundle. You got 500 gold instead.", tone = "good" })
		return true
	end
	d.bundle = true
	PS.AddOfficer(p, O.BundleOfficer())
	d.inv.gear["g_founder"] = O.BundleGear()
	PS.Note(p, { kind = "bundle" })
	return true
end

local byId = {}
for key, prod in pairs(Config.Products) do if prod.id ~= 0 then byId[prod.id] = key end end

function MK.ProcessReceipt(info)
	local plr = Players:GetPlayerByUserId(info.PlayerId)
	local p = plr and PS.Profiles[plr]
	if not p or not p.canSave then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local d = p.data
	d.receipts = d.receipts or {}
	d.pending = d.pending or {}
	if not table.find(d.receipts, info.PurchaseId) then
		local key = byId[info.ProductId]
		if not key or not grant[key] then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local intent = d.pending[key]
		if key == "MoveCapital" and type(intent) ~= "number" then
			-- the target city was lost (very rare): keep a free move to use from the map
			d.capitalCredit = (d.capitalCredit or 0) + 1
			PS.Note(p, { kind = "toast", text = "Capital move ready: open any city and press MAKE THIS MY CAPITAL.", tone = "good" })
		elseif not grant[key](p, intent) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		d.pending[key] = nil
		table.insert(d.receipts, info.PurchaseId)
		while #d.receipts > 50 do table.remove(d.receipts, 1) end
	end
	-- only tell Roblox it is granted once the profile (with the receipt id) is safely saved
	if not PS.Save(plr) then return Enum.ProductPurchaseDecision.NotProcessedYet end
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
		PS.GrantVipOfficer(p)
		plr:SetAttribute("IC_Vip", (p.gp.MegaVIP and "MEGA VIP") or (p.gp.VIP and "VIP") or nil)
		PS.Sync(plr)
	end)
end
return MK
