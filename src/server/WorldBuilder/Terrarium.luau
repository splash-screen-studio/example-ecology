--!strict
--[[
    Terrarium

    Creates a glass dome/box enclosure around the world.
    Players are observers/caretakers of a contained ecosystem.

    Usage:
        local Terrarium = require(script.Terrarium)
        Terrarium:create({
            center = Vector3.zero,
            size = Vector3.new(500, 200, 500),
            shape = "dome",  -- or "box"
        })
]]

local Terrarium = {}

-- Types
export type TerrariumConfig = {
	center: Vector3,
	size: Vector3,
	shape: "dome" | "box"?,
	wallThickness: number?,
	transparency: number?,
	tint: Color3?,
}

-- Configuration
local DEFAULT_CONFIG = {
	WALL_THICKNESS = 8,
	TRANSPARENCY = 0.6,
	TINT = Color3.fromRGB(200, 235, 225), -- Slight green-blue tint
	DOME_SEGMENTS = 24,
}

-- Services
local Workspace = game:GetService("Workspace")

--------------------------------------------------------------------------------
-- UTILITY
--------------------------------------------------------------------------------

local function createGlassPart(name: string, size: Vector3, cframe: CFrame, config: TerrariumConfig): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Material = Enum.Material.Glass
	part.Transparency = config.transparency or DEFAULT_CONFIG.TRANSPARENCY
	part.Color = config.tint or DEFAULT_CONFIG.TINT
	part.CanCollide = true
	part.Anchored = true
	part.CastShadow = false

	-- Add slight reflection
	local surfaceAppearance = Instance.new("SurfaceAppearance")
	surfaceAppearance.Name = "GlassAppearance"
	surfaceAppearance.Parent = part

	return part
end

--------------------------------------------------------------------------------
-- BOX ENCLOSURE
--------------------------------------------------------------------------------

local function createBox(config: TerrariumConfig): Folder
	local container = Instance.new("Folder")
	container.Name = "Terrarium"

	local center = config.center
	local size = config.size
	local thickness = config.wallThickness or DEFAULT_CONFIG.WALL_THICKNESS
	local halfX, halfY, halfZ = size.X / 2, size.Y / 2, size.Z / 2

	-- North wall (+Z)
	local northWall = createGlassPart(
		"NorthWall",
		Vector3.new(size.X + thickness * 2, size.Y, thickness),
		CFrame.new(center.X, center.Y + halfY, center.Z + halfZ + thickness / 2),
		config
	)
	northWall.Parent = container

	-- South wall (-Z)
	local southWall = createGlassPart(
		"SouthWall",
		Vector3.new(size.X + thickness * 2, size.Y, thickness),
		CFrame.new(center.X, center.Y + halfY, center.Z - halfZ - thickness / 2),
		config
	)
	southWall.Parent = container

	-- East wall (+X)
	local eastWall = createGlassPart(
		"EastWall",
		Vector3.new(thickness, size.Y, size.Z),
		CFrame.new(center.X + halfX + thickness / 2, center.Y + halfY, center.Z),
		config
	)
	eastWall.Parent = container

	-- West wall (-X)
	local westWall = createGlassPart(
		"WestWall",
		Vector3.new(thickness, size.Y, size.Z),
		CFrame.new(center.X - halfX - thickness / 2, center.Y + halfY, center.Z),
		config
	)
	westWall.Parent = container

	-- Ceiling
	local ceiling = createGlassPart(
		"Ceiling",
		Vector3.new(size.X + thickness * 2, thickness, size.Z + thickness * 2),
		CFrame.new(center.X, center.Y + size.Y + thickness / 2, center.Z),
		config
	)
	ceiling.Parent = container

	-- Floor (optional, usually terrain)
	local floor = createGlassPart(
		"Floor",
		Vector3.new(size.X + thickness * 2, thickness, size.Z + thickness * 2),
		CFrame.new(center.X, center.Y - 50 - thickness / 2, center.Z),
		config
	)
	floor.Transparency = 0.8 -- More transparent floor
	floor.Parent = container

	return container
end

--------------------------------------------------------------------------------
-- DOME ENCLOSURE
--------------------------------------------------------------------------------

