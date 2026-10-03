-- Cabinet screens: OFFICERS (you, LIMITED slots, seated officers, gear slots, hiring, slots) and INVENTORY (gear,
-- officers, crates, elite troops). Layouts copied from the reference game's CREW and INVENTORY tabs (Kash 1 Oct 16:45).
-- NO BENCH (Kash 2 Oct): officers only join into an open slot; limited officers live in their own slots (cab.ltd).
-- Also owns the crate / hire REVEAL popup, exposed as App.crateReveal(App, result, opts) for other screens (Shop),
-- and the DROP RATES popup for every RNG box, exposed as App.dropRates(kind) with kind "limited" | "basic" | "hire".
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local O = require(Shared.Officers)
local M = require(Shared.Military)
local Config = require(Shared.Config)
local Assets = require(Shared.Assets)
local UI = require(script.Parent:WaitForChild("UI"))
local C = UI.C
local mk, text = UI.mk, UI.text

local S = {}
local OVERLAY = 0.45 -- ClientMain's modal backdrop transparency (restored after our darker reveal overlay)
local DARK = Color3.fromHex("121519")
local TILE = Color3.fromHex("1b1f25")
local LIMITED = Color3.fromHex("ff9a2e")

---------------------------------------------------------------- small helpers
local function tw(o, t, props, style, dir, rep)
	local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, rep or 0), props)
	x:Play()
	return x
end
local function corner(g, r) return mk("UICorner", { CornerRadius = typeof(r) == "UDim" and r or UDim.new(0, r or 6) }, g) end
local function stroke(g, color, th, alpha)
	return mk("UIStroke", { Color = color, Thickness = th or 2, Transparency = alpha or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, g)
end
local function hoverScale(g, amount)
	local sc = g:FindFirstChildOfClass("UIScale") or mk("UIScale", {}, g)
	g.MouseEnter:Connect(function() tw(sc, 0.12, { Scale = 1 + (amount or 0.03) }, Enum.EasingStyle.Back) end)
	g.MouseLeave:Connect(function() tw(sc, 0.12, { Scale = 1 }) end)
	return sc
end
local function hoverBtn(btn) -- UI.button already owns a UIScale for the press; reuse it for a hover lift
	local sc = btn.Inst:FindFirstChildOfClass("UIScale")
	if not sc then return end
	btn.Inst.MouseEnter:Connect(function() tw(sc, 0.12, { Scale = 1.04 }, Enum.EasingStyle.Back) end)
	btn.Inst.MouseLeave:Connect(function() tw(sc, 0.12, { Scale = 1 }) end)
end

-- re-anchor a GuiObject on its centre without moving it, so a UIScale grows it from the middle (Kash 18:41)
local function centre(g)
	local a = g.AnchorPoint
	if a.X == 0.5 and a.Y == 0.5 then return g end
	local p, sz = g.Position, g.Size
	g.AnchorPoint = Vector2.new(0.5, 0.5)
	g.Position = UDim2.new(p.X.Scale + sz.X.Scale * (0.5 - a.X), p.X.Offset + sz.X.Offset * (0.5 - a.X), p.Y.Scale + sz.Y.Scale * (0.5 - a.Y), p.Y.Offset + sz.Y.Offset * (0.5 - a.Y))
	return g
end
-- fade a whole tree in from fully transparent to the values it was built with
local function fadeIn(root, t)
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
			tw(d, t, props)
		end
	end
end
-- pop in from the centre ("from far away towards me"): UIScale from ~0.6 to 1 with Back easing, plus a fade
local function popIn(g, from, t, noFade)
	centre(g)
	local sc = g:FindFirstChildOfClass("UIScale") or mk("UIScale", {}, g)
	sc.Scale = from or 0.6
	tw(sc, t or 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
	-- deferred so the content the caller builds right after this call fades in with the panel
	if not noFade then task.defer(fadeIn, g, math.min(0.2, (t or 0.32) * 0.7)) end
	return sc
end
local function spin(o, degPerSec)
	o.Rotation = (os.clock() * degPerSec) % 360 -- phase from the clock, so a rebuilt card does not jump
	local goal = o.Rotation + (degPerSec >= 0 and 360 or -360)
	tw(o, 360 / math.abs(degPerSec), { Rotation = goal }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
end

local function rar(key) return O.RarityByKey[key or "common"] or O.Rarities[1] end
local function rcol(key) return Color3.fromHex(rar(key).color) end
local function ridx(key) return rar(key).index or 1 end
local SHORT = { law = "law cash", props = "property income", convoy = "convoy pay", xp = "XP", attack = "attack", defense = "defense",
	loot = "raid loot", losses = "fewer deaths", interest = "bank interest", regen = "Influence regen", siege = "siege damage", boss = "boss damage" }
local function traitLine(t) return "+" .. tostring(t.v) .. "% " .. (SHORT[t.k] or (O.TraitByKey[t.k] and O.TraitByKey[t.k].name) or tostring(t.k)) end
local function gearMain(g) return "+" .. tostring(g.power or 0) .. "% " .. (g.kind == "weapon" and "attack" or "defense") end
local function gearStat(g) return gearMain(g) .. (g.perk and ("  " .. traitLine(g.perk)) or "") end
-- v is already a percent; up to 4 decimals so tiny odds (0.0375%) are shown exactly, never rounded to 0
local function pct(v)
	if not v or v <= 0 then return "-" end
	local s = string.format("%.4f", v)
	s = (s:gsub("0+$", ""))
	s = (s:gsub("%.$", ""))
	return s .. "%"
end
local function painted(o) return o and ((o.img and Assets[o.img]) or (o.portrait == 0 and Assets.officer_founder)) and true or false end
local function tintFor(o, rc) if painted(o) then return Color3.new(1, 1, 1) end return rc end
local function portraitKey(o)
	if o and o.img and Assets[o.img] then return o.img end
	local n = o and o.portrait or 1
	if n == 0 then return Assets.officer_founder and "officer_founder" or "officer_1" end
	return "officer_" .. math.clamp(n, 1, O.Portraits)
end
local function invOf(st)
	local inv = st and st.inv or {}
	return { gear = inv.gear or {}, officers = inv.officers or {} }
end
local function cabOf(st)
	local cab = st and st.cab or {}
	return { slots = cab.slots or {}, player = cab.player or {}, bought = cab.bought or 0, ltd = cab.ltd or {} }
end
local function slotsOf(st) return (st and st.officerSlots) or Config.Officers.StartSlots end
-- gear id -> { id = holderId, name = holderName }
local function wearers(st)
	local m = {}
	local cab, inv = cabOf(st), invOf(st)
	for _, k in ipairs({ "weapon", "armor" }) do
		if cab.player[k] then m[cab.player[k]] = { id = "player", name = "You" } end
	end
	for id, o in pairs(inv.officers) do
		for _, k in ipairs({ "weapon", "armor" }) do
			if o[k] then m[o[k]] = { id = id, name = o.name } end
		end
	end
	return m
end
-- officer id -> slot index (seated only)
local function seatedMap(st)
	local m = {}
	local cab = cabOf(st)
	for i = 1, slotsOf(st) do
		local id = cab.slots[i]
		if id and invOf(st).officers[id] then m[id] = i end
	end
	return m
end
-- limited officers in their exclusive slots, in slot order
local function ltdList(st)
	local out = {}
	local inv = invOf(st)
	for _, id in ipairs(cabOf(st).ltd) do
		if inv.officers[id] then table.insert(out, inv.officers[id]) end
	end
	return out
end
local function ltdSet(st)
	local m = {}
	for _, o in ipairs(ltdList(st)) do m[o.id] = true end
	return m
end
local function freeSlots(st)
	local cab, inv = cabOf(st), invOf(st)
	local n = 0
	for i = 1, slotsOf(st) do if not (cab.slots[i] and inv.officers[cab.slots[i]]) then n += 1 end end
	return n
end
local function gearSorted(st, kind)
	local out = {}
	for _, g in pairs(invOf(st).gear) do if not kind or g.kind == kind then table.insert(out, g) end end
	table.sort(out, function(a, b)
		if (a.power or 0) ~= (b.power or 0) then return (a.power or 0) > (b.power or 0) end
		local ra, rb = ridx(a.rarity), ridx(b.rarity)
		if ra ~= rb then return ra > rb end
		local pa, pb = a.perk and a.perk.v or 0, b.perk and b.perk.v or 0
		if pa ~= pb then return pa > pb end
		return (a.name or "") < (b.name or "")
	end)
	return out
end
local function bonuses(st)
	local cab, inv = cabOf(st), invOf(st)
	return O.Bonuses({ slots = cab.slots, player = cab.player, ltd = cab.ltd }, inv, slotsOf(st))
end

-- count a label up from its last value (stat boxes)
local function countTo(label, from, to, fmt)
	if from == to then label.Text = fmt(to); return end
	local nv = mk("NumberValue", { Value = from }, label)
	nv.Changed:Connect(function(v) label.Text = fmt(v) end)
	tw(nv, 0.6, { Value = to })
	task.delay(0.7, function() nv:Destroy(); if label.Parent then label.Text = fmt(to) end end)
end

---------------------------------------------------------------- popups (inside App.modalHost)
local function popup(App, title, w, h)
	local mh = App.modalHost
	UI.clear(mh)
	mh.BackgroundTransparency = OVERLAY
	mh.Visible = true
	w = math.min(w, App.W() - 24)
	h = math.min(h, App.H() - 24)
	local panel, body = UI.panel(mh, title, { sz = UDim2.fromOffset(w, h), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71 })
	popIn(panel, 0.6, 0.3)
	local function close() mh.Visible = false; mh.BackgroundTransparency = OVERLAY end
	local x = UI.img(panel, "icon_x", { button = true, name = "Close", sz = UDim2.fromOffset(22, 22), pos = UDim2.new(1, -16, 0, 16), anchor = Vector2.new(1, 0), color = C.muted, slice = false, z = 76 })
	x.MouseEnter:Connect(function() x.ImageColor3 = C.ink end)
	x.MouseLeave:Connect(function() x.ImageColor3 = C.muted end)
	x.Activated:Connect(close)
	return panel, body, close
end

-- the small "i" button: tap to open a short explanation (Kash Q3: details behind an i icon)
local function infoBtn(App, parent, title, body, pos, z)
	local b = mk("TextButton", { Name = "Info", Text = "i", FontFace = UI.Font.heavy, TextSize = 14, TextColor3 = C.manila, BackgroundColor3 = C.slate,
		AutoButtonColor = false, Size = UDim2.fromOffset(20, 20), Position = pos, ZIndex = z or 8 }, parent)
	corner(b, UDim.new(1, 0))
	stroke(b, C.manila, 1.4)
	hoverScale(b, 0.15)
	b.Activated:Connect(function()
		local _, bd, close = popup(App, title, 440, 250)
		text(bd, body, { size = 16, wrap = true, rich = true, sz = UDim2.new(1, 0, 1, -54), valign = Enum.TextYAlignment.Top, z = 74 })
		UI.button(bd, "slate", "GOT IT", close, { sz = UDim2.fromOffset(150, 42), pos = UDim2.new(0.5, 0, 1, -4), anchor = Vector2.new(0.5, 1), z = 74 })
	end)
	return b
end

---------------------------------------------------------------- DROP RATES (every RNG box, Kash 2 Oct 21:15)
-- Built from the same tables the server rolls with (O.CrateInfo, O.HireOdds) and the same luck rule as O.Roll
-- (2x Crate Luck doubles Legendary and up, then everything is renormalised), so the numbers always match.
local function weights(odds, luck)
	local w = table.clone(odds or {})
	if luck then for i = 5, #w do w[i] *= 2 end end
	local tot = 0
	for _, v in ipairs(w) do tot += v end
	if tot > 0 then for i, v in ipairs(w) do w[i] = v / tot end end
	return w -- fractions that sum to 1
end
-- columns = { { name, share (percent of all drops) or nil, vals = { [rarity index] = percent of ALL drops }, extra = { [i] = "x4" } } }
local function dropColumns(kind, st)
	local luck = (st and st.gp and st.gp.CrateLuck) and true or false
	local cols, notes = {}, {}
	if kind == "hire" then
		for _, t in ipairs(Config.Officers.Hire) do
			local w = weights(O.HireOdds[t.key], luck)
			local vals = {}
			for i = 1, O.RollTiers do vals[i] = (w[i] or 0) * 100 end
			table.insert(cols, { name = t.name, sub = R.Money(t.cost), vals = vals })
		end
		table.insert(notes, "Each hire gives one officer with random traits.")
	else
		for _, e in ipairs(O.CrateInfo[kind] or {}) do
			local w = weights(e.odds, luck)
			local troops = string.find(string.lower(e.label), "troop") ~= nil
			local vals, extra = {}, troops and {} or nil
			for i = 1, O.RollTiers do
				vals[i] = e.pct * (w[i] or 0)
				if extra then extra[i] = "x" .. tostring(O.EliteSize[i] or 0) end
			end
			table.insert(cols, { name = e.label, sub = pct(e.pct) .. " of drops", vals = vals, extra = extra, color = troops and C.gold or nil })
		end
		local pv = (st and st.pity and st.pity[kind]) or 0
		table.insert(notes, "<font color='#e9b949'><b>PITY " .. pv .. " / " .. (O.Pity[kind] or 50) .. ":</b></font> the crate that fills the meter is guaranteed <b>Legendary or better</b>.")
		if kind == "limited" then
			table.insert(notes, "<b>Elite troops</b> are your era's elite unit (pack size by rarity) and <font color='#f0c75a'><b>never die in raids</b></font>.")
			table.insert(notes, "A <b>10-pack</b> guarantees Epic or better: if nothing Epic+ dropped, the last crate is upgraded to Epic.")
		else
			if st and freeSlots(st) == 0 then
				table.insert(notes, "<font color='#e2695f'><b>Every slot is full right now: this crate gives gear only.</b></font>")
			end
		end
	end
	table.insert(notes, luck and "<font color='#f0c75a'><b>2x CRATE LUCK ACTIVE:</b></font> Legendary and up doubled (included above)."
		or "The <b>2x Crate Luck</b> pass doubles Legendary and up.")
	return cols, notes, luck
end

local function dropRates(App, kind)
	local st = App.state
	local cols, notes, luck = dropColumns(kind, st)
	local name = kind == "hire" and "HIRING" or (kind == "basic" and Config.Crates.Basic.name or Config.Crates.Limited.name)
	local rowH, headH = 26, 54
	local tableH = headH + rowH * (O.RollTiers + 1)
	local footH = luck and 52 or 106
	local _, bd, close = popup(App, name .. " · DROP RATES", 700, 48 + 12 + tableH + 22 * #notes + 20 + footH)
	local area = UI.list(bd, { sz = UDim2.new(1, 0, 1, -footH), gap = 6, z = 74 })
	local tbl = mk("Frame", { Name = "Rates", BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, tableH), ZIndex = 74, LayoutOrder = 1 }, area)
	local rw = #cols > 2 and 0.22 or 0.28
	local cw = (1 - rw) / math.max(1, #cols)
	text(tbl, "RARITY", { font = "heavy", size = 13, color = C.muted, valign = Enum.TextYAlignment.Bottom, pos = UDim2.fromOffset(8, 0), sz = UDim2.new(rw, -8, 0, headH - 6), z = 75 })
	for c, col in ipairs(cols) do
		local x = rw + (c - 1) * cw
		text(tbl, string.upper(col.name), { font = "heavy", size = 13, color = col.color or C.manila, align = Enum.TextXAlignment.Center, wrap = true, scaled = true,
			pos = UDim2.new(x, 4, 0, 0), sz = UDim2.new(cw, -8, 0, headH - 22), z = 75 })
		if col.sub then
			text(tbl, col.sub, { font = "bold", size = 12, color = C.muted, align = Enum.TextXAlignment.Center, pos = UDim2.new(x, 4, 0, headH - 22), sz = UDim2.new(cw, -8, 0, 16), z = 75, truncate = true })
		end
	end
	local totals = {}
	for i = 1, O.RollTiers + 1 do
		local y = headH + (i - 1) * rowH
		local band = mk("Frame", { BackgroundColor3 = i % 2 == 1 and C.slate or DARK, BackgroundTransparency = i <= O.RollTiers and 0.35 or 0, BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, rowH), ZIndex = 74 }, tbl)
		corner(band, 4)
		if i <= O.RollTiers then
			local r = O.Rarities[i]
			text(band, r.name, { font = "heavy", size = 15, color = Color3.fromHex(r.color), pos = UDim2.fromOffset(8, 0), sz = UDim2.new(rw, -8, 1, 0), z = 75, stroke = 1 })
			for c, col in ipairs(cols) do
				local v = col.vals[i] or 0
				totals[c] = (totals[c] or 0) + v
				local s = pct(v)
				if v > 0 and col.extra then s = s .. "  <font color='#9a9fa6'>" .. col.extra[i] .. "</font>" end
				text(band, s, { font = "heavy", size = 15, color = v > 0 and C.ink or C.dim, align = Enum.TextXAlignment.Center, rich = true,
					pos = UDim2.new(rw + (c - 1) * cw, 0, 0, 0), sz = UDim2.new(cw, 0, 1, 0), z = 75 })
			end
		else
			stroke(band, C.rule, 1)
			text(band, "TOTAL", { font = "heavy", size = 14, color = C.manila, pos = UDim2.fromOffset(8, 0), sz = UDim2.new(rw, -8, 1, 0), z = 75 })
			for c in ipairs(cols) do
				text(band, pct(totals[c] or 0), { font = "heavy", size = 15, color = C.manila, align = Enum.TextXAlignment.Center,
					pos = UDim2.new(rw + (c - 1) * cw, 0, 0, 0), sz = UDim2.new(cw, 0, 1, 0), z = 75 })
			end
		end
	end
	for k, n in ipairs(notes) do
		local l = text(area, n, { size = 14, color = C.ink, wrap = true, rich = true, sz = UDim2.new(1, -8, 0, 0), z = 75, order = 1 + k })
		l.AutomaticSize = Enum.AutomaticSize.Y
	end
	if not luck then
		local pass = Config.Passes and Config.Passes.CrateLuck
		local lb = UI.button(bd, "gold", "Increase your luck!" .. (pass and ("  R$" .. pass.price) or ""), function(b) App.req("buyPass", { key = "CrateLuck" }, b) end,
			{ pos = UDim2.new(0.5, 0, 1, -54), anchor = Vector2.new(0.5, 1), sz = UDim2.fromOffset(340, 44), z = 74, icon = "icon_sparkles", textSize = 18 })
		hoverBtn(lb)
	end
	UI.button(bd, "slate", "CLOSE", close, { pos = UDim2.new(0.5, 0, 1, -2), anchor = Vector2.new(0.5, 1), sz = UDim2.fromOffset(200, 44), z = 74 })
end
-- a compact "DROP RATES" button that opens the popup for kind
local function ratesBtn(App, parent, kind, p)
	p = p or {}
	local b = UI.button(parent, "slate", p.label or "DROP RATES", function() dropRates(App, kind) end,
		{ pos = p.pos, anchor = p.anchor, sz = p.sz or UDim2.fromOffset(150, 30), z = p.z or 8, textSize = p.textSize or 14, icon = p.icon ~= false and "icon_gauge" or nil, order = p.order })
	hoverBtn(b)
	return b
end

---------------------------------------------------------------- visuals: aura, portrait, gear image
-- the classic game-pass ROTATING BEAMS (Kash 18:41): two counter-rotating sunburst layers tinted in the rarity colour,
-- over a subtle soft glow. size is the full diameter (~1.6-2x the item).
local function aura(parent, color, size, pos, z, strength)
	strength = math.clamp(strength or 1, 0, 1)
	local root = mk("Frame", { Name = "Beams", BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Position = pos or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z or 2 }, parent)
	local mid = UDim2.fromScale(0.5, 0.5)
	local half = Vector2.new(0.5, 0.5)
	UI.img(root, "glow_soft", { color = color, alpha = 1 - 0.45 * strength, slice = false, z = root.ZIndex, anchor = half, pos = mid, sz = UDim2.fromScale(0.62, 0.62) })
	local back = UI.img(root, "beams", { color = color, alpha = 1 - 0.55 * strength, slice = false, z = root.ZIndex, anchor = half, pos = mid, sz = UDim2.fromScale(1, 1) })
	local front = UI.img(root, "beams_wide", { color = color:Lerp(C.white, 0.3), alpha = 1 - 0.4 * strength, slice = false, z = root.ZIndex, anchor = half, pos = mid, sz = UDim2.fromScale(0.78, 0.78) })
	spin(back, 22)
	spin(front, -34)
	return root
end
-- soft static glow only (cards in grids): the soft radial glow art, no rings
local function glow(parent, color, size, z, strength)
	return UI.img(parent, "glow_soft", { name = "Glow", color = color, alpha = 1 - 0.6 * (strength or 1), slice = false, z = z,
		anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromScale(0.5, 0.5), sz = UDim2.fromScale(size, size) })
end

local headshot -- the local player's avatar headshot (fetched once)
local function avatarInto(img)
	if headshot then img.Image = headshot; return end
	task.spawn(function()
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and url then headshot = url; if img.Parent then img.Image = url end end
	end)
end

-- dark tile with the officer silhouette tinted in rarity color
local function portrait(parent, o, size, pos, z, p)
	p = p or {}
	local rc = rcol(o.rarity)
	local tile = mk("Frame", { Name = "Portrait", BackgroundColor3 = DARK, BorderSizePixel = 0, Size = UDim2.fromOffset(size, size), Position = pos or UDim2.new(),
		AnchorPoint = p.anchor or Vector2.zero, ZIndex = z, ClipsDescendants = true, LayoutOrder = p.order or 0 }, parent)
	corner(tile, 6)
	stroke(tile, rc, p.thick or 2)
	local wash = mk("Frame", { BackgroundColor3 = rc, BackgroundTransparency = 0.55, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = z }, tile)
	corner(wash, 6)
	mk("UIGradient", { Rotation = -90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.7, 1), NumberSequenceKeypoint.new(1, 1) }) }, wash)
	UI.img(tile, portraitKey(o), { sz = UDim2.fromScale(0.92, 0.92), pos = UDim2.fromScale(0.5, 1), anchor = Vector2.new(0.5, 1), color = tintFor(o, rc), z = z + 1, slice = false, fit = true })
	return tile
