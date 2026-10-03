-- TESTER PANEL (Kash 2 Oct): owner only. A TEST button (and F2) opens a panel of quick buttons plus a command line.
-- Every button just sends the same text you could type, e.g. "/cash 1m". The server checks the owner again.
local UIS = game:GetService("UserInputService")

local S = {}

local GROUPS = {
	{ "PROGRESS", {
		{ "RESET (new player)", "/reset", "red" }, { "+10 LEVELS", "/levelup" }, { "LEVEL 30", "/level 30" }, { "LEVEL 100", "/level 100" },
		{ "NEXT ERA", "/era" }, { "+50K XP", "/xp 50k" }, { "WONDER +1", "/wonder" }, { "REPLAY ONBOARDING", "/onboard" },
	} },
	{ "MONEY", {
		{ "+$1M", "/cash 1m", "green" }, { "+$1B", "/cash 1b", "green" }, { "+$1T", "/cash 1t", "green" }, { "CASH TO 0", "/setcash 0" },
		{ "+500 GOLD", "/gold 500", "gold" }, { "+100 MERITS", "/merits 100", "gold" }, { "+1H INCOME", "/income 60" }, { "+$1M BANK", "/bank 1m" },
	} },
	{ "ENERGY", {
		{ "FILL INFLUENCE", "/inf", "blue" }, { "FILL SUPPLY", "/sup", "blue" }, { "EMPTY BOTH", "/drain" }, { "CLEAR LOAN", "/loan" },
	} },
	{ "ARMY AND OFFICERS", {
		{ "+50 TROOPS", "/army 50", "red" }, { "+500 TROOPS", "/army 500", "red" }, { "+5 ELITE", "/elite 5", "red" }, { "NO ARMY", "/noarmy" },
		{ "+1 OFFICER SLOT", "/slot" }, { "LEGENDARY OFFICER", "/officer legendary" }, { "MYTHIC GEAR", "/gear mythic" }, { "+5 FOUNDER CRATES", "/crates 5 founder", "gold" },
		{ "+5 SUPPLY CRATES", "/crates 5 basic" },
	} },
	{ "TIMERS AND EVENTS", {
		{ "FINISH CONVOYS", "/finish", "green" }, { "BOSS READY", "/boss" }, { "CLEAR RAID CD", "/raidcd" }, { "SHIELD 1H", "/shield 60" },
		{ "REMOVE SHIELD", "/shield 0" }, { "LOGIN REWARD", "/login" }, { "NEW ORDERS", "/tasks" }, { "OPEN WORLD EVENT", "/event", "gold" },
		{ "NORMAL EVENTS", "/noevent" },
	} },
	{ "SHOP AND ALLIANCE", {
		{ "STARTER PACK AGAIN", "/starter" }, { "BUNDLE AGAIN", "/bundle" }, { "PASSES OFF", "/passes off" }, { "PASSES ON", "/passes on" },
		{ "+500 ALLIANCE XP", "/allyxp 500" }, { "+$1M TREASURY", "/allytreasury 1m" }, { "SAVE NOW", "/save" }, { "HELP", "/help" },
	} },
}

