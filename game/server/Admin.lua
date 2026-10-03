-- TESTER PANEL (Kash 2 Oct): owner-only commands. Every command goes through act.admin, which checks IsAdmin first.
-- Typed as "/reset", "/cash 1m", "/level 50" etc. The client panel buttons send the same strings.
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local D = require(RS.Shared.GameData)
local R = require(RS.Shared.Rules)
local M = require(RS.Shared.Military)
local O = require(RS.Shared.Officers)
local Events = require(RS.Shared.Events)

local AD = {}
local PS, WS, RA

AD.Owners = { [250229074] = true } -- Kash
function AD.Init(ps, ws, ra) PS, WS, RA = ps, ws, ra end

function AD.IsAdmin(plr)
	if not plr then return false end
	if AD.Owners[plr.UserId] then return true end
	if game.CreatorType == Enum.CreatorType.User and game.CreatorId == plr.UserId then return true end
	return RunService:IsStudio() -- Studio test players (Player1, Player2) can use it too
end

-- "1.5k" "2m" "3b" "1e6" -> number
local MULT = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, q = 1e15 }
local function num(s, default)
	if s == nil then return default end
	s = tostring(s):lower():gsub(",", "")
	local n, suf = s:match("^(%-?[%d%.e%+]+)(%a?)$")
	n = tonumber(n)
	if not n or n ~= n or math.abs(n) == math.huge then return default end
	return n * (MULT[suf] or 1)
end

local C = {}  -- [name] = { help, fn(plr, p, args) -> text }
local ORDER = {}
local function cmd(name, help, fn) C[name] = { help = help, fn = fn }; table.insert(ORDER, name) end

local function fresh(p)
	local d = p.data
	local keep = { receipts = d.receipts, appliedHits = d.appliedHits, ownedPasses = d.ownedPasses, created = d.created }
	local nd = PS.Fresh()
	for k, v in pairs(keep) do nd[k] = v end
	p.data = PS._sanitize(nd)
end

