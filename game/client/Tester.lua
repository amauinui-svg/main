-- TESTER PANEL (Kash 2 Oct): owner only. A TEST button (and F2) opens a panel of quick buttons plus a command line.
-- Every button just sends the same text you could type, e.g. "/cash 1m". The server checks the owner again.
local UIS = game:GetService("UserInputService")

local S = {}

local GROUPS = {
	{ "PROGRESS", {
		{ "RESET (new player)", "/reset", "red" }, { "+10 LEVELS", "/levelup" }, { "LEVEL 30", "/level 30" }, { "LEVEL 100", "/level 100" },
		{ "NEXT ERA", "/era" }, { "+50K XP", "/xp 50k" }, { "WONDER +1", "/wonder" }, { "REPLAY ONBOARDING", "/onboard" }, { "RESTART TUTORIAL", "/tutorial" },
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
	{ "SOUNDS", {
		{ "SOUND BOARD", "#sounds", "blue" }, { "AFK CHAMBER", "#afk", "blue" },
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
					if b[2] == "#sounds" then if App.soundBoard then App.soundBoard() end
					elseif b[2] == "#afk" then open = false; if panel then panel.Visible = false end; if App.openAfk then App.openAfk() end
					elseif b[2] == "/reset" then
						App.confirm("RESET PROGRESS?", "This wipes your save and starts you again as a brand new player. Purchases you own stay.", "RESET", "red", function() run("/reset") end)
					else run(b[2]) end
				end, { z = 93, order = i, textSize = 12 })
			end
		end

		local right = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0.62, 6, 0, 0), Size = UDim2.new(0.38, -6, 1, 0), ZIndex = 91 }, body)
		local logBg = UI.img(right, "inset", { name = "Log", sz = UDim2.new(1, 0, 1, -48), z = 91 })
		log = UI.list(logBg, { pos = UDim2.fromOffset(6, 6), sz = UDim2.new(1, -12, 1, -12), z = 92, gap = 3 })
		-- command line on the kit's input plate
		local boxBg = UI.img(right, "input", { name = "Command", pos = UDim2.new(0, 0, 1, -40), sz = UDim2.new(1, -70, 0, 40), z = 92 })
		box = mk("TextBox", { BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), ZIndex = 93,
			FontFace = Font.fromEnum(Enum.Font.Code), TextSize = 16, TextColor3 = C.ink, PlaceholderText = "/reset, /cash 1m, /help", PlaceholderColor3 = C.dim,
			Text = "", ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left }, boxBg)
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

	-- SOUND BOARD (Kash 23:48: preview sounds before they go in). Current sounds by key, plus candidates to pick from.
	local CANDIDATES = {
		{ "DEFEAT (raid lost)", { { "A", 125909120236588, "Mounting Consequences sting (in use)" }, { "B", 116298781032555, "Sad trombone" }, { "C", 1837950656, "Brute Force sting" }, { "D", 97861773515321, "Lose arcade" }, { "E", 115055593775910, "Old defeat sound" } } },
		{ "MYTHIC / SECRET / FORBIDDEN REVEAL", { { "A", 9047100306, "Hustler sting (mythic)" }, { "B", 9047103106, "All It Takes sting (secret)" }, { "C", 1836860398, "Winning Spirit (forbidden)" }, { "D", 73774648241042, "Rating excellent" }, { "E", 135385970610304, "Twinkle" }, { "F", 134527763388412, "Current legendary" } } },
	}
	local board
	function App.soundBoard()
		if board then board:Destroy(); board = nil; return end
		local p, body = UI.panel(App.sg or App.root, "SOUND BOARD", { sz = UDim2.fromOffset(640, 560), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 95, name = "SoundBoard" })
		board = p
		UI.button(p, "slate", "X", function() p:Destroy(); board = nil end, { pos = UDim2.new(1, -54, 0, 10), sz = UDim2.fromOffset(40, 36), z = 99, textSize = 16 })
		local list = UI.list(body, { z = 96, gap = 6 })
		local order = 0
		local function head(t) order += 1; text(list, t, { font = "heavy", size = 15, color = C.manila, sz = UDim2.new(1, 0, 0, 22), z = 97, order = order }) end
		head("CANDIDATES: tell Claude the letter you like")
		for _, g in ipairs(CANDIDATES) do
			order += 1
			text(list, g[1], { font = "bold", size = 14, color = C.muted, sz = UDim2.new(1, 0, 0, 18), z = 97, order = order })
			for _, c in ipairs(g[2]) do
				order += 1
				local row = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 34), ZIndex = 97, LayoutOrder = order }, list)
				UI.button(row, "green", "PLAY " .. c[1], function() App.sfxPreview(c[2]) end, { sz = UDim2.fromOffset(110, 32), z = 98, textSize = 13 })
				text(row, c[3], { size = 14, pos = UDim2.fromOffset(122, 0), sz = UDim2.new(1, -122, 1, 0), z = 98, truncate = true })
			end
		end
		head("EVERY SOUND IN THE GAME")
		for _, k in ipairs(App.sfxKeys and App.sfxKeys() or {}) do
			order += 1
			local row = mk("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 34), ZIndex = 97, LayoutOrder = order }, list)
			UI.button(row, "slate", "PLAY", function() App.sfx(k) end, { sz = UDim2.fromOffset(90, 32), z = 98, textSize = 13 })
			text(row, k, { size = 14, pos = UDim2.fromOffset(102, 0), sz = UDim2.new(1, -102, 1, 0), z = 98 })
		end
	end

	local function ensureButton()
		if btn or not (App.state and App.state.admin) then return end
		btn = UI.button(App.root, "red", "TEST", toggle, { pos = UDim2.new(1, -86, 1, -48), sz = UDim2.fromOffset(72, 38), z = 89, textSize = 15, name = "TesterButton" })
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
