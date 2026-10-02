-- Shop: the store screen (key "shop", replaces the old list in Social.lua because this module loads later) and the
-- VIP / MEGA VIP chat tags (_vipTags init). Layout: LIMITED hero row (Limited Bundle + Founder's Crate), Supply Crate,
-- VIP passes, game passes, gold packs + gold spends, repeatable boosts. Built once per width, then Refresh/Tick only
-- update owned states, prices and timers so hover/shine animations keep running.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local O = require(Shared.Officers)
local Config = require(Shared.Config)
local UI = require(script.Parent:WaitForChild("UI"))
local C = UI.C
local mk, text = UI.mk, UI.text

local S = {}

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

-- gold spend prices mirror server/Actions.lua A.GoldPrices (inf = 10, sup = 5); not in Config yet
local GOLD_INF, GOLD_SUP = 10, 5
local ROBUX = Color3.fromHex("3fd27a")
local TEAL = Color3.fromHex("3fe0d0")
local PINK = Color3.fromHex(Config.VIP.MegaVIP.color)
local VIPGOLD = Color3.fromHex(Config.VIP.VIP.color)
local LIMITED = Color3.fromHex("ff9a2e")
local DARK = Color3.fromHex("121519")

local PASS_ART = { FastConvoys = "pass_express", AutoDispatch = "pass_auto", ExtraConvoys = "pass_convoys", ExtraLots = "pass_lots",
	BonusOfficer = "pass_officer", CrateLuck = "pass_luck", VIP = "pass_vip", MegaVIP = "pass_megavip", CustomFlag = "pass_flag" }

---------------------------------------------------------------- small local kit
local function tw(o, t, props, style, dir, rep, rev, delay)
	local tween = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, rep or 0, rev or false, delay or 0), props)
	tween:Play()
	return tween
