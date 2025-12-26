--!strict
--[[
    FootstepService

    Material-aware footstep sounds.
    Detects the surface the player is walking on and plays appropriate sounds.
]]

local FootstepService = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Dependencies
local SoundPool = require(script.Parent.SoundPool)

-- Lazy load
local Audio: any
local AudioConfig: any

-- Configuration
local CONFIG = {
	WALK_INTERVAL = 0.4, -- Seconds between footsteps when walking
	RUN_INTERVAL = 0.25, -- Seconds between footsteps when running
	RAYCAST_DISTANCE = 5, -- How far down to check for ground
	SPEED_THRESHOLD = 12, -- Above this = running
}

-- State
local soundPool: any = nil
local footstepFolder: Folder?
local isEnabled = true
local lastFootstep = 0
local lastMaterial: Enum.Material? = nil
local volumeMultiplier = 1

--------------------------------------------------------------------------------
-- MATERIAL DETECTION
--------------------------------------------------------------------------------

local function getGroundMaterial(): Enum.Material?
	local player = Players.LocalPlayer
	local character = player and player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not rootPart then
		return nil
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local rayOrigin = rootPart.Position
	local rayDirection = Vector3.new(0, -CONFIG.RAYCAST_DISTANCE, 0)

	local result = workspace:Raycast(rayOrigin, rayDirection, rayParams)

	if result then
		return result.Material
	end

	return nil
end

local function isPlayerMoving(): (boolean, boolean)
	local player = Players.LocalPlayer
	local character = player and player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return false, false
	end

	local moveDirection = humanoid.MoveDirection
	local isMoving = moveDirection.Magnitude > 0.1
	local isRunning = humanoid.WalkSpeed > CONFIG.SPEED_THRESHOLD

	-- Check if grounded
	local state = humanoid:GetState()
	local isGrounded = state ~= Enum.HumanoidStateType.Freefall
		and state ~= Enum.HumanoidStateType.Jumping
		and state ~= Enum.HumanoidStateType.Swimming

	return isMoving and isGrounded, isRunning
end

--------------------------------------------------------------------------------
-- SOUND PLAYBACK
--------------------------------------------------------------------------------

local function playFootstep(material: Enum.Material)
	if not AudioConfig then
		return
	end

	local footstepDef = AudioConfig.getFootstepForMaterial(material)
	if not footstepDef or #footstepDef.sounds == 0 then
		return
	end

	local sound = soundPool:get()
	if not sound then
		return
	end

	-- Pick random sound from the list
	local soundId = footstepDef.sounds[math.random(1, #footstepDef.sounds)]

	sound.Name = "Footstep"
	sound.SoundId = soundId
	sound.Volume = footstepDef.volume * volumeMultiplier

	-- Apply pitch variation
	local pitchVar = footstepDef.pitchVariation
	sound.PlaybackSpeed = 1 + (math.random() * 2 - 1) * pitchVar

	sound.Parent = footstepFolder
	sound:Play()

	-- Release when done
	sound.Ended:Once(function()
		soundPool:release(sound)
	end)
end

--------------------------------------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------------------------------------

local function update(dt: number)
	if not isEnabled then
		return
	end

	local isMoving, isRunning = isPlayerMoving()

	if not isMoving then
		return
	end

	local interval = if isRunning then CONFIG.RUN_INTERVAL else CONFIG.WALK_INTERVAL
	lastFootstep = lastFootstep + dt

	if lastFootstep >= interval then
		lastFootstep = 0

		local material = getGroundMaterial()
		if material then
			lastMaterial = material
			playFootstep(material)
		end
	end
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function FootstepService:setEnabled(enabled: boolean)
	isEnabled = enabled
end

function FootstepService:isEnabled(): boolean
	return isEnabled
end

function FootstepService:setVolume(volume: number)
	volumeMultiplier = math.clamp(volume, 0, 1)
end

function FootstepService:getVolume(): number
	return volumeMultiplier
end

function FootstepService:getLastMaterial(): Enum.Material?
	return lastMaterial
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function FootstepService:init()
	-- Load shared modules
	Audio = require(ReplicatedStorage.Shared.Audio)
	AudioConfig = Audio.Config

	-- Create footstep folder
	footstepFolder = Instance.new("Folder")
	footstepFolder.Name = "FootstepSounds"
	footstepFolder.Parent = SoundService

	-- Create sound pool
	soundPool = SoundPool.new(footstepFolder, 5)

	-- Start update loop
	RunService.Heartbeat:Connect(update)

	print("[FootstepService] Initialized")
end

return FootstepService
