-- UI: the State Dossier kit built from the rendered images in Shared.Assets (no Luau-drawn plates).
-- Every plate is a 9-slice ImageLabel; text is always a TextLabel (never baked into an image).
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Assets = require(RS.Shared.Assets)
local R = require(RS.Shared.Rules)

local UI = {}
local function hex(h) return Color3.fromHex(h) end
UI.C = {
	ink = hex("ece8dc"), muted = hex("9a9fa6"), dim = hex("6b7179"), manila = hex("e2cfa3"), manilaInk = hex("2a2214"),
	good = hex("8fd07a"), bad = hex("e2695f"), gold = hex("f0c75a"), blue = hex("7fb0e6"), xp = hex("b19cff"),
	inf = hex("e0a650"), sup = hex("6fb3c8"), rule = hex("444b54"), slate = hex("2a2f36"), black = hex("0b0d10"), white = Color3.new(1, 1, 1),
}
UI.Font = {
	display = Font.fromEnum(Enum.Font.SpecialElite),
	body = Font.new("rbxasset://fonts/families/RobotoCondensed.json", Enum.FontWeight.Regular),
	bold = Font.new("rbxasset://fonts/families/RobotoCondensed.json", Enum.FontWeight.Bold),
	heavy = Font.new("rbxasset://fonts/families/RobotoCondensed.json", Enum.FontWeight.ExtraBold),
}
UI.STUD = "rbxassetid://83911407732336" -- Build a Swarm stud pattern (Kash, 26 Sep 2026)

-- 9-slice centres in source pixels, and the slice scale that keeps corners at their designed size
local SLICE = {
	panel = { Rect.new(12, 12, 148, 148), 0.75 }, panel_folder = { Rect.new(12, 14, 148, 148), 0.75 }, panel_plain = { Rect.new(10, 10, 86, 86), 0.75 },
	card = { Rect.new(12, 12, 116, 84), 0.75 }, card_hot = { Rect.new(12, 12, 116, 84), 0.75 },
	topbar = { Rect.new(4, 8, 92, 88), 1 }, inset = { Rect.new(8, 8, 88, 40), 0.75 }, input = { Rect.new(8, 8, 152, 40), 0.75 },
	pill = { Rect.new(20, 19, 76, 21), 0.75 }, chip = { Rect.new(8, 8, 40, 20), 0.75 }, chip_manila = { Rect.new(8, 8, 40, 20), 0.75 },
	bar_track = { Rect.new(8, 8, 56, 20), 0.75 }, bar_fill = { Rect.new(6, 6, 34, 18), 0.75 }, folder_tab = { Rect.new(10, 6, 114, 15), 1 },
	nav_on = { Rect.new(12, 10, 188, 42), 0.75 }, nav_off = { Rect.new(12, 10, 188, 42), 0.75 },
	tab_on = { Rect.new(10, 10, 110, 34), 0.75 }, tab_off = { Rect.new(10, 10, 110, 34), 0.75 },
}
for _, k in ipairs({ "manila", "red", "green", "gold", "blue", "slate", "locked" }) do
	SLICE["btn_" .. k] = { Rect.new(10, 8, 110, 46), 0.7 }
	SLICE["btn_" .. k .. "_down"] = { Rect.new(10, 8, 110, 46), 0.7 }
end
UI.SLICE = SLICE

function UI.mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local mk = UI.mk

function UI.asset(key) return Assets[key] or "" end

