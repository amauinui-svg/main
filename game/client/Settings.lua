-- Settings: the top-right gear button and its big modal (SETTINGS / GAME GUIDE / CHANGELOG), plus the
-- favorite + group prompts after big moments (Kash 1 Oct 17:22: max once per session, never if already favorited,
-- shown behind the scenes after a big achievement; our own polished join-group popup with the +10% cash bonus).
-- ClientMain calls _settings.init(App) once after the first full sync. This entry has no build field on purpose.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local GroupService = game:GetService("GroupService")

local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local Config = require(Shared.Config)
local Assets = require(Shared.Assets)
local okO, O = pcall(require, Shared:WaitForChild("Officers"))
if not okO then O = nil end

local function loadChangelog()
	local m = Shared:FindFirstChild("Changelog") or Shared:WaitForChild("Changelog", 5)
	if not m then return {} end
	local ok, list = pcall(require, m)
	return (ok and type(list) == "table") and list or {}
end

local plr = Players.LocalPlayer

---------------------------------------------------------------- settings definitions
local DEFS = {
	-- volume sliders 0..1 (older saves only have the on/off booleans named in legacy: false there means 0)
	{ key = "musicVol", legacy = "music", slider = true, name = "Music", desc = "Background music volume", icon = "icon_radio", default = 0.5 },
	{ key = "sfxVol", legacy = "sfx", slider = true, name = "Sound effects", desc = "Clicks, coins, crates and battles", icon = "icon_sparkles", default = 0.8 },
	{ key = "toasts", name = "Show pop-up notifications", desc = "Deliveries, raids, level-ups and rewards", icon = "icon_bell", default = true },
	{ key = "confirmBig", name = "Confirm big purchases", desc = "Ask before spending a lot of cash or gold", icon = "icon_check", default = true },
	{ key = "shortNumbers", name = "Short numbers (1.2M)", desc = "Off shows full numbers (1,200,000)", icon = "icon_coins", default = true },
	{ key = "autoClaim", name = "Auto-claim finished orders", desc = "Daily and weekly orders claim themselves", icon = "icon_tasks", default = false },
	{ key = "reduceMotion", name = "Reduce animations", desc = "Fewer tweens, bobbing and screen shake", icon = "icon_gauge", default = false },
	{ key = "mapLabels", name = "City names on the map", desc = "Show capital names on the World map", icon = "icon_map", default = true },
}

local function hexOf(c) return string.format("%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)) end
local function kw(s, hex) return '<font color="#' .. hex .. '"><b>' .. s .. "</b></font>" end
local function strip(s) return (s:gsub("<[^>]->", "")) end
-- height of wrapped text (measured on the plain text with a safety margin for bold keywords)
local function textH(s, size, w)
	local v = TextService:GetTextSize(strip(s), size, Enum.Font.RobotoCondensed, Vector2.new(math.max(40, w * 0.88), 10000))
	return math.ceil(v.Y) + 4
end

---------------------------------------------------------------- centre pop-ins and rotating beams (Kash 18:41)
local FX = {}
local function fxTween(o, t, props, style, dir, rep)
	local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, rep or 0), props)
	x:Play()
	return x
end
-- re-anchor a GuiObject on its centre without moving it, so a UIScale grows it from the middle
function FX.centre(g)
	local a = g.AnchorPoint
	if a.X == 0.5 and a.Y == 0.5 then return g end
	local p, sz = g.Position, g.Size
	g.AnchorPoint = Vector2.new(0.5, 0.5)
	g.Position = UDim2.new(p.X.Scale + sz.X.Scale * (0.5 - a.X), p.X.Offset + sz.X.Offset * (0.5 - a.X), p.Y.Scale + sz.Y.Scale * (0.5 - a.Y), p.Y.Offset + sz.Y.Offset * (0.5 - a.Y))
	return g
end
-- fade a whole tree in from fully transparent to the values it was built with
function FX.fadeIn(root, t)
	t = t or 0.18
	local items = root:GetDescendants()
	table.insert(items, root)
	for _, d in ipairs(items) do
		local props = {}
		if d:IsA("GuiObject") and d.BackgroundTransparency < 1 then props.BackgroundTransparency = d.BackgroundTransparency end
		if (d:IsA("ImageLabel") or d:IsA("ImageButton")) and d.ImageTransparency < 1 then props.ImageTransparency = d.ImageTransparency end
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.TextTransparency < 1 then props.TextTransparency = d.TextTransparency end
		if d:IsA("UIStroke") and d.Transparency < 1 then props.Transparency = d.Transparency end
		if next(props) then
			for k in pairs(props) do d[k] = 1 end
			fxTween(d, t, props)
		end
	end
