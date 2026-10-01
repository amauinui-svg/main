-- War screens: MILITARY (recruit units), BATTLE (rival nations), BOSSES.
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local D = require(Shared.GameData)
local R = require(Shared.Rules)
local M = require(Shared.Military)

local S = {}
local function frame(host, App, title)
	local UI = App.UI
	local panel, body = UI.panel(host, title, { sz = UDim2.new(1, -20, 1, -20), pos = UDim2.fromOffset(10, 10), z = 5, titleSize = 26 })
	local sub = UI.text(panel, "", { font = "bold", size = 15, color = UI.C.muted, pos = UDim2.new(0, 18, 0, 16), sz = UDim2.new(1, -36, 0, 22), z = 7, align = Enum.TextXAlignment.Right, rich = true })
	return panel, body, sub
end

---------------------------------------------------------------- MILITARY
S.military = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "MILITARY")
	local list = UI.list(body, { gap = 8, z = 6 })
	local obj = {}
	function obj:Refresh(st)
		UI.clear(list)
		local count = M.UnitCount(st.units)
		local cap = M.UnitCap(st.lv)
		sub.Text = "Attack <font color='#e2695f'><b>" .. R.Short(st.atk) .. "</b></font> · Defense <font color='#7fb0e6'><b>" .. R.Short(st.def) .. "</b></font> · Army <b>" .. count .. "/" .. cap .. "</b> (+1 room per level)"
		local shown = {}
		for i, u in ipairs(M.Units) do
			if u.lvl <= st.lv or (st.units[tostring(i)] or 0) > 0 then table.insert(shown, i) end
		end
		local nextLocked
		for i, u in ipairs(M.Units) do if u.lvl > st.lv then nextLocked = i; break end end
		table.sort(shown, function(a, b) return a > b end)
		if nextLocked then table.insert(shown, 1, nextLocked) end
		for order, i in ipairs(shown) do
			local u = M.Units[i]
			local owned = st.units[tostring(i)] or 0
			local locked = u.lvl > st.lv
			local cost = M.UnitCost(i, owned)
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 70), z = 7, order = order })
			UI.icon(card, locked and "icon_lock" or u.icon, 30, locked and C.dim or C.manila, UDim2.fromOffset(14, 20), { z = 8 })
			text(card, u.name .. (owned > 0 and ("  <font color='#9a9fa6'>x" .. owned .. "</font>") or ""), { font = "heavy", size = 18, rich = true, pos = UDim2.fromOffset(58, 8), sz = UDim2.new(0.38, -58, 0, 24), z = 8, truncate = true })
			text(card, D.Eras[u.era].name .. (locked and (" · unlocks at level " .. u.lvl) or ""), { size = 13, color = C.muted, pos = UDim2.fromOffset(58, 36), sz = UDim2.new(0.38, -58, 0, 18), z = 8 })
			text(card, "<font color='#e2695f'>ATK " .. R.Short(u.atk) .. "</font>   <font color='#7fb0e6'>DEF " .. R.Short(u.def) .. "</font>", { font = "heavy", size = 16, rich = true, pos = UDim2.new(0.38, 0, 0, 10), sz = UDim2.new(0.22, 0, 0, 22), z = 8 })
			text(card, "Each costs 6% more than the last", { size = 12, color = C.muted, pos = UDim2.new(0.38, 0, 0, 36), sz = UDim2.new(0.25, 0, 0, 18), z = 8 })
			if locked then
				UI.button(card, "locked", "LEVEL " .. u.lvl, nil, { pos = UDim2.new(1, -170, 0, 14), sz = UDim2.fromOffset(160, 42), z = 9 })
			else
				UI.button(card, (st.cash >= cost and count < cap) and "green" or "slate", "RECRUIT " .. R.Money(cost), function(btn)
					local res = App.req("unit", { i = i, n = 1 }, btn)
					if res.ok then App.float(btn.Inst, "+1 " .. u.name, C.good) end
				end, { pos = UDim2.new(1, -244, 0, 14), sz = UDim2.fromOffset(176, 42), z = 9, textSize = 15 })
				UI.button(card, "slate", "x10", function(btn)
					local res = App.req("unit", { i = i, n = 10 }, btn)
					if res.ok then App.float(btn.Inst, "+" .. res.bought, C.good) end
				end, { pos = UDim2.new(1, -62, 0, 14), sz = UDim2.fromOffset(52, 42), z = 9, textSize = 15 })
				if owned > 0 then
					local d = UI.button(card, "red", "-", function(btn) App.req("disband", { i = i }, btn) end, { pos = UDim2.new(1, -290, 0, 18), sz = UDim2.fromOffset(38, 34), z = 9 })
				end
			end
		end
	end
	return obj
