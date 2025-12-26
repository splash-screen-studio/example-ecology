--!strict
--[[
    TerrainGenerator

    Generates natural undulating terrain using layered Perlin noise.
    Creates realistic material distribution based on elevation and slope.

    Usage:
        local TerrainGenerator = require(script.TerrainGenerator)
        TerrainGenerator:generate({
            center = Vector3.zero,
            size = Vector3.new(500, 100, 500),
        })
]]

local TerrainGenerator = {}

-- Types
export type TerrainConfig = {
	center: Vector3,
	size: Vector3,
	baseHeight: number?,
	waterLevel: number?,
	seed: number?,
}

-- Configuration
local DEFAULT_CONFIG = {
	VOXEL_RESOLUTION = 4,
	BASE_HEIGHT = 0,
	WATER_LEVEL = 5,
	SEED = 12345,

	-- Noise layers for natural terrain
	NOISE_LAYERS = {
		{ scale = 0.008, amplitude = 25, name = "continental" }, -- Large rolling hills
		{ scale = 0.025, amplitude = 12, name = "hills" }, -- Medium undulations
		{ scale = 0.08, amplitude = 5, name = "bumps" }, -- Small variations
		{ scale = 0.2, amplitude = 2, name = "roughness" }, -- Fine detail
	},
}

-- Services
local Workspace = game:GetService("Workspace")

--------------------------------------------------------------------------------
-- NOISE GENERATION
--------------------------------------------------------------------------------

local function octaveNoise(x: number, z: number, seed: number): number
	local height = 0

	for _, layer in DEFAULT_CONFIG.NOISE_LAYERS do
		local nx = x * layer.scale + seed
		local nz = z * layer.scale + seed * 0.7
		height = height + math.noise(nx, nz) * layer.amplitude
	end

	return height
end

local function generateHeight(x: number, z: number, config: TerrainConfig): number
	local seed = config.seed or DEFAULT_CONFIG.SEED
	local baseHeight = config.baseHeight or DEFAULT_CONFIG.BASE_HEIGHT

	-- Generate base terrain height
	local height = octaveNoise(x, z, seed) + baseHeight

	-- Create natural valleys (lower areas collect water)
	local valleyNoise = math.noise(x * 0.015 + seed * 2, z * 0.015 + seed * 2)
	if valleyNoise < -0.3 then
		height = height - 10 * math.abs(valleyNoise + 0.3)
	end

	-- Create occasional plateaus
	local plateauNoise = math.noise(x * 0.005 + seed * 3, z * 0.005 + seed * 3)
	if plateauNoise > 0.5 then
		height = height + 15 * (plateauNoise - 0.5)
	end

	return height
end

--------------------------------------------------------------------------------
-- MATERIAL SELECTION
--------------------------------------------------------------------------------

local function calculateSlope(x: number, z: number, config: TerrainConfig): number
	local delta = DEFAULT_CONFIG.VOXEL_RESOLUTION
	local h1 = generateHeight(x - delta, z, config)
	local h2 = generateHeight(x + delta, z, config)
	local h3 = generateHeight(x, z - delta, config)
	local h4 = generateHeight(x, z + delta, config)

	local slopeX = math.abs(h2 - h1) / (2 * delta)
	local slopeZ = math.abs(h4 - h3) / (2 * delta)

	return math.sqrt(slopeX * slopeX + slopeZ * slopeZ)
end

local function selectMaterial(x: number, z: number, height: number, config: TerrainConfig): Enum.Material
	local waterLevel = config.waterLevel or DEFAULT_CONFIG.WATER_LEVEL
	local slope = calculateSlope(x, z, config)
	local seed = config.seed or DEFAULT_CONFIG.SEED

	-- Steep slopes get rock
	if slope > 0.8 then
		return Enum.Material.Rock
	end

	if slope > 0.5 then
		-- Mix of rock and ground
		local rockChance = math.noise(x * 0.1 + seed, z * 0.1 + seed)
		if rockChance > 0.3 then
			return Enum.Material.Rock
		end
		return Enum.Material.Ground
	end

	-- Below or near water level
	if height < waterLevel - 2 then
		return Enum.Material.Mud
	end

	if height < waterLevel + 3 then
		-- Shoreline / marsh
		local marshNoise = math.noise(x * 0.08 + seed, z * 0.08 + seed)
		if marshNoise > 0 then
			return Enum.Material.Sand
		end
		return Enum.Material.Mud
	end

	-- Above water - vegetation zones
	local vegetationNoise = math.noise(x * 0.03 + seed * 5, z * 0.03 + seed * 5)

	if vegetationNoise > 0.4 then
		-- Dense vegetation
		return Enum.Material.LeafyGrass
	elseif vegetationNoise > 0 then
		return Enum.Material.Grass
	else
		return Enum.Material.Ground
	end
end

