-- WORLD EVENTS (Kash 2 Oct): every 30 to 60 minutes something happens in one world capital. For 15 minutes, the
-- first convoy you send there pays a big locked bonus. The schedule comes from the clock alone, so every server
-- (and every client) agrees on the same event without any messaging.
local World = require(script.Parent.World)
local RS = game:GetService("ReplicatedStorage")
local E = {}
-- the tester panel's /event shifts this server's event clock (ReplicatedStorage attribute, so clients follow)
local function clock(t) return math.floor(t or os.time()) + (RS:GetAttribute("IC_EventShift") or 0) end

E.Period = 2700      -- one event per 45 minute window...
E.Jitter = 900       -- ...starting somewhere in the first 15 minutes of it, so gaps run 30 to 60 minutes
E.Duration = 900     -- open for 15 minutes

E.Kinds = {
	{ key = "goldrush", name = "Gold Rush", desc = "Prospectors flood the city. Everything sells high.", icon = "icon_gold", mult = 2.5 },
	{ key = "festival", name = "Grand Festival", desc = "The whole city is celebrating and buying.", icon = "icon_star", mult = 2.5 },
	{ key = "famine", name = "Famine Relief", desc = "Supplies are desperately needed. Relief pays well.", icon = "icon_supply", mult = 3 },
	{ key = "fair", name = "World Fair", desc = "Merchants from every nation are in town.", icon = "icon_convoy", mult = 2.5 },
	{ key = "wedding", name = "Royal Wedding", desc = "The court is spending without limits.", icon = "icon_crown", mult = 2.75 },
}

local function mix(n)
	n = (n * 2654435761) % 4294967296
	n = (n + 0x9E3779B9 * (n % 97 + 1)) % 4294967296
	return n
end

-- the event of window w (always exists; may not be open yet)
function E.Window(w)
	local h = mix(w + 17)
	local start = w * E.Period + h % E.Jitter
	local kind = E.Kinds[(h // 7) % #E.Kinds + 1]
	local city = (h // 131) % #World.Cities + 1
	return { id = w, city = city, kind = kind.key, name = kind.name, desc = kind.desc, icon = kind.icon, mult = kind.mult,
		starts = start - (RS:GetAttribute("IC_EventShift") or 0), ends = start + E.Duration - (RS:GetAttribute("IC_EventShift") or 0) }
end

-- the event open at time t, or nil
function E.Active(t)
	local real = math.floor(t or os.time())
	local ev = E.Window(clock(real) // E.Period)
	if real >= ev.starts and real < ev.ends then return ev end
	return nil
end

-- the next event that has not ended yet (the open one, or the next to start)
function E.Next(t)
	local real = math.floor(t or os.time())
	local w = clock(real) // E.Period
	local ev = E.Window(w)
	if real < ev.ends then return ev end
	return E.Window(w + 1)
end

return E
