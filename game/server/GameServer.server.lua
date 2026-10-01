-- GameServer: wires the services together. All game rules live in ServerScriptService.Server and ReplicatedStorage.Shared.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Server = script.Parent:WaitForChild("Server")

local Remotes = RS:FindFirstChild("Remotes") or Instance.new("Folder")
Remotes.Name = "Remotes"; Remotes.Parent = RS
local function remote(class, name)
	local r = Remotes:FindFirstChild(name)
	if r and r.ClassName ~= class then r:Destroy(); r = nil end
	if not r then r = Instance.new(class); r.Name = name; r.Parent = Remotes end
	return r
end
local Request = remote("RemoteFunction", "Request")
local Sync = remote("RemoteEvent", "Sync")

local WS = require(Server.WorldService)
local PS = require(Server.PlayerService)
local MK = require(Server.Market)
local A = require(Server.Actions)
MK.Init(PS)
A.Init(PS, MK)

-- simple flood guard: 25 requests per second per player
local budget = {}
Request.OnServerInvoke = function(plr, action, args)
	local p = PS.Profiles[plr]
	if not p then return { ok = false, msg = "Still loading" } end
	local b = budget[plr] or { n = 0, t = os.clock() }
	if os.clock() - b.t > 1 then b.n = 0; b.t = os.clock() end
	b.n += 1; budget[plr] = b
	if b.n > 25 then return { ok = false, msg = "Slow down" } end
	local fn = type(action) == "string" and A.list[action]
	if not fn then return { ok = false, msg = "Unknown action" } end
	if not p.data.onboarded and not A.PreOnboard[action] then return { ok = false, msg = "Finish setting up your country first" } end
	if type(args) ~= "table" then args = {} end
	local okCall, res = pcall(fn, plr, p, args)
	if not okCall then
		warn("[Idle Country] action " .. action .. " failed: " .. tostring(res))
		res = { ok = false, msg = "Something went wrong. Try again." }
	end
	if not A.NoSync[action] then PS.Sync(plr) end
	return res
end
Players.PlayerRemoving:Connect(function(plr) budget[plr] = nil end)

-- the shared world: push to everyone (throttled) whenever a city or alliance changes
local worldDirty = true
WS.Changed.Event:Connect(function(kind, id)
	worldDirty = true
	if kind == "a" then
		-- members removed from an alliance on another server lose it here too
		for plr, p in pairs(PS.Profiles) do
			if p.data.alliance == id then
				local a = WS.Alliances[id]
				if not a or not a.members[tostring(plr.UserId)] or a.disbanded then p.data.alliance = nil end
				p.dirty = true
			end
		end
	elseif kind == "c" then
		for _, p in pairs(PS.Profiles) do if p.data.alliance then p.dirty = true end end
	end
end)
task.spawn(function()
	while true do
		task.wait(1)
		if worldDirty then
			worldDirty = false
			Sync:FireAllClients("world", WS.PublicState())
		end
	end
end)
Players.PlayerAdded:Connect(function(plr)
	task.wait(1)
	if plr.Parent then Sync:FireClient(plr, "world", WS.PublicState()) end
end)

WS.Start()
MK.Start()
PS.Start()
print("[Idle Country] server ready", WS.PublicState and "" or "")
