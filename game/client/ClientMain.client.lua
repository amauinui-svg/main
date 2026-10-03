-- ClientMain: the shell. Top bar, the left nav (flush with the screen's left edge, Kash 26 Sep), the screen host,
-- toasts and level-up banners. The Capitol world map is the home screen (Kash, 1 Oct 2026, Q12).
-- Everything is laid out in design pixels on a top-left anchored root scaled by ONE UIScale
-- (LESSONS: a UIScale scales about the AnchorPoint; read TopbarInset lazily).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local plr = Players.LocalPlayer
local pgui = plr:WaitForChild("PlayerGui")

local Shared = RS:WaitForChild("Shared")
local ClientMods = RS:WaitForChild("Client")
local R = require(Shared.Rules)
local Config = require(Shared.Config)
local Assets = require(Shared.Assets)
local UI = require(ClientMods.UI)
local C = UI.C
local mk, text = UI.mk, UI.text
local Remotes = RS:WaitForChild("Remotes")

local old = pgui:FindFirstChild("IdleCountryHUD"); if old then old:Destroy() end
local sg = mk("ScreenGui", { Name = "IdleCountryHUD", ResetOnSpawn = false, IgnoreGuiInset = true, ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 5 }, pgui)
local root = mk("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromOffset(1280, 720), ZIndex = 1 }, sg)
local uiScale = mk("UIScale", { Name = "Fit" }, root)
mk("Frame", { Name = "Backdrop", BackgroundColor3 = Color3.fromHex("14171b"), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 0 }, root)

local TOP, NAVW = 64, 176
local App = { UI = UI, root = root, sg = sg, state = nil, world = nil, screens = {}, current = nil, listeners = {}, TOP = TOP, NAVW = NAVW }
_G.IdleCountryApp = App -- for Studio debugging only

function App.now() return workspace:GetServerTimeNow() end
function App.on(ev, fn) App.listeners[ev] = App.listeners[ev] or {}; table.insert(App.listeners[ev], fn) end
function App.emit(ev, ...) for _, fn in ipairs(App.listeners[ev] or {}) do task.spawn(fn, ...) end end

---------------------------------------------------------------- fit to screen
local fakeVp -- Studio test hook: emulate a phone or tablet viewport (IC_Cmd "vp:844x390", "vp:" resets)
local function fit()
	local cam = workspace.CurrentCamera
	local vp = fakeVp or (cam and cam.ViewportSize) or Vector2.new(1280, 720)
	-- phones (short screens) use a 560-tall design so text stays readable; everything else 720
	local refH = vp.Y < 600 and 560 or 720
	local s = math.clamp(math.min(vp.X / (refH * 16 / 9), vp.Y / refH), 0.45, 1.6)
	uiScale.Scale = s
	root.Size = UDim2.fromOffset(math.floor(vp.X / s), math.floor(vp.Y / s))
	App.emit("resize", root.Size.X.Offset, root.Size.Y.Offset)
end
local function hookCamera()
	local cam = workspace.CurrentCamera
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	fit()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera)
hookCamera()
function App.W() return root.Size.X.Offset end
function App.H() return root.Size.Y.Offset end
local function robloxButtonsEnd()
	local ok, inset = pcall(function() return GuiService.TopbarInset end)
	local x = (ok and inset and inset.Min.X > 0) and inset.Min.X or 140
	return math.floor(x / uiScale.Scale) + 6
end

---------------------------------------------------------------- toasts, floats, shake
local toastHost = mk("Frame", { Name = "Toasts", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, NAVW / 2, 0, TOP + 12), Size = UDim2.fromOffset(520, 0), BackgroundTransparency = 1, ZIndex = 80 }, root)
mk("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, toastHost)
local toastN, liveToasts = 0, {}
local TONE = { good = C.good, bad = C.bad, gold = C.gold, info = C.blue }
function App.toast(title, body, tone)
	toastN += 1
	local key = title .. "|" .. (body or "")
	local live = liveToasts[key]
	if live and live.card.Parent then live.until_ = os.clock() + 2.5; live.card.LayoutOrder = toastN; return end
	local color = TONE[tone] or tone or C.manila
	local t = UI.img(toastHost, "panel_plain", { name = "Toast", sz = UDim2.fromOffset(520, body and 66 or 42), z = 80, order = toastN })
	local entry = { card = t, until_ = os.clock() + (body and 4 or 3) }
	liveToasts[key] = entry
	text(t, title, { font = "display", size = 19, pos = UDim2.fromOffset(16, body and 6 or 8), sz = UDim2.new(1, -32, 0, 26), z = 81, color = color, truncate = true })
	if body then text(t, body, { size = 15, pos = UDim2.fromOffset(16, 34), sz = UDim2.new(1, -32, 0, 24), z = 81, truncate = true, color = C.ink }) end
	task.spawn(function()
		while os.clock() < entry.until_ do task.wait(0.2) end
		if t.Parent then t:Destroy() end
		if liveToasts[key] == entry then liveToasts[key] = nil end
	end)
end
function App.shake(gui)
	if not gui then return end
	local p = gui.Position
	task.spawn(function()
		for _, dx in ipairs({ 7, -7, 4, -4, 0 }) do gui.Position = p + UDim2.fromOffset(dx, 0); task.wait(0.03) end
		gui.Position = p
	end)
end
function App.float(gui, str, color)
	if not gui or not gui.Parent then return end
	local s = uiScale.Scale
	local p = (gui.AbsolutePosition - root.AbsolutePosition) / s
	local w = gui.AbsoluteSize.X / s
	local l = text(root, str, { name = "Float", font = "heavy", size = 20, color = color or C.good, align = Enum.TextXAlignment.Center, pos = UDim2.fromOffset(p.X - 40, p.Y - 26), sz = UDim2.fromOffset(w + 80, 26), z = 90, stroke = 1.6, rich = true })
	TweenService:Create(l, TweenInfo.new(0.9, Enum.EasingStyle.Quad), { Position = UDim2.fromOffset(p.X - 40, p.Y - 80), TextTransparency = 1 }):Play()
	local st = l:FindFirstChildOfClass("UIStroke"); if st then TweenService:Create(st, TweenInfo.new(0.9), { Transparency = 1 }):Play() end
	task.delay(1, function() l:Destroy() end)
end

local PROMPTS = { buyPass = true, buyProduct = true, buyGold = true, revengeStrike = true, refillInfluence = true, finishRobux = true, moveCapital = true }
-- a completed Robux purchase gets its own celebration sound
pcall(function()
	local MPS = game:GetService("MarketplaceService")
	MPS.PromptGamePassPurchaseFinished:Connect(function(who, _, bought) if who == plr and bought then App.play("cash_big"); App.play("level_up", { volume = 0.6 }) end end)
	MPS.PromptProductPurchaseFinished:Connect(function(uid, _, bought) if uid == plr.UserId and bought then App.play("cash_big") end end)
end)
-- request: shakes the button and toasts the reason when the server says no
function App.req(action, args, btn)
	local ok, res = pcall(function() return Remotes.Request:InvokeServer(action, args or {}) end)
	if not ok then res = { ok = false, msg = "Connection problem. Try again." } end
	if not res.ok and res.msg then
		App.toast(res.msg, nil, "bad")
		if btn then App.shake(btn.Inst or btn) end
	end
	-- a Robux prompt is opening: a soft "register" sound (Kash 19:19)
	if res.ok and PROMPTS[action] and not (action == "refillInfluence" and args and args.method == "gold") then App.play("purchase", { volume = 0.45, pitch = 1.15 }) end
	return res
end

-- confirm modal (used for anything that costs a lot or cannot be undone)
local modalHost = mk("TextButton", { Name = "Modal", Text = "", AutoButtonColor = false, BackgroundColor3 = C.black, BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), ZIndex = 70, Visible = false }, root)
function App.confirm(title, body, okLabel, kind, fn)
	UI.clear(modalHost)
	modalHost.Visible = true
	local panel, b = UI.panel(modalHost, title, { sz = UDim2.fromOffset(460, 230), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71 })
	text(b, body, { size = 17, wrap = true, sz = UDim2.new(1, 0, 1, -56), valign = Enum.TextYAlignment.Top, z = 73, rich = true })
	UI.button(b, "slate", "CANCEL", function() modalHost.Visible = false end, { sz = UDim2.fromOffset(150, 44), pos = UDim2.new(0, 0, 1, -46), z = 73 })
	UI.button(b, kind or "manila", okLabel or "CONFIRM", function(btn) modalHost.Visible = false; fn(btn) end, { sz = UDim2.fromOffset(200, 44), pos = UDim2.new(1, -200, 1, -46), z = 73 })
	return panel
