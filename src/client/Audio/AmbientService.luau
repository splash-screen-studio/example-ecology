--!strict
--[[
    AmbientService

    Manages ambient audio based on player location.
    Plays biome-specific ambient sounds and random environmental effects.
]]

local AmbientService = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Dependencies
local SoundPool = require(script.Parent.SoundPool)

-- Lazy load shared modules
local Audio: any
local AudioConfig: any

-- Configuration
local CONFIG = {
	UPDATE_INTERVAL = 0.5, -- How often to check player position
	CROSSFADE_TIME = 2, -- Seconds to fade between zones
	RANDOM_CHECK_INTERVAL = 1, -- How often to check random sounds
}

-- State
local currentZone: string? = nil
local activeSounds: { [string]: Sound } = {}
local soundPool: any = nil
local ambientFolder: Folder?
local isRunning = false
local lastUpdate = 0
local lastRandomCheck = 0
local volumeMultiplier = 1

--------------------------------------------------------------------------------
-- ZONE DETECTION
--------------------------------------------------------------------------------

local function getCurrentBiome(): string
	local player = Players.LocalPlayer
	local character = player and player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if not rootPart then
		return "wetland" -- Default
	end

	-- Check if underwater
	local head = character:FindFirstChild("Head")
	if head then
		local waterHeight = 40 -- From PlaceConfig water level
		if head.Position.Y < waterHeight - 2 then
			return "underwater"
		end
	end

	-- TODO: Get biome from EcologyService region
	-- For now, use position-based detection
	local pos = rootPart.Position

	-- Simple position-based biome (adjust based on world layout)
	-- This should eventually query EcologyService
	local PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)
	local placeName = PlaceConfig.getCurrent().name

	if placeName == "Driftplain" then
		return "plains"
	else
		return "wetland"
	end
end

--------------------------------------------------------------------------------
-- SOUND MANAGEMENT
--------------------------------------------------------------------------------

local function createAmbientSound(soundDef: any): Sound?
	local sound = soundPool:get()
	if not sound then
		return nil
	end

	sound.Name = soundDef.id
	sound.SoundId = soundDef.soundId
	sound.Volume = 0 -- Start silent for fade-in
	sound.Looped = soundDef.looped
	sound.Parent = ambientFolder

	if soundDef.looped then
		sound:Play()
	end

	return sound
end

local function fadeSound(sound: Sound, targetVolume: number, duration: number)
	local startVolume = sound.Volume
	local startTime = os.clock()

	-- Use a simple lerp over time
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local alpha = math.min(1, elapsed / duration)

		sound.Volume = startVolume + (targetVolume - startVolume) * alpha

		if alpha >= 1 then
			connection:Disconnect()
			if targetVolume <= 0 then
				sound:Stop()
				soundPool:release(sound)
			end
		end
	end)
end

local function transitionToZone(newZone: string)
	if not AudioConfig then
		return
	end

	local zoneDef = AudioConfig.getAmbientZone(newZone)
	if not zoneDef then
		return
	end

	-- Fade out old sounds
	for id, sound in activeSounds do
		fadeSound(sound, 0, CONFIG.CROSSFADE_TIME)
		activeSounds[id] = nil
	end

	-- Create new sounds for the zone
	for _, soundDef in zoneDef.sounds do
		if soundDef.looped and (soundDef.playChance or 1) >= 1 then
			local sound = createAmbientSound(soundDef)
			if sound then
				activeSounds[soundDef.id] = sound
				fadeSound(sound, soundDef.volume * volumeMultiplier, CONFIG.CROSSFADE_TIME)
			end
		end
	end

	currentZone = newZone
	print(string.format("[AmbientService] Transitioned to zone: %s", newZone))
end

local function playRandomSound(soundDef: any)
	local sound = soundPool:get()
	if not sound then
		return
	end

	sound.Name = soundDef.id .. "_random"
	sound.SoundId = soundDef.soundId
	sound.Volume = soundDef.volume * volumeMultiplier
	sound.Looped = false
	sound.Parent = ambientFolder

	-- Random pitch variation
	sound.PlaybackSpeed = 0.9 + math.random() * 0.2

	sound:Play()

	-- Release when done
	sound.Ended:Once(function()
		soundPool:release(sound)
	end)
end

local function checkRandomSounds()
	if not AudioConfig or not currentZone then
		return
	end

	local zoneDef = AudioConfig.getAmbientZone(currentZone)
	if not zoneDef then
		return
	end

	for _, soundDef in zoneDef.sounds do
		if not soundDef.looped and soundDef.playChance then
			if math.random() < soundDef.playChance * CONFIG.RANDOM_CHECK_INTERVAL then
				playRandomSound(soundDef)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------------------------------------

local function update(dt: number)
	if not isRunning then
		return
	end

	lastUpdate = lastUpdate + dt

	-- Check zone changes
	if lastUpdate >= CONFIG.UPDATE_INTERVAL then
		lastUpdate = 0

		local biome = getCurrentBiome()
		if biome ~= currentZone then
			transitionToZone(biome)
		end
	end

	-- Check random sounds
	lastRandomCheck = lastRandomCheck + dt
	if lastRandomCheck >= CONFIG.RANDOM_CHECK_INTERVAL then
		lastRandomCheck = 0
		checkRandomSounds()
	end
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function AmbientService:setVolume(volume: number)
	volumeMultiplier = math.clamp(volume, 0, 1)

	-- Update active sounds
	for id, sound in activeSounds do
		if AudioConfig then
			local zoneDef = AudioConfig.getAmbientZone(currentZone or "wetland")
			if zoneDef then
				for _, soundDef in zoneDef.sounds do
					if soundDef.id == id then
						sound.Volume = soundDef.volume * volumeMultiplier
						break
					end
				end
			end
		end
	end
end

function AmbientService:getVolume(): number
	return volumeMultiplier
end

function AmbientService:getCurrentZone(): string?
	return currentZone
end

function AmbientService:forceZone(zone: string)
	transitionToZone(zone)
end

function AmbientService:stop()
	isRunning = false

	for _, sound in activeSounds do
		sound:Stop()
		soundPool:release(sound)
	end
	activeSounds = {}
	currentZone = nil
end

function AmbientService:start()
	isRunning = true
	local biome = getCurrentBiome()
	transitionToZone(biome)
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function AmbientService:init()
	-- Load shared modules
	Audio = require(ReplicatedStorage.Shared.Audio)
	AudioConfig = Audio.Config

	-- Create ambient folder
	ambientFolder = Instance.new("Folder")
	ambientFolder.Name = "AmbientSounds"
	ambientFolder.Parent = SoundService

	-- Create sound pool
	soundPool = SoundPool.new(ambientFolder, 15)

	-- Start update loop
	isRunning = true
	RunService.Heartbeat:Connect(update)

	-- Initial zone detection
	task.defer(function()
		local biome = getCurrentBiome()
		transitionToZone(biome)
	end)

	print("[AmbientService] Initialized")
end

return AmbientService