-- an image from the art set; plates get their 9-slice automatically
function UI.img(parent, key, p)
	p = p or {}
	local o = mk(p.button and "ImageButton" or "ImageLabel", {
		Name = p.name or key, Image = Assets[key] or "", BackgroundTransparency = 1, BorderSizePixel = 0,
		Position = p.pos or UDim2.new(), Size = p.sz or UDim2.fromScale(1, 1), AnchorPoint = p.anchor or Vector2.zero,
		ZIndex = p.z or 2, ImageColor3 = p.color or UI.C.white, ImageTransparency = p.alpha or 0, LayoutOrder = p.order or 0,
		Visible = p.visible ~= false,
	}, parent)
	local s = SLICE[key]
	if s and p.slice ~= false then
		o.ScaleType = Enum.ScaleType.Slice; o.SliceCenter = s[1]; o.SliceScale = p.sliceScale or s[2]
	elseif p.fit then
		o.ScaleType = Enum.ScaleType.Fit
	end
	if p.pixel then o.ResampleMode = Enum.ResamplerMode.Pixelated end
	if p.button then o.AutoButtonColor = false end
	return o
end

function UI.text(parent, s, p)
	p = p or {}
	local l = mk("TextLabel", {
		Name = p.name or "Text", BackgroundTransparency = 1, Text = s or "", FontFace = UI.Font[p.font or "body"],
		TextSize = p.size or 16, TextColor3 = p.color or UI.C.ink, TextXAlignment = p.align or Enum.TextXAlignment.Left,
		TextYAlignment = p.valign or Enum.TextYAlignment.Center, Position = p.pos or UDim2.new(), AnchorPoint = p.anchor or Vector2.zero,
		Size = p.sz or UDim2.new(1, 0, 0, (p.size or 16) + 6), TextWrapped = p.wrap or false, ZIndex = p.z or 3,
		TextTruncate = p.truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None, RichText = p.rich or false,
		LayoutOrder = p.order or 0, TextScaled = p.scaled or false, Visible = p.visible ~= false,
	}, parent)
	if p.scaled then mk("UITextSizeConstraint", { MaxTextSize = p.size or 16, MinTextSize = 8 }, l) end
	if p.stroke then mk("UIStroke", { Color = UI.C.black, Thickness = p.stroke, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual }, l) end
	if p.auto then l.AutomaticSize = p.auto end
	return l
end
function UI.align(name) return Enum.TextXAlignment[name] end

-- white Lucide icon tinted in Roblox
function UI.icon(parent, key, size, color, pos, p)
	p = p or {}
	return UI.img(parent, key, { sz = UDim2.fromOffset(size, size), pos = pos or UDim2.new(), color = color or UI.C.ink, z = p.z or 4, anchor = p.anchor, name = p.name or "Icon", order = p.order, slice = false })
end

---------------------------------------------------------------- buttons
local INK = { manila = UI.C.manilaInk, gold = UI.C.manilaInk, red = UI.C.white, green = UI.C.white, blue = UI.C.white, slate = UI.C.ink, locked = hex("b9bdc3") }
-- button(parent, kind, label, onClick, p) -> obj { Inst, Label, Set(kind,label), Busy(bool) }
-- p.static = true: a non-interactive plate in the button art (status labels like OWNED / LIMITED), no press animation
function UI.button(parent, kind, label, onClick, p)
	p = p or {}
	local b = UI.img(parent, "btn_" .. kind, { button = true, name = p.name or "Button", pos = p.pos, sz = p.sz or UDim2.fromOffset(120, 40), anchor = p.anchor, z = p.z or 4, order = p.order })
	local face = mk("Frame", { Name = "Face", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -3), ZIndex = b.ZIndex }, b)
	mk("ImageLabel", { Name = "Studs", BackgroundTransparency = 1, Image = UI.STUD, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(10, 10),
		ImageColor3 = UI.C.white, ImageTransparency = 0.88, Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -4), ZIndex = b.ZIndex }, face)
	local iconSize = p.iconSize or math.floor((p.sz and p.sz.Y.Offset or 40) * 0.5)
	local ic
	if p.icon then
		ic = UI.icon(face, p.icon, iconSize, INK[kind], UDim2.new(0, 10, 0.5, 0), { z = b.ZIndex + 1, anchor = Vector2.new(0, 0.5) })
	end
	local lbl = UI.text(face, label, { name = "Label", font = p.font or "heavy", size = p.textSize or 17, align = p.icon and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
		pos = UDim2.fromOffset(p.icon and (14 + iconSize) or 6, 0), sz = UDim2.new(1, p.icon and -(20 + iconSize) or -12, 1, 0), z = b.ZIndex + 1, color = INK[kind], scaled = p.scaledText ~= false, rich = p.rich })
	local scale = mk("UIScale", {}, b)
	local obj = { Inst = b, Label = lbl, Icon = ic, kind = kind, Face = face }
	function obj:Set(k, text)
		if text then lbl.Text = text end
		if k and k ~= self.kind then
			self.kind = k
			b.Image = Assets["btn_" .. k] or ""
			lbl.TextColor3 = INK[k] or UI.C.ink
			if ic then ic.ImageColor3 = INK[k] or UI.C.ink end
		end
	end
	local down = false
	local function press(on)
		if on == down then return end
		down = on
		b.Image = Assets["btn_" .. obj.kind .. (on and "_down" or "")] or ""
		face.Position = UDim2.fromOffset(0, on and 2 or 0)
		TweenService:Create(scale, TweenInfo.new(on and 0.05 or 0.12, on and Enum.EasingStyle.Quad or Enum.EasingStyle.Back), { Scale = on and 0.97 or 1 }):Play()
	end
	if p.static then b.Active = false; b.Selectable = false; return obj end
	b.MouseButton1Down:Connect(function() press(true) end)
	b.MouseButton1Up:Connect(function() press(false) end)
	b.MouseLeave:Connect(function() press(false) end)
	if onClick then b.Activated:Connect(function() onClick(obj) end) end
	return obj
