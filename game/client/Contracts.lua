-- CONTRACTS (screen key "tasks"), modelled on Idle Mafia's CONTRACTS tab (Kash 1 Oct 16:47):
-- daily orders (easy/medium/hard + a bonus for all 5) and weekly challenges (+ a bonus chest for all 5) that pay SEALS
-- and cash, a REPLACE per order (1 free a day, then 19 R$), and the SEALS SHOP where seals buy tickets, refills, crates.
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local TK = require(Shared.Tasks)
local Config = require(Shared.Config)

local S = {}

local WEEKLY_COLOR = Color3.fromHex("a77bff")
-- short subtitles under each order, by task key
local SUB = {
	laws = "Pass laws on the Laws tab.", trips = "Convoys that arrive at a city.", raids = "Win raids against other players.",
	build = "Build on your lots in Properties.", hits = "Siege a city or hit the boss.", units = "Recruit soldiers in Military.",
	boss = "Bring the era boss down.", deposit = "Put any amount in the bank.", donate = "Give cash to your alliance treasury.",
	hire = "Hire from the Officers tab.", crate = "Open any crate.", influence = "Influence spent on laws.",
	supply = "Supply spent on attacks.", level = "Level up your country.", earn = "Counted in minutes of law income.",
	moves = "Different destination cities.", online = "Minutes played.", siege = "Alliance siege hits on cities.",
}

local function hms(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%02d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60)
end
local function tween(o, t, props, style)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad), props)
	tw:Play()
	return tw