end }

---------------------------------------------------------------- BATTLE
S.battle = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "BATTLE")
	local list = UI.list(body, { pos = UDim2.fromOffset(0, 52), sz = UDim2.new(1, 0, 1, -52), gap = 8, z = 6 })
	local obj = {}
	local refresh = UI.button(body, "slate", "NEW RIVALS", function(btn) App.req("rivals", { refresh = true }, btn) end, { sz = UDim2.fromOffset(170, 40), z = 7, icon = "icon_flag", textSize = 15 })
	UI.text(body, "Each attack costs " .. M.BattleSupply .. " Supply. Win to take their treasury and XP. Losing only costs the Supply.", { size = 14, color = C.muted, pos = UDim2.fromOffset(184, 0), sz = UDim2.new(1, -184, 0, 40), z = 7, wrap = true })
	function obj:Opened() if not App.state.rivals or App.now() - App.state.rivals.t > 600 then App.req("rivals", {}) end end
	function obj:Refresh(st)
		UI.clear(list)
		sub.Text = "Supply <font color='#6fb3c8'><b>" .. st.sup .. "/" .. st.supMax .. "</b></font> · Your attack <b>" .. R.Short(st.atk) .. "</b>"
		if not st.rivals then return end
		for i, rv in ipairs(st.rivals.list) do
			local chance = M.WinChance(st.atk, rv.def)
			local card = UI.card(list, { sz = UDim2.new(1, 0, 0, 76), z = 7, order = i })
			UI.flag(card, rv.flag, 54, { pos = UDim2.fromOffset(14, 20), z = 8 })
			text(card, rv.name, { font = "display", size = 20, pos = UDim2.fromOffset(80, 8), sz = UDim2.new(0.42, -80, 0, 26), z = 8, truncate = true })
			text(card, "Level " .. rv.lv .. " · Defense " .. R.Short(rv.def), { size = 14, color = C.muted, pos = UDim2.fromOffset(80, 40), sz = UDim2.new(0.42, -80, 0, 20), z = 8 })
			local col = chance >= 0.7 and "#8fd07a" or (chance >= 0.45 and "#f0c75a" or "#e2695f")
			text(card, "<font color='" .. col .. "'><b>" .. math.floor(chance * 100 + 0.5) .. "% WIN</b></font>", { font = "heavy", size = 18, rich = true, pos = UDim2.new(0.42, 0, 0, 10), sz = UDim2.new(0.2, 0, 0, 24), z = 8 })
			text(card, "+" .. R.Money(rv.reward) .. " if you win", { size = 14, color = C.good, pos = UDim2.new(0.42, 0, 0, 40), sz = UDim2.new(0.25, 0, 0, 20), z = 8 })
			if rv.beaten then
				UI.button(card, "locked", "DEFEATED", nil, { pos = UDim2.new(1, -170, 0, 16), sz = UDim2.fromOffset(160, 44), z = 9 })
			else
				UI.button(card, st.sup >= M.BattleSupply and "red" or "locked", "ATTACK", function(btn)
					local res = App.req("battle", { i = i }, btn)
					if res.ok then
						if res.win then App.toast("VICTORY OVER " .. string.upper(rv.name), "+" .. R.Money(res.cash) .. " · +" .. res.xp .. " XP", "good")
						else App.toast("DEFEAT", "Their defense held (" .. math.floor(res.chance * 100 + 0.5) .. "% chance). Build your army in Military.", "bad") end
					end
				end, { pos = UDim2.new(1, -170, 0, 16), sz = UDim2.fromOffset(160, 44), z = 9, icon = "icon_attack" })
			end
		end
	end
	return obj
end }

