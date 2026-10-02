-- Economy screens: LAWS, PROPERTIES (Your Block + Build, Idle Mafia rework), SKILLS, BANK, TASKS.
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local D = require(Shared.GameData)
local R = require(Shared.Rules)

local S = {}

-- common frame: a folder panel filling the content area with a title and optional subtitle
local function frame(host, App, title)
	local UI = App.UI
	local panel, body = UI.panel(host, title, { sz = UDim2.new(1, -20, 1, -20), pos = UDim2.fromOffset(10, 10), z = 5, titleSize = 26 })
	local sub = UI.text(panel, "", { font = "bold", size = 15, color = UI.C.muted, pos = UDim2.new(0, 18, 0, 16), sz = UDim2.new(1, -36, 0, 22), z = 7, align = Enum.TextXAlignment.Right, rich = true })
	return panel, body, sub
end

---------------------------------------------------------------- LAWS
S.laws = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "LAWS")
	local obj = { era = nil, cards = {} }
	local tabs
	local grid = UI.list(body, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), grid = UDim2.new(1 / 3, -8, 0, 138), gap = 10, z = 6 })

	local function holdRepeat(btn, fn)
		local holding = false
		btn.Inst.MouseButton1Down:Connect(function()
			holding = true
			task.delay(0.45, function()
				while holding and btn.Inst.Parent do
					if not fn(btn, true) then break end
					task.wait(0.12)
				end
			end)
		end)
		btn.Inst.MouseButton1Up:Connect(function() holding = false end)
		btn.Inst.MouseLeave:Connect(function() holding = false end)
	end

	local function updateCard(card, st)
		local L, i = card.L, card.i
		local passes = st.passes[tostring(i)] or 0
		local tier = R.MasteryTier(passes)
		local locked = st.lv < L.lvl
		card.cash.Text = "+" .. R.Money(R.LawCash(i, passes, st.mods.law))
		card.xp.Text = "+" .. R.Short(R.LawXp(i, passes)) .. " XP"
		local nextAt = R.NextMastery(passes)
		if nextAt then
			local prev = R.MasteryAt[tier] or 0
			card.bar:Set((passes - prev) / (nextAt - prev), (tier > 0 and R.MasteryName[tier + 1] or "MASTERY") .. "  " .. passes .. "/" .. nextAt, "+" .. R.MasteryPct[tier + 2] .. "%")
		else
			card.bar:Set(1, "GOLD MASTERY  " .. passes, "+15%")
		end
		card.bar:Color(({ C.dim, Color3.fromHex("c98a4b"), Color3.fromHex("b9c2cc"), C.gold })[tier + 1])
		if card.medals then
			for m, md in ipairs(card.medals) do
				md.ImageColor3 = tier >= m and Color3.new(1, 1, 1) or Color3.fromHex("3a3d42")
				md.ImageTransparency = tier >= m and 0 or 0.25
			end
		end
		if locked then card.btn:Set("locked", "LEVEL " .. L.lvl)
		elseif st.inf < L.cost then card.btn:Set("slate", "PASS")
		else card.btn:Set("green", "PASS") end
	end

	local function build(st)
		UI.clear(grid)
		obj.cards = {}
		local n = 0
		for i, L in ipairs(D.Laws) do
			if L.era == obj.era then
				n += 1
				local card = UI.card(grid, { z = 7, order = i, hot = R.MasteryTier(st.passes[tostring(i)] or 0) == 3 })
				local o = { L = L, i = i }
				text(card, L.n, { font = "heavy", size = 16, pos = UDim2.fromOffset(12, 8), sz = UDim2.new(1, -80, 0, 20), z = 8, truncate = true })
				UI.chip(card, "T" .. L.tier, { pos = UDim2.new(1, -10, 0, 8), anchor = Vector2.new(1, 0), z = 8, h = 20, size = 12 })
				UI.icon(card, "icon_influence", 16, C.inf, UDim2.fromOffset(12, 34), { z = 8 })
				text(card, tostring(L.cost), { font = "heavy", size = 15, color = C.inf, pos = UDim2.fromOffset(32, 32), sz = UDim2.fromOffset(40, 20), z = 8 })
				o.cash = text(card, "", { font = "heavy", size = 15, color = C.good, pos = UDim2.fromOffset(70, 32), sz = UDim2.fromOffset(120, 20), z = 8 })
				o.xp = text(card, "", { font = "heavy", size = 15, color = C.xp, pos = UDim2.new(1, -110, 0, 32), sz = UDim2.fromOffset(100, 20), z = 8, align = Enum.TextXAlignment.Right })
				o.bar = UI.bar(card, C.dim, { pos = UDim2.fromOffset(12, 60), sz = UDim2.new(1, -24, 0, 20), z = 8, textSize = 12 })
				o.btn = UI.button(card, "green", "PASS", nil, { pos = UDim2.new(0, 12, 1, -48), sz = UDim2.new(1, -24, 0, 40), z = 9, textSize = 18 })
				local function pass(btn, repeating)
					local s = App.state
					if s.lv < L.lvl then if not repeating then App.toast("Unlocks at level " .. L.lvl, nil, "bad"); App.shake(btn.Inst) end; return false end
					if s.inf < L.cost then if not repeating then App.toast("Not enough Influence", "Wait for it to refill, or refill with gold in the Shop", "bad"); App.shake(btn.Inst) end; return false end
					local res = App.req("passLaw", { i = i }, not repeating and btn or nil)
					if res.ok then App.float(btn.Inst, "+" .. R.Money(res.cash) .. "  <font color='#b19cff'>+" .. res.xp .. " XP</font>") end
					return res.ok
				end
				o.btn.Inst.Activated:Connect(function() pass(o.btn) end)
				holdRepeat(o.btn, pass)
				obj.cards[i] = o
				updateCard(o, st)
			end
		end
	end

	function obj:Refresh(st)
		local cur = R.EraOf(st.lv)
		local maxTab = math.min(#D.Eras, cur + 1)
		if not tabs or obj.maxTab ~= maxTab then
			if tabs then tabs.Inst:Destroy() end
			local labels = {}
			for e = 1, maxTab do table.insert(labels, string.upper(D.Eras[e].name)) end
			obj.maxTab = maxTab
			tabs = UI.tabs(body, labels, function(i) obj.era = i; build(App.state) end, { w = 132, textSize = 13, z = 7 })
			obj.era = obj.era or cur
			tabs:Set(obj.era)
			build(st)
		end
		for _, card in pairs(obj.cards) do updateCard(card, st) end
		local inf = st.inf .. "/" .. st.infMax
		sub.Text = "Influence <font color='#e0a650'><b>" .. inf .. "</b></font> · 25/50/100 passes = Bronze/Silver/Gold mastery · Gold gives +1 skill point"
	end
	function obj:Opened()
		local cur = R.EraOf(App.state.lv)
		if obj.era ~= cur and tabs then obj.era = cur; tabs:Set(cur); build(App.state) end
	end
	App.on("tick", function(st) if host.Visible then for _, card in pairs(obj.cards) do updateCard(card, st) end end end)
	return obj
end }

