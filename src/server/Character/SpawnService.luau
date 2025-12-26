--!strict
--[[
    SpawnService

    Handles safe player spawning and respawning.
    Ensures players never spawn underwater or inside terrain.

    Usage:
        local SpawnService = require(script.SpawnService)
        SpawnService:init()
]]

local SpawnService = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Dependencies (lazy loaded)
local ElevationService
local PlaceConfig

-- Configuration
local CONFIG = {
	-- Spawn search settings
	SPAWN_SEARCH_RADIUS = 50, -- studs from center to search
	SPAWN_SEARCH_STEP = 10, -- grid resolution for searching
	MAX_SPAWN_ATTEMPTS = 100, -- max random attempts

	-- Safety requirements
	MIN_GROUND_HEIGHT = 5, -- minimum Y above water
	MAX_WATER_DEPTH = 2, -- max water depth allowed at spawn
	MAX_SLOPE = math.rad(30), -- max ground slope (radians)

	-- Respawn settings
	RESPAWN_DELAY = 3, -- seconds before respawn

	-- Character spawn height offset
	SPAWN_HEIGHT_OFFSET = 5, -- studs above ground
}

-- State
local spawnPoints: { Vector3 } = {}
local initialized = false

-- Types
export type SpawnPoint = {
	position: Vector3,
	name: string?,
	isDefault: boolean,
}

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function loadDependencies()
	if not ElevationService then
		ElevationService = require(ReplicatedStorage.Shared.ElevationService)
	end
	if not PlaceConfig then
		PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)
	end
end

--------------------------------------------------------------------------------
-- SAFE SPAWN DETECTION
--------------------------------------------------------------------------------

local function isPositionSafeForSpawn(x: number, z: number): (boolean, number?)
	loadDependencies()

	local elevation = ElevationService:getElevation(x, z)

	-- Check if terrain exists
	if not elevation.isValid then
		return false, nil
	end

	-- Check if underwater
	if elevation.waterSurfaceY then
		local waterDepth = elevation.waterSurfaceY - elevation.groundY
		if waterDepth > CONFIG.MAX_WATER_DEPTH then
			return false, nil
		end
	end

	-- Check ground height (must be above water level)
	local terrainConfig = PlaceConfig.getTerrainConfig()
	local waterLevel = terrainConfig.waterLevel or 5

	if elevation.groundY < waterLevel + CONFIG.MIN_GROUND_HEIGHT then
		-- Allow shallow areas but not submerged
		if elevation.waterSurfaceY and elevation.groundY < elevation.waterSurfaceY - 1 then
			return false, nil
		end
	end

	-- Check slope
	if not ElevationService:isWalkableAt(x, z, CONFIG.MAX_SLOPE) then
		return false, nil
	end

	return true, elevation.groundY
end

