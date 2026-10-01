-- Trade: convoy routes, loads and payouts. Shared so the client previews exactly what the server will pay.
-- Kash (1 Oct 2026): pay a fee, get money back; dressed as trading goods but no inventory. Click a city to see
-- every load going there with pay, tax, distance and time. Convoys stay where they arrive. Never fail.
-- Neighbours 2-5 min, ocean crossings a couple of hours, later eras travel faster.
local Rules = require(script.Parent.Rules)
local World = require(script.Parent.World)
local T = {}

---------------------------------------------------------------- goods (era = first era the good can be carried)
T.Goods = {
	grain = { "Grain", "icon_wheat", 1, 0.9 }, fish = { "Salted Fish", "icon_fish", 1, 0.9 }, wine = { "Wine", "icon_wine", 1, 1.15 },
	pottery = { "Pottery", "icon_amphora", 1, 1.0 }, cloth = { "Cloth", "icon_shirt", 1, 1.05 }, timber = { "Timber", "icon_tree", 1, 0.9 },
	olives = { "Olive Oil", "icon_droplet", 1, 1.05 }, copper = { "Copper", "icon_pickaxe", 1, 1.1 }, dates = { "Dates", "icon_sprout", 1, 0.95 },
	beef = { "Cattle", "icon_beef", 1, 1.0 }, wool = { "Wool", "icon_shirt", 1, 1.0 }, gems = { "Gemstones", "icon_gem", 1, 1.4 },
	gold = { "Gold", "icon_coins", 1, 1.4 }, silver = { "Silver", "icon_coins", 1, 1.3 }, fruit = { "Fruit", "icon_apple", 1, 0.95 },
	marble = { "Marble", "icon_mountain", 1, 1.1 }, carpets = { "Carpets", "icon_shirt", 1, 1.2 }, pistachios = { "Pistachios", "icon_sprout", 1, 1.05 },
	spices = { "Spices", "icon_flame", 1, 1.3 }, silk = { "Silk", "icon_shirt", 1, 1.35 }, rice = { "Rice", "icon_wheat", 1, 0.9 },
	metals = { "Iron Ore", "icon_pickaxe", 1, 1.0 }, tea = { "Tea", "icon_coffee", 3, 1.15 }, perfume = { "Perfume", "icon_flask", 3, 1.3 },
	coffee = { "Coffee", "icon_coffee", 4, 1.15 }, sugar = { "Sugar", "icon_cookie", 4, 1.05 }, cocoa = { "Cocoa", "icon_cookie", 4, 1.1 },
	flowers = { "Flowers", "icon_leaf", 4, 1.1 }, finance = { "Bonds", "icon_landmark", 4, 1.35 }, rubber = { "Rubber", "icon_droplet", 5, 1.05 },
	coal = { "Coal", "icon_mountain", 5, 0.95 }, steel = { "Steel", "icon_anvil", 5, 1.1 }, machinery = { "Machinery", "icon_hammer", 5, 1.2 },
	oil = { "Oil", "icon_fuel", 5, 1.15 }, chemicals = { "Chemicals", "icon_flask", 6, 1.15 }, cars = { "Cars", "icon_car", 6, 1.25 },
	medicine = { "Medicine", "icon_pill", 6, 1.3 }, films = { "Film Reels", "icon_tv", 6, 1.2 }, electronics = { "Electronics", "icon_cpu", 7, 1.35 },
	mixed = { "Mixed Freight", "icon_boxes", 1, 1.0 },
}
T.Staples = { "grain", "cloth", "pottery", "timber", "fish", "wine", "fruit", "copper", "spices", "tea", "coffee", "steel", "oil", "cars", "electronics" }
function T.GoodName(k) return T.Goods[k] and T.Goods[k][1] or k end
function T.GoodIcon(k) return T.Goods[k] and T.Goods[k][2] or "icon_package" end

---------------------------------------------------------------- vehicles by era
T.Vehicles = {
	{ land = { "Camel Caravan", "convoy_cart" }, sea = { "Trade Galley", "convoy_sail" }, cap = 8 },
	{ land = { "Ox Wagons", "convoy_cart" }, sea = { "Merchant Galley", "convoy_sail" }, cap = 12 },
	{ land = { "Merchant Carts", "convoy_cart" }, sea = { "Cog Ship", "convoy_sail" }, cap = 20 },
	{ land = { "Freight Coaches", "convoy_cart" }, sea = { "Galleon", "convoy_sail" }, cap = 40 },
	{ land = { "Freight Train", "convoy_train" }, sea = { "Steamship", "convoy_ship" }, cap = 120 },
	{ land = { "Lorry Convoy", "convoy_truck" }, sea = { "Container Ship", "convoy_ship" }, cap = 400 },
	{ land = { "Road Train", "convoy_truck" }, sea = { "Cargo Jet", "convoy_plane" }, cap = 900 },
	{ land = { "Hover Freighter", "convoy_rocket" }, sea = { "Cargo Rocket", "convoy_rocket" }, cap = 2500 },
}
T.EraSpeed = { 1.0, 0.9, 0.8, 0.72, 0.64, 0.56, 0.5, 0.45 } -- trip time multiplier per era
T.FastPassSpeed = 0.5