---------------------------------------------------------------- PROPERTIES (Kash 16:45: illustrated tiles like the reference)
-- Your Block: square tiles with the isometric building on a dark ground. Hover lifts the building off the ground.
-- Empty lots are FOR SALE (tap to build), lots you have not unlocked are LOCKED behind a fence.
-- Building plays a short construction animation: a tarp-covered frame bobbing with smoke puffs and a BUILDING bar.
S.properties = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local TweenService = game:GetService("TweenService")
	local Config = require(Shared.Config)
	local _, body, sub = frame(host, App, "PROPERTIES")
	local obj = { tab = 1, building = {}, pickLot = nil }
	local list = UI.list(body, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), gap = 10, z = 6 })
	local tabs = UI.tabs(body, { "YOUR BLOCK", "BUILD" }, function(i) obj.tab = i; obj.pickLot = nil; obj:Refresh(App.state) end, { w = 150, z = 7 })
	tabs:Set(1)
	local function tw(o, t, props, style) TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play() end
	local function propImg(p) local P = D.Props[p]; return "prop_e" .. P.era .. "_t" .. P.tier end
	local function plate(parent, s, pos, anchor, z, color)
		local f = UI.mk("Frame", { BackgroundColor3 = Color3.fromHex("121417"), BackgroundTransparency = 0.15, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 22), Position = pos, AnchorPoint = anchor, ZIndex = z }, parent)
		UI.mk("UICorner", { CornerRadius = UDim.new(0, 4) }, f)
		UI.mk("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, f)
		local l = text(f, s, { font = "bold", size = 13, color = color or C.ink, sz = UDim2.new(0, 0, 1, 0), z = z + 1, rich = true })
		l.AutomaticSize = Enum.AutomaticSize.X
		return f, l
	end

	-- one square tile. kind = "owned" | "sale" | "locked"
	local function tile(parent, order, kind)
		local t = UI.mk("ImageButton", { Name = "Lot", AutoButtonColor = false, BackgroundColor3 = C.black, BorderSizePixel = 0, LayoutOrder = order, ZIndex = 7,
			Image = UI.asset(kind == "owned" and "tile_owned" or kind == "sale" and "tile_forsale" or "tile_locked"), ScaleType = Enum.ScaleType.Crop, ClipsDescendants = true }, parent)
		UI.mk("UICorner", { CornerRadius = UDim.new(0, 6) }, t)
		local stroke = UI.mk("UIStroke", { Color = Color3.fromHex("4a4f57"), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, t)
		t.MouseEnter:Connect(function() tw(stroke, 0.15, { Color = C.manila }) end)
		t.MouseLeave:Connect(function() tw(stroke, 0.2, { Color = Color3.fromHex("4a4f57") }) end)
		return t, stroke
	end

	local function construction(t, lot)
		-- bobbing scaffold, smoke puffs, BUILDING bar; then the building pops in on the next refresh
		local site = UI.img(t, "construct", { sz = UDim2.fromScale(0.78, 0.78), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 9, slice = false, fit = true })
		local lbl = text(t, "BUILDING", { font = "heavy", size = 16, color = C.gold, align = Enum.TextXAlignment.Center, pos = UDim2.new(0, 0, 1, -44), sz = UDim2.new(1, 0, 0, 20), z = 11, stroke = 1.2 })
		local track = UI.mk("Frame", { BackgroundColor3 = C.black, BorderSizePixel = 0, Position = UDim2.new(0.12, 0, 1, -20), Size = UDim2.new(0.76, 0, 0, 8), ZIndex = 11 }, t)
		local fill = UI.mk("Frame", { BackgroundColor3 = C.gold, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 12 }, track)
		local dur = 2.4
		local started = obj.building[lot]
		local left = math.max(0.2, dur - (os.clock() - started))
		fill.Size = UDim2.fromScale(1 - left / dur, 1)
		tw(fill, left, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Linear)
		task.spawn(function()
			local up = true
			while site.Parent and os.clock() - started < dur do
				tw(site, 0.3, { Position = UDim2.fromScale(0.5, up and 0.46 or 0.5) }, Enum.EasingStyle.Sine)
				-- a puff of dust drifts up and fades
				local puff = UI.img(t, "smoke_puff", { sz = UDim2.fromScale(0.26, 0.26), pos = UDim2.fromScale(0.25 + math.random() * 0.5, 0.72), anchor = Vector2.new(0.5, 0.5), z = 10, slice = false, fit = true, alpha = 0.15 })
				tw(puff, 0.9, { Position = puff.Position - UDim2.fromScale(0, 0.22), Size = UDim2.fromScale(0.4, 0.4), ImageTransparency = 1 })
				task.delay(1, function() puff:Destroy() end)
				up = not up
				task.wait(0.3)
			end
			obj.building[lot] = nil
			if host.Visible and obj.tab == 1 then obj:Refresh(App.state) end
		end)
		return lbl
	end

	local function lotGrid(st)
		local w = list.AbsoluteSize.X / math.max(0.01, (App.root:FindFirstChildOfClass("UIScale") or { Scale = 1 }).Scale) - 14
		if w < 200 then w = 900 end
		local cols = math.clamp(math.floor(w / 185), 3, 6)
		local cell = math.floor((w - (cols - 1) * 10) / cols)
		-- header stat boxes (income, lots)
		local head = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 74), ZIndex = 6, LayoutOrder = 0 }, list)
		local used = 0
		for k = 1, st.lotsMax do if st.lots[k] and st.lots[k] > 0 then used += 1 end end
		local b1 = UI.card(head, { sz = UDim2.new(0.5, -5, 1, 0), z = 7 })
		text(b1, "INCOME", { font = "bold", size = 13, color = C.muted, pos = UDim2.fromOffset(16, 8), sz = UDim2.new(1, -20, 0, 16), z = 8 })
		text(b1, R.Money(st.incHr) .. "/hr", { font = "display", size = 28, color = C.good, pos = UDim2.fromOffset(16, 26), sz = UDim2.new(1, -20, 0, 32), z = 8 })
		local bonus = math.floor(((st.mods and st.mods.props or 1) - 1) * 100 + 0.5)
		plate(b1, (bonus > 0 and ("+" .. bonus .. "% bonus · ") or "") .. "50% while offline", UDim2.new(1, -12, 0, 10), Vector2.new(1, 0), 9, C.muted)
		local b2 = UI.card(head, { sz = UDim2.new(0.5, -5, 1, 0), pos = UDim2.new(0.5, 5, 0, 0), z = 7 })
		text(b2, "LOTS", { font = "bold", size = 13, color = C.muted, pos = UDim2.fromOffset(16, 8), sz = UDim2.new(1, -20, 0, 16), z = 8 })
		text(b2, used .. " / " .. st.lotsMax, { font = "display", size = 28, pos = UDim2.fromOffset(16, 26), sz = UDim2.new(0.5, 0, 0, 32), z = 8 })
		local free = st.lotsMax - used
		if free > 0 then plate(b2, free .. " OPEN", UDim2.new(1, -12, 0, 10), Vector2.new(1, 0), 9, C.good) end
		local pips = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.45, 0, 0, 44), Size = UDim2.new(0.55, -14, 0, 12), ZIndex = 8 }, b2)
		UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, pips)
		for k = 1, st.lotsMax do
			UI.mk("Frame", { BackgroundColor3 = k <= used and C.gold or C.slate, BorderSizePixel = 0, Size = UDim2.new(1 / st.lotsMax, -3, 1, 0), ZIndex = 9, LayoutOrder = k }, pips)
		end

		local grid = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 6, LayoutOrder = 1 }, list)
		UI.mk("UIGridLayout", { CellSize = UDim2.fromOffset(cell, cell), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
		for k = 1, st.lotsMax do
			local p = st.lots[k]
			if p and p > 0 then
				local P = D.Props[p]
				local t = tile(grid, k, "owned")
				if obj.building[k] then
					construction(t, k)
				else
					local shadow = UI.mk("Frame", { BackgroundColor3 = C.black, BackgroundTransparency = 0.55, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.74), Size = UDim2.fromScale(0.62, 0.16), ZIndex = 8 }, t)
					UI.mk("UICorner", { CornerRadius = UDim.new(1, 0) }, shadow)
					local bld = UI.img(t, propImg(p), { sz = UDim2.fromScale(0.8, 0.8), pos = UDim2.fromScale(0.5, 0.52), anchor = Vector2.new(0.5, 0.5), z = 9, slice = false, fit = true })
					t.MouseEnter:Connect(function()
						tw(bld, 0.18, { Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromScale(0.84, 0.84) }, Enum.EasingStyle.Back)
						tw(shadow, 0.18, { Size = UDim2.fromScale(0.5, 0.12), BackgroundTransparency = 0.72 })
					end)
					t.MouseLeave:Connect(function()
						tw(bld, 0.2, { Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.8, 0.8) })
						tw(shadow, 0.2, { Size = UDim2.fromScale(0.62, 0.16), BackgroundTransparency = 0.55 })
					end)
					t.Activated:Connect(function()
						local s = App.state
						local owned = R.CountProps(s.lots)[p] or 1
						local refund = math.floor(R.PropCost(p, owned - 1) * R.DemolishRefund)
						App.confirm(string.upper(P.n), D.Eras[P.era].name .. " · Tier " .. P.tier .. "\nEarns <font color='#8fd07a'><b>" .. R.Money(P.inc * s.mods.props) .. "/hr</b></font>.\nDemolish it to free the lot and get back <b>" .. R.Money(refund) .. "</b> (25%).", "DEMOLISH", "red", function(btn)
							App.req("demolish", { lot = k }, btn)
						end)
					end)
				end
				plate(t, P.n, UDim2.new(0.5, 0, 0, 8), Vector2.new(0.5, 0), 12)
				if not obj.building[k] then
					plate(t, "<font color='#8fd07a'><b>" .. R.Money(P.inc * st.mods.props) .. "/hr</b></font>", UDim2.new(0.5, 0, 1, -10), Vector2.new(0.5, 1), 12)
				end
			else
				local t = tile(grid, k, "sale")
				local plus = text(t, "+", { font = "heavy", size = 46, color = C.gold, align = Enum.TextXAlignment.Center, pos = UDim2.fromScale(0, 0.18), sz = UDim2.new(1, 0, 0, 50), z = 9 })
				text(t, "FOR SALE", { font = "heavy", size = 22, align = Enum.TextXAlignment.Center, pos = UDim2.fromScale(0, 0.48), sz = UDim2.new(1, 0, 0, 26), z = 9, stroke = 1 })
				text(t, "Tap to Build", { font = "bold", size = 17, color = C.gold, align = Enum.TextXAlignment.Center, pos = UDim2.fromScale(0, 0.62), sz = UDim2.new(1, 0, 0, 22), z = 9 })
				t.MouseEnter:Connect(function() tw(plus, 0.15, { TextSize = 56 }, Enum.EasingStyle.Back) end)
				t.MouseLeave:Connect(function() tw(plus, 0.15, { TextSize = 46 }) end)
				t.Activated:Connect(function() obj.pickLot = k; obj.tab = 2; tabs:Set(2); obj:Refresh(App.state) end)
			end
		end
		-- locked lots: fill out the last row plus one more, like the reference
		local shown = st.lotsMax
		local target = math.ceil((shown + 1) / cols) * cols
		if target - shown < cols then target += cols end
		local nextCost = R.SkillByKey.lot.cost(st.sk.lot or 0)
		for k = shown + 1, target do
			local t = tile(grid, k, "locked")
			if k == shown + 1 then
				text(t, "LOCKED", { font = "heavy", size = 22, align = Enum.TextXAlignment.Center, pos = UDim2.fromScale(0, 0.36), sz = UDim2.new(1, 0, 0, 26), z = 9, stroke = 1 })
				text(t, "Unlock with " .. nextCost .. " Skill Point" .. (nextCost > 1 and "s" or ""), { font = "bold", size = 15, color = C.gold, align = Enum.TextXAlignment.Center, wrap = true, pos = UDim2.fromScale(0.08, 0.5), sz = UDim2.new(0.84, 0, 0, 40), z = 9 })
				t.Activated:Connect(function() App.open("country") end)
			elseif k == shown + 2 and not (st.gp and st.gp.ExtraLots) and Config.Passes.ExtraLots.id ~= 0 then
				text(t, "+3 LOTS", { font = "heavy", size = 22, color = C.gold, align = Enum.TextXAlignment.Center, pos = UDim2.fromScale(0, 0.32), sz = UDim2.new(1, 0, 0, 26), z = 9, stroke = 1 })
				text(t, "Game pass, forever", { font = "bold", size = 14, align = Enum.TextXAlignment.Center, pos = UDim2.fromScale(0, 0.46), sz = UDim2.new(1, 0, 0, 18), z = 9 })
				UI.button(t, "gold", "R$" .. Config.Passes.ExtraLots.price, function(btn) App.req("buyPass", { key = "ExtraLots" }, btn) end, { pos = UDim2.new(0.5, 0, 0.62, 0), anchor = Vector2.new(0.5, 0), sz = UDim2.new(0.7, 0, 0, 36), z = 10, textSize = 15 })
			end
		end
	end

	local function buildList(st)
		local counts = R.CountProps(st.lots)
		local free = 0
		for k = 1, st.lotsMax do if not st.lots[k] or st.lots[k] == 0 then free += 1 end end
		if obj.pickLot then
			local bar = UI.card(list, { sz = UDim2.new(1, 0, 0, 40), z = 7, order = 0, hot = true })
			text(bar, "Choosing a building for <b>lot " .. obj.pickLot .. "</b>", { size = 16, rich = true, pos = UDim2.fromOffset(14, 0), sz = UDim2.new(1, -140, 1, 0), z = 8 })
			UI.button(bar, "slate", "ANY LOT", function() obj.pickLot = nil; obj:Refresh(App.state) end, { pos = UDim2.new(1, -120, 0, 4), sz = UDim2.fromOffset(110, 32), z = 9, textSize = 13 })
		end
		local rows = {}
		for i, P in ipairs(D.Props) do if P.lvl <= st.lv then table.insert(rows, i) end end
		table.sort(rows, function(a, b) return a > b end)
		while #rows > 24 do table.remove(rows) end
		local locked = {}
		for i, P in ipairs(D.Props) do if P.lvl > st.lv and #locked < 3 then table.insert(locked, i) end end
		local order = 0
		local function rowFor(i, isLocked)
			order += 1
			local P = D.Props[i]
			local owned = counts[i] or 0
			local cost = R.PropCost(i, owned)
			local inc = P.inc * st.mods.props
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 84), z = 7, order = isLocked and (1000 + order) or order })
			local thumb = UI.mk("ImageLabel", { BackgroundColor3 = C.black, BorderSizePixel = 0, Image = UI.asset("tile_owned"), ScaleType = Enum.ScaleType.Crop, Position = UDim2.fromOffset(8, 6), Size = UDim2.fromOffset(72, 72), ZIndex = 8 }, card)
			UI.mk("UICorner", { CornerRadius = UDim.new(0, 5) }, thumb)
			UI.img(thumb, "prop_e" .. P.era .. "_t" .. P.tier, { sz = UDim2.fromScale(0.92, 0.92), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 9, slice = false, fit = true, color = isLocked and Color3.fromHex("555555") or nil })
			text(card, P.n .. (owned > 0 and ("  <font color='#9a9fa6'>x" .. owned .. "</font>") or ""), { font = "heavy", size = 18, rich = true, pos = UDim2.fromOffset(92, 12), sz = UDim2.new(0.42, -92, 0, 24), z = 8, truncate = true })
			text(card, D.Eras[P.era].name .. " · Tier " .. P.tier .. (isLocked and (" · unlocks at level " .. P.lvl) or ""), { size = 14, color = C.muted, pos = UDim2.fromOffset(92, 40), sz = UDim2.new(0.45, -92, 0, 18), z = 8 })
			text(card, "+" .. R.Money(inc) .. "/hr", { font = "heavy", size = 18, color = C.good, pos = UDim2.new(0.44, 0, 0, 12), sz = UDim2.new(0.2, 0, 0, 24), z = 8 })
			text(card, "Pays back in " .. R.Duration(cost / math.max(1, inc) * 3600), { size = 14, color = C.muted, pos = UDim2.new(0.44, 0, 0, 40), sz = UDim2.new(0.24, 0, 0, 18), z = 8 })
			local kind = isLocked and "locked" or (free == 0 and "slate") or (st.cash >= cost and "green") or "slate"
			UI.button(card, kind, isLocked and ("LEVEL " .. P.lvl) or ("BUILD " .. R.Money(cost)), function(btn)
				if isLocked then App.toast("Unlocks at level " .. P.lvl, nil, "bad"); App.shake(btn.Inst); return end
				local res = App.req("build", { i = i, lot = obj.pickLot }, btn)
				if res.ok then
					obj.building[res.lot] = os.clock()
					obj.pickLot = nil
					obj.tab = 1; tabs:Set(1)
					obj:Refresh(App.state)
					App.toast(string.upper(P.n) .. " UNDER CONSTRUCTION", "Lot " .. res.lot .. " · +" .. R.Money(inc) .. "/hr", "good")
				end
			end, { pos = UDim2.new(1, -196, 0.5, 0), anchor = Vector2.new(0, 0.5), sz = UDim2.fromOffset(186, 44), z = 9, textSize = 15 })
		end
		for _, i in ipairs(rows) do rowFor(i, false) end
		for _, i in ipairs(locked) do rowFor(i, true) end
	end

	function obj:Refresh(st)
		local y = list.CanvasPosition.Y
		UI.clear(list)
		local used = 0
		for k = 1, st.lotsMax do if st.lots[k] and st.lots[k] > 0 then used += 1 end end
		sub.Text = "Lots <b>" .. used .. "/" .. st.lotsMax .. "</b> · Income <font color='#8fd07a'><b>" .. R.Money(st.incHr) .. "/hr</b></font>"
		if obj.tab == 1 then lotGrid(st) else buildList(st) end
		task.defer(function() list.CanvasPosition = Vector2.new(0, y) end)
	end
	return obj
