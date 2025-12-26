--!strict
--[[
    WaterController

    Prevents players from swimming under terrain.
    Ensures smooth water-to-shore transitions.

    Key guarantees:
    1. Player never clips below terrain floor
    2. Smooth wade-to-swim-to-walk transitions
    3. No jittering at water edges

    Usage:
        local WaterController = require(script.WaterController)
        WaterController:init()
]]

local WaterController = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Configuration
local CONFIG = {
	-- Water detection
	WATER_CHECK_INTERVAL = 0.1, -- How often to check (seconds)
	FLOOR_RAYCAST_LENGTH = 100, -- How far down to look for floor

	-- Floor clamping
	MIN_FLOOR_CLEARANCE = 2.5, -- Studs above terrain floor
	CLAMP_LERP_SPEED = 0.3, -- How fast to correct position

	-- Swimming states
	WADE_DEPTH = 3, -- Water depth for wading
	SWIM_DEPTH = 5, -- Water depth to start swimming

	-- Shoreline smoothing
	SHORE_TRANSITION_SPEED = 0.2,
}

-- State per player
local playerStates: { [Player]: PlayerWaterState } = {}

type PlayerWaterState = {
	isInWater: boolean,
	waterSurfaceY: number?,
	waterBottomY: number?,
	lastFloorY: number,
	mode: "dry" | "wading" | "swimming",
}

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

local function getTerrainFloorY(x: number, z: number): number
	local terrain = Workspace.Terrain
	local origin = Vector3.new(x, 500, z)
	local direction = Vector3.new(0, -CONFIG.FLOOR_RAYCAST_LENGTH - 500, 0)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { terrain }
	params.IgnoreWater = true -- Critical: ignore water to find actual floor

	local result = Workspace:Raycast(origin, direction, params)

	if result then
		return result.Position.Y
	end

	return -50 -- Default floor if no terrain found
end

local function detectWaterAtPosition(x: number, y: number, z: number): (boolean, number?, number?)
	local terrain = Workspace.Terrain

	-- Check if there's water at this position using ReadVoxels
	local halfVoxel = 2
	local region = Region3.new(
		Vector3.new(x - halfVoxel, y - halfVoxel, z - halfVoxel),
		Vector3.new(x + halfVoxel, y + halfVoxel, z + halfVoxel)
	):ExpandToGrid(4)

	local success, materials = pcall(function()
		return terrain:ReadVoxels(region, 4)
	end)

	if not success or not materials then
		return false, nil, nil
	end

	local hasWater = false
	for _, xMats in materials do
		for _, yMats in xMats do
			for _, material in yMats do
				if material == Enum.Material.Water then
					hasWater = true
					break
				end
			end
		end
	end

	if not hasWater then
		return false, nil, nil
	end

	-- Binary search to find water surface
	local floorY = getTerrainFloorY(x, z)
	local low = y
	local high = y + 50

	for _ = 1, 15 do
		local mid = (low + high) / 2
		local testRegion = Region3.new(
			Vector3.new(x - 2, mid - 2, z - 2),
			Vector3.new(x + 2, mid + 2, z + 2)
		):ExpandToGrid(4)

		local testSuccess, testMaterials = pcall(function()
			return terrain:ReadVoxels(testRegion, 4)
		end)

		if testSuccess and testMaterials then
			local foundWater = false
			for _, xM in testMaterials do
				for _, yM in xM do
					for _, mat in yM do
						if mat == Enum.Material.Water then
							foundWater = true
							break
						end
					end
				end
			end

			if foundWater then
				low = mid
			else
				high = mid
			end
		end
	end

	local waterSurfaceY = low + 2 -- Approximate surface
	local waterBottomY = floorY

	return true, waterSurfaceY, waterBottomY
end

--------------------------------------------------------------------------------
-- PLAYER STATE MANAGEMENT
--------------------------------------------------------------------------------

local function initPlayerState(player: Player)
	playerStates[player] = {
		isInWater = false,
		waterSurfaceY = nil,
		waterBottomY = nil,
		lastFloorY = 0,
		mode = "dry",
	}
end

local function cleanupPlayerState(player: Player)
	playerStates[player] = nil
