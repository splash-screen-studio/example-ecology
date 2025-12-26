--!strict
--[[
    AudioConfig

    Central configuration for all audio in the game.

    Sound Asset Sources:
    - Footsteps: Roblox default + community assets
    - UI: Need real assets from Creator Marketplace
    - Ambient: Need real assets from Creator Marketplace

    To find sounds: https://create.roblox.com/store (Audio section)
]]

local Types = require(script.Parent.Types)

local AudioConfig = {}

--------------------------------------------------------------------------------
-- VOLUME DEFAULTS
--------------------------------------------------------------------------------

AudioConfig.DefaultSettings = {
	masterVolume = 0.8,
	ambientVolume = 0.6,
	sfxVolume = 0.8,
	musicVolume = 0.4,
	uiVolume = 0.7,
	muteAll = false,
} :: Types.AudioSettings

--------------------------------------------------------------------------------
-- AMBIENT ZONES
--------------------------------------------------------------------------------

AudioConfig.AmbientZones = {
	wetland = {
		id = "wetland",
		name = "Wetland Ambience",
		biome = "wetland",
		reverbPreset = "OutdoorsMedium",
		sounds = {
			{
				id = "wetland_birds",
				soundId = "rbxassetid://0", -- Placeholder
				volume = 0.4,
				looped = true,
				playChance = 1,
			},
			{
				id = "wetland_water",
				soundId = "rbxassetid://0",
				volume = 0.3,
				looped = true,
				playChance = 1,
			},
			{
				id = "wetland_insects",
				soundId = "rbxassetid://0",
				volume = 0.25,
				looped = true,
				playChance = 1,
			},
			{
				id = "frog_croak",
				soundId = "rbxassetid://0",
				volume = 0.35,
				looped = false,
				playChance = 0.3,
				minInterval = 5,
				maxInterval = 15,
			},
			{
				id = "water_splash",
				soundId = "rbxassetid://0",
				volume = 0.4,
				looped = false,
				playChance = 0.2,
				minInterval = 10,
				maxInterval = 30,
			},
		},
	},

	plains = {
		id = "plains",
		name = "Plains Ambience",
		biome = "plains",
		reverbPreset = "OutdoorsOpen",
		sounds = {
			{
				id = "plains_wind",
				soundId = "rbxassetid://0",
				volume = 0.5,
				looped = true,
				playChance = 1,
			},
			{
				id = "plains_birds",
				soundId = "rbxassetid://0",
				volume = 0.3,
				looped = true,
				playChance = 1,
			},
			{
				id = "grass_rustle",
				soundId = "rbxassetid://0",
				volume = 0.25,
				looped = true,
				playChance = 1,
			},
			{
				id = "hawk_cry",
				soundId = "rbxassetid://0",
				volume = 0.4,
				looped = false,
				playChance = 0.15,
				minInterval = 20,
				maxInterval = 60,
			},
			{
				id = "coyote_howl",
				soundId = "rbxassetid://0",
				volume = 0.35,
				looped = false,
				playChance = 0.1,
				minInterval = 45,
				maxInterval = 120,
			},
		},
	},

	underwater = {
		id = "underwater",
		name = "Underwater Ambience",
		biome = "underwater",
		reverbPreset = "Underwater",
		sounds = {
			{
				id = "underwater_ambience",
				soundId = "rbxassetid://0",
				volume = 0.6,
				looped = true,
				playChance = 1,
			},
			{
				id = "bubble_sounds",
				soundId = "rbxassetid://0",
				volume = 0.3,
				looped = false,
				playChance = 0.4,
				minInterval = 2,
				maxInterval = 8,
			},
		},
	},
}

--------------------------------------------------------------------------------
-- FOOTSTEP MATERIALS
--------------------------------------------------------------------------------

