-- AFK CHAMBER (Kash 3 Oct): after 15 minutes with no input the whole screen becomes the chamber: the world map,
-- what your properties are earning, and a slim chance every minute to find gear. RETURN brings you back.
-- While it is up, Roblox's 20 minute idle kick is prevented.
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local R = require(Shared.Rules)
local O = require(Shared.Officers)
local Config = require(Shared.Config)

local S = {}

S._afk = { init = function(App)
	local UI = App.UI
	local C = UI.C
	local mk, text = UI.mk, UI.text
	local plr = Players.LocalPlayer
	local lastInput = os.clock()
	local open, gui, startCash, startT, findList, earnedL, timeL, incL
	local finds = {}

	local function touch() lastInput = os.clock() end
	UIS.InputBegan:Connect(touch)
	UIS.InputChanged:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then touch() end end)

	-- keep Roblox from kicking an idle player while the chamber is up
	plr.Idled:Connect(function()
		if not open then return end
		pcall(function()
			local VU = game:GetService("VirtualUser")
			VU:CaptureController()
			VU:ClickButton2(Vector2.new())
		end)
	end)

	local function drawFinds()
		if not findList then return end
		UI.clear(findList)
		if #finds == 0 then
			text(findList, "Nothing found yet. Keep your nation running!", { size = 15, color = C.muted, sz = UDim2.new(1, 0, 0, 24), z = 214, align = Enum.TextXAlignment.Center })
			return
		end
		for k = #finds, math.max(1, #finds - 5), -1 do
			local g = finds[k]
			local rar = O.RarityByKey[g.rarity] or O.Rarities[1]
			local row = UI.card(findList, { sz = UDim2.new(1, -6, 0, 44), z = 213, order = #finds - k })
			UI.img(row, g.icon or "gear_sword", { sz = UDim2.fromOffset(34, 34), pos = UDim2.fromOffset(8, 5), z = 214, slice = false, fit = true })
			text(row, g.name or "Gear", { font = "heavy", size = 15, pos = UDim2.fromOffset(50, 0), sz = UDim2.new(1, -170, 1, 0), z = 214, truncate = true })
			UI.tag(row, rar.name, Color3.fromHex(rar.color), { pos = UDim2.new(1, -10, 0.5, 0), anchor = Vector2.new(1, 0.5), z = 214 })
		end
	end

	local function close()
		if not open then return end
		open = false
		lastInput = os.clock()
		local n = #finds
		if gui then
			local g = gui
			gui = nil
			TweenService:Create(g, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			task.delay(0.25, function() g:Destroy() end)
		end
		task.spawn(function()
			local res = App.req("afk", { on = false })
			local earned = (App.state and App.state.cash or 0) - (startCash or 0)
			App.toast("WELCOME BACK!", (earned > 0 and ("+" .. R.Money(earned) .. " while you were away") or "Your nation kept working") .. (n > 0 and (" · " .. n .. " item" .. (n > 1 and "s" or "") .. " found") or ""), "gold")
			local _ = res
		end)
	end

	local function openChamber()
		if open or not (App.state and App.state.onboarded) then return end
		open = true
		finds = {}
		startCash = App.state.cash or 0
		startT = os.clock()
		if App.closeModal then pcall(App.closeModal) end
		task.spawn(function() App.req("afk", { on = true }) end)
		gui = mk("Frame", { Name = "AfkChamber", BackgroundColor3 = C.black, BackgroundTransparency = 0, Size = UDim2.fromScale(1, 1), ZIndex = 200, Active = true }, App.sg)
		local map = UI.img(gui, "map_world", { slice = false, pixel = true, sz = UDim2.fromScale(1, 1), z = 201 })
		map.ScaleType = Enum.ScaleType.Crop
		map.ImageTransparency = 0.25
		mk("Frame", { BackgroundColor3 = C.black, BackgroundTransparency = 0.45, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 202 }, gui)
		local p, body = UI.panel(gui, "AFK CHAMBER", { sz = UDim2.fromOffset(560, 520), pos = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 210, titleSize = 30 })
		mk("UISizeConstraint", { MaxSize = Vector2.new(560, 520) }, p)
		p.Size = UDim2.new(1, -40, 1, -40)
		text(body, "You're away, but your nation keeps working!", { size = 16, color = C.muted, sz = UDim2.new(1, 0, 0, 22), z = 212, align = Enum.TextXAlignment.Center })
		local stats = mk("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 86), ZIndex = 212 }, body)
		mk("UIGridLayout", { CellSize = UDim2.new(1 / 3, -8, 1, 0), CellPadding = UDim2.fromOffset(12, 0), SortOrder = Enum.SortOrder.LayoutOrder }, stats)
		local function stat(order, label, color)
			local c = UI.card(stats, { z = 213, order = order })
			text(c, label, { font = "heavy", size = 13, color = C.muted, pos = UDim2.fromOffset(0, 10), sz = UDim2.new(1, 0, 0, 18), z = 214, align = Enum.TextXAlignment.Center })
			return text(c, "", { font = "display", size = 26, color = color, pos = UDim2.fromOffset(6, 34), sz = UDim2.new(1, -12, 0, 34), z = 214, align = Enum.TextXAlignment.Center, scaled = true })
		end
		incL = stat(1, "INCOME", C.good)
		earnedL = stat(2, "EARNED HERE", C.gold)
		timeL = stat(3, "TIME AWAY", C.ink)
		text(body, "ITEMS FOUND", { font = "heavy", size = 15, color = C.manila, pos = UDim2.fromOffset(0, 128), sz = UDim2.new(1, 0, 0, 20), z = 212 })
		text(body, "Every minute there's a chance to find gear. Rare finds are VERY rare!", { size = 13, color = C.muted, pos = UDim2.fromOffset(0, 148), sz = UDim2.new(1, 0, 0, 18), z = 212 })
		findList = UI.list(body, { pos = UDim2.fromOffset(0, 172), sz = UDim2.new(1, 0, 1, -172 - 70), gap = 6, z = 212 })
		drawFinds()
		UI.button(body, "green", "RETURN", function() close() end, { pos = UDim2.new(0.5, 0, 1, -4), anchor = Vector2.new(0.5, 1), sz = UDim2.fromOffset(260, 58), z = 214, textSize = 24 })
		gui.BackgroundTransparency = 1
		TweenService:Create(gui, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
	end
	App.openAfk = openChamber

	function App.afkFind(n)
		local g = n.gear or {}
		table.insert(finds, g)
		drawFinds()
		local rar = O.RarityByKey[g.rarity]
		if rar and rar.index >= 5 and App.sfx then pcall(App.sfx, rar.index >= 8 and "reveal_forbidden" or rar.index >= 7 and "reveal_secret" or rar.index >= 6 and "reveal_mythic" or "reveal_legendary") end
	end

	task.spawn(function()
		while true do
			task.wait(1)
			if open and gui then
				local st = App.state or {}
				incL.Text = R.Money(st.incHr or 0) .. "/hr"
				earnedL.Text = R.Money(math.max(0, (st.cash or 0) - (startCash or 0)))
				local s = math.floor(os.clock() - startT)
				timeL.Text = string.format("%d:%02d", s // 60, s % 60)
			elseif not open and os.clock() - lastInput >= ((Config.Afk and Config.Afk.IdleSeconds) or 900) then
				openChamber()
			end
		end
	end)
end }

return S
