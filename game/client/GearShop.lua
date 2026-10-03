-- GEAR SHOP (Kash 2 Oct 23:26): a second tab inside SHOP. Restocks every 5 minutes with 3 random items of every
-- rarity, one of each per player. Higher rarities unlock at higher levels. Bought with cash.
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local O = require(Shared.Officers)
local Config = require(Shared.Config)

local S = {}

local SHORT = { law = "law cash", props = "property income", convoy = "convoy pay", xp = "XP", attack = "attack", defense = "defense",
	loot = "raid loot", losses = "fewer deaths", interest = "bank interest", regen = "Influence regen", siege = "siege damage", boss = "boss damage" }

S.gearshop = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local obj = {}
	local data, loading = nil, false
	local cards = {}

	local panel, body = UI.panel(host, "GEAR SHOP", { sz = UDim2.new(1, -20, 1, -20), pos = UDim2.fromOffset(10, 10), z = 5, titleSize = 26 })
	local _ = panel
	local timer = text(body, "", { font = "heavy", size = 16, color = C.gold, rich = true, pos = UDim2.fromOffset(0, 2), sz = UDim2.new(1, 0, 0, 22), z = 7, align = Enum.TextXAlignment.Right })
	text(body, "New gear every 5 minutes. One of each item per restock. Rarer gear unlocks as you level up.", { size = 15, color = C.muted, pos = UDim2.fromOffset(0, 2), sz = UDim2.new(1, -260, 0, 22), z = 7, truncate = true })
	local list = UI.list(body, { pos = UDim2.fromOffset(0, 34), sz = UDim2.new(1, 0, 1, -34), gap = 8, z = 6 })

	local function stat(g)
		local s = "+" .. tostring(g.power or 0) .. "% " .. (g.kind == "weapon" and "attack" or "defense")
		if g.perk then s ..= "\n<font color='#8fd07a'>+" .. tostring(g.perk.v) .. "% " .. (SHORT[g.perk.k] or g.perk.k) .. "</font>" end
		return s
	end

	local function setBtn(c)
		local st = App.state
		local e = c.e
		if e.bought then c.btn:Set("locked", "SOLD")
		elseif (st.lv or 1) < e.lvl then c.btn:Set("locked", "LEVEL " .. e.lvl)
		elseif (st.cash or 0) < e.cost then c.btn:Set("slate", R.Money(e.cost))
		else c.btn:Set("green", "BUY " .. R.Money(e.cost)) end
	end

	local function build()
		UI.clear(list)
		cards = {}
		if not data then
			text(list, "Loading the shop...", { size = 16, color = C.muted, sz = UDim2.new(1, 0, 0, 30), z = 7 })
			return
		end
		local byR = {}
		for _, e in ipairs(data.items) do
			local r = O.RarityByKey[e.gear.rarity].index
			byR[r] = byR[r] or {}
			table.insert(byR[r], e)
		end
		local order = 0
		for r = 1, #Config.GearShop.Levels do
			local rar = O.Rarities[r]
			local col = Color3.fromHex(rar.color)
			local need = Config.GearShop.Levels[r]
			local locked = (App.state.lv or 1) < need
			order += 1
			local head = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 26), ZIndex = 7, LayoutOrder = order }, list)
			text(head, rar.name, { font = "heavy", size = 18, color = col, stroke = 1, sz = UDim2.new(0.5, 0, 1, 0), z = 8 })
			if locked then text(head, "Unlocks at level " .. need, { font = "bold", size = 14, color = C.muted, sz = UDim2.new(1, 0, 1, 0), z = 8, align = Enum.TextXAlignment.Right }) end
			order += 1
			local row = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 132), ZIndex = 7, LayoutOrder = order }, list)
			mk("UIGridLayout", { CellSize = UDim2.new(1 / 3, -8, 1, 0), CellPadding = UDim2.fromOffset(10, 0), SortOrder = Enum.SortOrder.LayoutOrder }, row)
			for k, e in ipairs(byR[r] or {}) do
				local g = e.gear
				local card = UI.card(row, { z = 8, order = k })
				mk("UIStroke", { Color = col, Thickness = 2, Transparency = locked and 0.6 or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
				local well = mk("Frame", { BackgroundColor3 = C.black, BackgroundTransparency = 0.2, BorderSizePixel = 0, Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(84, 84), ZIndex = 9 }, card)
				mk("UICorner", { CornerRadius = UDim.new(0, 8) }, well)
				local glow = mk("UIGradient", { Color = ColorSequence.new(col:Lerp(C.black, 0.55), C.black), Rotation = 90 }, well)
				local _g = glow
				UI.img(well, g.icon, { sz = UDim2.fromScale(0.86, 0.86), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 10, slice = false, fit = true,
					color = locked and Color3.fromHex("444444") or nil })
				if locked then UI.icon(well, "icon_lock", 26, C.gold, UDim2.fromScale(0.5, 0.5), { z = 11, anchor = Vector2.new(0.5, 0.5) }) end
				text(card, g.name, { font = "heavy", size = 16, pos = UDim2.fromOffset(104, 10), sz = UDim2.new(1, -112, 0, 22), z = 9, truncate = true })
				text(card, (g.kind == "weapon" and "WEAPON" or "ARMOR") .. " · " .. rar.name, { font = "bold", size = 12, color = col, pos = UDim2.fromOffset(104, 32), sz = UDim2.new(1, -112, 0, 16), z = 9, truncate = true })
				text(card, stat(g), { size = 14, rich = true, wrap = true, pos = UDim2.fromOffset(104, 50), sz = UDim2.new(1, -112, 0, 40), z = 9, valign = Enum.TextYAlignment.Top })
				local c = { e = e }
				c.btn = UI.button(card, "green", "BUY", function(btn)
					local st = App.state
					if e.bought then App.toast("Sold out", "New stock in the next restock", "info"); return end
					if (st.lv or 1) < e.lvl then App.toast("Unlocks at level " .. e.lvl, nil, "bad"); App.shake(btn.Inst); return end
					local res = App.req("gearBuy", { i = e.i, w = data.w }, btn)
					if res.ok then
						e.bought = true
						setBtn(c)
						App.toast(string.upper(g.name) .. " BOUGHT", "Equip it on an officer in MILITARY > OFFICERS", "gold")
						App.play("purchase", { volume = 0.45 })
					elseif res.msg and res.msg:find("restocked") then obj.load() end
				end, { pos = UDim2.new(0, 10, 1, -38), sz = UDim2.new(1, -20, 0, 30), z = 10, textSize = 14 })
				setBtn(c)
				table.insert(cards, c)
			end
		end
	end

	function obj.load()
		if loading then return end
		loading = true
		task.spawn(function()
			local res = App.req("gearShop", {})
			loading = false
			if res.ok then data = res; build() end
		end)
	end

	function obj:Refresh(st) for _, c in ipairs(cards) do setBtn(c) end end
	function obj:Opened() obj.load() end
	App.on("tick", function()
		if not host.Visible or not data then return end
		local left = data.ends - math.floor(App.now())
		if left <= 0 then timer.Text = "RESTOCKING..."; obj.load(); return end
		timer.Text = "RESTOCK IN <font color='#ece8dc'>" .. string.format("%d:%02d", left // 60, left % 60) .. "</font>"
	end)
	build()
	return obj
end }

return S