-- Real footstep sound assets (community + Roblox default)
AudioConfig.FootstepMaterials = {
	{
		material = Enum.Material.Grass,
		sounds = { "rbxassetid://9064714296", "rbxassetid://9083837523", "rbxassetid://6133185073" },
		volume = 0.4,
		pitchVariation = 0.15,
	},
	{
		material = Enum.Material.LeafyGrass,
		sounds = { "rbxassetid://9064714296", "rbxassetid://9083837523" },
		volume = 0.45,
		pitchVariation = 0.15,
	},
	{
		material = Enum.Material.Ground,
		sounds = { "rbxassetid://9064853890", "rbxassetid://833564121", "rbxassetid://9064853890" },
		volume = 0.5,
		pitchVariation = 0.1,
	},
	{
		material = Enum.Material.Mud,
		sounds = { "rbxassetid://9064853890", "rbxassetid://9064853890" },
		volume = 0.55,
		pitchVariation = 0.12,
	},
	{
		material = Enum.Material.Sand,
		sounds = { "rbxassetid://9064853890", "rbxassetid://833564121" },
		volume = 0.35,
		pitchVariation = 0.1,
	},
	{
		material = Enum.Material.Rock,
		sounds = { "rbxassetid://9064974448", "rbxassetid://833564121", "rbxassetid://9064974448" },
		volume = 0.6,
		pitchVariation = 0.08,
	},
	{
		material = Enum.Material.Slate,
		sounds = { "rbxassetid://9064974448", "rbxassetid://833564121" },
		volume = 0.55,
		pitchVariation = 0.1,
	},
	{
		material = Enum.Material.Water,
		sounds = { "rbxassetid://5930519356", "rbxassetid://142431247", "rbxassetid://5930519356" },
		volume = 0.7,
		pitchVariation = 0.2,
	},
}

--------------------------------------------------------------------------------
-- SOUND EFFECTS
--------------------------------------------------------------------------------

AudioConfig.SoundEffects = {
	-- UI Sounds
	ui_click = {
		id = "ui_click",
		soundId = "rbxassetid://0",
		category = "ui",
		volume = 0.5,
		spatial = false,
	},
	ui_hover = {
		id = "ui_hover",
		soundId = "rbxassetid://0",
		category = "ui",
		volume = 0.3,
		spatial = false,
	},
	ui_open = {
		id = "ui_open",
		soundId = "rbxassetid://0",
		category = "ui",
		volume = 0.4,
		spatial = false,
	},
	ui_close = {
		id = "ui_close",
		soundId = "rbxassetid://0",
		category = "ui",
		volume = 0.4,
		spatial = false,
	},

	-- Item Sounds (using coin/collect sound as pickup)
	item_pickup = {
		id = "item_pickup",
		soundId = "rbxassetid://6895079853", -- Collect/pickup sound
		category = "sfx",
		volume = 0.5,
		spatial = true,
		minDistance = 5,
		maxDistance = 30,
	},
	item_drop = {
		id = "item_drop",
		soundId = "rbxassetid://0",
		category = "sfx",
		volume = 0.5,
		spatial = true,
		minDistance = 5,
		maxDistance = 30,
	},
	item_use = {
		id = "item_use",
		soundId = "rbxassetid://0",
		category = "sfx",
		volume = 0.5,
		spatial = false,
	},
	item_eat = {
		id = "item_eat",
		soundId = "rbxassetid://0",
		category = "sfx",
		volume = 0.6,
		spatial = false,
	},
	item_drink = {
		id = "item_drink",
		soundId = "rbxassetid://0",
		category = "sfx",
		volume = 0.6,
		spatial = false,
	},

	-- Ecology Sounds
	plant_grow = {
		id = "plant_grow",
		soundId = "rbxassetid://0",
		category = "sfx",
		volume = 0.4,
		spatial = true,
		minDistance = 5,
		maxDistance = 25,
	},
	water_pour = {
		id = "water_pour",
		soundId = "rbxassetid://0",
		category = "sfx",
		volume = 0.5,
		spatial = true,
		minDistance = 5,
		maxDistance = 20,
	},

	-- Player Sounds
	player_jump = {
		id = "player_jump",
		soundId = "rbxassetid://0",
		category = "sfx",
		volume = 0.4,
		spatial = false,
	},
	player_land = {
		id = "player_land",
		soundId = "rbxassetid://0",
		category = "sfx",
		volume = 0.5,
		spatial = false,
	},
	player_splash = {
		id = "player_splash",
		soundId = "rbxassetid://5930519356", -- Water splash
		category = "sfx",
		volume = 0.7,
		spatial = true,
		minDistance = 10,
		maxDistance = 50,
	},
}

