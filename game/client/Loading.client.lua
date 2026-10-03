-- Loading screen (ReplicatedFirst): war-room art, the IDLE COUNTRY logo, a shimmering bar, version and disclaimer.
-- Modelled on the reference game's loading screen (Kash 1 Oct 16:45). Hides once the HUD exists and the save is in.
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local plr = Players.LocalPlayer
pcall(function() ReplicatedFirst:RemoveDefaultLoadingScreen() end)

local BG = "rbxassetid://78862615309260"
local LOGO = "rbxassetid://92029969593916"
local VERSION = "ALPHA 0.3"
-- the UI kit's plates (Shared.Assets bar_track / bar_fill, same 9-slice centres as client/UI.lua). Inlined because this
-- runs from ReplicatedFirst before ReplicatedStorage has replicated.
local KIT = {
	bar_track = { "rbxassetid://134110984464626", Rect.new(8, 8, 56, 20), 0.75 },
	bar_fill = { "rbxassetid://125319890576593", Rect.new(6, 6, 34, 18), 0.75 },
}
local function plate(key, color)
	local k = KIT[key]
	local o = Instance.new("ImageLabel")
	o.BackgroundTransparency = 1; o.BorderSizePixel = 0; o.Image = k[1]
	o.ScaleType = Enum.ScaleType.Slice; o.SliceCenter = k[2]; o.SliceScale = k[3]
	if color then o.ImageColor3 = color end
	return o
end
local HEAVY = Font.new("rbxasset://fonts/families/RobotoCondensed.json", Enum.FontWeight.ExtraBold)
local BOLD = Font.new("rbxasset://fonts/families/RobotoCondensed.json", Enum.FontWeight.Bold)

local gui = Instance.new("ScreenGui")
gui.Name = "IC_Loading"; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100; gui.ResetOnSpawn = false
local root = Instance.new("Frame")
root.Size = UDim2.fromScale(1, 1); root.BackgroundColor3 = Color3.fromHex("0b0a0a"); root.BorderSizePixel = 0; root.Parent = gui
local bg = Instance.new("ImageLabel")
bg.Image = BG; bg.ScaleType = Enum.ScaleType.Crop; bg.Size = UDim2.fromScale(1.08, 1.08); bg.AnchorPoint = Vector2.new(0.5, 0.5)
bg.Position = UDim2.fromScale(0.5, 0.5); bg.BackgroundTransparency = 1; bg.ImageTransparency = 1; bg.Parent = root
local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1); shade.BackgroundColor3 = Color3.new(0, 0, 0); shade.BackgroundTransparency = 0.35; shade.BorderSizePixel = 0; shade.Parent = root
local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.5, 0.2), NumberSequenceKeypoint.new(1, 0) })
grad.Parent = shade

local logo = Instance.new("ImageLabel")
logo.Image = LOGO; logo.BackgroundTransparency = 1; logo.ScaleType = Enum.ScaleType.Fit
logo.AnchorPoint = Vector2.new(0.5, 0.5); logo.Position = UDim2.fromScale(0.5, 0.36); logo.Size = UDim2.fromScale(0.5, 0.42)
logo.ImageTransparency = 1; logo.Parent = root
local logoScale = Instance.new("UIScale"); logoScale.Scale = 0.85; logoScale.Parent = logo
local ar = Instance.new("UISizeConstraint"); ar.MaxSize = Vector2.new(760, 480); ar.Parent = logo

-- ALPHA tag: the kit's tag plate (bar fill art tinted red)
local chip = plate("bar_fill", Color3.fromHex("c9473e"))
chip.Size = UDim2.fromOffset(96, 34); chip.AnchorPoint = Vector2.new(0, 0.5); chip.Position = UDim2.new(0.5, 150, 0.2, 0); chip.ImageTransparency = 1; chip.Parent = root
local chipL = Instance.new("TextLabel")
chipL.Text = "ALPHA"; chipL.FontFace = HEAVY; chipL.TextSize = 18; chipL.TextColor3 = Color3.new(1, 1, 1); chipL.BackgroundTransparency = 1
chipL.Size = UDim2.fromScale(1, 1); chipL.TextTransparency = 1; chipL.ZIndex = 2; chipL.Parent = chip