local function createDome(config: TerrariumConfig): Folder
	local container = Instance.new("Folder")
	container.Name = "Terrarium"

	local center = config.center
	local size = config.size
	local thickness = config.wallThickness or DEFAULT_CONFIG.WALL_THICKNESS
	local segments = DEFAULT_CONFIG.DOME_SEGMENTS

	local radiusX = size.X / 2
	local radiusZ = size.Z / 2
	local height = size.Y

	-- Create dome using wedge approximation
	for i = 0, segments - 1 do
		local angle1 = (i / segments) * math.pi * 2
		local angle2 = ((i + 1) / segments) * math.pi * 2

		-- Vertical rings
		local verticalSegments = math.floor(segments / 2)
		for j = 0, verticalSegments - 1 do
			local vAngle1 = (j / verticalSegments) * math.pi / 2
			local vAngle2 = ((j + 1) / verticalSegments) * math.pi / 2

			-- Calculate four corners of this quad
			local function getPoint(hAngle: number, vAngle: number): Vector3
				local r = math.cos(vAngle)
				local y = math.sin(vAngle) * height
				local x = math.cos(hAngle) * radiusX * r
				local z = math.sin(hAngle) * radiusZ * r
				return Vector3.new(center.X + x, center.Y + y, center.Z + z)
			end

			local p1 = getPoint(angle1, vAngle1)
			local p2 = getPoint(angle2, vAngle1)
			local p3 = getPoint(angle1, vAngle2)
			local p4 = getPoint(angle2, vAngle2)

			-- Create a part for this segment
			local segmentCenter = (p1 + p2 + p3 + p4) / 4
			local segmentSize = Vector3.new(
				math.max((p2 - p1).Magnitude, (p4 - p3).Magnitude) + thickness,
				math.max((p3 - p1).Magnitude, (p4 - p2).Magnitude) + thickness,
				thickness
			)

			-- Calculate orientation
			local normal = ((p2 - p1):Cross(p3 - p1)).Unit
			local lookAt = segmentCenter + normal

			local segment = createGlassPart(
				string.format("DomeSegment_%d_%d", i, j),
				segmentSize,
				CFrame.lookAt(segmentCenter, lookAt),
				config
			)
			segment.Parent = container
		end
	end

	-- Base ring (cylinder walls)
	for i = 0, segments - 1 do
		local angle = (i / segments) * math.pi * 2
		local nextAngle = ((i + 1) / segments) * math.pi * 2

		local x1 = center.X + math.cos(angle) * radiusX
		local z1 = center.Z + math.sin(angle) * radiusZ
		local x2 = center.X + math.cos(nextAngle) * radiusX
		local z2 = center.Z + math.sin(nextAngle) * radiusZ

		local wallCenter = Vector3.new((x1 + x2) / 2, center.Y + height / 4, (z1 + z2) / 2)
		local wallLength = math.sqrt((x2 - x1) ^ 2 + (z2 - z1) ^ 2)
		local wallAngle = math.atan2(z2 - z1, x2 - x1)

		local wall = createGlassPart(
			string.format("BaseWall_%d", i),
			Vector3.new(wallLength, height / 2, thickness),
			CFrame.new(wallCenter) * CFrame.Angles(0, -wallAngle, 0),
			config
		)
		wall.Parent = container
	end

	-- Floor
	local floor = createGlassPart(
		"Floor",
		Vector3.new(size.X + thickness * 2, thickness, size.Z + thickness * 2),
		CFrame.new(center.X, center.Y - 50 - thickness / 2, center.Z),
		config
	)
	floor.Transparency = 0.8
	floor.Parent = container

	return container
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function Terrarium:create(config: TerrariumConfig): Folder
	local shape = config.shape or "box"

	print(string.format("[Terrarium] Creating %s enclosure...", shape))

	local container: Folder
	if shape == "dome" then
		container = createDome(config)
	else
		container = createBox(config)
	end

	container.Parent = Workspace

	-- Add atmosphere for contained feeling
	self:setupAtmosphere(config)

	print("[Terrarium] Enclosure created")
	return container
end

function Terrarium:setupAtmosphere(config: TerrariumConfig)
	local lighting = game:GetService("Lighting")

	-- Create or update atmosphere
	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = lighting
	end

	-- Soft, contained atmosphere
	atmosphere.Density = 0.3
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(200, 220, 210)
	atmosphere.Decay = Color3.fromRGB(180, 200, 190)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.5

	-- Ensure Sky exists for atmosphere to work
	local sky = lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = lighting
	end
end

function Terrarium:destroy()
	local existing = Workspace:FindFirstChild("Terrarium")
	if existing then
		existing:Destroy()
		print("[Terrarium] Enclosure destroyed")
	end
end

return Terrarium
