local PlaceConfig = {}

local PlaceIds = {
	VerdantBasin = 86994825772783,
	Driftplain = 127545080940760,
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
	},
	[PlaceIds.Driftplain] = {
		name = "Driftplain",
		lighting = {
			Ambient = Color3.fromRGB(64, 56, 46),
			Brightness = 3,
			ClockTime = 11,
			GeographicLatitude = 35,
		},
	},
}

function PlaceConfig.getCurrent()
	return Configs[game.PlaceId] or error("Unknown PlaceId: " .. game.PlaceId)
end

function PlaceConfig.applyLighting()
	local config = PlaceConfig.getCurrent()
	local lighting = game:GetService("Lighting")

	for property, value in config.lighting do
		lighting[property] = value
	end
end

PlaceConfig.PlaceIds = PlaceIds

return PlaceConfig
