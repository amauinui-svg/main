-- Warfare screens: the alliance WEEKLY TAKEDOWN (key "takedown", modelled on the reference game's Family > Takedown)
-- and RAIDS (key "battle", replaces the old rival list in War.lua: Kash 1 Oct 2026, raid only players in your server
-- plus 3 AI nations, no refresh, 10% of cash on hand capped at ~1 h of law income, 1 minute cooldown, soldiers die).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local M = require(Shared.Military)
local Config = require(Shared.Config)
local okO, O = pcall(require, Shared:WaitForChild("Officers"))
if not okO then O = nil end
local Remotes = RS:WaitForChild("Remotes")
local LP = Players.LocalPlayer

local S = {}

---------------------------------------------------------------- local helpers
local function tw(o, t, props, style, dir)
	local x = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	x:Play()
	return x
end
local function esc(s)
	s = tostring(s or "")
	s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
	return s
end
-- "2d 21h", "21h 13m", "13m 5s"
local function dhm(sec)
	sec = math.max(0, math.floor(sec or 0))
	local d, h, m = sec // 86400, (sec % 86400) // 3600, (sec % 3600) // 60
	if d > 0 then return d .. "d " .. h .. "h" end
	if h > 0 then return h .. "h " .. m .. "m" end
	return m .. "m " .. (sec % 60) .. "s"
end
local function ago(App, t)
	local d = math.max(0, math.floor(App.now() - (t or 0)))
	if d < 60 then return "now" end
	if d < 3600 then return (d // 60) .. "m ago" end
	if d < 86400 then return (d // 3600) .. "h ago" end
	return (d // 86400) .. "d ago"
end
-- request without App.req's raw toast (so "no_attacks" etc. can get friendly copy). quiet = no toast at all
local function req(App, action, args, btn, quiet)
	local ok, res = pcall(function() return Remotes.Request:InvokeServer(action, args or {}) end)
	if not ok or type(res) ~= "table" then res = { ok = false, msg = "Connection problem. Try again." } end
	if not res.ok and not quiet and res.msg and res.msg ~= "no_attacks" then
		App.toast(res.msg, nil, "bad")
		if btn then App.shake(btn.Inst or btn) end
	end
	return res
end
-- counts a label's number up to a target
local function countUp(label, from, to, fmt, dur)
	fmt = fmt or R.Commas
	if from == to or not from then label.Text = fmt(to); return end
	local nv = Instance.new("NumberValue")
	nv.Value = from
	nv.Changed:Connect(function(v) label.Text = fmt(math.floor(v + 0.5)) end)
	local t = tw(nv, dur or 0.6, { Value = to })
	t.Completed:Connect(function() label.Text = fmt(to); nv:Destroy() end)
end
-- hover lift on any GuiObject (adds its own UIScale)
local function hover(gui, amount)
	local sc = Instance.new("UIScale")
	sc.Name = "Hover"
	sc.Parent = gui
	gui.MouseEnter:Connect(function() tw(sc, 0.15, { Scale = 1 + (amount or 0.03) }, Enum.EasingStyle.Back) end)
	gui.MouseLeave:Connect(function() tw(sc, 0.15, { Scale = 1 }) end)
	return sc
end

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

-- popup on App.modalHost: scale-in folder panel with a close X. Returns panel, body, close()
local function popup(App, title, w, h)
	local UI = App.UI
	local host = App.modalHost
	UI.clear(host)
	host.Visible = true
	local function close() host.Visible = false; UI.clear(host) end
	local catcher = UI.mk("TextButton", { Name = "Backdrop", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 70 }, host)
	catcher.Activated:Connect(close)
	local W, H = math.min(w, App.W() - 40), math.min(h, App.H() - 40)
	local panel, body = UI.panel(host, title, { sz = UDim2.fromOffset(W, H), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71, button = true, titleSize = 24 })
	local x = UI.img(panel, "btn_slate", { button = true, name = "Close", sz = UDim2.fromOffset(36, 34), pos = UDim2.new(1, -48, 0, 10), z = 75 })
	UI.icon(x, "icon_x", 18, UI.C.ink, UDim2.new(0.5, 0, 0.5, -1), { z = 76, anchor = Vector2.new(0.5, 0.5) })
	x.Activated:Connect(close)
	FX.popIn(panel, 0.6, 0.3)
	return panel, body, close
end

-- an "i" button that explains a system in a small popup
local function infoButton(App, parent, title, body, pos, z)
	local UI = App.UI
	local b = UI.img(parent, "chip", { button = true, name = "Info", sz = UDim2.fromOffset(26, 26), pos = pos, z = z or 8 })
	UI.text(b, "i", { font = "heavy", size = 16, color = UI.C.manila, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = (z or 8) + 1 })
	hover(b, 0.1)
	b.Activated:Connect(function()
		local _, bd = popup(App, title, 460, 260)
		UI.text(bd, body, { size = 16, wrap = true, rich = true, sz = UDim2.fromScale(1, 1), valign = Enum.TextYAlignment.Top, z = 74 })
	end)
	return b
end

-- HP bar that tweens (UI.bar sets size instantly)
local function hpBar(UI, parent, p)
	local track = UI.img(parent, "bar_track", { name = "HP", pos = p.pos, sz = p.sz, z = p.z, anchor = p.anchor })
	local fill = UI.img(track, "bar_fill", { name = "Fill", pos = UDim2.fromOffset(3, 3), sz = UDim2.new(1, -6, 1, -6), z = p.z + 1, color = p.color })
	local label = UI.text(track, "", { font = "heavy", size = p.textSize or 13, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = p.z + 2, stroke = 1.3, color = UI.C.white, scaled = true })
	local o = { Inst = track, Fill = fill, Label = label, frac = -1 }
	function o:Set(frac, s, animate)
		frac = math.clamp(frac or 0, 0, 1)
		local size = UDim2.new(frac, -6 * frac, 1, -6)
		if frac > 0.005 then fill.Visible = true end
		if animate and self.frac >= 0 then
			local t = tw(fill, 0.4, { Size = size })
			if frac <= 0.005 then t.Completed:Connect(function() fill.Visible = false end) end
		else
			fill.Size = size
			fill.Visible = frac > 0.005
		end
		self.frac = frac
		label.Text = s or ""
	end
	return o
end

---------------------------------------------------------------- shared raid state + helpers (used by the RAIDS screen, the
-- raided popup and the revenge-strike result, so they live at module level)
local OVERLAY = 0.45 -- ClientMain's modal backdrop transparency
local DESIGN_W, DESIGN_H = 760, 560 -- the fight screen is laid out at this size and scaled to fit
local raidState = { dismissed = nil, intel = {} } -- dismissed = revenge.t answered/closed; intel[id] = { v = intel, at = os.clock() }
local INTEL_SECONDS = 15 * 60

local function rarityColor(key)
	local r = O and O.RarityByKey and O.RarityByKey[key or "common"]
	return r and Color3.fromHex(r.color) or Color3.fromHex("9a9fa6")
end
local function bigNum(n)
	n = math.floor(n or 0)
	if math.abs(n) < 1e6 then return R.Commas(n) end
	return R.Short(n)
end
-- guns leave bullet holes, blades and fists leave slashes, crits burst
local function impactKey(weapon, crit)
	if crit then return "fx_burst" end
	local ic = string.lower(tostring(weapon and weapon.icon or ""))
	if ic:find("musket") or ic:find("rifle") or ic:find("pistol") or ic:find("gun") then return "fx_bullet" end
	return "fx_slash"
end
local function closeModal(App)
	local mh = App.modalHost
	mh.Visible = false
	mh.BackgroundTransparency = OVERLAY
	App.UI.clear(mh)
end
-- a dark rounded reward pill: icon + text, sizes to its text
local function rewardPill(UI, parent, icon, color, s, order, z)
	local f = UI.mk("Frame", { Name = "Reward", BackgroundColor3 = Color3.fromHex("1a1f28"), BorderSizePixel = 0, Size = UDim2.fromOffset(0, 40), AutomaticSize = Enum.AutomaticSize.X, ZIndex = z, LayoutOrder = order }, parent)
	UI.mk("UICorner", { CornerRadius = UDim.new(0, 6) }, f)
	UI.mk("UIStroke", { Color = color, Thickness = 1, Transparency = 0.6 }, f)
	UI.mk("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 14) }, f)
	UI.mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, f)
	UI.icon(f, icon, 26, color, nil, { z = z + 1, order = 1 })
	local l = UI.text(f, s, { font = "heavy", size = 24, color = color, sz = UDim2.new(0, 0, 1, 0), z = z + 1, order = 2, rich = true })
	l.AutomaticSize = Enum.AutomaticSize.X
	return f, l
end

-- one side of the FIGHT screen. f = fight.a / fight.d, side = "a" (left, attacks right) or "d" (right)
local CARD_W, CARD_H, PORT = 300, 290, 110
local function fighterCard(App, parent, f, side, cx, top, maxHp, range, z)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	f = f or {}
	local o = { side = side, f = f, maxHp = math.max(1, maxHp or 1), range = range or { 0, 0 } }
	local card = mk("Frame", { Name = side == "a" and "Attacker" or "Defender", BackgroundColor3 = Color3.fromHex("1c2230"), BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(cx, top), Size = UDim2.fromOffset(CARD_W, CARD_H), ZIndex = z }, parent)
	mk("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
	o.stroke = mk("UIStroke", { Color = C.rule, Thickness = 1.5, Transparency = 0.2 }, card)
	o.card, o.home = card, card.Position

	-- portrait (avatar headshot for players, the big flag for AI nations) with the weapon beside it, facing the enemy
	local pcx = side == "a" and (CARD_W / 2 - 34) or (CARD_W / 2 + 34)
	local wcx = side == "a" and (pcx + PORT / 2 + 44) or (pcx - PORT / 2 - 44)
	local portrait = mk("Frame", { Name = "Portrait", BackgroundColor3 = Color3.fromHex("10141a"), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(pcx, 14), Size = UDim2.fromOffset(PORT, PORT), ZIndex = z + 1, ClipsDescendants = true }, card)
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, portrait)
	o.pstroke = mk("UIStroke", { Color = side == "a" and C.gold or C.rule, Thickness = 2 }, portrait)
	o.portrait, o.phome = portrait, portrait.Position
	o.pcx, o.pcy = cx - CARD_W / 2 + pcx, top + 14 + PORT / 2 -- portrait centre in panel coordinates
	if f.userId and not f.ai then
		local img = mk("ImageLabel", { Name = "Headshot", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z + 2, ScaleType = Enum.ScaleType.Crop, Image = "" }, portrait)
		o.img = img
		task.spawn(function()
			local ok, url = pcall(function() return Players:GetUserThumbnailAsync(f.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180) end)
			if ok and url and img.Parent then img.Image = url end
		end)
	else
		UI.flag(portrait, f.flag, PORT - 18, { pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = z + 2 })
		if f.ai then
			local ai = mk("Frame", { BackgroundColor3 = C.black, BackgroundTransparency = 0.25, BorderSizePixel = 0, Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(26, 16), ZIndex = z + 3 }, portrait)
			mk("UICorner", { CornerRadius = UDim.new(0, 3) }, ai)
			text(ai, "AI", { font = "heavy", size = 12, color = C.blue, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = z + 4 })
		end
	end
	-- hit flash overlay
	o.flash = mk("Frame", { Name = "Flash", BackgroundColor3 = Color3.fromRGB(255, 50, 40), BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = z + 5 }, portrait)
	-- gold level badge (outside the clipped portrait, on the card)
	local badge = mk("Frame", { Name = "Level", BackgroundColor3 = C.gold, BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromOffset(pcx + PORT / 2 + 10, 14 + PORT + 6), Size = UDim2.fromOffset(44, 28), ZIndex = z + 6 }, card)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, badge)
	text(badge, tostring(f.lv or 1), { font = "heavy", size = 18, color = C.manilaInk, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = z + 7 })
	-- weapon (fists when nothing is equipped), on a soft rarity glow
	local w = f.weapon or { icon = "gear_fists", name = "Fists", rarity = "common" }
	local wkey = (w.icon and UI.asset(w.icon) ~= "") and w.icon or "gear_fists"
	UI.img(card, "glow_soft", { name = "WeaponGlow", color = rarityColor(w.rarity), alpha = 0.55, slice = false, z = z + 1, anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromOffset(wcx, 14 + PORT / 2), sz = UDim2.fromOffset(104, 104) })
	local weapon = UI.img(card, wkey, { name = "Weapon", slice = false, fit = true, z = z + 2, anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromOffset(wcx, 14 + PORT / 2), sz = UDim2.fromOffset(78, 78) })
	weapon.Rotation = side == "a" and -12 or 12
	o.weapon = weapon
	-- name + tag line
	local nm = (f.name and tostring(f.name) ~= "") and tostring(f.name) or (side == "a" and Players.LocalPlayer.DisplayName or "?")
	text(card, nm, { font = "heavy", size = 21, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(10, 14 + PORT + 8), sz = UDim2.new(1, -20, 0, 24), z = z + 1, truncate = true })
	local tagLine = f.tag and ("[" .. tostring(f.tag) .. "]") or (f.ai and "AI NATION") or (side == "a" and "ATTACKER" or "DEFENDER")
	text(card, tagLine, { font = "bold", size = 14, color = C.gold, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(10, 14 + PORT + 32), sz = UDim2.new(1, -20, 0, 16), z = z + 1, truncate = true })
	-- power box: attack for the attacker, defense for the defender
	local box = mk("Frame", { Name = "Power", BackgroundColor3 = Color3.fromHex("10141a"), BorderSizePixel = 0, Position = UDim2.fromOffset(20, 182), Size = UDim2.fromOffset(CARD_W - 40, 38), ZIndex = z + 1 }, card)
	mk("UICorner", { CornerRadius = UDim.new(0, 5) }, box)
	UI.icon(box, side == "a" and "icon_attack" or "icon_defense", 24, side == "a" and C.bad or C.blue, UDim2.new(0, 12, 0.5, 0), { z = z + 2, anchor = Vector2.new(0, 0.5) })
	text(box, bigNum(f.pow), { font = "heavy", size = 24, color = side == "a" and C.gold or C.ink, pos = UDim2.fromOffset(48, 0), sz = UDim2.new(1, -56, 1, 0), z = z + 2, scaled = true })
	-- HP bar (tweens)
	o.hp = hpBar(UI, card, { pos = UDim2.fromOffset(20, 228), sz = UDim2.fromOffset(CARD_W - 40, 22), z = z + 1, color = C.good, textSize = 13 })
	o.hpNow = o.maxHp
	o.hp:Set(1, bigNum(o.maxHp) .. " / " .. bigNum(o.maxHp), false)
	-- damage range: "min ——|—— max" with a marker on each roll
	text(card, bigNum(o.range[1]), { size = 17, color = C.muted, align = Enum.TextXAlignment.Right, pos = UDim2.fromOffset(8, 256), sz = UDim2.fromOffset(62, 24), z = z + 1, scaled = true })
	text(card, bigNum(o.range[2]), { size = 17, color = C.muted, pos = UDim2.fromOffset(CARD_W - 70, 256), sz = UDim2.fromOffset(62, 24), z = z + 1, scaled = true })
	local track = mk("Frame", { Name = "Range", BackgroundColor3 = C.rule, BorderSizePixel = 0, Position = UDim2.fromOffset(80, 267), Size = UDim2.fromOffset(CARD_W - 160, 2), ZIndex = z + 1 }, card)
	for _, x in ipairs({ 0, 1 }) do
		mk("Frame", { BackgroundColor3 = C.rule, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.5), Size = UDim2.fromOffset(2, 10), ZIndex = z + 1 }, track)
	end
	o.marker = mk("Frame", { Name = "Marker", BackgroundColor3 = C.muted, BackgroundTransparency = 0.5, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(5, 16), ZIndex = z + 2 }, track)
	mk("UICorner", { CornerRadius = UDim.new(0, 2) }, o.marker)

	function o:SetHp(hp, animate)
		self.hpNow = math.max(0, hp or 0)
		local frac = self.hpNow / self.maxHp
		self.hp:Set(frac, bigNum(self.hpNow) .. " / " .. bigNum(self.maxHp), animate)
		self.hp.Fill.ImageColor3 = frac > 0.5 and C.good or (frac > 0.25 and C.gold or C.bad)
	end
	function o:Roll(r, crit, animate)
		local v = math.clamp(((r or 0.95) - 0.75) / 0.4, 0, 1)
		local goal = { Position = UDim2.fromScale(v, 0.5), BackgroundTransparency = 0, BackgroundColor3 = crit and C.gold or C.white }
		if animate then tw(self.marker, 0.28, goal, Enum.EasingStyle.Back) else for k, val in pairs(goal) do self.marker[k] = val end end
	end
	return o
end

-- plays res.fight on the modal host, then VICTORY / DEFEAT + rewards. opts = { revenge = bool, name = target name }
local fightToken = 0
local function playFight(App, res, opts)
	opts = opts or {}
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local fight = res.fight
	fightToken += 1
	local token = fightToken
	local mh = App.modalHost
	UI.clear(mh)
	mh.Visible = true
	mh.BackgroundTransparency = 0.2
	local stage = mk("TextButton", { Name = "Fight", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 71 }, mh)
	local skip, finished = false, false
	stage.Activated:Connect(function() if not finished then skip = true end end)
	local function alive() return token == fightToken and stage.Parent ~= nil end
	local function pause(t)
		local e = 0
		while e < t and not skip and alive() do e += task.wait() end
	end
	local function close() if token == fightToken then closeModal(App) end end

	-- the panel is built at DESIGN size and scaled to fit (phones), popping in from the centre
	local fitS = math.min(1, (App.W() - 24) / DESIGN_W, (App.H() - 24) / DESIGN_H)
	local panel = UI.img(stage, "panel_plain", { name = "FightPanel", sz = UDim2.fromOffset(DESIGN_W, DESIGN_H), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 72 })
	mk("UIStroke", { Color = C.gold, Thickness = 2, Transparency = 0.15 }, panel)
	local pscale = mk("UIScale", { Scale = fitS * 0.6 }, panel)
	tw(pscale, 0.34, { Scale = fitS }, Enum.EasingStyle.Back)

	text(panel, "FIGHT", { font = "display", size = 46, color = C.gold, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 10), sz = UDim2.new(1, 0, 0, 54), z = 74, stroke = 1.2 })
	if opts.revenge then
		UI.chip(panel, "REVENGE STRIKE", { pos = UDim2.new(0.5, 0, 0, 62), anchor = Vector2.new(0.5, 0), z = 74, icon = "icon_crosshair", color = C.bad, h = 22, size = 12 })
	end
	local A = fighterCard(App, panel, fight.a, "a", DESIGN_W / 2 - 64 - CARD_W / 2, 86, fight.aHp, fight.aRange, 74)
	local D = fighterCard(App, panel, fight.d, "d", DESIGN_W / 2 + 64 + CARD_W / 2, 86, fight.dHp, fight.dRange, 74)
	local vs = text(panel, "VS", { font = "display", size = 44, color = C.gold, align = Enum.TextXAlignment.Center, anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromOffset(DESIGN_W / 2, 86 + 120), sz = UDim2.fromOffset(110, 56), z = 75, stroke = 1 })
	local vsScale = mk("UIScale", { Scale = 0.2 }, vs)
	tw(vsScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	local hint = text(panel, "TAP TO SKIP", { font = "heavy", size = 15, color = C.muted, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 400), sz = UDim2.new(1, 0, 0, 20), z = 74 })
	task.spawn(function()
		while hint.Parent and not finished do
			tw(hint, 0.7, { TextTransparency = 0.6 }, Enum.EasingStyle.Sine); task.wait(0.7)
			if not hint.Parent or finished then break end
			tw(hint, 0.7, { TextTransparency = 0 }, Enum.EasingStyle.Sine); task.wait(0.7)
		end
	end)

	-- one blow: striker lunges, victim flashes red + shakes, impact art, floating number, HP drops, range marker slides
	local function blow(h)
		local S_, V_ = (h.who == "a") and A or D, (h.who == "a") and D or A
		local dir = h.who == "a" and 1 or -1
		tw(S_.card, 0.09, { Position = S_.home + UDim2.fromOffset(26 * dir, -4) }).Completed:Connect(function()
			if S_.card.Parent then tw(S_.card, 0.22, { Position = S_.home }, Enum.EasingStyle.Back) end
		end)
		S_:Roll(h.r, h.crit, true)
		task.delay(0.09, function()
			if finished or not V_.portrait.Parent then return end -- skipped: the final state is already shown
			V_.flash.BackgroundTransparency = h.crit and 0.2 or 0.4
			tw(V_.flash, 0.4, { BackgroundTransparency = 1 })
			task.spawn(function()
				for _, dx in ipairs({ 8, -7, 5, -4, 2, 0 }) do
					if not V_.portrait.Parent then return end
					V_.portrait.Position = V_.phome + UDim2.fromOffset(dx * (h.crit and 1.5 or 1), 0)
					task.wait(0.03)
				end
				V_.portrait.Position = V_.phome
			end)
			-- impact art on the portrait
			local fx = UI.img(V_.portrait, impactKey(S_.f.weapon, h.crit), { name = "Impact", slice = false, fit = true, z = 84, anchor = Vector2.new(0.5, 0.5),
				pos = UDim2.new(0.5, math.random(-16, 16), 0.5, math.random(-16, 16)), sz = UDim2.fromScale(h.crit and 0.95 or 0.7, h.crit and 0.95 or 0.7) })
			fx.Rotation = math.random(-25, 25)
			local fs = mk("UIScale", { Scale = 0.3 }, fx)
			tw(fs, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
			task.delay(0.45, function() if fx.Parent then tw(fx, 0.3, { ImageTransparency = 1 }) end end)
			task.delay(0.8, function() if fx.Parent then fx:Destroy() end end)
			-- floating damage
			local l = text(panel, (h.crit and "<font size='16'>CRIT!</font>\n" or "") .. "-" .. bigNum(h.dmg), { font = "heavy", size = h.crit and 34 or 28, rich = true,
				color = h.crit and C.gold or C.bad, align = Enum.TextXAlignment.Center, anchor = Vector2.new(0.5, 0.5),
				pos = UDim2.fromOffset(V_.pcx + math.random(-14, 14), V_.pcy - PORT / 2 - 6), sz = UDim2.fromOffset(160, h.crit and 64 or 36), z = 90, stroke = 2 })
			local ls = mk("UIScale", { Scale = 0.4 }, l)
			tw(ls, 0.22, { Scale = h.crit and 1.2 or 1 }, Enum.EasingStyle.Back)
			task.delay(0.3, function()
				if not l.Parent then return end
				tw(l, 0.7, { Position = l.Position - UDim2.fromOffset(0, 46), TextTransparency = 1 })
				local st = l:FindFirstChildOfClass("UIStroke")
				if st then tw(st, 0.7, { Transparency = 1 }) end
			end)
			task.delay(1.1, function() if l.Parent then l:Destroy() end end)
			V_:SetHp(h.hp, true)
		end)
	end

	local function finalState()
		local aEnd, dEnd = fight.aHp, fight.dHp
		local lastA, lastD
		for _, h in ipairs(fight.hits or {}) do
			if h.who == "a" then dEnd = h.hp; lastA = h else aEnd = h.hp; lastD = h end
		end
		A:SetHp(aEnd, false); D:SetHp(dEnd, false)
		if lastA then A:Roll(lastA.r, lastA.crit, false) end
		if lastD then D:Roll(lastD.r, lastD.crit, false) end
		A.card.Position, D.card.Position = A.home, D.home
		A.portrait.Position, D.portrait.Position = A.phome, D.phome
		for _, side in ipairs({ A, D }) do
			side.flash.BackgroundTransparency = 1
			for _, x in ipairs(side.portrait:GetChildren()) do if x.Name == "Impact" then x:Destroy() end end
		end
	end

	local function showResult()
		if finished or not alive() then return end
		finished = true
		finalState()
		hint.Visible = false
		local win = res.win
		local winner, loser = win and A or D, win and D or A
		winner.stroke.Color, winner.stroke.Thickness, winner.stroke.Transparency = C.gold, 2.5, 0
		loser.stroke.Color = C.bad
		if loser.img then tw(loser.img, 0.5, { ImageColor3 = Color3.fromRGB(90, 90, 96) }) end
		tw(loser.weapon, 0.5, { ImageTransparency = 0.5 })
		-- banner
		local holder = mk("Frame", { Name = "Result", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(DESIGN_W / 2, 404), Size = UDim2.fromOffset(DESIGN_W - 40, 60), ZIndex = 80 }, panel)
		text(holder, win and "VICTORY" or "DEFEAT", { font = "display", size = 58, color = win and C.gold or C.bad, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 81, stroke = 1.5 })
		FX.popIn(holder, 0.4, 0.42)
		-- rewards
		local function pillRow(y)
			local r = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(DESIGN_W / 2, y), Size = UDim2.fromOffset(DESIGN_W - 40, 40), ZIndex = 80 }, panel)
			mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, r)
			return r
		end
		local r1, r2 = pillRow(440), pillRow(486)
		if win then
			local _, cashL = rewardPill(UI, r1, "icon_cash", C.good, "+$0", 1, 81)
			countUp(cashL, 0, res.cash or 0, function(n) return "+" .. R.Money(n) end, 0.9)
			rewardPill(UI, r1, "icon_xp", C.xp, "+" .. R.Commas(res.xp or 0) .. " XP", 2, 81)
		else
			rewardPill(UI, r1, "icon_defense", C.muted, "Their defense held", 1, 81)
		end
		rewardPill(UI, r2, "icon_military", C.bad, R.Commas(res.lostN or 0) .. " soldiers lost", 1, 81)
		rewardPill(UI, r2, "icon_crosshair", C.gold, R.Commas(res.killed or 0) .. " enemy killed", 2, 81)
		for _, r in ipairs({ r1, r2 }) do
			r.Position += UDim2.fromOffset(0, 12)
			tw(r, 0.35, { Position = r.Position - UDim2.fromOffset(0, 12) }, Enum.EasingStyle.Back)
			FX.fadeIn(r, 0.25)
		end
		-- buttons
		local bar = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0, DESIGN_W / 2, 1, -14), Size = UDim2.fromOffset(DESIGN_W - 40, 46), ZIndex = 82 }, panel)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }, bar)
		UI.button(bar, "gold", "DONE", close, { sz = UDim2.fromOffset(240, 46), z = 83, order = 1, textSize = 20 })
		if (res.lostN or 0) > 0 then
			UI.button(bar, "green", "REBUILD ARMY", function() close(); App.open("military") end, { sz = UDim2.fromOffset(220, 46), z = 83, order = 2, icon = "icon_military", textSize = 17 })
		end
		FX.popIn(bar, 0.6, 0.3)
	end

	task.spawn(function()
		pause(0.55)
		for _, h in ipairs(fight.hits or {}) do
			if skip or not alive() then break end
			blow(h)
			pause(0.72)
		end
		if not alive() then return end
		if not skip then pause(0.35) end
		showResult()
	end)