end
function App.closeModal() modalHost.Visible = false end

-- FREE GIFT popup (Kash 2 Oct): like the game + join the group, then claim once
function App.showGroupGift()
	local st = App.state
	if not st then return end
	local gift = Config.GroupGift or { gold = 100, limitedCrates = 1 }
	local bonus = math.floor(((Config.Group and Config.Group.Bonus) or 0.1) * 100 + 0.5)
	UI.clear(modalHost)
	modalHost.Visible = true
	local _, b = UI.panel(modalHost, "FREE GIFT", { sz = UDim2.fromOffset(520, 360), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 71 })
	UI.button(b, "slate", "X", function() modalHost.Visible = false end, { pos = UDim2.new(1, 0, 0, -40), anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(40, 36), z = 75, textSize = 16 })
	UI.icon(b, "icon_gift", 64, C.gold, UDim2.fromOffset(0, 4), { z = 73 })
	text(b, "Like the game and join our group!", { font = "heavy", size = 20, pos = UDim2.fromOffset(80, 6), sz = UDim2.new(1, -80, 0, 26), z = 73 })
	text(b, "<font color='#f0c75a'><b>+" .. gift.gold .. " GOLD</b></font>  ·  <font color='#f0c75a'><b>" .. gift.limitedCrates .. " FOUNDER'S CRATE</b></font>  ·  <font color='#8fd07a'><b>+" .. bonus .. "% CASH FOREVER</b></font>",
		{ size = 16, rich = true, wrap = true, pos = UDim2.fromOffset(80, 38), sz = UDim2.new(1, -80, 0, 44), z = 73 })
	local gid = st.groupId or (Config.Group and Config.Group.Id) or 0
	UI.button(b, "blue", "1. LIKE THE GAME", function()
		pcall(function() game:GetService("AvatarEditorService"):PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true) end)
	end, { pos = UDim2.fromOffset(0, 104), sz = UDim2.new(0.5, -6, 0, 50), z = 73, icon = "icon_sparkles", textSize = 15 })
	UI.button(b, "green", "2. JOIN GROUP", function()
		pcall(function() game:GetService("GroupService"):PromptJoinAsync(gid) end)
	end, { pos = UDim2.new(0.5, 6, 0, 104), sz = UDim2.new(0.5, -6, 0, 50), z = 73, icon = "icon_alliance", textSize = 15 })
	UI.button(b, "gold", "3. CLAIM GIFT", function(btn)
		local res = App.req("groupGift", {}, btn)
		if res.ok then
			modalHost.Visible = false
			App.toast("FREE GIFT CLAIMED!", "+" .. (res.gold or gift.gold) .. " gold · " .. (res.crates or gift.limitedCrates) .. " Founder's Crate · +" .. bonus .. "% cash", "gold")
			App.play("purchase", { volume = 0.5 })
		end
	end, { pos = UDim2.new(0.5, 0, 1, -4), anchor = Vector2.new(0.5, 1), sz = UDim2.new(1, 0, 0, 56), z = 73, textSize = 20 })
end
App.modalHost = modalHost

