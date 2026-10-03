-- Social screens: ALLIANCE (clans are alliances, Kash Q11), RANKINGS, SHOP.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local W = require(Shared.World)
local Config = require(Shared.Config)

local S = {}
local AC = Config.Alliance
local UPGRADES = {
	{ key = "stipend", name = "STATE STIPEND", icon = "icon_coins", max = 10, desc = function(l) return "Every member earns " .. (3 * l) .. "% of a minute of law cash per minute, online (half while offline)" end },
	{ key = "trade", name = "TRADE NETWORK", icon = "icon_globe", max = 5, desc = function(l) return "+" .. (3 * l) .. "% convoy pay for every member" end },
	{ key = "war", name = "WAR COLLEGE", icon = "icon_attack", max = 5, desc = function(l) return "+" .. (5 * l) .. "% siege damage" end },
	{ key = "fort", name = "FORTIFICATIONS", icon = "icon_castle", max = 5, desc = function(l) return "+" .. (10 * l) .. "% garrison on cities you capture" end },
}
local function upCost(level) return math.floor(2.5e6 * 4 ^ level + 0.5) end

local function frame(host, App, title)
	local UI = App.UI
	local panel, body = UI.panel(host, title, { sz = UDim2.new(1, -20, 1, -20), pos = UDim2.fromOffset(10, 10), z = 5, titleSize = 26 })
	local sub = UI.text(panel, "", { font = "bold", size = 15, color = UI.C.muted, pos = UDim2.new(0, 18, 0, 16), sz = UDim2.new(1, -36, 0, 22), z = 7, align = Enum.TextXAlignment.Right, rich = true })
	return panel, body, sub
end

local function input(UI, parent, placeholder, p)
	local box = UI.img(parent, "input", { pos = p.pos, sz = p.sz, z = p.z or 8 })
	local tb = UI.mk("TextBox", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), Text = p.text or "", PlaceholderText = placeholder,
		PlaceholderColor3 = UI.C.dim, TextColor3 = UI.C.ink, FontFace = UI.Font.bold, TextSize = 17, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, ZIndex = box.ZIndex + 1 }, box)
	return tb
end
S.input = nil

