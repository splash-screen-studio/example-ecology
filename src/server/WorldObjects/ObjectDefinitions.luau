--!strict
--[[
    ObjectDefinitions

    Definitions for all world objects (harvestable plants, collectibles, etc.)
    Each definition includes spawn rules and interaction config.
]]

local ObjectDefinitions = {}

-- Types
export type SpawnRule = {
	biomes: { string }?, -- Which biomes this spawns in (nil = all)
	minElevation: number?,
	maxElevation: number?,
	nearWater: boolean?, -- Must be near water?
	density: number, -- Objects per 100x100 area
}

export type ObjectDefinition = {
	id: string,
	name: string,
	category: "plant" | "resource" | "collectible" | "container",

	-- Visual
	modelId: string?, -- Model asset ID or name in Assets
	scale: number?, -- Size multiplier
	randomRotation: boolean?, -- Random Y rotation on spawn

	-- Interaction
	interactionType: "harvest" | "pickup" | "examine" | "use",
	itemId: string?, -- Item given on harvest/pickup
	quantity: NumberRange?, -- Amount of items (min, max)

	-- Timing
	harvestTime: number?, -- Seconds to harvest
	respawnTime: number?, -- Seconds until respawn (nil = permanent)

	-- Spawn rules
	spawnRules: SpawnRule,
}

--------------------------------------------------------------------------------
-- WETLAND OBJECTS
--------------------------------------------------------------------------------

ObjectDefinitions.wetland_berries = {
	id = "wetland_berries",
	name = "Marsh Berries",
	category = "plant",

	modelId = "wetland_berries",
	scale = 1,
	randomRotation = true,

	interactionType = "harvest",
	itemId = "berries",
	quantity = NumberRange.new(2, 5),

	harvestTime = 1,
	respawnTime = 120, -- 2 minutes

	spawnRules = {
		biomes = { "wetland" },
		nearWater = false,
		density = 8,
	},
}

ObjectDefinitions.water_lily = {
	id = "water_lily",
	name = "Water Lily",
	category = "plant",

	modelId = "water_lily",
	scale = 1,
	randomRotation = true,

	interactionType = "harvest",
	itemId = "lily_seeds",
	quantity = NumberRange.new(1, 2),

	harvestTime = 2,
	respawnTime = 180, -- 3 minutes

	spawnRules = {
		biomes = { "wetland" },
		nearWater = true,
		minElevation = -5,
		maxElevation = 15,
		density = 5,
	},
}

ObjectDefinitions.driftwood = {
	id = "driftwood",
	name = "Driftwood",
	category = "resource",

	modelId = "driftwood",
	scale = 1,
	randomRotation = true,

	interactionType = "pickup",
	itemId = "wood",
	quantity = NumberRange.new(1, 3),

	respawnTime = 300, -- 5 minutes

	spawnRules = {
		biomes = { "wetland" },
		nearWater = true,
		density = 3,
	},
}

ObjectDefinitions.river_stone = {
	id = "river_stone",
	name = "River Stone",
	category = "resource",

	modelId = "river_stone",
	scale = 1,
	randomRotation = true,

	interactionType = "pickup",
	itemId = "stone",
	quantity = NumberRange.new(1, 2),

	respawnTime = 240, -- 4 minutes

	spawnRules = {
		biomes = { "wetland" },
		nearWater = true,
		density = 4,
	},
}

ObjectDefinitions.marsh_herb = {
	id = "marsh_herb",
	name = "Marsh Herb",
	category = "plant",

	modelId = "marsh_herb",
	scale = 1,
	randomRotation = true,

	interactionType = "harvest",
	itemId = "fiber",
	quantity = NumberRange.new(2, 4),

	harvestTime = 1.5,
	respawnTime = 90,

	spawnRules = {
		biomes = { "wetland" },
		density = 10,
	},
}

--------------------------------------------------------------------------------
-- PLAINS OBJECTS
--------------------------------------------------------------------------------

ObjectDefinitions.prairie_grass = {
	id = "prairie_grass",
	name = "Prairie Grass",
	category = "plant",

	modelId = "prairie_grass",
	scale = 1,
	randomRotation = true,

	interactionType = "harvest",
	itemId = "fiber",
	quantity = NumberRange.new(1, 3),

	harvestTime = 1,
	respawnTime = 60,

	spawnRules = {
		biomes = { "plains" },
		density = 15,
	},
}

ObjectDefinitions.desert_stone = {
	id = "desert_stone",
	name = "Sandstone",
	category = "resource",

	modelId = "desert_stone",
	scale = 1,
	randomRotation = true,

	interactionType = "pickup",
	itemId = "stone",
	quantity = NumberRange.new(1, 2),

	respawnTime = 180,

	spawnRules = {
		biomes = { "plains" },
		density = 6,
	},
}

ObjectDefinitions.cactus_fruit = {
	id = "cactus_fruit",
	name = "Cactus Fruit",
	category = "plant",

	modelId = "cactus_fruit",
	scale = 1,
	randomRotation = true,

	interactionType = "harvest",
	itemId = "apple", -- Reusing apple for now
	quantity = NumberRange.new(1, 2),

	harvestTime = 2,
	respawnTime = 300,

	spawnRules = {
		biomes = { "plains" },
		density = 3,
	},
}

--------------------------------------------------------------------------------
-- UNIVERSAL OBJECTS
--------------------------------------------------------------------------------

ObjectDefinitions.wild_apple = {
	id = "wild_apple",
	name = "Wild Apple",
	category = "plant",

	modelId = "wild_apple",
	scale = 1,
	randomRotation = true,

	interactionType = "harvest",
	itemId = "apple",
	quantity = NumberRange.new(1, 3),

	harvestTime = 1,
	respawnTime = 150,

	spawnRules = {
		density = 4, -- Spawns in all biomes
	},
}

ObjectDefinitions.rare_flower = {
	id = "rare_flower",
	name = "Basin Orchid",
	category = "collectible",

	modelId = "rare_flower",
	scale = 1,
	randomRotation = true,

	interactionType = "pickup",
	itemId = "rare_flower",
	quantity = NumberRange.new(1, 1),

	respawnTime = 600, -- 10 minutes

	spawnRules = {
		biomes = { "wetland" },
		density = 0.5, -- Very rare
	},
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

function ObjectDefinitions.get(id: string): ObjectDefinition?
	return ObjectDefinitions[id]
end

function ObjectDefinitions.getAll(): { [string]: ObjectDefinition }
	local result = {}
	for key, value in ObjectDefinitions do
		if type(value) == "table" and value.id then
			result[key] = value
		end
	end
	return result
end

function ObjectDefinitions.getByBiome(biome: string): { ObjectDefinition }
	local result = {}
	for _, def in ObjectDefinitions.getAll() do
		local biomes = def.spawnRules.biomes
		if not biomes or table.find(biomes, biome) then
			table.insert(result, def)
		end
	end
	return result
end

function ObjectDefinitions.getByCategory(category: string): { ObjectDefinition }
	local result = {}
	for _, def in ObjectDefinitions.getAll() do
		if def.category == category then
			table.insert(result, def)
		end
	end
	return result
end

return ObjectDefinitions
