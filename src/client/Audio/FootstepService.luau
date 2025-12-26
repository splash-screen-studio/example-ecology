--!strict
--[[
    FootstepService

    Material-aware footstep sounds with hysteresis.
    Based on community best practices:
    - Velocity-based detection with dynamic intervals
    - Clone sounds and destroy after playback (no pooling)
    - Don't interrupt playing sounds
    - Disable default Roblox footsteps
    - Material hysteresis prevents sound thrashing on terrain boundaries

    Hysteresis Algorithm:
    - Track last 5 material samples in a sliding window
    - Current material gets +1 "sticky" bias vote
    - New material must appear 3+ times to trigger switch
    - Prevents rapid switching when walking on terrain edges

    References:
    - Smile4's Material Footsteps
    - Custom Walking Sounds [Release]
]]

local FootstepService = {}

-- Services
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Lazy load
local Audio: any
local AudioConfig: any

-- Configuration (based on community best practices)
local CONFIG = {
	SPEED_GATE = 8, -- Minimum speed to trigger footsteps
	SPEED_MAXIMUM = 16, -- Reference speed for interval calculation
	DELAY_MINIMUM = 0.25, -- Fastest footstep interval (running)
	DELAY_MAXIMUM = 0.6, -- Slowest footstep interval (walking)
	BASE_DELAY = 0.35, -- Base delay multiplier
	RAYCAST_DISTANCE = 5, -- How far down to check for ground
	FOOTSTEP_VOLUME = 0.5, -- Base volume for footsteps
	LAND_VOLUME = 0.6, -- Volume for landing sounds
}

-- State
local footstepFolder: Folder?
local isEnabled = true
local lastMaterial: Enum.Material? = nil
local volumeMultiplier = 1
local isRunning = false

-- Material hysteresis (prevents thrashing on terrain boundaries)
local HYSTERESIS = {
	SAMPLE_COUNT = 5, -- Number of samples to track
	SWITCH_THRESHOLD = 3, -- New material must appear this many times to switch
	STICKY_BIAS = 1, -- Extra "votes" for current material (stickiness)
}
local materialHistory: { Enum.Material } = {}
local activeMaterial: Enum.Material? = nil

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function disableDefaultFootsteps(character: Model)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local runningSound = rootPart:FindFirstChild("Running") :: Sound?
		if runningSound then
			runningSound.Volume = 0
		end
	end
end

local function getPlayer(): Player
	return Players.LocalPlayer
end

local function getCharacter(): Model?
	return getPlayer().Character
end

local function getHumanoid(): Humanoid?
	local character = getCharacter()
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(): BasePart?
	local character = getCharacter()
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

--------------------------------------------------------------------------------
-- MATERIAL DETECTION
--------------------------------------------------------------------------------

local function raycastGroundMaterial(): Enum.Material?
	local character = getCharacter()
	local rootPart = getRootPart()

	if not character or not rootPart then
		return nil
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local result = workspace:Raycast(
		rootPart.Position,
		Vector3.new(0, -CONFIG.RAYCAST_DISTANCE, 0),
		rayParams
	)

	if result then
		return result.Material
	end

	return nil
end

--[[
	Get stabilized ground material using hysteresis.
	Prevents rapid switching when walking on terrain boundaries.

	Algorithm:
	1. Track last N material samples in a sliding window
	2. Count votes for each material (current material gets sticky bias)
	3. Only switch when a different material wins by threshold
]]
local function getGroundMaterial(): Enum.Material?
	local rawMaterial = raycastGroundMaterial()
	if not rawMaterial then
		return activeMaterial -- Keep last known material if raycast fails
	end

	-- Add to history (sliding window)
	table.insert(materialHistory, rawMaterial)
	if #materialHistory > HYSTERESIS.SAMPLE_COUNT then
		table.remove(materialHistory, 1)
	end

	-- Count votes for each material
	local votes: { [Enum.Material]: number } = {}
	for _, mat in materialHistory do
		votes[mat] = (votes[mat] or 0) + 1
	end

	-- Apply sticky bias to current active material
	if activeMaterial and votes[activeMaterial] then
		votes[activeMaterial] = votes[activeMaterial] + HYSTERESIS.STICKY_BIAS
	end

	-- Find material with most votes
	local bestMaterial: Enum.Material? = nil
	local bestVotes = 0
	for mat, count in votes do
		if count > bestVotes then
			bestVotes = count
			bestMaterial = mat
		end
	end

	-- Only switch if new material exceeds threshold
	if bestMaterial and bestMaterial ~= activeMaterial then
		local newMaterialVotes = votes[bestMaterial] or 0
		-- Subtract the sticky bias we added to get true count
		if bestMaterial == activeMaterial then
			newMaterialVotes = newMaterialVotes - HYSTERESIS.STICKY_BIAS
		end

		if newMaterialVotes >= HYSTERESIS.SWITCH_THRESHOLD then
			activeMaterial = bestMaterial
		end
	elseif not activeMaterial and bestMaterial then
		-- First material detection
		activeMaterial = bestMaterial
	end

	return activeMaterial
end

