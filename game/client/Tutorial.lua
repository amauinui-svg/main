-- TUTORIAL (Kash 2 Oct): offered at the end of onboarding. A small guide card at the bottom of the screen and a
-- pulsing frame on the tab to open. It never blocks the game and can be skipped any time.
-- Progress is saved on the server (App.state.tut: step number, -1 = skipped or finished, nil = never offered).
local TweenService = game:GetService("TweenService")

local S = {}

local function trips(st) return st.stats and st.stats.trips or 0 end
local function built(st) for _, v in ipairs(st.lots or {}) do if v and v ~= 0 then return true end end return false end
local function sending(st)
	for _, c in ipairs(st.convoys or {}) do if c.to then return true end end
	return trips(st) > 0
end

-- each step: text, the tab to point at (or nil), and when it is done
local STEPS = {
	{ title = "PASS LAWS", text = "Open <b>LAWS</b>. Laws are how your nation makes money.", tab = "laws", done = function(st, App) return App.current == "laws" end },
	{ title = "YOUR FIRST LAW", text = "Tap <b>PASS</b> on a law. It costs Influence and pays cash and XP.", find = "pass", done = function(st) return (st.stats and st.stats.laws or 0) >= 1 end },
	{ title = "LEVEL UP", text = "Keep passing laws to reach <b>level 2</b>. Influence refills over time and on every level up.", find = "pass", done = function(st) return (st.lv or 1) >= 2 end },
	{ title = "PROPERTIES", text = "You unlocked <b>PROPERTIES</b>! Open it to earn money even while you are away.", tab = "properties", done = function(st, App) return App.current == "properties" end },
	{ title = "BUILD", text = "Tap an empty lot (<b>FOR SALE</b>) and build your first property. It pays you every hour.", find = "lot", done = function(st) return built(st) end },
	{ title = "THE WORLD", text = "Open the <b>WORLD</b> map. Your convoys trade between real capitals.", tab = "map", done = function(st, App) return App.current == "map" end },
	{ title = "SEND A CONVOY", text = "Tap a city, pick a load and <b>SEND</b>. Cities that want your goods pay more.", done = function(st) return sending(st) end },
	{ title = "YOU ARE READY", text = "New tabs unlock as you level up. Good luck, leader!", final = true },
}