---------------------------------------------------------------- BOSSES
S.bosses = { build = function(host, App)
	local UI = App.UI
	local C = UI.C
	local text = UI.text
	local _, body, sub = frame(host, App, "BOSSES")
	local obj = {}
	local card = UI.card(body, { sz = UDim2.new(1, 0, 0, 330), z = 6 })
	local name = text(card, "", { font = "display", size = 34, color = C.manila, pos = UDim2.fromOffset(24, 18), sz = UDim2.new(1, -48, 0, 40), z = 7 })
	local desc = text(card, "", { size = 17, color = C.muted, pos = UDim2.fromOffset(24, 62), sz = UDim2.new(1, -48, 0, 22), z = 7 })
	UI.icon(card, "icon_bosses", 90, C.bad, UDim2.new(1, -120, 0, 20), { z = 7 })
	local hp = UI.bar(card, C.bad, { pos = UDim2.fromOffset(24, 110), sz = UDim2.new(1, -160, 0, 34), z = 7, textSize = 17 })
	local info = text(card, "", { size = 16, rich = true, pos = UDim2.fromOffset(24, 156), sz = UDim2.new(1, -48, 0, 50), z = 7, wrap = true, valign = Enum.TextYAlignment.Top })
	local btns = UI.mk("Frame", { BackgroundTransparency = 1, Position = UDim2.new(0, 24, 1, -76), Size = UDim2.new(1, -48, 0, 54), ZIndex = 7 }, card)
	local function hit(n) return function(btn)
		local res = App.req("bossHit", { n = n }, btn)
		if res.ok then App.float(btn.Inst, "-" .. R.Short(res.dmg), C.bad) end
	end end
	local b1 = UI.button(btns, "red", "HIT · 1 SUPPLY", hit(1), { sz = UDim2.new(0.4, -6, 1, 0), z = 8, icon = "icon_attack" })
	local b5 = UI.button(btns, "red", "x5", hit(5), { sz = UDim2.new(0.2, -6, 1, 0), pos = UDim2.new(0.4, 0, 0, 0), z = 8 })
	local bm = UI.button(btns, "red", "ALL SUPPLY", hit(50), { sz = UDim2.new(0.4, 0, 1, 0), pos = UDim2.new(0.6, 0, 0, 0), z = 8 })
	local skip = UI.button(btns, "gold", "SKIP WAIT · 3 GOLD", function(btn) App.req("bossSkip", {}, btn) end, { sz = UDim2.fromScale(1, 1), z = 9, icon = "icon_gold" })
	local list = UI.list(body, { pos = UDim2.fromOffset(0, 344), sz = UDim2.new(1, 0, 1, -344), gap = 6, z = 6 })
	function obj:Refresh(st)
		local boss = st.boss
		if not boss then return end
		local B = M.Bosses[boss.era]
		name.Text = string.upper(B[1])
		desc.Text = B[2] .. " · " .. D.Eras[boss.era].name .. " era"
		local max = M.BossHp(boss.era)
		hp:Set(boss.hp / max, R.Short(boss.hp) .. " / " .. R.Short(max) .. " HP", "")
		local per = M.BossDamage(st.atk)
		info.Text = string.format("Each hit deals about <b>%s</b> (3x your attack %s). Reward: <font color='#f0c75a'><b>%d gold</b></font>, <font color='#8fd07a'><b>%s</b></font> and XP. A new boss arrives an hour after each kill.",
			R.Short(per), R.Short(st.atk), M.BossGold[boss.era], R.Money(R.MinuteValue(st.lv) * 20))
		sub.Text = "Supply <font color='#6fb3c8'><b>" .. st.sup .. "/" .. st.supMax .. "</b></font> · Bosses defeated <b>" .. st.stats.bosses .. "</b>"
		UI.clear(list)
		for e, Bx in ipairs(M.Bosses) do
			local row = UI.card(list, { sz = UDim2.new(1, 0, 0, 34), z = 7, order = e })
			text(row, (e == boss.era and "▶ " or "") .. Bx[1], { font = "heavy", size = 15, color = e <= R.EraOf(st.lv) and C.ink or C.dim, pos = UDim2.fromOffset(12, 0), sz = UDim2.new(0.5, 0, 1, 0), z = 8 })
			text(row, D.Eras[e].name .. " · " .. R.Short(M.BossHp(e)) .. " HP · " .. M.BossGold[e] .. " gold", { size = 14, color = C.muted, pos = UDim2.new(0.5, 0, 0, 0), sz = UDim2.new(0.5, -12, 1, 0), z = 8, align = Enum.TextXAlignment.Right })
		end
		obj:Tick(st)
	end
	function obj:Tick(st)
		st = st or App.state
		local boss = st and st.boss
		if not boss then return end
		local wait = (boss.next or 0) - App.now()
		local resting = wait > 0
		skip.Inst.Visible = resting
		b1.Inst.Visible = not resting; b5.Inst.Visible = not resting; bm.Inst.Visible = not resting
		if resting then skip:Set(st.gold >= 3 and "gold" or "locked", "NEXT BOSS IN " .. R.Clock(wait) .. " · SKIP 3 GOLD") end
		local k = st.sup > 0 and "red" or "locked"
		b1:Set(k); b5:Set(k); bm:Set(k)
	end
	return obj
end }

return S
