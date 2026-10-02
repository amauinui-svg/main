-- Country screen (Kash 1 Oct 16:40/16:45): modelled on Idle Mafia's SAFEHOUSE tab.
-- A big era scene, the era title bar (ERA n OF 8, LEVEL, NEXT ERA), the 7-day login sheet, then YOUR STATS and
-- YOUR UPGRADES (the skill point upgrades live here, so there is no separate Skills tab).
-- Also exports the login sheet POPUP: App.showLogin() (set by _init.init at load and again inside build).
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Shared = RS:WaitForChild("Shared")
local D = require(Shared.GameData)
local R = require(Shared.Rules)
local TK = require(Shared.Tasks)

local S = {}

---------------------------------------------------------------- centre pop-ins and rotating beams (Kash 18:41)
local FX = {}
local function fxTween(o, t, props, style, dir, rep)
	local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, rep or 0), props)
	x:Play()
	return x
end
-- re-anchor a GuiObject on its centre without moving it, so a UIScale grows it from the middle
function FX.centre(g)
	local a = g.AnchorPoint
	if a.X == 0.5 and a.Y == 0.5 then return g end
	local p, sz = g.Position, g.Size
	g.AnchorPoint = Vector2.new(0.5, 0.5)
	g.Position = UDim2.new(p.X.Scale + sz.X.Scale * (0.5 - a.X), p.X.Offset + sz.X.Offset * (0.5 - a.X), p.Y.Scale + sz.Y.Scale * (0.5 - a.Y), p.Y.Offset + sz.Y.Offset * (0.5 - a.Y))
	return g
end
-- fade a whole tree in from fully transparent to the values it was built with
function FX.fadeIn(root, t)
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
			fxTween(d, t, props)
		end
	end
end
-- pop in from the centre ("from far away towards me"): UIScale ~0.6 -> 1 with Back easing, plus a quick fade
function FX.popIn(g, from, t, noFade)
	FX.centre(g)
	local sc = g:FindFirstChildOfClass("UIScale")
	if not sc then sc = Instance.new("UIScale"); sc.Parent = g end
	sc.Scale = from or 0.6
	fxTween(sc, t or 0.32, { Scale = 1 }, Enum.EasingStyle.Back)
	-- deferred so the content the caller builds right after this call fades in with the panel
	if not noFade then task.defer(FX.fadeIn, g, math.min(0.2, (t or 0.32) * 0.7)) end
	return sc