--------------------------------------------------------------------------------
-- MUSIC TRACKS
--------------------------------------------------------------------------------

AudioConfig.MusicTracks = {
	wetland_day = {
		id = "wetland_day",
		soundId = "rbxassetid://0",
		name = "Marsh Serenity",
		volume = 0.3,
		fadeInTime = 3,
		fadeOutTime = 2,
		looped = true,
		biomes = { "wetland" },
		timeOfDay = { min = 6, max = 18 },
	},
	wetland_night = {
		id = "wetland_night",
		soundId = "rbxassetid://0",
		name = "Nocturnal Waters",
		volume = 0.25,
		fadeInTime = 4,
		fadeOutTime = 3,
		looped = true,
		biomes = { "wetland" },
		timeOfDay = { min = 18, max = 6 },
	},
	plains_day = {
		id = "plains_day",
		soundId = "rbxassetid://0",
		name = "Prairie Wind",
		volume = 0.3,
		fadeInTime = 3,
		fadeOutTime = 2,
		looped = true,
		biomes = { "plains" },
		timeOfDay = { min = 6, max = 18 },
	},
	plains_night = {
		id = "plains_night",
		soundId = "rbxassetid://0",
		name = "Starlit Plains",
		volume = 0.25,
		fadeInTime = 4,
		fadeOutTime = 3,
		looped = true,
		biomes = { "plains" },
		timeOfDay = { min = 18, max = 6 },
	},
	exploration = {
		id = "exploration",
		soundId = "rbxassetid://0",
		name = "Discovery",
		volume = 0.35,
		fadeInTime = 2,
		fadeOutTime = 2,
		looped = true,
	},
}

--------------------------------------------------------------------------------
-- NPC SOUNDS
--------------------------------------------------------------------------------

AudioConfig.NPCSounds = {
	marsh_rabbit = {
		idle = { "rbxassetid://0" },
		alert = { "rbxassetid://0" },
		hurt = { "rbxassetid://0" },
	},
	wetland_deer = {
		idle = { "rbxassetid://0" },
		alert = { "rbxassetid://0" },
		hurt = { "rbxassetid://0" },
	},
	marsh_wolf = {
		idle = { "rbxassetid://0" },
		alert = { "rbxassetid://0" },
		hurt = { "rbxassetid://0" },
		attack = { "rbxassetid://0" },
	},
	heron = {
		idle = { "rbxassetid://0" },
		alert = { "rbxassetid://0" },
	},
	coyote = {
		idle = { "rbxassetid://0" },
		alert = { "rbxassetid://0" },
		hurt = { "rbxassetid://0" },
		attack = { "rbxassetid://0" },
	},
	hawk = {
		idle = { "rbxassetid://0" },
		alert = { "rbxassetid://0" },
	},
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

function AudioConfig.getFootstepForMaterial(material: Enum.Material): Types.FootstepMaterial?
	for _, footstep in AudioConfig.FootstepMaterials do
		if footstep.material == material then
			return footstep
		end
	end
	-- Default to ground if no match
	for _, footstep in AudioConfig.FootstepMaterials do
		if footstep.material == Enum.Material.Ground then
			return footstep
		end
	end
	return nil
end

function AudioConfig.getAmbientZone(biome: string): Types.AmbientZone?
	return AudioConfig.AmbientZones[biome]
end

function AudioConfig.getSoundEffect(id: string): Types.SoundEffect?
	return AudioConfig.SoundEffects[id]
end

function AudioConfig.getMusicTrack(id: string): Types.MusicTrack?
	return AudioConfig.MusicTracks[id]
end

return AudioConfig