local function getMovementSpeed(): number
	local rootPart = getRootPart()
	if not rootPart then
		return 0
	end

	-- Use horizontal velocity only (ignore Y)
	local velocity = rootPart.AssemblyLinearVelocity
	return Vector3.new(velocity.X, 0, velocity.Z).Magnitude
end

local function isGrounded(): boolean
	local humanoid = getHumanoid()
	if not humanoid then
		return false
	end

	local state = humanoid:GetState()
	return state ~= Enum.HumanoidStateType.Freefall
		and state ~= Enum.HumanoidStateType.Jumping
		and state ~= Enum.HumanoidStateType.Swimming
end

--------------------------------------------------------------------------------
-- SOUND PLAYBACK
--------------------------------------------------------------------------------

local function playSound(soundId: string, volume: number)
	if soundId == "rbxassetid://0" then
		return -- Skip placeholder sounds
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume * volumeMultiplier
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 0
	sound.RollOffMaxDistance = 100
	sound.Parent = footstepFolder
	sound:Play()

	-- Auto-cleanup after sound finishes
	Debris:AddItem(sound, sound.TimeLength + 0.1)
end

local function playFootstep(material: Enum.Material)
	if not AudioConfig then
		return
	end

	local footstepDef = AudioConfig.getFootstepForMaterial(material)
	if not footstepDef or #footstepDef.sounds == 0 then
		return
	end

	-- Pick random sound from the list
	local soundId = footstepDef.sounds[math.random(1, #footstepDef.sounds)]

	-- Calculate volume with material-specific adjustment
	local volume = (footstepDef.volume or CONFIG.FOOTSTEP_VOLUME) * volumeMultiplier

	-- Apply slight pitch variation
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.PlaybackSpeed = 1 + (math.random() * 2 - 1) * (footstepDef.pitchVariation or 0.1)
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.RollOffMinDistance = 0
	sound.RollOffMaxDistance = 100
	sound.Parent = footstepFolder
	sound:Play()

	-- Auto-cleanup after sound finishes (don't cut it off!)
	Debris:AddItem(sound, sound.TimeLength + 0.2)

	lastMaterial = material
end

--------------------------------------------------------------------------------
-- FOOTSTEP LOOP (Recursive task.delay approach)
--------------------------------------------------------------------------------

local function footstepLoop()
	local humanoid = getHumanoid()
	if not humanoid or humanoid.Health <= 0 then
		-- Character dead or gone, stop loop
		return
	end

	if not isEnabled then
		-- Disabled, but keep checking
		task.delay(0.5, footstepLoop)
		return
	end

	local speed = getMovementSpeed()
	local grounded = isGrounded()

	-- Calculate dynamic delay based on speed
	local delay: number
	if speed > CONFIG.SPEED_GATE then
		-- Faster movement = shorter delay
		delay = math.clamp(
			CONFIG.BASE_DELAY * (CONFIG.SPEED_MAXIMUM / speed),
			CONFIG.DELAY_MINIMUM,
			CONFIG.DELAY_MAXIMUM
		)
	else
		delay = CONFIG.DELAY_MAXIMUM
	end

	-- Play footstep if moving fast enough and grounded
	if speed > CONFIG.SPEED_GATE and grounded then
		local material = getGroundMaterial()
		if material then
			playFootstep(material)
		end
	end

	-- Schedule next check
	task.delay(delay, footstepLoop)
end

local function startFootstepLoop()
	-- Start the recursive loop
	task.spawn(footstepLoop)
end

--------------------------------------------------------------------------------
-- CHARACTER HANDLING
--------------------------------------------------------------------------------

local function onCharacterAdded(character: Model)
	-- Wait for character to fully load
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end

	-- Reset material hysteresis state
	materialHistory = {}
	activeMaterial = nil
	lastMaterial = nil

	-- Disable default footsteps
	task.wait(0.1) -- Wait for sounds to be added
	disableDefaultFootsteps(character)

	-- Start footstep loop for this character
	startFootstepLoop()

	-- Handle landing sounds
	humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			local material = getGroundMaterial()
			if material and AudioConfig then
				local footstepDef = AudioConfig.getFootstepForMaterial(material)
				if footstepDef and #footstepDef.sounds > 0 then
					local soundId = footstepDef.sounds[math.random(1, #footstepDef.sounds)]
					playSound(soundId, CONFIG.LAND_VOLUME)
				end
			end
		end
	end)
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
	volumeMultiplier = math.clamp(volume, 0, 2)
end

function FootstepService:getVolume(): number
	return volumeMultiplier
end

function FootstepService:getLastMaterial(): Enum.Material?
	return lastMaterial
end

function FootstepService:getActiveMaterial(): Enum.Material?
	return activeMaterial
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function FootstepService:init()
	-- Load shared modules
	Audio = require(ReplicatedStorage.Shared.Audio)
	AudioConfig = Audio.Config

	-- Create footstep folder in SoundService
	footstepFolder = Instance.new("Folder")
	footstepFolder.Name = "FootstepSounds"
	footstepFolder.Parent = SoundService

	-- Handle current character
	local player = getPlayer()
	if player.Character then
		onCharacterAdded(player.Character)
	end

	-- Handle future characters (respawns)
	player.CharacterAdded:Connect(onCharacterAdded)

	print("[FootstepService] Initialized")
end

return FootstepService