end
local function playerPortrait(parent, size, pos, z)
	local tile = mk("Frame", { Name = "Portrait", BackgroundColor3 = DARK, BorderSizePixel = 0, Size = UDim2.fromOffset(size, size), Position = pos, ZIndex = z, ClipsDescendants = true }, parent)
	corner(tile, 6)
	stroke(tile, C.gold, 2)
	local img = mk("ImageLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z + 1, ScaleType = Enum.ScaleType.Crop, Image = "" }, tile)
	corner(img, 6)
	avatarInto(img)
	return tile
end
local function gearImage(parent, g, sz, pos, z, anchor)
	return UI.img(parent, g.icon or (g.kind == "weapon" and "gear_sword" or "gear_helm"), { sz = sz, pos = pos, anchor = anchor, z = z, slice = false, fit = true })
end

---------------------------------------------------------------- shared officer actions
local function fireOfficer(App, o, btn)
	if o.limited then
		App.toast("LIMITED OFFICERS STAY", "They have their own slot and can't be fired", "bad")
		if btn and btn.Inst then App.shake(btn.Inst) end
		return
	end
	local body = "Fire <b>" .. o.name .. "</b>? You get <b>nothing</b> back. Their gear returns to your inventory and their slot opens up for a new hire."
	App.confirm("FIRE OFFICER?", body, "FIRE", "red", function()
		local res = App.req("fire", { id = o.id }, btn)
		if res.ok then App.toast(string.upper(o.name) .. " FIRED", "Their slot is free: hire someone new", "bad") end
	end)
end

-- gear picker for one holder slot: owned gear of that kind, sorted by power, with EQUIP buttons
local function openPicker(App, holderId, holderName, slot)
	local st = App.state
	local inv, cab = invOf(st), cabOf(st)
	local holder = holderId == "player" and cab.player or inv.officers[holderId]
	if not holder then return end
	local cur = holder[slot]
	local items = gearSorted(st, slot)
	local wm = wearers(st)
	local _, bd, close = popup(App, "EQUIP " .. string.upper(slot) .. " · " .. string.upper(holderName), 600, 500)
	local lst = UI.list(bd, { sz = UDim2.new(1, 0, 1, -56), gap = 6, z = 74 })
	if #items == 0 then
		text(lst, "You have no " .. (slot == "weapon" and "weapons" or "armor") .. " yet. Open crates in the Inventory to find some.", { size = 16, color = C.muted, wrap = true, sz = UDim2.new(1, 0, 0, 48), z = 75 })
	end
	for i, g in ipairs(items) do
		local rc = rcol(g.rarity)
		local row = UI.card(lst, { sz = UDim2.new(1, 0, 0, 66), z = 75, order = i, hot = g.id == cur })
		stroke(row, rc, g.id == cur and 2 or 1, g.id == cur and 0 or 0.4)
		local well = mk("Frame", { BackgroundColor3 = DARK, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 7), Size = UDim2.fromOffset(52, 52), ZIndex = 76 }, row)
		corner(well, 6)
		gearImage(well, g, UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.5, 0.5), 77, Vector2.new(0.5, 0.5))
		text(row, g.name, { font = "heavy", size = 16, color = rc, pos = UDim2.fromOffset(70, 6), sz = UDim2.new(1, -210, 0, 20), z = 76, truncate = true })
		text(row, rar(g.rarity).name .. "  " .. gearStat(g), { font = "bold", size = 13, color = C.good, pos = UDim2.fromOffset(70, 26), sz = UDim2.new(1, -210, 0, 18), z = 76, truncate = true })
		local w = wm[g.id]
		text(row, w and ("Worn by " .. w.name) or "In inventory", { size = 12, color = C.muted, pos = UDim2.fromOffset(70, 44), sz = UDim2.new(1, -210, 0, 16), z = 76, truncate = true })
		if g.id == cur then
			UI.button(row, "slate", "UNEQUIP", function(b)
				local res = App.req("unequip", { holder = holderId, slot = slot }, b)
				if res.ok then close() end
			end, { pos = UDim2.new(1, -10, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(120, 40), z = 77, textSize = 15 })
		else
			local eb = UI.button(row, "green", "EQUIP", function(b)
				local res = App.req("equip", { gear = g.id, holder = holderId }, b)
				if res.ok then close(); App.toast("EQUIPPED", g.name .. " on " .. holderName, "good") end
			end, { pos = UDim2.new(1, -10, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(120, 40), z = 77, textSize = 15 })
			hoverBtn(eb)
		end
	end
	UI.button(bd, "slate", "CLOSE", close, { pos = UDim2.new(0, 0, 1, -2), anchor = Vector2.new(0, 1), sz = UDim2.fromOffset(140, 44), z = 74 })
	UI.button(bd, "manila", "INVENTORY", function() close(); App.open("inventory") end, { pos = UDim2.new(1, 0, 1, -2), anchor = Vector2.new(1, 1), sz = UDim2.fromOffset(160, 44), z = 74, icon = "icon_boxes" })
end

---------------------------------------------------------------- REVEAL (crates and hires)
-- one result card: { type = "gear"|"officer"|"troops", item, where = "slot"|"limited", lost = bool }
-- troops item (Founder's Crate): { era, n, rarity, name } -> M.Elite[era] has the unit's name / atk / def
local function resultCard(parent, r, w, h, z)
	local item = r.item or {}
	local rc = rcol(item.rarity)
	local card = mk("Frame", { Name = "Result", BackgroundColor3 = TILE, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = z }, parent)
	corner(card, 10)
	stroke(card, rc, 3)
	local band = mk("Frame", { BackgroundColor3 = rc, BackgroundTransparency = 0.5, BorderSizePixel = 0, Size = UDim2.fromScale(1, 0.55), ZIndex = z }, card)
	corner(band, 10)
	mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }) }, band)
	local fs = math.max(11, math.floor(h * 0.06))
	text(card, rar(item.rarity).name, { font = "heavy", size = fs + 2, color = rc, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(6, 6), sz = UDim2.new(1, -12, 0, fs + 6), z = z + 2, stroke = 1.2, scaled = true })
	local imgH = math.floor(h * 0.42)
	local unit = r.type == "troops" and (M.Elite[tonumber(item.era) or 1] or M.Elite[1]) or nil
	if r.type == "officer" then
		portrait(card, item, imgH, UDim2.new(0.5, 0, 0, fs + 14), z + 1, { anchor = Vector2.new(0.5, 0), thick = 2 })
	elseif unit then
		-- elite troops: a gold-framed tile with the military crest and the pack size
		local tile = mk("Frame", { Name = "Elite", BackgroundColor3 = DARK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, fs + 14),
			Size = UDim2.fromOffset(imgH, imgH), ZIndex = z + 1, ClipsDescendants = true }, card)
		corner(tile, 8)
		stroke(tile, C.gold, 2)
		local wash = mk("Frame", { BackgroundColor3 = rc, BackgroundTransparency = 0.45, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = z + 1 }, tile)
		mk("UIGradient", { Rotation = -90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.8, 1), NumberSequenceKeypoint.new(1, 1) }) }, wash)
		UI.img(tile, "icon_military", { sz = UDim2.fromScale(0.6, 0.6), pos = UDim2.fromScale(0.5, 0.56), anchor = Vector2.new(0.5, 0.5), color = rc:Lerp(C.white, 0.35), z = z + 2, slice = false, fit = true })
		UI.icon(tile, unit.icon or "icon_crown", math.floor(imgH * 0.24), C.gold, UDim2.new(0.5, 0, 0, 4), { z = z + 3, anchor = Vector2.new(0.5, 0) })
		text(tile, "x" .. tostring(item.n or 0), { font = "heavy", size = math.max(14, math.floor(imgH * 0.22)), color = C.white, align = Enum.TextXAlignment.Right,
			anchor = Vector2.new(1, 1), pos = UDim2.new(1, -6, 1, -2), sz = UDim2.new(1, -8, 0, math.max(16, math.floor(imgH * 0.26))), z = z + 3, stroke = 1.6 })
	else
		gearImage(card, item, UDim2.fromOffset(imgH, imgH), UDim2.new(0.5, 0, 0, fs + 14), z + 1, Vector2.new(0.5, 0))
	end
	local y = fs + 18 + imgH
	local title = unit and (tostring(item.n or 0) .. "x " .. (item.name or unit.name)) or (item.name or "?")
	text(card, title, { font = "heavy", size = fs + 1, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(6, y), sz = UDim2.new(1, -12, 0, (fs + 2) * 2), z = z + 2, wrap = true, scaled = true })
	y += (fs + 2) * 2 + 2
	local lines
	if r.type == "officer" then
		local t = {}
		for k, tr in ipairs(item.traits or {}) do if k <= 4 then table.insert(t, traitLine(tr)) end end
		lines = (item.title and (item.title .. "\n") or "") .. table.concat(t, "\n")
	elseif unit then
		lines = "ELITE TROOPS\nATK " .. R.Short(unit.atk) .. "  DEF " .. R.Short(unit.def) .. " each\nElite troops never die in raids"
	else
		lines = (item.kind == "weapon" and "WEAPON" or "ARMOR") .. "\n" .. gearMain(item) .. (item.perk and ("\n" .. traitLine(item.perk)) or "")
	end
	local footH = fs + 8
	text(card, lines, { font = "bold", size = fs - 1, color = C.good, align = Enum.TextXAlignment.Center, valign = Enum.TextYAlignment.Top, pos = UDim2.fromOffset(6, y), sz = UDim2.new(1, -12, 1, -(y + footH + 6)), z = z + 2, wrap = true, scaled = true })
	local note
	if r.lost then note = "INVENTORY FULL · LOST"
	elseif r.type == "officer" then note = r.where == "limited" and "LIMITED SLOT" or "JOINED YOUR CABINET"
	elseif unit then note = "JOINED YOUR ARMY"
	else note = "ADDED TO INVENTORY" end
	local foot = mk("Frame", { BackgroundColor3 = rc, BorderSizePixel = 0, Position = UDim2.new(0, 6, 1, -(footH + 6)), Size = UDim2.new(1, -12, 0, footH), ZIndex = z + 1 }, card)
	corner(foot, 4)
	text(foot, note, { font = "heavy", size = fs - 1, color = r.lost and C.white or C.black, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = z + 2, scaled = true })
	if r.lost then foot.BackgroundColor3 = C.bad end
	return card