---------------------------------------------------------------- top bar
local topBar = UI.img(root, "topbar", { name = "TopBar", sz = UDim2.new(1, 0, 0, TOP), z = 20 })
local top = {}
do
	local id = mk("Frame", { Name = "Identity", BackgroundTransparency = 1, Size = UDim2.fromOffset(330, TOP), ZIndex = 21 }, topBar)
	top.id = id
	top.flagHost = mk("Frame", { Name = "FlagHost", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(60, 40), ZIndex = 21 }, id)
	top.name = text(id, "", { font = "display", size = 19, pos = UDim2.fromOffset(68, 6), sz = UDim2.fromOffset(250, 24), truncate = true, z = 22 })
	top.xp = UI.bar(id, C.xp, { pos = UDim2.fromOffset(68, 34), sz = UDim2.fromOffset(250, 22), z = 22, textSize = 13 })

	local mid = mk("Frame", { Name = "Money", BackgroundTransparency = 1, Size = UDim2.fromOffset(300, TOP), ZIndex = 21 }, topBar)
	top.mid = mid
	UI.icon(mid, "icon_cash", 26, C.good, UDim2.fromOffset(0, 10), { z = 22 })
	top.cash = text(mid, "$0", { font = "display", size = 28, color = C.good, pos = UDim2.fromOffset(32, 7), sz = UDim2.fromOffset(240, 30), z = 22, scaled = true })
	top.income = text(mid, "", { font = "bold", size = 13, color = C.muted, pos = UDim2.fromOffset(32, 38), sz = UDim2.fromOffset(106, 18), z = 22, truncate = true })
	-- gold bars and merits, big and readable (Kash 19:24)
	local function currency(x, w, imgKey, fallback, color, name)
		local b = UI.img(mid, "chip", { button = true, name = name, pos = UDim2.fromOffset(x, 34), sz = UDim2.fromOffset(w, 28), z = 22 })
		local key = (Assets[imgKey] and imgKey) or fallback
		UI.img(b, key, { sz = UDim2.fromOffset(30, 30), pos = UDim2.new(0, -4, 0.5, 0), anchor = Vector2.new(0, 0.5), z = 24, slice = false, fit = true, color = key == fallback and imgKey ~= fallback and color or nil })
		local l = text(b, "0", { font = "heavy", size = 17, color = color, pos = UDim2.fromOffset(30, 0), sz = UDim2.new(1, -34, 1, 0), z = 23, scaled = true })
		return b, l
	end
	local goldBtn
	goldBtn, top.gold = currency(144, 76, "icon_goldbar", "icon_gold", C.gold, "Gold")
	goldBtn.Activated:Connect(function() App.open("shop") end)
	local meritBtn
	meritBtn, top.merits = currency(226, 70, "icon_seal", "icon_seal", Color3.fromHex("e9c46a"), "Merits")
	meritBtn.Activated:Connect(function() App.open("tasks") end)

	local right = mk("Frame", { Name = "Energy", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -62, 0, 0), Size = UDim2.fromOffset(470, TOP), ZIndex = 21 }, topBar)
	top.right = right
	UI.icon(right, "icon_influence", 22, C.inf, UDim2.fromOffset(0, 8), { z = 22 })
	top.inf = UI.bar(right, C.inf, { pos = UDim2.fromOffset(26, 6), sz = UDim2.fromOffset(200, 24), z = 22, textSize = 14 })
	top.infT = text(right, "", { font = "bold", size = 12, color = C.muted, pos = UDim2.fromOffset(28, 32), sz = UDim2.fromOffset(196, 16), z = 22 })
	UI.icon(right, "icon_supply", 22, C.sup, UDim2.fromOffset(238, 8), { z = 22 })
	top.sup = UI.bar(right, C.sup, { pos = UDim2.fromOffset(264, 6), sz = UDim2.fromOffset(160, 24), z = 22, textSize = 14 })
	top.supT = text(right, "", { font = "bold", size = 12, color = C.muted, pos = UDim2.fromOffset(266, 32), sz = UDim2.fromOffset(156, 16), z = 22 })
	local plus = UI.img(right, "btn_gold", { button = true, name = "Refill", pos = UDim2.fromOffset(432, 8), sz = UDim2.fromOffset(36, 34), z = 22 })
	UI.icon(plus, "icon_plus", 18, C.manilaInk, UDim2.new(0.5, 0, 0.5, -1), { z = 23, anchor = Vector2.new(0.5, 0.5) })
	plus.Activated:Connect(function() App.open("shop") end)

	-- UPGRADES (skill points) from any screen: sits between the energy bars and the settings gear,
	-- appears with the Country tab (Config.NavUnlock.country)
	local upg = mk("Frame", { Name = "Upgrades", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -62, 0, 0), Size = UDim2.fromOffset(122, TOP), ZIndex = 21, Visible = false }, topBar)
	top.upg = upg
	top.upgBtn = UI.button(upg, "slate", "UPGRADES", function()
		if App.showUpgrades then App.showUpgrades() end
	end, { pos = UDim2.new(1, 0, 0.5, 0), anchor = Vector2.new(1, 0.5), sz = UDim2.fromOffset(118, 42), z = 22, icon = "icon_xp", iconSize = 20, textSize = 15 })
end
local topScales = {}
local function scaleOf(f) topScales[f] = topScales[f] or mk("UIScale", {}, f); return topScales[f] end
local function layoutTop()
	local w = App.W()
	local x0 = robloxButtonsEnd()
	top.id.Position = UDim2.fromOffset(x0, 0)
	-- shrink the three groups together until cash fits between identity and the bars (phones)
	-- the UPGRADES button (when shown) takes 122 px (scaled) between the energy group and the gear
	local upgW = top.upg.Visible and 122 or 0
	local k = 1
	for _, try in ipairs({ 1, 0.9, 0.8, 0.72, 0.65, 0.58 }) do
		k = try
		local room = w - 62 - (470 + upgW) * k - (x0 + 340 * k)
		if room >= 300 * k then break end
	end
	scaleOf(top.id).Scale = k; scaleOf(top.right).Scale = k; scaleOf(top.mid).Scale = k; scaleOf(top.upg).Scale = k
	top.id.Size = UDim2.fromOffset(330, TOP / k)
	top.right.Size = UDim2.fromOffset(470, TOP / k)
	top.mid.Size = UDim2.fromOffset(300, TOP / k)
	top.upg.Size = UDim2.fromOffset(122, TOP / k)
	top.upg.Position = UDim2.new(1, -62, 0, 0)
	top.right.Position = UDim2.new(1, -62 - math.floor(upgW * k), 0, 0)
	local midX = x0 + 340 * k
	local room = w - 62 - (470 + upgW) * k - midX
	top.mid.Visible = room >= 290 * k
	top.mid.Position = UDim2.fromOffset(midX + math.max(0, math.floor((room - 300 * k) / 2)), 0)
