--!strict
-- PixelArt: draws Build a Swarm's arena in pixel art from one uploaded atlas.
--
-- Fits the game as it is built (see BACKLOG.md):
--   * The arena is a 2D GUI (floor at ZIndex 1, entities from 3 up), so every
--     sprite is an ImageLabel with ResamplerMode.Pixelated: square, crisp pixels.
--   * Its own ModuleScript, so it costs the 860k GameClient ceiling nothing.
--     Require it inside an IIFE, not a bare `do` block, to keep the main
--     chunk's register peak where it is (LESSONS #15).
--   * Bees keep the shape book's channels. SHAPE = silhouette (bee_<shape>),
--     COLOUR = element (ImageColor3 on the tint layer), PAINT = rarity
--     (overlays). One drawing serves every palette in BeeShapes.
--
-- Cost per unit: an enemy is 1 ImageLabel, a bee is a Frame + 2 ImageLabels
-- (+1 for Epic, +2 for Legendary). The primitive-built bee is up to 9 Frames.
-- Every sprite shares one texture, and one Heartbeat animates all of them.

local RunService = game:GetService("RunService")

local Atlas = require(script.Atlas)

local PixelArt = {}

-- TODO: upload art/upload/atlas.png and paste the id. Upload it under the SAME
-- owner as the experience (group or user) or it will never render; that is
-- what the "doesn't have access permission to use asset id" warning means.
PixelArt.ATLAS_ID = "rbxassetid://0"
PixelArt.ARENA_ID = "rbxassetid://0" -- art/upload/arena_bg.png

-- Screen pixels per art pixel. A 12px bee at 2 is 24px, the size the shape
-- book reads silhouettes at. Multiply by the arena scale on resize.
PixelArt.SCALE = 2

PixelArt.RARITY_COLOUR = {
	Epic = Color3.fromRGB(190, 120, 255),
	Legendary = Color3.fromRGB(255, 210, 60),
}

type Frame = { number }
type Sprite = ImageLabel | ImageButton