end

local revealToken = 0
-- result = { results = {...}, kind = "basic"|"limited" }; opts = { noCrate, title, again = fn }
local function reveal(App, result, opts)
	opts = opts or {}
	local results = result and result.results or {}
	if #results == 0 then return end
	revealToken += 1
	local token = revealToken
	local mh = App.modalHost
	UI.clear(mh)
	mh.Visible = true
	mh.BackgroundTransparency = 0.1
	local W, H = App.W(), App.H()
	local stage = mk("TextButton", { Name = "Reveal", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 71 }, mh)
	local skip = false
	stage.Activated:Connect(function() skip = true end)
	local function alive() return token == revealToken and stage.Parent ~= nil end
	local function pause(t)
		local e = 0
		while e < t and not skip and alive() do e += task.wait() end
	end
	local function close()
		if token == revealToken then mh.Visible = false; mh.BackgroundTransparency = OVERLAY; UI.clear(mh) end
	end
	local best, bestIdx = results[1].item, 0
	for _, r in ipairs(results) do
		local i = ridx(r.item and r.item.rarity)
		if i > bestIdx then bestIdx, best = i, r.item end
	end
	local bestColor = rcol(best and best.rarity)
	local crateName = result.kind == "basic" and Config.Crates.Basic.name or Config.Crates.Limited.name
	local title = text(stage, opts.title or crateName, { font = "display", size = 32, color = C.manila, align = Enum.TextXAlignment.Center, pos = UDim2.new(0, 0, 0, 18), sz = UDim2.new(1, 0, 0, 40), z = 80, stroke = 1.5 })
	local hint = text(stage, "Tap to skip", { size = 13, color = C.dim, align = Enum.TextXAlignment.Center, pos = UDim2.new(0, 0, 1, -26), sz = UDim2.new(1, 0, 0, 18), z = 80 })

	task.spawn(function()
		------------------------------------------------ the crate: drop in, shake harder and harder, flash
		if not opts.noCrate then
			local size = math.min(260, H * 0.45)
			local holder = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromOffset(size, size), ZIndex = 75 }, stage)
			local g = aura(stage, bestIdx >= 4 and bestColor or C.manila, size * 1.9, UDim2.fromScale(0.5, 0.52), 74, bestIdx >= 4 and 0.9 or 0.6)
			local gs = mk("UIScale", { Scale = 0.4 }, g)
			local img = UI.img(holder, result.kind == "basic" and "crate_basic" or "crate_limited", { sz = UDim2.fromScale(1, 1), slice = false, fit = true, z = 76 })
			local sc = popIn(holder, 0.2, 0.4)
			if App.sfx then App.sfx("crate_shake") end
			pause(0.45)
			tw(gs, 1.2, { Scale = 1.1 })
			for i = 1, 16 do
				if skip or not alive() then break end
				local a = (i % 2 == 0 and 1 or -1) * (2 + i * 0.55)
				img.Rotation = a
				holder.Position = UDim2.new(0.5, math.random(-i, i) * 0.4, 0.52, math.random(-i, i) * 0.25)
				sc.Scale = 1 + i * 0.012
				pause(0.075 - i * 0.002)
			end
			if not alive() then return end
			local flash = mk("Frame", { BackgroundColor3 = bestIdx >= 4 and bestColor:Lerp(C.white, 0.5) or C.white, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 95 }, stage)
			tw(flash, 0.12, { BackgroundTransparency = 0 })
			if App.sfx then App.sfx("crate_open") end
			task.wait(0.13)
			holder:Destroy(); g:Destroy()
			tw(flash, 0.5, { BackgroundTransparency = 1 })
			task.delay(0.55, function() flash:Destroy() end)
		end
		if not alive() then return end
		if bestIdx >= 5 then
			title.Text = rar(best.rarity).name .. " PULL!"
			title.TextColor3 = bestColor
			centre(title)
			local ts = mk("UIScale", { Scale = 1.4 }, title)
			tw(ts, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
		end
		------------------------------------------------ the results, one after another
		local n = #results
		local rows = n > 5 and 2 or 1
		local perRow = math.ceil(n / rows)
		local gap = 16
		local cw = math.min(n == 1 and 250 or 190, math.floor((W - 60) / perRow) - gap)
		local ch = math.floor(cw * 1.38)
		local availH = H - 170
		if ch * rows + gap * (rows - 1) > availH then
			ch = math.floor((availH - gap * (rows - 1)) / rows)
			cw = math.floor(ch / 1.38)
		end
		local gridW, gridH = perRow * (cw + gap) - gap, rows * (ch + gap) - gap
		local grid = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 4), Size = UDim2.fromOffset(gridW, gridH), ZIndex = 76 }, stage)
		for k, r in ipairs(results) do
			if not alive() then return end
			local row = (k - 1) // perRow
			local col = (k - 1) % perRow
			local inRow = math.min(perRow, n - row * perRow)
			local x0 = (gridW - (inRow * (cw + gap) - gap)) / 2
			local slot = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(x0 + col * (cw + gap) + cw / 2, row * (ch + gap) + ch / 2), AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(cw, ch), ZIndex = 77 }, grid)
			local i = ridx(r.item and r.item.rarity)
			local rc = rcol(r.item and r.item.rarity)
			if App.sfx then App.sfx(i >= 5 and "reveal_legendary" or i >= 4 and "reveal_epic" or i >= 3 and "reveal_rare" or "reveal_common") end
			if i >= 3 then
				local a = aura(slot, rc, math.floor(math.max(cw, ch) * (1.15 + 0.1 * i)), UDim2.fromScale(0.5, 0.5), 77, math.min(1, 0.25 + 0.1 * i))
				local as = mk("UIScale", { Scale = 0 }, a)
				tw(as, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
			end
			local holder = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), ZIndex = 78 }, slot)
			resultCard(holder, r, cw, ch, 79)
			popIn(holder, 0.3, 0.45)
			if i >= 5 and not skip then
				local f = mk("Frame", { BackgroundColor3 = rc, BackgroundTransparency = 0.55, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 94 }, stage)
				tw(f, 0.6, { BackgroundTransparency = 1 })
				task.delay(0.65, function() f:Destroy() end)
			end
			pause(n == 1 and 0.3 or 0.32)
		end
		if not alive() then return end
		hint.Visible = false
		------------------------------------------------ buttons
		local bar = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -16), Size = UDim2.fromOffset(470, 50), ZIndex = 96 }, stage)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, bar)
		local cont = UI.button(bar, "gold", "CONTINUE", close, { sz = UDim2.fromOffset(220, 50), z = 97, order = 2, textSize = 20 })
		hoverBtn(cont)
		popIn(bar, 0.6, 0.3)
		if opts.again then
			local ag = UI.button(bar, "manila", opts.againLabel or "OPEN ANOTHER", function(b) opts.again(b) end, { sz = UDim2.fromOffset(220, 50), z = 97, order = 1, textSize = 18 })
			hoverBtn(ag)
		end
	end)