end

---------------------------------------------------------------- bars
-- bar(parent, color, p) -> obj { Inst, Set(frac, leftText, rightText) }
function UI.bar(parent, color, p)
	p = p or {}
	local track = UI.img(parent, "bar_track", { name = p.name or "Bar", pos = p.pos, sz = p.sz or UDim2.fromOffset(200, 24), z = p.z or 3, anchor = p.anchor, order = p.order })
	local fill = UI.img(track, "bar_fill", { name = "Fill", pos = UDim2.fromOffset(3, 3), sz = UDim2.new(0, 0, 1, -6), z = track.ZIndex + 1, color = color })
	local h = (p.sz and p.sz.Y.Offset or 24)
	local left = UI.text(track, "", { font = "heavy", size = p.textSize or math.max(11, h - 9), color = UI.C.white, pos = UDim2.fromOffset(8, 0), sz = UDim2.new(1, -16, 1, 0), z = track.ZIndex + 2, stroke = 1.4 })
	local right = UI.text(track, "", { font = "bold", size = (p.textSize or math.max(11, h - 9)) - 1, color = UI.C.white, pos = UDim2.fromOffset(8, 0), sz = UDim2.new(1, -16, 1, 0), z = track.ZIndex + 2, stroke = 1.4, align = Enum.TextXAlignment.Right })
	local obj = { Inst = track, Fill = fill }
	function obj:Set(frac, l, r)
		frac = math.clamp(frac or 0, 0, 1)
		fill.Visible = frac > 0.01
		fill.Size = UDim2.new(frac, -6 * frac, 1, -6)
		left.Text = l or ""; right.Text = r or ""
	end
	function obj:Color(c) fill.ImageColor3 = c end
	return obj
end