end

-- fallback report for a result without fight data (older server)
local function resultPopup(App, res, targetName)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local _, bd = popup(App, "RAID REPORT", 460, 420)
	local win = res.win
	local band = mk("Frame", { Name = "Banner", BackgroundColor3 = win and Color3.fromHex("2f4a26") or Color3.fromHex("4a1f1f"), BorderSizePixel = 0, Size = UDim2.new(1, -40, 0, 74), ZIndex = 74 }, bd)
	mk("UIStroke", { Color = win and C.good or C.bad, Thickness = 2 }, band)
	mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(170, 170, 170)) }, band)
	local big = text(band, win and "VICTORY" or "DEFEAT", { font = "display", size = 38, color = win and C.gold or C.bad, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(0, 4), sz = UDim2.new(1, 0, 0, 42), z = 75, stroke = 1.5 })
	FX.centre(big)
	local bs = mk("UIScale", { Scale = 1.6 }, big)
	tw(bs, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	text(band, "vs " .. tostring(targetName or res.target or "?"), { size = 14, color = C.ink, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(10, 46), sz = UDim2.new(1, -20, 0, 20), z = 75, truncate = true })
	local rowsF = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 1, -86 - 56), ZIndex = 74 }, bd)
	mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, rowsF)
	local function line(order, icon, color, label, value)
		local r = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), ZIndex = 74, LayoutOrder = order }, rowsF)
		UI.icon(r, icon, 20, color, UDim2.new(0, 2, 0.5, 0), { z = 75, anchor = Vector2.new(0, 0.5) })
		text(r, label, { size = 16, pos = UDim2.fromOffset(30, 0), sz = UDim2.new(0.6, -30, 1, 0), z = 75 })
		return text(r, value, { font = "heavy", size = 18, color = color, align = Enum.TextXAlignment.Right, pos = UDim2.new(0.6, 0, 0, 0), sz = UDim2.new(0.4, 0, 1, 0), z = 75 })
	end
	if win then
		local cashL = line(1, "icon_cash", C.good, "Cash stolen", "+$0")
		countUp(cashL, 0, res.cash or 0, function(n) return "+" .. R.Money(n) end, 0.8)
		line(2, "icon_xp", C.xp, "Experience", "+" .. R.Commas(res.xp or 0) .. " XP")
	else
		line(1, "icon_cash", C.muted, "Cash stolen", "$0")
	end
	line(3, "icon_military", C.bad, "Your soldiers lost", R.Commas(res.lostN or 0))
	line(5, "icon_crosshair", C.gold, "Enemy soldiers killed", R.Commas(res.killed or 0))
	UI.button(bd, "slate", "CLOSE", function() closeModal(App) end, { sz = UDim2.fromOffset(140, 46), anchor = Vector2.new(0, 1), pos = UDim2.new(0, 0, 1, 0), z = 75 })
	UI.button(bd, "green", "REBUILD ARMY", function() closeModal(App); App.open("military") end, { sz = UDim2.fromOffset(200, 46), anchor = Vector2.new(1, 1), pos = UDim2.new(1, 0, 1, 0), z = 75, icon = "icon_military" })