---------------------------------------------------------------- ALLIANCE
S.alliance = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "ALLIANCE")
	local obj = { tab = 1, list = nil }
	local area = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 6 }, body)
	local me = tostring(Players.LocalPlayer.UserId)

	local function noAlliance(st)
		sub.Text = "Alliances fight over the 41 capitals, tax trade through them, and pay their members"
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
		local function mark() for col, s in pairs(swatches) do s.BorderSizePixel = col == obj.form.color and 3 or 0 end end
		for k, col in ipairs(AC.Colors) do
			local s = UI.mk("TextButton", { LayoutOrder = k, Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromHex(col), BorderColor3 = C.manila, BorderMode = Enum.BorderMode.Inset, ZIndex = 9 }, sw)
			swatches[col] = s
			s.Activated:Connect(function() obj.form.color = col; mark() end)
		end
		mark()
		local ok = st.lv >= AC.MinLevel and st.cash >= AC.CreateCost
		UI.button(right, ok and "manila" or "locked", "FOUND · " .. R.Money(AC.CreateCost), function(btn)
			local res = App.req("allyCreate", { name = nameBox.Text, tag = tagBox.Text, color = obj.form.color }, btn)
			if res.ok then App.toast("ALLIANCE FOUNDED", "Invite friends: they can find it in the Alliance list", "good"); obj.list = nil end
		end, { sz = UDim2.new(1, -32, 0, 46), pos = UDim2.new(0, 16, 1, -62), z = 9 })
	end

	local function overview(st, a, myRole)
		local list = UI.list(area, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), gap = 8, z = 7 })
		local head = UI.card(list, { sz = UDim2.new(1, 0, 0, 96), z = 8, order = 1 })
		UI.mk("Frame", { BackgroundColor3 = Color3.fromHex(a.color), BorderSizePixel = 0, Position = UDim2.fromOffset(16, 16), Size = UDim2.fromOffset(64, 64), ZIndex = 9 }, head)
		text(head, a.tag, { font = "display", size = 22, color = C.white, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(16, 16), sz = UDim2.fromOffset(64, 64), z = 10, stroke = 1.5 })
		text(head, a.name, { font = "display", size = 26, pos = UDim2.fromOffset(96, 12), sz = UDim2.new(0.6, -96, 0, 32), z = 9, truncate = true })
		text(head, "Led by " .. (a.leaderName or "?") .. " · " .. (a.count or 0) .. "/" .. AC.MaxMembers .. " members · you are " .. (myRole or "member"), { size = 14, color = C.muted, pos = UDim2.fromOffset(96, 48), sz = UDim2.new(0.6, -96, 0, 20), z = 9 })
		text(head, "TREASURY", { font = "heavy", size = 13, color = C.muted, pos = UDim2.new(0.62, 0, 0, 14), sz = UDim2.new(0.38, -16, 0, 18), z = 9, align = Enum.TextXAlignment.Right })
		text(head, R.Money(a.treasury or 0), { font = "display", size = 30, color = C.gold, pos = UDim2.new(0.62, 0, 0, 34), sz = UDim2.new(0.38, -16, 0, 36), z = 9, align = Enum.TextXAlignment.Right })
		-- donate
		local don = UI.card(list, { sz = UDim2.new(1, 0, 0, 64), z = 8, order = 2 })
		text(don, "DONATE TO THE TREASURY", { font = "heavy", size = 15, pos = UDim2.fromOffset(16, 0), sz = UDim2.new(0.35, 0, 1, 0), z = 9 })
		for k, pct in ipairs({ 0.05, 0.25, 0.5 }) do
			local amt = math.floor(st.cash * pct)
			UI.button(don, amt > 0 and "gold" or "locked", math.floor(pct * 100) .. "% · " .. R.Money(amt), function(btn)
				local res = App.req("allyDonate", { amount = math.floor(App.state.cash * pct) }, btn)
				if res.ok then App.float(btn.Inst, "-" .. R.Money(res.amount), C.gold) end
			end, { sz = UDim2.new(0.21, -8, 0, 42), pos = UDim2.new(0.35 + (k - 1) * 0.21, 0, 0, 11), z = 9, textSize = 14 })
		end
		-- cities + perks
		local held = {}
		for i, cs in pairs(App.world and App.world.cities or {}) do if cs.owner == st.alliance then table.insert(held, i) end end
		local hdr = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), ZIndex = 8, LayoutOrder = 3 }, list)
		local countries = st.mods.countries or {}
		text(hdr, "CITIES HELD " .. #held .. "/" .. AC.MaxCities .. (#countries > 0 and (" · FULL CONTROL: " .. table.concat(countries, ", ") .. " (+10%)") or ""), { font = "heavy", size = 14, color = C.muted, sz = UDim2.fromScale(1, 1), z = 9 })
		if #held == 0 then
			local e = UI.card(list, { sz = UDim2.new(1, 0, 0, 50), z = 8, order = 4 })
			text(e, "No cities yet. Pick an unclaimed city on the WORLD map and attack it with your alliance.", { size = 15, color = C.muted, pos = UDim2.fromOffset(16, 0), sz = UDim2.new(1, -32, 1, 0), z = 9, wrap = true })
		end
		for k, i in ipairs(held) do
			local cs = App.world.cities[i]
			local city = W.Cities[i]
			local card = UI.card(list, { button = true, sz = UDim2.new(1, 0, 0, 50), z = 8, order = 4 + k })
			UI.icon(card, "icon_flag", 20, Color3.fromHex(a.color), UDim2.fromOffset(14, 15), { z = 9 })
			text(card, city.name .. " · " .. city.country, { font = "heavy", size = 16, pos = UDim2.fromOffset(44, 0), sz = UDim2.new(0.4, -44, 1, 0), z = 9 })
			text(card, "Tax " .. (cs.tax or 0) .. "% · Garrison " .. R.Short(cs.hp) .. " · +" .. ({ 3, 5, 8, 12 })[city.tier] .. "% " .. city.perk, { size = 14, color = C.muted, pos = UDim2.new(0.4, 0, 0, 0), sz = UDim2.new(0.6, -16, 1, 0), z = 9, align = Enum.TextXAlignment.Right })
			card.Activated:Connect(function() App.open("map"); if App.focusCity then App.focusCity(i) end end)
		end
		local leave = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 48), ZIndex = 8, LayoutOrder = 100 }, list)
		UI.button(leave, "red", "LEAVE ALLIANCE", function(btn)
			App.confirm("LEAVE " .. a.name .. "?", "You will lose the alliance perks and stipend." .. (myRole == "leader" and " Leadership passes to your longest-serving officer." or ""), "LEAVE", "red", function()
				App.req("allyLeave", {}, btn); obj.list = nil
			end)
		end, { sz = UDim2.fromOffset(200, 42), z = 9 })
		if myRole == "leader" then
			UI.button(leave, "slate", a.open == false and "INVITE ONLY: ON" or "OPEN TO ALL", function(btn) App.req("allyOpen", { open = a.open == false }, btn) end, { sz = UDim2.fromOffset(200, 42), pos = UDim2.fromOffset(210, 0), z = 9 })
		end
	end

	local function members(st, a, myRole)
		local list = UI.list(area, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), gap = 6, z = 7 })
		local rows = {}
		for uid, m in pairs(a.members) do table.insert(rows, { uid = uid, m = m }) end
		local rank = { leader = 1, officer = 2, member = 3 }
		table.sort(rows, function(x, y) if rank[x.m.role] ~= rank[y.m.role] then return rank[x.m.role] < rank[y.m.role] end; return (x.m.donated or 0) > (y.m.donated or 0) end)
		for k, r in ipairs(rows) do
			local m = r.m
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 52), z = 8, order = k })
			UI.icon(card, m.role == "leader" and "icon_crown" or (m.role == "officer" and "icon_defense" or "icon_users"), 22, m.role == "leader" and C.gold or C.manila, UDim2.fromOffset(14, 15), { z = 9 })
			text(card, m.name .. (r.uid == me and " (you)" or ""), { font = "heavy", size = 16, pos = UDim2.fromOffset(46, 0), sz = UDim2.new(0.35, -46, 1, 0), z = 9, truncate = true })
			text(card, string.upper(m.role) .. " · donated " .. R.Money(m.donated or 0), { size = 14, color = C.muted, pos = UDim2.new(0.35, 0, 0, 0), sz = UDim2.new(0.3, 0, 1, 0), z = 9 })
			if r.uid ~= me then
				local x = -10
				local function act(label, kind, fn)
					local w = 96
					x -= w
					UI.button(card, kind, label, fn, { sz = UDim2.fromOffset(w - 6, 36), pos = UDim2.new(1, x, 0, 8), z = 9, textSize = 13 })
				end
				if myRole == "leader" then
					act("REMOVE", "red", function(btn) App.confirm("REMOVE " .. m.name .. "?", "They leave the alliance right away.", "REMOVE", "red", function() App.req("allyKick", { uid = r.uid }, btn) end) end)
					if m.role == "member" then act("PROMOTE", "slate", function(btn) App.req("allyRole", { uid = r.uid, role = "officer" }, btn) end)
					else act("DEMOTE", "slate", function(btn) App.req("allyRole", { uid = r.uid, role = "member" }, btn) end) end
					act("MAKE LEADER", "gold", function(btn) App.confirm("HAND OVER LEADERSHIP?", m.name .. " becomes leader and you become an officer.", "HAND OVER", "gold", function() App.req("allyRole", { uid = r.uid, role = "leader" }, btn) end) end)
				elseif myRole == "officer" and m.role == "member" then
					act("REMOVE", "red", function(btn) App.req("allyKick", { uid = r.uid }, btn) end)
				end
			end
		end
	end

	local function upgrades(st, a, myRole)
		local list = UI.list(area, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), gap = 8, z = 7 })
		for k, u in ipairs(UPGRADES) do
			local lvl = a.up and a.up[u.key] or 0
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 80), z = 8, order = k })
			UI.icon(card, u.icon, 34, C.manila, UDim2.fromOffset(16, 22), { z = 9 })
			text(card, u.name .. "  <font color='#9a9fa6'>LV " .. lvl .. "/" .. u.max .. "</font>", { font = "display", size = 21, rich = true, pos = UDim2.fromOffset(64, 8), sz = UDim2.new(1, -280, 0, 28), z = 9 })
			text(card, lvl > 0 and u.desc(lvl) or ("Level 1: " .. u.desc(1)), { size = 14, color = C.muted, pos = UDim2.fromOffset(64, 42), sz = UDim2.new(1, -280, 0, 30), z = 9, wrap = true })
			if lvl >= u.max then
				UI.button(card, "locked", "MAXED", nil, { sz = UDim2.fromOffset(200, 46), pos = UDim2.new(1, -212, 0, 17), z = 9 })
			else
				local cost = upCost(lvl)
				local can = (myRole == "leader" or myRole == "officer") and (a.treasury or 0) >= cost
				UI.button(card, can and "gold" or "locked", "UPGRADE · " .. R.Money(cost), function(btn) App.req("allyUpgrade", { key = u.key }, btn) end, { sz = UDim2.fromOffset(200, 46), pos = UDim2.new(1, -212, 0, 17), z = 9, textSize = 15 })
			end
		end
		local note = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), ZIndex = 8, LayoutOrder = 10 }, list)
		text(note, "Upgrades are paid from the treasury (donations and city tax). Only the leader and officers can buy them.", { size = 14, color = C.muted, sz = UDim2.fromScale(1, 1), z = 9, wrap = true })
	end

	local function log(st, a)
		local list = UI.list(area, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), gap = 4, z = 7 })
		for k, e in ipairs(a.log or {}) do
			local row = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), ZIndex = 8, LayoutOrder = k }, list)
			text(row, os.date("!%d %b %H:%M", e.t), { size = 14, color = C.muted, sz = UDim2.fromOffset(110, 24), z = 9 })
			text(row, e.m, { size = 15, pos = UDim2.fromOffset(116, 0), sz = UDim2.new(1, -116, 1, 0), z = 9 })
		end
	end

	function obj:Refresh(st)
		UI.clear(area)
		local a = st.alliance_rec
		if not st.alliance or not a then obj.tabs = nil; noAlliance(st); return end
		local myRole = a.members[me] and a.members[me].role
		sub.Text = "[" .. a.tag .. "] " .. a.name .. " · stipend level " .. ((a.up and a.up.stipend) or 0)
		obj.tabs = UI.tabs(area, { "OVERVIEW", "MEMBERS", "UPGRADES", "LOG" }, function(i) obj.tab = i; obj:Refresh(App.state) end, { w = 130, z = 8 })
		obj.tabs:Set(obj.tab)
		if obj.tab == 1 then overview(st, a, myRole)
		elseif obj.tab == 2 then members(st, a, myRole)
		elseif obj.tab == 3 then upgrades(st, a, myRole)
		else log(st, a) end
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
	local list = UI.list(body, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), gap = 4, z = 6 })
	local function load()
		UI.clear(list)
		text(list, "Loading...", { size = 15, color = C.muted, z = 7 })
		local res = App.req("rankings", { kind = obj.kind })
		UI.clear(list)
		if not res.ok then return end
		if #res.list == 0 then text(list, "Nobody here yet.", { size = 15, color = C.muted, z = 7 }) end
		for k, e in ipairs(res.list) do
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 44), z = 7, order = k, hot = k <= 3 })
			text(card, "#" .. k, { font = "display", size = 20, color = k <= 3 and C.gold or C.muted, pos = UDim2.fromOffset(12, 0), sz = UDim2.fromOffset(56, 44), z = 8 })
			if obj.kind == "alliances" then
				UI.mk("Frame", { BackgroundColor3 = Color3.fromHex(e.color or "546e7a"), BorderSizePixel = 0, Position = UDim2.fromOffset(70, 12), Size = UDim2.fromOffset(20, 20), ZIndex = 8 }, card)
				text(card, "[" .. e.tag .. "] " .. e.name, { font = "heavy", size = 17, pos = UDim2.fromOffset(100, 0), sz = UDim2.new(0.6, -100, 1, 0), z = 8, truncate = true })
				text(card, e.value .. " cities · " .. (e.members or 0) .. " members", { font = "heavy", size = 16, color = C.manila, pos = UDim2.new(0.6, 0, 0, 0), sz = UDim2.new(0.4, -16, 1, 0), z = 8, align = Enum.TextXAlignment.Right })
			else
				if e.flag then UI.flag(card, e.flag, 36, { pos = UDim2.fromOffset(70, 10), z = 8 }) end
				text(card, (e.tag and ("[" .. e.tag .. "] ") or "") .. (e.name or "?"), { font = "heavy", size = 17, pos = UDim2.fromOffset(116, 0), sz = UDim2.new(0.6, -116, 1, 0), z = 8, truncate = true })
				text(card, obj.kind == "level" and ("Level " .. e.value) or R.Money(e.value), { font = "heavy", size = 17, color = obj.kind == "level" and C.xp or C.good, pos = UDim2.new(0.6, 0, 0, 0), sz = UDim2.new(0.4, -16, 1, 0), z = 8, align = Enum.TextXAlignment.Right })
			end
		end
	end
	local tabs = UI.tabs(body, { "LEVEL", "WEALTH", "ALLIANCES" }, function(i) obj.kind = KINDS[i]; task.spawn(load) end, { w = 140, z = 7 })
	tabs:Set(1)
	function obj:Refresh(st) sub.Text = "Top 50 across every server · updates every few minutes" end
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
		item(2, "icon_influence", C.inf, "REFILL INFLUENCE", "Fill your Influence bar right now", st.gold >= 10 and "gold" or "locked", "10 GOLD", function(btn) local r = App.req("goldInf", {}, btn); if r.ok then App.toast("INFLUENCE REFILLED", nil, "gold") end end)
		item(3, "icon_supply", C.sup, "REFILL SUPPLY", "Fill your Supply bar for battles, bosses and sieges", st.gold >= 5 and "gold" or "locked", "5 GOLD", function(btn) local r = App.req("goldSup", {}, btn); if r.ok then App.toast("SUPPLY REFILLED", nil, "gold") end end)
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