end
-- pop in from the centre ("from far away towards me"): UIScale ~0.6 -> 1 with Back easing, plus a quick fade
function FX.popIn(g, from, t, noFade)
	FX.centre(g)
	local sc = g:FindFirstChildOfClass("UIScale")
	if not sc then sc = Instance.new("UIScale"); sc.Parent = g end
	sc.Scale = from or 0.6
	fxTween(sc, t or 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
	-- deferred so the content the caller builds right after this call fades in with the panel
	if not noFade then task.defer(FX.fadeIn, g, math.min(0.2, (t or 0.32) * 0.7)) end
	return sc
end
function FX.spin(o, degPerSec)
	o.Rotation = (os.clock() * degPerSec) % 360 -- phase from the clock, so a rebuilt card does not jump
	fxTween(o, 360 / math.abs(degPerSec), { Rotation = o.Rotation + (degPerSec >= 0 and 360 or -360) }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
end
-- the classic game-pass ROTATING BEAMS behind an item: soft glow + two counter-rotating tinted sunburst layers.
-- size = full diameter in px (about 1.6-2x the item); strength 0..1
function FX.beams(UI, parent, color, size, pos, z, strength)
	strength = math.clamp(strength or 1, 0, 1)
	local root = UI.mk("Frame", { Name = "Beams", BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Position = pos or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z or 2 }, parent)
	local mid, half = UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
	UI.img(root, "glow_soft", { name = "Glow", color = color, alpha = 1 - 0.45 * strength, slice = false, z = root.ZIndex, anchor = half, pos = mid, sz = UDim2.fromScale(0.62, 0.62) })
	local back = UI.img(root, "beams", { name = "Rays", color = color, alpha = 1 - 0.55 * strength, slice = false, z = root.ZIndex, anchor = half, pos = mid, sz = UDim2.fromScale(1, 1) })
	local front = UI.img(root, "beams_wide", { name = "RaysWide", color = color:Lerp(Color3.new(1, 1, 1), 0.3), alpha = 1 - 0.4 * strength, slice = false, z = root.ZIndex, anchor = half, pos = mid, sz = UDim2.fromScale(0.78, 0.78) })
	FX.spin(back, 22)
	FX.spin(front, -34)
	return root
end

local M = {}
M._settings = { init = function(App)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local modalHost = App.modalHost

	---------------------------------------------------------------- settings state
	local function getSettings()
		local st = App.state
		if not st then return {} end
		st.settings = st.settings or {}
		return st.settings
	end
	local DEF = {}
	for _, d in ipairs(DEFS) do DEF[d.key] = d end
	local function value(key)
		local s = getSettings()
		local d = DEF[key]
		if d and d.slider then
			local v = s[key]
			if type(v) == "number" and v == v then return math.clamp(v, 0, 1) end
			if s[d.legacy] == false then return 0 end
			return d.default
		end
		if s[key] ~= nil then return s[key] end
		return d and d.default
	end
	App.setting = value -- other modules can read App.setting("reduceMotion") (or the IC_ player attributes)
	local function setAttr(key, v)
		pcall(function() plr:SetAttribute("IC_" .. key, v) end)
		local d = DEF[key]
		-- the old on/off attribute follows the slider (anything above 0 counts as on)
		if d and d.slider then pcall(function() plr:SetAttribute("IC_" .. d.legacy, v > 0) end) end
	end
	local function applyAttributes()
		for _, d in ipairs(DEFS) do setAttr(d.key, value(d.key)) end
	end
	applyAttributes()
	App.on("full", applyAttributes)
	local function calm() return value("reduceMotion") == true end
	local function tween(o, t, props, style, dir)
		if calm() then for k, v in pairs(props) do o[k] = v end; return end
		TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props):Play()
	end

	-- previewSetting applies a value locally (slider drags); setSetting applies it and saves it to the server
	local function previewSetting(key, v)
		getSettings()[key] = v
		setAttr(key, v)
		App.emit("settings", key, v)
	end
	local function setSetting(key, v, before)
		local s = getSettings()
		if before == nil then before = value(key) end
		s[key] = v
		setAttr(key, v)
		App.emit("settings", key, v)
		task.spawn(function()
			local res = App.req("saveSettings", { key = key, value = v })
			if not res.ok then
				s[key] = before
				setAttr(key, before)
				App.emit("settings", key, before)
			end
		end)
	end

	---------------------------------------------------------------- the gear button (top-right, under the top bar)
	local BTN = 46
	local basePos = UDim2.new(1, -8, 0, math.floor((App.TOP - 46) / 2)) -- inside the top bar, far right (like the reference menu button)
	local gear = UI.img(App.root, "btn_slate", { button = true, name = "SettingsButton", pos = basePos, anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(BTN, BTN), z = 30 })
	local gScale = mk("UIScale", {}, gear)
	local gIcon = UI.icon(gear, Assets.icon_settings and "icon_settings" or "icon_gauge", 28, C.manila, UDim2.new(0.5, 0, 0.5, -2), { z = 31, anchor = Vector2.new(0.5, 0.5) })
	local tip = UI.img(gear, "chip", { name = "Tip", pos = UDim2.new(0, -8, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(90, 26), z = 31, visible = false })
	text(tip, "SETTINGS", { font = "heavy", size = 14, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 32, color = C.manila })
	gear.MouseEnter:Connect(function()
		tip.Visible = true
		tween(gear, 0.15, { Position = basePos + UDim2.fromOffset(0, -3) }, Enum.EasingStyle.Back)
		tween(gScale, 0.15, { Scale = 1.08 }, Enum.EasingStyle.Back)
		tween(gIcon, 0.35, { Rotation = 60 })
	end)
	gear.MouseLeave:Connect(function()
		tip.Visible = false
		tween(gear, 0.15, { Position = basePos })
		tween(gScale, 0.15, { Scale = 1 })
		tween(gIcon, 0.35, { Rotation = 0 })
	end)
	gear.MouseButton1Down:Connect(function() tween(gScale, 0.05, { Scale = 0.95 }) end)
	gear.MouseButton1Up:Connect(function() tween(gScale, 0.12, { Scale = 1.08 }, Enum.EasingStyle.Back) end)

	---------------------------------------------------------------- small widgets
	local ON, OFF = C.good, Color3.fromHex("3a4049")
	-- pretty switch: returns obj { Inst, Set(v, animate) }
	local function switch(parent, on, z, onToggle)
		local track = mk("TextButton", { Name = "Switch", Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -16, 0.5, 0),
			Size = UDim2.fromOffset(64, 32), BackgroundColor3 = on and ON or OFF, BorderSizePixel = 0, ZIndex = z }, parent)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
		mk("UIStroke", { Color = C.black, Thickness = 2, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, track)
		mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 190)) }, track)
		local lbl = text(track, on and "ON" or "OFF", { font = "heavy", size = 12, color = C.white, sz = UDim2.new(1, -36, 1, 0), pos = UDim2.fromOffset(on and 8 or 30, 0), z = z + 1, align = Enum.TextXAlignment.Center, stroke = 1 })
		local knob = mk("Frame", { Name = "Knob", AnchorPoint = Vector2.new(0, 0.5), Position = on and UDim2.new(1, -29, 0.5, 0) or UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = C.white, BorderSizePixel = 0, ZIndex = z + 2 }, track)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
		mk("UIStroke", { Color = C.black, Thickness = 1, Transparency = 0.5 }, knob)
		local ks = mk("UIScale", {}, knob)
		local obj = { Inst = track, on = on }
		function obj:Set(v, animate)
			self.on = v
			lbl.Text = v and "ON" or "OFF"
			lbl.Position = UDim2.fromOffset(v and 8 or 30, 0)
			local pos = v and UDim2.new(1, -29, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
			if animate then
				tween(knob, 0.18, { Position = pos }, Enum.EasingStyle.Back)
				tween(track, 0.18, { BackgroundColor3 = v and ON or OFF })
				if not calm() then
					ks.Scale = 1.15
					tween(ks, 0.2, { Scale = 1 }, Enum.EasingStyle.Back)
				end
			else
				knob.Position = pos; track.BackgroundColor3 = v and ON or OFF
			end
		end
		track.Activated:Connect(function() onToggle() end)
		return obj
	end

	-- volume slider (mouse and touch): track, gold fill, knob and a percentage label.
	-- onChange(v) runs live while dragging, onCommit(v, before) once on release. Returns obj { Inst, Set(v) }
	local function slider(parent, v, z, onChange, onCommit)
		local box = mk("TextButton", { Name = "Slider", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -84, 0.5, 0), Size = UDim2.new(0.5, -60, 0, 36), ZIndex = z }, parent)
		box:SetAttribute("IC_NoClick", true)
		local track = mk("Frame", { Name = "Track", BackgroundColor3 = Color3.fromHex("14171b"), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.new(1, 0, 0, 12), ZIndex = z }, box)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
		mk("UIStroke", { Color = Color3.fromHex("4a4f57"), Thickness = 1, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, track)
		mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(150, 150, 150), Color3.new(1, 1, 1)) }, track)
		local fill = mk("Frame", { Name = "Fill", BackgroundColor3 = C.white, BorderSizePixel = 0, Size = UDim2.fromScale(v, 1), ZIndex = z + 1 }, track)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
		mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromHex("f6dc8a"), Color3.fromHex("c99a32")) }, fill)
		local knob = mk("Frame", { Name = "Knob", BackgroundColor3 = C.manila, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(v, 0.5), Size = UDim2.fromOffset(24, 24), ZIndex = z + 3 }, track)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
		mk("UIStroke", { Color = C.black, Thickness = 2, Transparency = 0.3 }, knob)
		mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)) }, knob)
		local dot = mk("Frame", { BackgroundColor3 = C.manilaInk, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(8, 8), ZIndex = z + 4 }, knob)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)
		local ks = mk("UIScale", {}, knob)
		local pct = text(parent, "", { font = "heavy", size = 18, color = C.manila, align = Enum.TextXAlignment.Right, anchor = Vector2.new(1, 0.5),
			pos = UDim2.new(1, -16, 0.5, 0), sz = UDim2.fromOffset(60, 26), z = z })

		local obj = { Inst = box, v = v }
		local function show(x)
			fill.Size = UDim2.fromScale(x, 1)
			fill.Visible = x > 0.001
			knob.Position = UDim2.fromScale(x, 0.5)
			pct.Text = math.floor(x * 100 + 0.5) .. "%"
			pct.TextColor3 = x > 0 and C.manila or C.dim
		end
		function obj:Set(x) self.v = x; show(x) end
		show(v)

		local dragging, before, scroller = false, nil, nil
		local function at(px)
			local w = track.AbsoluteSize.X
			if w <= 0 then return obj.v end
			local x = math.clamp((px - track.AbsolutePosition.X) / w, 0, 1)
			return math.floor(x * 100 + 0.5) / 100
		end
		local function move(px)
			local x = at(px)
			if x == obj.v then return end
			obj.v = x
			show(x)
			onChange(x)
		end
		local function isPress(io) return io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch end
		box.InputBegan:Connect(function(io)
			if dragging or not isPress(io) then return end
			dragging, before = true, obj.v
			-- a drag inside the settings list must not scroll it
			scroller = box:FindFirstAncestorWhichIsA("ScrollingFrame")
			if scroller then scroller.ScrollingEnabled = false end
			tween(ks, 0.12, { Scale = 1.2 }, Enum.EasingStyle.Back)
			move(io.Position.X)
		end)
		local conns = {}
		table.insert(conns, UserInputService.InputChanged:Connect(function(io)
			if not dragging then return end
			if io.UserInputType == Enum.UserInputType.MouseMovement or io.UserInputType == Enum.UserInputType.Touch then move(io.Position.X) end
		end))
		table.insert(conns, UserInputService.InputEnded:Connect(function(io)
			if not dragging or not isPress(io) then return end
			dragging = false
			if scroller then scroller.ScrollingEnabled = true; scroller = nil end
			tween(ks, 0.15, { Scale = 1 })
			onCommit(obj.v, before)
		end))
		box.Destroying:Connect(function()
			for _, c in ipairs(conns) do c:Disconnect() end
		end)
		return obj
	end

	local function chip(parent, s, bg, fg, p)
		p = p or {}
		local f = mk("Frame", { Name = "Chip", BackgroundColor3 = bg, BorderSizePixel = 0, Size = UDim2.fromOffset(0, p.h or 26), AutomaticSize = Enum.AutomaticSize.X,
			Position = p.pos or UDim2.new(), AnchorPoint = p.anchor or Vector2.zero, ZIndex = p.z or 75, LayoutOrder = p.order or 0 }, parent)
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }, f)
		mk("UIStroke", { Color = C.black, Thickness = 1.5, Transparency = 0.4 }, f)
		mk("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, f)
		local l = text(f, s, { font = "heavy", size = p.size or 14, color = fg or C.white, sz = UDim2.new(0, 0, 1, 0), z = (p.z or 75) + 1 })
		l.AutomaticSize = Enum.AutomaticSize.X
		return f
	end

	local function hoverCard(card, stroke, img)
		local scale = img and mk("UIScale", {}, img)
		card.MouseEnter:Connect(function()
			if stroke then tween(stroke, 0.15, { Thickness = 3, Transparency = 0 }) end
			if scale then tween(scale, 0.2, { Scale = 1.07 }, Enum.EasingStyle.Back) end
		end)
		card.MouseLeave:Connect(function()
			if stroke then tween(stroke, 0.15, { Thickness = 1.5, Transparency = 0.35 }) end
			if scale then tween(scale, 0.2, { Scale = 1 }) end
		end)
	end

	---------------------------------------------------------------- pages
	local pages = {}

	-- SETTINGS
	pages[1] = function(page, mw)
		local st = App.state or {}
		local list = UI.list(page, { gap = 8, z = 73 })
		-- profile / version card
		local head = UI.card(list, { sz = UDim2.new(1, 0, 0, 84), z = 73, order = 0 })
		local flagHost = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 18), Size = UDim2.fromOffset(72, 48), ZIndex = 74 }, head)
		pcall(UI.flag, flagHost, st.flag, 70, { z = 74 })
		text(head, string.upper((st.name and st.name ~= "") and st.name or plr.DisplayName), { font = "display", size = 24, color = C.manila, pos = UDim2.fromOffset(102, 10), sz = UDim2.new(1, -118, 0, 30), z = 74, truncate = true })
		local row = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(102, 46), Size = UDim2.new(1, -118, 0, 26), ZIndex = 74 }, head)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, row)
		chip(row, "IDLE COUNTRY · " .. string.upper(tostring(st.version or Config.Version or "")), Color3.fromHex("2f3a48"), C.blue, { order = 1, z = 75 })
		if st.lv then chip(row, "LEVEL " .. st.lv, Color3.fromHex("3b3357"), C.xp, { order = 2, z = 75 }) end
		if st.vip then
			local col = "f0c75a"
			for _, v in pairs(Config.VIP or {}) do if v.tag == st.vip then col = v.color end end
			local c = chip(row, "★ " .. st.vip, Color3.fromHex(col), C.black, { order = 3, z = 75 })
			mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205)) }, c)
		end
		if st.premium then chip(row, "PREMIUM +" .. math.floor((Config.PremiumBonus or 0) * 100) .. "%", Color3.fromHex("2b4a3a"), C.good, { order = 4, z = 75 }) end
		if st.inGroup then chip(row, "GROUP +" .. math.floor((Config.Group and Config.Group.Bonus or 0) * 100) .. "%", Color3.fromHex("2b4a3a"), C.good, { order = 5, z = 75 }) end

		local hdr = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), ZIndex = 73, LayoutOrder = 1 }, list)
		text(hdr, "PREFERENCES", { font = "heavy", size = 14, color = C.muted, sz = UDim2.fromScale(1, 1), z = 74, pos = UDim2.fromOffset(4, 0) })

		for i, d in ipairs(DEFS) do
			if d.slider then
				-- volume row: name and description on the left, slider and percentage on the right
				local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 62), z = 73, order = 1 + i })
				local ib = mk("Frame", { BackgroundColor3 = Color3.fromHex("20252c"), BorderSizePixel = 0, Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(40, 40), ZIndex = 74 }, card)
				mk("UICorner", { CornerRadius = UDim.new(0, 8) }, ib)
				local v0 = value(d.key)
				local ic = UI.icon(ib, d.icon, 24, v0 > 0 and C.manila or C.dim, UDim2.fromScale(0.5, 0.5), { z = 75, anchor = Vector2.new(0.5, 0.5) })
				text(card, d.name, { font = "heavy", size = 18, pos = UDim2.fromOffset(64, 8), sz = UDim2.new(0.5, -90, 0, 24), z = 74, truncate = true })
				text(card, d.desc, { size = 14, color = C.muted, pos = UDim2.fromOffset(64, 32), sz = UDim2.new(0.5, -90, 0, 20), z = 74, truncate = true })
				slider(card, v0, 76, function(v)
					ic.ImageColor3 = v > 0 and C.manila or C.dim
					previewSetting(d.key, v)
				end, function(v, before)
					ic.ImageColor3 = v > 0 and C.manila or C.dim
					if v ~= before then setSetting(d.key, v, before) end
					-- let the player hear the new effects level
					if d.key == "sfxVol" and v > 0 then App.play("ui_click") end
				end)
				continue
			end
			local card = UI.card(list, { button = true, sz = UDim2.new(1, 0, 0, 62), z = 73, order = 1 + i })
			local glow = mk("Frame", { BackgroundColor3 = C.manila, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), ZIndex = 73 }, card)
			mk("UICorner", { CornerRadius = UDim.new(0, 6) }, glow)
			local ib = mk("Frame", { BackgroundColor3 = Color3.fromHex("20252c"), BorderSizePixel = 0, Position = UDim2.fromOffset(12, 11), Size = UDim2.fromOffset(40, 40), ZIndex = 74 }, card)
			mk("UICorner", { CornerRadius = UDim.new(0, 8) }, ib)
			local on = value(d.key) == true
			local ic = UI.icon(ib, d.icon, 24, on and C.manila or C.dim, UDim2.fromScale(0.5, 0.5), { z = 75, anchor = Vector2.new(0.5, 0.5) })
			text(card, d.name, { font = "heavy", size = 18, pos = UDim2.fromOffset(64, 8), sz = UDim2.new(1, -170, 0, 24), z = 74, truncate = true })
			text(card, d.desc, { size = 14, color = C.muted, pos = UDim2.fromOffset(64, 32), sz = UDim2.new(1, -170, 0, 20), z = 74, truncate = true })
			local sw
			local function toggle()
				local v = not value(d.key)
				setSetting(d.key, v)
				sw:Set(v, true)
				ic.ImageColor3 = v and C.manila or C.dim
			end
			sw = switch(card, on, 76, toggle)
			card.Activated:Connect(toggle)
			card.MouseEnter:Connect(function() tween(glow, 0.15, { BackgroundTransparency = 0.94 }) end)
			card.MouseLeave:Connect(function() tween(glow, 0.15, { BackgroundTransparency = 1 }) end)
		end
		local foot = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), ZIndex = 73, LayoutOrder = 100 }, list)
		text(foot, "Settings are saved to your country and follow you to every server.", { size = 13, color = C.dim, sz = UDim2.fromScale(1, 1), z = 74, align = Enum.TextXAlignment.Center })
	end

	-- GAME GUIDE
	local function guideData()
		local G, B, Rd, M2 = "8fd07a", "7fb0e6", "e2695f", "f0c75a"
		local P, O2, T = "b06ef0", "ff9a2e", "3fe0d0"
		local bank = Config.Bank or { DepositFee = 0.1, InterestPerHour = 0.015, OfflineShare = 0.5 }
		local raid = Config.Raid or { StealPct = 0.1, CapLawMinutes = 60, Cooldown = 60, AICount = 3 }
		local hire = Config.Officers and Config.Officers.Hire or {}
		local hireText = {}
		for _, h in ipairs(hire) do table.insert(hireText, h.name:sub(1, 1) .. h.name:sub(2):lower() .. " " .. kw(R.Money(h.cost), G)) end
		local at = R.MasteryAt or { 25, 50, 100 }
		local pct = R.MasteryPct or { 0, 5, 10, 15 }
		local limited = Config.Crates and Config.Crates.Limited or { gold = 150 }
		local basic = Config.Crates and Config.Crates.Basic or { lawMinutes = 30 }
		local rarities = {}
		if O and O.Rarities then
			for i = 1, (O.RollTiers or 8) do local r = O.Rarities[i]; if r then table.insert(rarities, kw(r.name:sub(1, 1) .. r.name:sub(2):lower(), r.color)) end end
		end
		return {
			{ title = "YOUR COUNTRY", img = "country_era3", crop = true, color = "e2cfa3", lines = {
				"Pass " .. kw("LAWS", M2) .. " with " .. kw("Influence", "e0a650") .. " to earn " .. kw("cash", G) .. " and " .. kw("XP", "b19cff") .. ".",
				"Each level unlocks at most " .. kw("one new law", M2) .. ". New " .. kw("eras", B) .. " change how your country looks.",
				"Level-ups give " .. kw("skill points", "b19cff") .. " for permanent stat upgrades.",
			} },
			{ title = "PROPERTIES", img = "prop_e3_t2", color = G, lines = {
				"Build on your " .. kw("lots", G) .. " for steady " .. kw("cash per hour", G) .. ".",
				"They keep earning while you are " .. kw("offline", B) .. " (up to 12 hours).",
				"Better buildings unlock as you level up. Buy more lots to build more.",
			} },
			{ title = "OFFICERS & GEAR", img = "gear_saber", color = P, lines = {
				"Hire in 3 tiers: " .. table.concat(hireText, " · ") .. ". Better tiers, rarer officers.",
				(#rarities > 0 and (#rarities .. " rarities: " .. table.concat(rarities, ", ")) or "8 rarities from Common to Forbidden") .. ". Rarer = more and bigger traits.",
				"Officers " .. kw("never die", G) .. " in battle. Equip " .. kw("weapons", Rd) .. " and " .. kw("armor", B) .. " on them and on " .. kw("YOU", M2) .. ".",
				"Every officer is unique. Every new slot costs more than the last.",
			} },
			{ title = "CRATES", img = "crate_limited", color = O2, lines = {
				kw("Supply Crate", B) .. ": bought with cash (about " .. basic.lawMinutes .. " min of law income).",
				kw("Founder's Crate", O2) .. ": " .. kw(limited.gold .. " gold", M2) .. " or Robux. Same crate, so everyone chases the same items.",
				"Mostly " .. kw("cool gear", P) .. ", sometimes an " .. kw("officer", T) .. ". The limited crate rotates.",
			} },
			{ title = "ORDERS & MERITS", img = "icon_seal", color = M2, lines = {
				kw("Daily orders", G) .. " (easy, medium, hard) pay " .. kw("Merits", M2) .. " and cash. Finish all for a bonus.",
				kw("Weekly challenges", P) .. " reset Monday. Clear all 5 for a chest with Rare+ gear.",
				"One " .. kw("free replace", B) .. " per day for an order you do not like.",
				"Spend Merits in the " .. kw("Merits Shop", M2) .. ": refills, shields, crates.",
			} },
			{ title = "CONVOYS", img = "convoy_ship", color = B, lines = {
				"Send goods between world capitals. Pay is " .. kw("locked", M2) .. " when you send.",
				"Distance alone does not pay: trade between " .. kw("different regions", B) .. " (Europe to Asia) pays most.",
				"City " .. kw("wants change", O2) .. " as players deliver, so watch for new demand.",
				"Alliances that hold a city " .. kw("tax", Rd) .. " the trade passing through it.",
			} },
			{ title = "RAIDS", img = "enemy_soldier", color = Rd, lines = {
				"Raid players in your server and " .. kw(raid.AICount .. " AI nations", Rd) .. " that raid back.",
				"Win to take " .. kw(math.floor(raid.StealPct * 100 + 0.5) .. "% of their cash on hand", G) .. ", capped at about " .. kw(math.floor(raid.CapLawMinutes / 60 + 0.5) .. "h of their law income", M2) .. ".",
				kw("Banked cash is safe", B) .. ". Soldiers die on both sides; officers never do.",
				"Raided? Hit " .. kw("REVENGE", Rd) .. " to strike back in one tap.",
			} },
			{ title = "THE BANK", img = "icon_bank", icon = true, color = G, lines = {
				"Deposits cost a " .. kw(math.floor(bank.DepositFee * 100 + 0.5) .. "% fee", Rd) .. ". Withdrawals are " .. kw("free", G) .. ".",
				"Earn " .. kw((bank.InterestPerHour * 100) .. "% interest per hour", G) .. " (" .. kw("half rate offline", B) .. ", up to 12 h).",
				"Banked cash " .. kw("cannot be stolen", B) .. " in raids. Withdraw before you buy.",
			} },
			{ title = "LAW MASTERY", img = "medal_gold", color = M2, lines = {
				"Every pass of a law counts toward its medals.",
				kw("Bronze", "cd7f32") .. " " .. at[1] .. " passes: +" .. pct[2] .. "% cash and XP.  " .. kw("Silver", "c0c6cc") .. " " .. at[2] .. ": +" .. pct[3] .. "% and 5% less Influence.",
				kw("Gold", M2) .. " " .. at[3] .. " passes: +" .. pct[4] .. "% and " .. kw("+1 skill point", "b19cff") .. ". A reason to master every law.",
			} },
		}
	end

	pages[2] = function(page, mw)
		local list = UI.list(page, { gap = 10, z = 73 })
		local intro = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), ZIndex = 73, LayoutOrder = 0 }, list)
		text(intro, "HOW " .. kw("IDLE COUNTRY", "e2cfa3") .. " WORKS: the 10 systems that grow your nation", { font = "heavy", size = 15, color = C.muted, rich = true, sz = UDim2.fromScale(1, 1), z = 74, pos = UDim2.fromOffset(4, 0) })
		local cardW = mw - 28 - 14
		local imgW = cardW < 640 and 150 or 200
		local imgH = math.floor(imgW * 0.66)
		local textW = cardW - imgW - 48
		for i, g in ipairs(guideData()) do
			local acc = Color3.fromHex(g.color)
			-- measure
			local titleH = 30
			local hs, total = {}, 0
			for k, line in ipairs(g.lines) do hs[k] = textH("•  " .. line, 15, textW - 4); total += hs[k] + 4 end
			local h = math.max(imgH + 28, 16 + titleH + 6 + total + 12)
			local card = UI.card(list, { button = true, sz = UDim2.new(1, 0, 0, h), z = 73, order = i })
			local stroke = mk("UIStroke", { Color = acc, Thickness = 1.5, Transparency = 0.35, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
			local tint = mk("Frame", { BackgroundColor3 = acc, BackgroundTransparency = 0.88, BorderSizePixel = 0, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 1, -8), ZIndex = 73 }, card)
			mk("UICorner", { CornerRadius = UDim.new(0, 6) }, tint)
			mk("UIGradient", { Transparency = NumberSequence.new(0, 0.85) }, tint)
			-- image box
			local box = mk("Frame", { Name = "Art", BackgroundColor3 = Color3.fromHex("161a1f"), BorderSizePixel = 0, ClipsDescendants = true, Position = UDim2.fromOffset(14, 14),
				Size = UDim2.fromOffset(imgW, h - 28), ZIndex = 74 }, card)
			mk("UICorner", { CornerRadius = UDim.new(0, 8) }, box)
			mk("UIStroke", { Color = acc, Thickness = 2, Transparency = 0.2 }, box)
			mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(acc:Lerp(Color3.new(0, 0, 0), 0.55), Color3.fromHex("101317")) }, box)
			local art
			if g.crop then
				art = UI.img(box, g.img, { slice = false, z = 75 })
				art.ScaleType = Enum.ScaleType.Crop
			else
				-- rotating game-pass beams behind the picture (no flat circle, Kash 18:41); a still glow with Reduce animations
				if calm() then
					UI.img(box, "glow_soft", { slice = false, z = 75, sz = UDim2.fromOffset(imgH * 1.3, imgH * 1.3), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), color = acc, alpha = 0.45 })
				else
					FX.beams(UI, box, acc, math.floor(imgH * 1.7), UDim2.fromScale(0.5, 0.5), 75, 0.6)
				end
				local s = g.icon and 0.5 or 0.86
				art = UI.img(box, g.img, { slice = false, z = 76, fit = true, sz = UDim2.fromScale(s, s), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), color = g.icon and acc or C.white })
				art.ScaleType = Enum.ScaleType.Fit
			end
			-- text column
			local col = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(imgW + 32, 14), Size = UDim2.new(1, -(imgW + 46), 1, -24), ZIndex = 74 }, card)
			mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, col)
			local t = text(col, g.title, { font = "display", size = 24, color = acc, sz = UDim2.new(1, 0, 0, titleH), z = 75, order = 0, truncate = true })
			mk("UIStroke", { Color = C.black, Thickness = 1, Transparency = 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, t)
			mk("Frame", { BackgroundColor3 = acc, BackgroundTransparency = 0.5, BorderSizePixel = 0, Size = UDim2.new(0, 60, 0, 2), ZIndex = 75, LayoutOrder = 1 }, col)
			for k, line in ipairs(g.lines) do
				text(col, '<font color="#' .. g.color .. '">•</font>  ' .. line, { size = 15, rich = true, wrap = true, sz = UDim2.new(1, 0, 0, hs[k]), z = 75, order = 1 + k, valign = Enum.TextYAlignment.Top })
			end
			hoverCard(card, stroke, art)
		end
	end

	-- CHANGELOG
	pages[3] = function(page, mw)
		local list = UI.list(page, { gap = 10, z = 73 })
		local entries = loadChangelog()
		if #entries == 0 then
			text(list, "No changelog yet.", { size = 16, color = C.muted, z = 74 })
			return
		end
		local textW = mw - 28 - 14 - 56
		for i, e in ipairs(entries) do
			local items = e.items or {}
			local hs, total = {}, 0
			for k, s in ipairs(items) do hs[k] = textH("•  " .. s, 15, textW); total += hs[k] + 4 end
			local h = 16 + 34 + 10 + total + 14
			local latest = i == 1
			local acc = latest and C.gold or C.blue
			local card = UI.card(list, { hot = latest, sz = UDim2.new(1, 0, 0, h), z = 73, order = i })
			mk("Frame", { BackgroundColor3 = acc, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 10), Size = UDim2.new(0, 4, 1, -20), ZIndex = 74 }, card)
			local top = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(22, 14), Size = UDim2.new(1, -40, 0, 32), ZIndex = 74 }, card)
			mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, top)
			local badge = chip(top, string.upper(e.version or "?"), acc, C.black, { h = 30, size = 16, z = 75, order = 1 })
			mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(200, 200, 200)) }, badge)
			if latest then chip(top, "LATEST", Color3.fromHex("2b4a3a"), C.good, { h = 24, size = 12, z = 75, order = 2 }) end
			text(card, e.date or "", { font = "bold", size = 15, color = C.muted, pos = UDim2.fromOffset(22, 14), sz = UDim2.new(1, -40, 0, 32), z = 75, align = Enum.TextXAlignment.Right })
			local col = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(30, 58), Size = UDim2.new(1, -56, 1, -66), ZIndex = 74 }, card)
			mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, col)
			local hex = hexOf(acc)
			for k, s in ipairs(items) do
				text(col, '<font color="#' .. hex .. '">•</font>  ' .. s, { size = 15, rich = true, wrap = true, sz = UDim2.new(1, 0, 0, hs[k]), z = 75, order = k, valign = Enum.TextYAlignment.Top })
			end
		end
	end

	---------------------------------------------------------------- the modal
	local current = 1
	local function openSettings(tab)
		current = tab or current
		UI.clear(modalHost)
		modalHost.Visible = true
		local mw = math.min(880, App.W() - 40)
		local mh = math.min(620, App.H() - 40)
		local panel, body = UI.panel(modalHost, nil, { plain = true, sz = UDim2.fromOffset(mw, mh), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71 })
		local page
		local tabs = UI.tabs(body, { "SETTINGS", "GAME GUIDE", "CHANGELOG" }, function(i)
			current = i
			UI.clear(page)
			local ok, err = pcall(pages[i], page, mw)
			if not ok then warn("[Idle Country] settings page " .. i .. ": " .. tostring(err)) end
		end, { w = math.min(160, math.floor((mw - 100) / 3)), sz = UDim2.new(1, -60, 0, 40), z = 73, textSize = 16 })
		local close = UI.img(body, "btn_red", { button = true, name = "Close", pos = UDim2.new(1, 0, 0, 0), anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(44, 40), z = 73 })
		UI.icon(close, "icon_x", 22, C.white, UDim2.new(0.5, 0, 0.5, -1), { z = 74, anchor = Vector2.new(0.5, 0.5) })
		local cs = mk("UIScale", {}, close)
		close.MouseEnter:Connect(function() tween(cs, 0.12, { Scale = 1.1 }, Enum.EasingStyle.Back) end)
		close.MouseLeave:Connect(function() tween(cs, 0.12, { Scale = 1 }) end)
		close.Activated:Connect(function() modalHost.Visible = false; UI.clear(modalHost) end)
		mk("Frame", { BackgroundColor3 = C.rule, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 2), ZIndex = 73 }, body)
		page = mk("Frame", { Name = "Page", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 1, -58), ZIndex = 73 }, body)
		tabs:Set(current)
		local ok, err = pcall(pages[current], page, mw)
		if not ok then warn("[Idle Country] settings page " .. current .. ": " .. tostring(err)) end
		if not calm() then FX.popIn(panel, 0.6, 0.3) end
	end
	App.openSettings = openSettings
	gear.Activated:Connect(function() openSettings() end)

	---------------------------------------------------------------- favorite + group prompts after big moments
	local sessionStart = os.clock()
	local favRolled, favPending, groupDone = false, false, false

	local function groupEligible()
		local st = App.state
		return st and (st.groupId or 0) ~= 0 and not st.inGroup and not groupDone
	end

	local function showGroupPopup()
		if not groupEligible() then return end
		groupDone = true
		task.spawn(function()
			-- never cover another popup: wait (up to 90 s) until the modal host is free
			local waited = 0
			while modalHost.Visible and waited < 90 do task.wait(0.5); waited += 0.5 end
			local st = App.state
			if modalHost.Visible or not st or st.inGroup or (st.groupId or 0) == 0 then return end
			local gid = st.groupId
			local bonus = math.floor(((Config.Group and Config.Group.Bonus) or 0.1) * 100 + 0.5)
			UI.clear(modalHost)
			modalHost.Visible = true
			local panel = UI.img(modalHost, "panel", { name = "GroupPopup", sz = UDim2.fromOffset(440, 330), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71 })
			mk("UIStroke", { Color = C.gold, Thickness = 2, Transparency = 0.3 }, panel)
			-- emblem with the classic rotating gold beams behind it (Kash 18:41: no pulsing circle)
			if calm() then
				UI.img(panel, "glow_soft", { slice = false, z = 72, sz = UDim2.fromOffset(150, 150), pos = UDim2.new(0.5, 0, 0, 72), anchor = Vector2.new(0.5, 0.5), color = C.gold, alpha = 0.4 })
			else
				FX.beams(UI, panel, C.gold, 170, UDim2.new(0.5, 0, 0, 72), 72, 0.85)
			end
			local emb = mk("Frame", { BackgroundColor3 = Color3.fromHex("2a2416"), BorderSizePixel = 0, Size = UDim2.fromOffset(84, 84), Position = UDim2.new(0.5, 0, 0, 72), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 73 }, panel)
			mk("UICorner", { CornerRadius = UDim.new(1, 0) }, emb)
			mk("UIStroke", { Color = C.gold, Thickness = 3 }, emb)
			UI.icon(emb, "icon_users", 44, C.gold, UDim2.fromScale(0.5, 0.5), { z = 74, anchor = Vector2.new(0.5, 0.5) })
			text(panel, "JOIN THE GROUP", { font = "display", size = 28, color = C.manila, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(20, 124), sz = UDim2.new(1, -40, 0, 34), z = 73 })
			text(panel, '<font color="#8fd07a">+' .. bonus .. "% cash</font> forever", { font = "heavy", size = 26, rich = true, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(20, 160), sz = UDim2.new(1, -40, 0, 32), z = 73, stroke = 1.2 })
			text(panel, "Members earn more from laws, properties and convoys, and hear about updates first.", { size = 15, color = C.muted, wrap = true, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(30, 196), sz = UDim2.new(1, -60, 0, 42), z = 73 })
			local function close() modalHost.Visible = false; UI.clear(modalHost) end
			UI.button(panel, "slate", "NOT NOW", close, { sz = UDim2.fromOffset(160, 48), pos = UDim2.new(0, 24, 1, -70), z = 73 })
			UI.button(panel, "green", "JOIN", function()
				close()
				local ok, status = pcall(function() return GroupService:PromptJoinAsync(gid) end)
				if ok and status == Enum.GroupMembershipStatus.Joined then
					App.toast("WELCOME TO THE GROUP", "+" .. bonus .. "% cash is yours (active from your next join)", "good")
				elseif ok and status == Enum.GroupMembershipStatus.JoinRequestPending then
					App.toast("REQUEST SENT", "Your +" .. bonus .. "% starts once the group accepts you", "info")
				end
			end, { sz = UDim2.fromOffset(200, 48), pos = UDim2.new(1, -224, 1, -70), z = 73, icon = "icon_users" })
			if not calm() then FX.popIn(panel, 0.6, 0.34) end
		end)
	end

	pcall(function()
		AvatarEditorService.PromptSetFavoriteCompleted:Connect(function(...)
			if not favPending then return end
			favPending = false
			local result
			for _, v in ipairs({ ... }) do
				if typeof(v) == "EnumItem" and v.EnumType == Enum.AvatarPromptResult then result = v end
			end
			local fav = result == Enum.AvatarPromptResult.Success
			local st = App.state
			if st then
				st.meta = st.meta or {}
				st.meta.favShown = (st.meta.favShown or 0) + 1
				if fav then st.meta.favorited = true end
			end
			task.spawn(function() App.req("favResult", { favorited = fav }) end)
			if groupEligible() then task.delay(1.5, showGroupPopup) end
		end)
	end)

	-- other code calls App.bigMoment("levelup" / "boss" / "takedown" / "goldMastery" / "firstCrate") after a big win
	App.bigMoment = function(reason)
		local st = App.state
		if not st or not st.onboarded then return end
		local meta = st.meta or {}
		-- the very first session: leave new players alone for their first 2 minutes (moment not used up)
		local firstTime = (meta.favShown or 0) == 0 and not meta.favorited
		if firstTime and os.clock() - sessionStart < 120 then return end
		if favPending then return end
		if not favRolled and not meta.favorited then
			favRolled = true -- only the first eligible moment of a session can show it
			if math.random() < 0.6 then
				favPending = true
				task.delay(0.8, function()
					local ok = pcall(function() AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true) end)
					if not ok then
						favPending = false
						if groupEligible() then task.delay(1, showGroupPopup) end
					end
				end)
				return
			end
		end
		if groupEligible() then task.delay(1.2, showGroupPopup) end
	end
end }

return M
