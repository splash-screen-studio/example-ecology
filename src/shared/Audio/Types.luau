--!strict
--[[
    Audio Types

    Type definitions for the audio system.
]]

local Types = {}

-- Sound categories for volume control
export type SoundCategory = "master" | "ambient" | "sfx" | "music" | "ui"

-- Ambient zone definition
export type AmbientZone = {
	id: string,
	name: string,
	biome: string,
	sounds: { AmbientSound },
	reverbPreset: string?,
}

-- Individual ambient sound
export type AmbientSound = {
	id: string,
	soundId: string, -- Roblox asset ID
	volume: number,
	looped: boolean,
	minDistance: number?, -- For spatial sounds
	maxDistance: number?,
	playChance: number?, -- For random sounds (0-1)
	minInterval: number?, -- Seconds between plays
	maxInterval: number?,
}

-- Footstep material mapping
export type FootstepMaterial = {
	material: Enum.Material,
	sounds: { string }, -- List of sound IDs to pick from
	volume: number,
	pitchVariation: number, -- Random pitch range (0.1 = +/-10%)
}

-- Sound effect definition
export type SoundEffect = {
	id: string,
	soundId: string,
	category: SoundCategory,
	volume: number,
	pitch: number?,
	spatial: boolean,
	minDistance: number?,
	maxDistance: number?,
}

-- Music track definition
export type MusicTrack = {
	id: string,
	soundId: string,
	name: string,
	volume: number,
	fadeInTime: number,
	fadeOutTime: number,
	looped: boolean,
	biomes: { string }?, -- Which biomes this plays in
	timeOfDay: { min: number, max: number }?, -- Hour range (0-24)
}

-- Audio settings (saved per player)
export type AudioSettings = {
	masterVolume: number,
	ambientVolume: number,
	sfxVolume: number,
	musicVolume: number,
	uiVolume: number,
	muteAll: boolean,
}

return Types