---------------------------------------------------------------- panels
-- folder panel with a typewriter title. Returns panel, body (inner frame with padding)
function UI.panel(parent, title, p)
	p = p or {}
	local key = p.plain and "panel" or "panel_folder"
	local f = UI.img(parent, key, { name = p.name or "Panel", pos = p.pos, sz = p.sz, anchor = p.anchor, z = p.z or 5, button = p.button })
	if title then
		UI.text(f, title, { name = "Title", font = "display", size = p.titleSize or 24, color = UI.C.manila, pos = UDim2.fromOffset(18, 12), sz = UDim2.new(1, -80, 0, 30), z = f.ZIndex + 1, truncate = true })
	end
	local top = title and 48 or 12
	local body = mk("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(14, top), Size = UDim2.new(1, -28, 1, -top - 12), ZIndex = f.ZIndex + 1 }, f)
	return f, body
end

function UI.card(parent, p)
	p = p or {}
	return UI.img(parent, p.hot and "card_hot" or "card", { name = p.name or "Card", pos = p.pos, sz = p.sz, z = p.z or 6, order = p.order, anchor = p.anchor, button = p.button })
end

-- outline(plate, color, thickness, p) -> frame, stroke: a highlight outline that sits exactly on a kit plate's own
-- border. Every plate has a 2 px dark border with ~3 px rounded corners on screen, so the stroke is drawn on an inner
-- frame inset by its thickness (its outer edge lands on the plate edge) with a corner radius that gives the same ~3 px
-- outer radius. Use this for every highlight on a plate (never a raw UIStroke / UICorner on the plate itself).
-- p.alpha = stroke transparency (default 0), p.enabled = false starts it hidden, p.z = ZIndex, p.name.
-- Not for plates whose children are laid out by a UIListLayout / UIGridLayout (chips, auto-sized tags).
function UI.outline(plate, color, t, p)
	p = p or {}
	t = t or 2
	-- a UIPadding on the plate would shift the frame: compensate so it still covers the plate exactly
	local pad = plate:FindFirstChildOfClass("UIPadding")
	local pl, pr, pt, pb = UDim.new(), UDim.new(), UDim.new(), UDim.new()
	if pad then pl, pr, pt, pb = pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom end
	local f = mk("Frame", { Name = p.name or "Outline", BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, Selectable = false,
		Position = UDim2.new(-pl.Scale, t - pl.Offset, -pt.Scale, t - pt.Offset),
		Size = UDim2.new(1 + pl.Scale + pr.Scale, -2 * t + pl.Offset + pr.Offset, 1 + pt.Scale + pb.Scale, -2 * t + pt.Offset + pb.Offset),
		ZIndex = p.z or (plate.ZIndex + 8) }, plate)
	mk("UICorner", { CornerRadius = UDim.new(0, math.max(0, 3 - t)) }, f)
	local st = mk("UIStroke", { Name = "Stroke", Color = color or UI.C.manila, Thickness = t, Transparency = p.alpha or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Enabled = p.enabled ~= false }, f)
	return f, st
end

-- chip(parent, text, p) -> chipImage, label. p.w = fixed width (content centred) instead of sizing to the text;
-- p.button = true makes it an ImageButton (use UI.chipBtn for a clickable chip with press / hover feedback)
function UI.chip(parent, s, p)
	p = p or {}
	local c = UI.img(parent, p.manila and "chip_manila" or "chip", { name = p.name or "Chip", pos = p.pos, sz = UDim2.fromOffset(p.w or 0, p.h or 24), z = p.z or 7, order = p.order, anchor = p.anchor, button = p.button, visible = p.visible })
	if not p.w then c.AutomaticSize = Enum.AutomaticSize.X end
	mk("UIPadding", { PaddingLeft = UDim.new(0, p.icon and 4 or 8), PaddingRight = UDim.new(0, 8) }, c)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = p.w and Enum.HorizontalAlignment.Center or Enum.HorizontalAlignment.Left }, c)
	if p.icon then UI.icon(c, p.icon, (p.h or 24) - 8, p.iconColor or p.color or (p.manila and UI.C.manilaInk or UI.C.ink), nil, { z = c.ZIndex + 1, order = 0 }) end
	local l = UI.text(c, s, { size = p.size or 14, font = "bold", color = p.color or (p.manila and UI.C.manilaInk or UI.C.ink), sz = UDim2.new(0, 0, 1, 0), z = c.ZIndex + 1, order = 1, rich = p.rich })
	l.AutomaticSize = Enum.AutomaticSize.X
	return c, l