local status = Instance.new("TextLabel")
status.Text = "LOADING YOUR NATION"; status.FontFace = BOLD; status.TextSize = 20; status.TextColor3 = Color3.fromHex("ece8dc")
status.TextXAlignment = Enum.TextXAlignment.Left; status.BackgroundTransparency = 1; status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.66); status.Size = UDim2.new(0.42, 0, 0, 26); status.TextTransparency = 1; status.Parent = root
-- the progress bar: the kit's bar track with a gold bar-fill shimmer sweeping through it
local track = plate("bar_track")
track.AnchorPoint = Vector2.new(0.5, 0); track.Position = UDim2.new(0.5, 0, 0.66, 34); track.Size = UDim2.new(0.42, 0, 0, 18)
track.ImageTransparency = 1; track.Parent = root
local inner = Instance.new("Frame")
inner.BackgroundTransparency = 1; inner.Position = UDim2.fromOffset(3, 3); inner.Size = UDim2.new(1, -6, 1, -6); inner.ClipsDescendants = true; inner.ZIndex = 2; inner.Parent = track
local shine = plate("bar_fill", Color3.fromHex("f0c75a"))
shine.Size = UDim2.fromScale(0.3, 1); shine.ZIndex = 2; shine.Parent = inner
local sg = Instance.new("UIGradient")
sg.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }); sg.Parent = shine

local foot = Instance.new("TextLabel")
foot.Text = "This game is a work of fiction. Nations, leaders and events are invented."; foot.FontFace = BOLD; foot.TextSize = 14
foot.TextColor3 = Color3.fromHex("b8b2a6"); foot.TextXAlignment = Enum.TextXAlignment.Left; foot.BackgroundTransparency = 1
foot.Position = UDim2.new(0, 40, 1, -46); foot.Size = UDim2.new(0.6, 0, 0, 20); foot.TextTransparency = 1; foot.Parent = root
local ver = foot:Clone(); ver.Text = "VERSION " .. VERSION; ver.TextXAlignment = Enum.TextXAlignment.Right
ver.AnchorPoint = Vector2.new(1, 0); ver.Position = UDim2.new(1, -40, 1, -46); ver.Size = UDim2.new(0.3, 0, 0, 20); ver.Parent = root

gui.Parent = plr:WaitForChild("PlayerGui")
pcall(function() ContentProvider:PreloadAsync({ bg, logo }) end)

local function tw(o, t, p, style) TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play() end
tw(bg, 0.8, { ImageTransparency = 0 })
tw(logo, 0.7, { ImageTransparency = 0 }); tw(logoScale, 0.9, { Scale = 1 }, Enum.EasingStyle.Back)
task.delay(0.35, function()
	tw(chip, 0.4, { ImageTransparency = 0 }); tw(chipL, 0.4, { TextTransparency = 0 })
	tw(status, 0.4, { TextTransparency = 0 }); tw(track, 0.4, { ImageTransparency = 0 })
	tw(foot, 0.4, { TextTransparency = 0.2 }); tw(ver, 0.4, { TextTransparency = 0.2 })
end)
-- slow camera drift on the art + the shimmering bar
local alive = true
task.spawn(function()
	local t0 = os.clock()
	while alive do
		local t = os.clock() - t0
		bg.Position = UDim2.fromScale(0.5 + math.sin(t * 0.15) * 0.015, 0.5 + math.cos(t * 0.12) * 0.01)
		shine.Position = UDim2.fromScale(((t * 0.6) % 1.6) - 0.3, 0)
		task.wait()
	end
end)
local dots = { "", ".", "..", "..." }
task.spawn(function()
	local i = 0
	while alive do i += 1; status.Text = "LOADING YOUR NATION" .. dots[i % 4 + 1]; task.wait(0.4) end
end)

-- done when the game has loaded, the HUD exists and the first sync painted the top bar (min 2.5 s so it never flashes)
local start = os.clock()
if not game:IsLoaded() then game.Loaded:Wait() end
local pg = plr:WaitForChild("PlayerGui")
pg:WaitForChild("IdleCountryHUD", 30)
local t = os.clock()
while os.clock() - t < 12 do
	local hud = pg:FindFirstChild("IdleCountryHUD")
	local onb = hud and hud:FindFirstChild("Onboard", true)
	local name = hud and hud:FindFirstChild("TopBar", true)
	if onb or (name and name:FindFirstChild("Identity") and name.Identity:FindFirstChildWhichIsA("TextLabel") and name.Identity:FindFirstChildWhichIsA("TextLabel").Text ~= "") then break end
	task.wait(0.2)
end
while os.clock() - start < 2.5 do task.wait(0.1) end
status.Text = "WELCOME BACK"
for _, o in ipairs(root:GetDescendants()) do
	if o:IsA("TextLabel") then tw(o, 0.5, { TextTransparency = 1, BackgroundTransparency = 1 })
	elseif o:IsA("ImageLabel") then tw(o, 0.5, { ImageTransparency = 1 })
	elseif o:IsA("Frame") then tw(o, 0.5, { BackgroundTransparency = 1 })
	elseif o:IsA("UIStroke") then tw(o, 0.5, { Transparency = 1 }) end
end
tw(logoScale, 0.5, { Scale = 1.08 })
tw(root, 0.6, { BackgroundTransparency = 1 })
task.wait(0.65)
alive = false
gui:Destroy()