end

-- open crates from the inventory (or anywhere) and play the reveal; offers "open another" while crates remain
local function pityToast(App, res)
	for _, r in ipairs(res.results or {}) do
		if r.pity then App.toast("PITY REWARD!", "Your pity meter was full: guaranteed Legendary or better", "gold"); return end
	end
end
local function openCrates(App, kind, n, btn)
	local res = App.req("openCrate", { kind = kind, n = n }, btn)
	if not res.ok then return end
	pityToast(App, res)
	local left = res.left or (App.state and App.state.crates and App.state.crates[kind]) or 0
	reveal(App, res, {
		again = left > 0 and function(b) openCrates(App, kind, 1, b) end or nil,
		againLabel = "OPEN ANOTHER (" .. left .. ")",
	})
end
local function buyCrate(App, kind, btn)
	local res = App.req("buyCrate", { kind = kind }, btn)
	if res.ok then pityToast(App, res); reveal(App, res) end
end

local function hireReveal(App, o, where)
	reveal(App, { results = { { type = "officer", item = o, where = where } } }, { noCrate = true, title = "NEW OFFICER" })
end

local function installReveal(App)
	App.crateReveal = App.crateReveal or reveal
	App.openCrates = App.openCrates or function(kind, n, btn) openCrates(App, kind, n, btn) end
	App.dropRates = App.dropRates or function(kind) dropRates(App, kind) end
end

---------------------------------------------------------------- OFFICERS
local function header(host, App, title)
	local panel, body = UI.panel(host, title, { sz = UDim2.new(1, -20, 1, -20), pos = UDim2.fromOffset(10, 10), z = 5, titleSize = 26 })
	return panel, body
end