end
local function hoverStroke(UI, gui, color, base)
	local st = UI.mk("UIStroke", { Color = color, Thickness = 2, Transparency = base or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, gui)
	gui.MouseEnter:Connect(function() tween(st, 0.15, { Transparency = 0.1 }) end)
	gui.MouseLeave:Connect(function() tween(st, 0.2, { Transparency = base or 1 }) end)
	return st
end
local function dailyLeft(now) return 86400 - (now % 86400) end
local function weeklyLeft(now)
	local nextStart = (7 * (TK.Week(now) + 1) - 3) * 86400 -- weeks start Monday 00:00 UTC
	return nextStart - now
end
local function longLeft(sec)
	local days = math.floor(sec / 86400)
	if days >= 1 then return days .. (days == 1 and " day " or " days ") .. hms(sec % 86400) end
	return hms(sec)
end

S.tasks = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local panel, body = UI.panel(host, "CONTRACTS", { sz = UDim2.new(1, -20, 1, -20), pos = UDim2.fromOffset(10, 10), z = 5, titleSize = 26 })
	local obj = { tab = 1, timers = {} }

	-- top-right chips: seals + next orders
	local chipRow = UI.mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 12), Size = UDim2.fromOffset(460, 30), ZIndex = 7 }, panel)
	UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, chipRow)
	local sealChip, sealL = UI.chip(chipRow, "0 SEALS", { order = 1, h = 30, size = 15, icon = "icon_seal", iconColor = C.white, z = 8 })
	local _, newL = UI.chip(chipRow, "NEW ORDERS IN 00:00:00", { order = 2, h = 30, size = 15, icon = "icon_clock", iconColor = C.blue, z = 8 })
	-- the seal icon is a coloured image, not a white glyph: show it untinted
	local sealIcon = sealChip:FindFirstChild("Icon")
	if sealIcon then sealIcon.ImageColor3 = C.white end

	text(body, "Daily and weekly orders reward Seals, spent in the Seals Shop.", { size = 16, color = C.muted, sz = UDim2.new(1, 0, 0, 22), z = 7, truncate = true })
	local tabs = UI.tabs(body, { "ORDERS", "SEALS SHOP" }, function(i) obj.tab = i; obj:Refresh(App.state) end, { pos = UDim2.fromOffset(0, 28), w = 170, z = 7, textSize = 16, sz = UDim2.new(1, 0, 0, 38) })
	tabs:Set(1)
	local area = UI.mk("Frame", { Name = "Area", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 1, -76), ZIndex = 6 }, body)
	local list -- current ScrollingFrame

	------------------------------------------------ rows
	local function sectionHead(title, order, key)
		local h = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), ZIndex = 7, LayoutOrder = order }, list)
		text(h, title, { font = "display", size = 24, color = C.gold, sz = UDim2.new(0.6, 0, 1, 0), z = 8 })
		local r = text(h, "", { size = 15, color = C.muted, align = Enum.TextXAlignment.Right, pos = UDim2.fromScale(0.5, 0), sz = UDim2.new(0.5, -4, 1, 0), z = 8 })
		obj.timers[key] = r
	end

	local function diffChip(parent, label, color, z)
		local box = UI.img(parent, "inset", { pos = UDim2.new(0, 12, 0.5, 0), anchor = Vector2.new(0, 0.5), sz = UDim2.fromOffset(78, 28), z = z })
		text(box, label, { font = "heavy", size = 14, color = color, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = z + 1, scaled = true })
		return box
	end

	local function rewardChips(parent, parts, z)
		local holder = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 32), Size = UDim2.new(1, 0, 0, 24), ZIndex = z }, parent)
		UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, holder)
		for k, p in ipairs(parts) do
			local c = UI.chip(holder, p[1], { order = k, h = 24, size = 13, icon = p[2], iconColor = p[3], color = p[4], z = z + 1 })
			if p[2] == "icon_seal" then local ic = c:FindFirstChild("Icon"); if ic then ic.ImageColor3 = C.white end end
		end
	end

	local function rowFrame(order, gold)
		local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 76), z = 7, order = order, hot = gold })
		if gold then UI.mk("UIStroke", { Color = C.gold, Thickness = 2, Transparency = 0.15 }, card)
		else hoverStroke(UI, card, C.manila) end
		return card
	end

	-- middle column (progress bar + reward chips) and the text column, sized for 820..1104 wide content
	local MID = 0.3
	local BTN = 168
	local function textCol(card, title, subtitle)
		local w = UDim2.new(1 - MID, -(102 + BTN + 36), 0, 0)
		text(card, title, { font = "heavy", size = 19, pos = UDim2.fromOffset(102, 12), sz = UDim2.new(w.X.Scale, w.X.Offset, 0, 24), z = 8, truncate = true })
		text(card, subtitle, { size = 14, color = C.muted, pos = UDim2.fromOffset(102, 40), sz = UDim2.new(w.X.Scale, w.X.Offset, 0, 20), z = 8, truncate = true })
	end
	local function midCol(card)
		return UI.mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(BTN + 24), 0, 10), Size = UDim2.new(MID, 0, 0, 58), ZIndex = 8 }, card)
	end

	local function taskRow(st, ord, i, src, order)
		local isWeekly = src == "weekly"
		local card = rowFrame(order, false)
		local ready = ord.have >= ord.n and not ord.done
		if ready then card.Image = UI.asset("card_hot") end
		local D = TK.Diff[ord.diff]
		if isWeekly then diffChip(card, "WEEKLY", WEEKLY_COLOR, 8)
		else diffChip(card, D and D.name or "DAILY", D and Color3.fromHex(D.color) or C.ink, 8) end
		textCol(card, ord.text or ord.key, SUB[ord.key] or "")
		local mid = midCol(card)
		local have = math.floor(ord.have or 0)
		local isTime = ord.key == "online"
		local bar = UI.bar(mid, ord.done and C.dim or C.gold, { sz = UDim2.new(1, 0, 0, 24), z = 9, textSize = 13 })
		local label = isTime and (have .. " min / " .. ord.n .. " min") or (R.Commas(have) .. " / " .. R.Commas(ord.n))
		bar:Set(have / math.max(1, ord.n), "", "")
		text(bar.Inst, ord.done and "DONE" or label, { font = "heavy", size = 13, color = C.white, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 12, stroke = 1.4 })
		local rw = (st.taskRewards and st.taskRewards[isWeekly and "weekly" or ord.diff]) or {}
		rewardChips(mid, {
			{ "+" .. (rw.seals or 0) .. " SEAL" .. ((rw.seals or 0) == 1 and "" or "S"), "icon_seal", nil, C.gold },
			{ R.Money(rw.cash or 0), "icon_cash", C.good, C.good },
		}, 9)
		local bpos = UDim2.new(1, -12, 0.5, 0)
		local bsz = UDim2.fromOffset(BTN, 46)
		if ord.done then
			UI.button(card, "locked", "CLAIMED", nil, { pos = bpos, anchor = Vector2.new(1, 0.5), sz = bsz, z = 9, icon = "icon_check", textSize = 16 })
			card.ImageTransparency = 0.35
		elseif ready then
			UI.button(card, "gold", "CLAIM", function(btn)
				local res = App.req("taskClaim", { src = src, i = i }, btn)
				if res.ok then App.float(btn.Inst, "+" .. (res.seals or 0) .. " SEALS  <font color='#8fd07a'>+" .. R.Money(res.cash or 0) .. "</font>", C.gold) end
			end, { pos = bpos, anchor = Vector2.new(1, 0.5), sz = bsz, z = 9, textSize = 18 })
		else
			local rf = st.refresh or {}
			local free, tokens = rf.free or 0, rf.tokens or 0
			local label2, kind
			if free > 0 then label2, kind = "REPLACE (FREE)", "manila"
			elseif tokens > 0 then label2, kind = "REPLACE (" .. tokens .. " LEFT)", "manila"
			else label2, kind = "REPLACE (" .. ((Config.Products.ChallengeRefresh or {}).robux or 19) .. " R$)", "slate" end
			UI.button(card, kind, label2, function(btn)
				local function go() App.req("taskRefresh", { src = src, i = i }, btn) end
				if have > 0 then
					App.confirm("REPLACE THIS ORDER?", "You lose your progress on <b>" .. (ord.text or "this order") .. "</b> (" .. label .. ") and get a new one.", "REPLACE", "manila", function() go() end)
				else go() end
			end, { pos = bpos, anchor = Vector2.new(1, 0.5), sz = bsz, z = 9, textSize = 15 })
		end
	end

	local function bonusRow(order, title, subtitle, claimedN, total, rewards, claimed, action)
		local card = rowFrame(order, true)
		diffChip(card, "BONUS", C.gold, 8)
		textCol(card, title, subtitle)
		local mid = midCol(card)
		local bar = UI.bar(mid, C.gold, { sz = UDim2.new(1, 0, 0, 24), z = 9, textSize = 13 })
		bar:Set(claimedN / math.max(1, total), "", "")
		text(bar.Inst, claimedN .. " / " .. total .. " claimed", { font = "heavy", size = 13, color = C.white, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 12, stroke = 1.4 })
		rewardChips(mid, rewards, 9)
		local bpos, bsz = UDim2.new(1, -12, 0.5, 0), UDim2.fromOffset(BTN, 46)
		if claimed then
			UI.button(card, "locked", "CLAIMED", nil, { pos = bpos, anchor = Vector2.new(1, 0.5), sz = bsz, z = 9, icon = "icon_check", textSize = 16 })
		elseif claimedN >= total then
			local b = UI.button(card, "gold", "CLAIM", function(btn)
				local res = App.req(action, {}, btn)
				if res.ok then
					if action == "weeklyChest" then
						local g = res.gear
						App.toast("WEEKLY CHEST OPENED", "+12 Seals · Founder's Crate" .. (g and g.name and (" · " .. tostring(g.name)) or " · Rare+ gear"), "gold")
					else
						App.float(btn.Inst, "+" .. (res.seals or 2) .. " SEALS · FULL INFLUENCE", C.gold)
					end
				end
			end, { pos = bpos, anchor = Vector2.new(1, 0.5), sz = bsz, z = 9, textSize = 18 })
			local sc = b.Inst:FindFirstChildOfClass("UIScale")
			task.spawn(function()
				while b.Inst.Parent do
					task.wait(1.2)
					if not b.Inst.Parent or not sc then break end
					tween(sc, 0.25, { Scale = 1.06 }, Enum.EasingStyle.Sine); task.wait(0.25); tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Sine)
				end
			end)
		else
			UI.button(card, "locked", "CLAIM ALL " .. total, function(btn) App.toast("Claim all " .. total .. " first", nil, "bad"); App.shake(btn.Inst) end,
				{ pos = bpos, anchor = Vector2.new(1, 0.5), sz = bsz, z = 9, textSize = 15 })
		end
	end

	local function drawOrders(st)
		obj.timers = {}
		local t = st.tasks
		local wk = st.weekly
		local order = 0
		local function nextOrder() order += 1; return order end
		sectionHead("DAILY ORDERS", nextOrder(), "daily")
		local dl = (t and t.list) or {}
		local dn = 0
		for i, ord in ipairs(dl) do
			taskRow(st, ord, i, "daily", nextOrder())
			if ord.done then dn += 1 end
		end
		if #dl == 0 then text(list, "No orders today. Check back soon.", { size = 15, color = C.muted, order = nextOrder(), z = 8 }) end
		bonusRow(nextOrder(), "Claim all " .. math.max(#dl, TK.DailyCount) .. " daily orders", "Finish every order today for a bonus.", dn, math.max(#dl, 1),
			{ { "+" .. TK.DailyBonus.seals .. " SEALS", "icon_seal", nil, C.gold }, { "FULL INFLUENCE", "icon_influence", C.inf, C.inf } }, t and t.bonus, "taskBonus")

		local spacer = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 6), LayoutOrder = nextOrder() }, list)
		local _ = spacer
		sectionHead("WEEKLY CHALLENGES", nextOrder(), "weekly")
		local wl = (wk and wk.list) or {}
		local wn = 0
		for i, ord in ipairs(wl) do
			taskRow(st, ord, i, "weekly", nextOrder())
			if ord.done then wn += 1 end
		end
		bonusRow(nextOrder(), "Claim all " .. math.max(#wl, 5) .. " weekly challenges", "The weekly chest: guaranteed Rare or better gear.", wn, math.max(#wl, 1),
			{ { "+" .. TK.WeeklyChest.seals .. " SEALS", "icon_seal", nil, C.gold }, { "FOUNDER'S CRATE", "icon_gift", C.gold, C.gold }, { "RARE+ GEAR", "icon_sparkles", C.blue, C.blue } }, wk and wk.chest, "weeklyChest")
	end

	------------------------------------------------ seals shop
	local function drawShop(st)
		obj.timers = {}
		local seals = st.seals or 0
		local head = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), ZIndex = 7, LayoutOrder = 0 }, list)
		text(head, "Seals come only from orders. They cannot be traded or bought.", { size = 15, color = C.muted, sz = UDim2.new(1, -180, 1, 0), z = 8, truncate = true })
		UI.chip(head, (st.tickets or 0) .. " TICKETS", { pos = UDim2.new(1, -4, 0.5, 0), anchor = Vector2.new(1, 0.5), h = 26, size = 14, icon = "icon_ticket", iconColor = C.white, z = 8 })
		local contentW = App.W() - App.NAVW - 20 - 28
		local cols = contentW >= 980 and 4 or 3
		local grid = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 7, LayoutOrder = 1 }, list)
		UI.mk("UIGridLayout", { CellSize = UDim2.new(1 / cols, -10, 0, 236), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
		UI.mk("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingRight = UDim.new(0, 4) }, grid)
		for k, it in ipairs(TK.Shop) do
			local can = seals >= it.cost
			local cell = UI.mk("Frame", { Name = "Cell", BackgroundTransparency = 1, LayoutOrder = k, ZIndex = 7 }, grid)
			local isCrate = it.icon == "crate_basic" or it.icon == "crate_limited"
			local card = UI.card(cell, { sz = UDim2.fromScale(1, 1), z = 8, hot = it.key == "limited" })
			local stroke = UI.mk("UIStroke", { Color = it.key == "limited" and C.gold or C.manila, Thickness = 2, Transparency = it.key == "limited" and 0.3 or 1 }, card)
			cell.MouseEnter:Connect(function()
				tween(card, 0.15, { Position = UDim2.fromOffset(0, -5) }, Enum.EasingStyle.Back)
				tween(stroke, 0.15, { Transparency = 0.05 })
			end)
			cell.MouseLeave:Connect(function()
				tween(card, 0.2, { Position = UDim2.fromOffset(0, 0) })
				tween(stroke, 0.2, { Transparency = it.key == "limited" and 0.3 or 1 })
			end)
			-- picture with a soft glow
			local glow = UI.img(card, "circle", { sz = UDim2.fromOffset(96, 96), pos = UDim2.new(0.5, 0, 0, 58), anchor = Vector2.new(0.5, 0.5), color = it.key == "limited" and C.gold or C.manila, alpha = 0.85, z = 9, slice = false })
			local _ = glow
			if isCrate or it.icon == "icon_seal" or it.icon == "icon_ticket" then
				local img = UI.img(card, it.icon, { sz = UDim2.fromOffset(isCrate and 92 or 64, isCrate and 92 or 64), pos = UDim2.new(0.5, 0, 0, 58), anchor = Vector2.new(0.5, 0.5), z = 10, slice = false })
				img.ScaleType = Enum.ScaleType.Fit
			else
				local col = (it.refill == "inf" and C.inf) or (it.refill == "sup" and C.sup) or (it.shieldHours and C.blue) or C.manila
				UI.icon(card, it.icon, 48, col, UDim2.new(0.5, 0, 0, 58), { z = 10, anchor = Vector2.new(0.5, 0.5) })
			end
			text(card, string.upper(it.name), { font = "heavy", size = 17, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(8, 110), sz = UDim2.new(1, -16, 0, 22), z = 10, scaled = true, color = it.key == "limited" and C.gold or C.ink })
			text(card, it.desc, { size = 13, color = C.muted, align = Enum.TextXAlignment.Center, valign = Enum.TextYAlignment.Top, wrap = true, pos = UDim2.fromOffset(10, 134), sz = UDim2.new(1, -20, 0, 36), z = 10, scaled = true })
			UI.button(card, can and "gold" or "locked", it.cost .. " SEALS", function(btn)
				if (App.state.seals or 0) < it.cost then App.toast("Not enough Seals", "Finish daily and weekly orders to earn more", "bad"); App.shake(btn.Inst); return end
				local res = App.req("sealBuy", { key = it.key }, btn)
				if res.ok then App.toast(string.upper(it.name), "Bought for " .. it.cost .. " Seals", "gold"); App.float(btn.Inst, "-" .. it.cost .. " SEALS", C.gold) end
			end, { pos = UDim2.new(0, 10, 1, -54), sz = UDim2.new(1, -20, 0, 44), z = 11, icon = "icon_seal", textSize = 16 })
			local bi = card:FindFirstChild("Button")
			local ic = bi and bi:FindFirstChild("Face") and bi.Face:FindFirstChild("Icon")
			if ic then ic.ImageColor3 = C.white end
		end
	end

	------------------------------------------------ refresh / tick
	function obj:Refresh(st)
		if not st then return end
		-- count the seal chip up
		local from = sealL:GetAttribute("v") or (st.seals or 0)
		local to = st.seals or 0
		sealL:SetAttribute("v", to)
		if from ~= to then
			local nv = Instance.new("NumberValue"); nv.Value = from
			nv.Changed:Connect(function(v) sealL.Text = math.floor(v + 0.5) .. " SEALS" end)
			local tw = tween(nv, 0.6, { Value = to }, Enum.EasingStyle.Quart)
			tw.Completed:Connect(function() sealL.Text = to .. " SEALS"; nv:Destroy() end)
		else sealL.Text = to .. " SEALS" end

		local pos = list and list.CanvasPosition
		local keepTab = obj.drawnTab == obj.tab
		if list then list:Destroy() end
		list = UI.list(area, { gap = 8, z = 6 })
		if obj.tab == 1 then drawOrders(st) else drawShop(st) end
		obj.drawnTab = obj.tab
		if keepTab and pos then task.defer(function() if list then list.CanvasPosition = pos end end) end
		obj:Tick(st)
	end
	function obj:Tick()
		local now = App.now()
		local dLeft = dailyLeft(now)
		newL.Text = "NEW ORDERS IN " .. hms(dLeft)
		if obj.timers.daily and obj.timers.daily.Parent then obj.timers.daily.Text = "Resets in " .. hms(dLeft) end
		if obj.timers.weekly and obj.timers.weekly.Parent then obj.timers.weekly.Text = "Resets in " .. longLeft(weeklyLeft(now)) end
	end
	return obj
end }

return S
