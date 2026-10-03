-- Social screens: ALLIANCE (clans are alliances, Kash Q11), RANKINGS, SHOP, and the PLAYER PROFILE popup.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local W = require(Shared.World)
local D = require(Shared.GameData)
local Config = require(Shared.Config)

local S = {}
local AC = Config.Alliance
local UPGRADES = {
	{ key = "stipend", name = "STATE STIPEND", icon = "icon_coins", max = 10, desc = function(l) return "Every member earns an hourly wage (level " .. l .. ")" end },
	{ key = "trade", name = "TRADE NETWORK", icon = "icon_globe", max = 5, desc = function(l) return "+" .. (3 * l) .. "% convoy pay for every member" end },
	{ key = "war", name = "WAR COLLEGE", icon = "icon_attack", max = 5, desc = function(l) return "+" .. (5 * l) .. "% siege damage" end },
	{ key = "fort", name = "FORTIFICATIONS", icon = "icon_castle", max = 5, desc = function(l) return "+" .. (10 * l) .. "% garrison on cities you capture" end },
}
local function upCost(level) return math.floor(2.5e6 * 4 ^ level + 0.5) end
-- same numbers as WorldService (city perk size by tier, strongest 2 of each type count)
local PERK_SIZE = { 3, 5, 8, 12 }
local PERK_NAMES = { law = "law cash", props = "property income", convoy = "convoy pay", regen = "Influence regen", attack = "attack", defense = "defense" }
-- alliance quests: what each kind is called and drawn with
local QUEST_ICON = { law = "icon_laws", convoy = "icon_container", raid = "icon_attack", hit = "icon_crosshair", boss = "icon_bosses", donate = "icon_coins" }
local XP_LABELS = { { "law", "Law" }, { "convoy", "Convoy" }, { "raid", "Raid win" }, { "hit", "Siege hit" }, { "boss", "Boss" }, { "donate", "Donation" } }
-- what a finished quest pays each member who helped (act.allyClaim)
local QUEST_GOLD, QUEST_SEALS = 15, 3

local function frame(host, App, title)
	local UI = App.UI
	local panel, body = UI.panel(host, title, { sz = UDim2.new(1, -20, 1, -20), pos = UDim2.fromOffset(10, 10), z = 5, titleSize = 26 })
	-- the header line starts after the title (about 16 px per typewriter letter) so a long line can never run under it
	local x0 = host:GetAttribute("TabsRight") or (18 + #title * 16 + 16)
	local sub = UI.text(panel, "", { font = "bold", size = 15, color = UI.C.muted, pos = UDim2.new(0, x0, 0, 16), sz = UDim2.new(1, -x0 - 18, 0, 22), z = 7, align = Enum.TextXAlignment.Right, rich = true, truncate = true })
	return panel, body, sub
end

local function input(UI, parent, placeholder, p)
	local box = UI.img(parent, "input", { pos = p.pos, sz = p.sz, z = p.z or 8 })
	local tb = UI.mk("TextBox", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), Text = p.text or "", PlaceholderText = placeholder,
		PlaceholderColor3 = UI.C.dim, TextColor3 = UI.C.ink, FontFace = UI.Font.bold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = box.ZIndex + 1 }, box)
	return tb
end
S.input = nil

local function pct(f) return math.floor((f or 0) * 100 + 0.5) end
local function ago(t, nowT)
	if not t then return "never" end
	local s = math.max(0, nowT - t)
	if s < 300 then return "active now" end
	if s < 3600 then return "active " .. math.floor(s / 60) .. "m ago" end
	if s < 86400 then return "active " .. math.floor(s / 3600) .. "h ago" end
	return "active " .. math.floor(s / 86400) .. "d ago"
end
local function timeLeft(sec)
	sec = math.max(0, math.floor(sec))
	local d, h, m = sec // 86400, (sec % 86400) // 3600, (sec % 3600) // 60
	if d > 0 then return d .. "d " .. h .. "h" end
	if h > 0 then return h .. "h " .. m .. "m" end
	return m .. "m " .. (sec % 60) .. "s"
end
-- small hover lift on a clickable card
local function hover(UI, g)
	local sc = g:FindFirstChildOfClass("UIScale") or UI.mk("UIScale", {}, g)
	g.MouseEnter:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 1.012 }):Play() end)
	g.MouseLeave:Connect(function() TweenService:Create(sc, TweenInfo.new(0.12, Enum.EasingStyle.Quad), { Scale = 1 }):Play() end)
end

