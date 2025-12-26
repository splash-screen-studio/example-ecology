--!strict
--[[
    ElevationService

    Provides elevation data for any (x, z) position in the world.
    Returns ground height, terrain material, water levels, and surface normals.

    Performance: O(1) amortized via grid-based caching.

    Usage:
        local ElevationService = require(game.ReplicatedStorage.Shared.ElevationService)

        local result = ElevationService:getElevation(100, 50)
        print(result.groundY, result.waterSurfaceY)
]]

local ElevationService = {}

-- Types
export type ElevationResult = {
	-- Position queried
	x: number,
	z: number,

	-- Ground data
	groundY: number,
	groundMaterial: Enum.Material,
	groundNormal: Vector3,

	-- Water data (nil if no water)
	waterSurfaceY: number?,
	waterBottomY: number?,
	waterDepth: number?,
	isSubmerged: boolean,

	-- Metadata
	isValid: boolean,
	source: string, -- "terrain" | "cached" | "default"
}

export type WaterBody = {
	name: string,
	bounds: { min: Vector3, max: Vector3 },
	surfaceY: number,
}

-- Configuration
local CONFIG = {
	-- Raycast settings
	RAY_ORIGIN_HEIGHT = 1000,
	RAY_LENGTH = 2000,

	-- Cache settings
	CACHE_RESOLUTION = 4, -- studs per cell
	CACHE_MAX_SIZE = 50000, -- max cached cells
	CACHE_TTL = 0, -- 0 = no expiry

	-- Water detection
	WATER_VOXEL_RESOLUTION = 4,
	WATER_SCAN_HEIGHT = 100, -- how high to scan for water surface

	-- Performance
	MAX_BATCH_SIZE = 100,
}

-- State
local cache: { [string]: { result: ElevationResult, timestamp: number } } = {}
local cacheSize = 0
local waterBodies: { WaterBody } = {}

-- Services
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------
-- CACHE UTILITIES
--------------------------------------------------------------------------------

local function getCacheKey(x: number, z: number): string
	local gx = math.floor(x / CONFIG.CACHE_RESOLUTION)
	local gz = math.floor(z / CONFIG.CACHE_RESOLUTION)
	return string.format("%d,%d", gx, gz)
end

local function getCachedResult(x: number, z: number): ElevationResult?
	local key = getCacheKey(x, z)
	local entry = cache[key]

	if entry then
		if CONFIG.CACHE_TTL > 0 then
			local age = tick() - entry.timestamp
			if age > CONFIG.CACHE_TTL then
				cache[key] = nil
				cacheSize = cacheSize - 1
				return nil
			end
		end

		-- Update result position to exact query (cache stores grid center)
		local result = table.clone(entry.result)
		result.x = x
		result.z = z
		result.source = "cached"
		return result
	end

	return nil
end

local function setCachedResult(x: number, z: number, result: ElevationResult)
	-- Evict oldest entries if cache is full (simple FIFO for now)
	if cacheSize >= CONFIG.CACHE_MAX_SIZE then
		-- Clear 10% of cache
		local count = 0
		local toRemove = math.floor(CONFIG.CACHE_MAX_SIZE * 0.1)
		for key in cache do
			cache[key] = nil
			count = count + 1
			if count >= toRemove then
				break
			end
		end
		cacheSize = cacheSize - count
	end

	local key = getCacheKey(x, z)
	if not cache[key] then
		cacheSize = cacheSize + 1
	end

	cache[key] = {
		result = result,
		timestamp = tick(),
	}
end

--------------------------------------------------------------------------------
-- TERRAIN DETECTION
--------------------------------------------------------------------------------