end

-- chipBtn(parent, text, onClick, p) -> chipButton, label: a compact clickable chip for small inline actions
-- (DROP RATES on crate cards, "x3 OPEN" shortcuts). Same options as UI.chip.
function UI.chipBtn(parent, s, onClick, p)
	p = p or {}
	local o = {}
	for k, v in pairs(p) do o[k] = v end
	o.button = true
	local c, l = UI.chip(parent, s, o)
	local sc = mk("UIScale", {}, c)
	local function to(v, t) TweenService:Create(sc, TweenInfo.new(t or 0.12, Enum.EasingStyle.Back), { Scale = v }):Play() end
	c.MouseEnter:Connect(function() to(1.06) end)
	c.MouseLeave:Connect(function() to(1) end)
	c.MouseButton1Down:Connect(function() to(0.94, 0.05) end)
	c.MouseButton1Up:Connect(function() to(1.06) end)
	if onClick then c.Activated:Connect(function() onClick(c, l) end) end
	return c, l
end

-- tag(parent, text, color, p) -> plate, label: a solid label plate in the bar-fill art tinted with color (rarity bands,
-- status tags like EQUIPPED / BEST VALUE). color = nil gives the dark chip plate instead. Sizes to its text unless p.sz.
function UI.tag(parent, s, color, p)
	p = p or {}
	local h = p.h or 18
	local key = color and "bar_fill" or "chip"
	local t = UI.img(parent, key, { name = p.name or "Tag", pos = p.pos, sz = p.sz or UDim2.fromOffset(0, h), anchor = p.anchor, z = p.z or 9, order = p.order, color = color, visible = p.visible })
	if p.rot then t.Rotation = p.rot end
	local ink = p.textColor or (color and UI.C.manilaInk or UI.C.ink)
	local l
	if p.sz then
		l = UI.text(t, s, { font = "heavy", size = p.size or math.max(10, h - 6), color = ink, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(4, 0), sz = UDim2.new(1, -8, 1, 0),
			z = t.ZIndex + 1, rich = p.rich, scaled = true })
	else
		t.AutomaticSize = Enum.AutomaticSize.X
		mk("UIPadding", { PaddingLeft = UDim.new(0, p.pad or 7), PaddingRight = UDim.new(0, p.pad or 7) }, t)
		l = UI.text(t, s, { font = "heavy", size = p.size or math.max(10, h - 6), color = ink, sz = UDim2.new(0, 0, 1, 0), z = t.ZIndex + 1, rich = p.rich })
		l.AutomaticSize = Enum.AutomaticSize.X
	end
	return t, l
end

-- infoBtn(parent, pos, onClick, p) -> button obj: the small square "i" button on the slate button plate
function UI.infoBtn(parent, pos, onClick, p)
	p = p or {}
	local s = p.size or 24
	return UI.button(parent, p.kind or "slate", "i", onClick, { name = "Info", pos = pos, anchor = p.anchor, sz = UDim2.fromOffset(s, s), z = p.z or 8, order = p.order, textSize = 15, scaledText = false })
end

function UI.badge(parent, n, pos, z)
	local b = UI.img(parent, "badge", { name = "Badge", pos = pos, sz = UDim2.fromOffset(22, 22), anchor = Vector2.new(0.5, 0.5), z = z or 12, slice = false })
	UI.text(b, tostring(n), { font = "heavy", size = 13, color = UI.C.white, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = b.ZIndex + 1 })
	return b
end

