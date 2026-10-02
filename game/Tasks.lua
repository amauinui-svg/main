-- Tasks: daily orders (pool of 20, 4 a day), weekly challenges (5, reset Monday) and the 7-day login sheet.
-- Kash 1 Oct: 3x more variety, weekly challenges with very good rewards that take a lot of playtime, one free refresh a
-- day (more for 19 Robux), and a login sheet that PAUSES (a missed day keeps your place; day 7 is the big one).
local T = {}

T.Daily = {
	{ key = "laws", n = 40, text = "Pass 40 laws", icon = "icon_laws", diff = "easy" },
	{ key = "laws", n = 120, text = "Pass 120 laws", icon = "icon_laws", big = true, diff = "hard" },
	{ key = "trips", n = 4, text = "Deliver 4 convoy loads", icon = "icon_package", diff = "easy" },
	{ key = "trips", n = 10, text = "Deliver 10 convoy loads", icon = "icon_package", big = true, diff = "hard" },
	{ key = "raids", n = 3, text = "Win 3 raids", icon = "icon_battle", diff = "medium" },
	{ key = "raids", n = 8, text = "Win 8 raids", icon = "icon_battle", big = true, diff = "hard" },
	{ key = "build", n = 2, text = "Build 2 properties", icon = "icon_properties", diff = "easy" },
	{ key = "hits", n = 8, text = "Hit a boss or city 8 times", icon = "icon_attack", diff = "medium" },
	{ key = "units", n = 5, text = "Recruit 5 soldiers", icon = "icon_military", diff = "medium" },
	{ key = "units", n = 20, text = "Recruit 20 soldiers", icon = "icon_military", big = true, diff = "hard" },
	{ key = "boss", n = 1, text = "Defeat a boss", icon = "icon_bosses", big = true, diff = "hard" },
	{ key = "deposit", n = 1, text = "Deposit cash in the bank", icon = "icon_bank", diff = "easy" },
	{ key = "donate", n = 1, text = "Donate to your alliance", icon = "icon_alliance", diff = "easy" },
	{ key = "hire", n = 1, text = "Hire an officer", icon = "icon_users", diff = "easy" },
	{ key = "crate", n = 1, text = "Open a crate", icon = "icon_gift", diff = "easy" },
	{ key = "influence", n = 150, text = "Spend 150 Influence", icon = "icon_influence", diff = "easy" },
	{ key = "supply", n = 20, text = "Spend 20 Supply", icon = "icon_supply", diff = "easy" },
	{ key = "level", n = 1, text = "Gain a level", icon = "icon_xp", diff = "easy" },
	{ key = "earn", n = 60, text = "Earn an hour of law income", icon = "icon_cash", scaled = true, diff = "medium" },
	{ key = "moves", n = 3, text = "Send convoys to 3 different cities", icon = "icon_globe", diff = "medium" },
}
T.DailyCount = 5
table.insert(T.Daily, 1, { key = "online", n = 20, text = "Stay in the game for 20 minutes", icon = "icon_clock", diff = "easy" })
T.Weekly = {
	{ key = "laws", n = 1000, text = "Pass 1,000 laws", icon = "icon_laws" },
	{ key = "trips", n = 50, text = "Deliver 50 convoy loads", icon = "icon_package" },
	{ key = "raids", n = 25, text = "Win 25 raids", icon = "icon_battle" },
	{ key = "siege", n = 100, text = "Hit cities 100 times with your alliance", icon = "icon_castle" },
	{ key = "earn", n = 1200, text = "Earn 20 hours of law income", icon = "icon_cash", scaled = true },
}
T.WeeklyPool = {
	{ key = "online", n = 300, text = "Play for 5 hours this week", icon = "icon_clock" },
	{ key = "units", n = 150, text = "Recruit 150 soldiers", icon = "icon_military" },
	{ key = "boss", n = 5, text = "Defeat 5 bosses", icon = "icon_bosses" },
	{ key = "build", n = 15, text = "Build 15 properties", icon = "icon_properties" },
	{ key = "hits", n = 120, text = "Hit bosses or cities 120 times", icon = "icon_attack" },
	{ key = "influence", n = 3000, text = "Spend 3,000 Influence", icon = "icon_influence" },
	{ key = "crate", n = 10, text = "Open 10 crates", icon = "icon_gift" },
}

-- rewards (Kash 16:47: tasks pay SEALS, a separate task currency spent in the Seals shop, plus cash).
-- "lawMinutes" are minutes of law income at the player's level when claimed.
T.Diff = {
	easy = { name = "EASY", color = "6fcf6a", seals = 1, lawMinutes = 10 },
	medium = { name = "MEDIUM", color = "e9a23b", seals = 2, lawMinutes = 20 },
	hard = { name = "HARD", color = "e5533d", seals = 3, lawMinutes = 40 },
}
T.DailyBonus = { seals = 2, refill = true } -- claim all 5 daily: +2 seals and full Influence
T.WeeklyReward = { seals = 7, lawMinutes = 120 }
T.WeeklyChest = { seals = 12, limitedCrates = 1, gearMinRarity = 3 } -- all 5 weekly claimed

-- Seals shop. Seals are not tradable and never bought with Robux.
T.Shop = {
	{ key = "ticket1", name = "Takedown Ticket", desc = "One extra Takedown attack.", cost = 2, tickets = 1, icon = "icon_ticket" },
	{ key = "ticket5", name = "5 Takedown Tickets", desc = "Five extra Takedown attacks.", cost = 8, tickets = 5, icon = "icon_ticket" },
	{ key = "influence", name = "Influence Refill", desc = "Fill your Influence to max.", cost = 3, refill = "inf", icon = "icon_influence" },
	{ key = "supply", name = "Supply Refill", desc = "Fill your Supply to max.", cost = 3, refill = "sup", icon = "icon_supply" },
	{ key = "basic", name = "Supply Crate", desc = "A crate of gear, sometimes an officer.", cost = 6, basicCrates = 1, icon = "crate_basic" },
	{ key = "shield", name = "Raid Shield (1h)", desc = "Nobody can raid you for an hour.", cost = 10, shieldHours = 1, icon = "icon_defense" },
	{ key = "limited", name = "Founder's Crate", desc = "The premium crate: great gear and officers.", cost = 30, limitedCrates = 1, icon = "crate_limited" },
}
T.ShopByKey = {}
for _, it in ipairs(T.Shop) do T.ShopByKey[it.key] = it end

T.Login = {
	{ text = "30 min of law cash", lawMinutes = 30, icon = "icon_cash" },
	{ text = "5 gold", gold = 5, icon = "icon_gold" },
	{ text = "Full Influence + Supply", refill = true, icon = "icon_influence" },
	{ text = "1 hour of law cash", lawMinutes = 60, icon = "icon_cash" },
	{ text = "10 gold", gold = 10, icon = "icon_gold" },
	{ text = "2 Supply Crates", basicCrates = 2, icon = "icon_gift" },
	{ text = "30 gold + Founder's Crate", gold = 30, limitedCrates = 1, icon = "icon_crown", big = true },
}

function T.Week(t) -- weeks start Monday 00:00 UTC (Unix day 0 was a Thursday)
	return math.floor(((t or os.time()) / 86400 + 3) / 7)
end
return T