end

-- any raid result (normal raid, raid-back, revenge strike): the FIGHT screen when the server sent the blow-by-blow
local function showRaidResult(App, res, opts)
	if type(res) ~= "table" or not res.ok then return end
	opts = opts or {}
	local rv = App.state and App.state.revenge
	if rv and (opts.revenge or (opts.id and rv.id == opts.id and res.win)) then raidState.dismissed = rv.t end
	if type(res.fight) == "table" and type(res.fight.hits) == "table" and res.fight.a and res.fight.d then
		local ok, err = pcall(playFight, App, res, opts)
		if ok then return end
		warn("[Idle Country] fight screen: " .. tostring(err))
	end
	resultPopup(App, res, opts.name)
end

-- raid a nation by id and play the fight
local function raidTarget(App, id, name, btn)
	local res = App.req("raid", { id = id }, btn)
	if res.ok then showRaidResult(App, res, { id = id, name = name }) end
	return res
end

---------------------------------------------------------------- RAIDED popup + SPIED note (ClientMain calls App.raidedPopup / App.spiedNote)
local function raidedPopup(App, n)
	if type(n) ~= "table" then return end
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local revengeProd = Config.Products and Config.Products.RevengeStrike
	local price = revengeProd and revengeProd.robux or 49
	task.spawn(function()
		-- never cover another popup: wait (up to a minute) for the modal host to be free, else just toast
		local waited = 0
		while App.modalHost.Visible and waited < 60 do task.wait(0.5); waited += 0.5 end
		local name = tostring(n.by or "Someone")
		if App.modalHost.Visible then
			App.toast(n.win and (string.upper(name) .. " RAIDED YOU") or ("YOU HELD OFF " .. string.upper(name)), "Open RAIDS to hit back", n.win and "bad" or "good")
			return
		end
		local mh = App.modalHost
		UI.clear(mh)
		mh.Visible = true
		mh.BackgroundTransparency = OVERLAY
		local catcher = mk("TextButton", { Name = "Backdrop", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 70 }, mh)
		catcher.Activated:Connect(function() closeModal(App) end)
		local W, H = math.min(500, App.W() - 32), math.min(360, App.H() - 32)
		local panel = UI.img(mh, "panel", { button = true, name = "Raided", sz = UDim2.fromOffset(W, H), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71 })
		local accent = n.win and C.bad or C.good
		mk("UIStroke", { Color = accent, Thickness = 2, Transparency = 0.2 }, panel)
		local x = UI.img(panel, "btn_slate", { button = true, name = "Close", sz = UDim2.fromOffset(34, 32), pos = UDim2.new(1, -44, 0, 10), z = 76 })
		UI.icon(x, "icon_x", 16, C.ink, UDim2.new(0.5, 0, 0.5, -1), { z = 77, anchor = Vector2.new(0.5, 0.5) })
		x.Activated:Connect(function() closeModal(App) end)
		-- emblem
		local em = mk("Frame", { BackgroundColor3 = Color3.fromHex("10141a"), BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 62), Size = UDim2.fromOffset(78, 78), ZIndex = 73 }, panel)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, em)
		mk("UIStroke", { Color = accent, Thickness = 3 }, em)
		UI.img(panel, "glow_soft", { color = accent, alpha = 0.5, slice = false, z = 72, anchor = Vector2.new(0.5, 0.5), pos = UDim2.new(0.5, 0, 0, 62), sz = UDim2.fromOffset(150, 150) })
		UI.icon(em, n.win and "icon_flame" or "icon_defense", 40, accent, UDim2.fromScale(0.5, 0.5), { z = 74, anchor = Vector2.new(0.5, 0.5) })
		text(panel, n.win and (string.upper(name) .. " RAIDED YOU") or ("YOU HELD OFF " .. string.upper(name)), { font = "display", size = 28, color = n.win and C.bad or C.good,
			align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(20, 108), sz = UDim2.new(1, -40, 0, 34), z = 73, scaled = true, stroke = 1 })
		local rows = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 150), Size = UDim2.new(1, -40, 0, 40), ZIndex = 73 }, panel)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, rows)
		if n.win then
			local _, l = rewardPill(UI, rows, "icon_cash", C.bad, "-$0", 1, 74)
			countUp(l, 0, n.cash or 0, function(v) return "-" .. R.Money(v) end, 0.8)
		else
			rewardPill(UI, rows, "icon_cash", C.good, "Cash safe", 1, 74)
		end
		rewardPill(UI, rows, "icon_military", (n.lost or 0) > 0 and C.bad or C.muted, R.Commas(n.lost or 0) .. " soldiers lost", 2, 74)
		text(panel, n.win and "Hit back: ATTACK them now, or use a guaranteed REVENGE STRIKE." or "Their raid failed. Teach them a lesson?",
			{ size = 15, color = C.muted, wrap = true, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(24, 198), sz = UDim2.new(1, -48, 0, 40), z = 73 })
		local bar = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.new(1, -40, 0, 50), ZIndex = 74 }, panel)
		mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, bar)
		local bw = math.floor((W - 40 - 12) / 2)
		UI.button(bar, "red", "ATTACK", function(btn)
			if not n.byId then App.toast("They left the server", nil, "bad"); App.shake(btn.Inst); return end
			closeModal(App)
			App.open("battle")
			raidTarget(App, n.byId, name, nil)
		end, { sz = UDim2.fromOffset(bw, 50), z = 75, order = 1, icon = "icon_attack", textSize = 19 })
		UI.button(bar, "gold", "REVENGE · " .. price .. " R$", function(btn)
			if not n.byId then App.toast("They left the server", nil, "bad"); App.shake(btn.Inst); return end
			local res = App.req("revengeStrike", { id = n.byId }, btn)
			if res.ok then closeModal(App) end
		end, { sz = UDim2.fromOffset(bw, 50), z = 75, order = 2, icon = "icon_crosshair", textSize = 16 })
		FX.popIn(panel, 0.6, 0.34)
	end)