end
local function corner(o, r) return mk("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 8) }, o) end
local function stroke(o, c, th, tr)
	return mk("UIStroke", { Color = c, Thickness = th or 2, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end
local function kp(t, v) return NumberSequenceKeypoint.new(t, v) end

local function timeLeft(sec)
	sec = math.max(0, math.floor(sec))
	local d, h, m, s = sec // 86400, (sec % 86400) // 3600, (sec % 3600) // 60, sec % 60
	if d > 0 then return string.format("%dd %02dh %02dm", d, h, m) end
	return string.format("%02d:%02d:%02d", h, m, s)
end

-- a coloured pill tag that sizes to its text
local function tag(parent, label, bg, fg, p)
	p = p or {}
	local f = mk("Frame", { Name = "Tag", BackgroundColor3 = bg, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, p.h or 20),
		Position = p.pos or UDim2.new(), AnchorPoint = p.anchor or Vector2.zero, ZIndex = p.z or 12, Rotation = p.rot or 0, LayoutOrder = p.order or 0 }, parent)
	corner(f, p.radius or 5)
	mk("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7) }, f)
	if p.stroke then stroke(f, p.stroke, 1.5) end
	local l = text(f, label, { font = "heavy", size = p.size or 12, color = fg, sz = UDim2.new(0, 0, 1, 0), z = f.ZIndex + 1, rich = p.rich })
	l.AutomaticSize = Enum.AutomaticSize.X
	return f, l
end

-- diagonal corner ribbon (top-right of a card)
local function ribbon(card, label, bg, fg)
	local clip = mk("Frame", { Name = "Ribbon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 2), Size = UDim2.fromOffset(92, 92),
		ClipsDescendants = true, ZIndex = 30 }, card)
	local band = mk("Frame", { BackgroundColor3 = bg, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(58, 34), Size = UDim2.fromOffset(150, 24),
		Rotation = 45, ZIndex = 30 }, clip)
	mk("UIGradient", { Color = ColorSequence.new(bg:Lerp(C.white, 0.25), bg) , Rotation = 90 }, band)
	stroke(band, C.black, 1, 0.5)
	text(band, label, { font = "heavy", size = 12, color = fg, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 31 })
	return clip
end

-- a slow white sheen sweeping across a premium card every few seconds
local function shine(card, period, delay)
	local clip = mk("Frame", { Name = "Shine", BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), ClipsDescendants = true, ZIndex = 25 }, card)
	local bar = mk("Frame", { BackgroundColor3 = C.white, BackgroundTransparency = 0, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(-0.35, 0, 0.5, 0),
		Size = UDim2.new(0, 60, 2.2, 0), Rotation = 18, ZIndex = 25 }, clip)
	mk("UIGradient", { Transparency = NumberSequence.new({ kp(0, 1), kp(0.5, 0.78), kp(1, 1) }) }, bar)
	task.delay(delay or 0, function()
		if bar.Parent then tw(bar, 1.2, { Position = UDim2.new(1.35, 0, 0.5, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, false, period or 3.2) end
	end)
	return clip
end

-- animated gradient border (rotating colours) on a card
local function gradBorder(card, colors, th)
	local ring = mk("Frame", { Name = "GradBorder", BackgroundTransparency = 1, Size = UDim2.new(1, -2, 1, -2), Position = UDim2.fromOffset(1, 1), ZIndex = 24 }, card)
	corner(ring, 10)
	local st = stroke(ring, C.white, th or 3)
	local seq = {}
	for i, c in ipairs(colors) do table.insert(seq, ColorSequenceKeypoint.new((i - 1) / (#colors - 1), c)) end
	local g = mk("UIGradient", { Color = ColorSequence.new(seq) }, st)
	tw(g, 4, { Rotation = 360 }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
	return ring
end

-- soft static glow behind a card (placed in the card's cell, under the card). Was a pulsing frame halo (Kash 18:41)
local function halo(cell, c1, c2, z, maxPad)
	maxPad = maxPad or 10
	UI.img(cell, "glow_soft", { name = "Halo", color = c1:Lerp(c2, 0.35), alpha = 0.55, slice = false, z = z, anchor = Vector2.new(0.5, 0.5),
		pos = UDim2.fromScale(0.5, 0.5), sz = UDim2.new(1, maxPad * 6, 1, maxPad * 6) })
end

-- rays = the classic rotating game-pass beams (premium items); otherwise a faint static soft glow. No pulsing circles.
-- clip = optional frame to hold the beams so they stay inside the card
local function aura(parent, color, size, pos, z, strength, rays, clip)
	strength = strength or 1
	if rays then
		local host = parent
		if clip then
			host = mk("Frame", { Name = "BeamClip", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, ZIndex = z }, parent)
		end
		return FX.beams(UI, host, color, size, pos, z, strength)
	end
	return UI.img(parent, "glow_soft", { name = "Glow", color = color, alpha = 1 - 0.6 * strength, slice = false, z = z, anchor = Vector2.new(0.5, 0.5),
		pos = pos or UDim2.fromScale(0.5, 0.5), sz = UDim2.fromOffset(size, size) })
end

-- a layout cell holding a card that lifts and glows on hover. Returns cell, card, glowStroke
local function liftCard(parent, p)
	p = p or {}
	local cell = mk("Frame", { Name = p.name or "Cell", BackgroundTransparency = 1, Size = p.sz or UDim2.fromScale(1, 1), Position = p.pos or UDim2.new(),
		LayoutOrder = p.order or 0, ZIndex = 7 }, parent)
	if p.halo then halo(cell, p.halo[1], p.halo[2], 7, p.haloPad) end
	local card = UI.card(cell, { hot = p.hot, sz = UDim2.fromScale(1, 1), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 8 })
	local ring = mk("Frame", { Name = "HoverGlow", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 23 }, card)
	corner(ring, 10)
	local base = p.baseGlow or 1
	local gs = stroke(ring, p.glow or C.manila, 2, base)
	local sc = mk("UIScale", {}, card)
	card.MouseEnter:Connect(function()
		tw(card, 0.16, { Position = UDim2.new(0.5, 0, 0.5, -4) }, Enum.EasingStyle.Back)
		tw(sc, 0.16, { Scale = 1.012 })
		tw(gs, 0.16, { Transparency = 0.05 })
	end)
	card.MouseLeave:Connect(function()
		tw(card, 0.2, { Position = UDim2.fromScale(0.5, 0.5) })
		tw(sc, 0.2, { Scale = 1 })
		tw(gs, 0.2, { Transparency = base })
	end)
	return cell, card, gs
end

-- a buy button that swaps to a muted OWNED check
local function ownButton(parent, kind, label, fn, p)
	local b = UI.button(parent, kind, label, fn, p)
	local own = UI.button(parent, "locked", p.ownedLabel or "OWNED", nil, { sz = p.sz, pos = p.pos, anchor = p.anchor, z = p.z, icon = "icon_check", textSize = p.textSize })
	own.Inst.Visible = false
	local obj = { buy = b, own = own }
	function obj:Set(owned, ownedLabel, buyKind, buyLabel)
		b.Inst.Visible = not owned
		own.Inst.Visible = owned and true or false
		if ownedLabel then own:Set(nil, ownedLabel) end
		if buyKind or buyLabel then b:Set(buyKind, buyLabel) end
	end
	return obj
end

local function infoPopup(App, title, body)
	local mh = App.modalHost
	UI.clear(mh)
	mh.Visible = true
	local w, h = math.min(460, App.W() - 24), math.min(270, App.H() - 24)
	local panel, bd = UI.panel(mh, title, { sz = UDim2.fromOffset(w, h), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71 })
	FX.popIn(panel, 0.6, 0.3)
	text(bd, body, { size = 16, wrap = true, rich = true, sz = UDim2.new(1, 0, 1, -54), valign = Enum.TextYAlignment.Top, z = 74 })
	UI.button(bd, "slate", "GOT IT", function() mh.Visible = false end, { sz = UDim2.fromOffset(150, 42), pos = UDim2.new(0.5, 0, 1, -4), anchor = Vector2.new(0.5, 1), z = 74 })
end
local function infoBtn(App, parent, title, body, pos, z)
	local b = mk("TextButton", { Name = "Info", Text = "i", FontFace = UI.Font.heavy, TextSize = 14, TextColor3 = C.manila, BackgroundColor3 = C.slate,
		AutoButtonColor = false, Size = UDim2.fromOffset(20, 20), Position = pos, ZIndex = z or 30 }, parent)
	corner(b, UDim.new(1, 0))
	stroke(b, C.manila, 1.4)
	b.Activated:Connect(function() infoPopup(App, title, body) end)
	return b
end

-- crate results: the big reveal when Cabinet installed it, else a toast that points to the Inventory
local function showCrateResult(App, res)
	if App.crateReveal then
		local ok = pcall(App.crateReveal, App, res)
		if ok then return end
	end
	local best, bi = nil, 0
	for _, r in ipairs(res.results or {}) do
		local rr = r.item and O.RarityByKey[r.item.rarity or "common"]
		local i = rr and rr.index or 1
		if i > bi then bi, best = i, r end
	end
	if best and best.item then
		local rr = O.RarityByKey[best.item.rarity or "common"] or O.Rarities[1]
		App.toast("YOU GOT " .. string.upper(best.item.name or "AN ITEM"), rr.name .. (best.type == "officer" and " officer" or " gear") .. " · see your INVENTORY", Color3.fromHex(rr.color))
	else
		App.toast("CRATE OPENED", "See your INVENTORY", "gold")
	end
	if App.navBadge then App.navBadge("inventory", "!") end
end

---------------------------------------------------------------- SHOP
S.shop = { build = function(host, App)
	local panel, body = UI.panel(host, "SHOP", { sz = UDim2.new(1, -20, 1, -20), pos = UDim2.fromOffset(10, 10), z = 5, titleSize = 26 })
	local sub = text(panel, "", { font = "bold", size = 15, color = C.muted, pos = UDim2.new(0, 120, 0, 16), sz = UDim2.new(1, -138, 0, 22), z = 7,
		align = Enum.TextXAlignment.Right, rich = true, truncate = true })
	local list = UI.list(body, { gap = 10, z = 6 })
	local obj = { ups = {}, ticks = {}, anchors = {}, builtW = nil, shownGold = nil }

	local function innerW() return math.max(480, App.W() - (App.NAVW or 176) - 20 - 28 - 14) end
	local function scale()
		local s = App.root and App.root:FindFirstChild("Fit")
		return s and s.Scale or 1
	end
	local function scrollTo(key)
		local f = obj.anchors[key]
		if not f then return end
		local y = (f.AbsolutePosition.Y - list.AbsolutePosition.Y) / scale() + list.CanvasPosition.Y
		tw(list, 0.45, { CanvasPosition = Vector2.new(0, math.max(0, y - 4)) }, Enum.EasingStyle.Quint)
	end
	local function up(fn) table.insert(obj.ups, fn) end
	local function onTick(fn) table.insert(obj.ticks, fn) end

	local order = 0
	local function nextOrder() order += 1; return order end

	local function section(key, title, subtitle, icon, color)
		local f = mk("Frame", { Name = "H_" .. key, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 52), LayoutOrder = nextOrder(), ZIndex = 7 }, list)
		UI.icon(f, icon, 24, color or C.manila, UDim2.fromOffset(0, 6), { z = 8 })
		text(f, title, { font = "display", size = 24, color = C.manila, pos = UDim2.fromOffset(32, 2), sz = UDim2.new(1, -32, 0, 30), z = 8, truncate = true })
		text(f, subtitle, { size = 14, color = C.muted, pos = UDim2.fromOffset(32, 30), sz = UDim2.new(1, -32, 0, 18), z = 8, truncate = true, rich = true })
		local rule = mk("Frame", { BackgroundColor3 = color or C.manila, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2), ZIndex = 8 }, f)
		mk("UIGradient", { Transparency = NumberSequence.new({ kp(0, 0.2), kp(0.6, 0.85), kp(1, 1) }) }, rule)
		obj.anchors[key] = f
		return f
	end

	-- a grid of cards with computed cell sizes so it wraps cleanly at any width
	local function grid(minW, h, gap, maxCols, pad)
		pad = pad or 8
		local W = innerW() - pad * 2
		local n = math.max(1, math.floor((W + gap) / (minW + gap)))
		if maxCols then n = math.min(n, maxCols) end
		local cw = math.floor((W - gap * (n - 1)) / n)
		local f = mk("Frame", { Name = "Grid", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(), ZIndex = 7 }, list)
		mk("UIGridLayout", { CellSize = UDim2.fromOffset(cw, h), CellPadding = UDim2.fromOffset(gap, gap), SortOrder = Enum.SortOrder.LayoutOrder }, f)
		mk("UIPadding", { PaddingTop = UDim.new(0, pad), PaddingBottom = UDim.new(0, pad), PaddingLeft = UDim.new(0, pad), PaddingRight = UDim.new(0, pad) }, f)
		return f, cw
	end

	-- standard tall card: art on top, name, short description, button at the bottom
	local function tallCard(parent, p)
		local cell, card = liftCard(parent, { order = p.order, hot = p.hot, glow = p.glow, halo = p.halo, baseGlow = p.baseGlow })
		local artH = p.artH or 104
		local glowC = p.artGlow or C.manila
		aura(card, glowC, artH * 1.25, UDim2.new(0.5, 0, 0, 14 + artH / 2), 9, 0.35, false)
		local art = UI.img(card, p.art, { sz = UDim2.new(1, -28, 0, artH), pos = UDim2.new(0.5, 0, 0, 14), anchor = Vector2.new(0.5, 0), slice = false, fit = true, z = 10 })
		local y = 18 + artH
		local name = text(card, p.name, { font = "heavy", size = 18, color = p.nameColor or C.ink, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(10, y), sz = UDim2.new(1, -20, 0, 22), z = 10, truncate = true })
		local desc = text(card, p.desc, { size = 13, color = C.muted, align = Enum.TextXAlignment.Center, valign = Enum.TextYAlignment.Top, wrap = true, rich = true,
			pos = UDim2.fromOffset(12, y + 24), sz = UDim2.new(1, -24, 1, -(y + 24) - (p.live and 82 or 62)), z = 10 })
		local check = UI.icon(card, "icon_check", 26, C.good, UDim2.new(1, -14, 0, 14), { z = 12, anchor = Vector2.new(1, 0) })
		check.Visible = false
		return { cell = cell, card = card, art = art, name = name, desc = desc, check = check,
			btnSz = UDim2.new(1, -28, 0, 42), btnPos = UDim2.new(0.5, 0, 1, -14) }
	end
	local function markOwned(t, owned)
		t.check.Visible = owned and true or false
		t.art.ImageTransparency = owned and 0.35 or 0
		t.name.TextColor3 = owned and C.muted or C.ink
	end

	local function buyProduct(key, btn) App.req("buyProduct", { key = key }, btn) end
	local function buyPass(key, btn)
		if App.state and App.state.gp and App.state.gp[key] then return end
		App.req("buyPass", { key = key }, btn)
	end
	local function crateOver() return App.now() > Config.Crates.Limited.ends end

	------------------------------------------------------------ 1. LIMITED hero row
	local function hero()
		local L = Config.Crates.Limited
		section("limited", "LIMITED TIME", "Founder's offers leave the shop when the timer runs out", "icon_sparkles", C.gold)
		local W = innerW()
		local pad = 10
		local gap = 16
		local H = 344
		local stack = W < 700
		local inner = W - pad * 2
		local bw = stack and inner or math.floor((inner - gap) * 0.58)
		local cw = stack and inner or (inner - gap - bw)
		local row = mk("Frame", { Name = "Hero", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, (stack and (H * 2 + gap) or H) + pad * 2), LayoutOrder = nextOrder(), ZIndex = 7 }, list)
		mk("UIPadding", { PaddingTop = UDim.new(0, pad), PaddingBottom = UDim.new(0, pad), PaddingLeft = UDim.new(0, pad), PaddingRight = UDim.new(0, pad) }, row)

		-------------------------------------------------- LIMITED BUNDLE
		local _, bc = liftCard(row, { name = "Bundle", sz = UDim2.fromOffset(bw, H), hot = true, glow = C.gold, baseGlow = 0.6, halo = { C.gold, TEAL }, haloPad = 10 })
		local artHost = mk("Frame", { BackgroundColor3 = DARK, BorderSizePixel = 0, Position = UDim2.fromOffset(5, 5), Size = UDim2.new(1, -10, 1, -10), ZIndex = 9, ClipsDescendants = true }, bc)
		corner(artHost, 8)
		local bart = UI.img(artHost, "shop_bundle", { sz = UDim2.fromScale(1, 1), slice = false, z = 9 })
		bart.ScaleType = Enum.ScaleType.Crop
		corner(bart, 8)
		-- slow golden light rays over the bundle art, like game-pass art (Kash 18:41)
		FX.beams(UI, artHost, C.gold, math.floor(H * 1.6), UDim2.fromScale(0.5, 0.4), 9, 0.32)
		local shade = mk("Frame", { BackgroundColor3 = C.black, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 10 }, artHost)
		corner(shade, 8)
		mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ kp(0, 0.75), kp(0.3, 1), kp(0.55, 0.75), kp(1, 0.08) }) }, shade)
		gradBorder(bc, { C.gold, TEAL, C.gold, TEAL, C.gold }, 3)
		shine(bc, 3.4, 0.3)
		tag(bc, "LIMITED BUNDLE", C.gold, C.manilaInk, { pos = UDim2.fromOffset(16, 16), z = 26, h = 24, size = 14 })
		local _, onceL = tag(bc, "ONE PER PLAYER", DARK, C.gold, { pos = UDim2.fromOffset(16, 46), z = 26, h = 20, size = 11, stroke = C.gold })
		local clockChip = mk("Frame", { BackgroundColor3 = DARK, BackgroundTransparency = 0.15, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
			Size = UDim2.fromOffset(170, 26), ZIndex = 26 }, bc)
		corner(clockChip, 6)
		stroke(clockChip, LIMITED, 1.5)
		UI.icon(clockChip, "icon_clock", 16, LIMITED, UDim2.fromOffset(8, 5), { z = 27 })
		local bTimer = text(clockChip, "", { font = "heavy", size = 14, color = LIMITED, pos = UDim2.fromOffset(28, 0), sz = UDim2.new(1, -34, 1, 0), z = 27, scaled = true })
		local by = H - 132
		local bTitle = text(bc, "LIMITED BUNDLE · <font color='#3fd27a'>999 R$</font>", { font = "display", size = stack and 26 or (bw < 520 and 24 or 30), pos = UDim2.fromOffset(18, by),
			sz = UDim2.new(1, -36, 0, 36), z = 26, stroke = 1.6, rich = true, scaled = true })
		bTitle.Text = "LIMITED BUNDLE · <font color='#3fd27a'>" .. Config.Products.LimitedBundle.robux .. " R$</font>"
		text(bc, "<b><font color='#ff9a2e'>Empress Valeria Thorne</font></b> (LIMITED officer) + <b><font color='#f0c75a'>Founder's Saber</font></b>",
			{ size = 15, pos = UDim2.fromOffset(18, by + 38), sz = UDim2.new(1, -36, 0, 40), z = 26, wrap = true, rich = true, stroke = 1, valign = Enum.TextYAlignment.Top })
		tag(bc, "LIMITED", LIMITED, C.white, { pos = UDim2.new(0, 18, 1, -42), z = 26, h = 26, size = 13 })
		local bbtn = ownButton(bc, "green", "BUY · R$ " .. Config.Products.LimitedBundle.robux, function(btn)
			if App.state and App.state.bundle then return end
			buyProduct("LimitedBundle", btn)
		end, { sz = UDim2.fromOffset(math.min(230, bw - 130), 48), pos = UDim2.new(1, -16, 1, -14), anchor = Vector2.new(1, 1), z = 27, textSize = 19 })
		-- big OWNED stamp
		local stamp = mk("Frame", { Name = "Stamp", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.fromOffset(220, 64),
			Rotation = -12, ZIndex = 28, Visible = false }, bc)
		corner(stamp, 8)
		stroke(stamp, C.gold, 4)
		text(stamp, "OWNED", { font = "display", size = 44, color = C.gold, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 29, stroke = 1.5 })
		up(function(st)
			local owned = st.bundle and true or false
			local over = crateOver()
			bbtn:Set(owned, "OWNED", over and "locked" or "green", over and "SOLD OUT" or nil)
			stamp.Visible = owned
			bart.ImageTransparency = owned and 0.3 or 0
			onceL.Text = owned and "IN YOUR ROSTER" or "ONE PER PLAYER"
		end)
		onTick(function(now)
			local leftS = L.ends - now
			bTimer.Text = leftS > 0 and ("ENDS IN " .. timeLeft(leftS)) or "SOLD OUT"
		end)

		-------------------------------------------------- FOUNDER'S CRATE
		local _, cc = liftCard(row, { name = "Crate", sz = UDim2.fromOffset(cw, H), pos = stack and UDim2.fromOffset(0, H + gap) or UDim2.fromOffset(bw + gap, 0), glow = LIMITED, baseGlow = 0.7 })
		text(cc, L.name, { font = "display", size = 22, color = C.manila, pos = UDim2.fromOffset(16, 10), sz = UDim2.new(1, -60, 0, 28), z = 10, truncate = true })
		infoBtn(App, cc, L.name, "One crate, two prices: open one now for <b>" .. L.gold .. " gold</b>, or buy Robux packs that go to your <b>Inventory</b> to open any time.\n\n"
			.. "Mostly cool gear, sometimes an officer. The <b>10-pack</b> guarantees at least one <b>Epic or better</b>. The <b>2x Crate Luck</b> pass doubles Legendary+ odds.",
			UDim2.new(1, -34, 0, 14), 30)
		local cTimer = text(cc, "", { font = "heavy", size = 13, color = LIMITED, pos = UDim2.fromOffset(16, 38), sz = UDim2.new(1, -32, 0, 18), z = 10 })
		local crateSize = 116
		aura(cc, LIMITED, 220, UDim2.new(0.5, 0, 0, 62 + crateSize / 2), 9, 0.9, true, true)
		local crate = UI.img(cc, "crate_limited", { sz = UDim2.fromOffset(crateSize, crateSize), pos = UDim2.new(0.5, 0, 0, 62 + crateSize / 2), anchor = Vector2.new(0.5, 0.5), slice = false, fit = true, z = 11 })
		tw(crate, 1.6, { Position = UDim2.new(0.5, 0, 0, 56 + crateSize / 2) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		tw(crate, 2.4, { Rotation = 3 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
		-- owned crates shortcut
		local haveBtn = mk("TextButton", { Name = "Have", Text = "", AutoButtonColor = false, BackgroundColor3 = DARK, BackgroundTransparency = 0.1, AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -12, 0, 64), Size = UDim2.fromOffset(92, 24), ZIndex = 14, Visible = false }, cc)
		corner(haveBtn, 6)
		stroke(haveBtn, C.gold, 1.4)
		local haveL = text(haveBtn, "", { font = "heavy", size = 12, color = C.gold, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 15 })
		haveBtn.Activated:Connect(function()
			if App.openCrates then App.openCrates("limited", 1, haveBtn) else App.open("inventory") end
		end)
		text(cc, "Mostly cool gear, sometimes an officer", { size = 14, color = C.ink, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(12, 184), sz = UDim2.new(1, -24, 0, 20), z = 10, truncate = true })
		local goldBtn = UI.button(cc, "gold", "OPEN NOW · " .. L.gold .. " GOLD", function(btn)
			if crateOver() then return end
			local st = App.state
			if st and (st.gold or 0) < L.gold then
				App.toast("NOT ENOUGH GOLD", "You need " .. L.gold .. " gold. Grab a gold pack below.", "bad")
				App.shake(btn.Inst)
				scrollTo("gold")
				return
			end
			local res = App.req("buyCrate", { kind = "limited" }, btn)
			if res.ok then showCrateResult(App, res) end
		end, { sz = UDim2.new(1, -28, 0, 44), pos = UDim2.fromOffset(14, 210), z = 12, icon = "icon_gold", textSize = 17 })
		-- Robux packs 1 / 3 / 10
		local packs = { { key = "Crate1", n = 1 }, { key = "Crate3", n = 3 }, { key = "Crate10", n = 10 } }
		local pg = 8
		local pw = math.floor((cw - 28 - pg * 2) / 3)
		local packBtns = {}
		for i, pk in ipairs(packs) do
			local prod = Config.Products[pk.key]
			local x = 14 + (i - 1) * (pw + pg)
			local b = UI.button(cc, "green", pk.n .. "x · R$ " .. prod.robux, function(btn)
				if crateOver() then return end
				buyProduct(pk.key, btn)
			end, { sz = UDim2.fromOffset(pw, 44), pos = UDim2.fromOffset(x, 272), z = 12, textSize = 16 })
			packBtns[i] = b
			if pk.n == 10 then
				stroke(b.Inst, C.gold, 2, 0.1)
				local t = tag(cc, "BEST VALUE", C.gold, C.manilaInk, { pos = UDim2.fromOffset(x + pw / 2, 264), anchor = Vector2.new(0.5, 0.5), z = 16, h = 18, size = 11, rot = -4 })
				local ts = mk("UIScale", {}, t)
				tw(ts, 0.8, { Scale = 1.08 }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
				text(cc, "+Epic guaranteed", { font = "heavy", size = 12, color = Color3.fromHex("b06ef0"), align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(x - 10, 318), sz = UDim2.fromOffset(pw + 20, 16), z = 12 })
			end
		end
		-- per-crate price hint under the first two
		for i = 1, 2 do
			local prod = Config.Products[packs[i].key]
			local x = 14 + (i - 1) * (pw + pg)
			text(cc, i == 1 and "to Inventory" or (math.floor(prod.robux / packs[i].n + 0.5) .. " R$ each"), { size = 12, color = C.dim, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(x, 318), sz = UDim2.fromOffset(pw, 16), z = 12 })
		end
		up(function(st)
			local over = crateOver()
			local g = st.gold or 0
			goldBtn:Set(over and "locked" or (g >= L.gold and "gold" or "locked"), over and "LEFT THE SHOP" or ("OPEN NOW · " .. L.gold .. " GOLD"))
			for _, b in ipairs(packBtns) do b:Set(over and "locked" or "green") end
			local n = st.crates and st.crates.limited or 0
			haveBtn.Visible = n > 0
			haveL.Text = "x" .. n .. " · OPEN"
		end)
		onTick(function(now)
			local leftS = L.ends - now
			cTimer.Text = leftS > 0 and ("Leaves the shop in " .. timeLeft(leftS)) or "This crate has left the shop"
		end)
	end

	------------------------------------------------------------ 2. SUPPLY CRATE (free path)
	local function supply()
		local B = Config.Crates.Basic
		section("supply", "SUPPLY CRATE", "Free to play: bought with cash. Price = " .. B.lawMinutes .. " min of law income at your level", "icon_package", C.manila)
		local W = innerW()
		local wrap = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 132), LayoutOrder = nextOrder(), ZIndex = 7 }, list)
		mk("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, wrap)
		local _, card = liftCard(wrap, { name = "Supply" })
		aura(card, C.manila, 120, UDim2.fromOffset(70, 58), 9, 0.3, false)
		local crate = UI.img(card, "crate_basic", { sz = UDim2.fromOffset(92, 92), pos = UDim2.fromOffset(70, 58), anchor = Vector2.new(0.5, 0.5), slice = false, fit = true, z = 10 })
		local cs = mk("UIScale", {}, crate)
		card.MouseEnter:Connect(function() tw(crate, 0.3, { Rotation = -6 }, Enum.EasingStyle.Back) ; tw(cs, 0.3, { Scale = 1.08 }, Enum.EasingStyle.Back) end)
		card.MouseLeave:Connect(function() tw(crate, 0.3, { Rotation = 0 }); tw(cs, 0.3, { Scale = 1 }) end)
		local rightW = W < 820 and 200 or 240
		text(card, B.name, { font = "display", size = 22, color = C.manila, pos = UDim2.fromOffset(130, 12), sz = UDim2.new(1, -150 - rightW, 0, 28), z = 10, truncate = true })
		tag(card, "FREE TO PLAY", C.good, C.manilaInk, { pos = UDim2.fromOffset(132, 44), z = 11, h = 20, size = 11 })
		text(card, "Gear and the odd officer. Opens right away.", { size = 14, color = C.muted, pos = UDim2.fromOffset(130, 70), sz = UDim2.new(1, -150 - rightW, 0, 36), z = 10, wrap = true, valign = Enum.TextYAlignment.Top })
		local buy = UI.button(card, "manila", "BUY & OPEN", function(btn)
			local st = App.state
			local price = st and st.basicCratePrice or 0
			if st and st.cash < price then App.toast("NOT ENOUGH CASH", "A Supply Crate costs " .. R.Money(price), "bad"); App.shake(btn.Inst); return end
			local res = App.req("buyCrate", { kind = "basic" }, btn)
			if res.ok then App.float(btn.Inst, "-" .. R.Money(price), C.good); showCrateResult(App, res) end
		end, { sz = UDim2.fromOffset(rightW - 16, 46), pos = UDim2.new(1, -14, 0, 14), anchor = Vector2.new(1, 0), z = 11, icon = "icon_cash", textSize = 16 })
		local openOwned = UI.button(card, "slate", "OPEN OWNED", function(btn)
			if App.openCrates then App.openCrates("basic", 1, btn) else App.open("inventory") end
		end, { sz = UDim2.fromOffset(rightW - 16, 36), pos = UDim2.new(1, -14, 1, -12), anchor = Vector2.new(1, 1), z = 11, textSize = 14 })
		up(function(st)
			local price = st.basicCratePrice or 0
			buy:Set((st.cash or 0) >= price and "manila" or "locked", "BUY & OPEN · " .. R.Money(price))
			local n = st.crates and st.crates.basic or 0
			openOwned.Inst.Visible = n > 0
			openOwned:Set(nil, "OPEN OWNED (" .. n .. ")")
		end)
	end

	------------------------------------------------------------ 3. VIP
	local function vip()
		section("vip", "VIP", "Forever perks and a chat tag everyone sees · Mega VIP replaces VIP (they do not stack)", "icon_crown", VIPGOLD)
		local H = 236
		local g, cw = grid(330, H, 18, 2, 12)
		local function vipCard(key, order, color, perks, premium)
			local pass = Config.Passes[key]
			local _, card = liftCard(g, { order = order, hot = premium, glow = color, baseGlow = premium and 0.5 or 0.85, halo = premium and { PINK, C.gold } or nil, haloPad = 10 })
			local art = math.clamp(math.floor(cw * 0.3), 96, 150)
			aura(card, color, premium and math.floor(art * 1.8) or math.floor(art * 1.3), UDim2.fromOffset(14 + art / 2, 16 + art / 2), 9, premium and 0.9 or 0.4, premium, true)
			local img = UI.img(card, PASS_ART[key], { sz = UDim2.fromOffset(art, art), pos = UDim2.fromOffset(14, 16), slice = false, fit = true, z = 10 })
			local x = 26 + art
			local tagText = Config.VIP[key].tag
			text(card, string.upper(pass.name), { font = "display", size = 26, color = color, pos = UDim2.fromOffset(x, 12), sz = UDim2.new(1, -x - (premium and 56 or 16), 0, 32), z = 10, truncate = true, stroke = 1 })
			tag(card, "[" .. tagText .. "] " .. Players.LocalPlayer.DisplayName, DARK, color, { pos = UDim2.fromOffset(x, 46), z = 11, h = 20, size = 12, stroke = color })
			for i, line in ipairs(perks) do
				local y = 72 + (i - 1) * 24
				UI.icon(card, "icon_check", 16, color, UDim2.fromOffset(x, y + 3), { z = 10 })
				text(card, line, { size = 15, color = C.ink, pos = UDim2.fromOffset(x + 22, y), sz = UDim2.new(1, -x - 36, 0, 22), z = 10, rich = true, scaled = true })
			end
			local btn = ownButton(card, "green", "R$ " .. pass.price, function(b) buyPass(key, b) end,
				{ sz = UDim2.fromOffset(math.min(210, cw - x - 14), 46), pos = UDim2.new(1, -14, 1, -14), anchor = Vector2.new(1, 1), z = 12, textSize = 18 })
			if premium then
				gradBorder(card, { PINK, C.gold, PINK, C.gold, PINK }, 3)
				shine(card, 2.8, 1.2)
				ribbon(card, "BEST", PINK, C.white)
			end
			return btn, img
		end
		local V, M = Config.VIP.VIP, Config.VIP.MegaVIP
		local vb, vimg = vipCard("VIP", 1, VIPGOLD, {
			"+" .. math.floor(V.cash * 100 + 0.5) .. "% cash from everything",
			"+" .. math.floor(V.regen * 100 + 0.5) .. "% faster Influence regen",
			"<font color='#f0c75a'>[VIP]</font> chat tag",
		}, false)
		local mb, mimg = vipCard("MegaVIP", 2, PINK, {
			"+" .. math.floor(M.cash * 100 + 0.5) .. "% cash from everything",
			"+" .. math.floor(M.regen * 100 + 0.5) .. "% faster Influence regen",
			"LIMITED officer <b><font color='#ff9a2e'>Marshal Aurelio Vance</font></b>",
			"<font color='#ff4f8b'>[MEGA VIP]</font> chat tag",
		}, true)
		up(function(st)
			local gp = st.gp or {}
			mb:Set(gp.MegaVIP and true or false, "OWNED")
			if gp.MegaVIP and not gp.VIP then vb:Set(true, "MEGA VIP ACTIVE") else vb:Set(gp.VIP and true or false, "OWNED") end
			vimg.ImageTransparency = (gp.VIP or gp.MegaVIP) and 0.3 or 0
			mimg.ImageTransparency = gp.MegaVIP and 0.3 or 0
		end)
	end

	------------------------------------------------------------ 4. GAME PASSES
	local function passes()
		section("passes", "GAME PASSES", "Buy once, keep forever", "icon_ticket", C.manila)
		local g = grid(220, 262, 14, 3, 8)
		local k = 0
		for _, key in ipairs(Config.PassOrder) do
			if key ~= "VIP" and key ~= "MegaVIP" then
				local pass = Config.Passes[key]
				k += 1
				local t = tallCard(g, { order = k, art = PASS_ART[key] or "icon_sparkles", name = string.upper(pass.name), desc = pass.desc, glow = C.manila })
				local btn = ownButton(t.card, "green", "R$ " .. pass.price, function(b) buyPass(key, b) end, { sz = t.btnSz, pos = t.btnPos, anchor = Vector2.new(0.5, 1), z = 12, textSize = 17 })
				up(function(st)
					local owned = st.gp and st.gp[key]
					btn:Set(owned and true or false)
					markOwned(t, owned)
				end)
			end
		end
	end

	------------------------------------------------------------ 5. GOLD
	local function gold()
		section("gold", "GOLD", "Gold opens Founder's Crates, refills Influence and Supply, and skips waits", "icon_gold", C.gold)
		local base = Config.Products.GoldSmall
		local baseRate = base.gold / base.robux
		local g = grid(220, 252, 14, 3, 8)
		local packs = { { key = "GoldSmall", art = "shop_gold_small" }, { key = "GoldBig", art = "shop_gold_big" }, { key = "GoldHuge", art = "shop_gold_huge" } }
		for i, pk in ipairs(packs) do
			local p = Config.Products[pk.key]
			local bonus = math.floor(((p.gold / p.robux) / baseRate - 1) * 100 + 0.5)
			local best = i == #packs
			local t = tallCard(g, { order = i, art = pk.art, artH = 112, name = R.Commas(p.gold) .. " GOLD", nameColor = C.gold, desc = "", glow = C.gold,
				artGlow = C.gold, hot = best, baseGlow = best and 0.55 or 1, halo = best and { C.gold, Color3.fromHex("fff1b8") } or nil })
			t.name.FontFace = UI.Font.display
			t.name.TextSize = 24
			t.name.Size = UDim2.new(1, -20, 0, 28)
			if bonus > 0 then
				tag(t.card, "+" .. bonus .. "% BONUS VALUE", C.good, C.manilaInk, { pos = UDim2.new(0.5, 0, 0, 166), anchor = Vector2.new(0.5, 0), z = 12, h = 22, size = 12 })
			else
				text(t.card, "Starter pack", { size = 13, color = C.muted, align = Enum.TextXAlignment.Center, pos = UDim2.new(0, 10, 0, 166), sz = UDim2.new(1, -20, 0, 22), z = 12 })
			end
			if best then ribbon(t.card, "BEST VALUE", C.gold, C.manilaInk); shine(t.card, 3, 0.6) end
			UI.button(t.card, "green", "R$ " .. p.robux, function(b) buyProduct(pk.key, b) end, { sz = t.btnSz, pos = t.btnPos, anchor = Vector2.new(0.5, 1), z = 12, textSize = 17 })
		end
		-- gold spends
		local g2 = grid(320, 100, 14, 2, 8)
		local function spend(order, art, title, color, cost, action, okTitle, field, maxField)
			local _, card = liftCard(g2, { order = order, glow = color })
			UI.img(card, art, { sz = UDim2.fromOffset(76, 76), pos = UDim2.fromOffset(12, 12), slice = false, fit = true, z = 10 })
			text(card, title, { font = "heavy", size = 17, pos = UDim2.fromOffset(98, 14), sz = UDim2.new(1, -260, 0, 24), z = 10, truncate = true })
			local status = text(card, "", { size = 14, color = C.muted, pos = UDim2.fromOffset(98, 42), sz = UDim2.new(1, -260, 0, 20), z = 10, truncate = true })
			local bar = UI.bar(card, color, { pos = UDim2.fromOffset(98, 66), sz = UDim2.new(1, -260, 0, 16), z = 10, textSize = 11 })
			local b = UI.button(card, "gold", cost .. " GOLD", function(btn)
				local res = App.req(action, {}, btn)
				if res.ok then App.float(btn.Inst, "-" .. cost .. " gold", C.gold); App.toast(okTitle, nil, "gold") end
			end, { sz = UDim2.fromOffset(140, 46), pos = UDim2.new(1, -14, 0.5, 0), anchor = Vector2.new(1, 0.5), z = 11, icon = "icon_gold", textSize = 16 })
			up(function(st)
				local v, m = st[field] or 0, math.max(1, st[maxField] or 1)
				local full = v >= m
				status.Text = full and "Already full" or (v .. " / " .. m .. " · fills to max")
				bar:Set(v / m, "", "")
				b:Set((not full and (st.gold or 0) >= cost) and "gold" or "locked", full and "FULL" or (cost .. " GOLD"))
			end)
		end
		spend(1, "shop_influence", "REFILL INFLUENCE", C.inf, GOLD_INF, "goldInf", "INFLUENCE REFILLED", "inf", "infMax")
		spend(2, "shop_supply", "REFILL SUPPLY", C.sup, GOLD_SUP, "goldSup", "SUPPLY REFILLED", "sup", "supMax")
	end

	------------------------------------------------------------ 6. BOOSTS
	local function boosts()
		section("boosts", "BOOSTS", "Instant help, buy as often as you like", "icon_flame", C.inf)
		local g = grid(220, 272, 14, 3, 8)
		local P = Config.Products
		local finishMin, finishMax = math.huge, 0
		for _, k in ipairs({ "FinishConvoy1", "FinishConvoy2", "FinishConvoy3", "FinishConvoy4" }) do
			finishMin = math.min(finishMin, P[k].robux); finishMax = math.max(finishMax, P[k].robux)
		end
		local items = {
			{ key = "TreasuryGrant", art = "shop_treasury", name = "TREASURY GRANT", desc = "Instant cash: about 2 hours of your income", glow = C.good },
			{ key = "InfluenceRefill", art = "shop_influence", name = "INFLUENCE REFILL", desc = "Fill your Influence bar to max", glow = C.inf },
			{ key = "SupplyRefill", art = "shop_supply", name = "SUPPLY REFILL", desc = "Fill your Supply for raids, bosses and sieges", glow = C.sup },
			{ key = "RaidShield", art = "shop_shield", name = "RAID SHIELD (" .. P.RaidShield.hours .. "H)", desc = "Nobody can raid you for " .. P.RaidShield.hours .. " hours", glow = C.blue },
			{ key = "InstantArmy", art = "shop_army", name = "INSTANT ARMY", desc = "Fill your army to its cap with your best unit", glow = C.bad },
			{ key = "ChallengeRefresh", art = "shop_refresh", name = "CHALLENGE REFRESH", desc = "+1 refresh token: swap an order for a new one", glow = C.xp },
			{ key = "FinishConvoy", art = "shop_finish", name = "FINISH CONVOY", desc = "Land a travelling convoy instantly. Buy it from the convoy on the map", glow = C.manila,
				price = "R$ " .. finishMin .. "-" .. finishMax, ctx = "map", ctxLabel = "USE FROM CAPITOL" },
			{ key = "MoveCapital", art = "shop_capital", name = "MOVE CAPITAL", desc = "Move your capital to any city. Pick it on the CAPITOL map", glow = C.manila,
				price = "R$ " .. P.MoveCapital.robux, ctx = "map", ctxLabel = "USE FROM CAPITOL" },
			{ key = "RevengeStrike", art = "shop_revenge", name = "REVENGE STRIKE", desc = "Hit back at whoever raided you last. Buy it from RAIDS", glow = C.bad,
				price = "R$ " .. P.RevengeStrike.robux, ctx = "battle", ctxLabel = "USE FROM RAIDS" },
		}
		for i, it in ipairs(items) do
			local t = tallCard(g, { order = i, art = it.art, name = it.name, desc = it.desc, glow = it.glow, artGlow = it.glow, live = true })
			local live = mk("TextLabel", { BackgroundTransparency = 1, Text = "", FontFace = UI.Font.heavy, TextSize = 12, TextColor3 = it.glow, TextXAlignment = Enum.TextXAlignment.Center,
				Position = UDim2.new(0, 12, 1, -80), Size = UDim2.new(1, -24, 0, 16), ZIndex = 11, RichText = true, TextTruncate = Enum.TextTruncate.AtEnd }, t.card)
			if it.ctx then
				tag(t.card, it.price, DARK, ROBUX, { pos = UDim2.fromOffset(12, 12), z = 12, h = 22, size = 13, stroke = ROBUX })
				UI.button(t.card, "slate", it.ctxLabel, function() App.open(it.ctx) end, { sz = t.btnSz, pos = t.btnPos, anchor = Vector2.new(0.5, 1), z = 12, icon = "icon_right", textSize = 14 })
			else
				UI.button(t.card, "green", "R$ " .. P[it.key].robux, function(b) buyProduct(it.key, b) end, { sz = t.btnSz, pos = t.btnPos, anchor = Vector2.new(0.5, 1), z = 12, textSize = 17 })
			end
			if it.key == "TreasuryGrant" then
				up(function(st)
					local ok, amt = pcall(function() return math.floor(R.MinuteValue(st.lv) * 120 + (st.incHr or 0) * 2) end)
					live.Text = ok and ("Right now: +" .. R.Money(amt)) or ""
				end)
			elseif it.key == "RaidShield" then
				onTick(function(now)
					local sh = App.state and App.state.shield or 0
					live.Text = sh > now and ("SHIELD UP · " .. timeLeft(sh - now) .. " left") or ""
				end)
			elseif it.key == "ChallengeRefresh" then
				up(function(st)
					local n = st.refresh and st.refresh.tokens or 0
					live.Text = n > 0 and ("You have " .. n .. " token" .. (n > 1 and "s" or "")) or ""
				end)
			elseif it.key == "RevengeStrike" then
				up(function(st)
					live.Text = st.revenge and st.revenge.name and ("Target: " .. st.revenge.name) or "Nobody has raided you yet"
				end)
			end
		end
	end

	------------------------------------------------------------ build / refresh
	function obj:Build()
		UI.clear(list)
		obj.ups, obj.ticks, obj.anchors = {}, {}, {}
		order = 0
		obj.builtW = innerW()
		hero()
		supply()
		vip()
		passes()
		gold()
		boosts()
		local st = App.state
		if st and st.studio then
			local note = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 7, LayoutOrder = nextOrder() }, list)
			text(note, "Studio: every game pass is granted for testing (Config.StudioGrantsPasses). Set workspace attribute IC_NoPasses to test without them.",
				{ size = 13, color = C.dim, sz = UDim2.fromScale(1, 1), z = 8, wrap = true })
		end
		local foot = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), ZIndex = 7, LayoutOrder = nextOrder() }, list)
		text(foot, "Robux purchases are granted after Roblox confirms them. Crates bought with Robux wait in your Inventory.", { size = 12, color = C.dim, sz = UDim2.fromScale(1, 1), z = 8, wrap = true })
	end

	local function setSub(st)
		local g = st.gold or 0
		local function fmt(v)
			sub.Text = "<font color='#f0c75a'><b>" .. R.Commas(v) .. " gold</b></font>  ·  <font color='#8fd07a'><b>" .. R.Money(st.cash or 0) .. "</b></font>"
		end
		if obj.shownGold and obj.shownGold ~= g then
			local from = obj.shownGold
			local nv = mk("NumberValue", { Value = from }, sub)
			nv.Changed:Connect(function(v) fmt(math.floor(v + 0.5)) end)
			tw(nv, 0.6, { Value = g })
			task.delay(0.7, function() nv:Destroy(); if App.state then fmt(App.state.gold or 0) end end)
		else
			fmt(g)
		end
		obj.shownGold = g
	end

	function obj:Refresh(st)
		if not st then return end
		if obj.builtW ~= innerW() then obj:Build() end
		setSub(st)
		for _, fn in ipairs(obj.ups) do
			local ok, err = pcall(fn, st)
			if not ok then warn("[Shop] " .. tostring(err)) end
		end
		obj:Tick(st)
	end
	function obj:Tick(st)
		local now = App.now()
		for _, fn in ipairs(obj.ticks) do pcall(fn, now) end
		if st and obj.shownGold ~= (st.gold or 0) then setSub(st) end
	end
	function obj:Opened()
		list.CanvasPosition = Vector2.zero
	end
	App.on("resize", function()
		if obj.builtW and obj.builtW ~= innerW() and host.Visible and App.state then obj:Refresh(App.state) end
	end)
	App.shopScrollTo = scrollTo -- other screens can deep-link: App.open("shop"); App.shopScrollTo("gold")
	obj:Build()
	return obj
end }

---------------------------------------------------------------- VIP chat tags (TextChatService; legacy chat is skipped)
S._vipTags = { init = function(App)
	pcall(function()
		local TCS = game:GetService("TextChatService")
		if TCS.ChatVersion ~= Enum.ChatVersion.TextChatService then return end
		local COLORS = { ["VIP"] = Config.VIP.VIP.color, ["MEGA VIP"] = Config.VIP.MegaVIP.color }
		TCS.OnIncomingMessage = function(message)
			local props = Instance.new("TextChatMessageProperties")
			local okT = pcall(function()
				local src = message.TextSource
				local plr = src and Players:GetPlayerByUserId(src.UserId)
				local tier = plr and plr:GetAttribute("IC_Vip")
				local col = tier and COLORS[tier]
				if col then
					props.PrefixText = "<font color='#" .. col .. "'>[" .. tier .. "]</font> " .. (message.PrefixText or "")
				end
			end)
			if not okT then return nil end
			return props
		end
	end)
end }

return S
