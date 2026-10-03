-- Analytics (Kash 2 Oct): Roblox Creator Analytics funnels and events so we can see where new players drop off.
-- Every call is wrapped in pcall: analytics must never break gameplay.
local AnalyticsService = game:GetService("AnalyticsService")
local AN = {}

-- ONBOARDING FUNNEL: each step is logged once per player, in order (earlier steps are filled in if skipped).
AN.Steps = {
	"Joined", "Named country", "Designed flag", "Chose government", "Founded country", "Answered tutorial",
	"First law", "Reached level 2", "First property", "First convoy", "Reached level 5", "Reached level 10",
	"Joined an alliance", "Reached level 20",
}
AN.StepIndex = {}
for i, n in ipairs(AN.Steps) do AN.StepIndex[n] = i end

function AN.Step(p, name)
	local i = AN.StepIndex[name]
	if not i or not p or not p.data or not p.player then return end
	local d = p.data
	local done = tonumber(d.funnel) or 0
	if i <= done then return end
	for k = done + 1, i do
		pcall(AnalyticsService.LogOnboardingFunnelStepEvent, AnalyticsService, p.player, k, AN.Steps[k])
	end
	d.funnel = i
end

-- progression: levels and eras
function AN.Level(p, lv)
	if not p or not p.player then return end
	pcall(AnalyticsService.LogProgressionCompleteEvent, AnalyticsService, p.player, "Level", lv, "Level " .. lv)
	if lv == 2 then AN.Step(p, "Reached level 2") elseif lv == 5 then AN.Step(p, "Reached level 5")
	elseif lv == 10 then AN.Step(p, "Reached level 10") elseif lv == 20 then AN.Step(p, "Reached level 20") end
end
function AN.Era(p, era, name)
	if not p or not p.player then return end
	pcall(AnalyticsService.LogProgressionCompleteEvent, AnalyticsService, p.player, "Era", era, name)
end

-- economy: gold and Merits (the two premium-style currencies), logged from before/after balances
local TX = {
	loginClaim = "TimedReward", groupGift = "Onboarding",
	buyCrate = "Shop", goldInf = "Shop", goldSup = "Shop", finishGold = "Shop", bossSkip = "Shop", sealBuy = "Shop",
	refillInfluence = "Shop", openCrate = "Gameplay",
}
local function txName(kind)
	local ok, e = pcall(function() return Enum.AnalyticsEconomyTransactionType[kind].Name end)
	return ok and e or kind
end
local function econ(p, currency, before, after, tx, sku)
	local delta = (after or 0) - (before or 0)
	if delta == 0 or delta ~= delta then return end
	local flow = delta > 0 and Enum.AnalyticsEconomyFlowType.Source or Enum.AnalyticsEconomyFlowType.Sink
	pcall(AnalyticsService.LogEconomyEvent, AnalyticsService, p.player, flow, currency, math.abs(delta), math.max(0, after or 0), txName(tx), sku or "")
end
-- snapshot before an action, log the difference after
function AN.Before(p) return { gold = p.data.gold or 0, merits = p.data.seals or 0 } end
function AN.After(p, snap, action)
	if not snap or not p or not p.player then return end
	local tx = TX[action] or "Gameplay"
	econ(p, "Gold", snap.gold, p.data.gold, tx, action)
	econ(p, "Merits", snap.merits, p.data.seals, tx, action)
end
function AN.Purchase(p, snap, key, robux)
	if not p or not p.player then return end
	if snap then
		econ(p, "Gold", snap.gold, p.data.gold, "IAP", key)
		econ(p, "Merits", snap.merits, p.data.seals, "IAP", key)
	end
	pcall(AnalyticsService.LogCustomEvent, AnalyticsService, p.player, "RobuxSpent", robux or 0)
	AN.ShopStep(p, key, 2, "Purchased")
end

-- SHOP FUNNEL per item: 1 prompt shown, 2 purchased
function AN.ShopStep(p, key, step, name)
	if not p or not p.player then return end
	p.shopSession = p.shopSession or {}
	if step == 1 then p.shopSession[key] = tostring(p.player.UserId) .. "-" .. tostring(os.time()) end
	local sid = p.shopSession[key]
	if not sid then return end
	pcall(AnalyticsService.LogFunnelStepEvent, AnalyticsService, p.player, "Shop " .. tostring(key), sid, step, name)
end

function AN.Custom(p, name, value)
	if not p or not p.player then return end
	pcall(AnalyticsService.LogCustomEvent, AnalyticsService, p.player, name, value or 1)
end

return AN
