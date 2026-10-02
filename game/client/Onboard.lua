-- Onboard: found your country. Name (filtered by Roblox), flag, form of government, home capital.
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local W = require(Shared.World)

local O = {}
local PERK_TEXT = { law = "law cash", props = "property income", convoy = "convoy pay", regen = "Influence regen", attack = "attack", defense = "defense" }
local SUGGEST = { "Avalon", "Novaria", "Eldoria", "Valdris", "Corvania", "Solmere", "Ironvale", "Astoria", "Brightwater", "Kestrel", "Marisol", "Northmark" }

function O.show(App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local form = { name = "", flag = { l = "h3", c = { "1f3a93", "ecf0f1", "c0392b" } }, ideo = "republic", home = 12 }
	local cover = UI.mk("TextButton", { Name = "Onboard", Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromHex("101317"), BackgroundTransparency = 0.05, Size = UDim2.fromScale(1, 1), ZIndex = 60 }, App.root)
	local panel, body = UI.panel(cover, "FOUND YOUR COUNTRY", { sz = UDim2.fromOffset(760, 560), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 61, titleSize = 28 })
	local fit = UI.mk("UISizeConstraint", { MaxSize = Vector2.new(760, 560) }, panel)
	panel.Size = UDim2.new(1, -40, 1, -40)
	local stepLbl = text(panel, "", { font = "bold", size = 15, color = C.muted, pos = UDim2.new(0, 18, 0, 16), sz = UDim2.new(1, -36, 0, 22), z = 63, align = Enum.TextXAlignment.Right })
	local area = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -60), ZIndex = 62 }, body)
	local nav = UI.mk("Frame", { Name = "NavRow", BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -52), Size = UDim2.new(1, 0, 0, 52), ZIndex = 62 }, body)
	local step = 1
	local draw

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
		text(area, "Design your flag", { font = "display", size = 24, pos = UDim2.fromOffset(4, 10), sz = UDim2.new(1, 0, 0, 30), z = 63 })
		local prev = preview(area, UDim2.new(1, -210, 0, 50))
		local function redraw() prev:Destroy(); prev = preview(area, UDim2.new(1, -210, 0, 50)) end
		local lay = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 50), Size = UDim2.new(1, -230, 0, 46), ZIndex = 63 }, area)
		UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, lay)
		for li, l in ipairs(R.FlagLayouts) do
			local b = UI.mk("TextButton", { LayoutOrder = li, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(54, 40), ZIndex = 63 }, lay)
			UI.flag(b, { l = l, c = form.flag.c }, 52, { z = 64, pos = UDim2.fromOffset(1, 3) })
			if form.flag.l == l then UI.mk("Frame", { BackgroundColor3 = C.manila, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, 2), Size = UDim2.new(1, 0, 0, 4), ZIndex = 64 }, b) end
			b.Activated:Connect(function() form.flag.l = l; draw() end)
		end
		for row = 1, 3 do
			text(area, ({ "MAIN", "SECOND", "THIRD" })[row], { font = "heavy", size = 13, color = C.muted, pos = UDim2.fromOffset(4, 108 + (row - 1) * 52), sz = UDim2.fromOffset(70, 40), z = 63 })
			local sw = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(76, 108 + (row - 1) * 52), Size = UDim2.new(1, -310, 0, 40), ZIndex = 63 }, area)
			UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sw)
			for ci, col in ipairs(R.FlagColors) do
				local s = UI.mk("TextButton", { LayoutOrder = ci, Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromHex(col), Size = UDim2.fromOffset(30, 36), ZIndex = 64, BorderSizePixel = 0 }, sw)
				UI.mk("UIStroke", { Color = C.black, Thickness = 1 }, s)
				if form.flag.c[row] == col then UI.icon(s, "icon_check", 22, (col == "ecf0f1" or col == "f1c40f") and C.black or C.white, UDim2.fromScale(0.5, 0.5), { anchor = Vector2.new(0.5, 0.5), z = 65 }) end
				s.Activated:Connect(function() form.flag.c[row] = col; draw() end)
			end
		end
		UI.button(area, "slate", "RANDOM", function()
			form.flag.l = R.FlagLayouts[math.random(1, #R.FlagLayouts)]
			for k = 1, 3 do form.flag.c[k] = R.FlagColors[math.random(1, #R.FlagColors)] end
			draw()
		end, { sz = UDim2.fromOffset(200, 44), pos = UDim2.new(1, -210, 0, 196), z = 63, icon = "icon_sparkles", textSize = 15 })
		return function() return true end
	end
	steps[3] = function()
		text(area, "Choose your form of government", { font = "display", size = 24, pos = UDim2.fromOffset(4, 10), sz = UDim2.new(1, 0, 0, 30), z = 63 })
		local grid = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 54), Size = UDim2.new(1, -8, 1, -60), ZIndex = 63 }, area)
		UI.mk("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 110), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
		local icons = { republic = "icon_landmark", monarchy = "icon_crown", federation = "icon_globe", junta = "icon_military" }
		for k, d in ipairs(R.Ideologies) do
			local card = UI.card(grid, { button = true, z = 64, hot = form.ideo == d.key, order = k })
			UI.icon(card, icons[d.key], 36, form.ideo == d.key and C.gold or C.manila, UDim2.fromOffset(16, 16), { z = 65 })
			text(card, d.name, { font = "display", size = 22, pos = UDim2.fromOffset(64, 18), sz = UDim2.new(1, -72, 0, 28), z = 65 })
			text(card, d.desc, { font = "heavy", size = 17, color = C.good, pos = UDim2.fromOffset(64, 54), sz = UDim2.new(1, -72, 0, 22), z = 65 })
			card.Activated:Connect(function() form.ideo = d.key; draw() end)
		end
		return function() return true end
	end
	steps[4] = function()
		text(area, "Pick your home capital", { font = "display", size = 24, pos = UDim2.fromOffset(4, 10), sz = UDim2.new(1, 0, 0, 30), z = 63 })
		text(area, "Your first convoy starts here and every new convoy is built here. You can trade with every city either way.", { size = 15, color = C.muted, wrap = true, pos = UDim2.fromOffset(4, 42), sz = UDim2.new(1, 0, 0, 40), z = 63 })
		local grid = UI.list(area, { pos = UDim2.fromOffset(0, 86), sz = UDim2.new(1, 0, 1, -86), grid = UDim2.new(1 / 3, -8, 0, 54), gap = 8, z = 63 })
		local order = {}
		for i in ipairs(W.Cities) do table.insert(order, i) end
		table.sort(order, function(a, b) return W.Cities[a].name < W.Cities[b].name end)
		for k, i in ipairs(order) do
			local c = W.Cities[i]
			local card = UI.card(grid, { button = true, z = 64, order = k, hot = form.home == i })
			text(card, c.name, { font = "heavy", size = 16, pos = UDim2.fromOffset(10, 4), sz = UDim2.new(1, -16, 0, 22), z = 65, truncate = true })
			text(card, c.country .. " · " .. ({ "City", "Capital", "Major capital", "Global city" })[c.tier], { size = 12, color = C.muted, pos = UDim2.fromOffset(10, 27), sz = UDim2.new(1, -16, 0, 18), z = 65, truncate = true })
			card.Activated:Connect(function() form.home = i; draw() end)
		end
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
		if step < 4 then step += 1; draw(); return end
		local res = App.req("onboard", form, nextB)
		if res.ok then
			cover:Destroy()
			App.toast("WELCOME, " .. string.upper(form.name), "Pass your first laws, then send a convoy from the CAPITOL map", "gold")
			App.open("map")
		end
	end)
	draw()
	-- finished elsewhere (another server, or a retry): close the cover
	App.on("full", function(st) if st.onboarded and cover.Parent then cover:Destroy(); App.open("map") end end)
end
return O
