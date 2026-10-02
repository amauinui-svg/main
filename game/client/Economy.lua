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

---------------------------------------------------------------- PROPERTIES
S.properties = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "PROPERTIES")
	local obj = { tab = 1 }
	local list = UI.list(body, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), gap = 8, z = 6 })
	local tabs = UI.tabs(body, { "YOUR BLOCK", "BUILD" }, function(i) obj.tab = i; obj:Refresh(App.state) end, { w = 150, z = 7 })
	tabs:Set(1)

	local function lotGrid(st)
		local grid = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 6, LayoutOrder = 1 }, list)
		UI.mk("UIGridLayout", { CellSize = UDim2.new(0.25, -8, 0, 132), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
		local counts = {}
		for k = 1, st.lotsMax do
			local p = st.lots[k]
			if p and p > 0 then
				local P = D.Props[p]
				counts[p] = (counts[p] or 0) + 1
				local card = UI.card(grid, { z = 7, order = k })
				UI.icon(card, "icon_house", 22, C.manila, UDim2.fromOffset(10, 10), { z = 8 })
				text(card, P.n, { font = "heavy", size = 16, pos = UDim2.fromOffset(38, 8), sz = UDim2.new(1, -46, 0, 22), z = 8, truncate = true })
				text(card, D.Eras[P.era].name .. " · Tier " .. P.tier, { size = 13, color = C.muted, pos = UDim2.fromOffset(12, 34), sz = UDim2.new(1, -20, 0, 16), z = 8 })
				text(card, "+" .. R.Money(P.inc * st.mods.props) .. "/hr", { font = "heavy", size = 18, color = C.good, pos = UDim2.fromOffset(12, 52), sz = UDim2.new(1, -20, 0, 24), z = 8 })
				UI.button(card, "red", "DEMOLISH", function(btn)
					local s = App.state
					local owned = R.CountProps(s.lots)[p] or 1
					local refund = math.floor(R.PropCost(p, owned - 1) * R.DemolishRefund)
					App.confirm("DEMOLISH?", "Tear down <b>" .. P.n .. "</b> and get back <b>" .. R.Money(refund) .. "</b> (25% of its price). The lot becomes empty.", "DEMOLISH", "red", function()
						App.req("demolish", { lot = k }, btn)
					end)
				end, { pos = UDim2.new(0, 10, 1, -46), sz = UDim2.new(1, -20, 0, 36), z = 9, textSize = 15 })
			else
				local card = UI.card(grid, { z = 7, order = k })
				UI.icon(card, "icon_tent", 30, C.dim, UDim2.new(0.5, 0, 0, 14), { z = 8, anchor = Vector2.new(0.5, 0) })
				text(card, "EMPTY LOT", { font = "display", size = 18, color = C.muted, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 50), sz = UDim2.new(1, 0, 0, 22), z = 8 })
				UI.button(card, "manila", "BUILD", function() obj.tab = 2; tabs:Set(2); obj:Refresh(App.state) end, { pos = UDim2.new(0, 10, 1, -46), sz = UDim2.new(1, -20, 0, 36), z = 9, textSize = 15 })
			end
		end
		local more = UI.card(grid, { z = 7, order = 1000 })
		UI.icon(more, "icon_lock", 26, C.dim, UDim2.new(0.5, 0, 0, 12), { z = 8, anchor = Vector2.new(0.5, 0) })
		local nextCost = R.SkillByKey.lot.cost(st.sk.lot or 0)
		text(more, "MORE LOTS", { font = "display", size = 17, color = C.muted, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 42), sz = UDim2.new(1, 0, 0, 22), z = 8 })
		text(more, "Next lot: " .. nextCost .. " skill points", { size = 13, color = C.muted, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 64), sz = UDim2.new(1, 0, 0, 18), z = 8 })
		UI.button(more, "slate", "UPGRADES", function() App.open("country") end, { pos = UDim2.new(0, 10, 1, -46), sz = UDim2.new(1, -20, 0, 36), z = 9, textSize = 15 })
		if not (st.gp and st.gp.ExtraLots) then
			local pass = UI.card(grid, { z = 7, order = 1001, hot = true })
			UI.icon(pass, "icon_plus", 26, C.gold, UDim2.new(0.5, 0, 0, 12), { z = 8, anchor = Vector2.new(0.5, 0) })
			text(pass, "+3 LOTS", { font = "display", size = 17, color = C.gold, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 42), sz = UDim2.new(1, 0, 0, 22), z = 8 })
			text(pass, "Game pass, forever", { size = 13, color = C.muted, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 64), sz = UDim2.new(1, 0, 0, 18), z = 8 })
			local Config = require(Shared.Config)
			local live = Config.Passes.ExtraLots.id ~= 0
			UI.button(pass, live and "gold" or "locked", live and ("R$" .. Config.Passes.ExtraLots.price) or "COMING SOON", function(btn) App.req("buyPass", { key = "ExtraLots" }, btn) end, { pos = UDim2.new(0, 10, 1, -46), sz = UDim2.new(1, -20, 0, 36), z = 9, textSize = 14 })
		end
	end

	local function buildList(st)
		local counts = R.CountProps(st.lots)
		local free = 0
		for k = 1, st.lotsMax do if not st.lots[k] or st.lots[k] == 0 then free += 1 end end
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
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 64), z = 7, order = isLocked and (1000 + order) or order })
			UI.icon(card, isLocked and "icon_lock" or "icon_house", 24, isLocked and C.dim or C.manila, UDim2.fromOffset(12, 20), { z = 8 })
			text(card, P.n .. (owned > 0 and ("  <font color='#9a9fa6'>x" .. owned .. "</font>") or ""), { font = "heavy", size = 17, rich = true, pos = UDim2.fromOffset(46, 8), sz = UDim2.new(0.4, -46, 0, 22), z = 8, truncate = true })
			text(card, D.Eras[P.era].name .. " · Tier " .. P.tier .. (isLocked and (" · unlocks at level " .. P.lvl) or ""), { size = 13, color = C.muted, pos = UDim2.fromOffset(46, 32), sz = UDim2.new(0.45, -46, 0, 18), z = 8 })
			text(card, "+" .. R.Money(inc) .. "/hr", { font = "heavy", size = 17, color = C.good, pos = UDim2.new(0.42, 0, 0, 8), sz = UDim2.new(0.2, 0, 0, 22), z = 8 })
			text(card, "Pays back in " .. R.Duration(cost / math.max(1, inc) * 3600), { size = 13, color = C.muted, pos = UDim2.new(0.42, 0, 0, 32), sz = UDim2.new(0.24, 0, 0, 18), z = 8 })
			local kind = isLocked and "locked" or (free == 0 and "slate") or (st.cash >= cost and "green") or "slate"
			UI.button(card, kind, isLocked and ("LEVEL " .. P.lvl) or ("BUILD " .. R.Money(cost)), function(btn)
				if isLocked then App.toast("Unlocks at level " .. P.lvl, nil, "bad"); App.shake(btn.Inst); return end
				local res = App.req("build", { i = i }, btn)
				if res.ok then App.toast(P.n .. " BUILT", "Lot " .. res.lot .. " · +" .. R.Money(inc) .. "/hr", "good") end
			end, { pos = UDim2.new(1, -196, 0, 12), sz = UDim2.fromOffset(186, 40), z = 9, textSize = 15 })
		end
		for _, i in ipairs(rows) do rowFor(i, false) end
		for _, i in ipairs(locked) do rowFor(i, true) end
	end

	function obj:Refresh(st)
		UI.clear(list)
		local used = 0
		for k = 1, st.lotsMax do if st.lots[k] and st.lots[k] > 0 then used += 1 end end
		sub.Text = "Lots <b>" .. used .. "/" .. st.lotsMax .. "</b> · Income <font color='#8fd07a'><b>" .. R.Money(st.incHr) .. "/hr</b></font>" .. (st.mods.props > 1 and (" (+" .. math.floor((st.mods.props - 1) * 100 + 0.5) .. "%)") or "") .. " · 50% keeps earning while you are offline"
		if obj.tab == 1 then lotGrid(st) else buildList(st) end
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