S._tutorial = { init = function(App)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local card, titleL, bodyL, stepL, ring, ringTw, nextBtn
	local saving = -99

	local function save(step)
		if saving == step then return end
		saving = step
		task.spawn(function() App.req("tutorial", { step = step }) end)
		if App.state then App.state.tut = step end
	end

	-- SPOTLIGHT (Kash 23:23): darken everything except the thing to press, with a snug rounded gold frame around it
	local spot = {}
	local spotConn
	local function clearRing()
		if spotConn then spotConn:Disconnect(); spotConn = nil end
		for _, f in pairs(spot) do f:Destroy() end
		spot = {}
	end
	local function findTarget(S1)
		if S1.tab then
			local nb = App.navButtons and App.navButtons[S1.tab]
			return nb and nb.Inst.Visible and nb.Inst or nil
		end
		local scr
		if S1.find == "pass" then scr = App.screens and App.screens.laws
		elseif S1.find == "lot" then scr = App.screens and App.screens.properties end
		if not scr or not scr.host or not scr.host.Visible then return nil end
		local want = S1.find == "pass" and "PASS" or "FOR SALE"
		for _, d in ipairs(scr.host:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text == want and d.Visible then
				local b = d:FindFirstAncestorWhichIsA("GuiButton")
				if b and b.Visible and b.AbsoluteSize.X > 0 then
					-- only targets on screen (inside the scrolling list)
					local sf = b:FindFirstAncestorWhichIsA("ScrollingFrame")
					if not sf or (b.AbsolutePosition.Y >= sf.AbsolutePosition.Y and b.AbsolutePosition.Y + b.AbsoluteSize.Y <= sf.AbsolutePosition.Y + sf.AbsoluteSize.Y) then return b end
				end
			end
		end
		return nil
	end
	local function pointAt(S1)
		clearRing()
		if not S1.tab and not S1.find then return end
		local host = App.sg
		local function dim(name)
			local f = mk("Frame", { Name = "TutDim" .. name, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 50, Visible = false }, host)
			spot[name] = f
			return f
		end
		local top, bottom, left, right = dim("T"), dim("B"), dim("L"), dim("R")
		local ring = mk("Frame", { Name = "TutRing", BackgroundTransparency = 1, ZIndex = 51, Visible = false }, host)
		mk("UICorner", { CornerRadius = UDim.new(0, 10) }, ring)
		local st = mk("UIStroke", { Color = C.gold, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, ring)
		spot.ring = ring
		local t0 = os.clock()
		spotConn = game:GetService("RunService").RenderStepped:Connect(function()
			local target = findTarget(S1)
			local vis = target ~= nil and card and card.Visible
			for _, f in pairs(spot) do f.Visible = vis and true or false end
			if not vis then return end
			local pad = 6
			local p0, sz = target.AbsolutePosition - Vector2.new(pad, pad), target.AbsoluteSize + Vector2.new(pad * 2, pad * 2)
			local W, H = host.AbsoluteSize.X, host.AbsoluteSize.Y
			top.Position = UDim2.fromOffset(0, 0); top.Size = UDim2.fromOffset(W, math.max(0, p0.Y))
			bottom.Position = UDim2.fromOffset(0, p0.Y + sz.Y); bottom.Size = UDim2.fromOffset(W, math.max(0, H - p0.Y - sz.Y))
			left.Position = UDim2.fromOffset(0, p0.Y); left.Size = UDim2.fromOffset(math.max(0, p0.X), sz.Y)
			right.Position = UDim2.fromOffset(p0.X + sz.X, p0.Y); right.Size = UDim2.fromOffset(math.max(0, W - p0.X - sz.X), sz.Y)
			ring.Position = UDim2.fromOffset(p0.X, p0.Y); ring.Size = UDim2.fromOffset(sz.X, sz.Y)
			local k = (math.sin((os.clock() - t0) * 5) + 1) / 2
			st.Thickness = 3 + 2 * k
			st.Transparency = 0.15 * k
			-- keep the guide card away from the target
			local wantTop = p0.Y + sz.Y / 2 > H * 0.55
			local cy = wantTop and UDim2.new(0, 96, 0, 0) or UDim2.new(1, -18, 0, 0)
			card.AnchorPoint = Vector2.new(0.5, wantTop and 0 or 1)
			card.Position = UDim2.new(0.5, (App.NAVW or 176) / 2, cy.X.Scale, cy.X.Offset)
		end)
	end

	local function hide()
		clearRing()
		if card then card.Visible = false end
	end

	local function finish(skipped)
		hide()
		save(-1)
		if skipped then App.toast("Tutorial skipped", "The GAME GUIDE in Settings explains everything", "info") end
	end

	local function build()
		card = UI.img(App.sg or App.root, "panel", { name = "Tutorial", sz = UDim2.fromOffset(520, 118), pos = UDim2.new(0.5, (App.NAVW or 176) / 2, 1, -18), anchor = Vector2.new(0.5, 1), z = 70 })
		UI.outline(card, C.gold, 2)
		UI.icon(card, "icon_sparkles", 26, C.gold, UDim2.fromOffset(16, 16), { z = 71 })
		titleL = text(card, "", { font = "display", size = 20, color = C.manila, pos = UDim2.fromOffset(50, 12), sz = UDim2.new(1, -170, 0, 26), z = 71 })
		stepL = text(card, "", { font = "heavy", size = 12, color = C.muted, pos = UDim2.new(1, -116, 0, 16), sz = UDim2.fromOffset(100, 18), z = 71, align = Enum.TextXAlignment.Right })
		bodyL = text(card, "", { size = 16, rich = true, wrap = true, pos = UDim2.fromOffset(18, 42), sz = UDim2.new(1, -150, 0, 64), z = 71, valign = Enum.TextYAlignment.Top })
		nextBtn = UI.button(card, "green", "GOT IT", function() finish(false) end, { pos = UDim2.new(1, -14, 1, -14), anchor = Vector2.new(1, 1), sz = UDim2.fromOffset(116, 38), z = 72, textSize = 15 })
		UI.button(card, "slate", "SKIP", function() finish(true) end, { pos = UDim2.new(1, -14, 1, -14), anchor = Vector2.new(1, 1), sz = UDim2.fromOffset(116, 38), z = 72, textSize = 14, name = "Skip" })
	end

	local shown = 0
	local function update()
		local st = App.state
		if not st or not st.onboarded or type(st.tut) ~= "number" or st.tut < 0 then hide(); return end
		local step = st.tut + 1
		-- skip ahead past anything already done (rejoins, players who explore on their own)
		while STEPS[step] and STEPS[step].done and STEPS[step].done(st, App) do step += 1 end
		if step - 1 ~= st.tut then save(step - 1) end
		local S1 = STEPS[step]
		if not S1 then finish(false); return end
		if not card then build() end
		card.Visible = true
		titleL.Text = S1.title
		bodyL.Text = S1.text
		stepL.Text = "TUTORIAL " .. math.min(step, #STEPS) .. "/" .. #STEPS
		nextBtn.Inst.Visible = S1.final == true
		local skip = card:FindFirstChild("Skip")
		if skip then skip.Visible = not S1.final end
		if shown ~= step then
			shown = step
			pointAt(S1)
			card.AnchorPoint = Vector2.new(0.5, 1)
			card.Position = UDim2.new(0.5, (App.NAVW or 176) / 2, 1, -18)
			local sc = card:FindFirstChildOfClass("UIScale") or mk("UIScale", {}, card)
			sc.Scale = 0.85
			TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
			if App.play and step > 1 then pcall(App.play, "tab_open") end
		end
	end
	App.tutorialUpdate = update

	-- asked once at the end of onboarding
	function App.askTutorial()
		local host = mk("TextButton", { Name = "TutorialAsk", Text = "", AutoButtonColor = false, BackgroundColor3 = C.black, BackgroundTransparency = 0.4, Size = UDim2.fromScale(1, 1), ZIndex = 88 }, App.root)
		local pnl, b = UI.panel(host, "WELCOME, LEADER", { sz = UDim2.fromOffset(500, 250), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 89 })
		local _ = pnl
		text(b, "Would you like a quick tutorial? It takes about two minutes and shows you how to grow your nation.", { size = 18, wrap = true, sz = UDim2.new(1, 0, 0, 90), z = 90, valign = Enum.TextYAlignment.Top })
		UI.button(b, "slate", "NO THANKS", function() host:Destroy(); save(-1) end, { pos = UDim2.new(0, 0, 1, -48), sz = UDim2.fromOffset(170, 46), z = 90, textSize = 16 })
		UI.button(b, "green", "YES, SHOW ME", function() host:Destroy(); save(0); update() end, { pos = UDim2.new(1, 0, 1, -48), anchor = Vector2.new(1, 0), sz = UDim2.fromOffset(220, 46), z = 90, textSize = 17 })
	end

	App.on("full", function() update() end)
	task.spawn(function()
		while true do
			task.wait(0.5)
			if card and card.Visible then pcall(update) end
		end
	end)
	update()
end }

return S
