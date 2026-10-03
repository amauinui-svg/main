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

-- Studio grants every pass only on the TEST profile, so a Studio session never writes free passes into a live save (audit L11)
local function studioGrants()
	return Store.IsStudio and Config.StudioGrantsPasses and workspace:GetAttribute("IC_TestProfile") and not workspace:GetAttribute("IC_NoPasses")
end
-- Passes must ALWAYS work (Kash's rule from Build a Swarm, audit H1): retry, and when Roblox cannot answer, fall back to
-- the ownership this save last confirmed. A failed key is re-checked every minute; nothing is ever revoked on an error.
local function askOwns(uid, id)
	for i = 1, 3 do
		local ok, r = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, uid, id)
		if ok then return true, r end
		task.wait(0.5 * i)
	end
	return false, nil
end
function MK.CheckPasses(plr, p)
	local d = p.data
	d.ownedPasses = type(d.ownedPasses) == "table" and d.ownedPasses or {}
	p.passRetry = {}
	for key, pass in pairs(Config.Passes) do
		local owned = false
		if studioGrants() then owned = true
		elseif pass.id ~= 0 then
			local ok, r = askOwns(plr.UserId, pass.id)
			if ok then
				owned = r and true or false
				if owned then d.ownedPasses[key] = true end
			else
				owned = d.ownedPasses[key] == true
				p.passRetry[key] = true
				warn("[Idle Country] pass check failed for " .. key .. "; using the saved record (" .. tostring(owned) .. ")")
			end
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
-- the intent remembers WHICH trip was priced (audit M1): a different trip in that slot is refunded, never finished
local function finishConvoy(p, intent)
	local i, t1 = intent, nil
	if type(intent) == "table" then i, t1 = tonumber(intent.i), tonumber(intent.t1) end
	local c = p.data.convoys[i or 0]
	if not c or not c.to or (t1 and c.t1 ~= t1) then
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
	if type(city) ~= "number" or not require(RS.Shared.World).Cities[city] then return false end
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
function grant.InfluenceRefillFirst(p)
	p.data.firstRefill = true
	return grant.InfluenceRefill(p)
end
function grant.SupplyRefill(p)
	local R = require(game:GetService("ReplicatedStorage").Shared.Rules)
	p.data.sup = math.max(p.data.sup, R.MaxSupply(p.data.lv, p.data.sk)); p.data.supT = 0
	return true
end
function grant.RaidShield(p)
	if (p.data.shield or 0) < os.time() then p.data.shieldFrom = os.time() end
	p.data.shield = math.max(os.time(), p.data.shield or 0) + Config.Products.RaidShield.hours * 3600
	if PS.Raids then PS.Raids.SetShield(p.player.UserId, p.data.shield) end
	PS.Note(p, { kind = "toast", text = "Raid shield up for " .. Config.Products.RaidShield.hours .. " hours", tone = "good" })
	return true
end
function grant.InstantArmy(p)
	local M = require(game:GetService("ReplicatedStorage").Shared.Military)
	local R = require(game:GetService("ReplicatedStorage").Shared.Rules)
	local d = p.data
	local best = 1
	for i, u in ipairs(M.Units) do if u.lvl <= d.lv and u.era <= R.PlayerEra(d) then best = i end end
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
-- Starter Pack: the best property your era allows up to 8 levels ahead of you, 4 elite troops of your era, gold.
function grant.StarterPack(p)
	local R = require(RS.Shared.Rules)
	local D = require(RS.Shared.GameData)
	local cfg = Config.Products.StarterPack
	local d = p.data
	if d.starter then
		d.gold += 150
		PS.Note(p, { kind = "toast", text = "You already own the Starter Pack. You got 150 gold instead.", tone = "good" })
		return true
	end
	d.starter = true
	local era = R.PlayerEra(d)
	local best
	for i, P in ipairs(D.Props) do if P.era <= era and P.lvl <= d.lv + 8 then best = i end end
	best = best or 1
	-- first empty lot, else replace your weakest building (refunded at its base price)
	local lots = PS.LotsMax(p)
	local slot
	for i = 1, lots do if (d.lots[i] or 0) == 0 then slot = i; break end end
	if not slot then
		local low, lowInc = nil, math.huge
		for i = 1, math.min(lots, #d.lots) do local P = D.Props[d.lots[i]]; if P and P.inc < lowInc then low, lowInc = i, P.inc end end
		if low and D.Props[d.lots[low]].inc < D.Props[best].inc then d.cash += D.Props[d.lots[low]].cost; slot = low end
	end
	if slot then
		for i = #d.lots + 1, slot - 1 do d.lots[i] = 0 end
		d.lots[slot] = best
	else
		d.cash += D.Props[best].cost -- every lot already holds something better: pay it out
	end
	d.elite = d.elite or {}
	d.elite[tostring(era)] = (d.elite[tostring(era)] or 0) + cfg.troops
	d.gold += cfg.gold
	PS.Note(p, { kind = "toast", text = "Starter Pack: " .. D.Props[best].n .. ", " .. cfg.troops .. " elite troops and " .. cfg.gold .. " gold!", tone = "gold" })
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

local inFlight = {} -- PurchaseIds being granted right now (audit M2: a grant can yield and Roblox may call again)
function MK.ProcessReceipt(info)
	local plr = Players:GetPlayerByUserId(info.PlayerId)
	local p = plr and PS.Profiles[plr]
	if not p or not p.canSave or p.loading or p.leaving then return Enum.ProductPurchaseDecision.NotProcessedYet end
	if inFlight[info.PurchaseId] then return Enum.ProductPurchaseDecision.NotProcessedYet end
	inFlight[info.PurchaseId] = true
	local okR, res = pcall(MK._receipt, plr, p, info)
	inFlight[info.PurchaseId] = nil
	if not okR then warn("[Idle Country] receipt " .. tostring(info.PurchaseId) .. " failed: " .. tostring(res)); return Enum.ProductPurchaseDecision.NotProcessedYet end
	return res
end
function MK._receipt(plr, p, info)
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
	-- re-ask Roblox about any pass that could not be checked at join
	task.spawn(function()
		while true do
			task.wait(60)
			for plr, p in pairs(PS.Profiles) do
				if p.passRetry and next(p.passRetry) and not p.leaving then
					for key in pairs(p.passRetry) do
						local pass = Config.Passes[key]
						local ok, r = askOwns(plr.UserId, pass.id)
						if ok then
							p.passRetry[key] = nil
							if r then p.gp[key] = true; p.data.ownedPasses[key] = true; p.dirty = true end
						end
					end
					PS.EnsureConvoys(p)
				end
			end
		end
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, id, bought)
		if not bought then return end
		local p = PS.Profiles[plr]
		if not p then return end
		for key, pass in pairs(Config.Passes) do
			if pass.id == id then
				-- the server-side purchase event is reliable (Roblox docs); the ownership API can lag right after a purchase,
				-- so trust it and remember it in the save (audit H1)
				p.gp[key] = true
				p.data.ownedPasses = type(p.data.ownedPasses) == "table" and p.data.ownedPasses or {}
				p.data.ownedPasses[key] = true
				PS.Note(p, { kind = "toast", text = pass.name .. " unlocked!", tone = "good" })
			end
		end
		PS.EnsureConvoys(p)
		PS.GrantVipOfficer(p)
		plr:SetAttribute("IC_Vip", (p.gp.MegaVIP and "MEGA VIP") or (p.gp.VIP and "VIP") or nil)
		PS.Sync(plr)
	end)
end
return MK