--------------------------------------------------------------------------------
-- TERRAIN GENERATION
--------------------------------------------------------------------------------

function TerrainGenerator:generate(config: TerrainConfig)
	local terrain = Workspace.Terrain
	local resolution = DEFAULT_CONFIG.VOXEL_RESOLUTION

	local minX = config.center.X - config.size.X / 2
	local maxX = config.center.X + config.size.X / 2
	local minZ = config.center.Z - config.size.Z / 2
	local maxZ = config.center.Z + config.size.Z / 2

	print(string.format("[TerrainGenerator] Generating terrain from (%d,%d) to (%d,%d)", minX, minZ, maxX, maxZ))

	local startTime = tick()
	local blockCount = 0

	-- Generate terrain column by column
	for x = minX, maxX, resolution do
		for z = minZ, maxZ, resolution do
			local height = generateHeight(x, z, config)
			local material = selectMaterial(x, z, height, config)

			-- Fill from bottom to height
			local minY = -50 -- Below ground base
			local maxY = height

			if maxY > minY then
				local regionSize = Vector3.new(resolution, maxY - minY, resolution)
				local regionCenter = Vector3.new(x, (minY + maxY) / 2, z)

				terrain:FillBlock(CFrame.new(regionCenter), regionSize, material)
				blockCount = blockCount + 1
			end
		end

		-- Yield periodically to prevent timeout
		if blockCount % 500 == 0 then
			task.wait()
		end
	end

	local elapsed = tick() - startTime
	print(string.format("[TerrainGenerator] Generated %d blocks in %.2f seconds", blockCount, elapsed))
end

function TerrainGenerator:generateWater(config: TerrainConfig)
	local terrain = Workspace.Terrain
	local waterLevel = config.waterLevel or DEFAULT_CONFIG.WATER_LEVEL
	local resolution = DEFAULT_CONFIG.VOXEL_RESOLUTION

	local minX = config.center.X - config.size.X / 2
	local maxX = config.center.X + config.size.X / 2
	local minZ = config.center.Z - config.size.Z / 2
	local maxZ = config.center.Z + config.size.Z / 2

	print(string.format("[TerrainGenerator] Filling water to level %d", waterLevel))

	-- CRITICAL: First ensure solid floor exists under all water
	-- This prevents swimming under terrain
	print("[TerrainGenerator] Ensuring solid floor under water...")
	local floorLevel = -30 -- Guaranteed floor level
	local floorRegion = Region3.new(
		Vector3.new(minX, floorLevel - 10, minZ),
		Vector3.new(maxX, floorLevel, maxZ)
	):ExpandToGrid(resolution)

	terrain:FillRegion(floorRegion, resolution, Enum.Material.Rock)

	-- Fill water above the floor, below water level
	local waterRegion = Region3.new(
		Vector3.new(minX, floorLevel, minZ),
		Vector3.new(maxX, waterLevel, maxZ)
	):ExpandToGrid(resolution)

	terrain:FillRegion(waterRegion, resolution, Enum.Material.Water)

	print("[TerrainGenerator] Water generation complete with guaranteed floor")
end

function TerrainGenerator:ensureSolidFloor(config: TerrainConfig)
	--[[
		Creates a guaranteed solid floor at the bottom of the world.
		Call this before generating water to prevent swimming under terrain.
	]]
	local terrain = Workspace.Terrain
	local resolution = DEFAULT_CONFIG.VOXEL_RESOLUTION

	local minX = config.center.X - config.size.X / 2
	local maxX = config.center.X + config.size.X / 2
	local minZ = config.center.Z - config.size.Z / 2
	local maxZ = config.center.Z + config.size.Z / 2

	local floorLevel = -50
	local floorThickness = 20

	local floorRegion = Region3.new(
		Vector3.new(minX - 20, floorLevel - floorThickness, minZ - 20),
		Vector3.new(maxX + 20, floorLevel, maxZ + 20)
	):ExpandToGrid(resolution)

	terrain:FillRegion(floorRegion, resolution, Enum.Material.Basalt)
	print("[TerrainGenerator] Solid floor created at Y=" .. floorLevel)
end

function TerrainGenerator:clear(config: TerrainConfig)
	local terrain = Workspace.Terrain
	local resolution = DEFAULT_CONFIG.VOXEL_RESOLUTION

	local margin = 10
	local region = Region3.new(
		Vector3.new(
			config.center.X - config.size.X / 2 - margin,
			-100,
			config.center.Z - config.size.Z / 2 - margin
		),
		Vector3.new(
			config.center.X + config.size.X / 2 + margin,
			config.size.Y + 50,
			config.center.Z + config.size.Z / 2 + margin
		)
	):ExpandToGrid(resolution)

	terrain:FillRegion(region, resolution, Enum.Material.Air)
	print("[TerrainGenerator] Terrain cleared")
end

return TerrainGenerator
