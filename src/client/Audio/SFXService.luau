--!strict
--[[
    SFXService

    Plays one-off sound effects.
    Supports both 2D UI sounds and 3D spatial sounds.
]]

local SFXService = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Dependencies
local SoundPool = require(script.Parent.SoundPool)

-- Lazy load
local Audio: any
local AudioConfig: any

-- State
local soundPool2D: any = nil
local soundPool3D: any = nil
local sfxFolder: Folder?
local volumeMultiplier = 1

--------------------------------------------------------------------------------
-- SOUND PLAYBACK
--------------------------------------------------------------------------------

function SFXService:play(soundId: string, position: Vector3?): Sound?
	if not AudioConfig then
		return nil
	end

	local sfxDef = AudioConfig.getSoundEffect(soundId)
	if not sfxDef then
		warn("[SFXService] Unknown sound:", soundId)
		return nil
	end

	local pool = if sfxDef.spatial then soundPool3D else soundPool2D
	local sound = pool:get()

	if not sound then
		return nil
	end

	sound.Name = sfxDef.id
	sound.SoundId = sfxDef.soundId
	sound.Volume = sfxDef.volume * volumeMultiplier
	sound.PlaybackSpeed = sfxDef.pitch or 1

	if sfxDef.spatial and position then
		-- Create attachment at position for 3D sound
		local attachment = Instance.new("Attachment")
		attachment.WorldPosition = position
		attachment.Parent = workspace.Terrain

		sound.Parent = attachment

		if sfxDef.minDistance then
			sound.RollOffMinDistance = sfxDef.minDistance
		end
		if sfxDef.maxDistance then
			sound.RollOffMaxDistance = sfxDef.maxDistance
		end

		sound.Ended:Once(function()
			pool:release(sound)
			attachment:Destroy()
		end)
	else
		sound.Parent = sfxFolder

		sound.Ended:Once(function()
			pool:release(sound)
		end)
	end

	sound:Play()
	return sound
end

function SFXService:playAtPart(soundId: string, part: BasePart): Sound?
	return self:play(soundId, part.Position)
end

--------------------------------------------------------------------------------
-- UI SOUNDS (shortcuts)
--------------------------------------------------------------------------------

function SFXService:playClick()
	self:play("ui_click")
end

function SFXService:playHover()
	self:play("ui_hover")
end

function SFXService:playOpen()
	self:play("ui_open")
end

function SFXService:playClose()
	self:play("ui_close")
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function SFXService:setVolume(volume: number)
	volumeMultiplier = math.clamp(volume, 0, 1)
end

function SFXService:getVolume(): number
	return volumeMultiplier
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function SFXService:init()
	-- Load shared modules
	Audio = require(ReplicatedStorage.Shared.Audio)
	AudioConfig = Audio.Config

	-- Create SFX folder
	sfxFolder = Instance.new("Folder")
	sfxFolder.Name = "SFXSounds"
	sfxFolder.Parent = SoundService

	-- Create sound pools
	soundPool2D = SoundPool.new(sfxFolder, 10)
	soundPool3D = SoundPool.new(sfxFolder, 15)

	print("[SFXService] Initialized")
end

return SFXService
