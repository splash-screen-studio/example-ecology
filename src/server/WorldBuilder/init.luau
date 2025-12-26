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

local WorldBuilder = {}

-- Types
export type WorldConfig = {
	size: Vector3?,
	center: Vector3?,
	waterLevel: number?,
	seed: number?,
	terrariumShape: "dome" | "box"?,
	skipTerrain: boolean?,
	skipWater: boolean?,
	skipTerrarium: boolean?,
}

-- Default configuration for Verdant Basin
local DEFAULT_CONFIG: WorldConfig = {
	size = Vector3.new(400, 150, 400),
	center = Vector3.zero,
	waterLevel = 5,
	seed = 42,
	terrariumShape = "box",
}

--------------------------------------------------------------------------------
-- WORLD BUILDING
--------------------------------------------------------------------------------

function WorldBuilder:buildWorld(config: WorldConfig?)
	config = config or {}

	-- Merge with defaults
	local finalConfig = {
		size = config.size or DEFAULT_CONFIG.size,
		center = config.center or DEFAULT_CONFIG.center,
		waterLevel = config.waterLevel or DEFAULT_CONFIG.waterLevel,
		seed = config.seed or DEFAULT_CONFIG.seed,
		terrariumShape = config.terrariumShape or DEFAULT_CONFIG.terrariumShape,
	}

	print("========================================")
	print("[WorldBuilder] Starting world generation")
	print(string.format("  Size: %s", tostring(finalConfig.size)))
	print(string.format("  Center: %s", tostring(finalConfig.center)))
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
			baseHeight = 0,
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
	local finalConfig = {
		size = config.size or DEFAULT_CONFIG.size,
		center = config.center or DEFAULT_CONFIG.center,
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
