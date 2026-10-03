-- Sound: every sound effect and the background music for Idle Country.
-- ClientMain calls _sound.init(App) once after the first full sync (same pattern as Settings). No build field on purpose.
--
-- Other code plays sounds with:   if App.sfx then App.sfx("purchase") end
--   opts (all optional):  App.sfx("coin", { volume = 0.5 (multiplier), pitch = 1.1 (fixed), delay = 0.2 })
-- Music:                          App.music(true) / App.music(false) / App.music("battle") / App.music("calm")
--
-- Every id below is listed with its source and the reason it was picked in SOUNDS.md (Kash reviews there).
-- Sources: Roblox (official), ProSoundEffects + APMOfficial (Roblox's licensed libraries, free in any experience),
-- the classic Roblox sword set, BIG Games (Pet Simulator 99) and a few community uploads (marked in SOUNDS.md).
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local plr = Players.LocalPlayer

local function rid(n) return "rbxassetid://" .. tostring(n) end

-- name = { id, volume, jitter (random pitch +-, 0.03 = 3%), pitch (base), gap (min seconds between plays),
--          stop (cut the sound after N seconds), duck (lower the music while it plays), with (also play this sfx), alt (backup id) }
local SFX = {
	-- UI
	ui_click         = { id = rid(15675032796), volume = 0.45, jitter = 0.03, gap = 0.04, alt = rid(15675059323) },
	ui_hover         = { id = rid(15675032796), volume = 0.12, pitch = 1.35, jitter = 0.02, gap = 0.06, alt = rid(15675081158) },
	tab_open         = { id = rid(15675037413), volume = 0.45, gap = 0.08, alt = rid(15675012262) },
	notify           = { id = rid(15675085146), volume = 0.35, gap = 0.4, stop = 1.6, alt = rid(15675059323) },
	error            = { id = rid(15675075163), volume = 0.45, gap = 0.3, alt = rid(15675062723) },
	-- money
	purchase         = { id = rid(127645268874265), volume = 0.6, gap = 0.1, alt = rid(9113849651) },
	coin             = { id = rid(607665037), volume = 0.4, jitter = 0.04, gap = 0.04, alt = rid(9121189379) },
	cash_big         = { id = rid(9113849583), volume = 0.7, gap = 0.3, with = "purchase", alt = rid(9119218944) },
	claim            = { id = rid(1839997938), volume = 0.5, gap = 0.2, stop = 2.6, alt = rid(15675043410) },
	-- progression
	level_up         = { id = rid(87681931953984), volume = 0.6, gap = 1, duck = true, alt = rid(1841887348) },
	law_pass         = { id = rid(9125574158), volume = 0.7, gap = 0.2, alt = rid(9114559389) },
	seal             = { id = rid(9125573398), volume = 0.65, gap = 0.15, alt = rid(9114348725) },
	build_start      = { id = rid(9125574353), volume = 0.6, gap = 0.2, alt = rid(9114755645) },
	build_done       = { id = rid(15675043410), volume = 0.5, gap = 0.2, alt = rid(1839997938) },
	hire             = { id = rid(15675028888), volume = 0.5, gap = 0.1, with = "seal", alt = rid(12222200) },
	equip            = { id = rid(9116672675), volume = 0.55, jitter = 0.04, gap = 0.08, alt = rid(9116542304) },
	convoy_arrive    = { id = rid(134725934515507), volume = 0.45, gap = 1, stop = 2.6, alt = rid(107938430449015) },
	stage_clear      = { id = rid(100735630401429), volume = 0.6, gap = 2, duck = true, alt = rid(1844250707) },
	-- crates
	crate_shake      = { id = rid(1846435467), volume = 0.55, gap = 0.3, alt = rid(9120891869) },
	crate_open       = { id = rid(15675055424), volume = 0.55, gap = 0.15, stop = 1.2, alt = rid(15675024286) },
	reveal_common    = { id = rid(3199238931), volume = 0.4, gap = 0.08, stop = 1.2, alt = rid(15675043410) },
	reveal_rare      = { id = rid(4612374495), volume = 0.5, gap = 0.1, alt = rid(4612374393) },
	reveal_epic      = { id = rid(1841209502), volume = 0.55, gap = 0.3, duck = true, alt = rid(1846631123) },
	reveal_legendary = { id = rid(134527763388412), volume = 0.65, gap = 0.5, duck = true, alt = rid(9039690188) },
	-- rarer unlocks (Kash 2 Oct 23:48): officers and items above Legendary get their own bigger stings
	reveal_mythic    = { id = rid(9047100306), volume = 0.7, gap = 0.6, duck = true, alt = rid(1836860398) },
	reveal_secret    = { id = rid(9047103106), volume = 0.7, gap = 0.6, duck = true, alt = rid(9047100306) },
	reveal_forbidden = { id = rid(1836860398), volume = 0.75, gap = 0.6, duck = true, alt = rid(9047103106) },
	-- war
	raid_start       = { id = rid(1846284814), volume = 0.55, gap = 1, duck = true, with = "unsheath", alt = rid(1835324771) },
	unsheath         = { id = rid(12222225), volume = 0.45, gap = 0.2 },
	hit_gun          = { id = rid(130729359112925), volume = 0.4, jitter = 0.05, gap = 0.05, stop = 1.4, alt = rid(129944384098631) },
	hit_blade        = { id = rid(12222216), volume = 0.5, jitter = 0.05, gap = 0.05, alt = rid(109675024264804) },
	hit_punch        = { id = rid(9113565515), volume = 0.55, jitter = 0.05, gap = 0.05, alt = rid(9113575293) },
	crit             = { id = rid(9120730097), volume = 0.6, jitter = 0.03, gap = 0.1, alt = rid(9114559389) },
	takedown_hit     = { id = rid(9120974378), volume = 0.35, gap = 0.6, stop = 2.5, with = "crit", alt = rid(9120975204) },
	victory          = { id = rid(1835295052), volume = 0.6, gap = 2, duck = true, alt = rid(1835324771) },
	defeat           = { id = rid(125909120236588), volume = 0.6, gap = 2, duck = true, alt = rid(1837950656) }, -- Kash 23:48: new defeat sound
	boss_defeat      = { id = rid(1835324771), volume = 0.65, gap = 2, duck = true, with = "takedown_hit", alt = rid(119099828605032) },
}

-- background music: shuffled, cross-faded, no per-era switching
local MUSIC = {
	{ id = rid(9040686092), volume = 0.3, name = "Royal Retreat" },             -- APM, Regal Strings: grand, noble baroque strings
	{ id = rid(9042589035), volume = 0.3, name = "Summer Dawn (Strings)" },     -- APM, Light Orchestral: gentle, uplifting
	{ id = rid(1845379555), volume = 0.28, name = "Heroes Of Discovery" },      -- APM: adventurous orchestral
	{ id = rid(104175735498486), volume = 0.28, name = "History In The Making A" }, -- APM
}
local BATTLE = { id = rid(9046505640), volume = 0.3, name = "Imminent Closure (Underscore A)", alt = rid(9043173292) }

local M = { SFX = SFX, MUSIC = MUSIC, BATTLE = BATTLE }

M._sound = { init = function(App)
	---------------------------------------------------------------- groups + templates
	local root = SoundService:FindFirstChild("IC_Sounds")
	if root then root:Destroy() end
	root = Instance.new("Folder"); root.Name = "IC_Sounds"; root.Parent = SoundService
	local function group(name, vol)
		local g = SoundService:FindFirstChild(name)
		if not (g and g:IsA("SoundGroup")) then
			g = Instance.new("SoundGroup"); g.Name = name; g.Parent = SoundService
		end
		g.Volume = vol
		return g
	end
	local gSFX = group("SFX", 1)
	local gMusic = group("Music", 1)

	local templates, pools = {}, {}
	local preload = {}
	for name, d in pairs(SFX) do
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = d.id
		s.Volume = d.volume or 0.5
		s.PlaybackSpeed = d.pitch or 1
		s.SoundGroup = gSFX
		s.Parent = root
		templates[name] = s
		pools[name] = {}
		table.insert(preload, s)
	end
	local musicHost = Instance.new("Folder"); musicHost.Name = "Music"; musicHost.Parent = root
	local tracks = {}
	local function mkTrack(d)
		local s = Instance.new("Sound")
		s.Name = d.name or "Track"
		s.SoundId = d.id
		s.Volume = 0
		s.Looped = false
		s.SoundGroup = gMusic
		s.Parent = musicHost
		table.insert(preload, s)
		return { s = s, vol = d.volume or 0.3, d = d }
	end
	for _, d in ipairs(MUSIC) do table.insert(tracks, mkTrack(d)) end
	local battle = mkTrack(BATTLE)
	battle.s.Looped = true

	-- a sound that fails to load falls back to its backup id
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(preload, function(contentId, status)
				if status ~= Enum.AssetFetchStatus.Success then
					for name, d in pairs(SFX) do
						if d.id == contentId and d.alt then
							templates[name].SoundId = d.alt
							for _, c in ipairs(pools[name]) do c.SoundId = d.alt end
						end
					end
					if BATTLE.id == contentId and BATTLE.alt then battle.s.SoundId = BATTLE.alt end
				end
			end)
		end)
	end)

	---------------------------------------------------------------- settings
	-- volumes 0..1 from the settings sliders (musicVol / sfxVol). Older saves only have the on/off booleans
	-- music / sfx: false there means 0, otherwise the default (music 0.5, effects 0.8) until a volume is saved.
	local DEFAULT_VOL = { music = 0.5, sfx = 0.8 }
	local function volume(key)
		local st = App.state and App.state.settings
		local v = st and st[key .. "Vol"]
		if type(v) ~= "number" then v = plr:GetAttribute("IC_" .. key .. "Vol") end
		if type(v) == "number" and v == v then return math.clamp(v, 0, 1) end
		local old = st and st[key]
		if old == nil then old = plr:GetAttribute("IC_" .. key) end
		if old == false then return 0 end
		return DEFAULT_VOL[key]
	end
	local function sfxOn() return volume("sfx") > 0 end
	local function musicOn() return volume("music") > 0 end

	---------------------------------------------------------------- music ducking
	-- the Music group's volume is the slider level, lowered to 30% of it while a big sound plays
	local duckUntil = 0
	local groupTween
	local function musicGroupTo(vol, t)
		if groupTween then groupTween:Cancel(); groupTween = nil end
		if not t or t <= 0 then gMusic.Volume = vol; return end
		groupTween = TweenService:Create(gMusic, TweenInfo.new(t), { Volume = vol })
		groupTween:Play()
	end
	local function duck(seconds)
		duckUntil = math.max(duckUntil, os.clock() + seconds)
		musicGroupTo(volume("music") * 0.3, 0.25)
		task.delay(seconds + 0.05, function()
			if os.clock() >= duckUntil then musicGroupTo(volume("music"), 1.2) end
		end)
	end

	---------------------------------------------------------------- sfx
	local last = {}
	local lastExplicit = 0
	local live = 0
	local MAX_LIVE = 24
	local function play(name, opts, explicit)
		local d, t = SFX[name], templates[name]
		if not (d and t) then return end
		if not sfxOn() then return end
		local now = os.clock()
		if last[name] and now - last[name] < (d.gap or 0.05) then return end
		if live >= MAX_LIVE then return end
		last[name] = now
		if explicit and name ~= "ui_click" and name ~= "ui_hover" then lastExplicit = now end
		opts = opts or {}
		-- reuse an idle clone, else make one (max 6 per sound)
		local pool = pools[name]
		local s
		for _, c in ipairs(pool) do if not c.IsPlaying then s = c; break end end
		if not s then
			if #pool >= 6 then s = pool[1]; s:Stop() else s = t:Clone(); s.Parent = root; table.insert(pool, s) end
		end
		local j = d.jitter or 0
		local pitch = opts.pitch or d.pitch or 1
		if j > 0 then pitch = pitch * (1 + (math.random() * 2 - 1) * j) end
		s.PlaybackSpeed = pitch
		s.Volume = (d.volume or 0.5) * (opts.volume or 1)
		s.TimePosition = 0
		local function go()
			if not sfxOn() then return end
			live += 1
			s:Play()
			local len = d.stop or (s.TimeLength > 0 and s.TimeLength / pitch) or 2
			if d.duck then duck(math.min(len, 8)) end
			task.delay(len + 0.05, function()
				live = math.max(0, live - 1)
				if d.stop and s.IsPlaying then
					local v = s.Volume
					local tw = TweenService:Create(s, TweenInfo.new(0.25), { Volume = 0 })
					tw:Play(); tw.Completed:Wait()
					s:Stop(); s.Volume = v
				end
			end)
		end
		if opts.delay and opts.delay > 0 then task.delay(opts.delay, go) else go() end
		if d.with then play(d.with, { volume = opts.volume }, false) end
	end
	function App.sfx(name, opts) play(name, opts, true) end
	-- sound board (tester panel): every sound key, and raw candidate ids to audition
	App.sfxKeys = function() local k = {}; for n in pairs(SFX) do table.insert(k, n) end; table.sort(k); return k end
	local preview
	function App.sfxPreview(id)
		if preview then preview:Stop(); preview:Destroy() end
		preview = Instance.new("Sound"); preview.SoundId = "rbxassetid://" .. tostring(id); preview.Volume = 0.7; preview.SoundGroup = gSFX; preview.Parent = root
		preview:Play()
	end
	local function stopAllSfx()
		for _, pool in pairs(pools) do for _, c in ipairs(pool) do c:Stop() end end
		live = 0
	end

	---------------------------------------------------------------- music player
	local order, idx = {}, 0
	local current -- track table currently playing
	local mode = "calm"
	local gen = 0 -- bumps on every change; old loops notice and quit
	local function shuffle()
		order = {}
		for i = 1, #tracks do order[i] = i end
		for i = #order, 2, -1 do local k = math.random(i); order[i], order[k] = order[k], order[i] end
		-- never repeat the track that just played
		if current and #order > 1 and tracks[order[1]] == current then order[1], order[2] = order[2], order[1] end
		idx = 0
	end
	local function fade(tr, to, t, thenStop)
		if not tr then return end
		local tw = TweenService:Create(tr.s, TweenInfo.new(t, Enum.EasingStyle.Sine), { Volume = to })
		tw:Play()
		if thenStop then tw.Completed:Connect(function(state) if state == Enum.TweenPlaybackState.Completed and tr ~= current then tr.s:Stop() end end) end
	end
	local function startTrack(tr)
		local old = current
		current = tr
		if old and old ~= tr then fade(old, 0, 2.5, true) end
		if not tr.s.IsPlaying then tr.s.TimePosition = 0; tr.s.Volume = 0; tr.s:Play() end
		fade(tr, tr.vol, 2.5)
	end
	local function calmLoop(myGen)
		while gen == myGen do
			idx += 1
			if idx > #order then shuffle(); idx = 1 end
			local tr = tracks[order[idx]]
			startTrack(tr)
			-- wait for the track to load, then until ~3s before its end
			local t0 = os.clock()
			while gen == myGen and tr.s.TimeLength <= 0 and os.clock() - t0 < 10 do task.wait(0.5) end
			if tr.s.TimeLength <= 0 then task.wait(1) else
				while gen == myGen and tr.s.IsPlaying and tr.s.TimePosition < tr.s.TimeLength - 3 do task.wait(0.5) end
			end
		end
	end
	local function stopMusic()
		gen += 1
		if current then local c = current; current = nil; fade(c, 0, 1.5, true) end
	end
	function App.music(on)
		if on == "battle" or on == "calm" then mode = on; on = true end
		if on == false then stopMusic(); return end
		if not musicOn() then stopMusic(); return end
		gen += 1
		local myGen = gen
		if mode == "battle" then
			startTrack(battle)
		else
			if #order == 0 then shuffle() end
			task.spawn(calmLoop, myGen)
		end
	end

	---------------------------------------------------------------- respond to the volume sliders
	-- volume 0 mutes and stops (no track keeps playing silently); raising it from 0 starts the music again
	local musicStarted = false -- the first start waits for init's delay below
	local function applyVolumes()
		local mv, sv = volume("music"), volume("sfx")
		gSFX.Volume = sv
		if sv <= 0 then stopAllSfx() end
		musicGroupTo(os.clock() < duckUntil and mv * 0.3 or mv)
		if mv <= 0 then
			if current then stopMusic() end
		elseif musicStarted and not current then
			App.music(true)
		end
	end
	App.on("settings", function(key)
		if key == "musicVol" or key == "sfxVol" or key == "music" or key == "sfx" then applyVolumes() end
	end)
	App.on("full", applyVolumes)
	for _, a in ipairs({ "IC_musicVol", "IC_sfxVol" }) do
		plr:GetAttributeChangedSignal(a):Connect(applyVolumes)
	end
	gSFX.Volume = volume("sfx")
	gMusic.Volume = volume("music")

	---------------------------------------------------------------- generic UI sounds (no edits to other files)
	local hooked = setmetatable({}, { __mode = "k" })
	local function isHoverTarget(b) return b.Name == "Button" or b.Name:sub(1, 3) == "Tab" end
	local function hook(b)
		if hooked[b] or not b:IsA("GuiButton") then return end
		if b.Name == "Modal" then return end -- full-screen modal backdrop
		hooked[b] = true
		b.Activated:Connect(function()
			if b:GetAttribute("IC_NoClick") then return end
			local t = os.clock()
			-- if the button's own handler plays a specific sound right away, skip the generic click
			task.delay(0.03, function()
				if lastExplicit >= t - 0.005 then return end
				play(b.Name:sub(1, 3) == "Tab" and "tab_open" or "ui_click", nil, false)
			end)
		end)
		if isHoverTarget(b) then
			b.MouseEnter:Connect(function()
				if b:GetAttribute("IC_NoClick") then return end
				if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then return end
				play("ui_hover", nil, false)
			end)
		end
	end
	local function watch(gui)
		if not gui then return end
		for _, d in ipairs(gui:GetDescendants()) do hook(d) end
		gui.DescendantAdded:Connect(hook)
	end
	local pgui = plr:WaitForChild("PlayerGui")
	watch(pgui:FindFirstChild("IdleCountryHUD"))
	pgui.ChildAdded:Connect(function(c) if c.Name == "IdleCountryHUD" then watch(c) end end)

	---------------------------------------------------------------- toasts ping
	local origToast = App.toast
	if origToast then
		App.toast = function(title, body, tone, ...)
			local r = origToast(title, body, tone, ...)
			play(tone == "bad" and "error" or "notify", nil, true)
			return r
		end
	end

	---------------------------------------------------------------- go (init runs after the first full sync)
	task.delay(1, function()
		musicStarted = true
		if musicOn() and not current then App.music(true) end
	end)
end }

return M