function UI.list(parent, p)
	p = p or {}
	local s = mk("ScrollingFrame", {
		Name = p.name or "List", BackgroundTransparency = 1, BorderSizePixel = 0, Position = p.pos or UDim2.new(), Size = p.sz or UDim2.fromScale(1, 1),
		CanvasSize = UDim2.new(), AutomaticCanvasSize = p.horizontal and Enum.AutomaticSize.X or Enum.AutomaticSize.Y, ScrollBarThickness = 6,
		ScrollBarImageColor3 = UI.C.manila, ScrollingDirection = p.horizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y, ZIndex = p.z or 6,
		ElasticBehavior = Enum.ElasticBehavior.Never, TopImage = "", BottomImage = "", MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png",
	}, parent)
	if p.grid then
		mk("UIGridLayout", { CellSize = p.grid, CellPadding = UDim2.fromOffset(p.gap or 10, p.gap or 10), SortOrder = Enum.SortOrder.LayoutOrder }, s)
	else
		mk("UIListLayout", { FillDirection = p.horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical, Padding = UDim.new(0, p.gap or 8), SortOrder = Enum.SortOrder.LayoutOrder }, s)
	end
	mk("UIPadding", { PaddingRight = UDim.new(0, p.horizontal and 0 or 10), PaddingBottom = UDim.new(0, p.horizontal and 8 or 4), PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2) }, s)
	return s
end
function UI.clear(f)
	for _, c in ipairs(f:GetChildren()) do
		if not (c:IsA("UIListLayout") or c:IsA("UIGridLayout") or c:IsA("UIPadding") or c:IsA("UIScale")) then c:Destroy() end
	end
end

-- tab strip: tabs(parent, {labels}, onPick, p) -> obj { Set(i), buttons }
function UI.tabs(parent, labels, onPick, p)
	p = p or {}
	local row = mk("Frame", { Name = "Tabs", BackgroundTransparency = 1, Position = p.pos or UDim2.new(), Size = p.sz or UDim2.new(1, 0, 0, 34), ZIndex = p.z or 7 }, parent)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, row)
	local obj = { buttons = {}, current = nil, Inst = row }
	for i, label in ipairs(labels) do
		local t = UI.img(row, "tab_off", { button = true, name = "Tab" .. i, sz = UDim2.fromOffset(p.w or 120, (p.sz and p.sz.Y.Offset) or 34), z = row.ZIndex, order = i })
		local l = UI.text(t, label, { font = "heavy", size = p.textSize or 15, align = Enum.TextXAlignment.Center, sz = UDim2.new(1, -8, 1, 0), pos = UDim2.fromOffset(4, 0), z = t.ZIndex + 1, color = UI.C.muted, scaled = true })
		obj.buttons[i] = { Inst = t, Label = l }
		t.Activated:Connect(function() obj:Set(i); if onPick then onPick(i) end end)
	end
	function obj:Set(i)
		self.current = i
		for k, b in ipairs(self.buttons) do
			b.Inst.Image = Assets[k == i and "tab_on" or "tab_off"]
			b.Label.TextColor3 = k == i and UI.C.manilaInk or UI.C.muted
		end
	end
	function obj:Label(i, s) if self.buttons[i] then self.buttons[i].Label.Text = s end end
	return obj
end

