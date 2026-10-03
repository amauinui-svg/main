-- GameServer: wires the services together. All game rules live in ServerScriptService.Server and ReplicatedStorage.Shared.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Server = script.Parent:WaitForChild("Server")

-- Kash 2 Oct: no shift lock
game:GetService("StarterPlayer").EnableMouseLockOption = false
-- Kash 3 Oct: this is a UI game, nobody walks or jumps around the Roblox world (no footsteps, no thumbstick, no WASD)
do
	local SP = game:GetService("StarterPlayer")
	SP.CharacterWalkSpeed = 0
	SP.CharacterUseJumpPower = true
	SP.CharacterJumpPower = 0
	pcall(function() SP.DevComputerMovementMode = Enum.DevComputerMovementMode.Scriptable end)
	pcall(function() SP.DevTouchMovementMode = Enum.DevTouchMovementMode.Scriptable end)
end

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
local RA = require(Server.Raids)
local AD = require(Server.Admin)
local AN = require(Server.Analytics)
local BG = require(Server.Badges)
local CH = require(Server.Chat)
MK.Init(PS)
RA.Init(PS)
AD.Init(PS, WS, RA)
PS.Admin = AD
PS.AN = AN
BG.Start(PS, WS)
task.spawn(function()
	while true do
		task.wait(60)
		for plr, p in pairs(PS.Profiles) do if p.afkSince and plr.Parent then pcall(A.AfkTick, plr, p) end end
	end
end)
CH.Start()
PS.Chat = CH
A.Init(PS, MK, RA, AD)

-- flood guard (audit M7): a token bucket per player, 8 requests a second with bursts of 15
local budget = {}
local RATE, BURST = 8, 15
Request.OnServerInvoke = function(plr, action, args)
	local p = PS.Profiles[plr]
	if not p or p.loading or p.leaving then return { ok = false, msg = "Still loading" } end
	local b = budget[plr] or { tokens = BURST, t = os.clock() }
	b.tokens = math.min(BURST, b.tokens + (os.clock() - b.t) * RATE); b.t = os.clock()
	budget[plr] = b
	if b.tokens < 1 then return { ok = false, msg = "Slow down" } end
	b.tokens -= 1
	local fn = type(action) == "string" and A.list[action]
	if not fn then return { ok = false, msg = "Unknown action" } end
	if not p.data.onboarded and not A.PreOnboard[action] then return { ok = false, msg = "Finish setting up your country first" } end
	if type(args) ~= "table" then args = {} end
	-- one request at a time per player: actions that wait on DataStores/MemoryStores must not interleave
	-- (two parallel donates or sieges would both pass the balance check)
	local waited = 0
	while p.busy and waited < 8 do waited += task.wait() end
	if p.busy then return { ok = false, msg = "Busy, try again" } end
	if PS.Profiles[plr] ~= p or p.leaving then return { ok = false, msg = "Left" } end -- audit M3
	-- any real action ends AFK (the chamber only sends sync/afk while it is up)
	if action ~= "afk" and action ~= "sync" and p.afkSince then p.afkSince = nil end
	p.busy = true
	local snap = AN.Before(p)
	local okCall, res = pcall(fn, plr, p, args)
	p.busy = false
	if okCall and type(res) == "table" and res.ok then pcall(AN.After, p, snap, action) end
	if not okCall then
		warn("[Idle Country] action " .. action .. " failed: " .. tostring(res))
		res = { ok = false, msg = "Something went wrong. Try again." }
	end
	-- a failed request changes nothing worth a full snapshot; successes sync now (at most ~7 a second), else next tick
	if not A.NoSync[action] and PS.Profiles[plr] == p then
		if type(res) == "table" and res.ok and os.clock() - (p.lastSync or 0) > 0.12 then p.lastSync = os.clock(); PS.Sync(plr)
		else p.dirty = true end
	end
	return res
end
Players.PlayerRemoving:Connect(function(plr) budget[plr] = nil end)

WS.Interest = function(id)
	for _, p in pairs(PS.Profiles) do if p.data.alliance == id then return true end end
	return false