---------------------------------------------------------------- PLAYER PROFILE popup (App.showProfile(uid))
local profileToken = 0
local function showProfile(App, uid)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local myUid = Players.LocalPlayer.UserId
	uid = tonumber(uid) or myUid
	local mine = uid == myUid
	local mh = App.modalHost
	if not mh then return end
	profileToken += 1
	local token = profileToken
	UI.clear(mh)
	mh.Visible = true
	local w = math.min(640, App.W() - 24)
	local h = math.min(520, App.H() - 24)
	local panel, body = UI.panel(mh, mine and "MY PROFILE" or "PLAYER PROFILE", { sz = UDim2.fromOffset(w, h), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71 })
	local sc = UI.mk("UIScale", { Scale = 0.8 }, panel)
	TweenService:Create(sc, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	local x = UI.img(panel, "icon_x", { button = true, name = "Close", sz = UDim2.fromOffset(22, 22), pos = UDim2.new(1, -16, 0, 16), anchor = Vector2.new(1, 0), color = C.muted, slice = false, z = 76 })
	x.MouseEnter:Connect(function() x.ImageColor3 = C.ink end)
	x.MouseLeave:Connect(function() x.ImageColor3 = C.muted end)
	x.Activated:Connect(function() profileToken += 1; mh.Visible = false end)
	local loading = text(body, "Loading profile...", { size = 16, color = C.muted, z = 74, align = Enum.TextXAlignment.Center, sz = UDim2.new(1, 0, 0, 30), pos = UDim2.new(0, 0, 0.4, 0) })

	local render
	render = function(pf)
		UI.clear(body)
		local nowT = App.now()
		-- header: flag, name, chips, level
		local head = UI.mk("Frame", { Name = "Head", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 84), ZIndex = 73 }, body)
		if type(pf.f) == "table" then
			UI.flag(head, pf.f, 72, { pos = UDim2.fromOffset(0, 8), z = 74 })
		else
			UI.mk("Frame", { BackgroundColor3 = C.slate, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 8), Size = UDim2.fromOffset(72, 48), ZIndex = 74 }, head)
		end
		text(head, pf.n or "?", { font = "display", size = 26, pos = UDim2.fromOffset(86, 0), sz = UDim2.new(1, -236, 0, 30), z = 74, truncate = true })
		local chips = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(86, 32), Size = UDim2.new(1, -236, 0, 24), ZIndex = 74, ClipsDescendants = true }, head)
		UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, chips)
		local _, titleLbl = UI.chip(chips, string.upper(pf.title or "Citizen"), { manila = true, icon = "icon_crown", z = 75, order = 1 })
		if pf.tag then UI.chip(chips, "[" .. pf.tag .. "]", { icon = "icon_alliance", z = 75, order = 2 }) end
		local ideo = pf.ideo and R.IdeologyByKey and R.IdeologyByKey[pf.ideo]
		if ideo then UI.chip(chips, ideo.name, { z = 75, order = 3 }) end
		local bits = {}
		if pf.online or pf.here then table.insert(bits, "<font color='#8fd07a'><b>ONLINE</b></font>")
		elseif pf.lastSeen then table.insert(bits, "Last seen " .. ago(pf.lastSeen, nowT):gsub("^active ", ""))
		end
		local home = pf.home and W.Cities[pf.home]
		if home then table.insert(bits, "Capital: " .. home.name) end
		if pf.since then table.insert(bits, "Since " .. os.date("!%d %b %Y", pf.since)) end
		local bitsL = text(head, table.concat(bits, " · "), { size = 13, color = C.muted, pos = UDim2.fromOffset(86, 60), sz = UDim2.new(1, -236, 0, 20), z = 74, rich = true, truncate = true })
		-- the Roblox player behind the country (rankings show the player, the profile ties it to their nation)
		task.spawn(function()
			local okN, un = pcall(Players.GetNameFromUserIdAsync, Players, uid)
			if okN and un and bitsL.Parent then bitsL.Text = "<font color='#e2cfa3'><b>@" .. un .. "</b></font>" .. (bitsL.Text ~= "" and (" · " .. bitsL.Text) or "") end
		end)
		local era = pf.era and D.Eras[pf.era]
		text(head, "LEVEL", { font = "heavy", size = 12, color = C.muted, pos = UDim2.new(1, -140, 0, 2), sz = UDim2.fromOffset(140, 16), z = 74, align = Enum.TextXAlignment.Right })
		text(head, tostring(pf.lv or "?"), { font = "display", size = 34, color = C.xp, pos = UDim2.new(1, -140, 0, 18), sz = UDim2.fromOffset(140, 38), z = 74, align = Enum.TextXAlignment.Right })
		text(head, era and (string.upper(era.name) .. " ERA") or "", { font = "bold", size = 13, color = C.manila, pos = UDim2.new(1, -140, 0, 58), sz = UDim2.fromOffset(140, 20), z = 74, align = Enum.TextXAlignment.Right })

		local list = UI.list(body, { pos = UDim2.fromOffset(0, 92), sz = UDim2.new(1, 0, 1, -92), gap = 8, z = 73 })
		-- power row
		local row = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), ZIndex = 74, LayoutOrder = 1 }, list)
		UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, row)
		local function box(order, icon, col, label, value)
			local b = UI.card(row, { sz = UDim2.new(0.25, -6, 1, 0), z = 74, order = order })
			UI.icon(b, icon, 22, col, UDim2.fromOffset(10, 19), { z = 75 })
			text(b, label, { font = "heavy", size = 12, color = C.muted, pos = UDim2.fromOffset(40, 8), sz = UDim2.new(1, -46, 0, 16), z = 75 })
			text(b, value, { font = "heavy", size = 18, color = col, pos = UDim2.fromOffset(40, 26), sz = UDim2.new(1, -46, 0, 24), z = 75, scaled = true })
		end
		box(1, "icon_attack", C.bad, "ATTACK", R.Short(pf.atk or 0))
		box(2, "icon_defense", C.blue, "DEFENSE", R.Short(pf.def or 0))
		box(3, "icon_cash", C.good, "INCOME / HR", pf.inc and R.Money(pf.inc) or "?")
		box(4, "icon_landmark", C.gold, "WONDER", "Stage " .. tostring(pf.wonder or 0))

		local function header(label, order, rightText)
			local f = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), ZIndex = 74, LayoutOrder = order }, list)
			text(f, label, { font = "heavy", size = 14, color = C.muted, sz = UDim2.new(0.5, 0, 1, 0), z = 75 })
			if rightText then text(f, rightText, { size = 13, color = C.dim, pos = UDim2.new(0.5, 0, 0, 0), sz = UDim2.new(0.5, 0, 1, 0), z = 75, align = Enum.TextXAlignment.Right, truncate = true }) end
			return f
		end
		-- lifetime stats
		header("LIFETIME STATS", 2)
		local st = pf.st
		if type(st) == "table" then
			local grid = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 74, LayoutOrder = 3 }, list)
			UI.mk("UIGridLayout", { CellSize = UDim2.new(0.25, -6, 0, 50), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
			local cells = {
				{ "LAWS PASSED", R.Commas(st.laws or 0) }, { "CONVOYS", R.Commas(st.trips or 0) }, { "RAIDS WON", R.Commas(st.wins or 0) }, { "BATTLES", R.Commas(st.battles or 0) },
				{ "BOSSES", R.Commas(st.bosses or 0) }, { "BUILT", R.Commas(st.built or 0) }, { "EARNED", R.Money(st.earned or 0) }, { "STOLEN", R.Money(st.stolen or 0) },
			}
			for k, c in ipairs(cells) do
				local cell = UI.card(grid, { z = 74, order = k })
				text(cell, c[1], { font = "heavy", size = 11, color = C.muted, pos = UDim2.fromOffset(10, 6), sz = UDim2.new(1, -20, 0, 16), z = 75 })
				text(cell, c[2], { font = "heavy", size = 18, pos = UDim2.fromOffset(10, 22), sz = UDim2.new(1, -20, 0, 22), z = 75, scaled = true })
			end
		else
			local f = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), ZIndex = 74, LayoutOrder = 3 }, list)
			text(f, "Full stats show after this player's next visit.", { size = 14, color = C.dim, sz = UDim2.fromScale(1, 1), z = 75 })
		end

		-- achievements
		local got = {}
		for _, k in ipairs(type(pf.ach) == "table" and pf.ach or {}) do got[k] = true end
		local nGot = 0
		for _ in pairs(got) do nGot += 1 end
		local cur = mine and App.state and App.state.title or nil
		local ah = header("ACHIEVEMENTS " .. nGot .. "/" .. #R.Achievements, 4, mine and "Tap an earned badge to wear its title" or nil)
		if mine and cur then
			UI.button(ah, "slate", "AUTO TITLE", function(btn)
				local r = App.req("setTitle", {}, btn)
				if r.ok then
					local r2 = App.req("profile", { uid = uid })
					if token == profileToken and body.Parent and r2.ok and type(r2.profile) == "table" then render(r2.profile) end
				end
			end, { sz = UDim2.fromOffset(110, 26), pos = UDim2.new(0.5, -116, 0, 0), z = 76, textSize = 12 })
		end
		local grid = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 74, LayoutOrder = 5 }, list)
		UI.mk("UIGridLayout", { CellSize = UDim2.new(1 / 3, -6, 0, 86), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
		local strokes = {}
		local function mark(sel)
			for k, s in pairs(strokes) do s.stroke.Enabled = k == sel; s.shown.Visible = k == sel end
		end
		for k, A in ipairs(R.Achievements) do
			local earned = got[A.key] == true
			local pickable = mine and earned
			local cell = UI.card(grid, { z = 74, order = (earned and 0 or 100) + k, button = pickable, hot = earned })
			local tier = tonumber(A.key:match("(%d)$")) or 1
			UI.img(cell, tier >= 3 and "medal_gold" or (tier == 2 and "medal_silver" or "medal_bronze"), { sz = UDim2.fromOffset(42, 42), pos = UDim2.fromOffset(8, 10), z = 75, slice = false, fit = true,
				color = earned and C.white or Color3.fromHex("5a5f66"), alpha = earned and 0 or 0.45 })
			if not earned then UI.icon(cell, "icon_lock", 18, C.muted, UDim2.fromOffset(20, 22), { z = 76 }) end
			text(cell, A.name, { font = "heavy", size = 15, color = earned and C.ink or C.muted, pos = UDim2.fromOffset(58, 6), sz = UDim2.new(1, -64, 0, 20), z = 75, truncate = true })
			text(cell, A.desc, { size = 12, color = earned and C.muted or C.dim, pos = UDim2.fromOffset(58, 26), sz = UDim2.new(1, -64, 0, 30), z = 75, wrap = true, valign = Enum.TextYAlignment.Top })
			text(cell, "Title: " .. A.title, { font = "bold", size = 12, color = earned and C.manila or C.dim, pos = UDim2.fromOffset(58, 60), sz = UDim2.new(1, -64, 0, 18), z = 75, truncate = true })
			if pickable then
				local _, stroke = UI.outline(cell, C.gold, 2, { enabled = false })
				local shown = text(cell, "SHOWN", { font = "heavy", size = 11, color = C.gold, pos = UDim2.new(1, -60, 0, 4), sz = UDim2.fromOffset(52, 14), z = 77, align = Enum.TextXAlignment.Right, visible = false })
				strokes[A.key] = { stroke = stroke, shown = shown }
				hover(UI, cell)
				cell.Activated:Connect(function()
					if cur == A.key then return end
					local r = App.req("setTitle", { key = A.key })
					if r.ok and token == profileToken then
						cur = A.key
						titleLbl.Text = string.upper(A.title)
						mark(cur)
						App.toast("TITLE CHANGED", "You are now known as " .. A.title, "good")
					end
				end)
			end
		end
		mark(cur)
	end

	task.spawn(function()
		local res = App.req("profile", { uid = uid })
		if token ~= profileToken or not panel.Parent then return end
		if not res.ok or type(res.profile) ~= "table" then
			if loading.Parent then loading.Text = res.msg or "Could not load this profile" end
			return
		end
		render(res.profile)
	end)
end

-- registers App.showProfile as soon as the client starts, so any screen can open a profile
S.profilePopup = { init = function(App) App.showProfile = function(uid) showProfile(App, uid) end end }

---------------------------------------------------------------- ALLIANCE
S.alliance = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "ALLIANCE")
	local obj = { tab = 1, list = nil, scroll = {} }
	local area = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6 }, body)
	local me = tostring(Players.LocalPlayer.UserId)
	App.showProfile = App.showProfile or function(uid) showProfile(App, uid) end

	local function noAlliance(st)
		sub.Text = "Team up, capture capitals and get rich together"
		local left = UI.list(area, { sz = UDim2.new(0.6, -8, 1, 0), gap = 6, z = 7 })
		local right = UI.card(area, { sz = UDim2.new(0.4, -8, 1, 0), pos = UDim2.new(0.6, 8, 0, 0), z = 7 })
		local hdr = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), ZIndex = 7, LayoutOrder = 0 }, left)
		text(hdr, "JOIN AN ALLIANCE", { font = "heavy", size = 15, color = C.muted, sz = UDim2.fromScale(1, 1), z = 8 })
		if not obj.list then
			text(left, "Loading...", { size = 15, color = C.muted, order = 1, z = 8 })
			task.spawn(function()
				local res = App.req("allyList", {})
				if res.ok then obj.list = res.list; obj:Refresh(App.state) end
			end)
		elseif #obj.list == 0 then
			text(left, "No alliances yet. Found the first one!", { size = 16, color = C.muted, order = 1, z = 8 })
		else
			for i, a in ipairs(obj.list) do
				local card = UI.card(left, { sz = UDim2.new(1, 0, 0, 58), z = 8, order = i })
				UI.mk("Frame", { BackgroundColor3 = Color3.fromHex(a.color), BorderSizePixel = 0, Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(28, 28), ZIndex = 9 }, card)
				text(card, "[" .. a.tag .. "] " .. a.name, { font = "heavy", size = 17, pos = UDim2.fromOffset(52, 6), sz = UDim2.new(1, -180, 0, 24), z = 9, truncate = true })
				text(card, (a.members or 0) .. "/" .. AC.MaxMembers .. " members · " .. a.cities .. " cities" .. (a.open == false and " · invite only" or ""), { size = 13, color = C.muted, pos = UDim2.fromOffset(52, 30), sz = UDim2.new(1, -180, 0, 18), z = 9 })
				local full = (a.members or 0) >= AC.MaxMembers or a.open == false
				UI.button(card, full and "locked" or "green", full and "CLOSED" or "JOIN", function(btn)
					local res = App.req("allyJoin", { id = a.id }, btn)
					if res.ok then App.toast("WELCOME TO [" .. a.tag .. "]", a.name, "good"); obj.list = nil end
				end, { sz = UDim2.fromOffset(110, 40), pos = UDim2.new(1, -120, 0, 9), z = 9 })
			end
		end
		-- found one
		text(right, "FOUND AN ALLIANCE", { font = "display", size = 22, color = C.manila, pos = UDim2.fromOffset(16, 12), sz = UDim2.new(1, -32, 0, 28), z = 8 })
		text(right, "Needs level " .. AC.MinLevel .. " and " .. R.Money(AC.CreateCost) .. ". Up to " .. AC.MaxMembers .. " members and " .. AC.MaxCities .. " cities.", { size = 14, color = C.muted, wrap = true, pos = UDim2.fromOffset(16, 44), sz = UDim2.new(1, -32, 0, 40), z = 8, valign = Enum.TextYAlignment.Top })
		obj.form = obj.form or { color = AC.Colors[1] }
		local nameBox = input(UI, right, "Alliance name (3-24)", { pos = UDim2.fromOffset(16, 92), sz = UDim2.new(1, -32, 0, 40), text = obj.form.name })
		local tagBox = input(UI, right, "Tag (2-4)", { pos = UDim2.fromOffset(16, 140), sz = UDim2.new(0, 120, 0, 40), text = obj.form.tag })
		nameBox:GetPropertyChangedSignal("Text"):Connect(function() obj.form.name = nameBox.Text end)
		tagBox:GetPropertyChangedSignal("Text"):Connect(function() tagBox.Text = tagBox.Text:upper():gsub("[^A-Z0-9]", ""):sub(1, 4); obj.form.tag = tagBox.Text end)
		local sw = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 192), Size = UDim2.new(1, -32, 0, 70), ZIndex = 8 }, right)
		UI.mk("UIGridLayout", { CellSize = UDim2.fromOffset(30, 30), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sw)
		local swatches = {}
		local function mark() for col, s in pairs(swatches) do s.ring.Enabled = col == obj.form.color end end
		for k, col in ipairs(AC.Colors) do
			-- colour swatch on an inset plate, with a manila ring on the picked one
			local cell = UI.img(sw, "inset", { button = true, name = "Swatch", order = k, z = 9 })
			UI.mk("Frame", { BackgroundColor3 = Color3.fromHex(col), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), ZIndex = 10 }, cell)
			local _, ring = UI.outline(cell, C.manila, 2, { enabled = false })
			local s = cell
			swatches[col] = { ring = ring }
			s.Activated:Connect(function() obj.form.color = col; mark() end)
		end
		mark()
		local ok = st.lv >= AC.MinLevel and st.cash >= AC.CreateCost
		UI.button(right, ok and "manila" or "locked", "FOUND · " .. R.Money(AC.CreateCost), function(btn)
			local res = App.req("allyCreate", { name = nameBox.Text, tag = tagBox.Text, color = obj.form.color }, btn)
			if res.ok then App.toast("ALLIANCE FOUNDED", "Invite friends: they can find it in the Alliance list", "good"); obj.list = nil end
		end, { sz = UDim2.new(1, -32, 0, 46), pos = UDim2.new(0, 16, 1, -62), z = 9 })
	end

	-- a scrolling list under the tab strip that keeps its scroll position across refreshes
	local function tabList(gap)
		local list = UI.list(area, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), gap = gap or 8, z = 7 })
		local tab = obj.tab
		local saved = obj.scroll[tab]
		if saved then task.defer(function() if list.Parent then list.CanvasPosition = saved end end) end
		list:GetPropertyChangedSignal("CanvasPosition"):Connect(function() obj.scroll[tab] = list.CanvasPosition end)
		return list
	end
	local function section(list, label, order, rightText)
		local f = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), ZIndex = 8, LayoutOrder = order }, list)
		text(f, label, { font = "heavy", size = 14, color = C.muted, pos = UDim2.fromOffset(2, 0), sz = UDim2.new(0.6, 0, 1, 0), z = 9 })
		if rightText then text(f, rightText, { size = 13, color = C.dim, pos = UDim2.new(0.4, 0, 0, 0), sz = UDim2.new(0.6, -4, 1, 0), z = 9, align = Enum.TextXAlignment.Right, truncate = true, rich = true }) end
		return f
	end
	local function claimCount(info)
		local c = info and info.claim
		if type(c) ~= "table" then return 0 end
		return (c.levels or 0) + (type(c.quests) == "table" and #c.quests or 0)
	end
	local function claim(btn)
		local res = App.req("allyClaim", {}, btn)
		if res.ok then
			local bits = {}
			if (res.gold or 0) > 0 then table.insert(bits, R.Commas(res.gold) .. " gold") end
			if (res.seals or 0) > 0 then table.insert(bits, res.seals .. " seals") end
			if (res.basic or 0) > 0 then table.insert(bits, res.basic .. (res.basic == 1 and " basic crate" or " basic crates")) end
			App.toast("ALLIANCE REWARDS", #bits > 0 and table.concat(bits, " · ") or nil, "gold")
		end
	end
	local function heldCities(st)
		local held, byIdx = {}, {}
		for i, cs in pairs(App.world and App.world.cities or {}) do
			local idx = tonumber(i)
			if type(cs) == "table" and cs.owner == st.alliance and idx and W.Cities[idx] then table.insert(held, idx); byIdx[idx] = cs end
		end
		table.sort(held)
		return held, byIdx
	end

	---------------------------------------------------------------- OVERVIEW
	local function overview(st, a, myRole, info)
		local list = tabList(8)
		local nMembers = 0
		for _ in pairs(a.members or {}) do nMembers += 1 end
		local cap = (info and info.cap) or AC.MaxMembers
		local nowT = App.now()
		-- header
		local head = UI.card(list, { sz = UDim2.new(1, 0, 0, 96), z = 8, order = 1 })
		UI.mk("Frame", { BackgroundColor3 = Color3.fromHex(a.color or "546e7a"), BorderSizePixel = 0, Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(64, 64), ZIndex = 9 }, head)
		text(head, a.tag, { font = "display", size = 22, color = C.white, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(16, 16), sz = UDim2.fromOffset(64, 64), z = 10, stroke = 1.5 })
		text(head, a.name, { font = "display", size = 26, pos = UDim2.fromOffset(96, 12), sz = UDim2.new(0.6, -96, 0, 32), z = 9, truncate = true })
		text(head, "Led by " .. (a.leaderName or "?") .. " · " .. nMembers .. "/" .. cap .. " members · you are " .. (myRole or "member"), { size = 14, color = C.muted, pos = UDim2.fromOffset(96, 48), sz = UDim2.new(0.6, -96, 0, 20), z = 9, truncate = true })
		text(head, "TREASURY", { font = "heavy", size = 13, color = C.muted, pos = UDim2.new(0.62, 0, 0, 14), sz = UDim2.new(0.38, -16, 0, 18), z = 9, align = Enum.TextXAlignment.Right })
		text(head, R.Money(a.treasury or 0), { font = "display", size = 30, color = C.gold, pos = UDim2.new(0.62, 0, 0, 34), sz = UDim2.new(0.38, -16, 0, 36), z = 9, align = Enum.TextXAlignment.Right })

		-- level + XP + claim
		if info then
			local n = claimCount(info)
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 108), z = 8, order = 2, hot = n > 0 })
			local badge = UI.img(card, "chip_manila", { pos = UDim2.fromOffset(16, 16), sz = UDim2.fromOffset(76, 76), z = 9 })
			text(badge, "LEVEL", { font = "heavy", size = 12, color = C.manilaInk, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 8), sz = UDim2.new(1, 0, 0, 14), z = 10 })
			text(badge, tostring(info.level or 1), { font = "display", size = 34, color = C.manilaInk, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 24), sz = UDim2.new(1, 0, 0, 42), z = 10 })
			local rightW = n > 0 and 200 or 16
			local maxed = (info.level or 1) >= (info.maxLevel or 30)
			text(card, maxed and "ALLIANCE AT MAX LEVEL" or ("ALLIANCE LEVEL " .. (info.level or 1) .. "  <font color='#9a9fa6'>/ " .. (info.maxLevel or 30) .. "</font>"), { font = "display", size = 20, rich = true, pos = UDim2.fromOffset(108, 8), sz = UDim2.new(1, -108 - rightW, 0, 26), z = 9, truncate = true })
			local bar = UI.bar(card, C.xp, { pos = UDim2.fromOffset(108, 40), sz = UDim2.new(1, -108 - rightW, 0, 22), z = 9 })
			if maxed then bar:Set(1, "MAX", "")
			else bar:Set((info.xp or 0) / math.max(1, info.xpReq or 1), "XP", R.Commas(info.xp or 0) .. " / " .. R.Commas(info.xpReq or 0)) end
			local nr = info.nextReward or {}
			local crates = nr.basicCrates or nr.basic or 0
			local nextTxt = maxed and "" or (" · Next level: +" .. pct(info.nextBonus) .. "%, " .. (info.nextCap or cap) .. " member slots, " .. (nr.gold or 0) .. " gold each" .. (crates > 0 and (" + " .. crates .. " basic crate") or ""))
			text(card, "Bonus now: <font color='#8fd07a'><b>+" .. pct(info.bonus) .. "%</b></font> law, property and convoy cash" .. nextTxt, { size = 13, color = C.muted, rich = true, wrap = true, pos = UDim2.fromOffset(108, 66), sz = UDim2.new(1, -108 - rightW, 0, 36), z = 9, valign = Enum.TextYAlignment.Top })
			if n > 0 then
				local b = UI.button(card, "gold", "CLAIM REWARDS", claim, { sz = UDim2.fromOffset(180, 48), pos = UDim2.new(1, -194, 0, 30), z = 9, icon = "icon_gift", textSize = 15 })
				UI.badge(b.Inst, n, UDim2.new(1, -4, 0, 4), 12)
			end
		end

		-- donate
		local don = UI.card(list, { sz = UDim2.new(1, 0, 0, 64), z = 8, order = 3 })
		text(don, "DONATE TO THE TREASURY", { font = "heavy", size = 15, pos = UDim2.fromOffset(16, 0), sz = UDim2.new(0.35, -16, 1, 0), z = 9, scaled = true })
		for k, p in ipairs({ 0.05, 0.25, 0.5 }) do
			local amt = math.floor(st.cash * p)
			UI.button(don, amt > 0 and "gold" or "locked", math.floor(p * 100) .. "% · " .. R.Money(amt), function(btn)
				local res = App.req("allyDonate", { amount = math.floor(App.state.cash * p) }, btn)
				if res.ok then App.float(btn.Inst, "-" .. R.Money(res.amount), C.gold) end
			end, { sz = UDim2.new(0.21, -8, 0, 42), pos = UDim2.new(0.35 + (k - 1) * 0.21, 0, 0, 11), z = 9, textSize = 14 })
		end

		-- members
		section(list, "MEMBERS " .. nMembers .. "/" .. cap, 10, "Contribution: alliance XP this week · all time · cash donated")
		local rows = {}
		for uid, m in pairs(a.members or {}) do table.insert(rows, { uid = uid, m = m }) end
		local rank = { leader = 1, officer = 2, member = 3 }
		table.sort(rows, function(x, y)
			local rx, ry = rank[x.m.role] or 4, rank[y.m.role] or 4
			if rx ~= ry then return rx < ry end
			if (x.m.wk or 0) ~= (y.m.wk or 0) then return (x.m.wk or 0) > (y.m.wk or 0) end
			return (x.m.tot or 0) > (y.m.tot or 0)
		end)
		for k, r in ipairs(rows) do
			local m = r.m
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 56), z = 8, order = 10 + k, button = true })
			hover(UI, card)
			card.Activated:Connect(function() if App.showProfile then App.showProfile(tonumber(r.uid)) end end)
			-- management buttons first so we know how much room the text gets
			local btnW = 10
			if r.uid ~= me then
				local function act(label, kind, fn)
					btnW += 96
					UI.button(card, kind, label, fn, { sz = UDim2.fromOffset(90, 36), pos = UDim2.new(1, -btnW, 0, 10), z = 9, textSize = 13 })
				end
				if myRole == "leader" then
					act("REMOVE", "red", function(btn) App.confirm("REMOVE " .. (m.name or "?") .. "?", "They leave the alliance right away.", "REMOVE", "red", function() App.req("allyKick", { uid = r.uid }, btn) end) end)
					if m.role == "member" then act("PROMOTE", "slate", function(btn) App.req("allyRole", { uid = r.uid, role = "officer" }, btn) end)
					else act("DEMOTE", "slate", function(btn) App.req("allyRole", { uid = r.uid, role = "member" }, btn) end) end
					act("MAKE LEADER", "gold", function(btn) App.confirm("HAND OVER LEADERSHIP?", (m.name or "?") .. " becomes leader and you become an officer.", "HAND OVER", "gold", function() App.req("allyRole", { uid = r.uid, role = "leader" }, btn) end) end)
				elseif myRole == "officer" and m.role == "member" then
					act("REMOVE", "red", function(btn) App.req("allyKick", { uid = r.uid }, btn) end)
				end
			end
			local roleCol = m.role == "leader" and C.gold or C.manila
			UI.icon(card, m.role == "leader" and "icon_crown" or (m.role == "officer" and "icon_defense" or "icon_users"), 22, roleCol, UDim2.fromOffset(14, 17), { z = 9 })
			local left = 46
			local half = (left + btnW) / 2
			text(card, (m.name or "?") .. (r.uid == me and " (you)" or ""), { font = "heavy", size = 16, pos = UDim2.fromOffset(left, 7), sz = UDim2.new(0.5, -half, 0, 22), z = 9, truncate = true })
			local online = m.active and nowT - m.active < 300
			text(card, string.upper(m.role or "member") .. (m.lv and (" · LV " .. m.lv) or "") .. " · " .. (online and "<font color='#8fd07a'>active now</font>" or ago(m.active, nowT)), { size = 13, color = C.muted, rich = true, pos = UDim2.fromOffset(left, 29), sz = UDim2.new(0.5, -half, 0, 18), z = 9, truncate = true })
			text(card, R.Commas(m.wk or 0) .. " XP this week", { font = "heavy", size = 15, color = C.xp, pos = UDim2.new(0.5, left - half, 0, 7), sz = UDim2.new(0.5, -half, 0, 22), z = 9, truncate = true })
			text(card, R.Commas(m.tot or 0) .. " XP total · " .. R.Money(m.donated or 0) .. " donated", { size = 13, color = C.muted, pos = UDim2.new(0.5, left - half, 0, 29), sz = UDim2.new(0.5, -half, 0, 18), z = 9, truncate = true })
		end

		-- perks: alliance level, cities, upgrades
		section(list, "PERKS", 200, "Upgrades are paid from the treasury by the leader and officers")
		if info then
			local lc = UI.card(list, { sz = UDim2.new(1, 0, 0, 60), z = 8, order = 201 })
			UI.icon(lc, "icon_sparkles", 28, C.xp, UDim2.fromOffset(16, 16), { z = 9 })
			text(lc, "ALLIANCE LEVEL " .. (info.level or 1), { font = "display", size = 19, pos = UDim2.fromOffset(60, 6), sz = UDim2.new(1, -76, 0, 24), z = 9 })
			text(lc, "+" .. pct(info.bonus) .. "% law cash, property income and convoy pay for every member", { size = 13, color = C.muted, pos = UDim2.fromOffset(60, 32), sz = UDim2.new(1, -76, 0, 18), z = 9, truncate = true })
		end
		do
			local byType = {}
			for _, i in ipairs(heldCities(st)) do
				local city = W.Cities[i]
				byType[city.perk] = byType[city.perk] or {}
				table.insert(byType[city.perk], PERK_SIZE[city.tier] or 0)
			end
			local parts = {}
			for p, sizes in pairs(byType) do
				table.sort(sizes, function(x, y) return x > y end)
				table.insert(parts, "+" .. ((sizes[1] or 0) + (sizes[2] or 0)) .. "% " .. (PERK_NAMES[p] or p))
			end
			table.sort(parts)
			local countries = (st.mods and st.mods.countries) or {}
			if #countries > 0 then table.insert(parts, "+10% cash for full control of " .. table.concat(countries, ", ")) end
			local cc = UI.card(list, { sz = UDim2.new(1, 0, 0, 60), z = 8, order = 202 })
			UI.icon(cc, "icon_flag", 28, C.manila, UDim2.fromOffset(16, 16), { z = 9 })
			text(cc, "CITY PERKS", { font = "display", size = 19, pos = UDim2.fromOffset(60, 6), sz = UDim2.new(1, -76, 0, 24), z = 9 })
			text(cc, #parts > 0 and table.concat(parts, " · ") or "None yet. Hold cities to earn perks.", { size = 13, color = C.muted, pos = UDim2.fromOffset(60, 32), sz = UDim2.new(1, -76, 0, 18), z = 9, truncate = true })
		end
		for k, u in ipairs(UPGRADES) do
			local lvl = a.up and a.up[u.key] or 0
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 72), z = 8, order = 210 + k })
			UI.icon(card, u.icon, 30, C.manila, UDim2.fromOffset(16, 21), { z = 9 })
			text(card, u.name .. "  <font color='#9a9fa6'>LV " .. lvl .. "/" .. u.max .. "</font>", { font = "display", size = 19, rich = true, pos = UDim2.fromOffset(60, 6), sz = UDim2.new(1, -270, 0, 26), z = 9, truncate = true })
			text(card, lvl > 0 and u.desc(lvl) or ("Level 1: " .. u.desc(1)), { size = 13, color = C.muted, pos = UDim2.fromOffset(60, 34), sz = UDim2.new(1, -270, 0, 32), z = 9, wrap = true, valign = Enum.TextYAlignment.Top })
			if lvl >= u.max then
				UI.button(card, "locked", "MAXED", nil, { sz = UDim2.fromOffset(196, 44), pos = UDim2.new(1, -208, 0, 14), z = 9 })
			else
				local cost = upCost(lvl)
				local can = (myRole == "leader" or myRole == "officer") and (a.treasury or 0) >= cost
				UI.button(card, can and "gold" or "locked", "UPGRADE · " .. R.Money(cost), function(btn) App.req("allyUpgrade", { key = u.key }, btn) end, { sz = UDim2.fromOffset(196, 44), pos = UDim2.new(1, -208, 0, 14), z = 9, textSize = 15 })
			end
		end

		-- activity log
		local logs = a.log or {}
		if #logs > 0 then
			section(list, "ALLIANCE LOG", 300)
			local box = UI.card(list, { sz = UDim2.new(1, 0, 0, 0), z = 8, order = 301 })
			box.AutomaticSize = Enum.AutomaticSize.Y
			UI.mk("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, box)
			UI.mk("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }, box)
			for k, e in ipairs(logs) do
				if k > 15 then break end
				local row = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), ZIndex = 9, LayoutOrder = k }, box)
				text(row, e.t and os.date("!%d %b %H:%M", e.t) or "", { size = 13, color = C.muted, sz = UDim2.fromOffset(104, 22), z = 10 })
				text(row, e.m or "", { size = 14, pos = UDim2.fromOffset(108, 0), sz = UDim2.new(1, -108, 1, 0), z = 10, truncate = true })
			end
		end

		-- manage
		section(list, "MANAGE", 400)
		local manage = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), ZIndex = 8, LayoutOrder = 401 }, list)
		UI.button(manage, "red", "LEAVE ALLIANCE", function(btn)
			App.confirm("LEAVE " .. a.name .. "?", "You will lose the alliance perks and stipend." .. (myRole == "leader" and " An officer will take over as leader." or ""), "LEAVE", "red", function()
				App.req("allyLeave", {}, btn); obj.list = nil
			end)
		end, { sz = UDim2.fromOffset(200, 42), z = 9 })
		if myRole == "leader" then
			UI.button(manage, "slate", a.open == false and "INVITE ONLY: ON" or "OPEN TO ALL", function(btn) App.req("allyOpen", { open = a.open == false }, btn) end, { sz = UDim2.fromOffset(200, 42), pos = UDim2.fromOffset(210, 0), z = 9 })
		end
	end

	---------------------------------------------------------------- CITIES
	local function cities(st, a)
		local list = tabList(8)
		local held, byIdx = heldCities(st)
		local countries = (st.mods and st.mods.countries) or {}
		local top = UI.card(list, { sz = UDim2.new(1, 0, 0, 70), z = 8, order = 1 })
		UI.icon(top, "icon_flag", 30, Color3.fromHex(a.color or "546e7a"), UDim2.fromOffset(16, 20), { z = 9 })
		text(top, "CITIES HELD", { font = "heavy", size = 13, color = C.muted, pos = UDim2.fromOffset(60, 10), sz = UDim2.fromOffset(160, 16), z = 9 })
		text(top, #held .. " / " .. AC.MaxCities, { font = "display", size = 28, color = C.manila, pos = UDim2.fromOffset(60, 26), sz = UDim2.fromOffset(160, 34), z = 9 })
		text(top, "Your cities earn tax from every convoy that arrives."
			.. (#countries > 0 and (" Full control: " .. table.concat(countries, ", ") .. " (+10% cash).") or ""), { size = 13, color = C.muted, pos = UDim2.fromOffset(230, 0), sz = UDim2.new(1, -246, 1, 0), z = 9, wrap = true })
		if #held == 0 then
			local e = UI.card(list, { sz = UDim2.new(1, 0, 0, 96), z = 8, order = 2 })
			UI.icon(e, "icon_map", 34, C.muted, UDim2.fromOffset(18, 31), { z = 9 })
			text(e, "Your alliance holds no cities yet. Capture cities on the WORLD map.", { font = "heavy", size = 16, color = C.ink, pos = UDim2.fromOffset(66, 0), sz = UDim2.new(1, -260, 1, 0), z = 9, wrap = true })
			UI.button(e, "manila", "OPEN WORLD MAP", function() App.open("map") end, { sz = UDim2.fromOffset(170, 44), pos = UDim2.new(1, -184, 0, 26), z = 9, icon = "icon_globe", textSize = 14 })
			return
		end
		for k, i in ipairs(held) do
			local cs = byIdx[i] or {}
			local city = W.Cities[i]
			local card = UI.card(list, { button = true, sz = UDim2.new(1, 0, 0, 58), z = 8, order = 10 + k })
			hover(UI, card)
			UI.icon(card, "icon_flag", 22, Color3.fromHex(a.color or "546e7a"), UDim2.fromOffset(14, 18), { z = 9 })
			text(card, city.name, { font = "heavy", size = 17, pos = UDim2.fromOffset(46, 6), sz = UDim2.new(0.4, -46, 0, 22), z = 9, truncate = true })
			text(card, city.country .. " · Tier " .. (city.tier or 1) .. " · +" .. (PERK_SIZE[city.tier] or 0) .. "% " .. (PERK_NAMES[city.perk] or city.perk or ""), { size = 13, color = C.muted, pos = UDim2.fromOffset(46, 30), sz = UDim2.new(0.4, -46, 0, 18), z = 9, truncate = true })
			text(card, "TAX " .. (cs.tax or 0) .. "%" .. ((cs.rent or 0) > 0 and (" · RENT " .. cs.rent .. "%") or ""), { font = "heavy", size = 16, color = C.gold, pos = UDim2.new(0.4, 0, 0, 6), sz = UDim2.new(0.6, -16, 0, 22), z = 9, align = Enum.TextXAlignment.Right })
			text(card, "Garrison " .. R.Short(cs.hp or 0) .. (cs.maxHp and (" / " .. R.Short(cs.maxHp)) or ""), { size = 13, color = C.muted, pos = UDim2.new(0.4, 0, 0, 30), sz = UDim2.new(0.6, -16, 0, 18), z = 9, align = Enum.TextXAlignment.Right })
			card.Activated:Connect(function() App.open("map"); if App.focusCity then App.focusCity(i) end end)
		end
		local note = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), ZIndex = 8, LayoutOrder = 999 }, list)
		text(note, "Tap a city to open it on the WORLD map, where the leader and officers set its tax and rent.", { size = 13, color = C.dim, sz = UDim2.fromScale(1, 1), z = 9, wrap = true })
	end

	---------------------------------------------------------------- QUESTS
	local function quests(st, a, info)
		local list = tabList(8)
		local ends = info and info.weekEnds
		local hdr = section(list, "THIS WEEK'S ALLIANCE QUESTS", 1)
		obj.timer = text(hdr, "", { font = "heavy", size = 14, color = C.manila, pos = UDim2.new(0.5, 0, 0, 0), sz = UDim2.new(0.5, -4, 1, 0), z = 9, align = Enum.TextXAlignment.Right })
		obj.weekEnds = ends
		if ends then obj.timer.Text = "NEW QUESTS IN " .. timeLeft(ends - App.now()) end
		local qs = a.quests
		local stale = info and info.week and a.qweek and a.qweek ~= info.week
		local claimable = {}
		if info and type(info.claim) == "table" and type(info.claim.quests) == "table" then
			for _, k in ipairs(info.claim.quests) do claimable[k] = true end
		end
		if type(qs) ~= "table" or #qs == 0 or stale then
			local e = UI.card(list, { sz = UDim2.new(1, 0, 0, 60), z = 8, order = 2 })
			text(e, "New quests are on the way!", { size = 15, color = C.muted, pos = UDim2.fromOffset(16, 0), sz = UDim2.new(1, -32, 1, 0), z = 9, wrap = true })
		else
			for k, q in ipairs(qs) do
				local mineN = (q.by and q.by[me]) or 0
				local canClaim = claimable[q.key] == true
				local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 96), z = 8, order = 1 + k, hot = canClaim })
				UI.icon(card, QUEST_ICON[q.key] or "icon_tasks", 32, q.done and C.good or C.manila, UDim2.fromOffset(16, 32), { z = 9 })
				local rightW = 196
				text(card, string.upper(q.name or q.key or "?"), { font = "display", size = 19, pos = UDim2.fromOffset(64, 6), sz = UDim2.new(1, -64 - rightW, 0, 26), z = 9, truncate = true })
				local goal = math.max(1, q.goal or 1)
				local bar = UI.bar(card, q.done and C.good or C.manila, { pos = UDim2.fromOffset(64, 36), sz = UDim2.new(1, -64 - rightW, 0, 22), z = 9 })
				bar:Set((q.prog or 0) / goal, R.Commas(q.prog or 0) .. " / " .. R.Commas(goal), math.floor(math.min(1, (q.prog or 0) / goal) * 100) .. "%")
				text(card, "Reward: +" .. R.Commas((info and info.questXp) or 600) .. " alliance XP, and " .. QUEST_GOLD .. " gold + " .. QUEST_SEALS .. " seals for every member who helped · you helped: " .. R.Commas(mineN),
					{ size = 13, color = C.muted, pos = UDim2.fromOffset(64, 62), sz = UDim2.new(1, -64 - rightW, 0, 30), z = 9, wrap = true, valign = Enum.TextYAlignment.Top })
				if canClaim then
					UI.button(card, "gold", "CLAIM", claim, { sz = UDim2.fromOffset(176, 46), pos = UDim2.new(1, -188, 0, 25), z = 9, icon = "icon_gift" })
				elseif q.done then
					UI.button(card, "locked", mineN > 0 and "CLAIMED" or "COMPLETE", nil, { sz = UDim2.fromOffset(176, 46), pos = UDim2.new(1, -188, 0, 25), z = 9, icon = "icon_check" })
				else
					text(card, "+" .. R.Commas((info and info.questXp) or 600) .. " XP", { font = "display", size = 24, color = C.xp, pos = UDim2.new(1, -188, 0, 22), sz = UDim2.fromOffset(176, 30), z = 9, align = Enum.TextXAlignment.Center })
					text(card, "IN PROGRESS", { font = "heavy", size = 12, color = C.muted, pos = UDim2.new(1, -188, 0, 54), sz = UDim2.fromOffset(176, 16), z = 9, align = Enum.TextXAlignment.Center })
				end
			end
		end
		-- how XP is earned
		local xpPer = info and info.xpPer
		if type(xpPer) == "table" then
			section(list, "HOW ALLIANCE XP IS EARNED", 50)
			local parts = {}
			for _, e in ipairs(XP_LABELS) do
				if xpPer[e[1]] then table.insert(parts, e[2] .. " <font color='#b19cff'><b>" .. xpPer[e[1]] .. " XP</b></font>") end
			end
			local c = UI.card(list, { sz = UDim2.new(1, 0, 0, 62), z = 8, order = 51 })
			UI.icon(c, "icon_xp", 26, C.xp, UDim2.fromOffset(16, 18), { z = 9 })
			text(c, "Every member earns alliance XP just by playing: " .. table.concat(parts, " · "), { size = 14, color = C.ink, rich = true, wrap = true, pos = UDim2.fromOffset(56, 0), sz = UDim2.new(1, -72, 1, 0), z = 9 })
		end
	end

	---------------------------------------------------------------- WAR
	local function war()
		local list = tabList(8)
		local c = UI.card(list, { sz = UDim2.new(1, 0, 0, 150), z = 8, order = 1, hot = true })
		UI.icon(c, "icon_battle", 64, C.bad, UDim2.fromOffset(24, 43), { z = 9 })
		text(c, "ALLIANCE WARS", { font = "display", size = 28, color = C.manila, pos = UDim2.fromOffset(110, 22), sz = UDim2.new(1, -130, 0, 34), z = 9 })
		UI.chip(c, "COMING SOON", { manila = true, icon = "icon_clock", pos = UDim2.fromOffset(110, 60), z = 9 })
		text(c, "Alliance wars are coming soon: declare war on rival alliances and fight for their cities.", { size = 16, color = C.muted, pos = UDim2.fromOffset(110, 92), sz = UDim2.new(1, -130, 0, 44), z = 9, wrap = true, valign = Enum.TextYAlignment.Top })
	end

	function obj:Refresh(st)
		UI.clear(area)
		obj.timer = nil
		local a = st.alliance_rec
		if not st.alliance or not a or type(a.members) ~= "table" then obj.tabs = nil; noAlliance(st); return end
		local myRole = a.members[me] and a.members[me].role
		local info = st.allyInfo
		sub.Text = "[" .. a.tag .. "] " .. a.name .. (info and (" · level " .. (info.level or 1)) or "")
		obj.tabs = UI.tabs(area, { "OVERVIEW", "CITIES", "QUESTS", "WAR" }, function(i) obj.tab = i; obj:Refresh(App.state) end, { w = 130, z = 8 })
		if obj.tab > 4 then obj.tab = 1 end
		obj.tabs:Set(obj.tab)
		local n = claimCount(info)
		if n > 0 then obj.tabs:Label(1, "OVERVIEW (" .. n .. ")") end
		local qn = info and type(info.claim) == "table" and type(info.claim.quests) == "table" and #info.claim.quests or 0
		if qn > 0 then obj.tabs:Label(3, "QUESTS (" .. qn .. ")") end
		if obj.tab == 1 then overview(st, a, myRole, info)
		elseif obj.tab == 2 then cities(st, a)
		elseif obj.tab == 3 then quests(st, a, info)
		else war() end
	end
	function obj:Tick()
		if obj.timer and obj.timer.Parent and obj.weekEnds then obj.timer.Text = "NEW QUESTS IN " .. timeLeft(obj.weekEnds - App.now()) end
	end
	function obj:Opened() obj.list = nil; obj:Refresh(App.state) end
	return obj