end
App.on("resize", layoutTop)
pcall(function() GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layoutTop) end)
layoutTop()

---------------------------------------------------------------- nav (flush left)
local NAV = {
	{ key = "country", label = "COUNTRY", icon = "icon_flag" },
	{ key = "map", label = "WORLD", icon = "icon_map" },
	{ key = "laws", label = "LAWS", icon = "icon_laws" },
	{ key = "properties", label = "PROPERTIES", icon = "icon_properties" },
	{ key = "inventory", label = "INVENTORY", icon = "icon_boxes" },
	{ key = "military", label = "MILITARY", icon = "icon_military" },
	{ key = "battle", label = "RAIDS", icon = "icon_battle" },
	{ key = "bosses", label = "BOSSES", icon = "icon_bosses" },
	{ key = "alliance", label = "ALLIANCE", icon = "icon_alliance" },
	{ key = "tasks", label = "ORDERS", icon = "icon_tasks" },
	{ key = "bank", label = "BANK", icon = "icon_bank" },
	{ key = "rankings", label = "RANKINGS", icon = "icon_rankings" },
	{ key = "shop", label = "SHOP", icon = "icon_shop" },
}
local nav = UI.list(root, { name = "Nav", pos = UDim2.fromOffset(0, TOP + 4), sz = UDim2.new(0, NAVW, 1, -TOP - 4), gap = 3, z = 15 })
nav.ScrollBarThickness = 0
-- on phones the Roblox menu buttons are taller than our scaled top bar: start the nav below them (Kash 00:30 mobile test)
local function layoutNav()
	local ok, inset = pcall(function() return GuiService.TopbarInset end)
	local robloxBottom = (ok and inset and inset.Max.Y > 0) and math.ceil(inset.Max.Y / uiScale.Scale) + 6 or 0
	local y = math.max(TOP + 4, robloxBottom)
	nav.Position = UDim2.fromOffset(0, y)
	nav.Size = UDim2.new(0, NAVW, 1, -y)
end
App.on("resize", layoutNav)
pcall(function() GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layoutNav) end)
layoutNav()
nav:FindFirstChildOfClass("UIPadding").PaddingRight = UDim.new(0, 0)
nav:FindFirstChildOfClass("UIPadding").PaddingLeft = UDim.new(0, 0)
local navButtons = {}
for i, n in ipairs(NAV) do
	local b = UI.img(nav, "nav_off", { button = true, name = n.key, sz = UDim2.fromOffset(NAVW, 44), z = 16, order = i })
	local ic = UI.icon(b, n.icon, 22, C.ink, UDim2.new(0, 12, 0.5, 0), { z = 17, anchor = Vector2.new(0, 0.5) })
	local l = text(b, n.label, { font = "heavy", size = 16, pos = UDim2.fromOffset(42, 0), sz = UDim2.new(1, -48, 1, 0), z = 17 })
	navButtons[n.key] = { Inst = b, Icon = ic, Label = l }
	b.Activated:Connect(function() App.open(n.key) end)
end
App.navButtons = navButtons
-- level-gated tabs (Kash 2 Oct): hidden until unlocked, plus one dim "LV x" teaser row for the next tab
local NAV_UNLOCK = (Config and Config.NavUnlock) or {}
local navTeaser = UI.img(nav, "nav_off", { name = "NextUnlock", sz = UDim2.fromOffset(NAVW, 44), z = 16, order = 999 })
navTeaser.ImageTransparency = 0.5
UI.icon(navTeaser, "icon_lock", 20, C.dim, UDim2.new(0, 12, 0.5, 0), { z = 17, anchor = Vector2.new(0, 0.5) })
local teaserL = text(navTeaser, "", { font = "heavy", size = 14, color = C.dim, pos = UDim2.fromOffset(42, 0), sz = UDim2.new(1, -48, 1, 0), z = 17, rich = true })
local navLv
function App.navUnlocked(key)
	local need = NAV_UNLOCK[key]
	return not need or not App.state or (App.state.lv or 1) >= need
end
local function navLabel(key) for _, n in ipairs(NAV) do if n.key == key then return n.label end end return string.upper(key) end
local function updateNav(st)
	if not st or not st.onboarded then return end
	local lv = st.lv or 1
	local nextKey, nextLv
	for _, n in ipairs(NAV) do
		local need = NAV_UNLOCK[n.key] or 1
		local open = lv >= need
		navButtons[n.key].Inst.Visible = open
		if not open and (not nextLv or need < nextLv) then nextKey, nextLv = n.key, need end
		-- newly unlocked this session: announce it
		if open and navLv and navLv < need then
			App.toast("NEW TAB UNLOCKED: " .. navLabel(n.key), "Find it in the menu on the left", "gold")
			App.navBadge(n.key, "!")
		end
	end
	navTeaser.Visible = nextKey ~= nil
	if nextKey then teaserL.Text = "LV " .. nextLv .. " · " .. navLabel(nextKey) end
	navLv = lv
end
App.updateNav = updateNav
local navBadges = {}
function App.navBadge(key, n)
	local nb = navButtons[key]
	if not nb then return end
	if navBadges[key] then navBadges[key]:Destroy(); navBadges[key] = nil end
	if n and n ~= 0 and n ~= false then navBadges[key] = UI.badge(nb.Inst, n == true and "!" or n, UDim2.new(1, -16, 0.5, 0), 18) end
end

