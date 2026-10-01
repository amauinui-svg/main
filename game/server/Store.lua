-- Store: DataStore + MemoryStore helpers with safe fallbacks.
-- If Studio API access is off, everything runs in memory so the game still plays (nothing is saved).
local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local RunService = game:GetService("RunService")
local S = {}

S.Online = true
local probeOk = pcall(function() DataStoreService:GetDataStore("IC_Probe"):GetAsync("probe") end)
if not probeOk then
	S.Online = false
	warn("[Idle Country] DataStores unavailable (Studio API access off?). Running in memory only: nothing will save.")
end

local stores = {}
function S.DS(name)
	if not S.Online then return nil end
	if not stores[name] then stores[name] = DataStoreService:GetDataStore(name) end
	return stores[name]
end
local ordered = {}
function S.ODS(name)
	if not S.Online then return nil end
	if not ordered[name] then ordered[name] = DataStoreService:GetOrderedDataStore(name) end
	return ordered[name]
end

-- retrying wrappers; return ok, result
function S.Get(store, key)
	if not store then return true, nil end
	for i = 1, 3 do
		local ok, r = pcall(store.GetAsync, store, key)
		if ok then return true, r end
		warn("[Idle Country] GetAsync " .. key .. " failed (" .. i .. "): " .. tostring(r))
		task.wait(i)
	end
	return false, nil
end
function S.Update(store, key, fn)
	if not store then return true, fn(nil) end
	for i = 1, 3 do
		local ok, r = pcall(store.UpdateAsync, store, key, fn)
		if ok then return true, r end
		warn("[Idle Country] UpdateAsync " .. key .. " failed (" .. i .. "): " .. tostring(r))
		task.wait(i)
	end
	return false, nil
end

-- MemoryStore hash map with in-memory fallback (live shared world state)
local memMaps = {}
local localMaps = {}
local memOk = S.Online and pcall(function() MemoryStoreService:GetHashMap("IC_Probe"):GetAsync("probe") end)
S.MemOnline = memOk and true or false
if S.Online and not memOk then warn("[Idle Country] MemoryStore unavailable: city state is local to this server.") end
function S.MapGet(name, key)
	if S.MemOnline then
		memMaps[name] = memMaps[name] or MemoryStoreService:GetHashMap(name)
		local ok, r = pcall(memMaps[name].GetAsync, memMaps[name], key)
		if ok then return r end
	end
	localMaps[name] = localMaps[name] or {}
	return localMaps[name][key]
end
-- fn(old) -> new (or nil to abort). Expiry 30 days; city state is also backed up to a DataStore.
function S.MapUpdate(name, key, fn)
	if S.MemOnline then
		memMaps[name] = memMaps[name] or MemoryStoreService:GetHashMap(name)
		for i = 1, 3 do
			local ok, r = pcall(memMaps[name].UpdateAsync, memMaps[name], key, fn, 30 * 86400)
			if ok then return r end
			task.wait(0.2 * i)
		end
		return nil -- never fall back to a local copy while the shared one exists (it would fork the world)
	end
	localMaps[name] = localMaps[name] or {}
	local new = fn(localMaps[name][key])
	if new ~= nil then localMaps[name][key] = new end
	return new
end

S.JobId = (game.JobId ~= "" and game.JobId) or ("studio-" .. tostring(math.random(1e9)))
S.IsStudio = RunService:IsStudio()
return S
