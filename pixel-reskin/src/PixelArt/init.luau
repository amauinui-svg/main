--!strict
-- PixelArt: draws Build a Swarm's pixel sprites from one uploaded atlas image.
--
-- Why this is cheap: every bee, bug, projectile and decoration comes from the
-- SAME texture (atlas.png), so the client downloads and keeps one image in
-- memory. Animation just moves ImageRectOffset; nothing gets created or
-- destroyed per frame, and one Heartbeat connection drives every animated
-- sprite instead of one loop per unit.
--
-- Usage (2D / ScreenGui playfield):
--     local PixelArt = require(ReplicatedStorage.PixelArt)
--     local bee = PixelArt.new("bee_yellow", playfield)   -- ImageLabel
--     bee.Position = UDim2.fromOffset(x, y)
--     PixelArt.animate(bee, "bee_yellow", 8)               -- 8 fps wing flap
--
-- Usage (3D parts seen from a top down camera):
--     PixelArt.attach(enemyModel.PrimaryPart, "enemy_ant")  -- BillboardGui

local RunService = game:GetService("RunService")

local Atlas = require(script.Atlas)

local PixelArt = {}

-- TODO: upload art/upload/atlas.png (Creator Hub, or Asset Manager in Studio)
-- and paste its id here.
PixelArt.ATLAS_ID = "rbxassetid://0"

-- Screen pixels per art pixel. 4 matches the mockup (480x270 art -> 1080p).
PixelArt.SCALE = 4

-- Studs per art pixel for world sprites. Tune to your map's unit sizes.
PixelArt.STUDS_PER_PIXEL = 0.25

type Frame = { number }

local function frameOf(name: string, index: number): Frame
	local frames = Atlas.Sprites[name]
	assert(frames, `PixelArt: no sprite named {name}`)
	return frames[((index - 1) % #frames) + 1]
end

-- Point an existing ImageLabel/ImageButton at a sprite frame (1 based).
function PixelArt.setFrame(label: ImageLabel | ImageButton, name: string, index: number?)
	local f = frameOf(name, index or 1)
	label.ImageRectOffset = Vector2.new(f[1], f[2])
	label.ImageRectSize = Vector2.new(f[3], f[4])
end

-- Size in art pixels of a sprite's first frame.
function PixelArt.pixelSize(name: string): Vector2
	local f = frameOf(name, 1)
	return Vector2.new(f[3], f[4])
end

function PixelArt.new(name: string, parent: Instance?, scale: number?): ImageLabel
	local s = scale or PixelArt.SCALE
	local px = PixelArt.pixelSize(name)
	local label = Instance.new("ImageLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Image = PixelArt.ATLAS_ID
	-- The key line: nearest neighbour scaling keeps every pixel a crisp square.
	label.ResamplerMode = Enum.ResamplerMode.Pixelated
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Size = UDim2.fromOffset(px.X * s, px.Y * s)
	PixelArt.setFrame(label, name, 1)
	label.Parent = parent
	return label
end

-- World sprite for 3D units: a BillboardGui on the part, sized in studs.
function PixelArt.attach(part: BasePart, name: string, studsPerPixel: number?): ImageLabel
	local spp = studsPerPixel or PixelArt.STUDS_PER_PIXEL
	local px = PixelArt.pixelSize(name)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PixelSprite"
	gui.Size = UDim2.fromScale(px.X * spp, px.Y * spp)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Adornee = part
	local label = PixelArt.new(name, gui)
	label.Size = UDim2.fromScale(1, 1)
	label.Position = UDim2.fromScale(0.5, 0.5)
	gui.Parent = part
	return label
end

-- Snap a rotation to 45 degree steps. Pixel art rotated to odd angles gets
-- jaggy; 8 directions reads cleanly (the reference game does the same).
function PixelArt.snapRotation(degrees: number): number
	return math.round(degrees / 45) * 45
end

---------------------------------------------------------------------------
-- Animation: one shared Heartbeat for every animated sprite.
---------------------------------------------------------------------------

type Anim = { name: string, fps: number, count: number, t: number, frame: number }

local animating: { [ImageLabel | ImageButton]: Anim } = setmetatable({}, { __mode = "k" }) :: any
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

function PixelArt.animate(label: ImageLabel | ImageButton, name: string, fps: number?)
	local count = #Atlas.Sprites[name]
	if count <= 1 then
		PixelArt.setFrame(label, name, 1)
		return
	end
	-- Random start time so a swarm of bees doesn't flap in perfect sync.
	animating[label] = { name = name, fps = fps or 8, count = count, t = math.random() * 2, frame = 0 }
	if not connection then
		connection = RunService.Heartbeat:Connect(step)
	end
end

function PixelArt.stop(label: ImageLabel | ImageButton)
	animating[label] = nil
end

---------------------------------------------------------------------------
-- Ground
---------------------------------------------------------------------------

-- 2D: a tiled background ImageLabel. Upload art/upload/tile_*.png (1x).
function PixelArt.tiledGround(imageId: string, parent: Instance, scale: number?): ImageLabel
	local s = scale or PixelArt.SCALE
	local bg = Instance.new("ImageLabel")
	bg.Name = "PixelGround"
	bg.BackgroundTransparency = 1
	bg.Size = UDim2.fromScale(1, 1)
	bg.ZIndex = 0
	bg.Image = imageId
	bg.ScaleType = Enum.ScaleType.Tile
	bg.TileSize = UDim2.fromOffset(32 * s, 32 * s)
	bg.ResamplerMode = Enum.ResamplerMode.Pixelated
	bg.Parent = parent
	return bg
end

-- 3D: a Texture on the floor part. Upload art/upload/tile_*_x8.png; Textures
-- can't use Pixelated, so the 8x upscale is what keeps the pixels sharp.
function PixelArt.floorTexture(floor: BasePart, imageId: string, studsPerPixel: number?): Texture
	local spp = studsPerPixel or PixelArt.STUDS_PER_PIXEL
	local tex = Instance.new("Texture")
	tex.Name = "PixelGround"
	tex.Face = Enum.NormalId.Top
	tex.Texture = imageId
	tex.StudsPerTileU = 32 * spp
	tex.StudsPerTileV = 32 * spp
	floor.Material = Enum.Material.SmoothPlastic
	tex.Parent = floor
	return tex
end

return PixelArt