end
function FX.spin(o, degPerSec)
	o.Rotation = (os.clock() * degPerSec) % 360 -- phase from the clock, so a rebuilt card does not jump
	fxTween(o, 360 / math.abs(degPerSec), { Rotation = o.Rotation + (degPerSec >= 0 and 360 or -360) }, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
end
-- the classic game-pass ROTATING BEAMS behind an item: soft glow + two counter-rotating tinted sunburst layers.
-- size = full diameter in px (about 1.6-2x the item); strength 0..1
function FX.beams(UI, parent, color, size, pos, z, strength)
	strength = math.clamp(strength or 1, 0, 1)
	local root = UI.mk("Frame", { Name = "Beams", BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Position = pos or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z or 2 }, parent)
	local mid, half = UDim2.fromScale(0.5, 0.5), Vector2.new(0.5, 0.5)
	UI.img(root, "glow_soft", { name = "Glow", color = color, alpha = 1 - 0.45 * strength, slice = false, z = root.ZIndex, anchor = half, pos = mid, sz = UDim2.fromScale(0.62, 0.62) })
	local back = UI.img(root, "beams", { name = "Rays", color = color, alpha = 1 - 0.55 * strength, slice = false, z = root.ZIndex, anchor = half, pos = mid, sz = UDim2.fromScale(1, 1) })
	local front = UI.img(root, "beams_wide", { name = "RaysWide", color = color:Lerp(Color3.new(1, 1, 1), 0.3), alpha = 1 - 0.4 * strength, slice = false, z = root.ZIndex, anchor = half, pos = mid, sz = UDim2.fromScale(0.78, 0.78) })
	FX.spin(back, 22)
	FX.spin(front, -34)
	return root
end

---------------------------------------------------------------- local helpers
local function hms(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%02d:%02d:%02d", sec // 3600, (sec % 3600) // 60, sec % 60)
end
local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
local function eraTitle(name)
	local up = string.upper(name)
	if up:sub(-4) == " AGE" then return up end
	return up .. " ERA"
end
-- count a label up (or down) to a value, formatting every frame
local function countTo(label, value, fmt)
	value = tonumber(value) or 0
	local from = label:GetAttribute("v")
	label:SetAttribute("v", value)
	if from == nil then from = 0 end
	if from == value then label.Text = fmt(value); return end
	local nv = Instance.new("NumberValue")
	nv.Value = from
	nv.Changed:Connect(function(v) if label.Parent then label.Text = fmt(v) end end)
	local tw = tween(nv, 0.7, { Value = value }, Enum.EasingStyle.Quart)
	tw.Completed:Connect(function() if label.Parent then label.Text = fmt(value) end; nv:Destroy() end)
end
-- outline that lights up on hover
local function hoverStroke(UI, gui, color)
	local st = UI.mk("UIStroke", { Color = color or UI.C.manila, Thickness = 2, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, gui)
	gui.MouseEnter:Connect(function() tween(st, 0.15, { Transparency = 0.15 }) end)
	gui.MouseLeave:Connect(function() tween(st, 0.2, { Transparency = 1 }) end)
	return st
end
-- a cell that lifts its card a few pixels on hover (cell is the layout child, card moves inside it)
local function liftCell(UI, parent, order, z)
	local cell = UI.mk("Frame", { Name = "Cell", BackgroundTransparency = 1, LayoutOrder = order or 0, ZIndex = z or 7 }, parent)
	local card = UI.card(cell, { sz = UDim2.fromScale(1, 1), z = z or 7 })
	cell.MouseEnter:Connect(function() tween(card, 0.15, { Position = UDim2.fromOffset(0, -4) }, Enum.EasingStyle.Back) end)
	cell.MouseLeave:Connect(function() tween(card, 0.2, { Position = UDim2.fromOffset(0, 0) }) end)
	return cell, card
end
-- small "i" info button: tap or hover shows a short explanation (Kash Q3 UI rule)
local function infoButton(UI, App, parent, pos, title, body, z)
	local b = UI.mk("TextButton", { Name = "Info", Text = "i", FontFace = UI.Font.heavy, TextSize = 14, TextColor3 = UI.C.manilaInk, BackgroundColor3 = UI.C.manila,
		AutoButtonColor = false, Position = pos, Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(0, 0.5), ZIndex = z or 9 }, parent)
	UI.mk("UICorner", { CornerRadius = UDim.new(1, 0) }, b)
	local tip
	local function hide() if tip then tip:Destroy(); tip = nil end end
	local function show()
		hide()
		local root = App.root
		local fit = root:FindFirstChild("Fit")
		local s = fit and fit.Scale or 1
		local p = (b.AbsolutePosition - root.AbsolutePosition) / s
		local w = 300
		local x = math.clamp(p.X - w / 2, 8, App.W() - w - 8)
		-- anchored top-centre so it grows out of the "i" button instead of from its top-left corner
		tip = UI.img(root, "panel_plain", { name = "InfoTip", pos = UDim2.fromOffset(x + w / 2, p.Y + 26), anchor = Vector2.new(0.5, 0), sz = UDim2.fromOffset(w, 0), z = 85 })
		tip.AutomaticSize = Enum.AutomaticSize.Y
		UI.mk("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 12) }, tip)
		UI.mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, tip)
		UI.text(tip, title, { font = "heavy", size = 15, color = UI.C.gold, z = 86, order = 1 })
		local l = UI.text(tip, body, { size = 14, wrap = true, z = 86, order = 2, sz = UDim2.new(1, 0, 0, 0) })
		l.AutomaticSize = Enum.AutomaticSize.Y
		local sc = UI.mk("UIScale", { Scale = 0.8 }, tip)
		tween(sc, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
		FX.fadeIn(tip, 0.12)
		local mine = tip
		task.delay(5, function() if tip == mine then hide() end end)
	end
	b.MouseEnter:Connect(show)
	b.MouseLeave:Connect(hide)
	b.Activated:Connect(function() if tip then hide() else show() end end)
	b.Destroying:Connect(hide)
	return b
end

---------------------------------------------------------------- login sheet cards (shared by the screen and the popup)
-- buildLoginCards(App, parent, st, onClaimed) -> { countdown = TextLabel or nil }
local function buildLoginCards(App, parent, st, onClaimed)
	local UI = App.UI
	local C = UI.C
	local login = st.login or { idx = 1 }
	local idx = math.clamp(login.idx or 1, 1, #TK.Login)
	local ready = st.loginReady == true
	local out = {}
	for i, r in ipairs(TK.Login) do
		local claimed = i < idx
		local today = i == idx
		local cell, card = liftCell(UI, parent, i, 8)
		if today and ready then card.Image = UI.asset("card_hot") end
		local z = card.ZIndex + 1
		local dayL = UI.text(card, "DAY " .. i, { font = "heavy", size = 15, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 6), sz = UDim2.new(1, 0, 0, 20), z = z,
			color = today and C.gold or (r.big and C.gold or C.ink) })
		-- reward picture: the big day shows the Founder's Crate art with a soft glow
		if r.big then
			-- classic rotating game-pass beams behind the crate (Kash 18:41: no pulsing circle)
			FX.beams(UI, card, C.gold, 96, UDim2.new(0.5, 0, 0, 52), z - 1, claimed and 0.35 or 0.9)
			local img = UI.img(card, "crate_limited", { sz = UDim2.fromOffset(48, 48), pos = UDim2.new(0.5, 0, 0, 52), anchor = Vector2.new(0.5, 0.5), z = z + 1, slice = false, fit = true })
			img.ScaleType = Enum.ScaleType.Fit
		else
			local col = (r.gold and C.gold) or (r.lawMinutes and C.good) or (r.refill and C.inf) or C.manila
			UI.icon(card, r.icon or "icon_gift", 30, col, UDim2.new(0.5, 0, 0, 52), { z = z, anchor = Vector2.new(0.5, 0.5) })
		end
		UI.text(card, r.text, { size = 12, font = "bold", wrap = true, align = Enum.TextXAlignment.Center, valign = Enum.TextYAlignment.Top, color = C.muted,
			pos = UDim2.fromOffset(4, 80), sz = UDim2.new(1, -8, 1, -122), z = z, scaled = true })
		local bottom = UDim2.new(0, 6, 1, -36)
		local bsz = UDim2.new(1, -12, 0, 30)
		if claimed then
			card.ImageTransparency = 0.45
			for _, ch in ipairs(card:GetDescendants()) do
				if ch:IsA("TextLabel") then ch.TextTransparency = 0.5 elseif ch:IsA("ImageLabel") then ch.ImageTransparency = math.max(ch.ImageTransparency, 0.5) end
			end
			local ok = UI.img(card, "circle", { sz = UDim2.fromOffset(30, 30), pos = UDim2.new(0.5, 0, 1, -21), anchor = Vector2.new(0.5, 0.5), color = C.good, z = z + 1, slice = false })
			UI.icon(ok, "icon_check", 18, C.black, UDim2.fromScale(0.5, 0.5), { z = z + 2, anchor = Vector2.new(0.5, 0.5) })
		elseif today and ready then
			local btn = UI.button(card, "gold", "CLAIM", function(btn)
				local res = App.req("loginClaim", {}, btn)
				if res.ok then
					local got = TK.Login[res.idx or i]
					App.toast("DAY " .. (res.idx or i) .. " CLAIMED", got and got.text or nil, "gold")
					App.float(btn.Inst, "+" .. (got and got.text or "reward"), C.gold)
					if onClaimed then onClaimed(res) end
				end
			end, { pos = bottom, sz = bsz, z = z + 1, textSize = 15 })
			-- gentle pulse so the claim button reads as the thing to press
			local sc = btn.Inst:FindFirstChildOfClass("UIScale")
			task.spawn(function()
				while btn.Inst.Parent do
					task.wait(1.1)
					if not btn.Inst.Parent then break end
					if sc then tween(sc, 0.25, { Scale = 1.06 }, Enum.EasingStyle.Sine); task.wait(0.25); tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Sine) end
				end
			end)
		elseif today then
			local box = UI.img(card, "inset", { pos = bottom, sz = bsz, z = z })
			out.countdown = UI.text(box, "", { font = "heavy", size = 13, color = C.gold, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = z + 1, scaled = true })
		else
			local box = UI.img(card, "inset", { pos = bottom, sz = bsz, z = z })
			UI.text(box, r.big and "BIG REWARD" or "LOCKED", { font = "heavy", size = 12, color = r.big and C.gold or C.dim, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = z + 1, scaled = true })
		end
		dayL.ZIndex = z
		if r.big and not claimed then
			UI.mk("UIStroke", { Color = C.gold, Thickness = 2, Transparency = 0.25 }, card)
		end
		local _ = cell
	end
	return out
end

local function nextDayIn(App)
	local now = App.now()
	return 86400 - (now % 86400)
end

---------------------------------------------------------------- LOGIN SHEET POPUP
local function showLogin(App)
	local UI = App.UI
	local C = UI.C
	local st = App.state
	if not st then return end
	local host = App.modalHost
	UI.clear(host)
	host.Visible = true
	local w = math.min(App.W() - 40, 860)
	local cardH = App.H() < 560 and 150 or 170
	local panel, body = UI.panel(host, "DAILY LOGIN", { sz = UDim2.fromOffset(w, cardH + 168), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71 })
	local sc = FX.popIn(panel, 0.6, 0.32)
	local function close()
		local tw = tween(sc, 0.15, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw.Completed:Connect(function() if panel.Parent then host.Visible = false; UI.clear(host) end end)
	end
	local x = UI.button(panel, "slate", "", function() close() end, { pos = UDim2.new(1, -14, 0, 12), anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(38, 36), z = 75, icon = "icon_x", iconSize = 18 })
	local _ = x
	local login = st.login or { idx = 1 }
	local idx = math.clamp(login.idx or 1, 1, #TK.Login)
	UI.text(body, "Come back every day for a reward. Day " .. idx .. " of 7 is next. Missed a day? Your sheet pauses, it never resets.",
		{ size = 15, color = C.muted, sz = UDim2.new(1, -40, 0, 22), z = 73, truncate = true })
	local row = UI.mk("Frame", { Name = "Days", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, cardH), ZIndex = 72 }, body)
	UI.mk("UIGridLayout", { CellSize = UDim2.new(1 / 7, -7, 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder }, row)
	local function draw()
		UI.clear(row)
		local o = buildLoginCards(App, row, App.state, function()
			task.delay(0.9, close)
		end)
		if o.countdown then
			task.spawn(function()
				while o.countdown.Parent and host.Visible do
					o.countdown.Text = "IN " .. hms(nextDayIn(App))
					task.wait(0.5)
				end
			end)
		end
	end
	draw()
	UI.button(body, "slate", "LATER", function() close() end, { pos = UDim2.new(1, 0, 1, -2), anchor = Vector2.new(1, 1), sz = UDim2.fromOffset(150, 42), z = 73 })
	if not App.state.loginReady then
		UI.text(body, "Next reward in " .. hms(nextDayIn(App)), { font = "heavy", size = 16, color = C.gold, pos = UDim2.new(0, 0, 1, -44), sz = UDim2.new(1, -170, 0, 40), z = 73 })
	end
end

---------------------------------------------------------------- FLAG EDITOR POPUP (Kash 19:24: Custom Flag pass, 99 Robux)
-- Everyone: the 8 basic layouts and 12 colours. Pass owners: 14 layouts, 24 colours, an emblem and their own image.
-- Non-owners can PREVIEW the locked options (try before you buy); SAVE asks them to unlock first.
local function showFlagEditor(App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local Config = require(Shared.Config)
	local st = App.state
	if not st then return end
	local host = App.modalHost
	UI.clear(host)
	host.Visible = true
	local passInfo = Config.Passes.CustomFlag or { price = 99 }
	local function owns() return (App.state and App.state.gp and App.state.gp.CustomFlag) and true or false end
	local basicL, basicC = {}, {}
	for _, l in ipairs(R.FlagLayouts) do basicL[l] = true end
	for _, c in ipairs(R.FlagColors) do basicC[c] = true end
	local allL = R.FlagLayoutsAll or R.FlagLayouts
	local allC = R.FlagColorsAll or R.FlagColors
	local emblems = R.FlagEmblems or {}

	-- working copy of the flag
	local cur = st.flag or { l = "h3", c = { "1f3a93", "ecf0f1", "c0392b" } }
	local f = { l = cur.l or "h3", c = { (cur.c or {})[1] or "1f3a93", (cur.c or {})[2] or "ecf0f1", (cur.c or {})[3] or "c0392b" }, e = cur.e, img = cur.img }
	local slot = 1

	local W = math.min(App.W() - 40, 820)
	local H = math.min(App.H() - 40, 560)
	local panel, body = UI.panel(host, "EDIT FLAG", { sz = UDim2.fromOffset(W, H), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71 })
	local sc = FX.popIn(panel, 0.6, 0.32)
	local closed = false
	local function close()
		if closed then return end
		closed = true
		local tw = tween(sc, 0.15, { Scale = 0.9 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tw.Completed:Connect(function() if panel.Parent then host.Visible = false; UI.clear(host) end end)
	end
	UI.button(panel, "slate", "", function() close() end, { pos = UDim2.new(1, -14, 0, 12), anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(38, 36), z = 75, icon = "icon_x", iconSize = 18 })

	-- left: live preview + save
	local leftW = math.clamp(math.floor(W * 0.34), 210, 270)
	local left = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, leftW, 1, 0), ZIndex = 72 }, body)
	local stage = UI.img(left, "inset", { sz = UDim2.new(1, 0, 0, math.floor((leftW - 30) * 0.66) + 30), z = 72 })
	local previewHost = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 73 }, stage)
	local previewW = leftW - 40
	local usesLocked = text(left, "", { font = "bold", size = 13, color = C.gold, wrap = true, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, stage.Size.Y.Offset + 6), sz = UDim2.new(1, 0, 0, 34), z = 73 })
	local save
	local unlockBtns = {}

	local function lockedNow()
		if owns() then return false end
		if not basicL[f.l] then return true end
		for k = 1, 3 do if not basicC[f.c[k]] then return true end end
		return f.e ~= nil or f.img ~= nil
	end
	local function drawPreview()
		UI.clear(previewHost)
		local fl = UI.flag(previewHost, { l = f.l, c = { f.c[1], f.c[2], f.c[3] }, e = f.e, img = f.img }, previewW, { z = 74, pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5) })
		local s = Instance.new("UIScale"); s.Scale = 0.94; s.Parent = fl
		tween(s, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
		local lk = lockedNow()
		usesLocked.Text = lk and ("Uses Custom Flag options · unlock for R$" .. passInfo.price) or ""
		if save then save:Set(lk and "locked" or "green") end
	end

	save = UI.button(left, "green", "SAVE FLAG", function(btn)
		if lockedNow() then
			App.toast("Custom Flag pass needed", "Unlock all layouts, colours, emblems and your own image for R$" .. passInfo.price, "bad")
			App.shake(btn.Inst)
			for _, u in ipairs(unlockBtns) do if u.Inst.Parent then App.shake(u.Inst) end end
			return
		end
		local out = { l = f.l, c = { f.c[1], f.c[2], f.c[3] }, e = f.e, img = f.img }
		local res = App.req("setFlag", { flag = out }, btn)
		if res.ok then
			App.toast("FLAG SAVED", "Your nation flies its new colours.", "good")
			if App.sfx then pcall(App.sfx, "coin", { volume = 0.4 }) end
			close()
		end
	end, { pos = UDim2.new(0, 0, 1, -50), sz = UDim2.new(1, 0, 0, 48), z = 74, textSize = 18 })
	UI.button(left, "slate", "CANCEL", function() close() end, { pos = UDim2.new(0, 0, 1, -104), sz = UDim2.new(1, 0, 0, 44), z = 74 })

	-- right: scrolling option sections
	local list = UI.list(body, { pos = UDim2.fromOffset(leftW + 14, 0), sz = UDim2.new(1, -leftW - 14, 1, 0), gap = 8, z = 72 })
	local order = 0
	local function section(title)
		order += 1
		local l = text(list, title, { font = "display", size = 18, color = C.manila, sz = UDim2.new(1, 0, 0, 24), z = 73, order = order })
		return l
	end
	local function grid(cell, rows)
		order += 1
		local g = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 73, LayoutOrder = order }, list)
		UI.mk("UIGridLayout", { CellSize = cell, CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, g)
		local _ = rows
		return g
	end
	-- a pickable cell with a selection ring and an optional lock badge
	local function pickCell(parent, ord, selected, locked, onPick)
		local b = UI.mk("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = C.black, BackgroundTransparency = 0.35, BorderSizePixel = 0, LayoutOrder = ord, ZIndex = 74 }, parent)
		UI.mk("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
		local ring = UI.mk("UIStroke", { Color = selected and C.gold or C.rule, Thickness = selected and 3 or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		local s = UI.mk("UIScale", {}, b)
		b.MouseEnter:Connect(function() tween(s, 0.12, { Scale = 1.06 }, Enum.EasingStyle.Back); if not selected then tween(ring, 0.12, { Color = C.manila }) end end)
		b.MouseLeave:Connect(function() tween(s, 0.15, { Scale = 1 }); if not selected then tween(ring, 0.15, { Color = C.rule }) end end)
		b.Activated:Connect(onPick)
		if locked then
			local lb = UI.img(b, "circle", { sz = UDim2.fromOffset(18, 18), pos = UDim2.new(1, -2, 0, 2), anchor = Vector2.new(1, 0), color = C.black, z = 78, slice = false })
			UI.icon(lb, "icon_lock", 11, C.gold, UDim2.fromScale(0.5, 0.5), { z = 79, anchor = Vector2.new(0.5, 0.5) })
		end
		return b
	end

	local draw
	local function unlockBanner()
		order += 1
		local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 66), z = 73, order = order, hot = true })
		UI.icon(card, "icon_flag", 28, C.gold, UDim2.new(0, 12, 0.5, 0), { z = 75, anchor = Vector2.new(0, 0.5) })
		text(card, "CUSTOM FLAG PASS", { font = "heavy", size = 16, color = C.gold, pos = UDim2.fromOffset(50, 10), sz = UDim2.new(1, -220, 0, 20), z = 75, truncate = true })
		text(card, #allL .. " layouts · " .. #allC .. " colours · emblems · your own image", { size = 13, color = C.muted, pos = UDim2.fromOffset(50, 32), sz = UDim2.new(1, -220, 0, 18), z = 75, truncate = true })
		local u = UI.button(card, "gold", "UNLOCK ALL · R$" .. passInfo.price, function(btn) App.req("buyPass", { key = "CustomFlag" }, btn) end,
			{ pos = UDim2.new(1, -10, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(160, 42), z = 75, textSize = 15 })
		table.insert(unlockBtns, u)
	end

	draw = function()
		UI.clear(list)
		order = 0
		unlockBtns = {}
		local pass = owns()
		if not pass then unlockBanner() end

		-- LAYOUT
		section("LAYOUT")
		local lg = grid(UDim2.fromOffset(64, 46))
		for i, l in ipairs(allL) do
			local locked = not pass and not basicL[l]
			local cell = pickCell(lg, i, f.l == l, locked, function() f.l = l; draw() end)
			UI.flag(cell, { l = l, c = { f.c[1], f.c[2], f.c[3] } }, 52, { z = 75, pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5) })
		end

		-- COLOURS: pick the slot, then the swatch
		section("COLOURS")
		order += 1
		local slots = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), ZIndex = 73, LayoutOrder = order }, list)
		UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, slots)
		for k = 1, 3 do
			local b = UI.button(slots, slot == k and "manila" or "slate", "COLOUR " .. k, function() slot = k; draw() end, { sz = UDim2.fromOffset(110, 34), z = 74, textSize = 13, order = k })
			local sw = UI.mk("Frame", { BackgroundColor3 = Color3.fromHex(f.c[k]), BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, -1), Size = UDim2.fromOffset(16, 16), ZIndex = 76 }, b.Face)
			UI.mk("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)
			UI.mk("UIStroke", { Color = C.black, Thickness = 1.5 }, sw)
			b.Label.Size = UDim2.new(1, -36, 1, 0)
		end
		local cg = grid(UDim2.fromOffset(36, 36))
		for i, hexC in ipairs(allC) do
			local locked = not pass and not basicC[hexC]
			local cell = pickCell(cg, i, f.c[slot] == hexC, locked, function() f.c[slot] = hexC; draw() end)
			local sw = UI.mk("Frame", { BackgroundColor3 = Color3.fromHex(hexC), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -8), ZIndex = 75 }, cell)
			UI.mk("UICorner", { CornerRadius = UDim.new(0, 4) }, sw)
		end

		-- EMBLEM
		section("EMBLEM")
		local eg = grid(UDim2.fromOffset(44, 44))
		local none = pickCell(eg, 0, f.e == nil, false, function() f.e = nil; draw() end)
		text(none, "NONE", { font = "heavy", size = 11, color = C.muted, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 75 })
		for i, key in ipairs(emblems) do
			local cell = pickCell(eg, i, f.e == key, not pass, function() f.e = key; f.img = nil; draw() end)
			UI.icon(cell, key, 24, C.white, UDim2.fromScale(0.5, 0.5), { z = 75, anchor = Vector2.new(0.5, 0.5) })
		end

		-- YOUR OWN IMAGE
		section("USE MY OWN IMAGE")
		order += 1
		local row = UI.img(list, "inset", { sz = UDim2.new(1, 0, 0, 44), z = 73, order = order })
		local box = UI.mk("TextBox", { Text = f.img and tostring(f.img) or "", PlaceholderText = pass and "Paste an image or decal ID (numbers only)" or "Custom Flag pass: paste any image ID",
			PlaceholderColor3 = C.dim, ClearTextOnFocus = false, FontFace = UI.Font.bold, TextSize = 15, TextColor3 = C.ink, TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -110, 1, 0), ZIndex = 74, TextTruncate = Enum.TextTruncate.AtEnd }, row)
		if not pass then
			UI.icon(row, "icon_lock", 16, C.gold, UDim2.new(1, -96, 0.5, 0), { z = 75, anchor = Vector2.new(1, 0.5) })
		end
		box:GetPropertyChangedSignal("Text"):Connect(function()
			local digits = box.Text:gsub("%D", "")
			if digits ~= box.Text then box.Text = digits end
		end)
		box.FocusLost:Connect(function()
			local id = box.Text:match("^%d+$")
			if id and #id >= 3 and #id <= 15 then f.img = id; f.e = nil else f.img = nil; box.Text = "" end
			drawPreview()
		end)
		UI.button(row, "slate", "CLEAR", function() f.img = nil; box.Text = ""; drawPreview() end, { pos = UDim2.new(1, -6, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(80, 34), z = 75, textSize = 13 })
		order += 1
		text(list, "Covers the whole flag. Roblox moderates every uploaded image.", { size = 12, color = C.dim, sz = UDim2.new(1, 0, 0, 16), z = 73, order = order })

		drawPreview()
	end
	draw()

	-- the pass can be bought from inside this popup: unlock everything the moment it lands
	local had = owns()
	task.spawn(function()
		while not closed and panel.Parent and host.Visible do
			task.wait(0.5)
			if owns() ~= had then
				had = owns()
				if had then App.toast("CUSTOM FLAG UNLOCKED", "Every layout, colour, emblem and your own image.", "gold") end
				local y = list.CanvasPosition.Y
				draw()
				task.defer(function() list.CanvasPosition = Vector2.new(0, y) end)
			end
		end
	end)
end

---------------------------------------------------------------- COUNTRY
S.country = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	App.showLogin = function() showLogin(App) end

	local panel, body = UI.panel(host, "COUNTRY", { sz = UDim2.new(1, -20, 1, -20), pos = UDim2.fromOffset(10, 10), z = 5, titleSize = 26 })
	local sub = text(panel, "", { font = "bold", size = 15, color = C.muted, pos = UDim2.new(0, 18, 0, 16), sz = UDim2.new(1, -36, 0, 22), z = 7, align = Enum.TextXAlignment.Right, rich = true })
	local list = UI.list(body, { gap = 12, z = 6 })
	local obj = { era = nil, flagKey = nil }

	local contentW = math.max(600, App.W() - App.NAVW - 20 - 28 - 14)
	local bannerH = math.floor(math.clamp(contentW * 0.25, 160, 270))

	------------------------------------------------ hero: banner + era bar
	local hero = UI.img(list, "panel_plain", { name = "Hero", sz = UDim2.new(1, 0, 0, bannerH + 96), z = 7, order = 1 })
	local cg = UI.mk("CanvasGroup", { Name = "Banner", BackgroundColor3 = C.black, BorderSizePixel = 0, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, bannerH), ZIndex = 8 }, hero)
	UI.mk("UICorner", { CornerRadius = UDim.new(0, 10) }, cg)
	local scene = UI.mk("ImageLabel", { Name = "Scene", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Crop, ZIndex = 8, Image = "" }, cg)
	-- bottom shade so the scene sits into the title bar
	local shade = UI.mk("Frame", { Name = "Shade", BackgroundColor3 = C.black, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0.45, 0), ZIndex = 9 }, cg)
	UI.mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.25) }) }, shade)
	local frameStroke = UI.mk("Frame", { Name = "Border", BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -12, 0, bannerH), ZIndex = 10 }, hero)
	UI.mk("UICorner", { CornerRadius = UDim.new(0, 10) }, frameStroke)
	UI.mk("UIStroke", { Color = C.manila, Thickness = 2, Transparency = 0.35 }, frameStroke)
	local eraChipOnImg, eraChipOnImgL = UI.chip(cg, "", { pos = UDim2.new(1, -12, 0, 12), anchor = Vector2.new(1, 0), z = 11, h = 26, size = 14, icon = "icon_globe", manila = true })
	local _ = eraChipOnImg
	-- slow Ken Burns: drift and zoom, back and forth forever
	local kb
	local function kenBurns()
		if kb then kb:Cancel() end
		scene.Size = UDim2.fromScale(1.02, 1.02)
		scene.Position = UDim2.fromScale(0.5, 0.5)
		kb = TweenService:Create(scene, TweenInfo.new(22, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = UDim2.fromScale(1.14, 1.14), Position = UDim2.fromScale(0.47, 0.53) })
		kb:Play()
	end

	local bar = UI.mk("Frame", { Name = "EraBar", BackgroundTransparency = 1, Position = UDim2.fromOffset(16, bannerH + 10), Size = UDim2.new(1, -32, 0, 80), ZIndex = 8 }, hero)
	local eraName = text(bar, "", { font = "display", size = 34, color = C.gold, sz = UDim2.new(1, -330, 0, 40), z = 9, scaled = true })
	local chips = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, -330, 0, 28), ZIndex = 9 }, bar)
	UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, chips)
	local _, chipEra = UI.chip(chips, "", { order = 1, h = 28, size = 15, z = 10 })
	local _, chipLv = UI.chip(chips, "", { order = 2, h = 28, size = 15, z = 10, icon = "icon_xp", iconColor = C.xp })
	local _, chipInc = UI.chip(chips, "", { order = 3, h = 28, size = 15, z = 10, icon = "icon_cash", iconColor = C.good })
	local right = UI.mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.fromOffset(316, 80), ZIndex = 9 }, bar)
	local nextL = text(right, "", { font = "heavy", size = 14, color = C.muted, align = Enum.TextXAlignment.Right, sz = UDim2.new(1, 0, 0, 20), z = 10, rich = true, scaled = true })
	local reqBox = UI.img(right, "inset", { pos = UDim2.fromOffset(0, 24), sz = UDim2.new(1, 0, 0, 30), z = 10 })
	local reqL = text(reqBox, "", { font = "heavy", size = 17, color = C.ink, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 11, scaled = true })
	local eraBar = UI.bar(right, C.gold, { pos = UDim2.fromOffset(0, 60), sz = UDim2.new(1, 0, 0, 18), z = 10, textSize = 11 })

	------------------------------------------------ daily login row
	local loginHead = UI.mk("Frame", { Name = "LoginHead", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 34), ZIndex = 7, LayoutOrder = 2 }, list)
	text(loginHead, "DAILY LOGIN", { font = "display", size = 26, color = C.gold, sz = UDim2.new(0, 220, 1, 0), z = 8 })
	infoButton(UI, App, loginHead, UDim2.new(0, 200, 0.5, 0), "DAILY LOGIN SHEET",
		"Claim one reward each day you play. Missed a day? The sheet PAUSES: you keep your place. Day 7 is the big one: 30 gold + a Founder's Crate.", 9)
	local loginRight = text(loginHead, "", { font = "heavy", size = 18, color = C.ink, align = Enum.TextXAlignment.Right, sz = UDim2.new(1, -240, 1, 0), pos = UDim2.fromOffset(240, 0), z = 8, rich = true })
	local loginRowH = contentW < 760 and 150 or 168
	local loginRow = UI.mk("Frame", { Name = "LoginRow", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, loginRowH), ZIndex = 7, LayoutOrder = 3 }, list)
	UI.mk("UIGridLayout", { CellSize = UDim2.new(1 / 7, -7, 1, -4), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder }, loginRow)
	UI.mk("UIPadding", { PaddingTop = UDim.new(0, 4) }, loginRow)
	local loginCountdown

	------------------------------------------------ YOUR STATS / YOUR UPGRADES
	local twoH = 452
	local two = UI.mk("Frame", { Name = "Panels", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, twoH), ZIndex = 7, LayoutOrder = 4 }, list)
	local statsP, statsB = UI.panel(two, "YOUR STATS", { plain = true, sz = UDim2.new(0.5, -6, 1, 0), z = 7, titleSize = 24 })
	local upP, upB = UI.panel(two, "YOUR UPGRADES", { plain = true, sz = UDim2.new(0.5, -6, 1, 0), pos = UDim2.new(0.5, 6, 0, 0), z = 7, titleSize = 24 })
	local _ = statsP
	infoButton(UI, App, upP, UDim2.new(1, -34, 0, 28), "SKILL POINTS", "You get +3 skill points every level and +1 for every law you take to Gold mastery. Spend them here on permanent upgrades.", 10)

	-- stats: identity header
	local idRow = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 44), ZIndex = 9 }, statsB)
	local flagHost = UI.mk("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(60, 40), Position = UDim2.fromOffset(0, 2), ZIndex = 9 }, idRow)
	local nameL = text(idRow, "", { font = "display", size = 22, pos = UDim2.fromOffset(70, 0), sz = UDim2.new(1, -184, 0, 26), z = 10, truncate = true })
	local ideoL = text(idRow, "", { size = 13, color = C.muted, pos = UDim2.fromOffset(70, 26), sz = UDim2.new(1, -184, 0, 16), z = 10, truncate = true })
	-- EDIT FLAG (Kash 19:24): opens the flag editor; the Custom Flag pass unlocks the extra options
	UI.button(idRow, "manila", "EDIT FLAG", function() showFlagEditor(App) end, { pos = UDim2.new(1, 0, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(108, 36), z = 11, textSize = 14, icon = "icon_flag", iconSize = 16 })
	local flagClick = UI.mk("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12 }, flagHost)
	flagClick.Activated:Connect(function() showFlagEditor(App) end)
	local xpBar = UI.bar(statsB, C.xp, { pos = UDim2.fromOffset(0, 52), sz = UDim2.new(1, 0, 0, 26), z = 10, textSize = 14 })
	local statRows = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 1, -88), ZIndex = 9 }, statsB)
	UI.mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, statRows)
	local STATS = {
		{ "level", "Level", "icon_xp", C.xp, function(v) return tostring(math.floor(v)) end },
		{ "incHr", "Property income", "icon_cash", C.good, function(v) return R.Money(math.floor(v)) .. "/hr" end },
		{ "atk", "Attack", "icon_attack", C.bad, function(v) return R.Short(math.floor(v)) end },
		{ "def", "Defense", "icon_defense", C.blue, function(v) return R.Short(math.floor(v)) end },
		{ "inf", "Max Influence", "icon_influence", C.inf, function(v) return tostring(math.floor(v)) end },
		{ "sup", "Max Supply", "icon_supply", C.sup, function(v) return tostring(math.floor(v)) end },
		{ "off", "Officers", "icon_users", C.manila, function(v) return tostring(math.floor(v)) end },
		{ "gold", "Laws at Gold mastery", "icon_laws", C.gold, function(v) return tostring(math.floor(v)) end },
		{ "wins", "Raids won", "icon_battle", C.ink, function(v) return R.Commas(math.floor(v)) end },
	}
	local statVal = {}
	for k, s in ipairs(STATS) do
		local row = UI.mk("Frame", { BackgroundColor3 = C.white, BackgroundTransparency = k % 2 == 0 and 0.97 or 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 29), ZIndex = 9, LayoutOrder = k }, statRows)
		UI.mk("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
		UI.icon(row, s[3], 18, s[4], UDim2.new(0, 8, 0.5, 0), { z = 10, anchor = Vector2.new(0, 0.5) })
		text(row, s[2], { size = 16, color = C.muted, pos = UDim2.fromOffset(34, 0), sz = UDim2.new(0.6, -34, 1, 0), z = 10, truncate = true })
		statVal[s[1]] = { label = text(row, "", { font = "heavy", size = 17, color = s[4] == C.ink and C.ink or s[4], align = Enum.TextXAlignment.Right, pos = UDim2.new(0.5, 0, 0, 0), sz = UDim2.new(0.5, -8, 1, 0), z = 10 }), fmt = s[5] }
		row.MouseEnter:Connect(function() tween(row, 0.12, { BackgroundTransparency = 0.92 }) end)
		row.MouseLeave:Connect(function() tween(row, 0.2, { BackgroundTransparency = k % 2 == 0 and 0.97 or 1 }) end)
	end

	-- upgrades: free points banner + one row per skill (same actions and numbers as the old Skills screen)
	local freeCard = UI.card(upB, { sz = UDim2.new(1, 0, 0, 58), z = 9, hot = true })
	local freeN = text(freeCard, "0", { font = "display", size = 36, color = C.gold, pos = UDim2.fromOffset(14, 0), sz = UDim2.fromOffset(80, 58), z = 10, align = Enum.TextXAlignment.Center, scaled = true })
	text(freeCard, "SKILL POINTS FREE", { font = "heavy", size = 17, color = C.gold, pos = UDim2.fromOffset(100, 8), sz = UDim2.new(1, -110, 0, 22), z = 10, truncate = true })
	local freeSub = text(freeCard, "", { size = 13, color = C.muted, pos = UDim2.fromOffset(100, 30), sz = UDim2.new(1, -110, 0, 18), z = 10, truncate = true })
	local freeStroke = UI.mk("UIStroke", { Color = C.gold, Thickness = 2, Transparency = 1 }, freeCard)
	task.spawn(function()
		while freeCard.Parent do
			if (App.state and App.state.skillFree or 0) > 0 then
				tween(freeStroke, 0.8, { Transparency = 0.1 }, Enum.EasingStyle.Sine); task.wait(0.8)
				tween(freeStroke, 0.8, { Transparency = 0.8 }, Enum.EasingStyle.Sine); task.wait(0.8)
			else
				freeStroke.Transparency = 1; task.wait(1)
			end
		end
	end)
	local upRows = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 66), Size = UDim2.new(1, 0, 1, -66), ZIndex = 9 }, upB)
	UI.mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, upRows)

	local function effect(s, n, st)
		if s.key == "inf" then return "Max Influence " .. R.MaxInfluence(st.lv, st.sk) end
		if s.key == "sup" then return "Max Supply " .. R.MaxSupply(st.lv, st.sk) end
		if s.key == "atk" then return "+" .. (n * 4) .. " attack" end
		if s.key == "def" then return "+" .. (n * 4) .. " defense" end
		return (st.lotsMax or 0) .. " building lots"
	end
	local function drawUpgrades(st)
		UI.clear(upRows)
		local free = st.skillFree or 0
		for k, s in ipairs(R.Skills) do
			local n = (st.sk and st.sk[s.key]) or 0
			local cost = s.cost(n)
			local can = free >= cost
			local row = UI.card(upRows, { sz = UDim2.new(1, 0, 0, 56), z = 10, order = k })
			hoverStroke(UI, row, can and C.gold or C.rule)
			local iconBg = UI.img(row, "circle", { sz = UDim2.fromOffset(38, 38), pos = UDim2.new(0, 8, 0.5, 0), anchor = Vector2.new(0, 0.5), color = C.slate, z = 11, slice = false })
			UI.icon(iconBg, s.icon, 22, can and C.gold or C.manila, UDim2.fromScale(0.5, 0.5), { z = 12, anchor = Vector2.new(0.5, 0.5) })
			text(row, s.name, { font = "heavy", size = 16, pos = UDim2.fromOffset(54, 6), sz = UDim2.new(1, -54 - 176, 0, 20), z = 11, truncate = true })
			text(row, effect(s, n, st) .. "  <font color='#6b7179'>· " .. s.desc .. "</font>", { size = 13, color = C.ink, rich = true, pos = UDim2.fromOffset(54, 28), sz = UDim2.new(1, -54 - 120, 0, 18), z = 11, truncate = true })
			UI.chip(row, "LV " .. n, { pos = UDim2.new(1, -124, 0, 6), anchor = Vector2.new(1, 0), h = 22, size = 13, z = 11, manila = n > 0 })
			UI.button(row, can and "gold" or "locked", "+  " .. cost .. " PT" .. (cost > 1 and "S" or ""), function(btn)
				local res = App.req("skill", { key = s.key }, btn)
				if res.ok then App.float(btn.Inst, s.name .. " UP", C.gold) end
			end, { pos = UDim2.new(1, -8, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(108, 40), z = 12, textSize = 15 })
		end
	end

	------------------------------------------------ refresh
	local function drawLogin(st)
		UI.clear(loginRow)
		local o = buildLoginCards(App, loginRow, st, nil)
		loginCountdown = o.countdown
		local idx = math.clamp((st.login and st.login.idx) or 1, 1, #TK.Login)
		obj.loginReady = st.loginReady == true
		obj.loginIdx = idx
	end

	function obj:Refresh(st)
		if not st then return end
		local era = R.EraOf(st.lv)
		local E = D.Eras[era]
		if obj.era ~= era then
			obj.era = era
			scene.Image = UI.asset("country_era" .. era)
			scene.ImageTransparency = 1
			tween(scene, 0.6, { ImageTransparency = 0 })
			kenBurns()
		end
		eraName.Text = eraTitle(E.name)
		eraChipOnImgL.Text = string.upper(E.name)
		chipEra.Text = "ERA " .. era .. " OF " .. #D.Eras
		chipLv.Text = "LEVEL " .. st.lv
		chipInc.Text = R.Money(st.incHr or 0) .. "/HR"
		local N = D.Eras[era + 1]
		if N then
			nextL.Text = "NEXT: <font color='#ece8dc'>" .. eraTitle(N.name) .. "</font>"
			reqL.Text = "REQUIRES LEVEL " .. N.start
			reqL.TextColor3 = C.ink
			local span = math.max(1, N.start - E.start)
			eraBar:Set((st.lv - E.start) / span, "LV " .. st.lv .. " / " .. N.start, (N.start - st.lv) .. " TO GO")
		else
			nextL.Text = "THE FINAL ERA"
			reqL.Text = "YOU REACHED THE STARS"
			reqL.TextColor3 = C.gold
			eraBar:Set(1, "MAX ERA", "")
		end
		sub.Text = "Your nation in the <font color='#f0c75a'><b>" .. eraTitle(E.name) .. "</b></font>"

		-- identity + stats
		local fk = st.flag and (tostring(st.flag.l) .. table.concat(st.flag.c or {}, "") .. tostring(st.flag.e) .. tostring(st.flag.img))
		if fk ~= obj.flagKey then
			obj.flagKey = fk
			for _, ch in ipairs(flagHost:GetChildren()) do if ch.Name == "Flag" then ch:Destroy() end end
			UI.flag(flagHost, st.flag, 58, { z = 10 })
		end
		nameL.Text = string.upper((st.name and st.name ~= "") and st.name or Players.LocalPlayer.DisplayName)
		ideoL.Text = (st.ideo and type(st.ideo) == "string" and (st.ideo .. " · ") or "") .. eraTitle(E.name)
		xpBar:Set((st.xp or 0) / math.max(1, st.xpReq or 1), "LEVEL " .. st.lv, R.Short(math.floor(st.xp or 0)) .. " / " .. R.Short(st.xpReq or 0) .. " XP")
		local officers = 0
		for _ in pairs((st.inv and st.inv.officers) or {}) do officers += 1 end
		local values = {
			level = st.lv, incHr = st.incHr or 0, atk = st.atk or 0, def = st.def or 0, inf = st.infMax or 0, sup = st.supMax or 0,
			off = officers, gold = st.goldLaws or 0, wins = (st.stats and st.stats.wins) or 0,
		}
		for key, v in pairs(values) do
			local sv = statVal[key]
			if sv then countTo(sv.label, v, sv.fmt) end
		end

		-- upgrades
		countTo(freeN, st.skillFree or 0, function(v) return tostring(math.floor(v + 0.5)) end)
		freeSub.Text = "+3 every level · +1 per Gold law (" .. (st.goldLaws or 0) .. " so far)"
		drawUpgrades(st)

		-- login row (rebuild only when it changed so the hover state does not flicker)
		local idx = math.clamp((st.login and st.login.idx) or 1, 1, #TK.Login)
		if obj.loginIdx ~= idx or obj.loginReady ~= (st.loginReady == true) then drawLogin(st) end
	end
	function obj:Tick(st)
		if not st then return end
		local idx = obj.loginIdx or 1
		if obj.loginReady then
			loginRight.Text = "<font color='#f0c75a'>Day " .. idx .. " is ready to claim!</font>"
		else
			local left = hms(nextDayIn(App))
			loginRight.Text = "Day " .. idx .. " in <font color='#f0c75a'>" .. left .. "</font>"
			if loginCountdown and loginCountdown.Parent then loginCountdown.Text = "IN " .. left end
		end
	end
	function obj:Opened()
		if kb then kb:Play() end
		list.CanvasPosition = Vector2.zero
	end
	return obj
end }

-- ClientMain calls _init.init(App) at load so App.showLogin exists before the Country screen is ever opened
S._init = { init = function(App)
	App.showLogin = function() showLogin(App) end
	App.showFlagEditor = function() showFlagEditor(App) end
end }

return S