local function findSafeSpawnPosition(): Vector3?
	loadDependencies()

	local worldDims = PlaceConfig.getWorldDimensions()
	local center = worldDims.center
	local size = worldDims.size

	-- First try known spawn points
	if #spawnPoints > 0 then
		for _, point in spawnPoints do
			local safe, groundY = isPositionSafeForSpawn(point.X, point.Z)
			if safe and groundY then
				return Vector3.new(point.X, groundY + CONFIG.SPAWN_HEIGHT_OFFSET, point.Z)
			end
		end
	end

	-- Search in a spiral pattern from center
	local searchRadius = CONFIG.SPAWN_SEARCH_RADIUS
	local step = CONFIG.SPAWN_SEARCH_STEP

	for r = 0, searchRadius, step do
		if r == 0 then
			local safe, groundY = isPositionSafeForSpawn(center.X, center.Z)
			if safe and groundY then
				return Vector3.new(center.X, groundY + CONFIG.SPAWN_HEIGHT_OFFSET, center.Z)
			end
		else
			-- Check points in a circle at radius r
			local circumference = 2 * math.pi * r
			local pointsOnCircle = math.max(8, math.floor(circumference / step))

			for i = 0, pointsOnCircle - 1 do
				local angle = (i / pointsOnCircle) * 2 * math.pi
				local x = center.X + r * math.cos(angle)
				local z = center.Z + r * math.sin(angle)

				-- Keep within world bounds
				local halfX, halfZ = size.X / 2, size.Z / 2
				x = math.clamp(x, center.X - halfX + 10, center.X + halfX - 10)
				z = math.clamp(z, center.Z - halfZ + 10, center.Z + halfZ - 10)

				local safe, groundY = isPositionSafeForSpawn(x, z)
				if safe and groundY then
					return Vector3.new(x, groundY + CONFIG.SPAWN_HEIGHT_OFFSET, z)
				end
			end
		end
	end

	-- Random attempts as fallback
	local halfX = size.X / 2 - 20
	local halfZ = size.Z / 2 - 20

	for _ = 1, CONFIG.MAX_SPAWN_ATTEMPTS do
		local x = center.X + (math.random() * 2 - 1) * halfX
		local z = center.Z + (math.random() * 2 - 1) * halfZ

		local safe, groundY = isPositionSafeForSpawn(x, z)
		if safe and groundY then
			return Vector3.new(x, groundY + CONFIG.SPAWN_HEIGHT_OFFSET, z)
		end
	end

	-- Absolute fallback: center of world, high up
	warn("[SpawnService] Could not find safe spawn, using fallback position")
	return Vector3.new(center.X, 50, center.Z)
end

--------------------------------------------------------------------------------
-- PLAYER SPAWNING
--------------------------------------------------------------------------------

local function spawnPlayer(player: Player)
	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not rootPart then
		warn("[SpawnService] No HumanoidRootPart for", player.Name)
		return
	end

	local spawnPos = findSafeSpawnPosition()
	if spawnPos then
		rootPart.CFrame = CFrame.new(spawnPos)
		print(string.format("[SpawnService] Spawned %s at (%.0f, %.0f, %.0f)",
			player.Name, spawnPos.X, spawnPos.Y, spawnPos.Z))
	end
end

local function onCharacterAdded(player: Player, character: Model)
	-- Wait a frame for character to fully load
	task.defer(function()
		if character.Parent then
			spawnPlayer(player)
		end
	end)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)

	-- Handle existing character
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

--------------------------------------------------------------------------------
-- SPAWN POINT MANAGEMENT
--------------------------------------------------------------------------------

function SpawnService:addSpawnPoint(position: Vector3, name: string?)
	table.insert(spawnPoints, position)
	print(string.format("[SpawnService] Added spawn point at (%.0f, %.0f, %.0f)%s",
		position.X, position.Y, position.Z,
		name and (" - " .. name) or ""))
end

function SpawnService:removeSpawnPoint(position: Vector3)
	for i, point in spawnPoints do
		if (point - position).Magnitude < 1 then
			table.remove(spawnPoints, i)
			return true
		end
	end
	return false
end

function SpawnService:clearSpawnPoints()
	spawnPoints = {}
end

function SpawnService:getSpawnPoints(): { Vector3 }
	return table.clone(spawnPoints)
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function SpawnService:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()

	-- Add default spawn point at world center
	local worldDims = PlaceConfig.getWorldDimensions()
	self:addSpawnPoint(worldDims.center, "World Center")

	-- Handle existing players
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	-- Handle new players
	Players.PlayerAdded:Connect(onPlayerAdded)

	print("[SpawnService] Initialized")
end

function SpawnService:respawnPlayer(player: Player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end

	-- Respawn after delay
	task.delay(CONFIG.RESPAWN_DELAY, function()
		player:LoadCharacter()
	end)
end

function SpawnService:teleportToSafePosition(player: Player)
	local character = player.Character
	if not character then
		return false
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return false
	end

	local spawnPos = findSafeSpawnPosition()
	if spawnPos then
		rootPart.CFrame = CFrame.new(spawnPos)
		return true
	end

	return false
end

function SpawnService:findSafeSpawn(): Vector3?
	return findSafeSpawnPosition()
end

function SpawnService:isSafePosition(position: Vector3): boolean
	local safe, _ = isPositionSafeForSpawn(position.X, position.Z)
	return safe
end

return SpawnService