---------------------------------------------------------------- routes
-- land: same landmass. coast: different landmass but under 1,500 km (Channel, Korea Strait, Java Sea).
function T.RouteKind(a, b)
	local A, B = World.Cities[a], World.Cities[b]
	if A.land == B.land then return "land" end
	if World.Km[a][b] < 1500 then return "coast" end
	return "sea"
end
-- base minutes before era/pass speed-ups (this is also what pay is measured on, so speed never cuts pay)
function T.BaseMinutes(a, b)
	local km, kind = World.Km[a][b], T.RouteKind(a, b)
	if kind == "land" then return 1.5 + km / 250 end
	if kind == "coast" then return 3 + km / 220 end
	return 15 + km / 90
end
function T.TripSeconds(a, b, era, fast)
	local s = T.BaseMinutes(a, b) * 60 * T.EraSpeed[math.clamp(era, 1, 8)]
	if fast then s *= T.FastPassSpeed end
	return math.max(30, math.floor(s + 0.5))
end
-- Balance (1 Oct 2026 fact-check, scratchpad sim): one convoy on its best route earns about 40% of what laws earn per
-- minute, short hops about 20%. Six convoys roughly double a player's income, Express Logistics doubles the convoy share.
-- Later eras travel faster; pay is scaled by sqrt(era speed) so a faster era earns ~1.5x per minute, not 2.2x.
local K = { land = 0.09, coast = 0.1, sea = 0.12 }

-- the money yardstick: a minute of law regen, plus a quarter of property income, so trade grows with the country
function T.TradeValue(lv, incHr) return Rules.MinuteValue(lv) + 0.25 * (incHr or 0) / 60 end

-- deterministic "hot good" of the day for a city (+25% on top of demand)
function T.HotGood(city, day)
	local C = World.Cities[city]
	local n = ((day or Rules.Day()) * 7 + city * 13) % #C.demand
	return C.demand[n + 1]
end

-- Loads offered from city a to city b for a player. ctx = { lv, incHr, day, convoyMult, taxPct, taxFree }
function T.Loads(a, b, ctx)
	local A, B = World.Cities[a], World.Cities[b]
	local era = Rules.EraOf(ctx.lv)
	local kind = T.RouteKind(a, b)
	local base = T.BaseMinutes(a, b)
	local value = T.TradeValue(ctx.lv, ctx.incHr)
	local hot = T.HotGood(b, ctx.day)
	local list, seen = {}, {}
	local function add(key)
		if seen[key] then return end
		local g = T.Goods[key]
		if not g or g[3] > era then return end
		seen[key] = true
		local demand = table.find(B.demand, key) ~= nil
		local mult = g[4] * (demand and 1.3 or 1) * (key == hot and 1.25 or 1) * (ctx.convoyMult or 1)
		local profit = value * K[kind] * base ^ 1.1 * mult * math.sqrt(T.EraSpeed[era])
		local cost = math.floor(profit * 0.6 + 0.5)
		local pay = math.floor(cost + profit + 0.5)
		local tax = ctx.taxFree and 0 or math.floor(pay * (ctx.taxPct or 0) / 100 + 0.5)
		local tons = math.floor(T.Vehicles[era].cap * (0.6 + 0.4 * (g[4] - 0.9) / 0.5) + 0.5)
		table.insert(list, {
			good = key, name = g[1], icon = g[2], cost = cost, pay = pay, tax = tax, net = pay - tax - cost,
			xp = math.max(1, math.floor(Rules.MinuteXp(ctx.lv) * base * 0.1 + 0.5)),
			demand = demand, hot = key == hot, tons = tons,
		})
	end
	-- 1) what the origin exports, 2) what the destination wants, 3) era staples, until there are 3 loads
	for _, k in ipairs(A.exports) do add(k) end
	for _, k in ipairs(B.demand) do if #list < 3 then add(k) end end
	if #list < 3 then
		local pool = T.Staples
		local start = (a * 7 + b * 3) % #pool
		for i = 0, #pool - 1 do
			if #list >= 3 then break end
			add(pool[(start + i) % #pool + 1])
		end
	end
	if #list < 3 then add("mixed") end
	table.sort(list, function(x, y) return x.net > y.net end)
	return list, kind, base
end

-- empty move (reposition or recall home): pays nothing, costs a travel fee
function T.MoveFee(a, b, lv, incHr)
	return math.floor(T.TradeValue(lv, incHr) * 0.15 * T.BaseMinutes(a, b) + 0.5)
end

function T.Vehicle(era, kind)
	local v = T.Vehicles[math.clamp(era, 1, 8)]
	return kind == "land" and v.land or v.sea
end

-- position of a convoy on the pixel map at fraction f. Routes take the short way round, so a Pacific
-- crossing (Los Angeles -> Tokyo) leaves the right edge and re-enters on the left; x is wrapped into [0, MapW).
-- Sea legs bow slightly toward the equator so they read as sea lanes, not straight lines.
function T.Lerp(a, b, f)
	local A, B = World.Cities[a], World.Cities[b]
	local dx = B.px - A.px
	if dx > World.MapW / 2 then dx -= World.MapW elseif dx < -World.MapW / 2 then dx += World.MapW end
	local x = (A.px + dx * f) % World.MapW
	local y = A.py + (B.py - A.py) * f
	if T.RouteKind(a, b) == "sea" then
		y += math.sin(f * math.pi) * math.min(18, World.Km[a][b] / 900) * (A.py + B.py < World.MapH and 1 or -1)
	end
	return x, y
end
return T
