-- BADGES (Kash 2 Oct): awarded from a check every 30 seconds (and on join). d.badges remembers what was given
-- so BadgeService is only called once per badge per player.
local BadgeService = game:GetService("BadgeService")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local R = require(RS.Shared.Rules)
local BG = {}
local PS, WS

local function forbidden(d)
	for _, o in pairs(d.inv and d.inv.officers or {}) do if o.rarity == "forbidden" then return true end end
	return false
end

BG.Check = {
	welcome = function(d) return d.onboarded == true end,
	wonder = function(d) return (d.wonder or 0) >= R.WonderMax(#require(RS.Shared.GameData).Eras) end,
	stars = function(d) return R.PlayerEra(d) >= 8 end,
	warlord = function(d) return (d.stats.wins or 0) >= 1000 end,
	trade = function(d) return (d.stats.trips or 0) >= 10000 end,
	quadrillion = function(d) return (d.stats.earned or 0) >= 1e15 end,
	lawgiver = function(d) return PS.GoldLaws(d) >= 100 end,
	slayer = function(d) return (d.stats.bosses or 0) >= 500 end,
	alliance = function(d) local a = d.alliance and WS.Alliances[d.alliance]; return a ~= nil and (a.level or 1) >= 30 end,
	forbidden = forbidden,
}

function BG.Run(plr, p)
	local d = p and p.data
	if not d or not d.onboarded or not p.canSave then return end
	d.badges = type(d.badges) == "table" and d.badges or {}
	for _, b in ipairs(Config.Badges or {}) do
		if b.id ~= 0 and not d.badges[b.key] then
			local okC, has = pcall(BG.Check[b.key] or function() return false end, d)
			if okC and has then
				local okA, res = pcall(BadgeService.AwardBadge, BadgeService, plr.UserId, b.id)
				if okA and res then
					d.badges[b.key] = os.time()
					if PS.AN then PS.AN.Custom(p, "Badge_" .. b.key) end
				elseif okA then
					-- false: already owned or badge disabled; remember owned ones so we stop asking
					local okH, owns = pcall(BadgeService.UserHasBadgeAsync, BadgeService, plr.UserId, b.id)
					if okH and owns then d.badges[b.key] = os.time() end
				end
			end
		end
	end
end

function BG.Start(ps, ws)
	PS, WS = ps, ws
	local Players = game:GetService("Players")
	task.spawn(function()
		while true do
			task.wait(30)
			for plr, p in pairs(PS.Profiles) do
				if plr.Parent and not p.loading then task.spawn(BG.Run, plr, p) end
			end
		end
	end)
	Players.PlayerAdded:Connect(function(plr)
		task.delay(15, function() local p = PS.Profiles[plr]; if p then BG.Run(plr, p) end end)
	end)
end

return BG
