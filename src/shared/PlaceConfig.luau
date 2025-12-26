local PlaceConfig = {}

local PlaceIds = {
	VerdantBasin = 86994825772783,
	Driftplain = 127545080940760,
}

-- Shared world dimensions (same for all places)
local WorldDimensions = {
	size = Vector3.new(500, 150, 500),
	center = Vector3.zero,
	terrariumShape = "box",
}

-- Shared time settings
local TimeDefaults = {
	dayLengthMinutes = 12, -- Real minutes per full game day
	startTime = 10, -- Start at 10 AM
	timeEnabled = true, -- Whether time advances
}

local Configs = {
	[PlaceIds.VerdantBasin] = {
		name = "Verdant Basin",
		biome = "wetland",
		time = TimeDefaults,
		lighting = {
			-- Base values (used as noon reference)
			Ambient = Color3.fromRGB(38, 46, 31),
			Brightness = 2,
			ClockTime = 14,
			GeographicLatitude = 20,
			-- Day/night presets for lerping
			day = {
				Ambient = Color3.fromRGB(48, 56, 41),
				Brightness = 2.2,
				OutdoorAmbient = Color3.fromRGB(128, 128, 128),
			},
			night = {
				Ambient = Color3.fromRGB(15, 20, 25),
				Brightness = 0.3,
				OutdoorAmbient = Color3.fromRGB(50, 50, 70),
			},
			dawn = {
				Ambient = Color3.fromRGB(60, 45, 35),
				Brightness = 1.2,
				OutdoorAmbient = Color3.fromRGB(180, 140, 100),
			},
			dusk = {
				Ambient = Color3.fromRGB(55, 40, 40),
				Brightness = 1.0,
				OutdoorAmbient = Color3.fromRGB(160, 100, 80),
			},
		},
		terrain = {
			waterLevel = 12,     -- Water surface level
			baseHeight = 5,      -- Lower base = more water coverage
			seed = 42,
			waterCoverage = 0.30, -- Target 30% water
		},
		-- Lush wetland materials
		materials = {
			primary = Enum.Material.Grass,
			secondary = Enum.Material.LeafyGrass,
			dry = Enum.Material.Ground,
			shore = Enum.Material.Mud,
			underwater = Enum.Material.Mud,
			grassChance = 0.7, -- 70% grass coverage
		},
	},
	[PlaceIds.Driftplain] = {
		name = "Driftplain",
		biome = "plains",
		time = TimeDefaults,
		lighting = {
			-- Base values (used as noon reference)
			Ambient = Color3.fromRGB(64, 56, 46),
			Brightness = 3,
			ClockTime = 11,
			GeographicLatitude = 35,
			-- Day/night presets for lerping
			day = {
				Ambient = Color3.fromRGB(74, 66, 56),
				Brightness = 3.5,
				OutdoorAmbient = Color3.fromRGB(140, 130, 110),
			},
			night = {
				Ambient = Color3.fromRGB(20, 18, 30),
				Brightness = 0.4,
				OutdoorAmbient = Color3.fromRGB(40, 35, 60),
			},
			dawn = {
				Ambient = Color3.fromRGB(80, 55, 40),
				Brightness = 1.5,
				OutdoorAmbient = Color3.fromRGB(200, 150, 100),
			},
			dusk = {
				Ambient = Color3.fromRGB(70, 45, 35),
				Brightness = 1.2,
				OutdoorAmbient = Color3.fromRGB(180, 100, 60),
			},
		},
		terrain = {
			waterLevel = -5,     -- Very little water (scarce)
			baseHeight = 10,
			seed = 99,
			waterCoverage = 0.05, -- Target 5% water (oases only)
		},
		-- Arid plains materials
		materials = {
			primary = Enum.Material.Sand,
			secondary = Enum.Material.Ground,
			dry = Enum.Material.Sandstone,
			shore = Enum.Material.Sand,
			underwater = Enum.Material.Sand,
			grassChance = 0.15, -- Only 15% sparse grass patches
		},
	},
}

function PlaceConfig.getCurrent()
	return Configs[game.PlaceId] or error("Unknown PlaceId: " .. game.PlaceId)
end

function PlaceConfig.getWorldDimensions()
	return WorldDimensions
end

function PlaceConfig.getTerrainConfig()
	local current = PlaceConfig.getCurrent()
	local dims = WorldDimensions
	return {
		center = dims.center,
		size = dims.size,
		terrariumShape = dims.terrariumShape,
		waterLevel = current.terrain.waterLevel,
		baseHeight = current.terrain.baseHeight,
		seed = current.terrain.seed,
		materials = current.materials,
		biome = current.biome,
	}
end

function PlaceConfig.getMaterials()
	return PlaceConfig.getCurrent().materials
end

function PlaceConfig.applyLighting()
	local config = PlaceConfig.getCurrent()
	local lighting = game:GetService("Lighting")

	-- Only apply base lighting properties, skip nested presets (day/night/dawn/dusk)
	for property, value in config.lighting do
		if type(value) ~= "table" then
			lighting[property] = value
		end
	end
end

function PlaceConfig.getTimeConfig()
	local config = PlaceConfig.getCurrent()
	return config.time or TimeDefaults
end

function PlaceConfig.getLightingPresets()
	local config = PlaceConfig.getCurrent()
	return config.lighting
end

PlaceConfig.PlaceIds = PlaceIds
PlaceConfig.WorldDimensions = WorldDimensions
PlaceConfig.TimeDefaults = TimeDefaults

return PlaceConfig