S.officers = { build = function(host, App)
	installReveal(App)
	local panel, body = header(host, App, "OFFICERS")
	local obj = { sig = nil, costBtns = {}, last = { atk = 0, def = 0, tot = 0 }, busy = false }

	infoBtn(App, panel, "OFFICERS", "Officers give your country % boosts. Every officer sits in a <b>slot</b>: you can only hire when a slot is open. "
		.. "<font color='#ff9a2e'><b>LIMITED</b></font> officers (Mega VIP, Limited Bundle) get their own extra slot.\n\n"
		.. "Every hire is unique: a rarity plus random traits. Weapons add attack, armor adds defense, on you and on each officer.",
		UDim2.fromOffset(158, 18), 8)
	text(panel, "Hire officers with cash. Each one rolls a rarity and traits; their gear adds attack and defense.", { size = 13, color = C.muted, wrap = true,
		pos = UDim2.fromOffset(186, 10), sz = UDim2.new(1, -186 - 372, 0, 36), z = 7 })

	-- UNEQUIP ALL / AUTO EQUIP BEST (client-side sequences of equip / unequip)
	local function runSeq(btn, label, calls, doneMsg)
		if obj.busy then return end
		if #calls == 0 then App.toast(doneMsg[1], doneMsg[3] or nil, "info"); return end
		obj.busy = true
		btn:Set(nil, "WORKING...")
		for _, c in ipairs(calls) do
			local r = App.req(c[1], c[2], btn)
			if not r.ok then break end
			task.wait(0.05)
		end
		obj.busy = false
		btn:Set(nil, label)
		App.toast(doneMsg[2], nil, "good")
	end
	local unequipBtn, autoBtn
	unequipBtn = UI.button(panel, "slate", "UNEQUIP ALL", function()
		local st = App.state
		local cab, inv = cabOf(st), invOf(st)
		local calls = {}
		for _, k in ipairs({ "weapon", "armor" }) do if cab.player[k] then table.insert(calls, { "unequip", { holder = "player", slot = k } }) end end
		local who = ltdList(st)
		for i = 1, slotsOf(st) do
			local o = cab.slots[i] and inv.officers[cab.slots[i]]
			if o then table.insert(who, o) end
		end
		for _, o in ipairs(who) do
			for _, k in ipairs({ "weapon", "armor" }) do if o[k] then table.insert(calls, { "unequip", { holder = o.id, slot = k } }) end end
		end
		runSeq(unequipBtn, "UNEQUIP ALL", calls, { "Nobody is wearing gear", "ALL GEAR UNEQUIPPED" })
	end, { pos = UDim2.new(1, -194, 0, 10), anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(170, 38), z = 8, textSize = 15 })
	autoBtn = UI.button(panel, "gold", "AUTO EQUIP BEST", function()
		local st = App.state
		local cab, inv = cabOf(st), invOf(st)
		local holders = { { id = "player", h = cab.player } }
		for _, o in ipairs(ltdList(st)) do table.insert(holders, { id = o.id, h = o }) end
		for i = 1, slotsOf(st) do
			local o = cab.slots[i] and inv.officers[cab.slots[i]]
			if o then table.insert(holders, { id = o.id, h = o }) end
		end
		local calls = {}
		for _, k in ipairs({ "weapon", "armor" }) do
			local items = gearSorted(st, k)
			for i, hd in ipairs(holders) do
				local want = items[i]
				if want and hd.h[k] ~= want.id then table.insert(calls, { "equip", { gear = want.id, holder = hd.id } }) end
			end
		end
		local hasGear = next(inv.gear) ~= nil
		runSeq(autoBtn, "AUTO EQUIP BEST", calls, { hasGear and "Already wearing your best gear" or "No gear yet", "BEST GEAR EQUIPPED", (not hasGear) and "Open crates in the Inventory to find weapons and armor" or nil })
	end, { pos = UDim2.new(1, -16, 0, 10), anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(170, 38), z = 8, textSize = 15 })
	hoverBtn(unequipBtn); hoverBtn(autoBtn)

	-- stat boxes
	local boxes = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), ZIndex = 6 }, body)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, boxes)
	local function statBox(order, icon, color, button)
		local b = UI.img(boxes, "inset", { sz = UDim2.new(0.25, -6, 1, 0), z = 7, order = order, button = button })
		UI.icon(b, icon, 22, color, UDim2.new(0, 12, 0.5, 0), { z = 8, anchor = Vector2.new(0, 0.5) })
		local l = text(b, "", { font = "heavy", size = 18, color = color == C.manila and C.ink or color, pos = UDim2.fromOffset(42, 0), sz = UDim2.new(1, -50, 1, 0), z = 8, scaled = true })
		return b, l
	end
	local _, countL = statBox(1, "icon_users", C.manila)
	local _, atkL = statBox(2, "icon_attack", C.bad)
	local _, defL = statBox(3, "icon_defense", C.blue)
	local totB, totL = statBox(4, "icon_sparkles", C.gold, true)
	UI.icon(totB, "icon_right", 16, C.muted, UDim2.new(1, -10, 0.5, 0), { z = 8, anchor = Vector2.new(1, 0.5) })
	hoverScale(totB, 0.03)
	totB.Activated:Connect(function()
		local b = bonuses(App.state)
		local lines = {}
		for _, t in ipairs(O.Traits) do
			if (b[t.key] or 0) > 0 then table.insert(lines, "<font color='#8fd07a'><b>+" .. math.floor(b[t.key] * 100 + 0.5) .. "%</b></font>  " .. t.name) end
		end
		if b.gearAtk > 0 then table.insert(lines, "<font color='#e2695f'><b>+" .. math.floor(b.gearAtk * 100 + 0.5) .. "%</b></font>  attack from weapons") end
		if b.gearDef > 0 then table.insert(lines, "<font color='#7fb0e6'><b>+" .. math.floor(b.gearDef * 100 + 0.5) .. "%</b></font>  defense from armor") end
		local _, bd, close = popup(App, "CABINET BONUSES", 440, 120 + 24 * math.max(2, #lines))
		text(bd, #lines > 0 and table.concat(lines, "\n") or "No bonuses yet. Hire officers and equip gear.", { size = 17, rich = true, wrap = true, valign = Enum.TextYAlignment.Top, sz = UDim2.new(1, 0, 1, -54), z = 74 })
		UI.button(bd, "slate", "CLOSE", close, { sz = UDim2.fromOffset(150, 42), pos = UDim2.new(0.5, 0, 1, -4), anchor = Vector2.new(0.5, 1), z = 74 })
	end)

	-- column headers
	local cols = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 52), Size = UDim2.new(1, -12, 0, 18), ZIndex = 6 }, body)
	for _, c in ipairs({ { "OFFICER", UDim2.new(0, 120, 0, 0) }, { "BONUSES", UDim2.new(0.3, 0, 0, 0) }, { "WEAPON", UDim2.new(0.47, 0, 0, 0) }, { "ARMOR", UDim2.new(0.66, 0, 0, 0) } }) do
		text(cols, c[1], { font = "heavy", size = 13, color = C.dim, pos = c[2], sz = UDim2.new(0.17, 0, 1, 0), z = 7 })
	end
	local list = UI.list(body, { pos = UDim2.fromOffset(0, 74), sz = UDim2.new(1, 0, 1, -74), gap = 8, z = 6 })

	---------------------------------------------- row pieces
	local function gearBox(card, st, holderId, holderName, slot, x)
		local holder = holderId == "player" and cabOf(st).player or invOf(st).officers[holderId]
		local g = holder and holder[slot] and invOf(st).gear[holder[slot]]
		local box = UI.img(card, "inset", { button = true, name = slot, pos = UDim2.new(x, 0, 0, 8), sz = UDim2.new(0.19, -8, 1, -16), z = 8 })
		if g then
			local rc = rcol(g.rarity)
			stroke(box, rc, 2)
			local well = mk("Frame", { BackgroundColor3 = DARK, BorderSizePixel = 0, Position = UDim2.new(0, 6, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(54, 54), ZIndex = 9 }, box)
			corner(well, 5)
			if ridx(g.rarity) >= 4 then glow(well, rc, 1.1, 9, 0.8) end
			gearImage(well, g, UDim2.fromScale(0.9, 0.9), UDim2.fromScale(0.5, 0.5), 10, Vector2.new(0.5, 0.5))
			text(box, g.name, { font = "heavy", size = 15, color = rc, pos = UDim2.fromOffset(66, 8), sz = UDim2.new(1, -70, 0, 19), z = 9, truncate = true })
			text(box, rar(g.rarity).name .. " " .. string.upper(slot), { font = "bold", size = 11, color = rc, pos = UDim2.fromOffset(66, 28), sz = UDim2.new(1, -70, 0, 14), z = 9, truncate = true })
			text(box, gearStat(g), { font = "bold", size = 12, color = C.good, pos = UDim2.fromOffset(66, 44), sz = UDim2.new(1, -70, 0, 16), z = 9, truncate = true })
		else
			stroke(box, C.rule, 1)
			text(box, (slot == "weapon" and "Weapon" or "Armor") .. ": Empty", { font = "bold", size = 16, color = C.muted, pos = UDim2.fromOffset(12, -8), sz = UDim2.new(1, -20, 1, 0), z = 9, truncate = true })
			text(box, "Tap to equip", { size = 12, color = C.dim, pos = UDim2.new(0, 12, 0.5, 6), sz = UDim2.new(1, -20, 0, 16), z = 9 })
		end
		hoverScale(box, 0.03)
		box.Activated:Connect(function() openPicker(App, holderId, holderName, slot) end)
	end
	local function arrow(card, up, y, fn)
		local b = UI.img(card, "btn_slate", { button = true, pos = UDim2.fromOffset(6, y), sz = UDim2.fromOffset(24, 32), z = 8 })
		UI.icon(b, up and "icon_left" or "icon_right", 14, C.ink, UDim2.fromScale(0.5, 0.5), { z = 9, anchor = Vector2.new(0.5, 0.5) }).Rotation = 90
		hoverScale(b, 0.1)
		b.Activated:Connect(fn)
	end
	local function costBtn(btn, cost, onKind)
		table.insert(obj.costBtns, { btn = btn, cost = cost, on = onKind })
		btn:Set((App.state and App.state.cash or 0) >= cost and onKind or "slate")
	end

	local function playerRow(st, order)
		local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 92), z = 7, order = order, hot = true })
		stroke(card, C.gold, 2)
		playerPortrait(card, 76, UDim2.fromOffset(36, 8), 8)
		text(card, "YOU", { font = "display", size = 22, color = C.gold, pos = UDim2.fromOffset(120, 8), sz = UDim2.new(0.3, -124, 0, 26), z = 8 })
		text(card, "HEAD OF STATE", { font = "heavy", size = 13, color = C.manila, pos = UDim2.fromOffset(120, 36), sz = UDim2.new(0.3, -124, 0, 16), z = 8, truncate = true })
		text(card, (st.name and st.name ~= "" and st.name or Players.LocalPlayer.DisplayName) .. " · LV " .. tostring(st.lv or 1), { size = 13, color = C.muted, pos = UDim2.fromOffset(120, 54), sz = UDim2.new(0.3, -124, 0, 16), z = 8, truncate = true })
		local p, inv = cabOf(st).player, invOf(st)
		local lines = {}
		local w, a = p.weapon and inv.gear[p.weapon], p.armor and inv.gear[p.armor]
		if w then table.insert(lines, "+" .. w.power .. "% attack") end
		if a then table.insert(lines, "+" .. a.power .. "% defense") end
		for _, g in ipairs({ w, a }) do if g and g.perk then table.insert(lines, traitLine(g.perk)) end end
		text(card, #lines > 0 and table.concat(lines, "\n") or "No gear worn", { font = "bold", size = 13, color = #lines > 0 and C.good or C.dim, valign = Enum.TextYAlignment.Center,
			pos = UDim2.new(0.3, 0, 0, 8), sz = UDim2.new(0.17, -8, 1, -16), z = 8, wrap = true })
		gearBox(card, st, "player", "You", "weapon", 0.47)
		gearBox(card, st, "player", "You", "armor", 0.66)
		UI.chip(card, "LEADER", { pos = UDim2.new(1, -12, 0.5, 0), anchor = Vector2.new(1, 0.5), z = 8, icon = "icon_crown", manila = true, size = 13 })
	end

	-- one officer row. slotIndex = normal slot number, or nil for a LIMITED officer in its exclusive slot
	local function officerRow(st, o, slotIndex, order)
		local rc = rcol(o.rarity)
		local limited = slotIndex == nil
		local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 92), z = 7, order = order, hot = limited })
		if limited then
			-- the special orange LIMITED frame: thick border, warm wash from the left, a LIMITED band under the portrait
			stroke(card, LIMITED, 3)
			local wash = mk("Frame", { Name = "LimitedWash", BackgroundColor3 = LIMITED, BackgroundTransparency = 0.55, BorderSizePixel = 0, Position = UDim2.fromOffset(3, 3),
				Size = UDim2.new(0.45, 0, 1, -6), ZIndex = 7 }, card)
			corner(wash, 8)
			mk("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }) }, wash)
			UI.icon(card, "icon_sparkles", 18, LIMITED, UDim2.fromOffset(9, 10), { z = 9 })
		else
			if slotIndex > 1 then arrow(card, true, 10, function() App.req("seat", { id = o.id, slot = slotIndex - 1 }) end) end
			if slotIndex < slotsOf(st) then arrow(card, false, 50, function() App.req("seat", { id = o.id, slot = slotIndex + 1 }) end) end
		end
		local pt = portrait(card, o, 76, UDim2.fromOffset(36, 8), 8)
		if ridx(o.rarity) >= 5 then glow(pt, rc, 1.2, 8, 0.5) end
		if limited then
			local band = mk("Frame", { BackgroundColor3 = LIMITED, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(1, 0, 0, 16), ZIndex = 10 }, pt)
			text(band, "LIMITED", { font = "heavy", size = 12, color = C.black, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 11 })
		end
		text(card, o.name, { font = "heavy", size = 15, color = limited and LIMITED or C.ink, pos = UDim2.fromOffset(120, 8), sz = UDim2.new(0.3, -124, 0, 20), z = 8, truncate = true })
		text(card, rar(o.rarity).name, { font = "heavy", size = 13, color = rc, pos = UDim2.fromOffset(120, 30), sz = UDim2.new(0.3, -124, 0, 16), z = 8 })
		text(card, string.upper(o.title or "") .. (limited and " · LIMITED SLOT" or (" · SLOT " .. slotIndex)), { font = "bold", size = 12, color = C.muted, pos = UDim2.fromOffset(120, 48), sz = UDim2.new(0.3, -124, 0, 16), z = 8, truncate = true })
		local t = {}
		for k, tr in ipairs(o.traits or {}) do if k <= 4 then table.insert(t, traitLine(tr)) end end
		text(card, table.concat(t, "\n"), { font = "bold", size = 13, color = C.good, pos = UDim2.new(0.3, 0, 0, 8), sz = UDim2.new(0.17, -8, 1, -16), z = 8, wrap = true })
		gearBox(card, st, o.id, o.name, "weapon", 0.47)
		gearBox(card, st, o.id, o.name, "armor", 0.66)
		if limited then
			local chip = mk("Frame", { BackgroundColor3 = DARK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0.85, 2, 0.5, 0), Size = UDim2.new(0.15, -10, 0, 44), ZIndex = 8 }, card)
			corner(chip, 6)
			stroke(chip, LIMITED, 2)
			text(chip, "LIMITED\n<font color='#9a9fa6'>always active</font>", { font = "heavy", size = 14, color = LIMITED, align = Enum.TextXAlignment.Center, rich = true, wrap = true, scaled = true,
				pos = UDim2.fromOffset(4, 2), sz = UDim2.new(1, -8, 1, -4), z = 9 })
		else
			local fb = UI.button(card, "red", "FIRE", function(b) fireOfficer(App, o, b) end,
				{ pos = UDim2.new(0.85, 2, 0.5, 0), anchor = Vector2.new(0, 0.5), sz = UDim2.new(0.15, -10, 0, 40), z = 8, textSize = 15 })
			hoverBtn(fb)
		end
	end

	local function hireRow(st, order, free)
		local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 100), z = 7, order = order })
		stroke(card, free > 0 and C.rule or C.bad, 1, free > 0 and 0 or 0.4)
		text(card, free > 0 and (free > 1 and (free .. " EMPTY SLOTS") or "EMPTY SLOT") or "NO FREE SLOT", { font = "display", size = 21, color = free > 0 and C.manila or C.bad, pos = UDim2.fromOffset(16, 8), sz = UDim2.new(0.42, -16, 0, 26), z = 8 })
		text(card, free > 0 and "A random recruit joins your cabinet. Pricier hires roll rarer officers."
			or "Every slot is full. <b>Unlock a slot below</b> or fire an officer to hire again.",
			{ size = 13, color = C.muted, pos = UDim2.fromOffset(16, 34), sz = UDim2.new(0.42, -16, 0, 30), z = 8, wrap = true, rich = true })
		ratesBtn(App, card, "hire", { pos = UDim2.new(0, 16, 1, -38), sz = UDim2.fromOffset(150, 30) })
		for k, t in ipairs(Config.Officers.Hire) do
			local b = UI.button(card, free > 0 and "gold" or "locked", t.name .. "\n" .. (free > 0 and R.Money(t.cost) or "NO FREE SLOT"), function(btn)
				local s = App.state
				if freeSlots(s) == 0 then App.toast("NO FREE SLOT", "Unlock a slot or fire an officer first", "bad"); App.shake(btn.Inst); return end
				if (s.cash or 0) < t.cost then App.toast("Not enough cash", t.name .. " costs " .. R.Money(t.cost), "bad"); App.shake(btn.Inst); return end
				local res = App.req("hire", { tier = t.key }, btn)
				if res.ok and res.officer then hireReveal(App, res.officer, res.where) end
			end, { pos = UDim2.new(0.43 + (k - 1) * 0.19, 0, 0.5, 0), anchor = Vector2.new(0, 0.5), sz = UDim2.new(0.18, -4, 0, 60), z = 8, textSize = 16 })
			hoverBtn(b)
			if free > 0 then costBtn(b, t.cost, "gold") end
		end
	end

	local function lockedRow(st, order)
		local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 78), z = 7, order = order })
		stroke(card, C.rule, 1)
		local cost = st.nextSlotCost
		local pass = Config.Passes and Config.Passes.BonusOfficer
		local showPass = pass and not (st.gp and st.gp.BonusOfficer)
		local rightW = (cost and 264 or 0) + (showPass and 196 or 0)
		UI.icon(card, "icon_lock", 26, C.dim, UDim2.new(0, 16, 0.5, 0), { z = 8, anchor = Vector2.new(0, 0.5) })
		text(card, cost and "LOCKED SLOT" or "ALL SLOTS UNLOCKED", { font = "display", size = 21, color = C.muted, pos = UDim2.fromOffset(54, 10), sz = UDim2.new(1, -64 - rightW, 0, 26), z = 8, truncate = true })
		text(card, cost and "Buy this slot to hire another officer. Each slot costs more than the last." or "You own every officer slot you can buy.",
			{ size = 13, color = C.muted, pos = UDim2.fromOffset(54, 38), sz = UDim2.new(1, -64 - rightW, 0, 32), z = 8, wrap = true })
		if cost then
			local b = UI.button(card, "gold", "UNLOCK SLOT  " .. R.Money(cost), function(btn)
				local s = App.state
				if s.cash < cost then App.toast("Not enough cash", "This slot costs " .. R.Money(cost), "bad"); App.shake(btn.Inst); return end
				local res = App.req("buySlot", {}, btn)
				if res.ok then App.toast("OFFICER SLOT UNLOCKED", "Hire someone to fill it", "good") end
			end, { pos = UDim2.new(1, -14, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(250, 46), z = 8, textSize = 16 })
			hoverBtn(b)
			costBtn(b, cost, "gold")
		end
		if showPass then
			local pb = UI.button(card, "blue", "+1 SLOT  R$" .. pass.price, function(btn) App.req("buyPass", { key = "BonusOfficer" }, btn) end,
				{ pos = UDim2.new(1, cost and -276 or -14, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(180, 46), z = 8, textSize = 15 })
			hoverBtn(pb)
		end
	end

	-- LIMITED slots: exclusive slots for limited officers (Mega VIP, Limited Bundle), never using a normal slot
	local function limitedSection(st, order)
		local ltd = ltdList(st)
		if #ltd == 0 then return end
		local hdr = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), ZIndex = 7, LayoutOrder = order }, list)
		text(hdr, "LIMITED SLOTS", { font = "display", size = 22, color = LIMITED, pos = UDim2.fromOffset(4, 4), sz = UDim2.fromOffset(190, 28), z = 8 })
		infoBtn(App, hdr, "LIMITED SLOTS", "Limited officers from <b>Mega VIP</b> and the <b>Limited Bundle</b> sit in their own exclusive slots. "
			.. "They never take a normal slot, always give their bonuses and can't be fired.", UDim2.fromOffset(200, 8), 8)
		for k, o in ipairs(ltd) do officerRow(st, o, nil, order + k) end
	end
	-- no limited officer yet: a slim pointer to where they come from
	local function limitedTeaser(order)
		local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 60), z = 7, order = order })
		stroke(card, LIMITED, 1, 0.5)
		UI.icon(card, "icon_sparkles", 22, LIMITED, UDim2.new(0, 16, 0.5, 0), { z = 8, anchor = Vector2.new(0, 0.5) })
		text(card, "<font color='#ff9a2e'><b>LIMITED SLOT</b></font>  Mega VIP and the Limited Bundle add an exclusive officer in their own extra slot.",
			{ size = 14, color = C.muted, rich = true, wrap = true, pos = UDim2.fromOffset(50, 0), sz = UDim2.new(1, -200, 1, 0), z = 8 })
		local b = UI.button(card, "manila", "SHOP", function() App.open("shop") end, { pos = UDim2.new(1, -12, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(130, 40), z = 8, icon = "icon_shop", textSize = 15 })
		hoverBtn(b)
	end

	-- signature of everything the rows show, so a sync that changes nothing here does not rebuild (and break hovers)
	local function sig(st)
		local cab, inv = cabOf(st), invOf(st)
		local parts = { slotsOf(st), tostring(st.nextSlotCost), tostring(st.name), tostring(st.lv), st.gp and st.gp.BonusOfficer and 1 or 0, st.gp and st.gp.CrateLuck and 1 or 0,
			tostring(cab.player.weapon), tostring(cab.player.armor) }
		for i = 1, slotsOf(st) do table.insert(parts, tostring(cab.slots[i])) end
		table.insert(parts, "L" .. table.concat(cab.ltd, ","))
		local ids = {}
		for id, o in pairs(inv.officers) do table.insert(ids, id .. ":" .. tostring(o.weapon) .. ":" .. tostring(o.armor)) end
		table.sort(ids)
		table.insert(parts, table.concat(ids, ","))
		local gids = {}
		for id in pairs(inv.gear) do table.insert(gids, id) end
		table.sort(gids)
		table.insert(parts, table.concat(gids, ","))
		return table.concat(parts, "|")
	end

	local function updateStats(st)
		local seatedN = 0
		for _ in pairs(seatedMap(st)) do seatedN += 1 end
		local ltdN = #ltdList(st)
		countL.Text = seatedN .. " OF " .. slotsOf(st) .. " OFFICERS" .. (ltdN > 0 and (" +" .. ltdN .. " LTD") or "")
		local b = bonuses(st)
		local atk = math.floor((b.attack + b.gearAtk) * 100 + 0.5)
		local def = math.floor((b.defense + b.gearDef) * 100 + 0.5)
		local tot = 0
		for k, v in pairs(b) do if type(v) == "number" then tot += v end end
		tot = math.floor(tot * 100 + 0.5)
		countTo(atkL, obj.last.atk, atk, function(v) return "+" .. math.floor(v + 0.5) .. "% ATTACK" end)
		countTo(defL, obj.last.def, def, function(v) return "+" .. math.floor(v + 0.5) .. "% DEFENSE" end)
		countTo(totL, obj.last.tot, tot, function(v) return "+" .. math.floor(v + 0.5) .. "% TOTAL BONUS" end)
		obj.last = { atk = atk, def = def, tot = tot }
	end

	function obj:Refresh(st)
		if not st then return end
		local s = sig(st)
		if s ~= obj.sig then
			obj.sig = s
			UI.clear(list)
			obj.costBtns = {}
			local cab, inv = cabOf(st), invOf(st)
			playerRow(st, 1)
			limitedSection(st, 2) -- orders 2..(2 + n), normal slots start at 30
			local free = 0
			for i = 1, slotsOf(st) do
				local o = cab.slots[i] and inv.officers[cab.slots[i]]
				if o then officerRow(st, o, i, 30 + i) else free += 1 end
			end
			hireRow(st, 100, free)
			lockedRow(st, 101)
			if #ltdList(st) == 0 then limitedTeaser(150) end
			updateStats(st)
		end
		self:Tick(st)
	end
	function obj:Tick(st)
		if not st then return end
		for _, c in ipairs(obj.costBtns) do
			if c.btn.Inst.Parent then c.btn:Set(st.cash >= c.cost and c.on or "slate") end
		end
	end
	function obj:Opened() obj.sig = nil; if App.state then self:Refresh(App.state) end end
	return obj
end }