end }

---------------------------------------------------------------- SKILLS
S.skills = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "SKILL POINTS")
	local list = UI.list(body, { gap = 8, z = 6 })
	local obj = {}
	local function effect(s, n, st)
		if s.key == "inf" then return "Max Influence " .. R.MaxInfluence(st.lv, st.sk) end
		if s.key == "sup" then return "Max Supply " .. R.MaxSupply(st.lv, st.sk) end
		if s.key == "atk" then return "+" .. (n * 4) .. " attack" end
		if s.key == "def" then return "+" .. (n * 4) .. " defense" end
		return st.lotsMax .. " building lots"
	end
	function obj:Refresh(st)
		UI.clear(list)
		sub.Text = "<font color='#f0c75a'><b>" .. st.skillFree .. " POINTS FREE</b></font> · +3 every level · +1 for every law at Gold mastery (" .. st.goldLaws .. " so far)"
		for k, s in ipairs(R.Skills) do
			local n = st.sk[s.key] or 0
			local cost = s.cost(n)
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 76), z = 7, order = k })
			UI.icon(card, s.icon, 34, C.manila, UDim2.fromOffset(14, 20), { z = 8 })
			text(card, s.name, { font = "display", size = 21, pos = UDim2.fromOffset(62, 8), sz = UDim2.new(0.5, -62, 0, 26), z = 8 })
			text(card, s.desc, { size = 14, color = C.muted, pos = UDim2.fromOffset(62, 38), sz = UDim2.new(0.5, -62, 0, 20), z = 8 })
			text(card, "LEVEL " .. n, { font = "heavy", size = 16, color = C.manila, pos = UDim2.new(0.5, 0, 0, 12), sz = UDim2.new(0.25, 0, 0, 20), z = 8 })
			text(card, effect(s, n, st), { size = 14, pos = UDim2.new(0.5, 0, 0, 38), sz = UDim2.new(0.28, 0, 0, 20), z = 8 })
			UI.button(card, st.skillFree >= cost and "gold" or "locked", "+1 · " .. cost .. " PT" .. (cost > 1 and "S" or ""), function(btn)
				local res = App.req("skill", { key = s.key }, btn)
				if res.ok then App.float(btn.Inst, s.name .. " UP", C.gold) end
			end, { pos = UDim2.new(1, -176, 0, 16), sz = UDim2.fromOffset(164, 44), z = 9, textSize = 16 })
		end
	end
	return obj
