-- Map: the CAPITOL screen. One shared pixel-art world map (Kash, 1 Oct 2026): 41 real capitals, territory tints for
-- alliance-held cities, your convoys visibly travelling (Fleet Simulator style), a convoy dock and a city dossier panel
-- listing every load with cost, pay, tax, distance and time. Convoys never fail; they stay where they arrive.
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local T = require(Shared.Trade)
local W = require(Shared.World)
local M = require(Shared.Military)
local Config = require(Shared.Config)

local Map = {}
local OCEAN = Color3.fromRGB(24, 32, 42)
local PERK_TEXT = { law = "law cash", props = "property income", convoy = "convoy pay", regen = "Influence regen", attack = "attack", defense = "defense" }
local TIER_NAME = { "CITY", "CAPITAL", "MAJOR CAPITAL" }
local TIER_PIN = { 20, 24, 28 }
local PERK_SIZE = { 3, 5, 8 }

-- parse territory runs once
local RUNS = {}
for i, c in ipairs(W.Cities) do
	local list = {}
	for y, x0, x1 in string.gmatch(c.runs, "(%d+),(%d+),(%d+)") do table.insert(list, { tonumber(y), tonumber(x0), tonumber(x1) }) end
	RUNS[i] = list
end

function Map.build(host, App)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local obj = {}

	local view = mk("Frame", { Name = "View", BackgroundColor3 = OCEAN, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, ZIndex = 2, Active = true }, host)
	local mapImg = UI.img(view, "map_world", { name = "World", pixel = true, z = 3, slice = false, sz = UDim2.fromOffset(768, 292) })
	local tintLayer = mk("Frame", { Name = "Territory", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, mapImg)
	local routeLayer = mk("Frame", { Name = "Routes", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, mapImg)
	local pinLayer = mk("Frame", { Name = "Pins", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6 }, mapImg)
	local convoyLayer = mk("Frame", { Name = "Convoys", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 8 }, mapImg)

	local zoom, minZoom, maxZoom = 1.5, 1, 7
	local cx, cy = 384, 120 -- map pixel at the centre of the view
	local selected, selConvoy = nil, 1

	local function viewSize() return view.AbsoluteSize / App.root:FindFirstChildOfClass("UIScale").Scale end
	local function clampView()
		local vs = viewSize()
		minZoom = math.max(vs.X / 768, 1)
		zoom = math.clamp(zoom, minZoom, maxZoom)
		local halfW, halfH = vs.X / 2 / zoom, vs.Y / 2 / zoom
		cx = math.clamp(cx, halfW, 768 - halfW)
		if halfH * 2 >= 292 then cy = 146 else cy = math.clamp(cy, halfH, 292 - halfH) end
	end
	local function place()
		clampView()
		local vs = viewSize()
		mapImg.Size = UDim2.fromOffset(768 * zoom, 292 * zoom)
		mapImg.Position = UDim2.fromOffset(vs.X / 2 - cx * zoom, vs.Y / 2 - cy * zoom)
		obj.labels()
	end
	local function toMap(screen)
		local s = App.root:FindFirstChildOfClass("UIScale").Scale
		local rel = (screen - mapImg.AbsolutePosition) / s
		return rel.X / zoom, rel.Y / zoom
	end
	local function at(px, py) return UDim2.fromScale(px / 768, py / 292) end

	---------------------------------------------------------------- territory tints
	local function drawTerritory()
		UI.clear(tintLayer)
		local world = App.world
		local st = App.state
		for i in ipairs(W.Cities) do
			local cs = world and world.cities[i]
			local color, alpha
			if cs and cs.owner and world.alliances[cs.owner] then
				color = Color3.fromHex(world.alliances[cs.owner].color); alpha = 0.5
			elseif st and st.home == i then
				color = C.manila; alpha = 0.72
			end
			if color then
				local holder = mk("Frame", { Name = "T" .. i, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, tintLayer)
				for _, r in ipairs(RUNS[i]) do
					mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = color, BackgroundTransparency = alpha, Position = at(r[2], r[1]), Size = UDim2.fromScale((r[3] - r[2] + 1) / 768, 1 / 292), ZIndex = 4 }, holder)
				end
			end
		end
	end

	---------------------------------------------------------------- pins
	local pins = {}
	local ring = UI.img(pinLayer, "ring", { name = "Ring", sz = UDim2.fromOffset(46, 46), anchor = Vector2.new(0.5, 0.5), z = 6, slice = false, visible = false })
	for i, c in ipairs(W.Cities) do
		local s = TIER_PIN[c.tier]
		local b = UI.img(pinLayer, "pin_neutral", { button = true, name = c.name, pos = at(c.px, c.py), sz = UDim2.fromOffset(s, math.floor(s * 112 / 88)), anchor = Vector2.new(0.5, 0.92), z = 7, slice = false })
		local lbl = text(b, c.name, { font = "heavy", size = 13, align = Enum.TextXAlignment.Center, anchor = Vector2.new(0.5, 0), pos = UDim2.new(0.5, 0, 1, 1), sz = UDim2.fromOffset(160, 15), z = 9, stroke = 1.5 })
		local tag = text(b, "", { font = "heavy", size = 11, align = Enum.TextXAlignment.Center, anchor = Vector2.new(0.5, 1), pos = UDim2.new(0.5, 0, 0, -1), sz = UDim2.fromOffset(80, 13), z = 9, stroke = 1.4, visible = false })
		pins[i] = { Inst = b, Label = lbl, Tag = tag }
		b.Activated:Connect(function() obj.select(i) end)
	end
	function obj.labels()
		for i, p in pairs(pins) do
			local c = W.Cities[i]
			p.Label.Visible = (c.tier == 3 and zoom >= 1.3) or zoom >= 2.6 or selected == i or (App.state and App.state.home == i)
		end
	end
	local function drawPins()
		local world, st = App.world, App.state
		for i, p in ipairs(pins) do
			local cs = world and world.cities[i]
			local a = cs and cs.owner and world.alliances[cs.owner]
			if st and st.home == i then
				p.Inst.Image = UI.asset("pin_home"); p.Inst.ImageColor3 = C.white
			elseif a then
				p.Inst.Image = UI.asset("pin_tint"); p.Inst.ImageColor3 = Color3.fromHex(a.color)
			else
				p.Inst.Image = UI.asset("pin_neutral"); p.Inst.ImageColor3 = C.white
			end
			p.Tag.Visible = a ~= nil
			if a then p.Tag.Text = "[" .. a.tag .. "]" .. ((cs.tax or 0) > 0 and (" " .. cs.tax .. "%") or ""); p.Tag.TextColor3 = Color3.fromHex(a.color):Lerp(C.white, 0.45) end
			p.Label.TextColor3 = (st and st.home == i) and C.manila or C.ink
		end
		obj.labels()
	end

	---------------------------------------------------------------- convoys on the map
	local era = function() return App.state and R.EraOf(App.state.lv) or 1 end
	local convoyIcons, routeDots = {}, {}
	local function vehicleIcon(kind) return T.Vehicle(era(), kind or "land")[2] end
	local function drawConvoyIcons()
		UI.clear(convoyLayer); UI.clear(routeLayer)
		convoyIcons, routeDots = {}, {}
		local st = App.state
		if not st then return end
		local parked = {}
		for i, c in ipairs(st.convoys) do
			local b = UI.img(convoyLayer, vehicleIcon(c.kind or (c.to and T.RouteKind(c.from, c.to)) or "land"), { button = true, name = "Convoy" .. i, sz = UDim2.fromOffset(30, 30), anchor = Vector2.new(0.5, 0.5), z = 10, slice = false })
			local num = UI.badge(b, i, UDim2.new(1, -2, 0, 2), 11)
			num.Size = UDim2.fromOffset(15, 15)
			num:FindFirstChildOfClass("TextLabel").TextSize = 10
			convoyIcons[i] = b
			b.Activated:Connect(function() selConvoy = i; obj.select(c.to or c.at, true) end)
			if c.to then
				-- dotted route from origin to destination
				local dots = {}
				local km = W.Km[c.from][c.to]
				local n = math.clamp(math.floor(km / 250), 6, 60)
				for k = 1, n - 1 do
					local x, y = T.Lerp(c.from, c.to, k / n)
					local d = UI.img(routeLayer, "dot_route", { sz = UDim2.fromOffset(5, 5), anchor = Vector2.new(0.5, 0.5), pos = at(x, y), z = 5, slice = false, color = C.manila, alpha = 0.15 })
					dots[k] = { d, k / n }
				end
				routeDots[i] = dots
			else
				parked[c.at] = (parked[c.at] or 0) + 1
				local k = parked[c.at]
				local cc = W.Cities[c.at]
				b.Position = UDim2.new(cc.px / 768, 12 + (k - 1) * 10, cc.py / 292, -16 - (k - 1) * 4)
				b.Size = UDim2.fromOffset(24, 24)
			end
		end
	end

	-- ambient traffic: other nations' caravans and ships so the world never looks empty
	local ambient = {}
	for k = 1, 16 do
		local b = UI.img(convoyLayer, "convoy_cart", { sz = UDim2.fromOffset(18, 18), anchor = Vector2.new(0.5, 0.5), z = 9, slice = false, alpha = 0.35 })
		ambient[k] = { Inst = b, period = 150 + k * 53 }
	end
	local function ambientPair(k, cycle)
		local seed = (cycle * 7919 + k * 104729) % 2147483647
		local a = seed % #W.Cities + 1
		local best, bestD
		for tries = 1, 6 do
			seed = (seed * 48271) % 2147483647
			local b = seed % #W.Cities + 1
			if b ~= a then
				local d = W.Km[a][b]
				if not bestD or math.abs(d - 2500) < math.abs(bestD - 2500) then best, bestD = b, d end
			end
		end
		return a, best or (a % #W.Cities + 1)
	end

	local function animate()
		local st = App.state
		local now = App.now()
		if st then
			for i, c in ipairs(st.convoys) do
				local b = convoyIcons[i]
				if b and c.to then
					local f = math.clamp((now - c.t0) / math.max(1, c.t1 - c.t0), 0, 1)
					local x, y = T.Lerp(c.from, c.to, f)
					b.Position = at(x, y)
					for _, d in ipairs(routeDots[i] or {}) do d[1].ImageTransparency = d[2] < f and 0.85 or 0.15 end
				end
			end
		end
		for k, a in ipairs(ambient) do
			local cycle = math.floor(now / a.period)
			local f = (now % a.period) / a.period
			local o, d = ambientPair(k, cycle)
			local x, y = T.Lerp(o, d, f)
			a.Inst.Position = at(x, y)
			local kind = T.RouteKind(o, d)
			if a.kind ~= kind or a.era ~= era() then
				a.kind = kind; a.era = era()
				a.Inst.Image = UI.asset(T.Vehicle(math.max(1, era() - 1 + (k % 2)), kind)[2])
			end
		end
		if selected then
			ring.Rotation = (os.clock() * 30) % 360
		end
	end
	RunService.RenderStepped:Connect(function() if host.Visible then animate() end end)

	---------------------------------------------------------------- map controls (drag, wheel, pinch, buttons)
	local dragStart, dragMoved, dragFrom
	view.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStart = Vector2.new(input.Position.X, input.Position.Y); dragFrom = Vector2.new(cx, cy); dragMoved = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local s = App.root:FindFirstChildOfClass("UIScale").Scale
			local delta = (Vector2.new(input.Position.X, input.Position.Y) - dragStart) / s
			if delta.Magnitude > 6 then dragMoved = true end
			if dragMoved then cx = dragFrom.X - delta.X / zoom; cy = dragFrom.Y - delta.Y / zoom; place() end
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if dragStart and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			if not dragMoved and host.Visible then
				-- a tap on the map selects the nearest capital (big targets for phones)
				local mx, my = toMap(Vector2.new(input.Position.X, input.Position.Y))
				local best, bestD
				for i, c in ipairs(W.Cities) do
					local d = math.sqrt((c.px - mx) ^ 2 + (c.py - my) ^ 2)
					if not bestD or d < bestD then best, bestD = i, d end
				end
				if best and bestD * zoom < 40 then obj.select(best) end
			end
			dragStart = nil
		end
	end)
	local function zoomAt(factor, screenPos)
		local mx, my
		if screenPos then mx, my = toMap(screenPos) end
		local old = zoom
		zoom = math.clamp(zoom * factor, minZoom, maxZoom)
		if mx then
			cx = mx - (mx - cx) * old / zoom
			cy = my - (my - cy) * old / zoom
		end
		place()
	end
	view.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			zoomAt(input.Position.Z > 0 and 1.2 or 1 / 1.2, Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
	UIS.TouchPinch:Connect(function(_, scale, _, state)
		if not host.Visible then return end
		if state == Enum.UserInputState.Begin then obj.pinch0 = zoom end
		if obj.pinch0 then zoom = math.clamp(obj.pinch0 * scale, minZoom, maxZoom); place() end
		if state == Enum.UserInputState.End then obj.pinch0 = nil end
	end)

	local tools = mk("Frame", { Name = "Tools", BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(44, 150), ZIndex = 20 }, view)
	local function toolBtn(icon, y, fn)
		local b = UI.button(tools, "slate", "", fn, { sz = UDim2.fromOffset(44, 42), pos = UDim2.fromOffset(0, y), z = 20 })
		UI.icon(b.Face, icon, 20, C.ink, UDim2.fromScale(0.5, 0.5), { anchor = Vector2.new(0.5, 0.5), z = 22 })
		return b
	end
	toolBtn("icon_plus", 0, function() zoomAt(1.4) end)
	toolBtn("icon_minus", 46, function() zoomAt(1 / 1.4) end)
	toolBtn("icon_home", 92, function()
		local h = App.state and W.Cities[App.state.home]
		if h then cx, cy = h.px, h.py; zoom = math.max(zoom, 3); place(); obj.select(App.state.home) end
	end)

	-- era + legend chip (top centre)
	local eraChip, eraLbl = UI.chip(view, "", { pos = UDim2.new(0.5, 0, 0, 10), anchor = Vector2.new(0.5, 0), z = 20, icon = "icon_globe", h = 28, size = 15 })

	---------------------------------------------------------------- convoy dock
	local dock = UI.list(view, { name = "Dock", horizontal = true, pos = UDim2.new(0, 10, 1, -96), sz = UDim2.new(1, -20, 0, 92), gap = 8, z = 20 })
	local function drawDock()
		UI.clear(dock)
		local st = App.state
		if not st then return end
		local now = App.now()
		local auto = st.gp and st.gp.AutoDispatch
		if auto then
			local b = UI.button(dock, st.autoOff and "slate" or "green", st.autoOff and "AUTO: OFF" or "AUTO: ON", function(btn)
				App.req("toggleAuto", {}, btn)
			end, { sz = UDim2.fromOffset(110, 80), z = 21, order = 0, icon = "icon_bot", textSize = 14 })
		end
		for i, c in ipairs(st.convoys) do
			local card = UI.card(dock, { button = true, sz = UDim2.fromOffset(214, 80), z = 21, order = i, hot = (selConvoy == i) })
			local kind = c.kind or "land"
			UI.img(card, vehicleIcon(c.to and kind or "land"), { sz = UDim2.fromOffset(44, 44), pos = UDim2.fromOffset(8, 8), z = 22, slice = false })
			text(card, "CONVOY " .. i, { font = "heavy", size = 14, color = C.manila, pos = UDim2.fromOffset(58, 6), sz = UDim2.new(1, -64, 0, 16), z = 22 })
			local status = text(card, "", { font = "bold", size = 14, pos = UDim2.fromOffset(58, 24), sz = UDim2.new(1, -64, 0, 30), z = 22, wrap = true, valign = Enum.TextYAlignment.Top })
			if c.to then
				local f = math.clamp((now - c.t0) / math.max(1, c.t1 - c.t0), 0, 1)
				status.Text = (c.load and T.GoodName(c.load.good) or "Empty") .. " → " .. W.Cities[c.to].name
				local bar = UI.bar(card, c.load and C.good or C.muted, { pos = UDim2.new(0, 8, 1, -26), sz = UDim2.new(1, -16, 0, 18), z = 22, textSize = 12 })
				bar:Set(f, R.Clock(c.t1 - now), c.load and ("+" .. R.Money(c.load.pay - c.load.tax)) or "")
				obj.dockBars = obj.dockBars or {}
				obj.dockBars[i] = { bar = bar, c = c }
			else
				status.Text = "Idle at " .. W.Cities[c.at].name
				text(card, "Pick a city on the map", { size = 13, color = C.muted, pos = UDim2.new(0, 10, 1, -24), sz = UDim2.new(1, -20, 0, 16), z = 22 })
			end
			card.Activated:Connect(function()
				selConvoy = i
				local target = c.to or c.at
				local cc = W.Cities[target]
				cx, cy = cc.px, cc.py; place()
				obj.select(target, true)
			end)
		end
		-- locked slots: show the next level gate (and the pass) so players know what is coming
		local nextGate
		for _, g in ipairs(R.ConvoySlotLevels) do if g > st.lv then nextGate = g; break end end
		if nextGate then
			local card = UI.card(dock, { sz = UDim2.fromOffset(150, 80), z = 21, order = 50 })
			UI.icon(card, "icon_lock", 22, C.dim, UDim2.fromOffset(10, 10), { z = 22 })
			text(card, "NEXT CONVOY", { font = "heavy", size = 13, color = C.muted, pos = UDim2.fromOffset(38, 12), sz = UDim2.new(1, -44, 0, 16), z = 22 })
			text(card, "Unlocks at level " .. nextGate, { size = 14, pos = UDim2.fromOffset(10, 40), sz = UDim2.new(1, -20, 0, 30), z = 22, wrap = true })
		end
		if not (st.gp and st.gp.ExtraConvoys) then
			local b = UI.button(dock, "gold", "+2 CONVOYS", function(btn) App.req("buyPass", { key = "ExtraConvoys" }, btn) end, { sz = UDim2.fromOffset(140, 80), z = 21, order = 60, icon = "icon_plus", textSize = 14 })
		end
	end
	local function tickDock()
		local now = App.now()
		for _, e in pairs(obj.dockBars or {}) do
			local c = e.c
			if c.to and e.bar.Inst.Parent then
				e.bar:Set(math.clamp((now - c.t0) / math.max(1, c.t1 - c.t0), 0, 1), R.Clock(c.t1 - now), c.load and ("+" .. R.Money(c.load.pay - c.load.tax)) or "")
			end
		end
	end

	---------------------------------------------------------------- city dossier panel
	local panel, pbody = UI.panel(view, "", { sz = UDim2.new(0, 380, 1, -116), pos = UDim2.new(1, -10, 0, 10), anchor = Vector2.new(1, 0), z = 25 })
	panel.Visible = false
	local closeB = UI.button(panel, "slate", "", function() obj.select(nil) end, { sz = UDim2.fromOffset(36, 34), pos = UDim2.new(1, -46, 0, 10), z = 27 })
	UI.icon(closeB.Face, "icon_x", 18, C.ink, UDim2.fromScale(0.5, 0.5), { anchor = Vector2.new(0.5, 0.5), z = 28 })
	local plist = UI.list(pbody, { gap = 8, z = 27 })

	local function section(label, order)
		local f = mk("Frame", { Name = "S_" .. label, BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), ZIndex = 27, LayoutOrder = order }, plist)
		text(f, label, { font = "heavy", size = 13, color = C.muted, sz = UDim2.new(1, 0, 1, 0), z = 27 })
		mk("Frame", { BorderSizePixel = 0, BackgroundColor3 = C.rule, Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), ZIndex = 27 }, f)
		return f
	end
	local function row(h, order)
		return mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h), ZIndex = 27, LayoutOrder = order }, plist)
	end
	local function goodsRow(label, keys, order, hot)
		local f = row(28, order)
		text(f, label, { font = "bold", size = 14, color = C.muted, sz = UDim2.fromOffset(70, 28), z = 28 })
		local hold = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(70, 0), Size = UDim2.new(1, -70, 1, 0), ZIndex = 28 }, f)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, hold)
		for _, k in ipairs(keys) do
			UI.chip(hold, T.GoodName(k), { icon = T.GoodIcon(k), z = 28, h = 24, size = 12, manila = k == hot })
		end
	end

	local function tradeCtx(b)
		local st = App.state
		local cs = App.world and App.world.cities[b]
		local taxPct = (cs and cs.owner and cs.owner ~= st.alliance) and (cs.tax or 0) or 0
		return { lv = st.lv, incHr = st.incHr, day = R.Day(math.floor(App.now())), convoyMult = st.mods.convoy, taxPct = taxPct }
	end

	local function loadRow(order, c, ci, b, L, kind)
		local st = App.state
		local secs = T.TripSeconds(c.at, b, R.EraOf(st.lv), st.gp and st.gp.FastConvoys)
		local card = UI.card(plist, { sz = UDim2.new(1, 0, 0, 96), z = 27, order = order, hot = L.hot })
		UI.icon(card, L.icon, 26, L.hot and C.gold or C.manila, UDim2.fromOffset(10, 10), { z = 28 })
		text(card, L.name, { font = "heavy", size = 17, pos = UDim2.fromOffset(44, 6), sz = UDim2.new(1, -150, 0, 20), z = 28, truncate = true })
		local tags = {}
		if L.demand then table.insert(tags, "<font color='#8fd07a'>WANTED +30%</font>") end
		if L.hot then table.insert(tags, "<font color='#f0c75a'>HOT TODAY +25%</font>") end
		table.insert(tags, L.tons .. " t")
		text(card, table.concat(tags, "  "), { font = "bold", size = 12, rich = true, color = C.muted, pos = UDim2.fromOffset(44, 26), sz = UDim2.new(1, -150, 0, 16), z = 28 })
		local lines = string.format("Cost <b>%s</b>   Pay <b>%s</b>%s", R.Money(L.cost), R.Money(L.pay), L.tax > 0 and string.format("   Tax <font color='#e2696f'>-%s</font>", R.Money(L.tax)) or "")
		text(card, lines, { size = 13, rich = true, pos = UDim2.fromOffset(10, 46), sz = UDim2.new(1, -20, 0, 18), z = 28 })
		text(card, string.format("<font color='#8fd07a'><b>PROFIT %s</b></font>   +%s XP   %s   %s km", R.Money(L.net), R.Short(L.xp), R.Duration(secs), R.Commas(W.Km[c.at][b])), { size = 13, rich = true, pos = UDim2.fromOffset(10, 66), sz = UDim2.new(1, -20, 0, 18), z = 28 })
		local canPay = st.cash >= L.cost
		UI.button(card, canPay and "green" or "locked", "SEND", function(btn)
			local res = App.req("send", { c = ci, b = b, good = L.good, cost = L.cost, tax = L.tax }, btn)
			if res.ok then App.toast("CONVOY " .. ci .. " DISPATCHED", L.name .. " to " .. W.Cities[b].name .. " · arrives in " .. R.Duration(secs), "good") end
		end, { sz = UDim2.fromOffset(92, 36), pos = UDim2.new(1, -100, 0, 8), z = 29, textSize = 15 })
	end

	local function moveRow(order, c, ci, b, label, icon)
		local st = App.state
		local fee = T.MoveFee(c.at, b, st.lv, st.incHr)
		local secs = T.TripSeconds(c.at, b, R.EraOf(st.lv), st.gp and st.gp.FastConvoys)
		local card = UI.card(plist, { sz = UDim2.new(1, 0, 0, 60), z = 27, order = order })
		UI.icon(card, icon, 22, C.muted, UDim2.fromOffset(10, 10), { z = 28 })
		text(card, label, { font = "heavy", size = 15, pos = UDim2.fromOffset(40, 6), sz = UDim2.new(1, -150, 0, 20), z = 28 })
		text(card, "No cargo · fee " .. R.Money(fee) .. " · " .. R.Duration(secs), { size = 13, color = C.muted, pos = UDim2.fromOffset(40, 28), sz = UDim2.new(1, -150, 0, 18), z = 28 })
		UI.button(card, st.cash >= fee and "slate" or "locked", "MOVE", function(btn)
			local res = App.req("move", { c = ci, b = b }, btn)
			if res.ok then App.toast("CONVOY " .. ci .. " ON THE MOVE", "Empty to " .. W.Cities[b].name, "info") end
		end, { sz = UDim2.fromOffset(92, 36), pos = UDim2.new(1, -100, 0, 12), z = 29, textSize = 15 })
	end

	local function bestTrips(order, c, ci)
		local st = App.state
		local list = {}
		local eraN = R.EraOf(st.lv)
		for b = 1, #W.Cities do
			if b ~= c.at then
				local loads = T.Loads(c.at, b, tradeCtx(b))
				local L = loads[1]
				if L then
					local secs = T.TripSeconds(c.at, b, eraN, st.gp and st.gp.FastConvoys)
					table.insert(list, { b = b, L = L, secs = secs, rate = L.net / secs })
				end
			end
		end
		table.sort(list, function(x, y) return x.rate > y.rate end)
		section("BEST TRIPS FROM " .. string.upper(W.Cities[c.at].name), order)
		for k = 1, math.min(4, #list) do
			local e = list[k]
			local card = UI.card(plist, { button = true, sz = UDim2.new(1, 0, 0, 50), z = 27, order = order + k })
			UI.icon(card, e.L.icon, 20, C.manila, UDim2.fromOffset(10, 14), { z = 28 })
			text(card, W.Cities[e.b].name .. " · " .. e.L.name, { font = "heavy", size = 14, pos = UDim2.fromOffset(38, 5), sz = UDim2.new(1, -46, 0, 18), z = 28, truncate = true })
			text(card, string.format("Profit %s · %s · %s/min", R.Money(e.L.net), R.Duration(e.secs), R.Money(e.rate * 60)), { size = 13, color = C.good, pos = UDim2.fromOffset(38, 25), sz = UDim2.new(1, -46, 0, 18), z = 28 })
			card.Activated:Connect(function()
				local cc = W.Cities[e.b]
				cx, cy = cc.px, cc.py; place(); obj.select(e.b)
			end)
		end
	end

	local function drawPanel()
		UI.clear(plist)
		obj.panelBars = {}
		local b = selected
		local st = App.state
		if not b or not st then panel.Visible = false; return end
		panel.Visible = true
		local city = W.Cities[b]
		local cs = App.world and App.world.cities[b] or { hp = M.NeutralGarrison[city.tier], maxHp = M.NeutralGarrison[city.tier], tax = 0 }
		local owner = cs.owner and App.world.alliances[cs.owner]
		panel.Title.Text = string.upper(city.name)
		local o = 0
		local function nx() o += 1; return o end

		local head = row(22, nx())
		text(head, city.country .. " · " .. TIER_NAME[city.tier] .. (st.home == b and " · <font color='#e2cfa3'>YOUR CAPITAL</font>" or ""), { font = "bold", size = 14, color = C.muted, sz = UDim2.fromScale(1, 1), z = 28, rich = true })

		-- control
		local ctl = row(30, nx())
		if owner then
			mk("Frame", { BackgroundColor3 = Color3.fromHex(owner.color), BorderSizePixel = 0, Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(0, 7), ZIndex = 28 }, ctl)
			text(ctl, "[" .. owner.tag .. "] " .. owner.name, { font = "heavy", size = 16, pos = UDim2.fromOffset(24, 0), sz = UDim2.new(1, -120, 1, 0), z = 28, truncate = true })
			UI.chip(ctl, "TAX " .. (cs.tax or 0) .. "%", { icon = "icon_tax", pos = UDim2.new(1, 0, 0, 3), anchor = Vector2.new(1, 0), z = 28, manila = (cs.tax or 0) > 0 })
		else
			text(ctl, "Unclaimed · no tax", { font = "heavy", size = 16, color = C.muted, sz = UDim2.fromScale(1, 1), z = 28 })
		end
		local perk = row(22, nx())
		text(perk, "Holder's perk: +" .. PERK_SIZE[city.tier] .. "% " .. PERK_TEXT[city.perk], { size = 14, color = C.manila, sz = UDim2.fromScale(1, 1), z = 28 })

		goodsRow("EXPORTS", city.exports, nx())
		goodsRow("WANTS", city.demand, nx(), T.HotGood(b, R.Day(math.floor(App.now()))))

		-- convoys
		section("YOUR CONVOYS", nx())
		local chips = row(30, nx())
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, chips)
		selConvoy = math.clamp(selConvoy, 1, math.max(1, #st.convoys))
		for i, c in ipairs(st.convoys) do
			local chip = UI.img(chips, selConvoy == i and "chip_manila" or "chip", { button = true, sz = UDim2.fromOffset(52, 28), z = 28, order = i })
			UI.img(chip, vehicleIcon(c.kind or "land"), { sz = UDim2.fromOffset(20, 20), pos = UDim2.fromOffset(3, 4), z = 29, slice = false })
			text(chip, tostring(i), { font = "heavy", size = 14, color = selConvoy == i and C.manilaInk or C.ink, pos = UDim2.fromOffset(25, 0), sz = UDim2.new(1, -27, 1, 0), z = 29 })
			chip.Activated:Connect(function() selConvoy = i; drawPanel(); drawDock() end)
		end
		local c = st.convoys[selConvoy]
		if c then
			if c.to then
				local info = row(44, nx())
				text(info, (c.load and (T.GoodName(c.load.good) .. " for " .. R.Money(c.load.pay - c.load.tax)) or "Travelling empty") .. "\n" .. W.Cities[c.from].name .. " → " .. W.Cities[c.to].name, { size = 14, sz = UDim2.fromScale(1, 1), z = 28, wrap = true })
				local brow = row(24, nx())
				local bar = UI.bar(brow, C.good, { sz = UDim2.new(1, 0, 1, 0), z = 28, textSize = 13 })
				obj.panelBars.trip = { bar = bar, c = c }
				local fin = row(40, nx())
				local gold = math.max(1, math.ceil((c.t1 - App.now()) / 600))
				UI.button(fin, st.gold >= gold and "gold" or "locked", "FINISH · " .. gold .. " GOLD", function(btn) App.req("finishGold", { c = selConvoy }, btn) end, { sz = UDim2.new(0.5, -4, 1, 0), z = 29, textSize = 14, icon = "icon_gold" })
				local mins = (c.t1 - App.now()) / 60
				local robux
				for _, k in ipairs({ "FinishConvoy1", "FinishConvoy2", "FinishConvoy3", "FinishConvoy4" }) do
					if not robux and mins <= Config.Products[k].maxMinutes then robux = Config.Products[k] end
				end
				local live = robux and robux.id ~= 0
				UI.button(fin, live and "green" or "locked", live and ("FINISH · R$" .. robux.robux) or "R$ COMING SOON", function(btn) App.req("finishRobux", { c = selConvoy }, btn) end, { sz = UDim2.new(0.5, -4, 1, 0), pos = UDim2.new(0.5, 4, 0, 0), z = 29, textSize = 14 })
			elseif c.at == b then
				local info = row(40, nx())
				text(info, "Convoy " .. selConvoy .. " is parked here. Pick another city on the map to see its loads.", { size = 14, color = C.muted, sz = UDim2.fromScale(1, 1), z = 28, wrap = true })
				bestTrips(nx(), c, selConvoy); o += 6
			else
				section("LOADS FROM " .. string.upper(W.Cities[c.at].name) .. " · " .. string.upper(T.RouteKind(c.at, b)) .. " ROUTE", nx())
				local loads = T.Loads(c.at, b, tradeCtx(b))
				for _, L in ipairs(loads) do loadRow(nx(), c, selConvoy, b, L) end
				moveRow(nx(), c, selConvoy, b, "MOVE HERE EMPTY", "icon_right")
				if c.at ~= st.home and b ~= st.home then moveRow(nx(), c, selConvoy, st.home, "RECALL HOME", "icon_home") end
			end
		end

		-- war: garrison, siege, reinforce, tax
		section("GARRISON", nx())
		local grow = row(24, nx())
		local gbar = UI.bar(grow, owner and Color3.fromHex(owner.color) or C.muted, { sz = UDim2.fromScale(1, 1), z = 28, textSize = 13 })
		gbar:Set(cs.hp / math.max(1, cs.maxHp), R.Short(cs.hp) .. " / " .. R.Short(cs.maxHp), (cs.prot or 0) > App.now() and ("PROTECTED " .. R.Clock(cs.prot - App.now())) or "")
		local mine = st.alliance and cs.owner == st.alliance
		local war = row(40, nx())
		if not st.alliance then
			text(war, "Join an alliance to besiege cities.", { size = 14, color = C.muted, sz = UDim2.new(1, -130, 1, 0), z = 28, wrap = true })
			UI.button(war, "slate", "ALLIANCE", function() App.open("alliance") end, { sz = UDim2.fromOffset(120, 38), pos = UDim2.new(1, -120, 0, 0), z = 29, textSize = 14 })
		elseif mine then
			UI.button(war, "blue", "REINFORCE x1", function(btn) local r = App.req("reinforce", { city = b, n = 1 }, btn); if r.ok then App.float(btn.Inst, "+" .. R.Short(r.added), C.blue) end end, { sz = UDim2.new(0.5, -4, 1, 0), z = 29, textSize = 14, icon = "icon_defense" })
			UI.button(war, "blue", "x5", function(btn) local r = App.req("reinforce", { city = b, n = 5 }, btn); if r.ok then App.float(btn.Inst, "+" .. R.Short(r.added), C.blue) end end, { sz = UDim2.new(0.25, -4, 1, 0), pos = UDim2.new(0.5, 4, 0, 0), z = 29, textSize = 14 })
			UI.button(war, "blue", "MAX", function(btn) local r = App.req("reinforce", { city = b, n = 50 }, btn); if r.ok then App.float(btn.Inst, "+" .. R.Short(r.added), C.blue) end end, { sz = UDim2.new(0.25, -4, 1, 0), pos = UDim2.new(0.75, 4, 0, 0), z = 29, textSize = 14 })
			local rec = st.alliance_rec
			local role = rec and rec.members[tostring(game:GetService("Players").LocalPlayer.UserId)]
			role = role and role.role
			if role == "leader" or role == "officer" then
				local tax = row(40, nx())
				obj.taxPick = obj.taxPick or (cs.tax or 0)
				local lbl = text(tax, "", { font = "heavy", size = 16, pos = UDim2.fromOffset(92, 0), sz = UDim2.fromOffset(100, 40), z = 28, align = Enum.TextXAlignment.Center })
				local function show() lbl.Text = "TAX " .. obj.taxPick .. "%" end
				show()
				UI.button(tax, "slate", "-", function() obj.taxPick = math.max(0, obj.taxPick - 1); show() end, { sz = UDim2.fromOffset(40, 38), pos = UDim2.fromOffset(46, 0), z = 29 })
				UI.button(tax, "slate", "+", function() obj.taxPick = math.min(Config.Alliance.TaxMax, obj.taxPick + 1); show() end, { sz = UDim2.fromOffset(40, 38), pos = UDim2.fromOffset(198, 0), z = 29 })
				UI.icon(tax, "icon_tax", 22, C.manila, UDim2.fromOffset(10, 9), { z = 28 })
				UI.button(tax, "manila", "SET", function(btn) local r = App.req("setTax", { city = b, pct = obj.taxPick }, btn); if r.ok then App.toast("Tax in " .. city.name .. " is now " .. r.tax .. "%", "Changes once a day", "good") end end, { sz = UDim2.fromOffset(80, 38), pos = UDim2.new(1, -80, 0, 0), z = 29, textSize = 15 })
			end
		else
			local dmg = st.siege or 0
			local protected = (cs.prot or 0) > App.now()
			UI.button(war, protected and "locked" or "red", "ATTACK · " .. R.Short(dmg), function(btn) local r = App.req("siege", { city = b, n = 1 }, btn); if r.ok then App.float(btn.Inst, "-" .. R.Short(r.dmg), C.bad) end end, { sz = UDim2.new(0.5, -4, 1, 0), z = 29, textSize = 14, icon = "icon_attack" })
			UI.button(war, protected and "locked" or "red", "x5", function(btn) local r = App.req("siege", { city = b, n = 5 }, btn); if r.ok then App.float(btn.Inst, "-" .. R.Short(r.dmg), C.bad) end end, { sz = UDim2.new(0.25, -4, 1, 0), pos = UDim2.new(0.5, 4, 0, 0), z = 29, textSize = 14 })
			UI.button(war, protected and "locked" or "red", "MAX", function(btn) local r = App.req("siege", { city = b, n = 50 }, btn); if r.ok then App.float(btn.Inst, "-" .. R.Short(r.dmg), C.bad) end end, { sz = UDim2.new(0.25, -4, 1, 0), pos = UDim2.new(0.75, 4, 0, 0), z = 29, textSize = 14 })
			local note = row(34, nx())
			text(note, "1 Supply per hit. When the garrison hits 0 the alliance that did the most damage in the last 30 min takes the city.", { size = 12, color = C.muted, sz = UDim2.fromScale(1, 1), z = 28, wrap = true })
		end

		if b ~= st.home then
			local mv = row(40, nx())
			local prod = Config.Products.MoveCapital
			local credit = (st.capitalCredit or 0) > 0
			UI.button(mv, (credit or prod.id ~= 0) and "slate" or "locked", credit and "MAKE THIS MY CAPITAL · FREE MOVE" or (prod.id ~= 0 and ("MAKE THIS MY CAPITAL · R$" .. prod.robux) or "MOVE CAPITAL · COMING SOON"), function(btn)
				local r = App.req("moveCapital", { city = b }, btn)
				if r.ok and r.moved then App.toast("CAPITAL MOVED TO " .. string.upper(city.name), nil, "good") end
			end, { sz = UDim2.fromScale(1, 1), z = 29, textSize = 14, icon = "icon_capitol" })
		end
	end
	local function tickPanel()
		local e = obj.panelBars and obj.panelBars.trip
		if e and e.bar.Inst.Parent and e.c.to then
			local now = App.now()
			e.bar:Set(math.clamp((now - e.c.t0) / math.max(1, e.c.t1 - e.c.t0), 0, 1), "Arrives in " .. R.Clock(e.c.t1 - now), "")
		end
	end

	function obj.select(i, keepConvoy)
		if selected ~= i then obj.taxPick = nil end
		selected = i
		ring.Visible = i ~= nil
		if i then
			local c = W.Cities[i]
			ring.Position = at(c.px, c.py)
			-- if the chosen convoy is parked here, prefer an idle convoy parked elsewhere so loads show at once
			local st = App.state
			local sc = st and st.convoys[selConvoy]
			if st and sc and not keepConvoy and (sc.to or sc.at == i) then
				for k, c2 in ipairs(st.convoys) do if not c2.to and c2.at ~= i then selConvoy = k; break end end
			end
		end
		obj.labels()
		drawPanel()
		drawDock()
	end

	---------------------------------------------------------------- refresh hooks
	local lastConvoyKey
	local function convoyKey(st)
		local parts = {}
		for _, c in ipairs(st.convoys) do table.insert(parts, tostring(c.at) .. ":" .. tostring(c.to) .. ":" .. tostring(c.t1)) end
		return table.concat(parts, "|") .. R.EraOf(st.lv)
	end
	function obj:Refresh(st)
		local key = convoyKey(st)
		if key ~= lastConvoyKey then lastConvoyKey = key; drawConvoyIcons() end
		local e = R.EraOf(st.lv)
		eraLbl.Text = string.upper(require(Shared.GameData).Eras[e].name) .. " ERA · " .. string.upper(T.Vehicle(e, "land")[1]) .. " & " .. string.upper(T.Vehicle(e, "sea")[1])
		drawDock()
		drawPanel()
		drawPins()
		drawTerritory()
	end
	function obj:Tick() tickDock(); tickPanel() end
	App.on("world", function()
		if not App.state then return end
		drawPins(); drawTerritory()
		if host.Visible and selected then drawPanel() end
	end)
	App.on("resize", function() if host.Visible then place() end end)
	view:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
	function obj:Opened()
		task.defer(place)
		if not obj.centred and App.state then
			obj.centred = true
			local h = W.Cities[App.state.home]
			cx, cy = h.px, h.py; zoom = 2.2
			task.defer(place)
		end
	end
	obj.focus = function(i) local c = W.Cities[i]; cx, cy = c.px, c.py; zoom = math.max(zoom, 2.5); place(); obj.select(i) end
	App.focusCity = obj.focus
	place()
	return obj
end

return { map = { build = Map.build } }