local function getTerrainElevation(x: number, z: number): (number, Enum.Material, Vector3)
	local terrain = Workspace.Terrain
	local origin = Vector3.new(x, CONFIG.RAY_ORIGIN_HEIGHT, z)
	local direction = Vector3.new(0, -CONFIG.RAY_LENGTH, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { terrain }
	params.IgnoreWater = true -- We detect water separately

	local result = Workspace:Raycast(origin, direction, params)

	if result then
		return result.Position.Y, result.Material, result.Normal
	end

	-- No terrain found - return default
	return 0, Enum.Material.Air, Vector3.yAxis
end

--------------------------------------------------------------------------------
-- WATER DETECTION
--------------------------------------------------------------------------------

--[[
    Water detection strategy:
    1. Check known water bodies first (O(n) where n = number of bodies, typically small)
    2. Use ReadVoxels to detect terrain water at specific positions
    3. Binary search to find exact water surface Y
]]

local function isPointInWaterBody(x: number, z: number, y: number): WaterBody?
	for _, body in waterBodies do
		local min, max = body.bounds.min, body.bounds.max
		if x >= min.X and x <= max.X and z >= min.Z and z <= max.Z and y >= min.Y and y <= max.Y then
			return body
		end
	end
	return nil
end

local function detectTerrainWater(x: number, z: number, searchY: number): boolean
	local terrain = Workspace.Terrain
	local halfVoxel = CONFIG.WATER_VOXEL_RESOLUTION / 2

	local region = Region3.new(
		Vector3.new(x - halfVoxel, searchY - halfVoxel, z - halfVoxel),
		Vector3.new(x + halfVoxel, searchY + halfVoxel, z + halfVoxel)
	)

	-- Expand to voxel grid
	region = region:ExpandToGrid(CONFIG.WATER_VOXEL_RESOLUTION)

	local success, materials = pcall(function()
		return terrain:ReadVoxels(region, CONFIG.WATER_VOXEL_RESOLUTION)
	end)

	if not success or not materials then
		return false
	end

	-- Check if any voxel is water
	for _, xMats in materials do
		for _, yMats in xMats do
			for _, material in yMats do
				if material == Enum.Material.Water then
					return true
				end
			end
		end
	end

	return false
end

local function findWaterSurface(x: number, z: number, groundY: number): (number?, number?)
	-- First check known water bodies
	local body = isPointInWaterBody(x, z, groundY)
	if body then
		return body.surfaceY, groundY
	end

	-- Binary search for water surface in terrain
	local low = groundY
	local high = groundY + CONFIG.WATER_SCAN_HEIGHT
	local waterSurfaceY: number? = nil

	-- First, check if there's any water above ground
	local hasWater = false
	for testY = groundY, high, CONFIG.WATER_VOXEL_RESOLUTION do
		if detectTerrainWater(x, z, testY) then
			hasWater = true
			break
		end
	end

	if not hasWater then
		return nil, nil
	end

	-- Binary search to find the top of water
	local iterations = 0
	local maxIterations = 20

	while high - low > CONFIG.WATER_VOXEL_RESOLUTION and iterations < maxIterations do
		iterations = iterations + 1
		local mid = (low + high) / 2

		if detectTerrainWater(x, z, mid) then
			waterSurfaceY = mid
			low = mid
		else
			high = mid
		end
	end

	-- Refine to get the actual surface
	if waterSurfaceY then
		-- The surface is approximately at waterSurfaceY + half voxel
		waterSurfaceY = waterSurfaceY + CONFIG.WATER_VOXEL_RESOLUTION / 2
	end

	return waterSurfaceY, groundY
end

--------------------------------------------------------------------------------
-- CORE API
--------------------------------------------------------------------------------

function ElevationService:getElevation(x: number, z: number): ElevationResult
	-- Check cache first
	local cached = getCachedResult(x, z)
	if cached then
		return cached
	end

	-- Get terrain elevation
	local groundY, groundMaterial, groundNormal = getTerrainElevation(x, z)

	-- Detect water
	local waterSurfaceY, waterBottomY = findWaterSurface(x, z, groundY)
	local waterDepth: number? = nil
	if waterSurfaceY and waterBottomY then
		waterDepth = waterSurfaceY - waterBottomY
	end

	-- Build result
	local result: ElevationResult = {
		x = x,
		z = z,
		groundY = groundY,
		groundMaterial = groundMaterial,
		groundNormal = groundNormal,
		waterSurfaceY = waterSurfaceY,
		waterBottomY = waterBottomY,
		waterDepth = waterDepth,
		isSubmerged = false, -- Set by caller based on entity position
		isValid = groundMaterial ~= Enum.Material.Air,
		source = "terrain",
	}

	-- Cache the result
	setCachedResult(x, z, result)

	return result
end

function ElevationService:getElevations(positions: { { x: number, z: number } }): { ElevationResult }
	local results: { ElevationResult } = {}

	-- Limit batch size
	local count = math.min(#positions, CONFIG.MAX_BATCH_SIZE)

	for i = 1, count do
		local pos = positions[i]
		table.insert(results, self:getElevation(pos.x, pos.z))
	end

	return results
end

--------------------------------------------------------------------------------
-- CONVENIENCE METHODS
--------------------------------------------------------------------------------

function ElevationService:getGroundY(x: number, z: number): number
	return self:getElevation(x, z).groundY
end

function ElevationService:isInWater(x: number, z: number, y: number): boolean
	local result = self:getElevation(x, z)

	if result.waterSurfaceY and result.waterBottomY then
		return y >= result.waterBottomY and y <= result.waterSurfaceY
	end

	return false
end

function ElevationService:getWaterDepthAt(x: number, z: number): number?
	return self:getElevation(x, z).waterDepth
end

function ElevationService:canWadeAt(x: number, z: number, maxWadeDepth: number?): boolean
	local depth = self:getWaterDepthAt(x, z)
	if not depth then
		return true -- No water, can walk
	end

	maxWadeDepth = maxWadeDepth or 3 -- Default: waist-high
	return depth <= maxWadeDepth
end

function ElevationService:getSlopeAt(x: number, z: number): number
	local result = self:getElevation(x, z)
	-- Angle between normal and up vector (in radians)
	return math.acos(result.groundNormal:Dot(Vector3.yAxis))
end

function ElevationService:isWalkableAt(x: number, z: number, maxSlopeRadians: number?): boolean
	maxSlopeRadians = maxSlopeRadians or math.rad(45) -- Default: 45 degrees
	return self:getSlopeAt(x, z) <= maxSlopeRadians
end

function ElevationService:getElevationsAlongPath(
	from: Vector3,
	to: Vector3,
	steps: number?
): { ElevationResult }
	steps = steps or 10
	local results: { ElevationResult } = {}

	for i = 0, steps do
		local t = i / steps
		local x = from.X + (to.X - from.X) * t
		local z = from.Z + (to.Z - from.Z) * t
		table.insert(results, self:getElevation(x, z))
	end

	return results
end

--------------------------------------------------------------------------------
-- WATER BODY REGISTRATION
--------------------------------------------------------------------------------

function ElevationService:registerWaterBody(body: WaterBody)
	table.insert(waterBodies, body)
end

function ElevationService:registerWaterBodies(bodies: { WaterBody })
	for _, body in bodies do
		self:registerWaterBody(body)
	end
end

function ElevationService:clearWaterBodies()
	waterBodies = {}
end

--------------------------------------------------------------------------------
-- CACHE MANAGEMENT
--------------------------------------------------------------------------------

function ElevationService:clearCache()
	cache = {}
	cacheSize = 0
end

function ElevationService:invalidateRegion(min: Vector3, max: Vector3)
	local minGX = math.floor(min.X / CONFIG.CACHE_RESOLUTION)
	local maxGX = math.floor(max.X / CONFIG.CACHE_RESOLUTION)
	local minGZ = math.floor(min.Z / CONFIG.CACHE_RESOLUTION)
	local maxGZ = math.floor(max.Z / CONFIG.CACHE_RESOLUTION)

	for gx = minGX, maxGX do
		for gz = minGZ, maxGZ do
			local key = string.format("%d,%d", gx, gz)
			if cache[key] then
				cache[key] = nil
				cacheSize = cacheSize - 1
			end
		end
	end
end

function ElevationService:precomputeRegion(min: Vector3, max: Vector3)
	for x = min.X, max.X, CONFIG.CACHE_RESOLUTION do
		for z = min.Z, max.Z, CONFIG.CACHE_RESOLUTION do
			self:getElevation(x, z) -- This caches the result
		end
	end
end

function ElevationService:getCacheStats(): { size: number, maxSize: number, resolution: number }
	return {
		size = cacheSize,
		maxSize = CONFIG.CACHE_MAX_SIZE,
		resolution = CONFIG.CACHE_RESOLUTION,
	}
end

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------

function ElevationService:setConfig(key: string, value: any)
	if CONFIG[key] ~= nil then
		CONFIG[key] = value

		-- Clear cache if resolution changes
		if key == "CACHE_RESOLUTION" then
			self:clearCache()
		end
	end
end

function ElevationService:getConfig(key: string): any
	return CONFIG[key]
end

return ElevationService