end }

---------------------------------------------------------------- BANK (vault + loan + national record)
-- Kash 1 Oct: deposits cost 10%, withdrawals are free, 1.5%/h interest (half offline), no cap, raids can't touch it,
-- you can't spend straight from the bank.
S.bank = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local Config = require(Shared.Config)
	local _, body, sub = frame(host, App, "NATIONAL BANK")
	local obj = {}
	local vault = UI.card(body, { sz = UDim2.new(0.5, -6, 0, 300), z = 6 })
	local left = UI.card(body, { sz = UDim2.new(0.5, -6, 1, -310), pos = UDim2.fromOffset(0, 310), z = 6 })
	local right = UI.card(body, { sz = UDim2.new(0.5, -6, 1, 0), pos = UDim2.new(0.5, 6, 0, 0), z = 6 })
	local balance, rateL
	local function buildVault(st)
		UI.clear(vault)
		UI.icon(vault, "icon_bank", 30, C.gold, UDim2.fromOffset(16, 14), { z = 7 })
		text(vault, "THE VAULT", { font = "display", size = 22, pos = UDim2.fromOffset(56, 14), sz = UDim2.new(1, -110, 0, 30), z = 7 })
		local info = UI.img(vault, "chip", { button = true, sz = UDim2.fromOffset(28, 28), pos = UDim2.new(1, -40, 0, 14), z = 8 })
		text(info, "i", { font = "heavy", size = 17, color = C.gold, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 9 })
		info.Activated:Connect(function()
			App.confirm("HOW THE BANK WORKS", "• Banked cash <b>can't be stolen</b> in raids.\n• Depositing costs a <b>" .. math.floor(Config.Bank.DepositFee * 100) .. "% fee</b>. Withdrawing is free.\n• It earns <b>" .. (Config.Bank.InterestPerHour * 100) .. "% interest per hour</b> (half while you're offline), with no cap.\n• You can't buy things straight from the bank: withdraw first.", "GOT IT", "manila", function() end)
		end)
		balance = text(vault, R.Money(st.bank or 0), { font = "display", size = 38, color = C.gold, pos = UDim2.fromOffset(16, 52), sz = UDim2.new(1, -32, 0, 44), z = 7 })
		rateL = text(vault, "", { size = 15, color = C.muted, rich = true, pos = UDim2.fromOffset(16, 98), sz = UDim2.new(1, -32, 0, 20), z = 7 })
		text(vault, "DEPOSIT  <font color='#9a9fa6'>(" .. math.floor(Config.Bank.DepositFee * 100) .. "% fee)</font>", { font = "heavy", size = 14, rich = true, pos = UDim2.fromOffset(16, 130), sz = UDim2.new(1, -32, 0, 18), z = 7 })
		local row = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 152), Size = UDim2.new(1, -32, 0, 44), ZIndex = 7 }, vault)
		UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, row)
		for k, f in ipairs({ 0.25, 0.5, 1 }) do
			UI.button(row, "green", f == 1 and "ALL" or (math.floor(f * 100) .. "%"), function(btn)
				local amt = math.floor(App.state.cash * f)
				if amt <= 0 then App.toast("No cash on hand", nil, "bad"); App.shake(btn.Inst); return end
				local res = App.req("deposit", { amount = amt }, btn)
				if res.ok then App.float(btn.Inst, "+" .. R.Money(res.deposited) .. " banked", C.gold) end
			end, { sz = UDim2.new(1 / 3, -6, 1, 0), z = 8, order = k, textSize = 16 })
		end
		text(vault, "WITHDRAW  <font color='#9a9fa6'>(free)</font>", { font = "heavy", size = 14, rich = true, pos = UDim2.fromOffset(16, 208), sz = UDim2.new(1, -32, 0, 18), z = 7 })
		local row2 = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 230), Size = UDim2.new(1, -32, 0, 44), ZIndex = 7 }, vault)
		UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, row2)
		for k, f in ipairs({ 0.25, 0.5, 1 }) do
			UI.button(row2, "manila", f == 1 and "ALL" or (math.floor(f * 100) .. "%"), function(btn)
				local amt = math.floor((App.state.bank or 0) * f)
				if amt <= 0 then App.toast("The vault is empty", nil, "bad"); App.shake(btn.Inst); return end
				local res = App.req("withdraw", { amount = amt }, btn)
				if res.ok then App.float(btn.Inst, "+" .. R.Money(res.withdrawn), C.good) end
			end, { sz = UDim2.new(1 / 3, -6, 1, 0), z = 8, order = k, textSize = 16 })
		end
	end
	local function tickVault(st)
		if not balance then return end
		local b = st.bank or 0
		balance.Text = R.Money(b)
		local rate = st.bankRate or Config.Bank.InterestPerHour
		rateL.Text = "<font color='#8fd07a'><b>+" .. R.Money(b * rate) .. "/hr</b></font> interest (" .. (math.floor(rate * 1000 + 0.5) / 10) .. "%/h) · safe from raids"
	end
	function obj:Refresh(st)
		buildVault(st); tickVault(st)
		UI.clear(left); UI.clear(right)
		sub.Text = "Cash on hand <font color='#8fd07a'><b>" .. R.Money(st.cash) .. "</b></font> · Banked <font color='#f0c75a'><b>" .. R.Money(st.bank or 0) .. "</b></font>"
		UI.icon(left, "icon_coins", 26, C.manila, UDim2.fromOffset(16, 12), { z = 7 })
		text(left, "STATE LOAN", { font = "display", size = 20, pos = UDim2.fromOffset(52, 12), sz = UDim2.new(1, -70, 0, 26), z = 7 })
		if st.loan then
			local total = math.floor(st.loan.amt * 1.1)
			text(left, "You owe <b>" .. R.Money(st.loan.owed) .. "</b>. 20% of what you earn repays it.", { size = 15, rich = true, wrap = true, pos = UDim2.fromOffset(16, 44), sz = UDim2.new(1, -32, 0, 40), z = 7, valign = Enum.TextYAlignment.Top })
			local bar = UI.bar(left, C.good, { pos = UDim2.fromOffset(16, 88), sz = UDim2.new(1, -32, 0, 22), z = 7 })
			bar:Set(1 - st.loan.owed / math.max(1, total), "REPAID " .. math.floor((1 - st.loan.owed / math.max(1, total)) * 100) .. "%", "")
			UI.button(left, st.cash > 0 and "manila" or "locked", "REPAY " .. R.Money(math.min(st.cash, st.loan.owed)), function(btn) App.req("loanRepay", {}, btn) end, { pos = UDim2.new(0, 16, 1, -54), sz = UDim2.new(1, -32, 0, 40), z = 8 })
		else
			text(left, "Borrow <b>" .. R.Money(st.loanMax) .. "</b> now, pay back 110% from what you earn.", { size = 15, rich = true, wrap = true, pos = UDim2.fromOffset(16, 44), sz = UDim2.new(1, -32, 0, 40), z = 7, valign = Enum.TextYAlignment.Top })
			UI.button(left, st.lv >= 3 and "green" or "locked", st.lv >= 3 and ("BORROW " .. R.Money(st.loanMax)) or "UNLOCKS AT LEVEL 3", function(btn)
				App.confirm("TAKE THE LOAN?", "Borrow <b>" .. R.Money(App.state.loanMax) .. "</b> and repay <b>" .. R.Money(math.floor(App.state.loanMax * 1.1)) .. "</b>.", "BORROW", "green", function()
					App.req("loanTake", {}, btn)
				end)
			end, { pos = UDim2.new(0, 16, 1, -54), sz = UDim2.new(1, -32, 0, 40), z = 8 })
		end
		UI.icon(right, "icon_book", 28, C.manila, UDim2.fromOffset(16, 16), { z = 7 })
		text(right, "NATIONAL RECORD", { font = "display", size = 22, pos = UDim2.fromOffset(56, 16), sz = UDim2.new(1, -70, 0, 30), z = 7 })
		local s = st.stats
		local lines = {
			{ "Total earned", R.Money(s.earned) }, { "Laws passed", R.Commas(s.laws) }, { "Convoy deliveries", R.Commas(s.trips) },
			{ "Raids won", R.Commas(s.wins) .. " / " .. R.Commas(s.battles) }, { "Cash stolen in raids", R.Money(s.stolen or 0) }, { "Times raided", R.Commas(s.raided or 0) },
			{ "Cash lost to raids", R.Money(s.lost or 0) }, { "Bosses defeated", R.Commas(s.bosses) }, { "Properties built", R.Commas(s.built) },
			{ "Property income", R.Money(st.incHr) .. "/hr" }, { "Attack / Defense", R.Short(st.atk) .. " / " .. R.Short(st.def) },
		}
		for k, l in ipairs(lines) do
			local y = 56 + (k - 1) * 28
			text(right, l[1], { size = 16, color = C.muted, pos = UDim2.fromOffset(20, y), sz = UDim2.new(0.55, -20, 0, 24), z = 7 })
			text(right, l[2], { font = "heavy", size = 16, pos = UDim2.new(0.55, 0, 0, y), sz = UDim2.new(0.45, -20, 0, 24), z = 7, align = Enum.TextXAlignment.Right })
		end
	end
	function obj:Tick(st) if st then tickVault(st) end end
	return obj
