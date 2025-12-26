--!strict
--[[
    Audio Controller

    Main client-side audio controller.
    Manages all audio services and provides a unified API.

    Usage:
        local Audio = require(script.Parent.Audio)
        Audio:init()

        Audio:playSFX("item_pickup", position)
        Audio:setAmbientVolume(0.5)
]]

local AudioController = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Sub-services
local AmbientService = require(script.AmbientService)
local FootstepService = require(script.FootstepService)
local SFXService = require(script.SFXService)

-- Shared config
local Audio: any
local AudioConfig: any

-- State
local settings: any = nil
local isInitialized = false

--------------------------------------------------------------------------------
-- VOLUME CONTROL
--------------------------------------------------------------------------------

function AudioController:setMasterVolume(volume: number)
	if not settings then return end
	settings.masterVolume = math.clamp(volume, 0, 1)
	self:_applySettings()
end

function AudioController:setAmbientVolume(volume: number)
	if not settings then return end
	settings.ambientVolume = math.clamp(volume, 0, 1)
	AmbientService:setVolume(settings.ambientVolume * settings.masterVolume)
end

function AudioController:setSFXVolume(volume: number)
	if not settings then return end
	settings.sfxVolume = math.clamp(volume, 0, 1)
	SFXService:setVolume(settings.sfxVolume * settings.masterVolume)
	FootstepService:setVolume(settings.sfxVolume * settings.masterVolume)
end

function AudioController:setMusicVolume(volume: number)
	if not settings then return end
	settings.musicVolume = math.clamp(volume, 0, 1)
	-- MusicService:setVolume(settings.musicVolume * settings.masterVolume)
end

function AudioController:setUIVolume(volume: number)
	if not settings then return end
	settings.uiVolume = math.clamp(volume, 0, 1)
	-- UI sounds use SFX service but with UI volume
end

function AudioController:setMuteAll(muted: boolean)
	if not settings then return end
	settings.muteAll = muted
	self:_applySettings()
end

function AudioController:_applySettings()
	local master = if settings.muteAll then 0 else settings.masterVolume

	AmbientService:setVolume(settings.ambientVolume * master)
	SFXService:setVolume(settings.sfxVolume * master)
	FootstepService:setVolume(settings.sfxVolume * master)
end

function AudioController:getSettings()
	return settings
end

--------------------------------------------------------------------------------
-- SOUND PLAYBACK (Convenience wrappers)
--------------------------------------------------------------------------------

function AudioController:playSFX(soundId: string, position: Vector3?): Sound?
	return SFXService:play(soundId, position)
end

function AudioController:playSFXAtPart(soundId: string, part: BasePart): Sound?
	return SFXService:playAtPart(soundId, part)
end

function AudioController:playUIClick()
	SFXService:playClick()
end

function AudioController:playUIHover()
	SFXService:playHover()
end

function AudioController:playUIOpen()
	SFXService:playOpen()
end

function AudioController:playUIClose()
	SFXService:playClose()
end

--------------------------------------------------------------------------------
-- AMBIENT CONTROL
--------------------------------------------------------------------------------

function AudioController:forceAmbientZone(zone: string)
	AmbientService:forceZone(zone)
end

function AudioController:getCurrentZone(): string?
	return AmbientService:getCurrentZone()
end

--------------------------------------------------------------------------------
-- FOOTSTEP CONTROL
--------------------------------------------------------------------------------

function AudioController:setFootstepsEnabled(enabled: boolean)
	FootstepService:setEnabled(enabled)
end

--------------------------------------------------------------------------------
-- SERVICE ACCESS
--------------------------------------------------------------------------------

function AudioController:getAmbientService()
	return AmbientService
end

function AudioController:getFootstepService()
	return FootstepService
end

function AudioController:getSFXService()
	return SFXService
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function AudioController:init()
	if isInitialized then
		return
	end

	-- Load shared config
	Audio = require(ReplicatedStorage.Shared.Audio)
	AudioConfig = Audio.Config

	-- Initialize settings with defaults
	settings = table.clone(AudioConfig.DefaultSettings)

	-- Initialize sub-services
	AmbientService:init()
	FootstepService:init()
	SFXService:init()

	-- Apply initial settings
	self:_applySettings()

	isInitialized = true
	print("[AudioController] Initialized")
end

return AudioController