end

local spiedHost
local function spiedNote(App, n)
	if type(n) ~= "table" then return end
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	if not (spiedHost and spiedHost.Parent) then
		spiedHost = mk("Frame", { Name = "SpiedNotes", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, (App.TOP or 64) + 12),
			Size = UDim2.fromOffset(330, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 82 }, App.root)
		mk("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, spiedHost)
	end
	-- the layout positions the cell; the card inside is centre-anchored so it pops from its middle
	local cell = mk("TextButton", { Name = "Spied", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(330, 70), ZIndex = 82, LayoutOrder = math.floor(os.clock() * 10) }, spiedHost)
	local card = UI.img(cell, "panel_plain", { name = "Card", sz = UDim2.fromScale(1, 1), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 83 })
	mk("UIStroke", { Color = C.blue, Thickness = 1.5, Transparency = 0.3 }, card)
	mk("Frame", { Size = UDim2.new(0, 5, 1, -12), Position = UDim2.fromOffset(6, 6), BackgroundColor3 = C.blue, BorderSizePixel = 0, ZIndex = 84 }, card)
	UI.icon(card, "icon_satellite", 30, C.blue, UDim2.new(0, 22, 0.5, 0), { z = 84, anchor = Vector2.new(0, 0.5) })
	text(card, string.upper(tostring(n.by or "Someone")) .. " SPIED ON YOU", { font = "display", size = 17, color = C.blue, pos = UDim2.fromOffset(62, 8), sz = UDim2.new(1, -72, 0, 24), z = 84, truncate = true })
	text(card, "LV " .. tostring(n.lv or "?") .. " · they can see your cash and army. Bank your cash!", { size = 13, color = C.ink, pos = UDim2.fromOffset(62, 34), sz = UDim2.new(1, -72, 0, 28), z = 84, wrap = true })
	FX.popIn(card, 0.6, 0.3)
	local gone = false
	local function dismiss()
		if gone then return end
		gone = true
		tw(card:FindFirstChildOfClass("UIScale") or card, 0.18, { Scale = 0.85 })
		for _, d in ipairs(card:GetDescendants()) do
			if d:IsA("TextLabel") then tw(d, 0.18, { TextTransparency = 1 }) elseif d:IsA("ImageLabel") then tw(d, 0.18, { ImageTransparency = 1 })
			elseif d:IsA("Frame") then tw(d, 0.18, { BackgroundTransparency = 1 }) elseif d:IsA("UIStroke") then tw(d, 0.18, { Transparency = 1 }) end
		end
		tw(card, 0.18, { ImageTransparency = 1 })
		task.delay(0.2, function() cell:Destroy() end)
	end
	cell.Activated:Connect(dismiss)
	task.delay(6, dismiss)
end

-- no build field: ClientMain runs this once, so the popups exist before the RAIDS screen is ever opened
S._raided = { init = function(App)
	App.raidedPopup = function(n) raidedPopup(App, n) end
	App.spiedNote = function(n) spiedNote(App, n) end
	-- Revenge Strike results arrive later as a "raidResult" note (ClientMain emits it)
	App.on("raidResult", function(res) showRaidResult(App, res, { revenge = true, name = type(res) == "table" and res.target or nil }) end)
end }

---------------------------------------------------------------- WEEKLY TAKEDOWN
-- mirrors TD.StageRewards on the server
local TD_REWARDS = {
	{ seals = 3 },
	{ seals = 4, basic = 1 },
	{ seals = 5, basic = 2 },
	{ seals = 6, basic = 2 },
	{ seals = 10, limited = 1 },
}
local DEAD_TINT = Color3.fromRGB(22, 22, 26)

S.takedown = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local obj = {}
	local view, viewClock = nil, os.clock()
	local sel = 1
	local busy, polling, lastPoll = false, false, 0
	local enemyViews, enemyKey = {}, nil

	local root = mk("Frame", { Name = "Takedown", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 1, -20), ZIndex = 4 }, host)

	-------------------------------------------------- empty state (no alliance)
	local empty = UI.panel(host, nil, { sz = UDim2.fromOffset(460, 280), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 5, plain = true })
	empty.Visible = false
	UI.icon(empty, "icon_alliance", 64, C.manila, UDim2.new(0.5, 0, 0, 28), { z = 7, anchor = Vector2.new(0.5, 0) })
	text(empty, "WEEKLY TAKEDOWN", { font = "display", size = 26, color = C.manila, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(20, 102), sz = UDim2.new(1, -40, 0, 30), z = 7 })
	text(empty, "Join an alliance to storm a new enemy stronghold every week with your teammates and earn Seals and crates.", { size = 16, color = C.muted, wrap = true, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(30, 138), sz = UDim2.new(1, -60, 0, 54), z = 7 })
	UI.button(empty, "gold", "FIND AN ALLIANCE", function() App.open("alliance") end, { sz = UDim2.fromOffset(240, 48), pos = UDim2.new(0.5, 0, 1, -24), anchor = Vector2.new(0.5, 1), z = 8, icon = "icon_alliance" })

	-------------------------------------------------- header
	local title = text(root, "Weekly Takedown", { font = "display", size = 26, color = C.manila, pos = UDim2.fromOffset(0, 0), sz = UDim2.new(1, -520, 0, 30), z = 6, scaled = true })
	UI.icon(root, "icon_clock", 14, C.muted, UDim2.fromOffset(0, 35), { z = 6 })
	local ends = text(root, "", { size = 14, color = C.muted, pos = UDim2.fromOffset(20, 31), sz = UDim2.new(1, -540, 0, 20), z = 6, truncate = true })

	local btnRow = mk("Frame", { Name = "Buttons", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 4), Size = UDim2.fromOffset(3 * 148 + 16, 40), ZIndex = 6 }, root)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }, btnRow)
	local rewardsBtn, openRewards, openBoard, openLog
	rewardsBtn = UI.button(btnRow, "slate", "REWARDS", function() openRewards() end, { sz = UDim2.fromOffset(148, 40), icon = "icon_gift", textSize = 15, z = 7, order = 1, iconSize = 20 })
	UI.button(btnRow, "slate", "LEADERBOARD", function() openBoard() end, { sz = UDim2.fromOffset(148, 40), icon = "icon_rankings", textSize = 15, z = 7, order = 2, iconSize = 20 })
	UI.button(btnRow, "slate", "RECENT ATTACKS", function() openLog() end, { sz = UDim2.fromOffset(148, 40), icon = "icon_clock", textSize = 15, z = 7, order = 3, iconSize = 20 })
	local rewardDot = UI.badge(rewardsBtn.Inst, "!", UDim2.new(1, -4, 0, 4), 12)
	rewardDot.Visible = false
	infoButton(App, root, "WEEKLY TAKEDOWN",
		"Your whole alliance attacks the same stronghold this week: <b>5 stages</b>, the last one is the boss.\n\n" ..
		"You get <b>10 free attacks</b> (+1 every hour). After that each attack uses a <b>Takedown Ticket</b> from the Seals shop in Tasks.\n\n" ..
		"Every member who attacked at least once can claim the reward for each stage cleared. A <font color='#e2695f'><b>BIG HIT</b></font> deals double damage.",
		UDim2.new(1, -(3 * 148 + 16) - 34, 0, 11), 7)

	-------------------------------------------------- stat boxes
	local stats = mk("Frame", { Name = "Stats", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 58), ZIndex = 5 }, root)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, stats)
	local function statBox(order, icon, iconColor, label)
		local card = UI.card(stats, { sz = UDim2.new(1 / 3, -6, 1, 0), z = 6, order = order })
		UI.icon(card, icon, 28, iconColor, UDim2.new(0, 12, 0.5, 0), { z = 7, anchor = Vector2.new(0, 0.5) })
		text(card, label, { font = "bold", size = 12, color = C.muted, pos = UDim2.fromOffset(50, 6), sz = UDim2.new(0.55, -50, 0, 16), z = 7, truncate = true })
		local val = text(card, "0", { font = "heavy", size = 22, pos = UDim2.fromOffset(50, 24), sz = UDim2.new(0.5, -50, 0, 26), z = 7, scaled = true })
		local right = text(card, "", { size = 13, color = C.muted, anchor = Vector2.new(1, 1), pos = UDim2.new(1, -12, 1, -6), sz = UDim2.new(0.5, -6, 0, 18), z = 7, align = Enum.TextXAlignment.Right, truncate = true })
		return card, val, right
	end
	local freeCard, freeVal, freeNext = statBox(1, "icon_attack", C.gold, "FREE ATTACKS")
	local pipRow = mk("Frame", { Name = "Pips", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 10), Size = UDim2.new(0.45, 0, 0, 8), ZIndex = 7 }, freeCard)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, pipRow)
	local pips = {}
	for i = 1, 10 do
		pips[i] = mk("Frame", { Name = "Pip" .. i, BackgroundColor3 = C.rule, BorderSizePixel = 0, Size = UDim2.new(0.1, -2, 1, 0), ZIndex = 7, LayoutOrder = i }, pipRow)
	end
	local _, ticketVal, ticketNote = statBox(2, "icon_ticket", C.gold, "TAKEDOWN TICKETS")
	ticketNote.Text = "Used after free attacks"
	local _, dmgVal, rankNote = statBox(3, "icon_flame", C.bad, "YOUR WEEKLY DAMAGE")

	-------------------------------------------------- the stage (scene)
	local scene = UI.img(root, "takedown_bg", { name = "Scene", pos = UDim2.fromOffset(0, 122), sz = UDim2.new(1, 0, 1, -122 - 66), z = 5, slice = false })
	scene.ScaleType = Enum.ScaleType.Crop
	scene.ClipsDescendants = true
	mk("UICorner", { CornerRadius = UDim.new(0, 6) }, scene)
	mk("UIStroke", { Color = C.rule, Thickness = 2 }, scene)
	-- soft floor shade so plates and figures read on any part of the art
	local shade = mk("Frame", { Name = "Shade", BackgroundColor3 = C.black, BackgroundTransparency = 0.35, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, scene)
	mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.6, 1), NumberSequenceKeypoint.new(1, 0.4) }) }, shade)

	-- player card
	local col = mk("Frame", { Name = "You", BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 12), Size = UDim2.new(0, 176, 1, -24), ZIndex = 6 }, scene)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, col)
	local avatar = mk("Frame", { Name = "Avatar", BackgroundColor3 = C.slate, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -112), ZIndex = 6, LayoutOrder = 1 }, col)
	mk("UIAspectRatioConstraint", { AspectRatio = 1 }, avatar)
	mk("UIStroke", { Color = C.gold, Thickness = 2 }, avatar)
	mk("UICorner", { CornerRadius = UDim.new(0, 4) }, avatar)
	local avatarImg = mk("ImageLabel", { Name = "Headshot", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), ZIndex = 7, ScaleType = Enum.ScaleType.Crop }, avatar)
	task.spawn(function()
		local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180) end)
		if ok and img then avatarImg.Image = img end
	end)
	local avatarScale = mk("UIScale", {}, avatarImg) -- on the centred headshot (the frame sits in a list layout), so the lunge grows from the middle
	local you = mk("Frame", { Name = "Plate", BackgroundColor3 = C.black, BackgroundTransparency = 0.2, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 36), ZIndex = 6, LayoutOrder = 2 }, col)
	mk("UIStroke", { Color = C.rule, Thickness = 1 }, you)
	text(you, "YOU", { font = "heavy", size = 17, pos = UDim2.fromOffset(10, 0), sz = UDim2.new(0.4, 0, 1, 0), z = 7 })
	UI.icon(you, "icon_attack", 14, C.bad, UDim2.new(0.42, 0, 0.5, 0), { z = 7, anchor = Vector2.new(0, 0.5) })
	local youAtk = text(you, "", { font = "bold", size = 15, color = C.gold, pos = UDim2.new(0.42, 18, 0, 0), sz = UDim2.new(0.58, -28, 1, 0), z = 7, align = Enum.TextXAlignment.Right, scaled = true })
	local attackBtn
	local function attack() end -- forward (assigned below)
	attackBtn = UI.button(col, "red", "ATTACK", function() attack() end, { sz = UDim2.new(1, 0, 0, 64), textSize = 26, icon = "icon_attack", iconSize = 28, z = 7, order = 3 })
	local atkPulse = mk("UIStroke", { Color = C.gold, Thickness = 0, Transparency = 0.2 }, attackBtn.Inst)

	-- enemies
	local foe = mk("Frame", { Name = "Enemies", BackgroundTransparency = 1, Position = UDim2.fromOffset(204, 0), Size = UDim2.new(1, -216, 1, 0), ZIndex = 6 }, scene)
	local banner = mk("Frame", { Name = "Banner", BackgroundColor3 = C.black, BackgroundTransparency = 0.25, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.6, 0, 0, 120), ZIndex = 9, Visible = false }, scene)
	mk("UIStroke", { Color = C.gold, Thickness = 2 }, banner)
	local bannerTitle = text(banner, "", { font = "display", size = 28, color = C.gold, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(10, 14), sz = UDim2.new(1, -20, 0, 34), z = 10, scaled = true })
	local bannerBody = text(banner, "", { size = 15, color = C.ink, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(16, 52), sz = UDim2.new(1, -32, 0, 56), z = 10, wrap = true, valign = Enum.TextYAlignment.Top })

	local function updateSel()
		for i, ev in ipairs(enemyViews) do
			local on = i == sel and ev.alive
			ev.stroke.Color = on and C.gold or C.rule
			ev.stroke.Thickness = on and 2.5 or 1
			ev.name.TextColor3 = on and C.gold or C.ink
			ev.shadow.ImageColor3 = on and C.gold or C.black
			ev.shadow.ImageTransparency = on and 0.45 or 0.5
		end
	end

	local function buildEnemies(list)
		UI.clear(foe)
		enemyViews = {}
		local n = #list
		for i, e in ipairs(list) do
			local cx = n == 1 and 0.5 or (i - 0.5) / n
			local slot = mk("Frame", { Name = "Enemy" .. i, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(cx, 0, 1, -6),
				Size = UDim2.new(n == 1 and 0.5 or 1 / n, -10, 1, -12), ZIndex = 6 }, foe)
			local back = (n == 3 and i == 2) -- the middle one stands further back, like the reference
			local shadow = UI.img(slot, "circle", { name = "Shadow", slice = false, anchor = Vector2.new(0.5, 0.5), pos = UDim2.new(0.5, 0, 1, back and -30 or -6), sz = UDim2.new(0.55, 0, 0, 16), color = C.black, alpha = 0.5, z = 6 })
			local fig = UI.img(slot, e.img or "enemy_guard", { button = true, name = "Figure", slice = false, fit = true, anchor = Vector2.new(0.5, 1),
				pos = UDim2.new(0.5, 0, 1, back and -26 or 0), sz = back and UDim2.new(0.85, 0, 1, -96) or UDim2.new(1, 0, 1, -62), z = 7 })
			local figScale = hover(fig, 0.04)
			local plate = mk("Frame", { Name = "Plate", BackgroundColor3 = C.black, BackgroundTransparency = 0.15, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, back and 0 or 8), Size = UDim2.new(1, -4, 0, 50), ZIndex = 8 }, slot)
			mk("UISizeConstraint", { MaxSize = Vector2.new(210, 50) }, plate)
			local stroke = mk("UIStroke", { Color = C.rule, Thickness = 1 }, plate)
			local name = text(plate, e.name or "", { font = "heavy", size = 15, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(6, 3), sz = UDim2.new(1, -12, 0, 18), z = 9, scaled = true })
			local bar = hpBar(UI, plate, { pos = UDim2.fromOffset(6, 24), sz = UDim2.new(1, -12, 0, 22), z = 9, color = C.bad, textSize = 13 })
			local skull = UI.icon(slot, "icon_bosses", 60, C.bad, UDim2.new(0.5, 0, 0.62, 0), { z = 9, anchor = Vector2.new(0.5, 0.5), name = "Skull" })
			skull.Visible = false
			local skullScale = mk("UIScale", {}, skull)
			local ev = { slot = slot, fig = fig, figScale = figScale, plate = plate, stroke = stroke, name = name, bar = bar, skull = skull, skullScale = skullScale, shadow = shadow, alive = true, home = fig.Position }
			enemyViews[i] = ev
			fig.Activated:Connect(function()
				if not ev.alive then return end
				sel = i
				updateSel()
				tw(figScale, 0.08, { Scale = 1.08 }).Completed:Connect(function() tw(figScale, 0.15, { Scale = 1.04 }, Enum.EasingStyle.Back) end)
			end)
		end
	end

	local function setEnemy(ev, e, animate)
		local alive = (e.hp or 0) > 0
		ev.bar:Set((e.hp or 0) / math.max(1, e.max or 1), R.Commas(e.hp or 0) .. " / " .. R.Commas(e.max or 0), animate)
		if alive ~= ev.alive or not ev.init then
			ev.init = true
			ev.alive = alive
			ev.plate.Visible = alive
			ev.skull.Visible = not alive
			ev.fig.Active = alive
			if alive then
				ev.fig.ImageColor3 = C.white; ev.fig.ImageTransparency = 0
			elseif animate then
				tw(ev.fig, 0.6, { ImageColor3 = DEAD_TINT, ImageTransparency = 0.3 })
				ev.skullScale.Scale = 0.2
				tw(ev.skullScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
			else
				ev.fig.ImageColor3 = DEAD_TINT; ev.fig.ImageTransparency = 0.3
			end
		end
	end

	-------------------------------------------------- stage boxes
	local stageRow = mk("Frame", { Name = "Stages", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 56), ZIndex = 5 }, root)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, stageRow)
	local stageBoxes = {}
	for s = 1, 5 do
		local b = mk("Frame", { Name = "Stage" .. s, BackgroundColor3 = Color3.fromHex("3a1d1d"), BorderSizePixel = 0, Size = UDim2.new(0.2, -7, 1, 0), ZIndex = 6, LayoutOrder = s, ClipsDescendants = true }, stageRow)
		local st = mk("UIStroke", { Color = Color3.fromHex("5a2a2a"), Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, b)
		local fill = mk("Frame", { Name = "Fill", BackgroundColor3 = C.bad, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1), ZIndex = 6, Visible = false }, b)
		local lab = text(b, "STAGE " .. s, { font = "bold", size = 12, color = C.manila, pos = UDim2.fromOffset(10, 6), sz = UDim2.new(0.5, -10, 0, 16), z = 7 })
		local hp = text(b, "", { font = "bold", size = 12, color = C.white, pos = UDim2.new(0.4, 0, 0, 6), sz = UDim2.new(0.6, -8, 0, 16), z = 7, align = Enum.TextXAlignment.Right, scaled = true })
		local nm = text(b, "", { font = "heavy", size = 15, pos = UDim2.fromOffset(10, 24), sz = UDim2.new(1, -38, 0, 22), z = 7, scaled = true })
		local chk = UI.icon(b, "icon_check", 22, C.good, UDim2.new(1, -8, 0.5, 6), { z = 7, anchor = Vector2.new(1, 0.5) })
		stageBoxes[s] = { box = b, stroke = st, fill = fill, label = lab, hp = hp, name = nm, check = chk }
	end

	-------------------------------------------------- apply a view
	local function noAttacks(v) return (v.free or 0) <= 0 and (v.tickets or 0) <= 0 end
	local function claimable(v) return (v.cleared or 0) > (v.claimed or 0) and (v.myDmg or 0) > 0 end

	local function apply(v, animate)
		if type(v) ~= "table" then return end
		local prev = view
		view, viewClock = v, os.clock()
		local tgt = v.target or { name = "", stages = {} }
		title.Text = "Weekly Takedown: " .. (tgt.name or "")
		-- stat boxes
		freeVal.Text = (v.free or 0) .. " / " .. (v.freeMax or 10)
		for i, p in ipairs(pips) do
			local on = i <= (v.free or 0)
			p.Visible = i <= (v.freeMax or 10)
			p.BackgroundColor3 = on and C.gold or C.rule
		end
		ticketVal.Text = R.Commas(v.tickets or 0)
		countUp(dmgVal, animate and prev and prev.myDmg or nil, v.myDmg or 0, R.Commas)
		rankNote.Text = v.myRank and ("#" .. v.myRank .. " in your alliance") or "Attack to get ranked"
		rewardDot.Visible = claimable(v)
		-- stage boxes
		local stage, cleared = v.stage or 1, v.cleared or 0
		for s, b in ipairs(stageBoxes) do
			b.name.Text = (tgt.stages and tgt.stages[s]) or ("Stage " .. s)
			local done = s <= cleared
			local cur = s == stage and stage <= 5
			b.check.Visible = done
			b.fill.Visible = cur
			b.hp.Visible = cur
			b.box.BackgroundColor3 = done and Color3.fromHex("2b3a26") or (cur and C.black or Color3.fromHex("3a1d1d"))
			b.stroke.Color = cur and C.gold or (done and Color3.fromHex("4f6b45") or Color3.fromHex("5a2a2a"))
			b.stroke.Thickness = cur and 2 or 1
			b.name.TextColor3 = (cur or done) and C.ink or C.muted
			if cur then
				local frac = v.stageMax and v.stageMax > 0 and (v.stageHp or 0) / v.stageMax or 1
				local size = UDim2.fromScale(frac, 1)
				if animate then tw(b.fill, 0.4, { Size = size }) else b.fill.Size = size end
				b.hp.Text = v.stageMax and (R.Commas(v.stageHp or 0) .. " / " .. R.Commas(v.stageMax)) or ""
			end
		end
		if animate and prev and (v.cleared or 0) > (prev.cleared or 0) then
			App.toast("STAGE " .. v.cleared .. " CLEARED", ((tgt.stages and tgt.stages[v.cleared]) or "") .. " has fallen. Claim your reward!", "gold")
		end
		-- enemies
		if v.enemies and #v.enemies > 0 then
			banner.Visible = false
			local key = stage .. ":" .. #v.enemies .. ":" .. (v.week or 0)
			if key ~= enemyKey then
				enemyKey = key
				buildEnemies(v.enemies)
				sel = 1
				animate = false
			end
			for i, e in ipairs(v.enemies) do if enemyViews[i] then setEnemy(enemyViews[i], e, animate) end end
			if not enemyViews[sel] or not enemyViews[sel].alive then
				for i, ev in ipairs(enemyViews) do if ev.alive then sel = i; break end end
			end
			updateSel()
		else
			enemyKey = nil
			UI.clear(foe)
			enemyViews = {}
			banner.Visible = true
			if stage > 5 then
				bannerTitle.Text = "STRONGHOLD TAKEN!"
				bannerBody.Text = "Your alliance cleared all 5 stages this week. Claim your rewards. A new stronghold arrives in " .. dhm(v.endsIn or 0) .. "."
			else
				bannerTitle.Text = string.upper(tgt.name or "THE STRONGHOLD")
				bannerBody.Text = "Nobody in your alliance has struck yet this week. Hit ATTACK to lead the charge!"
			end
		end
		-- attack button
		if stage > 5 then attackBtn:Set("locked", "CLEARED")
		elseif noAttacks(v) then attackBtn:Set("gold", "GET TICKETS")
		elseif (v.free or 0) <= 0 then attackBtn:Set("red", "ATTACK · TICKET")
		else attackBtn:Set("red", "ATTACK") end
		atkPulse.Thickness = (stage <= 5 and not noAttacks(v)) and 2 or 0
	end

	local function poll()
		if polling then return end
		polling = true
		lastPoll = os.clock()
		task.spawn(function()
			local res = req(App, "tdView", {}, nil, true)
			polling = false
			if res.ok and res.view and root.Parent then apply(res.view, view ~= nil) end
		end)
	end

	-------------------------------------------------- attack feedback
	local function hitFx(e, dmg, big)
		local ev = enemyViews[e]
		if not ev then return end
		-- your portrait lunges
		avatarScale.Scale = 1
		tw(avatarScale, 0.07, { Scale = 1.07 }).Completed:Connect(function() tw(avatarScale, 0.2, { Scale = 1 }, Enum.EasingStyle.Back) end)
		-- the enemy shakes and flashes red
		local home = ev.home
		task.spawn(function()
			for _, dx in ipairs({ 9, -8, 6, -4, 2, 0 }) do
				if not ev.fig.Parent then return end
				ev.fig.Position = home + UDim2.fromOffset(dx, 0)
				task.wait(0.03)
			end
			ev.fig.Position = home
		end)
		if ev.alive then
			ev.fig.ImageColor3 = Color3.fromRGB(255, 90, 80)
			tw(ev.fig, 0.35, { ImageColor3 = C.white })
		end
		-- floating number
		local fit = App.root:FindFirstChild("Fit")
		local k = fit and fit.Scale or 1
		local at = (ev.slot.AbsolutePosition + ev.slot.AbsoluteSize * Vector2.new(0.5, 0.42) - scene.AbsolutePosition) / k
		local l = text(scene, (big and "<font size='18' color='#e2695f'>BIG HIT!</font>\n" or "") .. "-" .. R.Commas(dmg or 0), {
			font = "heavy", size = big and 34 or 26, color = big and C.gold or C.bad, rich = true, align = Enum.TextXAlignment.Center,
			anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromOffset(at.X + math.random(-20, 20), at.Y), sz = UDim2.fromOffset(200, big and 70 or 36), z = 12, stroke = 2 })
		local sc = mk("UIScale", { Scale = 0.4 }, l)
		tw(sc, 0.25, { Scale = big and 1.25 or 1 }, Enum.EasingStyle.Back)
		task.delay(0.35, function()
			if not l.Parent then return end
			tw(l, 0.8, { Position = l.Position - UDim2.fromOffset(0, 70), TextTransparency = 1 })
			local st = l:FindFirstChildOfClass("UIStroke")
			if st then tw(st, 0.8, { Transparency = 1 }) end
		end)
		task.delay(1.3, function() if l.Parent then l:Destroy() end end)
	end

	attack = function()
		if busy then return end
		if not view then poll(); return end
		if (view.stage or 1) > 5 then App.toast("Stronghold taken", "Your alliance cleared every stage this week. Claim your rewards!", "gold"); return end
		if noAttacks(view) then App.open("tasks"); return end
		local e = sel
		if view.enemies then
			local en = view.enemies[e]
			if not en or (en.hp or 0) <= 0 then
				for i, x in ipairs(view.enemies) do if (x.hp or 0) > 0 then e = i; break end end
			end
		end
		busy = true
		local res = req(App, "tdAttack", { e = e }, attackBtn)
		busy = false
		if res.ok then
			hitFx(e, res.dmg, res.big)
			if res.ticket then App.float(attackBtn.Inst, "-1 TICKET", C.gold) end
			lastPoll = os.clock()
			local nv = res.view
			if nv and view and (nv.stage or 1) ~= (view.stage or 1) and enemyViews[e] then
				local old = view.enemies and view.enemies[e]
				if old then setEnemy(enemyViews[e], { hp = 0, max = old.max }, true) end
				busy = true
				task.delay(0.9, function() busy = false; apply(nv, true) end)
			elseif nv then apply(nv, true) else poll() end
		elseif res.msg == "no_attacks" then
			App.shake(attackBtn.Inst)
			local wait = (view.nextFree or 0) - (os.clock() - viewClock)
			App.toast("OUT OF ATTACKS", "Next free attack in " .. dhm(wait) .. ". Takedown Tickets are in the Seals shop (Tasks).", "bad")
			poll()
		end
	end

	-------------------------------------------------- popups
	openRewards = function()
		local v = view or {}
		local tgt = v.target or { stages = {} }
		local _, bd, close = popup(App, "TAKEDOWN REWARDS", 560, 470)
		text(bd, "Every member who attacked at least once this week earns each cleared stage's reward.", { size = 14, color = C.muted, wrap = true, sz = UDim2.new(1, -40, 0, 36), z = 74 })
		local list = UI.list(bd, { pos = UDim2.fromOffset(0, 42), sz = UDim2.new(1, 0, 1, -42 - 58), gap = 6, z = 73 })
		for s, rw in ipairs(TD_REWARDS) do
			local done = s <= (v.cleared or 0)
			local got = s <= (v.claimed or 0)
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 54), z = 74, order = s, hot = done and not got })
			text(card, "STAGE " .. s, { font = "bold", size = 12, color = C.manila, pos = UDim2.fromOffset(12, 6), sz = UDim2.new(0.4, -12, 0, 16), z = 75 })
			text(card, (tgt.stages and tgt.stages[s]) or "", { font = "heavy", size = 15, pos = UDim2.fromOffset(12, 24), sz = UDim2.new(0.38, -12, 0, 22), z = 75, scaled = true })
			local rew = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.38, 0, 0, 0), Size = UDim2.new(0.42, 0, 1, 0), ZIndex = 75 }, card)
			mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, rew)
			UI.chip(rew, rw.seals .. " Seals", { icon = "icon_seal", color = C.gold, z = 76, order = 1, h = 26 })
			if rw.basic then
				local c = UI.img(rew, "crate_basic", { slice = false, fit = true, sz = UDim2.fromOffset(32, 32), z = 76, order = 2 })
				c.ScaleType = Enum.ScaleType.Fit
				text(rew, (rw.basic > 1 and (rw.basic .. "x ") or "") .. "Supply Crate", { font = "bold", size = 13, sz = UDim2.fromOffset(96, 20), z = 76, order = 3, scaled = true })
			end
			if rw.limited then
				local c = UI.img(rew, "crate_limited", { slice = false, fit = true, sz = UDim2.fromOffset(32, 32), z = 76, order = 2 })
				c.ScaleType = Enum.ScaleType.Fit
				text(rew, "Founder's Crate", { font = "bold", size = 13, color = C.gold, sz = UDim2.fromOffset(96, 20), z = 76, order = 3, scaled = true })
			end
			local status, color = "LOCKED", C.dim
			if got then status, color = "CLAIMED", C.good elseif done then status, color = "READY", C.gold elseif s == (v.stage or 1) then status, color = "IN PROGRESS", C.bad end
			text(card, status, { font = "heavy", size = 14, color = color, anchor = Vector2.new(1, 0.5), pos = UDim2.new(1, -12, 0.5, 0), sz = UDim2.new(0.2, -12, 0, 20), z = 75, align = Enum.TextXAlignment.Right, scaled = true })
		end
		local can = claimable(v)
		UI.button(bd, can and "green" or "locked", can and "CLAIM REWARDS" or "NOTHING TO CLAIM", function(btn)
			local res = req(App, "tdClaim", {}, btn)
			if res.ok then
				local r = res.reward or {}
				local bits = { "+" .. (r.seals or 0) .. " Seals" }
				if (r.basicCrates or 0) > 0 then table.insert(bits, "+" .. r.basicCrates .. " Supply Crate" .. (r.basicCrates > 1 and "s" or "")) end
				if (r.limitedCrates or 0) > 0 then table.insert(bits, "+" .. r.limitedCrates .. " Founder's Crate") end
				App.toast("TAKEDOWN REWARDS CLAIMED", table.concat(bits, " · "), "gold")
				close()
				poll()
			end
		end, { sz = UDim2.fromOffset(240, 46), anchor = Vector2.new(0.5, 1), pos = UDim2.new(0.5, 0, 1, 0), z = 75, icon = "icon_gift" })
	end

	openBoard = function()
		local v = view or {}
		local _, bd = popup(App, "LEADERBOARD", 520, 480)
		text(bd, "Damage dealt by your alliance members this week.", { size = 14, color = C.muted, sz = UDim2.new(1, -40, 0, 20), z = 74 })
		local list = UI.list(bd, { pos = UDim2.fromOffset(0, 28), sz = UDim2.new(1, 0, 1, -28), gap = 6, z = 73 })
		local board = v.board or {}
		if #board == 0 then
			text(list, "No attacks yet this week. Be the first!", { size = 16, color = C.muted, align = Enum.TextXAlignment.Center, sz = UDim2.new(1, 0, 0, 60), z = 74 })
		end
		local top = board[1] and board[1].dmg or 1
		local me = tostring(LP.UserId)
		for i, b in ipairs(board) do
			local mine = tostring(b.uid) == me
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 48), z = 74, order = i, hot = mine })
			if i <= 3 then
				UI.img(card, ({ "medal_gold", "medal_silver", "medal_bronze" })[i], { slice = false, fit = true, sz = UDim2.fromOffset(34, 34), pos = UDim2.fromOffset(10, 7), z = 75 })
			else
				text(card, "#" .. i, { font = "heavy", size = 16, color = C.muted, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(6, 0), sz = UDim2.new(0, 42, 1, 0), z = 75 })
			end
			text(card, esc(b.name) .. (mine and " <font color='#f0c75a'>(you)</font>" or ""), { font = "heavy", size = 16, rich = true, pos = UDim2.fromOffset(56, 4), sz = UDim2.new(0.6, -56, 0, 22), z = 75, truncate = true })
			local track = mk("Frame", { BackgroundColor3 = C.slate, BorderSizePixel = 0, Position = UDim2.fromOffset(56, 30), Size = UDim2.new(0.6, -56, 0, 6), ZIndex = 75 }, card)
			mk("Frame", { BackgroundColor3 = C.bad, BorderSizePixel = 0, Size = UDim2.fromScale(math.clamp(b.dmg / math.max(1, top), 0, 1), 1), ZIndex = 76 }, track)
			text(card, R.Commas(b.dmg or 0), { font = "heavy", size = 18, color = C.gold, anchor = Vector2.new(1, 0.5), pos = UDim2.new(1, -14, 0.5, 0), sz = UDim2.new(0.4, -20, 0, 24), z = 75, align = Enum.TextXAlignment.Right })
		end
	end

	openLog = function()
		local v = view or {}
		local _, bd = popup(App, "RECENT ATTACKS", 620, 500)
		text(bd, "The last 50 attacks by your alliance this week.", { size = 14, color = C.muted, sz = UDim2.new(1, -40, 0, 20), z = 74 })
		local list = UI.list(bd, { pos = UDim2.fromOffset(0, 28), sz = UDim2.new(1, 0, 1, -28), gap = 4, z = 73 })
		local log = v.log or {}
		if #log == 0 then
			text(list, "No attacks yet this week.", { size = 16, color = C.muted, align = Enum.TextXAlignment.Center, sz = UDim2.new(1, 0, 0, 60), z = 74 })
		end
		for i, h in ipairs(log) do
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 40), z = 74, order = i })
			text(card, ago(App, h.t), { size = 13, color = C.muted, pos = UDim2.fromOffset(12, 0), sz = UDim2.new(0, 64, 1, 0), z = 75 })
			text(card, "<b>" .. esc(h.who) .. "</b> hit the " .. esc(h.e) .. " for <font color='#f0c75a'>" .. R.Commas(h.dmg or 0) .. "</font>" .. (h.big and " <font color='#e2695f'><b>BIG HIT</b></font>" or ""),
				{ size = 15, rich = true, pos = UDim2.fromOffset(80, 0), sz = UDim2.new(1, -92, 1, 0), z = 75, truncate = true })
		end
	end

	-------------------------------------------------- screen hooks
	function obj:Refresh(st)
		local has = st and st.alliance ~= nil
		root.Visible = has
		empty.Visible = not has
		if not has then return end
		youAtk.Text = "ATK " .. R.Short(st.atk or 0)
		if not view then poll() end
	end
	function obj:Opened() lastPoll = 0 end
	function obj:Tick(st)
		if not (st and st.alliance) then
			if root.Visible then obj:Refresh(st) end
			return
		end
		if not root.Visible then obj:Refresh(st) end
		if os.clock() - lastPoll > 5 and not busy then poll() end
		if not view then return end
		local since = os.clock() - viewClock
		ends.Text = "New Takedown in " .. dhm((view.endsIn or 0) - since)
		if (view.free or 0) < (view.freeMax or 10) then
			local left = (view.nextFree or 0) - since
			freeNext.Text = "+1 in " .. dhm(left)
			if left <= 0 and os.clock() - lastPoll > 1.5 then poll() end
		else
			freeNext.Text = "FULL"
		end
		-- gentle pulse on the ATTACK outline
		if atkPulse.Thickness > 0 then atkPulse.Transparency = 0.35 + 0.35 * math.sin(os.clock() * 4) end
	end
	return obj