---------------------------------------------------------------- screen host
local content = mk("Frame", { Name = "Content", BackgroundTransparency = 1, Position = UDim2.fromOffset(NAVW, TOP), Size = UDim2.new(1, -NAVW, 1, -TOP), ZIndex = 2, ClipsDescendants = true }, root)
App.content = content
local defs = {}
local inits = {} -- modules can return entries without a build field: { init = function(App) end }
-- later modules override earlier ones (Warfare's raids replace War's battle, Contracts replaces Economy's tasks)
for _, modName in ipairs({ "Sound", "Map", "Economy", "War", "Social", "Warfare", "Cabinet", "Country", "Contracts", "Settings", "Shop", "GearShop", "Afk", "Tester", "Tutorial" }) do
	local okReq, mod = pcall(require, ClientMods:WaitForChild(modName, 5))
	if okReq and type(mod) == "table" then
		for k, def in pairs(mod) do
			if type(def) == "table" and def.build then defs[k] = def
			elseif type(def) == "table" and def.init and k == "_sound" then App.soundInit = def.init -- runs before onboarding (music + click sounds)
			elseif type(def) == "table" and def.init then table.insert(inits, def.init) end
		end
	else warn("[Idle Country] " .. modName .. ": " .. tostring(mod)) end
end
-- tabbed screens (Kash 19:19): Officers live inside Military. (Weekly Takedown removed 2 Oct, Kash.)
-- The child screen's own title is replaced by two tab buttons in the same spot.
local COMPOSITE = {
	military = { { key = "military", label = "ARMY", title = "MILITARY" }, { key = "officers", label = "OFFICERS", title = "OFFICERS" } },
	shop = { { key = "shop", label = "STORE", title = "SHOP" }, { key = "gearshop", label = "GEAR SHOP", title = "GEAR SHOP" } },
}
local ROUTE = { officers = { "military", 2 }, gearshop = { "shop", 2 } }
-- Sub tabs use the kit's tab plates and sit exactly where the panel title was (panel x 16, y 6). Every child host gets
-- the attribute TabsRight (panel x where the tabs end) so the child lays its header text and buttons out after them.
local SUBTAB_W, SUBTAB_GAP, SUBTAB_X, SUBTAB_Y = 150, 6, 26, 16
for parentKey, kids in pairs(COMPOSITE) do
	local childDefs = {}
	for i, k in ipairs(kids) do childDefs[i] = defs[k.key] end
	defs[parentKey] = { build = function(host, App)
		local obj = { kids = {}, cur = 1 }
		local labels = {}
		for i, k in ipairs(kids) do labels[i] = k.label end
		local tabsW = #kids * SUBTAB_W + (#kids - 1) * SUBTAB_GAP
		local tabsRight = (SUBTAB_X - 10) + tabsW + 14 -- in the child panel's coordinates (panels sit 10 px inside the host)
		local function hideTitle(root, title)
			if not title then return end
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("TextLabel") and d.Name == "Title" and d.Text == title then d.Visible = false end
			end
		end
		local tabs
		function obj.select(i)
			obj.cur = i
			for j, kid in ipairs(obj.kids) do kid.host.Visible = j == i end
			if tabs then tabs:Set(i) end
			local kid = obj.kids[i]
			if kid and kid.obj then
				if App.state and kid.obj.Refresh then pcall(kid.obj.Refresh, kid.obj, App.state) end
				if kid.obj.Opened then pcall(kid.obj.Opened, kid.obj) end
			end
		end
		for i, k in ipairs(kids) do
			local h = mk("Frame", { Name = "Sub_" .. k.key, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3, Visible = i == 1 }, host)
			h:SetAttribute("TabsRight", tabsRight)
			local okB, o = false, nil
			if childDefs[i] then okB, o = pcall(childDefs[i].build, h, App) end
			if not okB then warn("[Idle Country] sub screen " .. k.key .. ": " .. tostring(o)) end
			obj.kids[i] = { host = h, obj = okB and o or nil }
			hideTitle(h, k.title)
		end
		tabs = UI.tabs(host, labels, function(i)
			if App.play then App.play("tab_open") end
			obj.select(i)
		end, { pos = UDim2.fromOffset(SUBTAB_X, SUBTAB_Y), sz = UDim2.fromOffset(tabsW, 36), w = SUBTAB_W, textSize = 16, z = 40 })
		tabs:Set(1)
		function obj:Refresh(st)
			local kid = obj.kids[obj.cur]
			if kid and kid.obj and kid.obj.Refresh then kid.obj.Refresh(kid.obj, st) end
		end
		function obj:Tick(st)
			local kid = obj.kids[obj.cur]
			if kid and kid.obj and kid.obj.Tick then kid.obj.Tick(kid.obj, st) end
		end
		function obj:Opened()
			local kid = obj.kids[obj.cur]
			if kid and kid.obj and kid.obj.Opened then pcall(kid.obj.Opened, kid.obj) end
		end
		return obj
	end }
end
local initsDone = false
local function runInits()
	if initsDone or not (App.state and App.state.onboarded) then return end
	initsDone = true
	for _, fn in ipairs(inits) do
		-- each init in its own thread: one that yields (sound preloading) must not hold up the rest
		task.spawn(function()
			local okI, err = pcall(fn, App)
			if not okI then warn("[Idle Country] init: " .. tostring(err)) end
		end)
	end
end
function App.big(reason) if App.bigMoment then pcall(App.bigMoment, reason) end end
function App.play(name, opts) if App.sfx then pcall(App.sfx, name, opts) end end

function App.open(key)
	local route = ROUTE[key]
	if route then
		App.open(route[1])
		local s = App.screens[route[1]]
		if s and s.obj and s.obj.select then s.obj.select(route[2]) end
		return
	end
	if not defs[key] then App.toast("Coming soon", nil, "info"); return end
	if not App.navUnlocked(key) then App.toast("Unlocks at level " .. NAV_UNLOCK[key], nil, "info"); return end
	local MANAGED = { country = true, tasks = true, map = true, bosses = true }
	if not MANAGED[key] then App.navBadge(key, nil) end
	if App.state and not App.state.onboarded then return end
	for k, s in pairs(App.screens) do s.host.Visible = (k == key) or (k == "map" and key ~= "map" and false) end
	local s = App.screens[key]
	if not s then
		local host = mk("Frame", { Name = "Screen_" .. key, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 3 }, content)
		local okB, obj = pcall(defs[key].build, host, App)
		if not okB then warn("[Idle Country] screen " .. key .. ": " .. tostring(obj)); host:Destroy(); App.toast("That screen failed to open", tostring(obj):sub(1, 80), "bad"); return end
		s = { host = host, obj = obj }
		App.screens[key] = s
	end
	s.host.Visible = true
	App.current = key
	for k, nb in pairs(navButtons) do
		nb.Inst.Image = Assets[k == key and "nav_on" or "nav_off"]
		nb.Label.TextColor3 = k == key and C.manilaInk or C.ink
		nb.Icon.ImageColor3 = k == key and C.manilaInk or C.ink
	end
	if App.state and s.obj and s.obj.Refresh then pcall(s.obj.Refresh, s.obj, App.state) end
	if s.obj and s.obj.Opened then pcall(s.obj.Opened, s.obj) end
end

App.runInits = function() runInits() end
-- /g and /global send to every server (global chat, Kash 23:29)
task.spawn(function()
	local TCS = game:GetService("TextChatService")
	local folder = TCS:WaitForChild("TextChatCommands", 30)
	local cmd = folder and folder:WaitForChild("IC_Global", 30)
	if not cmd then return end
	cmd.Triggered:Connect(function(_, raw)
		local body = tostring(raw or ""):gsub("^%s*/%a+%s*", "")
		local res = App.req("globalChat", { text = body })
		if not res.ok and res.msg then App.toast(res.msg, nil, "bad") end
	end)
end)
local function refreshCurrent()
	local s = App.current and App.screens[App.current]
	if s and s.obj and s.obj.Refresh then
		local okR, err = pcall(s.obj.Refresh, s.obj, App.state)
		if not okR then warn("[Idle Country] refresh " .. App.current .. ": " .. tostring(err)) end
	end
end

---------------------------------------------------------------- top bar values (ticks locally between server ticks)
local function ideoTitle(st)
	local n = st.name ~= "" and st.name or plr.DisplayName
	return string.upper(n)
end
local lastFlag
-- the top bar UPGRADES button: shown from the Country unlock level, gold with a red badge while points are free
local upgShownFree
local function drawUpgradesButton(st)
	local need = NAV_UNLOCK.country or 4
	local show = st.onboarded == true and (st.lv or 1) >= need
	if top.upg.Visible ~= show then
		top.upg.Visible = show
		layoutTop()
	end
	local free = tonumber(st.skillFree) or 0
	if free == upgShownFree then return end
	upgShownFree = free
	top.upgBtn:Set(free > 0 and "gold" or "slate")
	if top.upgBadge then top.upgBadge:Destroy(); top.upgBadge = nil end
	if free > 0 then top.upgBadge = UI.badge(top.upgBtn.Inst, free > 99 and "99+" or free, UDim2.new(1, -4, 0, 4), 26) end
end
local function drawTop()
	local st = App.state
	if not st then return end
	drawUpgradesButton(st)
	top.name.Text = ideoTitle(st)
	top.xp:Set(st.xp / math.max(1, st.xpReq), "LV " .. st.lv, R.Short(math.floor(st.xp)) .. " / " .. R.Short(st.xpReq) .. " XP")
	top.cash.Text = R.Money(st.cash)
	top.income.Text = "+" .. R.Money(st.incHr) .. "/hr"
	top.gold.Text = R.Commas(st.gold)
	if top.merits then top.merits.Text = R.Commas(st.seals or 0) end
	top.inf:Set(st.inf / st.infMax, "INFLUENCE  " .. st.inf .. " / " .. st.infMax, "")
	top.sup:Set(st.sup / st.supMax, "SUPPLY  " .. st.sup .. " / " .. st.supMax, "")
	local fk = st.flag and (st.flag.l .. table.concat(st.flag.c, ""))
	if fk ~= lastFlag then
		lastFlag = fk
		UI.clear(top.flagHost)
		UI.flag(top.flagHost, st.flag, 56, { z = 22 })
	end
end
local function drawTimers()
	local st = App.state
	if not st then return end
	local since = os.clock() - (App.tickClock or os.clock())
	if st.inf < st.infMax then
		top.infT.Text = "+1 in " .. R.Clock(math.max(0, st.regenSec - st.infT - since)) .. " · full in " .. R.Duration((st.infMax - st.inf) * st.regenSec - st.infT - since)
	else top.infT.Text = "FULL" end
	if st.sup < st.supMax then
		top.supT.Text = "+1 in " .. R.Clock(math.max(0, (st.supSec or 60) - st.supT - since))
	else top.supT.Text = "FULL" end
end

local function badges()
	local st = App.state
	if not st then return end
	App.navBadge("country", ((st.skillFree > 0) and st.skillFree) or (st.loginReady and "!") or nil)
	local claim = 0
	for _, t in ipairs(st.tasks and st.tasks.list or {}) do if t.have >= t.n and not t.done then claim += 1 end end
	App.navBadge("tasks", claim > 0 and claim or nil)
	local idle = 0
	for _, c in ipairs(st.convoys or {}) do if not c.to then idle += 1 end end
	App.navBadge("map", (idle > 0 and not (st.gp and st.gp.AutoDispatch and not st.autoOff)) and idle or nil)
	local boss = st.boss
	App.navBadge("bosses", boss and (boss.next or 0) <= App.now() and st.sup >= st.supMax and true or nil)
end

---------------------------------------------------------------- notes from the server
local function levelBanner(n)
	local bits = {}
	if n.era then table.insert(bits, "THE " .. string.upper(n.era) .. " ERA IS AVAILABLE: ADVANCE IN LAWS") end
	if #n.laws > 0 then table.insert(bits, #n.laws .. " new law" .. (#n.laws > 1 and "s" or "")) end
	if #n.props > 0 then table.insert(bits, "new property: " .. n.props[1]) end
	if #n.units > 0 then table.insert(bits, "new unit: " .. n.units[1]) end
	if n.slot then table.insert(bits, "a new convoy is for sale (WORLD)") end
	table.insert(bits, "+" .. n.points .. " skill points")
	App.toast("LEVEL " .. n.lv .. " · INFLUENCE REFILLED", table.concat(bits, " · "), "gold")
	App.play("level_up")
	if n.era or n.lv % 5 == 0 then App.big("level") end
end
local handleNote
local function handleNotes(notes)
	-- one bad note must never swallow the rest (audit L13)
	for _, n in ipairs(type(notes) == "table" and notes or {}) do
		local ok, err = pcall(handleNote, n)
		if not ok then warn("[Idle Country] note " .. tostring(n and n.kind) .. ": " .. tostring(err)) end
	end
end
handleNote = function(n)
	do
		if n.kind == "level" then levelBanner(n)
		elseif n.kind == "mastery" then
			App.toast(R.MasteryName[n.tier + 1] .. " MASTERY", n.law .. ": +" .. n.pct .. "% cash and XP" .. (n.tier >= 2 and " · 5% less Influence" or "") .. (n.point and " · +1 skill point" or ""), "gold")
			App.play(n.point and "stage_clear" or "claim")
			if n.point then App.big("mastery") end
		elseif n.kind == "arrive" then
			local World = require(Shared.World)
			local Trade = require(Shared.Trade)
			App.play("convoy_arrive", { volume = 0.5 })
			App.toast("DELIVERED TO " .. string.upper(World.Cities[n.city].name), Trade.GoodName(n.good) .. " · +" .. R.Money(n.cash) .. (n.tax > 0 and (" (tax " .. R.Money(n.tax) .. ")") or "") .. " · +" .. R.Short(n.xp) .. " XP", "good")
		elseif n.kind == "offline" then
			local parts = { "+" .. R.Money(n.cash) }
			if n.trips > 0 then table.insert(parts, n.trips .. " convoy deliveries") end
			if n.levels > 0 then table.insert(parts, "+" .. n.levels .. " levels") end
			App.toast("WHILE YOU WERE AWAY (" .. R.Duration(n.away) .. ")", table.concat(parts, " · "), "good")
		elseif n.kind == "boss" then App.toast(string.upper(n.name) .. " DEFEATED", "+" .. n.gold .. " gold · +" .. R.Money(n.cash) .. " · +" .. R.Short(n.xp) .. " XP", "gold"); App.play("boss_defeat"); App.big("boss")
		elseif n.kind == "raided" and App.raidedPopup then
			pcall(App.raidedPopup, n)
			App.navBadge("battle", "!")
		elseif n.kind == "spied" then
			if App.spiedNote then pcall(App.spiedNote, n) else App.toast(string.upper(n.by or "SOMEONE") .. " SPIED ON YOU", nil, "bad") end
		elseif n.kind == "raided" then
			if n.win then
				App.toast(string.upper(n.by) .. " RAIDED YOU", "Stole " .. R.Money(n.cash) .. (n.lost and n.lost > 0 and (" · " .. n.lost .. (n.lost == 1 and " soldier lost" or " soldiers lost")) or "") .. " · open RAIDS for REVENGE", "bad")
			else
				App.toast("YOU HELD OFF " .. string.upper(n.by), "Their raid failed" .. (n.lost and n.lost > 0 and (" · " .. n.lost .. (n.lost == 1 and " soldier lost" or " soldiers lost")) or "") .. " · open RAIDS to hit back", "good")
			end
			App.navBadge("battle", "!")
		elseif n.kind == "raidResult" then
			App.emit("raidResult", n.res)
			local r = n.res or {}
			if r.ok and not r.fight then App.toast(r.win and "REVENGE STRIKE · VICTORY" or "REVENGE STRIKE", r.win and ("+" .. R.Money(r.cash or 0)) or nil, r.win and "gold" or "bad") end
		elseif n.kind == "afkFind" then if App.afkFind then App.afkFind(n) end
		elseif n.kind == "crates" then App.toast("+" .. n.n .. " FOUNDER'S CRATE" .. (n.n > 1 and "S" or ""), "Open them in your Inventory", "gold"); App.navBadge("inventory", "!")
		elseif n.kind == "bundle" then App.toast("LIMITED BUNDLE UNLOCKED", "Empress Valeria Thorne and the Founder's Saber joined you", "gold"); App.big("bundle")
		elseif n.kind == "toast" then App.toast(n.text, nil, n.tone)
		end
	end
end

---------------------------------------------------------------- sync
local onboardShown = false
Remotes.Sync.OnClientEvent:Connect(function(kind, data)
	if kind == "full" then
		App.state = data
		App.tickClock = os.clock()
		if App.soundInit then local f = App.soundInit; App.soundInit = nil; task.spawn(function() local okS, e = pcall(f, App); if not okS then warn("[Idle Country] sound: " .. tostring(e)) end end) end
		updateNav(data)
		drawTop(); badges()
		if not data.onboarded then
			-- shown on first join, and again after the tester panel's /reset (App.onboarding guards repeats)
			if not onboardShown or not App.onboarding then
				onboardShown = true
				App.onboarding = true
				App.reonboard = nil
				local okO, Onboard = pcall(require, ClientMods:WaitForChild("Onboard"))
				if okO then Onboard.show(App) else warn(Onboard) end
			end
		elseif not App.current then
			App.onboarding = nil
			App.open("map")
			runInits()
			if data.loginReady and App.showLogin then task.delay(1.5, function() pcall(App.showLogin) end) end
		else
			App.onboarding = nil
			runInits() -- a brand new player finishes onboarding with a screen already open: inits still need to run
			refreshCurrent()
		end
		App.emit("full", data)
	elseif kind == "tick" then
		local st = App.state
		if not st then return end
		for k, v in pairs(data) do st[k] = v end
		App.tickClock = os.clock()
		drawTop()
		App.emit("tick", st)
	elseif kind == "notes" then
		handleNotes(data)
	elseif kind == "gchat" then
		pcall(function()
			local d = data or {}
			local TCS = game:GetService("TextChatService")
			local ch = TCS:FindFirstChild("TextChannels") and TCS.TextChannels:FindFirstChild("RBXGeneral")
			local function esc(x) return (tostring(x or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
			if ch then ch:DisplaySystemMessage("<font color='#7fb0e6'><b>[GLOBAL] " .. esc(d.n) .. ":</b></font> " .. esc(d.t)) end
		end)
	elseif kind == "chat" then
		-- purchase shout-out (Kash 2 Oct): a starred system message in chat
		pcall(function()
			local d = data or {}
			local TCS = game:GetService("TextChatService")
			local ch = TCS:FindFirstChild("TextChannels") and TCS.TextChannels:FindFirstChild("RBXGeneral")
			local function esc(x) return (tostring(x or ""):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
			local star = utf8.char(0x2B50)
			local msg = "<font color='#f0c75a'><b>" .. star .. " " .. esc(d.who) .. " bought " .. esc(d.what) .. " for R$" .. esc(d.robux) .. "! " .. star .. "</b></font>"
			if ch then ch:DisplaySystemMessage(msg) end
		end)
	elseif kind == "world" then
		App.world = data
		App.emit("world", data)
		if App.current and App.current ~= "map" then refreshCurrent() end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.25)
		drawTimers()
		local s = App.current and App.screens[App.current]
		if s and s.obj and s.obj.Tick then pcall(s.obj.Tick, s.obj, App.state) end
		if math.floor(os.clock() * 4) % 4 == 0 then badges() end
	end
end)

-- preload the art so nothing pops in
task.spawn(function()
	local list = {}
	for _, id in pairs(Assets) do table.insert(list, id) end
	pcall(function() ContentProvider:PreloadAsync(list) end)
end)

App.req("sync")

-- Studio layout audit: visible text that overflows its box, spills outside its panel, or sits on top of other text
function App.auditLayout()
	local HttpService = game:GetService("HttpService")
	local function shown(g)
		local o = g
		while o and o ~= sg do
			if o:IsA("GuiObject") and not o.Visible then return false end
			o = o.Parent
		end
		return true
	end
	local function rect(g) return g.AbsolutePosition, g.AbsolutePosition + g.AbsoluteSize end
	local function inter(a0, a1, b0, b1)
		local w = math.min(a1.X, b1.X) - math.max(a0.X, b0.X)
		local h = math.min(a1.Y, b1.Y) - math.max(a0.Y, b0.Y)
		return (w > 3 and h > 3) and w * h or 0
	end
	local function clipper(g)
		local o = g.Parent
		while o and o ~= sg do
			if o:IsA("GuiObject") and (o.ClipsDescendants or o:IsA("ScrollingFrame")) then return o end
			o = o.Parent
		end
	end
	local function nameOf(g) local n = g:GetFullName():gsub("^.-IdleCountryHUD%.", ""); return n end
	local texts, issues = {}, {}
	for _, g in ipairs(sg:GetDescendants()) do
		if (g:IsA("TextLabel") or g:IsA("TextButton")) and g.Text ~= "" and g.TextTransparency < 0.9 and shown(g) and g.AbsoluteSize.X > 2 then
			local c = clipper(g)
			local a0, a1 = rect(g)
			local visible = true
			if c then local c0, c1 = rect(c); visible = inter(a0, a1, c0, c1) > 0 end
			if visible then
				table.insert(texts, g)
				local plain = g.ContentText
				if not g.TextScaled and not g.TextWrapped and g.TextTruncate == Enum.TextTruncate.None and g.TextBounds.X > g.AbsoluteSize.X + 4 then
					table.insert(issues, { k = "overflow", n = nameOf(g), t = plain, need = math.floor(g.TextBounds.X), have = math.floor(g.AbsoluteSize.X) })
				elseif not g.TextFits and not g.TextScaled then
					table.insert(issues, { k = "nofit", n = nameOf(g), t = plain })
				end
				local vp = sg.AbsoluteSize
				if a1.X > vp.X + 2 or a1.Y > vp.Y + 2 or a0.X < -2 then
					table.insert(issues, { k = "offscreen", n = nameOf(g), t = plain })
				end
			end
		end
	end
	-- text on text (actual glyph boxes, not the label boxes)
	local function glyph(g)
		local a0 = g.AbsolutePosition
		local sz, tb = g.AbsoluteSize, g.TextBounds
		local w, h = math.min(tb.X, sz.X), math.min(tb.Y, sz.Y)
		local x = a0.X + (g.TextXAlignment == Enum.TextXAlignment.Left and 0 or g.TextXAlignment == Enum.TextXAlignment.Right and sz.X - w or (sz.X - w) / 2)
		local y = a0.Y + (g.TextYAlignment == Enum.TextYAlignment.Top and 0 or g.TextYAlignment == Enum.TextYAlignment.Bottom and sz.Y - h or (sz.Y - h) / 2)
		return Vector2.new(x, y), Vector2.new(x + w, y + h)
	end
	for i = 1, #texts do
		local a = texts[i]
		local a0, a1 = glyph(a)
		for j = i + 1, #texts do
			local b = texts[j]
			if not a:IsAncestorOf(b) and not b:IsAncestorOf(a) and a.Text ~= b.Text then
				local b0, b1 = glyph(b)
				if inter(a0, a1, b0, b1) > 20 then
					table.insert(issues, { k = "overlap", n = nameOf(a), t = a.ContentText, n2 = nameOf(b), t2 = b.ContentText })
				end
			end
		end
	end
	return HttpService:JSONEncode({ vp = { sg.AbsoluteSize.X, sg.AbsoluteSize.Y }, scale = uiScale.Scale, n = #texts, issues = issues })
end

-- Studio-only test hook: tools set LocalPlayer attribute IC_Cmd = "open:<screen>" | "close" | "login" | "settings"
if game:GetService("RunService"):IsStudio() then
	plr:GetAttributeChangedSignal("IC_Cmd"):Connect(function()
		local cmd = plr:GetAttribute("IC_Cmd")
		if type(cmd) ~= "string" then return end
		local k, arg = cmd:match("^(%w+):?(.*)$")
		pcall(function()
			if k == "open" then App.closeModal(); App.open(arg)
			elseif k == "close" then App.closeModal()
			elseif k == "login" and App.showLogin then App.showLogin()
			elseif k == "settings" and App.openSettings then App.openSettings(arg ~= "" and arg or nil)
			elseif k == "tester" and App.toggleTester then App.toggleTester()
			elseif k == "afk" and App.openAfk then App.openAfk()
			elseif k == "sounds" and App.soundBoard then App.soundBoard()
			elseif k == "profile" and App.showProfile then App.showProfile(tonumber(arg) or plr.UserId)
			elseif k == "emit" then App.emit(arg)
			elseif k == "vp" then
				local w, h = arg:match("(%d+)x(%d+)")
				fakeVp = w and Vector2.new(tonumber(w), tonumber(h)) or nil
				fit()
			elseif k == "audit" then plr:SetAttribute("IC_Audit", App.auditLayout()) end
		end)
	end)
end