local function frameOf(name: string, index: number): Frame
	local frames = Atlas.Sprites[name]
	assert(frames, `PixelArt: no sprite named {name}`)
	return frames[((index - 1) % #frames) + 1]
end

function PixelArt.setFrame(label: Sprite, name: string, index: number?)
	local f = frameOf(name, index or 1)
	label.ImageRectOffset = Vector2.new(f[1], f[2])
	label.ImageRectSize = Vector2.new(f[3], f[4])
end

function PixelArt.pixelSize(name: string): Vector2
	local f = frameOf(name, 1)
	return Vector2.new(f[3], f[4])
end

-- One sprite. Anchored at its centre so Position is the unit's position and
-- Rotation spins it in place.
function PixelArt.new(name: string, parent: Instance?, scale: number?): ImageLabel
	local s = scale or PixelArt.SCALE
	local px = PixelArt.pixelSize(name)
	local label = Instance.new("ImageLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Image = PixelArt.ATLAS_ID
	label.ResamplerMode = Enum.ResamplerMode.Pixelated
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = UDim2.fromOffset(px.X * s, px.Y * s)
	PixelArt.setFrame(label, name, 1)
	label.Parent = parent
	return label
end

-- A child layer centred inside a bee's container.
local function layer(name: string, parent: Instance, s: number, z: number, offset: Vector2?): ImageLabel
	local l = PixelArt.new(name, parent, s)
	l.Position = UDim2.new(0.5, (offset and offset.X or 0) * s, 0.5, (offset and offset.Y or 0) * s)
	l.ZIndex = z
	return l
end

-- A bee: container Frame holding the tinted body and the line art on top.
--   shape   "orbiter" | "interceptor" | "sentry" | "guardian" | "charger" | "escort" | "worker"
--   colour  the element colour from the bee's palette in BeeShapes
--   rarity  "Common" | "Rare" | "Epic" | "Legendary" (optional)
-- Position/Rotation go on the returned Frame; ZIndex goes on its layers, so
-- pass the bee's Z band base as `z`.
function PixelArt.newBee(shape: string, colour: Color3, rarity: string?, parent: Instance?, z: number?, scale: number?): Frame
	local s = scale or PixelArt.SCALE
	local z0 = z or 3
	local base = "bee_" .. shape
	local px = PixelArt.pixelSize(base)

	local bee = Instance.new("Frame")
	bee.Name = base
	bee.BackgroundTransparency = 1
	bee.AnchorPoint = Vector2.new(0.5, 0.5)
	bee.Size = UDim2.fromOffset(px.X * s, px.Y * s)

	if rarity == "Epic" or rarity == "Legendary" then
		local aura = layer("rarity_aura", bee, s, z0)
		aura.ImageColor3 = PixelArt.RARITY_COLOUR[rarity]
	end
	local tint = layer(base .. "_tint", bee, s, z0 + 1)
	tint.ImageColor3 = colour
	local art = layer(base, bee, s, z0 + 2)
	if rarity == "Rare" then
		layer("rarity_shine", bee, s, z0 + 3, Vector2.new(-3, -1))
	elseif rarity == "Legendary" then
		layer("rarity_crown", bee, s, z0 + 3, Vector2.new(0, -8))
	end

	-- Both layers share one clock so the body and wings flap together.
	local t0 = math.random() * 2
	PixelArt.animate(tint, base .. "_tint", 10, t0)
	PixelArt.animate(art, base, 10, t0)

	bee.Parent = parent
	return bee
end

-- A bee's shot, tinted to its element.
function PixelArt.newShot(colour: Color3, parent: Instance?, scale: number?): ImageLabel
	local shot = PixelArt.new("shot_bee", parent, scale)
	shot.ImageColor3 = colour
	return shot
end

-- The baked arena floor: ONE ImageLabel at ZIndex 1. Crop keeps pixels square
-- on any screen shape; the grass border is what gets trimmed on narrow ones.
function PixelArt.arena(parent: Instance): ImageLabel
	local bg = Instance.new("ImageLabel")
	bg.Name = "PixelArena"
	bg.BackgroundTransparency = 1
	bg.Size = UDim2.fromScale(1, 1)
	bg.ZIndex = 1
	bg.Image = PixelArt.ARENA_ID
	bg.ScaleType = Enum.ScaleType.Crop
	bg.ResamplerMode = Enum.ResamplerMode.Pixelated
	bg.Parent = parent
	return bg
end

-- Pixel art turned to odd angles gets jaggy. 8 directions reads cleanly.
-- Use for bees and bugs; aim the weapon smoothly.
function PixelArt.snapRotation(degrees: number): number
	return math.round(degrees / 45) * 45
end

---------------------------------------------------------------------------
-- Animation: one Heartbeat for every animated sprite in the arena.
---------------------------------------------------------------------------

type Anim = { name: string, fps: number, count: number, t: number, frame: number }

local animating: { [Sprite]: Anim } = setmetatable({}, { __mode = "k" }) :: any
local connection: RBXScriptConnection? = nil

local function step(dt: number)
	for label, a in animating do
		if label.Parent == nil then
			animating[label] = nil
			continue
		end
		a.t += dt
		local frame = (math.floor(a.t * a.fps) % a.count) + 1
		if frame ~= a.frame then
			a.frame = frame
			PixelArt.setFrame(label, a.name, frame)
		end
	end
	if next(animating) == nil and connection then
		connection:Disconnect()
		connection = nil
	end
end

-- `t0` lets layers share a clock; leave it out and each sprite gets a random
-- start so a swarm doesn't flap in lockstep.
function PixelArt.animate(label: Sprite, name: string, fps: number?, t0: number?)
	local count = #Atlas.Sprites[name]
	if count <= 1 then
		PixelArt.setFrame(label, name, 1)
		return
	end
	animating[label] = { name = name, fps = fps or 8, count = count, t = t0 or math.random() * 2, frame = 0 }
	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
end

function PixelArt.stop(label: Sprite)
	animating[label] = nil
end

return PixelArt