end

--------------------------------------------------------------------------------
-- FLOOR CLAMPING (Critical for preventing clipping)
--------------------------------------------------------------------------------

local function clampPlayerAboveFloor(character: Model, state: PlayerWaterState)
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return
	end

	local pos = rootPart.Position
	local floorY = getTerrainFloorY(pos.X, pos.Z)
	state.lastFloorY = floorY

	local minY = floorY + CONFIG.MIN_FLOOR_CLEARANCE

	if pos.Y < minY then
		-- Smoothly push player up
		local correction = minY - pos.Y
		local newY = pos.Y + correction * CONFIG.CLAMP_LERP_SPEED

		-- Only correct if significant
		if correction > 0.1 then
			rootPart.CFrame = CFrame.new(pos.X, math.max(newY, minY), pos.Z)
				* CFrame.Angles(rootPart.CFrame:ToEulerAnglesYXZ())
		end
	end
end

--------------------------------------------------------------------------------
-- SWIMMING STATE MANAGEMENT
--------------------------------------------------------------------------------

local function updateSwimmingState(character: Model, state: PlayerWaterState)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not rootPart then
		return
	end

	local pos = rootPart.Position
	local feetY = pos.Y - 3

	-- Detect water
	local inWater, surfaceY, bottomY = detectWaterAtPosition(pos.X, pos.Y, pos.Z)

	state.isInWater = inWater
	state.waterSurfaceY = surfaceY
	state.waterBottomY = bottomY

	if not inWater then
		-- Not in water - ensure walking
		state.mode = "dry"
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		humanoid.WalkSpeed = 16
		return
	end

	-- In water - calculate depth relative to player
	local waterDepthAtFeet = (surfaceY or 0) - feetY
	local canTouchBottom = (pos.Y - (bottomY or 0)) < CONFIG.SWIM_DEPTH

	if waterDepthAtFeet < CONFIG.WADE_DEPTH and canTouchBottom then
		-- Wading: shallow water, can walk
		state.mode = "wading"
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		humanoid.WalkSpeed = 10 -- Slower in water

		-- Ensure player stays above floor
		clampPlayerAboveFloor(character, state)
	elseif canTouchBottom then
		-- Transition zone: deeper but can still touch
		state.mode = "wading"
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
		humanoid.WalkSpeed = 8

		clampPlayerAboveFloor(character, state)
	else
		-- Swimming: too deep to touch bottom
		state.mode = "swimming"
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)

		-- Still clamp to prevent going under terrain at edges
		clampPlayerAboveFloor(character, state)

		-- Also prevent swimming above water surface
		if surfaceY and pos.Y > surfaceY - 1 then
			local newY = surfaceY - 1.5
			rootPart.CFrame = CFrame.new(pos.X, newY, pos.Z)
				* CFrame.Angles(rootPart.CFrame:ToEulerAnglesYXZ())
		end
	end
end

--------------------------------------------------------------------------------
-- MAIN UPDATE LOOP
--------------------------------------------------------------------------------

local lastUpdate = 0

local function onHeartbeat(dt: number)
	lastUpdate = lastUpdate + dt
	if lastUpdate < CONFIG.WATER_CHECK_INTERVAL then
		return
	end
	lastUpdate = 0

	for player, state in playerStates do
		local character = player.Character
		if character then
			-- Always clamp above floor first
			clampPlayerAboveFloor(character, state)

			-- Then handle swimming state
			updateSwimmingState(character, state)
		end
	end
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function WaterController:init()
	-- Handle existing players
	for _, player in Players:GetPlayers() do
		initPlayerState(player)
	end

	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		initPlayerState(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		cleanupPlayerState(player)
	end)

	-- Main update loop
	RunService.Heartbeat:Connect(onHeartbeat)

	print("[WaterController] Initialized - preventing terrain clipping")
end

function WaterController:getPlayerState(player: Player): PlayerWaterState?
	return playerStates[player]
end

function WaterController:forceClamp(player: Player)
	local state = playerStates[player]
	local character = player.Character
	if state and character then
		clampPlayerAboveFloor(character, state)
	end
end

return WaterController
