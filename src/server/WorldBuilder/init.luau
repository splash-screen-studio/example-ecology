--!strict
--[[
    WorldBuilder

    Main module for world generation. Coordinates terrain, water, and enclosure.

    Usage:
        local WorldBuilder = require(script.Parent.WorldBuilder)
        WorldBuilder:buildWorld()
]]

local TerrainGenerator = require(script.TerrainGenerator)
local Terrarium = require(script.Terrarium)
local PlaceConfig = require(game:GetService("ReplicatedStorage").Shared.PlaceConfig)

local WorldBuilder = {}

-- Types
export type WorldConfig = {
	size: Vector3?,
	center: Vector3?,
	waterLevel: number?,
	baseHeight: number?,
	seed: number?,
	terrariumShape: "dome" | "box"?,
	skipTerrain: boolean?,
	skipWater: boolean?,
	skipTerrarium: boolean?,
}

-- Get defaults from PlaceConfig (shared across all places)
local function getDefaultConfig(): WorldConfig
	local terrainConfig = PlaceConfig.getTerrainConfig()
	return {
		size = terrainConfig.size,
		center = terrainConfig.center,
		waterLevel = terrainConfig.waterLevel,
		baseHeight = terrainConfig.baseHeight,
		seed = terrainConfig.seed,
		terrariumShape = terrainConfig.terrariumShape,
	}
end

--------------------------------------------------------------------------------
-- WORLD BUILDING
--------------------------------------------------------------------------------

function WorldBuilder:buildWorld(config: WorldConfig?)
	config = config or {}
	local defaults = getDefaultConfig()

	-- Merge with defaults from PlaceConfig
	local finalConfig = {
		size = config.size or defaults.size,
		center = config.center or defaults.center,
		waterLevel = config.waterLevel or defaults.waterLevel,
		baseHeight = config.baseHeight or defaults.baseHeight,
		seed = config.seed or defaults.seed,
		terrariumShape = config.terrariumShape or defaults.terrariumShape,
	}

	print("========================================")
	print("[WorldBuilder] Starting world generation")
	print(string.format("  Size: %s", tostring(finalConfig.size)))
	print(string.format("  Center: %s", tostring(finalConfig.center)))
	print(string.format("  Base Height: %d", finalConfig.baseHeight))
	print(string.format("  Water Level: %d", finalConfig.waterLevel))
	print(string.format("  Seed: %d", finalConfig.seed))
	print("========================================")

	local startTime = tick()

	-- Step 1: Generate terrain
	if not config.skipTerrain then
		print("\n[WorldBuilder] Step 1: Generating terrain...")
		TerrainGenerator:generate({
			center = finalConfig.center,
			size = finalConfig.size,
			baseHeight = finalConfig.baseHeight,
			waterLevel = finalConfig.waterLevel,
			seed = finalConfig.seed,
		})
	end

	-- Step 2: Fill water
	if not config.skipWater then
		print("\n[WorldBuilder] Step 2: Filling water...")
		TerrainGenerator:generateWater({
			center = finalConfig.center,
			size = finalConfig.size,
			waterLevel = finalConfig.waterLevel,
			seed = finalConfig.seed,
		})
	end

	-- Step 3: Create terrarium enclosure
	if not config.skipTerrarium then
		print("\n[WorldBuilder] Step 3: Creating terrarium...")
		Terrarium:create({
			center = finalConfig.center,
			size = finalConfig.size,
			shape = finalConfig.terrariumShape,
		})
	end

	local elapsed = tick() - startTime
	print("\n========================================")
	print(string.format("[WorldBuilder] World generation complete in %.2f seconds", elapsed))
	print("========================================")
end

function WorldBuilder:clearWorld(config: WorldConfig?)
	config = config or {}
	local defaults = getDefaultConfig()
	local finalConfig = {
		size = config.size or defaults.size,
		center = config.center or defaults.center,
	}

	print("[WorldBuilder] Clearing world...")

	TerrainGenerator:clear({
		center = finalConfig.center,
		size = finalConfig.size,
		baseHeight = 0,
		seed = 0,
	})

	Terrarium:destroy()

	print("[WorldBuilder] World cleared")
end

function WorldBuilder:rebuildWorld(config: WorldConfig?)
	self:clearWorld(config)
	task.wait(0.5) -- Brief pause between clear and rebuild
	self:buildWorld(config)
end

-- Export sub-modules
WorldBuilder.TerrainGenerator = TerrainGenerator
WorldBuilder.Terrarium = Terrarium

return WorldBuilder