end }

---------------------------------------------------------------- RANKINGS
S.rankings = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "RANKINGS")
	local obj = { kind = "level" }
	local KINDS = { "level", "wealth", "alliances" }
	local myUid = Players.LocalPlayer.UserId
	App.showProfile = App.showProfile or function(uid) showProfile(App, uid) end
	local list = UI.list(body, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), gap = 4, z = 6 })
	local function load()
		UI.clear(list)
		text(list, "Loading...", { size = 15, color = C.muted, z = 7 })
		local res = App.req("rankings", { kind = obj.kind })
		UI.clear(list)
		if not res.ok then return end
		if #res.list == 0 then text(list, "Nobody here yet.", { size = 15, color = C.muted, z = 7 }) end
		for k, e in ipairs(res.list) do
			local isPlayer = obj.kind ~= "alliances" and e.uid ~= nil
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 44), z = 7, order = k, hot = k <= 3, button = isPlayer })
			text(card, "#" .. k, { font = "display", size = 20, color = k <= 3 and C.gold or C.muted, pos = UDim2.fromOffset(12, 0), sz = UDim2.fromOffset(56, 44), z = 8 })
			if obj.kind == "alliances" then
				UI.mk("Frame", { BackgroundColor3 = Color3.fromHex(e.color or "546e7a"), BorderSizePixel = 0, Position = UDim2.fromOffset(70, 12), Size = UDim2.fromOffset(20, 20), ZIndex = 8 }, card)
				text(card, "[" .. e.tag .. "] " .. e.name, { font = "heavy", size = 17, pos = UDim2.fromOffset(100, 0), sz = UDim2.new(0.6, -100, 1, 0), z = 8, truncate = true })
				text(card, e.value .. " cities · " .. (e.members or 0) .. " members", { font = "heavy", size = 16, color = C.manila, pos = UDim2.new(0.6, 0, 0, 0), sz = UDim2.new(0.4, -16, 1, 0), z = 8, align = Enum.TextXAlignment.Right })
			else
				-- Roblox avatar headshot instead of the flag (Kash 3 Oct); flag and country live on the profile
				local av = UI.mk("ImageLabel", { BackgroundColor3 = C.black, BackgroundTransparency = 0.3, BorderSizePixel = 0, Position = UDim2.fromOffset(68, 4), Size = UDim2.fromOffset(36, 36), ZIndex = 8,
					Image = e.uid and e.uid > 0 and ("rbxthumb://type=AvatarHeadShot&id=" .. e.uid .. "&w=150&h=150") or "" }, card)
				UI.mk("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
				local isMe = e.uid == myUid
				-- Kash 2 Oct: anyone on the board can be spied on or attacked, whatever server they are in (or offline)
				local canHit = e.uid and not isMe
				local right = canHit and 196 or 16
				-- columns: [#] [flag] [name ... truncated] [value, 140 px] [SPY] [ATTACK]
				local dn = e.dn or e.un or e.name or "?"
				local un = e.un and ("  <font color='#9a9fa6'>@" .. e.un .. "</font>") or ""
				text(card, dn .. un .. (isMe and "  <font color='#f0c75a'>(you)</font>" or ""), { font = "heavy", size = 17, rich = true, pos = UDim2.fromOffset(116, 0), sz = UDim2.new(1, -116 - right - 150, 1, 0), z = 8, truncate = true })
				text(card, obj.kind == "level" and ("Level " .. e.value) or R.Money(e.value), { font = "heavy", size = 17, color = obj.kind == "level" and C.xp or C.good, pos = UDim2.new(1, -right - 140, 0, 0), sz = UDim2.new(0, 140, 1, 0), z = 8, align = Enum.TextXAlignment.Right, truncate = true })
				if canHit then
					local id, nm = "u" .. e.uid, e.dn or e.un or e.name or "?"
					UI.button(card, "slate", "SPY", function(btn)
						local r = App.req("spy", { id = id }, btn)
						if r.ok and r.intel then
							local i = r.intel
							App.toast("INTEL: " .. string.upper(nm), "LV " .. tostring(i.lv or "?") .. " · DEF " .. R.Short(i.def or 0) .. " · " .. R.Money(i.cash or 0) .. " on hand" .. ((i.shield or 0) > 0 and " · SHIELDED" or ""), "good")
						end
					end, { sz = UDim2.fromOffset(84, 34), pos = UDim2.new(1, -182, 0, 5), z = 9, textSize = 14, icon = "icon_satellite" })
					UI.button(card, "red", "ATTACK", function(btn)
						if App.raidTarget then App.raidTarget(id, nm, btn) end
					end, { sz = UDim2.fromOffset(92, 34), pos = UDim2.new(1, -96, 0, 5), z = 9, textSize = 14, icon = "icon_attack" })
				end
				if isPlayer then
					-- the rest of the row opens the player's profile (the SPY/ATTACK buttons sit on top and keep their clicks)
					hover(UI, card)
					local uid = e.uid
					card.Activated:Connect(function() if App.showProfile then App.showProfile(uid) end end)
				end
			end
		end
	end
	local tabs = UI.tabs(body, { "LEVEL", "WEALTH", "ALLIANCES" }, function(i) obj.kind = KINDS[i]; task.spawn(load) end, { w = 140, z = 7 })
	tabs:Set(1)
	UI.button(body, "manila", "MY PROFILE", function() if App.showProfile then App.showProfile(myUid) end end,
		{ sz = UDim2.fromOffset(160, 34), pos = UDim2.new(1, -160, 0, 0), z = 8, icon = "icon_crown", textSize = 15 })
	function obj:Refresh(st) sub.Text = "Top 50 across every server · tap a player to see their profile" end
	function obj:Opened() task.spawn(load) end
	return obj
end }

---------------------------------------------------------------- SHOP
S.shop = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "SHOP")
	local list = UI.list(body, { gap = 8, z = 6 })
	local obj = {}
	local function header(label, order)
		local f = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), ZIndex = 7, LayoutOrder = order }, list)
		text(f, label, { font = "heavy", size = 15, color = C.muted, sz = UDim2.fromScale(1, 1), z = 8 })
	end
	local function item(order, icon, iconColor, title, desc, btnKind, btnLabel, fn)
		local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 66), z = 7, order = order })
		UI.icon(card, icon, 30, iconColor, UDim2.fromOffset(16, 18), { z = 8 })
		text(card, title, { font = "display", size = 20, pos = UDim2.fromOffset(60, 6), sz = UDim2.new(1, -280, 0, 26), z = 8 })
		text(card, desc, { size = 14, color = C.muted, pos = UDim2.fromOffset(60, 34), sz = UDim2.new(1, -280, 0, 22), z = 8, truncate = true })
		UI.button(card, btnKind, btnLabel, fn, { sz = UDim2.fromOffset(200, 46), pos = UDim2.new(1, -212, 0, 10), z = 9, textSize = 15 })
	end
	function obj:Refresh(st)
		UI.clear(list)
		sub.Text = "You have <font color='#f0c75a'><b>" .. R.Commas(st.gold) .. " gold</b></font> · earn it from bosses and daily orders"
		header("SPEND GOLD", 1)
		item(2, "icon_influence", C.inf, "REFILL INFLUENCE", "Fill your Influence bar right now", st.gold >= Config.GoldPrices.inf and "gold" or "locked", Config.GoldPrices.inf .. " GOLD", function(btn) local r = App.req("goldInf", {}, btn); if r.ok then App.toast("INFLUENCE REFILLED", nil, "gold") end end)
		item(3, "icon_supply", C.sup, "REFILL SUPPLY", "Fill your Supply bar for battles, bosses and sieges", st.gold >= Config.GoldPrices.sup and "gold" or "locked", Config.GoldPrices.sup .. " GOLD", function(btn) local r = App.req("goldSup", {}, btn); if r.ok then App.toast("SUPPLY REFILLED", nil, "gold") end end)
		header("GOLD PACKS", 10)
		for k, key in ipairs({ "GoldSmall", "GoldBig" }) do
			local p = Config.Products[key]
			local live = p.id ~= 0
			item(10 + k, "icon_gold", C.gold, p.gold .. " GOLD", key == "GoldBig" and "Best value" or "A handful of refills", live and "green" or "locked", live and ("R$" .. p.robux) or "COMING SOON", function(btn) App.req("buyGold", { key = key }, btn) end)
		end
		header("GAME PASSES (FOREVER)", 20)
		local icons = { FastConvoys = "icon_gauge", AutoDispatch = "icon_bot", ExtraConvoys = "icon_container", ExtraLots = "icon_properties" }
		local order = { "FastConvoys", "AutoDispatch", "ExtraConvoys", "ExtraLots" }
		for k, key in ipairs(order) do
			local p = Config.Passes[key]
			local owned = st.gp and st.gp[key]
			local live = p.id ~= 0
			item(20 + k, icons[key] or "icon_sparkles", C.manila, string.upper(p.name), p.desc, owned and "locked" or (live and "green" or "locked"), owned and "OWNED" or (live and ("R$" .. p.price) or "COMING SOON"), function(btn)
				if owned then return end
				App.req("buyPass", { key = key }, btn)
			end)
		end
		header("CAPITAL", 30)
		local mc = Config.Products.MoveCapital
		item(31, "icon_capitol", C.manila, "MOVE YOUR CAPITAL", "Open any city on the WORLD map and press MAKE THIS MY CAPITAL", "slate", "OPEN MAP", function() App.open("map") end)
		if st.studio then
			local note = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 7, LayoutOrder = 99 }, list)
			text(note, "Studio: every game pass is granted for testing (Config.StudioGrantsPasses). Set workspace attribute IC_NoPasses to test without them.", { size = 13, color = C.dim, sz = UDim2.fromScale(1, 1), z = 8, wrap = true })
		end
	end
	return obj
end }

S.input = nil
return S