---------------------------------------------------------------- BANK
S.bank = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "NATIONAL BANK")
	local obj = {}
	local left = UI.card(body, { sz = UDim2.new(0.5, -6, 0, 250), z = 6 })
	local right = UI.card(body, { sz = UDim2.new(0.5, -6, 1, 0), pos = UDim2.new(0.5, 6, 0, 0), z = 6 })
	function obj:Refresh(st)
		UI.clear(left); UI.clear(right)
		sub.Text = "Borrow now, pay back from what you earn"
		UI.icon(left, "icon_bank", 30, C.manila, UDim2.fromOffset(16, 16), { z = 7 })
		text(left, "STATE LOAN", { font = "display", size = 22, pos = UDim2.fromOffset(56, 16), sz = UDim2.new(1, -70, 0, 30), z = 7 })
		if st.loan then
			text(left, "You owe <b>" .. R.Money(st.loan.owed) .. "</b>\n20% of everything you earn goes to repaying it until it is cleared.", { size = 16, rich = true, wrap = true, pos = UDim2.fromOffset(16, 60), sz = UDim2.new(1, -32, 0, 80), z = 7, valign = Enum.TextYAlignment.Top })
			local bar = UI.bar(left, C.good, { pos = UDim2.fromOffset(16, 146), sz = UDim2.new(1, -32, 0, 24), z = 7 })
			local total = math.floor(st.loan.amt * 1.1)
			bar:Set(1 - st.loan.owed / math.max(1, total), "REPAID " .. math.floor((1 - st.loan.owed / math.max(1, total)) * 100) .. "%", R.Money(total - st.loan.owed) .. " / " .. R.Money(total))
			UI.button(left, st.cash > 0 and "manila" or "locked", "REPAY " .. R.Money(math.min(st.cash, st.loan.owed)), function(btn) App.req("loanRepay", {}, btn) end, { pos = UDim2.new(0, 16, 1, -60), sz = UDim2.new(1, -32, 0, 44), z = 8 })
		else
			text(left, "Borrow <b>" .. R.Money(st.loanMax) .. "</b> right now (about an hour of laws plus two hours of property income).\nYou pay back 110%. 20% of everything you earn repays it automatically.", { size = 16, rich = true, wrap = true, pos = UDim2.fromOffset(16, 60), sz = UDim2.new(1, -32, 0, 110), z = 7, valign = Enum.TextYAlignment.Top })
			UI.button(left, st.lv >= 3 and "green" or "locked", st.lv >= 3 and ("BORROW " .. R.Money(st.loanMax)) or "UNLOCKS AT LEVEL 3", function(btn)
				App.confirm("TAKE THE LOAN?", "Borrow <b>" .. R.Money(App.state.loanMax) .. "</b> and repay <b>" .. R.Money(math.floor(App.state.loanMax * 1.1)) .. "</b>.", "BORROW", "green", function()
					App.req("loanTake", {}, btn)
				end)
			end, { pos = UDim2.new(0, 16, 1, -60), sz = UDim2.new(1, -32, 0, 44), z = 8 })
		end
		UI.icon(right, "icon_book", 28, C.manila, UDim2.fromOffset(16, 16), { z = 7 })
		text(right, "NATIONAL RECORD", { font = "display", size = 22, pos = UDim2.fromOffset(56, 16), sz = UDim2.new(1, -70, 0, 30), z = 7 })
		local s = st.stats
		local lines = {
			{ "Total earned", R.Money(s.earned) }, { "Laws passed", R.Commas(s.laws) }, { "Convoy deliveries", R.Commas(s.trips) },
			{ "Battles won", R.Commas(s.wins) .. " / " .. R.Commas(s.battles) }, { "Bosses defeated", R.Commas(s.bosses) }, { "Siege and boss hits", R.Commas(s.hits) },
			{ "Properties built", R.Commas(s.built) }, { "Property income", R.Money(st.incHr) .. "/hr" }, { "Attack / Defense", R.Short(st.atk) .. " / " .. R.Short(st.def) },
		}
		for k, l in ipairs(lines) do
			local y = 56 + (k - 1) * 28
			text(right, l[1], { size = 16, color = C.muted, pos = UDim2.fromOffset(20, y), sz = UDim2.new(0.55, -20, 0, 24), z = 7 })
			text(right, l[2], { font = "heavy", size = 16, pos = UDim2.new(0.55, 0, 0, y), sz = UDim2.new(0.45, -20, 0, 24), z = 7, align = Enum.TextXAlignment.Right })
		end
	end
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