---------------------------------------------------------------- INVENTORY
S.inventory = { build = function(host, App)
	installReveal(App)
	local panel, body = header(host, App, "INVENTORY")
	local obj = { tab = 1, rar = nil, sig = nil }
	local sub = text(panel, "", { font = "bold", size = 14, color = C.muted, pos = UDim2.fromOffset(250, 16), sz = UDim2.new(1, -300, 0, 22), z = 7, align = Enum.TextXAlignment.Right, rich = true, truncate = true })
	infoBtn(App, panel, "INVENTORY", "Everything you own. <b>Weapons</b> add attack and <b>armor</b> adds defense when worn by you or one of your officers. "
		.. "Legendary and better gear rolls a bonus perk.\n\nOpen <b>crates</b> here. Tap a card for details, equip or discard.", UDim2.new(1, -36, 0, 18), 8)

	local FILTERS = { "ALL", "WEAPONS", "ARMOR", "OFFICERS", "CRATES" }
	local tabs = UI.tabs(body, FILTERS, function(i) obj.tab = i; obj.sig = nil; obj:Refresh(App.state) end, { w = 106, textSize = 14, z = 7 })
	tabs:Set(1)

	-- rarity dropdown
	local rarBtn
	local drop = UI.img(body, "panel_plain", { name = "RarityDrop", pos = UDim2.new(1, 0, 0, 40), anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(190, 12 + 30 * (#O.Rarities + 1)), z = 30, visible = false })
	local dl = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 1, -12), ZIndex = 31 }, drop)
	mk("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }, dl)
	local function pickRar(key)
		obj.rar = key
		drop.Visible = false
		rarBtn:Set(nil, key and rar(key).name or "ALL RARITIES")
		rarBtn.Label.TextColor3 = key and rcol(key) or C.ink
		obj.sig = nil
		obj:Refresh(App.state)
	end
	local opts = { { nil, "ALL RARITIES", C.ink } }
	for _, r in ipairs(O.Rarities) do table.insert(opts, { r.key, r.name, Color3.fromHex(r.color) }) end
	for i, op in ipairs(opts) do
		local b = mk("TextButton", { Text = op[2], FontFace = UI.Font.heavy, TextSize = 15, TextColor3 = op[3], BackgroundColor3 = C.slate, BackgroundTransparency = 1, AutoButtonColor = false,
			TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 30), ZIndex = 32, LayoutOrder = i }, dl)
		mk("UIPadding", { PaddingLeft = UDim.new(0, 10) }, b)
		corner(b, 4)
		b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.2 end)
		b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
		b.Activated:Connect(function() pickRar(op[1]) end)
	end
	rarBtn = UI.button(body, "slate", "ALL RARITIES", function() drop.Visible = not drop.Visible end,
		{ pos = UDim2.new(1, 0, 0, 0), anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(170, 34), z = 8, textSize = 14, icon = "icon_gem" })
	hoverBtn(rarBtn)

	local grid = UI.list(body, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), grid = UDim2.fromOffset(150, 214), gap = 10, z = 6 })

	-- ELITE TROOPS strip (Founder's Crate / Starter Pack): one chip per era you own elite troops of
	local STRIP_H = 44
	local strip = UI.img(body, "inset", { name = "EliteStrip", pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, -12, 0, STRIP_H - 6), z = 7, visible = false })
	stroke(strip, C.gold, 1.5, 0.3)
	UI.icon(strip, "icon_crown", 18, C.gold, UDim2.new(0, 10, 0.5, 0), { z = 8, anchor = Vector2.new(0, 0.5) })
	text(strip, "ELITE TROOPS", { font = "heavy", size = 14, color = C.gold, pos = UDim2.fromOffset(34, 0), sz = UDim2.new(0, 104, 1, 0), z = 8 })
	infoBtn(App, strip, "ELITE TROOPS", "Elite troops come from the <b>Founder's Crate</b> and the <b>Starter Pack</b>. Each era has one elite unit, much stronger than its regular troops.\n\n"
		.. "<font color='#f0c75a'><b>Elite troops never die in raids</b></font> and do not use army capacity. They always add their ATK and DEF to your power.", UDim2.new(0, 138, 0.5, -10), 9)
	local chips = UI.list(strip, { horizontal = true, pos = UDim2.fromOffset(166, 4), sz = UDim2.new(1, -172, 1, -4), gap = 8, z = 8 })
	chips.ScrollBarThickness = 3
	local function eliteOf(st)
		local out = {}
		for k, n in pairs((st and st.elite) or {}) do
			local era, cnt = tonumber(k), tonumber(n) or 0
			if era and cnt > 0 and M.Elite[era] then table.insert(out, { era = era, n = cnt, u = M.Elite[era] }) end
		end
		table.sort(out, function(a, b) return a.era > b.era end)
		return out
	end
	local function buildStrip(st, show)
		UI.clear(chips)
		local list = eliteOf(st)
		show = show and #list > 0
		strip.Visible = show
		grid.Position = UDim2.fromOffset(0, show and 44 + STRIP_H or 44)
		grid.Size = UDim2.new(1, 0, 1, show and -(44 + STRIP_H) or -44)
		for i, e in ipairs(list) do
			UI.chip(chips, "<b>" .. R.Commas(e.n) .. "x " .. e.u.name .. "</b>  <font color='#e2695f'>ATK " .. R.Short(e.u.atk) .. "</font> <font color='#7fb0e6'>DEF " .. R.Short(e.u.def) .. "</font>",
				{ order = i, icon = "icon_military", iconColor = C.gold, rich = true, size = 13, h = 26, z = 9 })
		end
	end
	local empty = text(body, "", { size = 17, color = C.dim, align = Enum.TextXAlignment.Center, pos = UDim2.new(0, 0, 0.5, 0), sz = UDim2.new(1, 0, 0, 50), z = 8, wrap = true, visible = false })

	---------------------------------------------- details popups
	local function gearDetails(g)
		local st = App.state
		local rc = rcol(g.rarity)
		local w = wearers(st)[g.id]
		local _, bd, close = popup(App, string.upper(g.name), 560, 360)
		local well = mk("Frame", { BackgroundColor3 = DARK, BorderSizePixel = 0, Size = UDim2.fromOffset(180, 180), ZIndex = 74, ClipsDescendants = true }, bd)
		corner(well, 8)
		stroke(well, rc, 2)
		aura(well, rc, 260, UDim2.fromScale(0.5, 0.5), 74, math.min(1, 0.2 + 0.1 * ridx(g.rarity)))
		gearImage(well, g, UDim2.fromScale(0.85, 0.85), UDim2.fromScale(0.5, 0.5), 76, Vector2.new(0.5, 0.5))
		local info = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(196, 0), Size = UDim2.new(1, -196, 0, 180), ZIndex = 74 }, bd)
		text(info, rar(g.rarity).name .. " " .. string.upper(g.kind or ""), { font = "heavy", size = 18, color = rc, sz = UDim2.new(1, 0, 0, 24), z = 75 })
		text(info, g.type or "", { size = 14, color = C.muted, pos = UDim2.fromOffset(0, 26), sz = UDim2.new(1, 0, 0, 18), z = 75 })
		text(info, gearMain(g), { font = "heavy", size = 22, color = g.kind == "weapon" and C.bad or C.blue, pos = UDim2.fromOffset(0, 54), sz = UDim2.new(1, 0, 0, 28), z = 75 })
		if g.perk then text(info, "Perk: " .. traitLine(g.perk), { font = "bold", size = 16, color = C.good, pos = UDim2.fromOffset(0, 86), sz = UDim2.new(1, 0, 0, 22), z = 75 }) end
		text(info, w and ("Worn by <b>" .. w.name .. "</b>") or "Not equipped", { size = 15, color = C.ink, rich = true, pos = UDim2.fromOffset(0, 116), sz = UDim2.new(1, 0, 0, 22), z = 75 })
		if g.limited then text(info, "LIMITED · cannot be discarded", { font = "heavy", size = 13, color = rcol("limited"), pos = UDim2.fromOffset(0, 142), sz = UDim2.new(1, 0, 0, 18), z = 75 }) end
		local bar = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -46), Size = UDim2.new(1, 0, 0, 46), ZIndex = 74 }, bd)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }, bar)
		-- EQUIP ON: pick who wears it
		local eq = UI.button(bar, "green", "EQUIP ON...", function()
			local s = App.state
			local cab, inv = cabOf(s), invOf(s)
			local seated, ltd = seatedMap(s), ltdSet(s)
			local holders = { { id = "player", name = "You", seat = 0 } }
			for id, o in pairs(inv.officers) do table.insert(holders, { id = id, name = o.name, o = o, seat = ltd[id] and 0.5 or seated[id] or 99 }) end
			table.sort(holders, function(a, b) if a.seat ~= b.seat then return a.seat < b.seat end; return a.name < b.name end)
			local _, bd2, close2 = popup(App, "EQUIP " .. string.upper(g.name) .. " ON", 600, 480)
			local lst = UI.list(bd2, { sz = UDim2.new(1, 0, 1, -54), gap = 6, z = 74 })
			for k, hd in ipairs(holders) do
				local cur = hd.id == "player" and cab.player[g.kind] or (hd.o and hd.o[g.kind])
				local cg = cur and inv.gear[cur]
				local row = UI.card(lst, { sz = UDim2.new(1, 0, 0, 62), z = 75, order = k, hot = hd.id == "player" })
				if hd.id == "player" then playerPortrait(row, 48, UDim2.fromOffset(8, 7), 76) else portrait(row, hd.o, 48, UDim2.fromOffset(8, 7), 76) end
				text(row, hd.name, { font = "heavy", size = 16, color = hd.id == "player" and C.gold or C.ink, pos = UDim2.fromOffset(66, 6), sz = UDim2.new(1, -210, 0, 20), z = 76, truncate = true })
				local where = hd.id == "player" and "HEAD OF STATE" or hd.seat == 0.5 and "LIMITED SLOT" or (hd.seat < 99 and ("SLOT " .. hd.seat) or "NOT SEATED")
				text(row, where, { font = "bold", size = 12, color = hd.o and rcol(hd.o.rarity) or C.manila, pos = UDim2.fromOffset(66, 26), sz = UDim2.new(1, -210, 0, 15), z = 76 })
				text(row, cg and ("Now: " .. cg.name .. " (" .. gearMain(cg) .. ")") or "Now: empty", { size = 12, color = cg and rcol(cg.rarity) or C.dim, pos = UDim2.fromOffset(66, 42), sz = UDim2.new(1, -210, 0, 15), z = 76, truncate = true })
				if cur == g.id then
					UI.button(row, "locked", "WEARING", nil, { pos = UDim2.new(1, -10, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(120, 40), z = 77, textSize = 15 })
				else
					local b = UI.button(row, "green", "EQUIP", function(btn)
						local res = App.req("equip", { gear = g.id, holder = hd.id }, btn)
						if res.ok then close2(); App.toast("EQUIPPED", g.name .. " on " .. hd.name, "good") end
					end, { pos = UDim2.new(1, -10, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(120, 40), z = 77, textSize = 15 })
					hoverBtn(b)
				end
			end
			UI.button(bd2, "slate", "CLOSE", close2, { pos = UDim2.new(0.5, 0, 1, -2), anchor = Vector2.new(0.5, 1), sz = UDim2.fromOffset(160, 44), z = 74 })
		end, { sz = UDim2.fromOffset(150, 44), z = 75, order = 3, textSize = 16 })
		hoverBtn(eq)
		if w then
			UI.button(bar, "slate", "UNEQUIP", function(b)
				local res = App.req("unequip", { holder = w.id, slot = g.kind }, b)
				if res.ok then close() end
			end, { sz = UDim2.fromOffset(130, 44), z = 75, order = 2, textSize = 16 })
		end
		UI.button(bar, g.limited and "locked" or "red", "DISCARD", function(b)
			if g.limited then App.toast("Limited items cannot be thrown away", nil, "bad"); App.shake(b.Inst); return end
			App.confirm("DISCARD?", "Throw away <b>" .. g.name .. "</b> (" .. rar(g.rarity).name .. ")? You get nothing back. This cannot be undone.", "DISCARD", "red", function(cb)
				local res = App.req("discard", { gear = g.id }, cb)
				if res.ok then App.toast(string.upper(g.name) .. " DISCARDED", nil, "info") end
			end)
		end, { sz = UDim2.fromOffset(130, 44), z = 75, order = 1, textSize = 16 })
	end

	local function officerDetails(o)
		local st = App.state
		local rc = rcol(o.rarity)
		local slot = seatedMap(st)[o.id]
		local isLtd = ltdSet(st)[o.id] or o.limited
		local _, bd, close = popup(App, string.upper(o.name), 560, 360)
		local holder = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(180, 180), ZIndex = 74, ClipsDescendants = true }, bd)
		aura(holder, rc, 260, UDim2.fromScale(0.5, 0.5), 74, math.min(1, 0.2 + 0.1 * ridx(o.rarity)))
		portrait(holder, o, 160, UDim2.fromScale(0.5, 0.5), 75, { anchor = Vector2.new(0.5, 0.5), thick = 3 })
		local info = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(196, 0), Size = UDim2.new(1, -196, 0, 190), ZIndex = 74 }, bd)
		text(info, rar(o.rarity).name .. " OFFICER", { font = "heavy", size = 18, color = rc, sz = UDim2.new(1, 0, 0, 24), z = 75 })
		text(info, (o.title or "") .. " · " .. (isLtd and "Limited slot (always active)" or slot and ("Slot " .. slot) or "Not seated"), { size = 14, color = isLtd and LIMITED or C.muted, pos = UDim2.fromOffset(0, 26), sz = UDim2.new(1, 0, 0, 18), z = 75 })
		local t = {}
		for _, tr in ipairs(o.traits or {}) do table.insert(t, traitLine(tr)) end
		text(info, table.concat(t, "\n"), { font = "heavy", size = 18, color = C.good, pos = UDim2.fromOffset(0, 54), sz = UDim2.new(1, 0, 0, 110), z = 75, wrap = true, valign = Enum.TextYAlignment.Top })
		local bar = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -46), Size = UDim2.new(1, 0, 0, 46), ZIndex = 74 }, bd)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }, bar)
		UI.button(bar, "manila", "OFFICERS", function() close(); App.open("officers") end, { sz = UDim2.fromOffset(140, 44), z = 75, order = 1, textSize = 16 })
		UI.button(bar, isLtd and "locked" or "red", "FIRE", function(b)
			if isLtd then fireOfficer(App, o, b); return end
			close()
			fireOfficer(App, o, b)
		end, { sz = UDim2.fromOffset(110, 44), z = 75, order = 3, textSize = 16 })
	end

	---------------------------------------------- cards
	local function card(order, rc, tag)
		local c = UI.img(grid, "card", { button = true, z = 7, order = order })
		stroke(c, rc, 2)
		hoverScale(c, 0.05)
		text(c, tag, { font = "heavy", size = 11, color = C.muted, pos = UDim2.fromOffset(10, 6), sz = UDim2.new(1, -20, 0, 14), z = 9 })
		local well = mk("Frame", { BackgroundColor3 = DARK, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 22), Size = UDim2.new(1, -16, 0, 98), ZIndex = 8, ClipsDescendants = true }, c)
		corner(well, 6)
		return c, well
	end
	local function rarityBar(c, label, rc)
		local b = mk("Frame", { BackgroundColor3 = rc, BorderSizePixel = 0, Position = UDim2.new(0, 8, 1, -26), Size = UDim2.new(1, -16, 0, 18), ZIndex = 9 }, c)
		corner(b, 3)
		text(b, label, { font = "heavy", size = 12, color = C.black, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 10 })
	end
	local function nameLine(c, s, y)
		text(c, s, { font = "heavy", size = 15, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(6, y or 124), sz = UDim2.new(1, -12, 0, 36), z = 9, wrap = true, scaled = true })
	end
	local function tagChip(well, s, color)
		local ch = mk("Frame", { BackgroundColor3 = color, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.fromOffset(0, 16), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 11 }, well)
		corner(ch, 3)
		mk("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, ch)
		local l = text(ch, s, { font = "heavy", size = 11, color = C.black, sz = UDim2.fromScale(0, 1), z = 12 })
		l.AutomaticSize = Enum.AutomaticSize.X
	end

	local function gearCard(g, order, wm)
		local rc = rcol(g.rarity)
		local c, well = card(order, rc, g.kind == "weapon" and "WEAPON" or "ARMOR")
		if ridx(g.rarity) >= 4 then glow(well, rc, 1.1, 8, math.min(1, 0.1 * ridx(g.rarity))) end
		gearImage(well, g, UDim2.fromScale(0.8, 0.8), UDim2.fromScale(0.5, 0.46), 10, Vector2.new(0.5, 0.5))
		if wm[g.id] then tagChip(well, "EQUIPPED", C.gold) end
		nameLine(c, g.name)
		text(c, gearStat(g), { font = "bold", size = 12, color = C.good, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(6, 162), sz = UDim2.new(1, -12, 0, 22), z = 9, wrap = true, scaled = true })
		rarityBar(c, rar(g.rarity).name, rc)
		c.Activated:Connect(function() gearDetails(g) end)
	end
	local function officerCard(o, order, seated, ltd)
		local rc = rcol(o.rarity)
		local c, well = card(order, rc, "OFFICER")
		if ridx(o.rarity) >= 4 then glow(well, rc, 1.1, 8, math.min(1, 0.1 * ridx(o.rarity))) end
		UI.img(well, portraitKey(o), { sz = UDim2.fromScale(0.86, 0.9), pos = UDim2.fromScale(0.5, 1), anchor = Vector2.new(0.5, 1), color = tintFor(o, rc), z = 10, slice = false, fit = true })
		if ltd[o.id] then
			stroke(well, LIMITED, 2)
			tagChip(well, "LIMITED SLOT", LIMITED)
		else
			tagChip(well, seated[o.id] and ("SLOT " .. seated[o.id]) or "NOT SEATED", seated[o.id] and C.good or C.muted)
		end
		nameLine(c, o.name)
		local t = {}
		for k, tr in ipairs(o.traits or {}) do if k <= 2 then table.insert(t, traitLine(tr)) end end
		text(c, table.concat(t, "  "), { font = "bold", size = 12, color = C.good, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(6, 162), sz = UDim2.new(1, -12, 0, 22), z = 9, wrap = true, scaled = true })
		rarityBar(c, rar(o.rarity).name, rc)
		c.Activated:Connect(function() officerDetails(o) end)
	end
	local function crateCard(kind, count, order, st)
		local isBasic = kind == "basic"
		local def = isBasic and Config.Crates.Basic or Config.Crates.Limited
		local rc = isBasic and rcol("common") or rcol("limited")
		local c, well = card(order, rc, "CRATE")
		if not isBasic then glow(well, rc, 1.1, 8, 0.6) end
		local img = UI.img(well, isBasic and "crate_basic" or "crate_limited", { sz = UDim2.fromScale(0.82, 0.82), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 10, slice = false, fit = true })
		if count > 0 then
			text(well, "x" .. count, { font = "heavy", size = 22, color = C.white, align = Enum.TextXAlignment.Right, pos = UDim2.new(1, -6, 1, -4), anchor = Vector2.new(1, 1), sz = UDim2.fromOffset(60, 26), z = 11, stroke = 1.6 })
			-- idle wobble so unopened crates feel alive
			img.Rotation = -4
			TweenService:Create(img, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Rotation = 4 }):Play()
		end
		text(c, def.name, { font = "heavy", size = 14, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(6, 122), sz = UDim2.new(1, -12, 0, 20), z = 9, scaled = true })
		-- DROP RATES chip on every crate (Kash: every RNG box shows its drops and % rates)
		local ratesChip = mk("TextButton", { Name = "Rates", Text = "% RATES", FontFace = UI.Font.heavy, TextSize = 11, TextColor3 = C.manila, BackgroundColor3 = C.slate, AutoButtonColor = false,
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 3), Size = UDim2.fromOffset(60, 18), ZIndex = 12 }, c)
		corner(ratesChip, 9)
		stroke(ratesChip, C.manila, 1.2)
		hoverScale(ratesChip, 0.1)
		ratesChip.Activated:Connect(function() dropRates(App, kind) end)
		-- visible PITY meter (Kash 2 Oct): fills with every crate that is not Legendary+
		do
			local need = O.Pity[kind] or 50
			local have = math.min(need, (st and st.pity and st.pity[kind]) or 0)
			local track = mk("Frame", { Name = "Pity", BackgroundColor3 = C.black, BackgroundTransparency = 0.25, BorderSizePixel = 0, Position = UDim2.new(0, 8, 0, 100), Size = UDim2.new(1, -16, 0, 16), ZIndex = 12 }, c)
			corner(track, 8)
			local fill = mk("Frame", { BackgroundColor3 = Color3.fromHex("e9b949"), BorderSizePixel = 0, Size = UDim2.new(have / need, 0, 1, 0), ZIndex = 12 }, track)
			corner(fill, 8)
			text(track, "PITY " .. have .. "/" .. need, { font = "heavy", size = 11, color = C.white, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 13, stroke = 1.2 })
		end
		if count > 0 then
			local n = math.min(count, 10)
			if n > 1 then
				local a = UI.button(c, "green", "OPEN", function(b) openCrates(App, kind, 1, b) end, { pos = UDim2.fromOffset(8, 148), sz = UDim2.new(0.5, -11, 0, 32), z = 10, textSize = 14 })
				local m = UI.button(c, "gold", "OPEN " .. n, function(b) openCrates(App, kind, n, b) end, { pos = UDim2.new(0.5, 3, 0, 148), sz = UDim2.new(0.5, -11, 0, 32), z = 10, textSize = 14 })
				hoverBtn(a); hoverBtn(m)
			else
				local a = UI.button(c, "green", "OPEN", function(b) openCrates(App, kind, 1, b) end, { pos = UDim2.fromOffset(8, 148), sz = UDim2.new(1, -16, 0, 32), z = 10, textSize = 15 })
				hoverBtn(a)
			end
		elseif isBasic then
			local price = st.basicCratePrice or 0
			local b = UI.button(c, (st.cash or 0) >= price and "manila" or "slate", "BUY " .. R.Money(price), function(btn)
				if (App.state.cash or 0) < price then App.toast("Not enough cash", "A Supply Crate costs " .. R.Money(price), "bad"); App.shake(btn.Inst); return end
				buyCrate(App, "basic", btn)
			end, { pos = UDim2.fromOffset(8, 148), sz = UDim2.new(1, -16, 0, 32), z = 10, textSize = 14 })
			hoverBtn(b)
		else
			local live = App.now() < (def.ends or 0)
			if live then
				local gb = UI.button(c, (st.gold or 0) >= def.gold and "gold" or "slate", def.gold .. " GOLD", function(btn)
					if (App.state.gold or 0) < def.gold then App.toast("Not enough gold", "The " .. def.name .. " costs " .. def.gold .. " gold", "bad"); App.shake(btn.Inst); return end
					buyCrate(App, "limited", btn)
				end, { pos = UDim2.fromOffset(8, 148), sz = UDim2.new(0.55, -11, 0, 32), z = 10, textSize = 13 })
				local prod = Config.Products and Config.Products.Crate1
				local rb = UI.button(c, "blue", prod and ("R$" .. prod.robux) or "R$", function(btn) App.req("buyProduct", { key = "Crate1" }, btn) end,
					{ pos = UDim2.new(0.55, 3, 0, 148), sz = UDim2.new(0.45, -11, 0, 32), z = 10, textSize = 13 })
				hoverBtn(gb); hoverBtn(rb)
			else
				text(c, "LEFT THE SHOP", { font = "heavy", size = 13, color = C.dim, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(6, 152), sz = UDim2.new(1, -12, 0, 22), z = 9 })
			end
		end
		rarityBar(c, isBasic and "SUPPLY" or "LIMITED", rc)
		c.Activated:Connect(function()
			local body2 = isBasic and ("Gear and officers. Bought with cash: about " .. Config.Crates.Basic.lawMinutes .. " minutes of law income at your level.")
				or "Gear or <b>ELITE TROOPS</b>. Elite troops never die in raids. A 10-pack guarantees Epic or better. Buy with gold or Robux. Limited time!"
			local _, bd, close = popup(App, def.name, 460, 250)
			text(bd, body2, { size = 16, wrap = true, rich = true, sz = UDim2.new(1, 0, 1, -54), valign = Enum.TextYAlignment.Top, z = 74 })
			UI.button(bd, "slate", "CLOSE", close, { sz = UDim2.fromOffset(150, 42), pos = UDim2.new(0, 0, 1, -4), anchor = Vector2.new(0, 1), z = 74 })
			local dr = UI.button(bd, "gold", "DROP RATES", function() dropRates(App, kind) end, { sz = UDim2.fromOffset(190, 42), pos = UDim2.new(1, 0, 1, -4), anchor = Vector2.new(1, 1), z = 74, icon = "icon_gauge", textSize = 16 })
			hoverBtn(dr)
		end)
	end

	local function sig(st)
		local inv, cab = invOf(st), cabOf(st)
		local crates = st.crates or {}
		local el = {}
		for k, n in pairs(st.elite or {}) do table.insert(el, tostring(k) .. "=" .. tostring(n)) end
		table.sort(el)
		local parts = { obj.tab, tostring(obj.rar), tostring(crates.basic), tostring(crates.limited), tostring(cab.player.weapon), tostring(cab.player.armor), table.concat(el, ","), "L" .. table.concat(cab.ltd, ","),
			tostring(st.basicCratePrice), (st.cash or 0) >= (st.basicCratePrice or 0) and 1 or 0, (st.gold or 0) >= Config.Crates.Limited.gold and 1 or 0 }
		for i = 1, slotsOf(st) do table.insert(parts, tostring(cab.slots[i])) end
		local ids = {}
		for id, o in pairs(inv.officers) do table.insert(ids, id .. ":" .. tostring(o.weapon) .. ":" .. tostring(o.armor)) end
		for id in pairs(inv.gear) do table.insert(ids, id) end
		table.sort(ids)
		table.insert(parts, table.concat(ids, ","))
		return table.concat(parts, "|")
	end

	function obj:Refresh(st)
		if not st then return end
		local inv = invOf(st)
		local crates = st.crates or {}
		local gearN, offN = 0, 0
		for _ in pairs(inv.gear) do gearN += 1 end
		for _ in pairs(inv.officers) do offN += 1 end
		local crateN = (crates.basic or 0) + (crates.limited or 0)
		sub.Text = "Gear <b>" .. gearN .. "/" .. Config.InventoryMax .. "</b> · Officers <b>" .. offN .. "</b> · Crates <b>" .. crateN .. "</b>"
		local s = sig(st)
		if s == obj.sig then return end
		obj.sig = s
		UI.clear(grid)
		drop.Visible = false
		local tab, rk = obj.tab, obj.rar
		buildStrip(st, (tab == 1 or tab == 5) and not rk)
		local order = 0
		local shown = 0
		-- crates first (only when no rarity filter)
		if (tab == 1 or tab == 5) and not rk then
			for _, kind in ipairs({ "limited", "basic" }) do
				order += 1
				crateCard(kind, crates[kind] or 0, order, st)
				shown += 1
			end
		end
		local items = {}
		if tab <= 3 then
			for _, g in pairs(inv.gear) do
				if (tab == 1 or (tab == 2 and g.kind == "weapon") or (tab == 3 and g.kind == "armor")) and (not rk or g.rarity == rk) then
					table.insert(items, { g = g, r = ridx(g.rarity), p = g.power or 0, n = g.name or "" })
				end
			end
		end
		if tab == 1 or tab == 4 then
			for _, o in pairs(inv.officers) do
				if not rk or o.rarity == rk then table.insert(items, { o = o, r = ridx(o.rarity), p = 0, n = o.name or "" }) end
			end
		end
		table.sort(items, function(a, b)
			if a.r ~= b.r then return a.r > b.r end
			if (a.o ~= nil) ~= (b.o ~= nil) then return a.o == nil end
			if a.p ~= b.p then return a.p > b.p end
			return a.n < b.n
		end)
		local wm, seated, ltd = wearers(st), seatedMap(st), ltdSet(st)
		for _, it in ipairs(items) do
			order += 1
			shown += 1
			if it.g then gearCard(it.g, order, wm) else officerCard(it.o, order, seated, ltd) end
		end
		empty.Visible = #items == 0 and (tab ~= 1 and tab ~= 5 or rk ~= nil)
		if empty.Visible then
			empty.Text = (tab == 4) and "No officers yet. Hire them in the Officers tab or find them in crates."
				or "Nothing here yet. Open crates to find weapons and armor."
		end
	end
	function obj:Opened() obj.sig = nil; if App.state then self:Refresh(App.state) end end
	return obj
end }

-- install the reveal / open-crate / drop-rates hooks at start-up, so the Shop can use them before these screens are built
S._cabinetHooks = { init = function(App) installReveal(App) end }

return S
