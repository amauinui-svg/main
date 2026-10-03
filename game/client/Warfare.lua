-- Warfare screens: RAIDS (key "battle", replaces the old rival list in War.lua: Kash 1 Oct 2026, raid only players in your server
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
	return UI.infoBtn(parent, pos, function()
		local _, bd = popup(App, title, 460, 260)
		UI.text(bd, body, { size = 16, wrap = true, rich = true, sz = UDim2.fromScale(1, 1), valign = Enum.TextYAlignment.Top, z = 74 })
	end, { z = z or 8, size = 26 }).Inst
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
local DESIGN_W, DESIGN_H = 760, 620 -- the fight screen is laid out at this size and scaled to fit
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
-- a reward chip (the kit's chip plate): icon + big text, sizes to its text
local function rewardPill(UI, parent, icon, color, s, order, z)
	local f, l = UI.chip(parent, s, { name = "Reward", icon = icon, color = color, h = 40, size = 24, order = order, z = z, rich = true })
	l.FontFace = UI.Font.heavy
	return f, l
end

-- "gun" (aims and fires), "fist" (jabs) or "blade" (swords, sabers, spears, halberds: wind up and swing)
local function weaponKind(weapon)
	local ic = string.lower(tostring(weapon and weapon.icon or ""))
	if ic:find("musket") or ic:find("rifle") or ic:find("pistol") or ic:find("gun") then return "gun" end
	if ic == "" or ic:find("fist") then return "fist" end
	return "blade"
end
local KIND_SFX = { gun = "hit_gun", blade = "hit_blade", fist = "hit_punch" }
local function sfx(App, name, opts) if App.sfx then pcall(App.sfx, name, opts) end end
local function music(App, name) if App.music then pcall(App.music, name) end end

-- one side of the FIGHT screen. f = fight.a / fight.d, side = "a" (left, attacks right) or "d" (right)
local CARD_W, CARD_H, PORT = 300, 290, 110
local WEAPON_PX, ART_PX = 78, 512 -- weapon size on the card; source size of the gear_* art (used to mirror it)
local function fighterCard(App, parent, f, side, cx, top, maxHp, range, z)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	f = f or {}
	local o = { side = side, f = f, maxHp = math.max(1, maxHp or 1), range = range or { 0, 0 } }
	local card = UI.card(parent, { name = side == "a" and "Attacker" or "Defender", anchor = Vector2.new(0.5, 0), pos = UDim2.fromOffset(cx, top), sz = UDim2.fromOffset(CARD_W, CARD_H), z = z })
	-- result highlight on the card's own border (hidden until the fight ends)
	o.outline, o.stroke = UI.outline(card, C.rule, 2, { alpha = 1 })
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
	-- the big flag is the fallback for everyone (computer nations, or a player whose thumbnail fails): no "AI" tag
	-- anywhere (Kash 19:24), so a computer nation looks exactly like a player whose headshot did not load
	local bigFlag = UI.flag(portrait, f.flag, PORT - 18, { pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = z + 2 })
	if f.userId and not f.ai then
		local img = mk("ImageLabel", { Name = "Headshot", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z + 3, ScaleType = Enum.ScaleType.Crop, Image = "", Visible = false }, portrait)
		o.img = img
		task.spawn(function()
			local ok, url = pcall(function() return Players:GetUserThumbnailAsync(f.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size180x180) end)
			if ok and type(url) == "string" and url ~= "" and img.Parent then
				img.Image = url
				img.Visible = true
				if bigFlag and bigFlag.Parent then bigFlag.Visible = false end
			end
		end)
	end
	-- hit flash overlay
	o.flash = mk("Frame", { Name = "Flash", BackgroundColor3 = Color3.fromRGB(255, 50, 40), BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = z + 5 }, portrait)
	-- gold level badge (outside the clipped portrait, on the card)
	UI.tag(card, tostring(f.lv or 1), C.gold, { name = "Level", anchor = Vector2.new(1, 1), pos = UDim2.fromOffset(pcx + PORT / 2 + 10, 14 + PORT + 6), sz = UDim2.fromOffset(44, 28),
		z = z + 6, size = 18, textColor = C.manilaInk })
	-- weapon (fists when nothing is equipped), on a soft rarity glow
	local w = f.weapon or { icon = "gear_fists", name = "Fists", rarity = "common" }
	local wkey = (w.icon and UI.asset(w.icon) ~= "") and w.icon or "gear_fists"
	UI.img(card, "glow_soft", { name = "WeaponGlow", color = rarityColor(w.rarity), alpha = 0.55, slice = false, z = z + 1, anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromOffset(wcx, 14 + PORT / 2), sz = UDim2.fromOffset(104, 104) })
	local weapon = UI.img(card, wkey, { name = "Weapon", slice = false, fit = true, z = z + 2, anchor = Vector2.new(0.5, 0.5), pos = UDim2.fromOffset(wcx, 14 + PORT / 2), sz = UDim2.fromOffset(WEAPON_PX, WEAPON_PX) })
	-- all weapon art points up-right; the defender's copy is mirrored so its weapon faces the attacker. Every pose is
	-- written for the attacker and multiplied by dir, which mirrors it exactly for the defender.
	o.dir = side == "a" and 1 or -1
	if side == "d" then
		weapon.ImageRectOffset = Vector2.new(ART_PX, 0)
		weapon.ImageRectSize = Vector2.new(-ART_PX, ART_PX)
		weapon.ScaleType = Enum.ScaleType.Stretch -- square box + square art: same look as Fit, no aspect maths on a negative rect
	end
	o.wrot = -12 * o.dir
	weapon.Rotation = o.wrot
	o.weapon, o.whome = weapon, weapon.Position
	o.wkind = weaponKind(w)
	-- name + tag line
	local nm = (f.name and tostring(f.name) ~= "") and tostring(f.name) or (side == "a" and Players.LocalPlayer.DisplayName or "?")
	text(card, nm, { font = "heavy", size = 21, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(10, 14 + PORT + 8), sz = UDim2.new(1, -20, 0, 24), z = z + 1, truncate = true })
	local tagLine = f.tag and ("[" .. tostring(f.tag) .. "]") or (side == "a" and "ATTACKER" or "DEFENDER")
	text(card, tagLine, { font = "bold", size = 14, color = C.gold, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(10, 14 + PORT + 32), sz = UDim2.new(1, -20, 0, 16), z = z + 1, truncate = true })
	-- power box: attack for the attacker, defense for the defender
	local box = UI.img(card, "inset", { name = "Power", pos = UDim2.fromOffset(20, 182), sz = UDim2.fromOffset(CARD_W - 40, 38), z = z + 1 })
	UI.icon(box, side == "a" and "icon_attack" or "icon_defense", 24, side == "a" and C.bad or C.blue, UDim2.new(0, 12, 0.5, 0), { z = z + 2, anchor = Vector2.new(0, 0.5) })
	text(box, bigNum(f.pow), { font = "heavy", size = 24, color = side == "a" and C.gold or C.ink, pos = UDim2.fromOffset(48, 0), sz = UDim2.new(1, -56, 1, 0), z = z + 2, scaled = true })
	-- HP bar (tweens)
	o.hp = hpBar(UI, card, { pos = UDim2.fromOffset(20, 228), sz = UDim2.fromOffset(CARD_W - 40, 22), z = z + 1, color = C.good, textSize = 13 })
	o.hpNow = o.maxHp
	o.hp:Set(1, bigNum(o.maxHp) .. " / " .. bigNum(o.maxHp), false)
	-- damage range: "min --|-- max" with a marker on each roll
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
	-- battle music while this fight is on screen; back to calm when it goes (DONE, REBUILD, or another popup replacing
	-- it). A newer fight has already bumped fightToken, so it keeps its battle music.
	music(App, "battle")
	sfx(App, "raid_start")
	stage.Destroying:Connect(function() if token == fightToken then music(App, "calm") end end)

	-- the panel is built at DESIGN size and scaled to fit (phones), popping in from the centre
	local fitS = math.min(1, (App.W() - 24) / DESIGN_W, (App.H() - 24) / DESIGN_H)
	local panel = UI.img(stage, "panel_plain", { name = "FightPanel", sz = UDim2.fromOffset(DESIGN_W, DESIGN_H), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 72 })
	UI.outline(panel, C.gold, 2, { alpha = 0.15 })
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

	-------------------------------------------------- weapon animations (Kash 19:19: guns aim and fire, melee swings)
	-- one tween at a time per weapon, so a skip can cancel it and snap the weapon back to rest
	local function wtw(F, t, props, style, dir)
		if F.wtween then F.wtween:Cancel() end
		F.wtween = tw(F.weapon, t, props, style, dir)
		return F.wtween
	end
	local function wrest(F)
		if F.wtween then F.wtween:Cancel(); F.wtween = nil end
		F.weapon.Rotation, F.weapon.Position = F.wrot, F.whome
		for _, x in ipairs(F.card:GetChildren()) do if x.Name == "WeaponFx" then x:Destroy() end end
	end
	-- a short-lived effect image on the striker's card, centred at weapon-relative offset (dx, dy)
	local function weaponFx(F, key, dx, dy, size, color, alpha, rot, life)
		local fx = UI.img(F.card, key, { name = "WeaponFx", slice = false, fit = true, color = color, alpha = alpha or 0, z = F.weapon.ZIndex + 2,
			anchor = Vector2.new(0.5, 0.5), pos = F.whome + UDim2.fromOffset(dx, dy), sz = UDim2.fromOffset(size, size) })
		fx.Rotation = rot or 0
		local sc = mk("UIScale", { Scale = 0.4 }, fx)
		tw(sc, life * 0.35, { Scale = 1.15 }, Enum.EasingStyle.Back)
		task.delay(life * 0.35, function() if fx.Parent then tw(fx, life * 0.65, { ImageTransparency = 1 }) end end)
		task.delay(life + 0.05, function() if fx.Parent then fx:Destroy() end end)
		return fx
	end
	-- plays the striker's weapon move; returns the seconds until the blow lands
	local function swing(F)
		local dir = F.dir
		local function at(px, py) return F.whome + UDim2.fromOffset(px * dir, py or 0) end
		if F.wkind == "gun" then
			-- aim (barrel level with the enemy), fire: recoil back + muzzle up with a flash at the barrel end, then return
			local AIM = 42
			wtw(F, 0.1, { Rotation = AIM * dir, Position = at(4) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			task.delay(0.1, function()
				if finished or not F.weapon.Parent then return end
				-- barrel tip in the unrotated art is ~(0.42, -0.43) of the image from its centre; rotate it by the aim angle
				local th = math.rad(AIM)
				local bx, by = 0.42 * WEAPON_PX, -0.43 * WEAPON_PX
				local mx, my = bx * math.cos(th) - by * math.sin(th), bx * math.sin(th) + by * math.cos(th)
				weaponFx(F, "fx_burst", (mx + 4 + 6) * dir, my, 30, Color3.fromRGB(255, 226, 92), 0, math.random(0, 40), 0.2)
				wtw(F, 0.05, { Rotation = (AIM - 18) * dir, Position = at(-12, -3) }).Completed:Connect(function(state)
					if state ~= Enum.PlaybackState.Completed or finished then return end
					task.delay(0.1, function()
						if finished or not F.weapon.Parent then return end
						wtw(F, 0.3, { Rotation = F.wrot, Position = F.whome }, Enum.EasingStyle.Back)
					end)
				end)
			end)
			return 0.1
		end
		-- melee: wind up (rotate back), then a fast arc through toward the enemy with a faded slash trail, then return
		local fist = F.wkind == "fist"
		wtw(F, 0.12, { Rotation = (fist and -24 or -62) * dir, Position = at(fist and -14 or -8, fist and 0 or 4) }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		task.delay(0.12, function()
			if finished or not F.weapon.Parent then return end
			wtw(F, 0.09, { Rotation = (fist and 0 or 78) * dir, Position = at(fist and 36 or 24, fist and 0 or 6) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			task.delay(0.04, function()
				if finished or not F.weapon.Parent then return end
				weaponFx(F, "fx_slash", (fist and 52 or 46) * dir, fist and 0 or 8, fist and 56 or 92, nil, fist and 0.55 or 0.4, 20 * dir, 0.32)
			end)
			task.delay(0.15, function() -- hold the follow-through a moment, then return
				if finished or not F.weapon.Parent then return end
				wtw(F, 0.28, { Rotation = F.wrot, Position = F.whome }, Enum.EasingStyle.Back)
			end)
		end)
		return 0.17
	end

	-- one blow: the striker's weapon moves, then the card lunges, victim flashes red + shakes, impact art, floating
	-- number, HP drops, range marker slides, and the weapon's sound plays
	local function blow(h)
		local S_, V_ = (h.who == "a") and A or D, (h.who == "a") and D or A
		local dir = h.who == "a" and 1 or -1
		local lead = swing(S_)
		task.delay(lead, function()
			if finished or not S_.card.Parent then return end
			tw(S_.card, 0.09, { Position = S_.home + UDim2.fromOffset(26 * dir, -4) }).Completed:Connect(function()
				if S_.card.Parent and not finished then tw(S_.card, 0.22, { Position = S_.home }, Enum.EasingStyle.Back) end
			end)
			S_:Roll(h.r, h.crit, true)
			sfx(App, KIND_SFX[S_.wkind] or "hit_blade")
			if h.crit then sfx(App, "crit") end
		end)
		task.delay(lead + 0.09, function()
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
			wrest(side)
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
		winner.stroke.Color, winner.stroke.Transparency = C.gold, 0
		loser.stroke.Color, loser.stroke.Transparency = C.bad, 0.2
		if loser.img then tw(loser.img, 0.5, { ImageColor3 = Color3.fromRGB(90, 90, 96) }) end
		tw(loser.weapon, 0.5, { ImageTransparency = 0.5 })
		sfx(App, win and "victory" or "defeat")
		-- bottom area, stacked in fixed design-pixel bands so nothing can overlap (the panel scales as a whole):
		--   cards end 376 · title 384-436 · reward row 446-486 · casualty row 494-534 · buttons 560-606
		local holder = mk("Frame", { Name = "Result", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(DESIGN_W / 2, 410), Size = UDim2.fromOffset(DESIGN_W - 40, 52), ZIndex = 80 }, panel)
		text(holder, win and "VICTORY" or "DEFEAT", { font = "display", size = 50, color = win and C.gold or C.bad, align = Enum.TextXAlignment.Center, sz = UDim2.fromScale(1, 1), z = 81, stroke = 1.5 })
		FX.popIn(holder, 0.4, 0.42)
		-- rewards: two rows of pills (rewards, then casualties); a row whose pills grow wider than the panel
		-- (huge numbers) shrinks to fit instead of spilling out
		local function pillRow(y)
			local r = mk("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(DESIGN_W / 2, y), Size = UDim2.fromOffset(DESIGN_W - 40, 40), ZIndex = 80 }, panel)
			local lay = mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, r)
			local fit = mk("UIScale", { Name = "Fit", Scale = 1 }, r)
			local function refit()
				-- both sizes include every UIScale above, so their ratio is the true fit
				local cw, rw = lay.AbsoluteContentSize.X, r.AbsoluteSize.X
				if cw <= 0 or rw <= 0 then return end
				local s = math.clamp(rw / cw, 0.5, 1)
				if math.abs(s - fit.Scale) > 0.01 then fit.Scale = s end
			end
			lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refit)
			task.defer(refit)
			return r
		end
		local r1, r2 = pillRow(446), pillRow(494)
		if win then
			local _, cashL = rewardPill(UI, r1, "icon_cash", C.good, "+$0", 1, 81)
			countUp(cashL, 0, res.cash or 0, function(n) return "+" .. R.Money(n) end, 0.9)
			rewardPill(UI, r1, "icon_xp", C.xp, "+" .. R.Commas(res.xp or 0) .. " XP", 2, 81)
		else
			rewardPill(UI, r1, "icon_defense", C.muted, "Their defense held", 1, 81)
		end
		rewardPill(UI, r2, "icon_military", C.bad, R.Commas(res.lostN or 0) .. ((res.lostN == 1) and " soldier lost" or " soldiers lost"), 1, 81)
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
	local band = UI.card(bd, { name = "Banner", hot = win, sz = UDim2.new(1, -40, 0, 74), z = 74 })
	UI.outline(band, win and C.good or C.bad, 2)
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

---------------------------------------------------------------- RAIDED + SPIED notes (ClientMain calls App.raidedPopup / App.spiedNote)
-- Kash 2 Oct: "this popup should be smaller, it shouldn't take up your screen because players will most likely be
-- attacked often". Both are compact cards that slide in at the top right below the HUD and never block the screen.
local noteHost
local function getNoteHost(App)
	if noteHost and noteHost.Parent then return noteHost end
	local mk = App.UI.mk
	noteHost = mk("Frame", { Name = "Notes", BackgroundTransparency = 1, Active = false, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, (App.TOP or 64) + 12),
		Size = UDim2.fromOffset(340, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 82 }, App.root)
	mk("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, noteHost)
	return noteHost
end

local RAIDED_MAX, RAIDED_SECONDS = 3, 8
local raidedLive = {} -- oldest first: { dismiss = fn }
local function raidedPopup(App, n)
	if type(n) ~= "table" then return end
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local name = tostring(n.by or "Someone")
	local lost = n.win -- the attacker won: you lost cash
	local accent = lost and C.bad or C.good
	-- at most 3 on screen: a new one replaces the oldest
	while #raidedLive >= RAIDED_MAX do
		local old = table.remove(raidedLive, 1)
		old.dismiss(true)
	end
	local host = getNoteHost(App)
	-- the layout positions the cell (no input); the card inside slides in from the right
	local cell = mk("Frame", { Name = "Raided", BackgroundTransparency = 1, Active = false, Size = UDim2.fromOffset(340, 96), ZIndex = 82, LayoutOrder = math.floor(os.clock() * 10) }, host)
	local card = UI.img(cell, "panel_plain", { name = "Card", sz = UDim2.fromScale(1, 1), pos = UDim2.fromOffset(360, 0), z = 83 })
	UI.outline(card, accent, 2, { alpha = 0.25 })
	local em = mk("Frame", { BackgroundColor3 = Color3.fromHex("10141a"), BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 18, 0, 30), Size = UDim2.fromOffset(38, 38), ZIndex = 84 }, card)
	mk("UICorner", { CornerRadius = UDim.new(1, 0) }, em)
	mk("UIStroke", { Color = accent, Thickness = 2 }, em)
	UI.icon(em, lost and "icon_flame" or "icon_defense", 22, accent, UDim2.fromScale(0.5, 0.5), { z = 85, anchor = Vector2.new(0.5, 0.5) })
	text(card, lost and (string.upper(name) .. " RAIDED YOU") or ("YOU HELD OFF " .. string.upper(name)), { font = "display", size = 17, color = accent,
		pos = UDim2.fromOffset(64, 8), sz = UDim2.new(1, -110, 0, 22), z = 84, truncate = true })
	-- cash lost (counts up) and soldiers lost on one line
	local line = text(card, "", { font = "bold", size = 14, rich = true, pos = UDim2.fromOffset(64, 32), sz = UDim2.new(1, -72, 0, 18), z = 84, truncate = true })
	local soldiers = R.Commas(n.lost or 0) .. ((n.lost == 1) and " soldier lost" or " soldiers lost")
	local soldiersTxt = "<font color='" .. ((n.lost or 0) > 0 and "#e2695f" or "#9a9fa6") .. "'>" .. soldiers .. "</font>"
	if lost then
		countUp(line, 0, n.cash or 0, function(v) return "<font color='#e2695f'>-" .. R.Money(v) .. "</font>  ·  " .. soldiersTxt end, 0.8)
	else
		line.Text = "<font color='#8fd07a'><b>Defended!</b> Cash safe</font>  ·  " .. soldiersTxt
	end
	-- auto-hide timer bar along the bottom edge
	-- (a slim kit bar under the hint line, left of RAID BACK)
	local timer = UI.bar(card, accent, { name = "Timer", pos = UDim2.new(0, 14, 1, -16), sz = UDim2.new(1, -160, 0, 12), z = 84, textSize = 10 })
	timer:Set(1)
	local fill = timer.Fill

	local gone = false
	local entry = {}
	local function dismiss(instant)
		if gone then return end
		gone = true
		for i, e in ipairs(raidedLive) do if e == entry then table.remove(raidedLive, i); break end end
		if instant then cell:Destroy(); return end
		tw(card, 0.22, { Position = UDim2.fromOffset(360, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(0.24, function() cell:Destroy() end)
	end
	entry.dismiss = dismiss
	table.insert(raidedLive, entry)

	local x = UI.img(card, "btn_slate", { button = true, name = "Close", sz = UDim2.fromOffset(28, 26), pos = UDim2.new(1, -36, 0, 8), z = 86 })
	UI.icon(x, "icon_x", 14, C.ink, UDim2.new(0.5, 0, 0.5, -1), { z = 87, anchor = Vector2.new(0.5, 0.5) })
	x.Activated:Connect(function() dismiss() end)
	UI.button(card, "red", "RAID BACK", function(btn)
		if not n.byId then App.toast("They left the server", nil, "bad"); App.shake(btn.Inst); return end
		dismiss()
		App.open("battle")
		raidTarget(App, n.byId, name, nil)
	end, { sz = UDim2.fromOffset(120, 30), pos = UDim2.new(1, -10, 1, -12), anchor = Vector2.new(1, 1), z = 86, icon = "icon_attack", textSize = 14 })
	text(card, lost and "Hit them back!" or "Teach them a lesson?", { size = 13, color = C.muted, pos = UDim2.fromOffset(18, 56), sz = UDim2.new(1, -150, 0, 18), z = 84, truncate = true })

	tw(card, 0.35, { Position = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Back)
	tw(fill, RAIDED_SECONDS, { Size = UDim2.new(0, 0, 1, -6) }, Enum.EasingStyle.Linear)
	task.delay(RAIDED_SECONDS, function() dismiss() end)
end

local spiedHost
local function spiedNote(App, n)
	if type(n) ~= "table" then return end
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	-- shares the top right notes column with the raided cards so they stack instead of overlapping
	spiedHost = getNoteHost(App)
	-- the layout positions the cell; the card inside is centre-anchored so it pops from its middle
	local cell = mk("TextButton", { Name = "Spied", Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(330, 70), ZIndex = 82, LayoutOrder = math.floor(os.clock() * 10) }, spiedHost)
	local card = UI.img(cell, "panel_plain", { name = "Card", sz = UDim2.fromScale(1, 1), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 83 })
	UI.outline(card, C.blue, 2, { alpha = 0.3 })
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
	App.raidTarget = function(id, name, btn) return raidTarget(App, id, name, btn) end -- RANKINGS attacks anyone (Kash 2 Oct)
	-- Revenge Strike results arrive later as a "raidResult" note (ClientMain emits it)
	App.on("raidResult", function(res) showRaidResult(App, res, { revenge = true, name = type(res) == "table" and res.target or nil }) end)
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
		"Raid the nations in <b>this server</b> plus <b>3 rival nations</b> from around the world.\n\n" ..
		"<font color='#7fb0e6'><b>SPY</b></font> (" .. SPY_SUPPLY .. " Supply) to see their defense and cash.\n\n" ..
		"Win to steal <font color='#8fd07a'><b>10% of their cash on hand</b></font>. Bank your own cash to keep it safe!\n\n" ..
		"<font color='#e2695f'><b>Soldiers fall on both sides</b></font>, so keep your army strong.",
		UDim2.fromOffset(0, 5), 8)
	text(body, "Raid nations in your server and 3 rival nations. SPY first to see their defense and cash. Win to steal 10% of their cash on hand.",
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
		UI.outline(card, C.bad, 2)
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
			-- long nation names shrink to fit instead of cutting to "Empire of..." (small phones)
			text(card, t.name or "?", { font = "display", size = 19, pos = UDim2.fromOffset(80, 10), sz = UDim2.new(0.3, -92, 0, 24), z = 8, scaled = true })
			local tags = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(80, 40), Size = UDim2.new(0.3, -80, 0, 22), ZIndex = 8 }, card)
			mk("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, tags)
			UI.chip(tags, "LV " .. (t.lv or 1), { manila = true, h = 22, size = 13, z = 9, order = 1 })
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