---------------------------------------------------------------- progress
cmd("reset", "Wipe your save. You start again as a brand new player (onboarding included).", function(plr, p)
	local d = p.data
	if d.alliance and WS then pcall(WS.Leave, plr, d.alliance, d.name) end
	fresh(p)
	p.raidCd = {}; p.sentTo = {}; p.notes = {}
	if RA and RA.SetShield then pcall(RA.SetShield, plr.UserId, 0) end
	PS.MigrateOfficers(p)
	PS.Market.CheckPasses(plr, p)
	p.xpMult = PS.Mods(p).xp
	PS.EnsureTasks(p)
	PS.EnsureConvoys(p)
	return "Progress reset. Welcome, new player."
end)
cmd("cash", "/cash 1m  add cash (k, m, b, t work). Negative removes.", function(_, p, a)
	local n = num(a[1], 1e6); p.data.cash = math.max(0, p.data.cash + n); return "Cash " .. R.Money(p.data.cash)
end)
cmd("setcash", "/setcash 0  set cash to an exact amount", function(_, p, a)
	p.data.cash = math.max(0, num(a[1], 0)); return "Cash " .. R.Money(p.data.cash)
end)
cmd("gold", "/gold 500  add gold", function(_, p, a)
	p.data.gold = math.max(0, p.data.gold + math.floor(num(a[1], 500))); return "Gold " .. p.data.gold
end)
cmd("merits", "/merits 100  add Merits", function(_, p, a)
	p.data.seals = math.max(0, (p.data.seals or 0) + math.floor(num(a[1], 100))); return "Merits " .. p.data.seals
end)
cmd("xp", "/xp 5000  add XP (levels up normally)", function(_, p, a)
	PS.AddXp(p, math.floor(num(a[1], 1000)), false); return "Level " .. p.data.lv
end)
cmd("level", "/level 50  jump to a level (keeps your era: pay to advance)", function(_, p, a)
	local d = p.data
	d.lv = math.clamp(math.floor(num(a[1], d.lv + 1)), 1, 250); d.xp = 0
	d.inf = R.MaxInfluence(d.lv, d.sk); d.sup = R.MaxSupply(d.lv, d.sk)
	PS.EnsureConvoys(p)
	return "Level " .. d.lv .. " (era " .. R.PlayerEra(d) .. ")"
end)
cmd("era", "/era 3  set your paid era (level is raised to match if needed)", function(_, p, a)
	local d = p.data
	local e = math.clamp(math.floor(num(a[1], (d.era or 1) + 1)), 1, #D.Eras)
	d.era = e
	if d.lv < D.Eras[e].start then d.lv = D.Eras[e].start; d.xp = 0 end
	d.wonder = math.min(d.wonder or 0, R.WonderMax(e))
	PS.EnsureConvoys(p)
	return "Era " .. e .. " (" .. D.Eras[e].name .. "), level " .. d.lv
end)
cmd("wonder", "/wonder 5  set your Wonder stage", function(_, p, a)
	local d = p.data
	d.wonder = math.clamp(math.floor(num(a[1], (d.wonder or 0) + 1)), 0, R.WonderMax(R.PlayerEra(d)))
	return "Wonder stage " .. d.wonder .. " / " .. R.WonderMax(R.PlayerEra(d))
end)

---------------------------------------------------------------- resources
cmd("inf", "/inf  refill Influence", function(_, p) local d = p.data; d.inf = R.MaxInfluence(d.lv, d.sk); d.infT = 0; return "Influence full" end)
cmd("sup", "/sup  refill Supply", function(_, p) local d = p.data; d.sup = R.MaxSupply(d.lv, d.sk); d.supT = 0; return "Supply full" end)
cmd("drain", "/drain  empty Influence and Supply (to test the refill popups)", function(_, p)
	local d = p.data; d.inf = 0; d.sup = 0; d.infT = os.time(); d.supT = os.time(); return "Influence and Supply empty"
end)
cmd("income", "/income 60  collect N minutes of property income now", function(_, p, a)
	local mins = num(a[1], 60)
	local amt = math.floor(PS.IncHr(p) * mins / 60)
	PS.Earn(p, amt, "admin")
	return "+" .. R.Money(amt) .. " (" .. mins .. " min of income)"
end)
cmd("bank", "/bank 1m  add to the bank", function(_, p, a) p.data.bank = math.max(0, (p.data.bank or 0) + num(a[1], 1e6)); return "Bank " .. R.Money(p.data.bank) end)
cmd("loan", "/loan  clear your loan", function(_, p) p.data.loan = nil; return "Loan cleared" end)

---------------------------------------------------------------- army and officers
cmd("army", "/army 50  add N of your best unlocked unit", function(_, p, a)
	local d = p.data
	local best = 1
	for i, u in ipairs(M.Units) do if u.lvl <= d.lv and u.era <= R.PlayerEra(d) then best = i end end
	local k = tostring(best)
	d.units[k] = (d.units[k] or 0) + math.floor(num(a[1], 50))
	return "+" .. math.floor(num(a[1], 50)) .. " " .. M.Units[best].name
end)
cmd("noarmy", "/noarmy  remove all regular units", function(_, p) p.data.units = {}; return "Army cleared" end)
cmd("elite", "/elite 5  add elite troops of your era", function(_, p, a)
	local d = p.data; d.elite = d.elite or {}
	local k = tostring(R.PlayerEra(d)); d.elite[k] = (d.elite[k] or 0) + math.floor(num(a[1], 5))
	return "Elite troops (era " .. k .. "): " .. d.elite[k]
end)
cmd("officer", "/officer legendary  add an officer (needs a free slot). common..forbidden", function(_, p, a)
	local r = O.RarityByKey[tostring(a[1] or "legendary"):lower()]
	if not r or r.key == "limited" then return "Unknown rarity" end
	local res = PS.AddOfficer(p, O.NewOfficer(PS.Rng(p), r.index))
	return res and ("Added officer: " .. r.name) or "No free officer slot. /slot first."
end)
cmd("gear", "/gear mythic  add a gear item", function(_, p, a)
	local r = O.RarityByKey[tostring(a[1] or "epic"):lower()]
	if not r or r.key == "limited" then return "Unknown rarity" end
	return PS.AddGear(p, O.NewGear(PS.Rng(p), r.index, a[2])) and ("Added " .. r.name .. " gear") or "Inventory full"
end)
cmd("slot", "/slot  unlock one more officer slot for free", function(_, p)
	p.data.cab.bought = (p.data.cab.bought or 0) + 1; return "Officer slots bought: " .. p.data.cab.bought
end)
cmd("crates", "/crates 5 founder|basic  add crates", function(_, p, a)
	local n = math.floor(num(a[1], 5)); local kind = (tostring(a[2] or "founder"):lower() == "basic") and "basic" or "limited"
	p.data.crates[kind] = math.max(0, p.data.crates[kind] + n)
	return "Crates: " .. p.data.crates.limited .. " founder, " .. p.data.crates.basic .. " basic"
end)

---------------------------------------------------------------- timers
cmd("finish", "/finish  every convoy arrives now", function(_, p)
	local n = 0
	for _, c in ipairs(p.data.convoys) do if c.to then c.t1 = os.time(); n += 1 end end
	return n .. " convoys arriving"
end)
cmd("boss", "/boss  reset the boss cooldown", function(_, p) if p.data.boss then p.data.boss.next = 0 end; PS.EnsureBoss(p); return "Boss ready" end)
cmd("raidcd", "/raidcd  clear your raid cooldowns", function(_, p) p.raidCd = {}; return "Raid cooldowns cleared" end)
cmd("shield", "/shield 60  raid shield for N minutes (0 removes it)", function(plr, p, a)
	local mins = num(a[1], 60)
	p.data.shield = mins > 0 and (os.time() + math.floor(mins * 60)) or 0
	p.data.shieldFrom = mins > 0 and os.time() or nil
	if RA and RA.SetShield then pcall(RA.SetShield, plr.UserId, p.data.shield) end
	return mins > 0 and ("Shield for " .. mins .. " min") or "Shield removed"
end)
cmd("login", "/login  make today's login reward claimable again", function(_, p) p.data.login.last = 0; return "Login reward ready" end)
cmd("tasks", "/tasks  new daily orders and weekly challenges", function(_, p)
	p.data.tasks = nil; p.data.weekly = nil; p.data.refresh = { day = 0, tokens = 0 }; PS.EnsureTasks(p); return "Orders rerolled"
end)
cmd("event", "/event  open a world event right now (this server only)", function()
	RS:SetAttribute("IC_EventShift", nil)
	local t = os.time()
	if Events.Active(t) then return "A world event is already open: " .. Events.Active(t).name end
	local ev = Events.Next(t)
	RS:SetAttribute("IC_EventShift", ev.starts - t + 2)
	ev = Events.Active(t)
	return ev and ("World event open: " .. ev.name .. " in city " .. ev.city) or "Could not open an event"
end)
cmd("noevent", "/noevent  back to the normal event clock", function() RS:SetAttribute("IC_EventShift", nil); return "Event clock normal" end)

---------------------------------------------------------------- shop and flags
cmd("starter", "/starter  make the Starter Pack buyable again", function(_, p) p.data.starter = nil; return "Starter Pack available" end)
cmd("bundle", "/bundle  make the Limited Bundle buyable again", function(_, p) p.data.bundle = false; return "Bundle available" end)
cmd("passes", "/passes off|on  turn the Studio free gamepasses off or on", function(plr, p, a)
	local off = tostring(a[1] or "off"):lower() == "off"
	workspace:SetAttribute("IC_NoPasses", off or nil)
	p.gp = {}
	PS.Market.CheckPasses(plr, p)
	return off and "Studio passes OFF (you only have what you bought)" or "Studio passes ON"
end)
cmd("onboard", "/onboard  replay the first-time setup", function(_, p) p.data.onboarded = false; return "Onboarding will show" end)
cmd("save", "/save  save your data now", function(plr) task.spawn(PS.Save, plr); return "Saving" end)

---------------------------------------------------------------- alliance
cmd("allyxp", "/allyxp 500  add XP to your alliance (as donations)", function(plr, p, a)
	local d = p.data
	if not d.alliance then return "You are not in an alliance" end
	WS.AddProgress(d.alliance, p.userId, "donate", math.floor(num(a[1], 500)))
	if WS.FlushTreasury then task.spawn(WS.FlushTreasury) end
	return "Alliance XP added (applies in a few seconds)"
end)
cmd("allytreasury", "/allytreasury 1m  add cash to your alliance treasury", function(_, p, a)
	local d = p.data
	if not d.alliance then return "You are not in an alliance" end
	WS.Credit(d.alliance, num(a[1], 1e6))
	return "Treasury credited"
end)

cmd("help", "/help  list every command", function()
	local out = {}
	for _, n in ipairs(ORDER) do table.insert(out, C[n].help) end
	return table.concat(out, "\n")
end)

function AD.List()
	local out = {}
	for _, n in ipairs(ORDER) do table.insert(out, { name = n, help = C[n].help }) end
	return out
end

function AD.Run(plr, p, line)
	if not AD.IsAdmin(plr) then return { ok = false, msg = "Not allowed" } end
	if type(line) ~= "string" or #line > 200 then return { ok = false, msg = "Bad command" } end
	local parts = {}
	for w in line:gmatch("%S+") do table.insert(parts, w) end
	local name = (parts[1] or ""):gsub("^/", ""):lower()
	table.remove(parts, 1)
	local c = C[name]
	if not c then return { ok = false, msg = "Unknown command /" .. name .. ". Try /help" } end
	local okC, res = pcall(c.fn, plr, p, parts)
	if not okC then warn("[Idle Country] admin /" .. name .. ": " .. tostring(res)); return { ok = false, msg = "Error: " .. tostring(res) } end
	print("[Idle Country] admin " .. plr.Name .. ": /" .. name .. " " .. table.concat(parts, " "))
	return { ok = true, out = tostring(res or "Done") }
end

return AD