end }

---------------------------------------------------------------- TASKS
S.tasks = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "DAILY ORDERS")
	local list = UI.list(body, { gap = 10, z = 6 })
	local obj = {}
	local POOL = {
		laws = { "Pass 40 laws", "icon_laws" }, trips = { "Deliver 4 convoy loads", "icon_package" }, wins = { "Win 3 battles", "icon_battle" },
		build = { "Build 2 properties", "icon_properties" }, hits = { "Hit a boss or city 8 times", "icon_attack" }, units = { "Recruit 5 units", "icon_military" },
	}
	function obj:Refresh(st)
		UI.clear(list)
		local t = st.tasks
		if not t then return end
		for i, task in ipairs(t.list) do
			local info = POOL[task.key] or { task.key, "icon_check" }
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 84), z = 7, order = i, hot = task.have >= task.n and not task.done })
			UI.icon(card, info[2], 32, C.manila, UDim2.fromOffset(16, 26), { z = 8 })
			text(card, info[1], { font = "display", size = 20, pos = UDim2.fromOffset(62, 10), sz = UDim2.new(1, -260, 0, 26), z = 8 })
			local bar = UI.bar(card, C.good, { pos = UDim2.fromOffset(62, 44), sz = UDim2.new(1, -270, 0, 24), z = 8 })
			bar:Set(task.have / task.n, task.have .. " / " .. task.n, "+" .. st.taskReward.gold .. " gold · +" .. R.Money(st.taskReward.cash))
			local kind = task.done and "locked" or (task.have >= task.n and "gold" or "slate")
			UI.button(card, kind, task.done and "CLAIMED" or "CLAIM", function(btn)
				local res = App.req("taskClaim", { i = i }, btn)
				if res.ok then App.float(btn.Inst, "+" .. res.gold .. " gold", C.gold) end
			end, { pos = UDim2.new(1, -186, 0, 20), sz = UDim2.fromOffset(170, 44), z = 9 })
		end
		local all = true
		for _, task in ipairs(t.list) do if not task.done then all = false end end
		local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 70), z = 7, order = 10 })
		UI.icon(card, "icon_gift", 30, C.gold, UDim2.fromOffset(16, 20), { z = 8 })
		text(card, "ALL THREE DONE: +5 GOLD", { font = "display", size = 20, color = C.gold, pos = UDim2.fromOffset(62, 0), sz = UDim2.new(1, -260, 1, 0), z = 8 })
		UI.button(card, t.bonus and "locked" or (all and "gold" or "slate"), t.bonus and "CLAIMED" or "CLAIM", function(btn) App.req("taskBonus", {}, btn) end, { pos = UDim2.new(1, -186, 0, 13), sz = UDim2.fromOffset(170, 44), z = 9 })
		obj.subBase = "New orders every day at 00:00 UTC"
	end
	function obj:Tick()
		local now = App.now()
		local left = 86400 - (now % 86400)
		sub.Text = (obj.subBase or "") .. " · next in " .. R.Clock(left)
	end
	return obj
end }

return S