S._tester = { init = function(App)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local open = false
	local btn, panel, log, box
	local history, hi = {}, 0

	local function addLog(s, color)
		if not log then return end
		local l = text(log, s, { size = 14, wrap = true, color = color or C.ink, sz = UDim2.new(1, -8, 0, 0), z = 93, auto = Enum.AutomaticSize.Y, order = os.clock() * 1000 })
		l.FontFace = Font.fromEnum(Enum.Font.Code)
		local kids = {}
		for _, k in ipairs(log:GetChildren()) do if k:IsA("TextLabel") then table.insert(kids, k) end end
		if #kids > 60 then kids[1]:Destroy() end
		task.defer(function() log.CanvasPosition = Vector2.new(0, 1e6) end)
	end

	local function run(line)
		line = (line or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if line == "" then return end
		if line:sub(1, 1) ~= "/" then line = "/" .. line end
		table.insert(history, line); hi = #history + 1
		-- shortcut commands that expand on the client
		if line == "/levelup" then line = "/level " .. ((App.state and App.state.lv or 1) + 10) end
		addLog("> " .. line, C.manila)
		if line:match("^/reset") then App.reonboard = true end
		local res = App.req("admin", { cmd = line })
		if res.ok then addLog(res.out or "Done", C.good) else addLog(res.msg or "Failed", C.bad); App.reonboard = nil end
	end

	local function build()
		local p, body = UI.panel(App.root, "TESTER PANEL", { sz = UDim2.fromOffset(720, 560), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 90, name = "TesterPanel" })
		panel = p
		panel.Visible = false
		UI.button(panel, "slate", "X", function() open = false; panel.Visible = false end, { pos = UDim2.new(1, -54, 0, 10), sz = UDim2.fromOffset(40, 36), z = 95, textSize = 16 })
		text(panel, "Owner only · F2 toggles", { size = 13, color = C.muted, pos = UDim2.new(1, -260, 0, 18), sz = UDim2.fromOffset(196, 20), z = 95, align = Enum.TextXAlignment.Right })

		local list = UI.list(body, { sz = UDim2.new(0.62, -6, 1, 0), z = 91, gap = 6 })
		for gi, g in ipairs(GROUPS) do
			text(list, g[1], { font = "heavy", size = 14, color = C.manila, sz = UDim2.new(1, 0, 0, 20), z = 92, order = gi * 100 })
			local grid = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 92, LayoutOrder = gi * 100 + 1 }, list)
			mk("UIGridLayout", { CellSize = UDim2.new(0.25, -5, 0, 34), CellPadding = UDim2.fromOffset(5, 5), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
			for i, b in ipairs(g[2]) do
				UI.button(grid, b[3] or "slate", b[1], function()
					if b[2] == "/reset" then
						App.confirm("RESET PROGRESS?", "This wipes your save and starts you again as a brand new player. Purchases you own stay.", "RESET", "red", function() run("/reset") end)
					else run(b[2]) end
				end, { z = 93, order = i, textSize = 12 })
			end
		end

		local right = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.62, 6, 0, 0), Size = UDim2.new(0.38, -6, 1, 0), ZIndex = 91 }, body)
		local logBg = mk("Frame", { BackgroundColor3 = C.black, BackgroundTransparency = 0.2, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -48), ZIndex = 91 }, right)
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }, logBg)
		log = UI.list(logBg, { pos = UDim2.fromOffset(6, 6), sz = UDim2.new(1, -12, 1, -12), z = 92, gap = 3 })
		box = mk("TextBox", { BackgroundColor3 = C.slate, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -40), Size = UDim2.new(1, -70, 0, 40), ZIndex = 93,
			FontFace = Font.fromEnum(Enum.Font.Code), TextSize = 16, TextColor3 = C.ink, PlaceholderText = "/reset, /cash 1m, /help", PlaceholderColor3 = C.dim,
			Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, right)
		mk("UICorner", { CornerRadius = UDim.new(0, 6) }, box)
		mk("UIPadding", { PaddingLeft = UDim.new(0, 8) }, box)
		local function submit() local t = box.Text; box.Text = ""; run(t) end
		box.FocusLost:Connect(function(enter) if enter then submit(); task.defer(function() box:CaptureFocus() end) end end)
		UI.button(right, "green", "RUN", submit, { pos = UDim2.new(1, -64, 1, -40), sz = UDim2.fromOffset(64, 40), z = 93, textSize = 15 })
		addLog("Tester panel ready. Type /help for every command.", C.muted)
	end

	local function toggle()
		if not (App.state and App.state.admin) then return end
		if not panel then build() end
		open = not open
		panel.Visible = open
		if open and box then task.defer(function() box:CaptureFocus() end) end
	end
	App.toggleTester = toggle

	local function ensureButton()
		if btn or not (App.state and App.state.admin) then return end
		btn = UI.button(App.root, "red", "TEST", toggle, { pos = UDim2.new(0, 8, 1, -46), sz = UDim2.fromOffset(72, 38), z = 89, textSize = 15, name = "TesterButton" })
	end
	App.on("full", function() ensureButton() end)
	ensureButton()

	UIS.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.F2 then toggle() end
	end)
	-- arrow keys walk the command history while typing
	UIS.InputBegan:Connect(function(input)
		if not (box and box:IsFocused()) or #history == 0 then return end
		if input.KeyCode == Enum.KeyCode.Up then hi = math.max(1, hi - 1); box.Text = history[hi] or ""
		elseif input.KeyCode == Enum.KeyCode.Down then hi = math.min(#history + 1, hi + 1); box.Text = history[hi] or "" end
	end)
end }

return S