---------------------------------------------------------------- flags (14 layouts x 24 colours, built from flat frames like a real flag)
-- flag = { l = layout, c = { hex1, hex2, hex3 }, e = emblem icon key or nil, img = image/decal id or nil }
-- Custom Flag pass (Kash 19:24) adds nordic, saltire, tri, quad, band, disc, an emblem and your own image.
function UI.flag(parent, flag, w, p)
	p = p or {}
	flag = flag or { l = "h3", c = { "1f3a93", "ecf0f1", "c0392b" } }
	local cols = type(flag.c) == "table" and flag.c or {}
	local function col(i, d)
		local ok, c = pcall(Color3.fromHex, tostring(cols[i] or d))
		return ok and c or hex(d)
	end
	local h = math.floor(w * 0.66)
	local z = p.z or 5
	local c1, c2, c3 = col(1, "1f3a93"), col(2, "ecf0f1"), col(3, "c0392b")
	local f = mk("Frame", { Name = "Flag", Position = p.pos or UDim2.new(), Size = UDim2.fromOffset(w, h), AnchorPoint = p.anchor or Vector2.zero, BackgroundColor3 = c1, BorderSizePixel = 0, ZIndex = z, ClipsDescendants = true, LayoutOrder = p.order or 0 }, parent)
	mk("UIStroke", { Color = UI.C.black, Thickness = math.max(1, math.floor(w / 36)) }, f)
	local function rect(x, y, sx, sy, c) return mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = c, Position = UDim2.fromScale(x, y), Size = UDim2.fromScale(sx, sy), ZIndex = z }, f) end
	-- a centred bar rotated by deg, long enough to cross the whole flag
	local function bar(thick, deg, c)
		return mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = c, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, math.ceil(math.sqrt(w * w + h * h)) + 4, 0, math.max(1, math.floor(h * thick))), Rotation = deg, ZIndex = z }, f)
	end
	local l = flag.l
	if l == "h3" then rect(0, 1 / 3, 1, 1 / 3 + 0.01, c2); rect(0, 2 / 3, 1, 1 / 3 + 0.01, c3)
	elseif l == "v3" then rect(1 / 3, 0, 1 / 3 + 0.01, 1, c2); rect(2 / 3, 0, 1 / 3 + 0.01, 1, c3)
	elseif l == "h2" then rect(0, 0.5, 1, 0.5, c2); rect(0.4, 0.3, 0.2, 0.4, c3)
	elseif l == "v2" then rect(0.5, 0, 0.5, 1, c2); rect(0.4, 0.3, 0.2, 0.4, c3)
	elseif l == "cross" then rect(0.28, 0, 0.16, 1, c2); rect(0, 0.4, 1, 0.2, c2); rect(0.32, 0, 0.08, 1, c3); rect(0, 0.45, 1, 0.1, c3)
	elseif l == "diag" then
		local d = mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = c2, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1.6, 0.34), Rotation = -33, ZIndex = z }, f)
		mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = c3, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 0.4), ZIndex = z }, d)
	elseif l == "canton" then rect(0, 0.5, 1, 0.5, c3); rect(0, 0, 0.45, 0.55, c2)
	elseif l == "border" then rect(0.12, 0.18, 0.76, 0.64, c2); rect(0.38, 0.33, 0.24, 0.34, c3)
	elseif l == "nordic" then
		-- Scandinavian cross: off-centre towards the hoist, thin fimbriation in colour 2 around a colour 3 cross
		rect(0.25, 0, 0.17, 1, c2); rect(0, 0.39, 1, 0.22, c2)
		rect(0.28, 0, 0.11, 1, c3); rect(0, 0.435, 1, 0.13, c3)
	elseif l == "saltire" then
		-- diagonal X corner to corner
		local deg = math.deg(math.atan2(h, w))
		bar(0.24, deg, c2); bar(0.24, -deg, c2)
		bar(0.1, deg, c3); bar(0.1, -deg, c3)
	elseif l == "tri" then
		-- two horizontal bands with a triangle at the hoist (a 45-degree square half outside the flag)
		rect(0, 0.5, 1, 0.5, c2)
		local s = math.ceil(h / math.sqrt(2)) + 1
		mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = c3, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(s, s), Rotation = 45, ZIndex = z }, f)
	elseif l == "quad" then
		-- quartered 1/2/2/1 with a thin colour 3 cross between the quarters
		rect(0.5, 0, 0.5, 0.5, c2); rect(0, 0.5, 0.5, 0.5, c2)
		rect(0.475, 0, 0.05, 1, c3); rect(0, 0.465, 1, 0.07, c3)
	elseif l == "band" then
		-- thick central band (colour 2) edged by thin colour 3 lines; colour 1 shows at the top and bottom edges
		rect(0, 0.16, 1, 0.68, c3); rect(0, 0.22, 1, 0.56, c2)
	elseif l == "disc" then
		-- a disc in the centre with a colour 3 ring
		local d = math.floor(h * 0.6)
		local disc = mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = c2, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(d, d), ZIndex = z }, f)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, disc)
		mk("UIStroke", { Color = c3, Thickness = math.max(1, math.floor(h / 16)), ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, disc)
	end
	-- emblem: a white icon in the centre (with a soft dark shadow so it reads on light colours too)
	if flag.e and flag.e ~= "" and not flag.img and Assets[flag.e] then
		local sz = math.max(6, math.floor(h * 0.45))
		local off = math.max(1, math.floor(sz / 20))
		mk("ImageLabel", { Name = "EmblemShadow", BackgroundTransparency = 1, Image = Assets[flag.e], ImageColor3 = UI.C.black, ImageTransparency = 0.45, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, off, 0.5, off), Size = UDim2.fromOffset(sz, sz), ScaleType = Enum.ScaleType.Fit, ZIndex = z + 1 }, f)
		mk("ImageLabel", { Name = "Emblem", BackgroundTransparency = 1, Image = Assets[flag.e], ImageColor3 = UI.C.white, AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(sz, sz), ScaleType = Enum.ScaleType.Fit, ZIndex = z + 2 }, f)
	end
	-- your own image covers the whole flag
	if flag.img and tostring(flag.img) ~= "" then
		local id = tostring(flag.img):match("%d+")
		if id then
			mk("ImageLabel", { Name = "Custom", BackgroundTransparency = 1, Image = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420", ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1), ZIndex = z + 3 }, f)
		end
	end
	return f
end

-- alliance badge (Kash 3 Oct): the alliance colour with its emblem (or the leader's own image), tag underneath when big enough
-- a = { color, tag, emblem, emblemImg }
function UI.allyBadge(parent, a, size, p)
	p = p or {}
	local z = p.z or 5
	local okC, col = pcall(Color3.fromHex, tostring(a.color or "546e7a"))
	local f = mk("Frame", { Name = "AllyBadge", BackgroundColor3 = okC and col or Color3.fromHex("546e7a"), BorderSizePixel = 0, Position = p.pos or UDim2.new(),
		Size = UDim2.fromOffset(size, size), AnchorPoint = p.anchor or Vector2.zero, ZIndex = z, ClipsDescendants = true, LayoutOrder = p.order or 0 }, parent)
	mk("UICorner", { CornerRadius = UDim.new(0, math.max(3, math.floor(size / 8))) }, f)
	mk("UIStroke", { Color = UI.C.black, Thickness = math.max(1, math.floor(size / 28)) }, f)
	local id = a.emblemImg and tostring(a.emblemImg):match("%d+")
	if id then
		mk("ImageLabel", { BackgroundTransparency = 1, Image = "rbxthumb://type=Asset&id=" .. id .. "&w=150&h=150", ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1), ZIndex = z + 1 }, f)
	elseif a.emblem and Assets[a.emblem] then
		local big = size >= 48 and a.tag
		local s = math.floor(size * (big and 0.56 or 0.7))
		UI.img(f, a.emblem, { sz = UDim2.fromOffset(s, s), pos = UDim2.new(0.5, 0, big and 0.4 or 0.5, 0), anchor = Vector2.new(0.5, 0.5), color = UI.C.white, z = z + 1, slice = false })
		if big then UI.text(f, a.tag, { font = "heavy", size = math.floor(size * 0.2), color = UI.C.white, align = Enum.TextXAlignment.Center, pos = UDim2.new(0, 0, 1, -math.floor(size * 0.27)), sz = UDim2.new(1, 0, 0, math.floor(size * 0.24)), z = z + 1, stroke = 1.2 }) end
	else
		UI.text(f, a.tag or "?", { font = "display", size = math.floor(size * 0.34), color = UI.C.white, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = z + 1, stroke = 1.5, scaled = size < 40 })
	end
	return f
end

---------------------------------------------------------------- formatting shortcuts
UI.Money = R.Money
UI.Short = R.Short
UI.Clock = R.Clock
UI.Duration = R.Duration
return UI
