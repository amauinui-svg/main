-- Onboard: found your country. Name (filtered by Roblox), flag, form of government, home capital.
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local W = require(Shared.World)
local Config = require(Shared.Config)

local O = {}
local PERK_TEXT = { law = "law cash", props = "property income", convoy = "convoy pay", regen = "Influence regen", attack = "attack", defense = "defense" }
local SUGGEST = { "Avalon", "Novaria", "Eldoria", "Valdris", "Corvania", "Solmere", "Ironvale", "Astoria", "Brightwater", "Kestrel", "Marisol", "Northmark" }

function O.show(App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local form = { name = "", flag = { l = "h3", c = { "1f3a93", "ecf0f1", "c0392b" } }, ideo = "republic", home = ((App.world and App.world.popular) or Config.PopularCapitals)[1] or 12 }
	local cover = UI.mk("TextButton", { Name = "Onboard", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromHex("101317"), BackgroundTransparency = 0.05, Size = UDim2.fromScale(1, 1), ZIndex = 60 }, App.root)
	local panel, body = UI.panel(cover, "FOUND YOUR COUNTRY", { sz = UDim2.fromOffset(760, 560), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 61, titleSize = 28 })
	local fit = UI.mk("UISizeConstraint", { MaxSize = Vector2.new(760, 560) }, panel)
	panel.Size = UDim2.new(1, -40, 1, -40)
	local stepLbl = text(panel, "", { font = "bold", size = 15, color = C.muted, pos = UDim2.new(0, 18, 0, 16), sz = UDim2.new(1, -36, 0, 22), z = 63, align = Enum.TextXAlignment.Right })
	local area = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -60), ZIndex = 62 }, body)
	local nav = UI.mk("Frame", { Name = "NavRow", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -52), Size = UDim2.new(1, 0, 0, 52), ZIndex = 62 }, body)
	local step = 1
	local draw
	local obPassSeen = false

	local back = UI.button(nav, "slate", "BACK", function() if step > 1 then step -= 1; draw() end end, { sz = UDim2.fromOffset(140, 46), z = 63 })
	local nextB = UI.button(nav, "manila", "NEXT", nil, { name = "NextBtn", sz = UDim2.fromOffset(220, 46), pos = UDim2.new(1, -220, 0, 0), z = 63 })

	local function preview(parent, pos)
		local holder = UI.mk("Frame", { BackgroundTransparency = 1, Position = pos, Size = UDim2.fromOffset(200, 132), ZIndex = 63 }, parent)
		UI.flag(holder, form.flag, 200, { z = 64 })
		return holder
	end

	local steps = {}
	steps[1] = function()
		text(area, "What is your country called?", { font = "display", size = 24, pos = UDim2.fromOffset(4, 10), sz = UDim2.new(1, 0, 0, 30), z = 63 })
		text(area, "3 to 22 letters. Everyone sees it on the rankings and in alliances.", { size = 15, color = C.muted, pos = UDim2.fromOffset(4, 44), sz = UDim2.new(1, 0, 0, 20), z = 63 })
		local box = UI.img(area, "input", { pos = UDim2.fromOffset(4, 80), sz = UDim2.new(1, -170, 0, 52), z = 63 })
		local tb = UI.mk("TextBox", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0), Text = form.name, PlaceholderText = "Republic of ...",
			PlaceholderColor3 = C.dim, TextColor3 = C.ink, FontFace = UI.Font.bold, TextSize = 24, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = 64 }, box)
		tb:GetPropertyChangedSignal("Text"):Connect(function()
			if #tb.Text > 22 then tb.Text = tb.Text:sub(1, 22) end
			form.name = tb.Text
		end)
		UI.button(area, "slate", "SUGGEST", function()
			tb.Text = ({ "Republic of ", "Kingdom of ", "", "United States of ", "Federation of " })[math.random(1, 5)] .. SUGGEST[math.random(1, #SUGGEST)]
		end, { sz = UDim2.fromOffset(150, 52), pos = UDim2.new(1, -150, 0, 80), z = 63, icon = "icon_sparkles", textSize = 15 })
		text(area, "You start as a small, poor nation in the Ancient era. Pass laws for cash and XP, build properties for income, run trade convoys between the world's capitals, and join an alliance to fight for cities.", { size = 16, wrap = true, color = C.ink, pos = UDim2.fromOffset(4, 160), sz = UDim2.new(1, -8, 0, 90), z = 63, valign = Enum.TextYAlignment.Top })
		return function()
			local n = form.name:gsub("^%s+", ""):gsub("%s+$", "")
			if #n < 3 then App.toast("Name must be at least 3 letters", nil, "bad"); App.shake(box); return false end
			return true
		end
	end
	steps[2] = function()
		-- Kash 2 Oct 23:23: the Custom Flag pass is offered right here, with its extra options shown (locked until owned)
		local owned = App.state and App.state.gp and App.state.gp.CustomFlag
		local passInfo = Config.Passes.CustomFlag or { price = 99 }
		local basicL, basicC = {}, {}
		for _, l in ipairs(R.FlagLayouts) do basicL[l] = true end
		for _, c in ipairs(R.FlagColors) do basicC[c] = true end
		local function buyPass() task.spawn(function() App.req("buyPass", { key = "CustomFlag" }) end) end
		local function lockMark(parent, z)
			local lk = UI.mk("Frame", { BackgroundColor3 = C.black, BackgroundTransparency = 0.45, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = z }, parent)
			UI.icon(lk, "icon_lock", 14, C.gold, UDim2.fromScale(0.5, 0.5), { z = z + 1, anchor = Vector2.new(0.5, 0.5) })
		end
		text(area, "Design your flag", { font = "display", size = 24, pos = UDim2.fromOffset(4, 6), sz = UDim2.new(1, 0, 0, 30), z = 63 })
		local prev = preview(area, UDim2.new(1, -210, 0, 46))
		local lay = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 42), Size = UDim2.new(1, -230, 0, 84), ZIndex = 63 }, area)
		UI.mk("UIGridLayout", { CellSize = UDim2.fromOffset(52, 38), CellPadding = UDim2.fromOffset(5, 6), SortOrder = Enum.SortOrder.LayoutOrder }, lay)
		for li, l in ipairs(R.FlagLayoutsAll or R.FlagLayouts) do
			local locked = not basicL[l] and not owned
			local b = UI.mk("TextButton", { LayoutOrder = li, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, ZIndex = 63 }, lay)
			UI.flag(b, { l = l, c = form.flag.c }, 50, { z = 64, pos = UDim2.fromOffset(1, 2) })
			if locked then lockMark(b, 66) end
			if form.flag.l == l then UI.mk("Frame", { BackgroundColor3 = C.manila, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 3), ZIndex = 64 }, b) end
			b.Activated:Connect(function() if locked then buyPass() else form.flag.l = l; draw() end end)
		end
		local cols = R.FlagColorsAll or R.FlagColors
		for row = 1, 3 do
			local y = 134 + (row - 1) * 40
			text(area, ({ "MAIN", "SECOND", "THIRD" })[row], { font = "heavy", size = 13, color = C.muted, pos = UDim2.fromOffset(4, y), sz = UDim2.fromOffset(62, 34), z = 63 })
			local sw = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(66, y), Size = UDim2.new(1, -296, 0, 34), ZIndex = 63 }, area)
			UI.mk("UIGridLayout", { CellSize = UDim2.new(1 / #cols, -2, 1, 0), CellPadding = UDim2.fromOffset(2, 0), SortOrder = Enum.SortOrder.LayoutOrder }, sw)
			for ci, col in ipairs(cols) do
				local locked = not basicC[col] and not owned
				local s2 = UI.mk("TextButton", { LayoutOrder = ci, Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromHex(col), ZIndex = 64, BorderSizePixel = 0 }, sw)
				UI.mk("UIStroke", { Color = C.black, Thickness = 1 }, s2)
				if locked then lockMark(s2, 65) end
				if form.flag.c[row] == col then UI.icon(s2, "icon_check", 14, (col == "ecf0f1" or col == "f1c40f" or col == "f5deb3" or col == "c0c0c0") and C.black or C.white, UDim2.fromScale(0.5, 0.5), { anchor = Vector2.new(0.5, 0.5), z = 66 }) end
				s2.Activated:Connect(function() if locked then buyPass() else form.flag.c[row] = col; draw() end end)
			end
		end
		-- emblems (pass)
		local ey = 258
		text(area, "EMBLEM", { font = "heavy", size = 13, color = C.muted, pos = UDim2.fromOffset(4, ey), sz = UDim2.fromOffset(62, 34), z = 63 })
		local em = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(66, ey), Size = UDim2.new(1, -296, 0, 34), ZIndex = 63 }, area)
		UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, em)
		local emblems = { false }
		for _, e in ipairs(R.FlagEmblems or {}) do table.insert(emblems, e) end
		for ei, e in ipairs(emblems) do
			local b = UI.mk("TextButton", { LayoutOrder = ei, Text = e and "" or "NONE", FontFace = UI.Font.heavy, TextSize = 10, TextColor3 = C.muted, AutoButtonColor = false, BackgroundColor3 = C.slate, BorderSizePixel = 0, Size = UDim2.fromOffset(34, 34), ZIndex = 64 }, em)
			UI.mk("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
			if (form.flag.e or false) == e then UI.mk("UIStroke", { Color = C.manila, Thickness = 2 }, b) end
			if e then UI.icon(b, e, 22, C.ink, UDim2.fromScale(0.5, 0.5), { z = 65, anchor = Vector2.new(0.5, 0.5) }) end
			local locked = e and not owned
			if locked then lockMark(b, 66) end
			b.Activated:Connect(function() if locked then buyPass() else form.flag.e = e or nil; draw() end end)
		end
		UI.button(area, "slate", "RANDOM", function()
			local L = owned and (R.FlagLayoutsAll or R.FlagLayouts) or R.FlagLayouts
			local Cc = owned and (R.FlagColorsAll or R.FlagColors) or R.FlagColors
			form.flag.l = L[math.random(1, #L)]
			for k = 1, 3 do form.flag.c[k] = Cc[math.random(1, #Cc)] end
			draw()
		end, { sz = UDim2.fromOffset(200, 40), pos = UDim2.new(1, -210, 0, 186), z = 63, icon = "icon_sparkles", textSize = 15 })
		-- the pass offer
		local offer = UI.card(area, { pos = UDim2.fromOffset(4, 306), sz = UDim2.new(1, -8, 0, 64), z = 63, hot = true })
		UI.icon(offer, "icon_flag", 30, C.gold, UDim2.new(0, 14, 0.5, 0), { z = 64, anchor = Vector2.new(0, 0.5) })
		if owned then
			text(offer, "<b>CUSTOM FLAG</b> unlocked: every layout, colour and emblem is yours.", { size = 16, rich = true, pos = UDim2.fromOffset(56, 0), sz = UDim2.new(1, -70, 1, 0), z = 64 })
		else
			text(offer, "<font color='#f0c75a'><b>CUSTOM FLAG</b></font>: 6 more layouts, 12 more colours, emblems, or your own image.", { size = 15, rich = true, wrap = true, pos = UDim2.fromOffset(56, 0), sz = UDim2.new(1, -250, 1, 0), z = 64 })
			UI.button(offer, "gold", "UNLOCK · R$ " .. (passInfo.price or 99), function() buyPass() end, { pos = UDim2.new(1, -10, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(176, 44), z = 65, textSize = 15 })
		end
		local _ = prev
		return function() return true end
	end
	steps[3] = function()
		text(area, "Choose your form of government (you can change it later)", { font = "display", size = 24, pos = UDim2.fromOffset(4, 10), sz = UDim2.new(1, 0, 0, 30), z = 63 })
		local grid = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 54), Size = UDim2.new(1, -8, 1, -60), ZIndex = 63 }, area)
		UI.mk("UIGridLayout", { CellSize = UDim2.new(1 / 3, -8, 0, 132), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
		local icons = { republic = "icon_landmark", monarchy = "icon_crown", federation = "icon_globe", junta = "icon_military", theocracy = "icon_sparkles", technocracy = "icon_rocket" }
		for k, d in ipairs(R.Ideologies) do
			local card = UI.card(grid, { button = true, z = 64, hot = form.ideo == d.key, order = k })
			UI.icon(card, icons[d.key], 36, form.ideo == d.key and C.gold or C.manila, UDim2.fromOffset(16, 16), { z = 65 })
			text(card, d.name, { font = "display", size = 20, pos = UDim2.fromOffset(62, 14), sz = UDim2.new(1, -70, 0, 26), z = 65, scaled = true })
			text(card, d.desc, { font = "heavy", size = 16, color = C.good, wrap = true, pos = UDim2.fromOffset(62, 44), sz = UDim2.new(1, -70, 0, 40), z = 65, valign = Enum.TextYAlignment.Top })
			text(card, d.flavor or "", { size = 14, color = C.muted, wrap = true, pos = UDim2.fromOffset(14, 88), sz = UDim2.new(1, -24, 0, 36), z = 65, valign = Enum.TextYAlignment.Top })
			card.Activated:Connect(function() form.ideo = d.key; draw() end)
		end
		return function() return true end
	end
	steps[4] = function()
		text(area, "Pick your home capital", { font = "display", size = 24, pos = UDim2.fromOffset(4, 10), sz = UDim2.new(1, 0, 0, 30), z = 63 })
		text(area, "Your first convoy starts here and every new convoy is built here. You can trade with every city either way.", { size = 15, color = C.muted, wrap = true, pos = UDim2.fromOffset(4, 42), sz = UDim2.new(1, 0, 0, 40), z = 63 })
		local list = UI.list(area, { pos = UDim2.fromOffset(0, 86), sz = UDim2.new(1, 0, 1, -86), gap = 8, z = 63 })
		local popular = (App.world and App.world.popular) or Config.PopularCapitals
		local function cityCard(parent, i, order, hot)
			local c = W.Cities[i]
			local card = UI.card(parent, { button = true, z = 64, order = order, hot = form.home == i })
			text(card, c.name, { font = "heavy", size = 16, pos = UDim2.fromOffset(10, 4), sz = UDim2.new(1, -16, 0, 22), z = 65, truncate = true })
			text(card, hot and "<font color='#f0c75a'><b>POPULAR</b></font> · busy trade routes" or (c.country .. " · " .. ({ "City", "Capital", "Major capital", "Global city" })[c.tier]),
				{ size = 12, color = C.muted, rich = hot, pos = UDim2.fromOffset(10, 27), sz = UDim2.new(1, -16, 0, 18), z = 65, truncate = true })
			if hot then UI.icon(card, "icon_sparkles", 16, C.gold, UDim2.new(1, -10, 0, 8), { z = 66, anchor = Vector2.new(1, 0) }) end
			card.Activated:Connect(function() form.home = i; draw() end)
		end
		local function section(title, order)
			text(list, title, { font = "heavy", size = 14, color = C.manila, sz = UDim2.new(1, 0, 0, 20), z = 64, order = order })
			local g = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 63, LayoutOrder = order + 1 }, list)
			UI.mk("UIGridLayout", { CellSize = UDim2.new(1 / 3, -8, 0, 54), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, g)
			return g
		end
		local pg = section("RECOMMENDED: WHERE MOST PLAYERS LIVE", 1)
		for k, i in ipairs(popular) do if W.Cities[i] then cityCard(pg, i, k, true) end end
		local ag = section("ALL CAPITALS", 3)
		local order = {}
		for i in ipairs(W.Cities) do if not table.find(popular, i) then table.insert(order, i) end end
		table.sort(order, function(a, b) return W.Cities[a].name < W.Cities[b].name end)
		for k, i in ipairs(order) do cityCard(ag, i, k, false) end
		return function() return true end
	end

	local check
	draw = function()
		UI.clear(area)
		stepLbl.Text = "STEP " .. step .. " OF 4"
		check = steps[step]()
		back.Inst.Visible = step > 1
		nextB:Set(step == 4 and "green" or "manila", step == 4 and "FOUND MY COUNTRY" or "NEXT")
	end
	nextB.Inst.Activated:Connect(function()
		if not check() then return end
		local FUN = { "name", "flag", "gov" }
		if FUN[step] then task.spawn(function() App.req("funnel", { step = FUN[step] }) end) end
		if step < 4 then step += 1; draw(); return end
		local res = App.req("onboard", form, nextB)
		if res.ok then
			cover:Destroy()
			App.state.onboarded = true
			App.play("level_up")
			if App.updateNav then App.updateNav(App.state) end
			App.open("laws")
			-- run the screen inits now, then ask about the tutorial (Kash 2 Oct)
			if App.runInits then App.runInits() end
			task.delay(0.6, function()
				if App.askTutorial then App.askTutorial()
				else App.toast("WELCOME, " .. string.upper(form.name), "Pass your first laws to grow your nation", "gold") end
			end)
		end
	end)
	draw()
	-- finished elsewhere (another server, or a retry): close the cover
	App.on("full", function(st)
		if cover.Parent and step == 2 and st.gp and st.gp.CustomFlag and not obPassSeen then obPassSeen = true; draw() end
	end)
	App.on("full", function(st) if st.onboarded and cover.Parent then cover:Destroy(); App.open("laws") end end)
end
return O