end

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
-- no walking: freeze every character (also players who joined before this script ran, e.g. Studio)
local function freezeChar(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then hum.WalkSpeed = 0; hum.UseJumpPower = true; hum.JumpPower = 0 end
	local root = char:WaitForChild("HumanoidRootPart", 10)
	if root then task.wait(); root.Anchored = true end
end
local function watchChars(plr)
	plr.CharacterAdded:Connect(freezeChar)
	if plr.Character then task.spawn(freezeChar, plr.Character) end
end
Players.PlayerAdded:Connect(watchChars)
for _, plr in ipairs(Players:GetPlayers()) do watchChars(plr) end
Players.PlayerAdded:Connect(function(plr)
	plr.DevEnableMouseLock = false
	pcall(function() plr.DevComputerMovementMode = Enum.DevComputerMovementMode.Scriptable end)
	pcall(function() plr.DevTouchMovementMode = Enum.DevTouchMovementMode.Scriptable end)

	task.wait(1)
	if plr.Parent then Sync:FireClient(plr, "world", WS.PublicState()) end
end)

WS.Start()
MK.Start()
RA.Start()
PS.Start()
game:BindToClose(function() pcall(WS.FlushTreasury) end)
print("[Idle Country] server ready", WS.PublicState and "" or "")

-- Studio-only test hook (LESSONS: never test destructive actions on a real profile; use IC_TestProfile).
-- ServerStorage.IC_Debug:Invoke("dump") / ("set", key, value) / ("act", action, args) / ("world")
if game:GetService("RunService"):IsStudio() then
	local HttpService = game:GetService("HttpService")
	local dbg = game.ServerStorage:FindFirstChild("IC_Debug") or Instance.new("BindableFunction")
	dbg.Name = "IC_Debug"; dbg.Parent = game.ServerStorage
	local handle
	-- bridge for sandboxed tools that cannot invoke the BindableFunction: they create a StringValue named IC_DebugReq
	-- (in ServerStorage or workspace) with attributes cmd/a/b (b as JSON), and get the answer in attribute "res".
	task.spawn(function()
		while true do
			task.wait(0.1)
			for _, host in ipairs({ game.ServerStorage, workspace }) do
				for _, req in ipairs(host:GetChildren()) do
					if req.Name == "IC_DebugReq" and req:GetAttribute("cmd") and req:GetAttribute("res") == nil then
						local b = req:GetAttribute("b")
						if type(b) == "string" and (b:sub(1, 1) == "{" or b:sub(1, 1) == "[") then b = HttpService:JSONDecode(b) end
						local ok, r = pcall(handle, req:GetAttribute("cmd"), req:GetAttribute("a"), b)
						req:SetAttribute("res", ok and tostring(r) or ("ERR " .. tostring(r)))
					end
				end
			end
		end
	end)
	dbg.OnInvoke = function(...) return handle(...) end
	handle = function(cmd, a, b)
		local plr, p = next(PS.Profiles)
		if cmd == "world" then return HttpService:JSONEncode(WS.PublicState()) end
		if not p then return "no profile" end
		if cmd == "dump" then
			local d = p.data
			return HttpService:JSONEncode({ key = workspace:GetAttribute("IC_TestProfile") and "test" or "LIVE", cash = d.cash, gold = d.gold, lv = d.lv, xp = d.xp, inf = d.inf, sup = d.sup, home = d.home, name = d.name,
				onboarded = d.onboarded, lots = d.lots, convoys = d.convoys, sk = d.sk, units = d.units, alliance = d.alliance, gp = p.gp, canSave = p.canSave, tasks = d.tasks, boss = d.boss, loan = d.loan })
		elseif cmd == "get" then
			return HttpService:JSONEncode(a and p.data[a] or PS.Snapshot(p))
		elseif cmd == "set" then
			if not workspace:GetAttribute("IC_TestProfile") then return "refused: not a test profile" end
			p.data[a] = b; PS.Sync(plr); return "ok"
		elseif cmd == "act" then
			local fn = A.list[a]
			local res = fn(plr, p, b or {})
			PS.Sync(plr)
			return HttpService:JSONEncode(res)
		elseif cmd == "reset" then
			if not workspace:GetAttribute("IC_TestProfile") then return "refused: not a test profile" end
			p.data = PS.Fresh(); PS.EnsureConvoys(p); PS.Sync(plr); return "ok"
		elseif cmd == "offline" then
			if not workspace:GetAttribute("IC_TestProfile") then return "refused: not a test profile" end
			local d = p.data
			local before = { cash = d.cash, lv = d.lv, trips = d.stats.trips }
			d.last = os.time() - a
			for _, c in ipairs(d.convoys) do if c.to then c.t0 -= a; c.t1 -= a end end
			PS.CatchUp(p); PS.Sync(plr)
			return HttpService:JSONEncode({ before = before, after = { cash = d.cash, lv = d.lv, trips = d.stats.trips } })
		elseif cmd == "time" then
			-- pretend `a` seconds passed for convoys (test profile only)
			if not workspace:GetAttribute("IC_TestProfile") then return "refused: not a test profile" end
			for _, c in ipairs(p.data.convoys) do if c.to then c.t0 -= a; c.t1 -= a end end
			if p.data.boss and p.data.boss.next then p.data.boss.next -= a end
			return "ok"
		end
	end
end
