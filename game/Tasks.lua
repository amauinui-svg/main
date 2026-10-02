-- Tasks: daily orders (pool of 20, 4 a day), weekly challenges (5, reset Monday) and the 7-day login sheet.
-- Kash 1 Oct: 3x more variety, weekly challenges with very good rewards that take a lot of playtime, one free refresh a
-- day (more for 19 Robux), and a login sheet that PAUSES (a missed day keeps your place; day 7 is the big one).
local T = {}

T.Daily = {
	{ key = "laws", n = 40, text = "Pass 40 laws", icon = "icon_laws" },
	{ key = "laws", n = 120, text = "Pass 120 laws", icon = "icon_laws", big = true },
	{ key = "trips", n = 4, text = "Deliver 4 convoy loads", icon = "icon_package" },
	{ key = "trips", n = 10, text = "Deliver 10 convoy loads", icon = "icon_package", big = true },
	{ key = "raids", n = 3, text = "Win 3 raids", icon = "icon_battle" },
	{ key = "raids", n = 8, text = "Win 8 raids", icon = "icon_battle", big = true },
	{ key = "build", n = 2, text = "Build 2 properties", icon = "icon_properties" },
	{ key = "hits", n = 8, text = "Hit a boss or city 8 times", icon = "icon_attack" },
	{ key = "units", n = 5, text = "Recruit 5 soldiers", icon = "icon_military" },
	{ key = "units", n = 20, text = "Recruit 20 soldiers", icon = "icon_military", big = true },
	{ key = "boss", n = 1, text = "Defeat a boss", icon = "icon_bosses", big = true },
	{ key = "deposit", n = 1, text = "Deposit cash in the bank", icon = "icon_bank" },
	{ key = "donate", n = 1, text = "Donate to your alliance", icon = "icon_alliance" },
	{ key = "hire", n = 1, text = "Hire an officer", icon = "icon_users" },
	{ key = "crate", n = 1, text = "Open a crate", icon = "icon_gift" },
	{ key = "influence", n = 150, text = "Spend 150 Influence", icon = "icon_influence" },
	{ key = "supply", n = 20, text = "Spend 20 Supply", icon = "icon_supply" },
	{ key = "level", n = 1, text = "Gain a level", icon = "icon_xp" },
	{ key = "earn", n = 60, text = "Earn an hour of law income", icon = "icon_cash", scaled = true },
	{ key = "moves", n = 3, text = "Send convoys to 3 different cities", icon = "icon_globe" },
}
T.DailyCount = 4
T.Weekly = {
	{ key = "laws", n = 1000, text = "Pass 1,000 laws", icon = "icon_laws" },
	{ key = "trips", n = 50, text = "Deliver 50 convoy loads", icon = "icon_package" },
	{ key = "raids", n = 25, text = "Win 25 raids", icon = "icon_battle" },
	{ key = "siege", n = 100, text = "Hit cities 100 times with your alliance", icon = "icon_castle" },
	{ key = "earn", n = 1200, text = "Earn 20 hours of law income", icon = "icon_cash", scaled = true },
}
T.WeeklyPool = {
	{ key = "units", n = 150, text = "Recruit 150 soldiers", icon = "icon_military" },
	{ key = "boss", n = 5, text = "Defeat 5 bosses", icon = "icon_bosses" },
	{ key = "build", n = 15, text = "Build 15 properties", icon = "icon_properties" },
	{ key = "hits", n = 120, text = "Hit bosses or cities 120 times", icon = "icon_attack" },
	{ key = "influence", n = 3000, text = "Spend 3,000 Influence", icon = "icon_influence" },
	{ key = "crate", n = 10, text = "Open 10 crates", icon = "icon_gift" },
}

-- rewards. "lawMinutes" are minutes of law income at the player's level when claimed.
T.DailyReward = { gold = 2, lawMinutes = 15 }
T.DailyRewardBig = { gold = 4, lawMinutes = 30 }
T.DailyBonus = { gold = 5 } -- all of today's orders claimed
T.WeeklyReward = { gold = 15, basicCrates = 1 }
T.WeeklyChest = { limitedCrates = 1, gearMinRarity = 2 } -- all 5 weekly claimed: Founder's Crate + Rare-or-better gear

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
