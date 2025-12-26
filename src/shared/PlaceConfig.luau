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

local Configs = {
	[PlaceIds.VerdantBasin] = {
		name = "Verdant Basin",
		lighting = {
			Ambient = Color3.fromRGB(38, 46, 31),
			Brightness = 2,
			ClockTime = 14,
			GeographicLatitude = 20,
		},
		terrain = {
			waterLevel = 8,      -- Higher water level
			baseHeight = 15,     -- Raise terrain so ~30% is underwater
			seed = 42,
			waterCoverage = 0.30, -- Target 30% water
		},
	},
	[PlaceIds.Driftplain] = {
		name = "Driftplain",
		lighting = {
			Ambient = Color3.fromRGB(64, 56, 46),
			Brightness = 3,
			ClockTime = 11,
			GeographicLatitude = 35,
		},
		terrain = {
			waterLevel = -5,     -- Very little water (scarce)
			baseHeight = 10,
			seed = 99,
			waterCoverage = 0.05, -- Target 5% water (oases only)
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
	}
end

function PlaceConfig.applyLighting()
	local config = PlaceConfig.getCurrent()
	local lighting = game:GetService("Lighting")

	for property, value in config.lighting do
		lighting[property] = value
	end
end

PlaceConfig.PlaceIds = PlaceIds
PlaceConfig.WorldDimensions = WorldDimensions

return PlaceConfig