end }

---------------------------------------------------------------- RAIDS
S.battle = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local RC = Config.Raid or { Supply = 2, StealPct = 0.1, CapLawMinutes = 60, Cooldown = 60 }
	local SPY_SUPPLY = (Config.Raid and Config.Raid.SpySupply) or 1
	local revengeProd = Config.Products and Config.Products.RevengeStrike
	local revengePrice = revengeProd and revengeProd.robux or 49
	local obj = {}
	local rows = {}
	local refreshedAt = os.clock()

	local panel, body = UI.panel(host, "RAIDS", { sz = UDim2.new(1, -20, 1, -20), pos = UDim2.fromOffset(10, 10), z = 5, titleSize = 26 })
	local chips = mk("Frame", { Name = "Chips", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -18, 0, 14), Size = UDim2.new(1, -150, 0, 26), ZIndex = 7 }, panel)
	mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, chips)

	infoButton(App, body, "HOW RAIDS WORK",
		"You can raid the other nations in <b>this server</b> plus <b>3 AI nations</b>. The list is fixed: it cannot be refreshed.\n\n" ..
		"Their defense and cash are <b>hidden</b>. <font color='#7fb0e6'><b>SPY</b></font> (" .. SPY_SUPPLY .. " Supply) to see them for 15 minutes. They are told you spied.\n\n" ..
		"Win and you take <font color='#8fd07a'><b>10% of their cash on hand</b></font>, up to about 1 hour of their law income. Banked cash is safe.\n\n" ..
		"The same nation can be raided again after <b>1 minute</b>. <font color='#e2695f'><b>Soldiers die on both sides</b></font>, cheapest first.",
		UDim2.fromOffset(0, 5), 8)
	text(body, "Raid nations in your server and 3 AI nations. SPY first to see their defense and cash. Win to steal 10% of their cash on hand.",
		{ size = 14, color = C.muted, wrap = true, pos = UDim2.fromOffset(34, 0), sz = UDim2.new(1, -34, 0, 36), z = 7, valign = Enum.TextYAlignment.Center })

	local revengeHost = mk("Frame", { Name = "Revenge", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, 68), ZIndex = 6, Visible = false }, body)
	local list = UI.list(body, { pos = UDim2.fromOffset(0, 44), sz = UDim2.new(1, 0, 1, -44), gap = 8, z = 6 })

	-------------------------------------------------- revenge banner
	local function drawRevenge(st)
		UI.clear(revengeHost)
		local rv = st.revenge
		local show = type(rv) == "table" and rv.id and rv.t ~= raidState.dismissed
		revengeHost.Visible = show and true or false
		list.Position = UDim2.fromOffset(0, show and 120 or 44)
		list.Size = UDim2.new(1, 0, 1, show and -120 or -44)
		if not show then return end
		local card = UI.card(revengeHost, { sz = UDim2.fromScale(1, 1), z = 7, hot = true })
		mk("UIStroke", { Color = C.bad, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
		UI.icon(card, "icon_flame", 30, C.bad, UDim2.new(0, 14, 0.5, 0), { z = 8, anchor = Vector2.new(0, 0.5) })
		text(card, "REVENGE", { font = "display", size = 20, color = C.bad, pos = UDim2.fromOffset(54, 6), sz = UDim2.new(1, -440, 0, 24), z = 8 })
		text(card, "<b>" .. esc(rv.name) .. "</b> raided you " .. ago(App, rv.t) .. ". Hit back!", { size = 15, rich = true, pos = UDim2.fromOffset(54, 34), sz = UDim2.new(1, -440, 0, 22), z = 8, truncate = true })
		UI.button(card, "red", "RAID BACK", function(btn) raidTarget(App, rv.id, rv.name, btn) end,
			{ sz = UDim2.fromOffset(140, 46), anchor = Vector2.new(1, 0.5), pos = UDim2.new(1, -262, 0.5, 0), z = 9, icon = "icon_attack", textSize = 15 })
		UI.button(card, "gold", "REVENGE STRIKE · " .. revengePrice .. " R$", function(btn)
			App.req("revengeStrike", { id = rv.id }, btn)
		end, { sz = UDim2.fromOffset(206, 46), anchor = Vector2.new(1, 0.5), pos = UDim2.new(1, -50, 0.5, 0), z = 9, icon = "icon_crosshair", textSize = 14 })
		local x = UI.img(card, "btn_slate", { button = true, name = "Dismiss", sz = UDim2.fromOffset(30, 30), anchor = Vector2.new(1, 0.5), pos = UDim2.new(1, -10, 0.5, 0), z = 9 })
		UI.icon(x, "icon_x", 14, C.ink, UDim2.new(0.5, 0, 0.5, -1), { z = 10, anchor = Vector2.new(0.5, 0.5) })
		x.Activated:Connect(function() raidState.dismissed = rv.t; drawRevenge(App.state or st) end)
		FX.popIn(card, 0.9, 0.25)
	end

	-------------------------------------------------- target rows
	-- what we know about a target: the server's numbers once spied (intel = true), else what our own SPY returned
	local function known(t)
		if t.intel and t.def ~= nil then
			return { def = t.def, cash = t.cash, left = INTEL_SECONDS - (t.spiedAgo or 0), at = refreshedAt }
		end
		local c = raidState.intel[t.id]
		if c and os.clock() - c.at < INTEL_SECONDS then
			return { def = c.v.def, cash = c.v.cash, left = INTEL_SECONDS, at = c.at }
		end
		return nil
	end
	local function lootFor(st, t, cash)
		local mods = st.mods or {}
		local cap = R.MinuteValue(t.lv or 1) * (RC.CapLawMinutes or 60)
		local v = math.min((cash or 0) * (RC.StealPct or 0.1) * (1 + (mods.loot or 0)), cap)
		return math.max(0, math.floor(math.min(v, cash or 0)))
	end

	local function setRowButton(r, st)
		local since = os.clock() - refreshedAt
		local sh = (r.t.shield or 0) - since
		local cd = (r.t.cooldown or 0) - since
		if sh > 0 then
			r.btn:Set("locked", "SHIELD " .. dhm(sh))
		elseif cd > 0 then
			r.btn:Set("locked", "RAIDED · " .. R.Clock(cd))
		else
			r.btn:Set(((st and st.sup or 0) >= (RC.Supply or 2)) and "red" or "locked", "RAID")
		end
		local k = known(r.t)
		if k then
			local left = k.left - (os.clock() - k.at)
			if left > 0 then r.spy:Set("locked", "INTEL " .. math.max(1, math.ceil(left / 60)) .. "m") else r.spy:Set("blue", "SPY") end
		else
			r.spy:Set(((st and st.sup or 0) >= SPY_SUPPLY) and "blue" or "locked", "SPY")
		end
	end

	-- write the (known or hidden) numbers into a row; reveal = play the little reveal animation
	local function fillRow(r, st, reveal)
		local k = known(r.t)
		local L = r.labels
		if k then
			local chance = M.WinChance(st.atk or 0, k.def or 0)
			local ccol = chance >= 0.7 and "#8fd07a" or (chance >= 0.45 and "#f0c75a" or "#e2695f")
			L.def.Text = R.Short(k.def or 0)
			L.def.TextColor3 = C.blue
			L.chance.Text = "<font color='" .. ccol .. "'><b>" .. math.floor(chance * 100 + 0.5) .. "%</b></font> to win"
			L.cash.Text = R.Money(k.cash or 0)
			L.cash.TextColor3 = C.ink
			L.loot.Text = "Loot ≈ <b>" .. R.Money(lootFor(st, r.t, k.cash)) .. "</b>"
		else
			L.def.Text = "???"
			L.def.TextColor3 = C.dim
			L.chance.Text = "Spy to see your odds"
			L.cash.Text = "???"
			L.cash.TextColor3 = C.dim
			L.loot.Text = "Loot ≈ <b>???</b>"
		end
		if reveal and k then
			for _, l in ipairs({ L.def, L.cash }) do
				local sc = l:FindFirstChildOfClass("UIScale") or mk("UIScale", {}, l)
				sc.Scale = 0.3
				tw(sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
				local c0 = l.TextColor3
				l.TextColor3 = C.gold
				tw(l, 0.8, { TextColor3 = c0 })
			end
			for _, l in ipairs({ L.chance, L.loot }) do
				l.TextTransparency = 1
				tw(l, 0.4, { TextTransparency = 0 })
			end
			r.flash.BackgroundTransparency = 0.75
			tw(r.flash, 0.6, { BackgroundTransparency = 1 })
		end
	end

	local function spy(r, btn)
		local st = App.state
		if known(r.t) then App.toast("You already have fresh intel on " .. tostring(r.t.name), "Intel lasts 15 minutes", "info"); return end
		if (st and st.sup or 0) < SPY_SUPPLY then App.toast("Not enough Supply", "Spying costs " .. SPY_SUPPLY .. " Supply", "bad"); App.shake(btn.Inst); return end
		local res = req(App, "spy", { id = r.t.id }, btn)
		if not res.ok or type(res.intel) ~= "table" then return end
		raidState.intel[r.t.id] = { v = res.intel, at = os.clock() }
		App.float(btn.Inst, "-" .. SPY_SUPPLY .. " SUPPLY", C.sup)
		if r.card.Parent then
			fillRow(r, App.state or st, true)
			setRowButton(r, App.state or st)
		end
	end

	function obj:Refresh(st)
		if not st then return end
		refreshedAt = os.clock()
		UI.clear(chips)
		UI.chip(chips, "ATK " .. R.Short(st.atk or 0), { icon = "icon_attack", color = C.bad, z = 8, order = 1 })
		UI.chip(chips, "DEF " .. R.Short(st.def or 0), { icon = "icon_defense", color = C.blue, z = 8, order = 2 })
		UI.chip(chips, "SUPPLY " .. (st.sup or 0) .. "/" .. (st.supMax or 0) .. " · " .. (RC.Supply or 2) .. " per raid", { icon = "icon_supply", color = C.sup, z = 8, order = 3 })
		drawRevenge(st)

		local pos = list.CanvasPosition
		UI.clear(list)
		rows = {}
		local targets = st.targets or {}
		if #targets == 0 then
			text(list, "No nations to raid right now.", { size = 16, color = C.muted, align = Enum.TextXAlignment.Center, sz = UDim2.new(1, 0, 0, 60), z = 7 })
			return
		end
		for i, t in ipairs(targets) do
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 78), z = 7, order = i })
			local flash = mk("Frame", { Name = "Flash", BackgroundColor3 = C.blue, BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), ZIndex = 7 }, card)
			mk("UICorner", { CornerRadius = UDim.new(0, 6) }, flash)
			UI.flag(card, t.flag, 54, { pos = UDim2.new(0, 14, 0.5, 0), anchor = Vector2.new(0, 0.5), z = 8 })
			text(card, t.name or "?", { font = "display", size = 19, pos = UDim2.fromOffset(80, 10), sz = UDim2.new(0.3, -80, 0, 24), z = 8, truncate = true })
			local tags = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(80, 40), Size = UDim2.new(0.3, -80, 0, 22), ZIndex = 8 }, card)
			mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tags)
			UI.chip(tags, "LV " .. (t.lv or 1), { manila = true, h = 22, size = 13, z = 9, order = 1 })
			if t.ai then UI.chip(tags, "AI", { icon = "icon_bot", color = C.blue, h = 22, size = 12, z = 9, order = 2 }) end
			if t.tag then UI.chip(tags, "[" .. tostring(t.tag) .. "]", { color = C.gold, h = 22, size = 12, z = 9, order = 3 }) end

			text(card, "DEFENSE", { font = "bold", size = 12, color = C.muted, pos = UDim2.new(0.3, 0, 0, 10), sz = UDim2.new(0.18, -8, 0, 16), z = 8 })
			UI.icon(card, "icon_defense", 16, C.blue, UDim2.new(0.3, 0, 0, 30), { z = 8 })
			-- value labels are centre-anchored so the reveal pops them from their middle
			local defL = text(card, "???", { font = "heavy", size = 18, color = C.dim, anchor = Vector2.new(0.5, 0.5), pos = UDim2.new(0.39, 7, 0, 38), sz = UDim2.new(0.18, -30, 0, 22), z = 8, scaled = true })
			local chanceL = text(card, "", { size = 13, rich = true, color = C.muted, pos = UDim2.new(0.3, 0, 0, 52), sz = UDim2.new(0.18, -8, 0, 18), z = 8, truncate = true })

			text(card, "CASH ON HAND", { font = "bold", size = 12, color = C.muted, pos = UDim2.new(0.48, 0, 0, 10), sz = UDim2.new(0.52, -276, 0, 16), z = 8, truncate = true })
			local cashL = text(card, "???", { font = "heavy", size = 18, color = C.dim, anchor = Vector2.new(0.5, 0.5), pos = UDim2.new(0.74, -138, 0, 38), sz = UDim2.new(0.52, -276, 0, 22), z = 8, scaled = true })
			local lootL = text(card, "", { size = 13, rich = true, color = C.good, pos = UDim2.new(0.48, 0, 0, 52), sz = UDim2.new(0.52, -276, 0, 18), z = 8, truncate = true })
			defL.TextXAlignment = Enum.TextXAlignment.Left
			cashL.TextXAlignment = Enum.TextXAlignment.Left

			local r = { t = t, card = card, flash = flash, labels = { def = defL, chance = chanceL, cash = cashL, loot = lootL } }
			r.spy = UI.button(card, "blue", "SPY", function(btn) spy(r, btn) end,
				{ sz = UDim2.fromOffset(100, 48), anchor = Vector2.new(1, 0.5), pos = UDim2.new(1, -162, 0.5, 0), z = 9, icon = "icon_satellite", textSize = 15 })
			r.btn = UI.button(card, "red", "RAID", function(btn)
				local since = os.clock() - refreshedAt
				if (t.shield or 0) - since > 0 then App.toast("They are under a raid shield", nil, "bad"); App.shake(btn.Inst); return end
				if (t.cooldown or 0) - since > 0 then App.toast("They were just raided", "Try again in " .. R.Clock((t.cooldown or 0) - since), "bad"); App.shake(btn.Inst); return end
				raidTarget(App, t.id, t.name, btn)
			end, { sz = UDim2.fromOffset(140, 48), anchor = Vector2.new(1, 0.5), pos = UDim2.new(1, -12, 0.5, 0), z = 9, icon = "icon_attack", textSize = 16 })
			rows[i] = r
			fillRow(r, st, false)
			setRowButton(r, st)
		end
		task.defer(function() if list.Parent then list.CanvasPosition = pos end end)
	end
	function obj:Tick(st)
		for _, r in ipairs(rows) do setRowButton(r, st) end
	end
	return obj
end }

return S
