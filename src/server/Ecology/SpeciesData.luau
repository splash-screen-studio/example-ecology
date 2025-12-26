--!strict
--[[
    SpeciesData

    Definitions for all species in the game.
    Each species has population dynamics, resource needs, and interactions.
]]

local Types = require(script.Parent.Types)

local SpeciesData: { [string]: Types.SpeciesDefinition } = {}

--------------------------------------------------------------------------------
-- PRODUCERS (Plants, base of food chain)
--------------------------------------------------------------------------------

SpeciesData.wetland_grass = {
	id = "wetland_grass",
	name = "Marsh Grass",
	category = "producer",
	baseGrowthRate = 1.05, -- Grows 5% per tick
	carryingCapacity = 1000,
	minViablePopulation = 10,
	waterNeed = 0.3,
	foodNeed = 0, -- Producers don't need food
	shelterNeed = 0,
	preyOn = {},
	predators = { "marsh_rabbit", "wetland_deer", "pond_turtle" },
	preferredBiome = "wetland",
	waterTolerance = { min = 20, max = 100 },
}

SpeciesData.water_lily = {
	id = "water_lily",
	name = "Water Lily",
	category = "producer",
	baseGrowthRate = 1.03,
	carryingCapacity = 500,
	minViablePopulation = 5,
	waterNeed = 0.5,
	foodNeed = 0,
	shelterNeed = 0,
	preyOn = {},
	predators = { "pond_fish", "pond_turtle" },
	preferredBiome = "wetland",
	waterTolerance = { min = 40, max = 100 },
}

SpeciesData.plains_grass = {
	id = "plains_grass",
	name = "Prairie Grass",
	category = "producer",
	baseGrowthRate = 1.02, -- Slower in dry conditions
	carryingCapacity = 800,
	minViablePopulation = 20,
	waterNeed = 0.1, -- Drought tolerant
	foodNeed = 0,
	shelterNeed = 0,
	preyOn = {},
	predators = { "plains_hare", "pronghorn" },
	preferredBiome = "plains",
	waterTolerance = { min = 0, max = 60 },
}

--------------------------------------------------------------------------------
-- HERBIVORES
--------------------------------------------------------------------------------

SpeciesData.marsh_rabbit = {
	id = "marsh_rabbit",
	name = "Marsh Rabbit",
	category = "herbivore",
	baseGrowthRate = 1.08, -- Breeds quickly
	carryingCapacity = 200,
	minViablePopulation = 10,
	waterNeed = 0.2,
	foodNeed = 0.4,
	shelterNeed = 0.3,
	preyOn = { "wetland_grass" },
	predators = { "marsh_fox", "heron" },
	preferredBiome = "wetland",
	waterTolerance = { min = 10, max = 80 },
}

SpeciesData.wetland_deer = {
	id = "wetland_deer",
	name = "Wetland Deer",
	category = "herbivore",
	baseGrowthRate = 1.02,
	carryingCapacity = 50,
	minViablePopulation = 5,
	waterNeed = 0.3,
	foodNeed = 0.5,
	shelterNeed = 0.2,
	preyOn = { "wetland_grass" },
	predators = { "marsh_wolf" },
	preferredBiome = "wetland",
	waterTolerance = { min = 10, max = 70 },
}

SpeciesData.pond_turtle = {
	id = "pond_turtle",
	name = "Pond Turtle",
	category = "omnivore",
	baseGrowthRate = 1.01, -- Slow breeders
	carryingCapacity = 100,
	minViablePopulation = 5,
	waterNeed = 0.6,
	foodNeed = 0.2,
	shelterNeed = 0.1,
	preyOn = { "wetland_grass", "water_lily", "pond_fish" },
	predators = { "heron" },
	preferredBiome = "wetland",
	waterTolerance = { min = 30, max = 100 },
}

SpeciesData.pond_fish = {
	id = "pond_fish",
	name = "Basin Minnow",
	category = "herbivore",
	baseGrowthRate = 1.1,
	carryingCapacity = 500,
	minViablePopulation = 20,
	waterNeed = 1.0, -- Must have water
	foodNeed = 0.2,
	shelterNeed = 0.1,
	preyOn = { "water_lily" },
	predators = { "heron", "pond_turtle", "marsh_fox" },
	preferredBiome = "wetland",
	waterTolerance = { min = 50, max = 100 },
}

SpeciesData.plains_hare = {
	id = "plains_hare",
	name = "Prairie Hare",
	category = "herbivore",
	baseGrowthRate = 1.06,
	carryingCapacity = 150,
	minViablePopulation = 10,
	waterNeed = 0.1,
	foodNeed = 0.3,
	shelterNeed = 0.2,
	preyOn = { "plains_grass" },
	predators = { "coyote", "hawk" },
	preferredBiome = "plains",
	waterTolerance = { min = 0, max = 50 },
}

SpeciesData.pronghorn = {
	id = "pronghorn",
	name = "Pronghorn",
	category = "herbivore",
	baseGrowthRate = 1.02,
	carryingCapacity = 30,
	minViablePopulation = 4,
	waterNeed = 0.2,
	foodNeed = 0.4,
	shelterNeed = 0.1,
	preyOn = { "plains_grass" },
	predators = { "coyote" },
	preferredBiome = "plains",
	waterTolerance = { min = 0, max = 40 },
}

--------------------------------------------------------------------------------
-- CARNIVORES / OMNIVORES
--------------------------------------------------------------------------------

SpeciesData.marsh_fox = {
	id = "marsh_fox",
	name = "Marsh Fox",
	category = "carnivore",
	baseGrowthRate = 1.01,
	carryingCapacity = 20,
	minViablePopulation = 2,
	waterNeed = 0.2,
	foodNeed = 0.6,
	shelterNeed = 0.3,
	preyOn = { "marsh_rabbit", "pond_fish" },
	predators = { "marsh_wolf" },
	preferredBiome = "wetland",
	waterTolerance = { min = 10, max = 70 },
}

SpeciesData.heron = {
	id = "heron",
	name = "Great Heron",
	category = "carnivore",
	baseGrowthRate = 1.01,
	carryingCapacity = 30,
	minViablePopulation = 2,
	waterNeed = 0.4,
	foodNeed = 0.5,
	shelterNeed = 0.2,
	preyOn = { "pond_fish", "pond_turtle", "marsh_rabbit" },
	predators = {},
	preferredBiome = "wetland",
	waterTolerance = { min = 20, max = 100 },
}

SpeciesData.marsh_wolf = {
	id = "marsh_wolf",
	name = "Marsh Wolf",
	category = "carnivore",
	baseGrowthRate = 1.005, -- Apex predator, slow growth
	carryingCapacity = 8,
	minViablePopulation = 2,
	waterNeed = 0.2,
	foodNeed = 0.7,
	shelterNeed = 0.3,
	preyOn = { "wetland_deer", "marsh_rabbit", "marsh_fox" },
	predators = {},
	preferredBiome = "wetland",
	waterTolerance = { min = 5, max = 60 },
}

SpeciesData.coyote = {
	id = "coyote",
	name = "Plains Coyote",
	category = "carnivore",
	baseGrowthRate = 1.02,
	carryingCapacity = 15,
	minViablePopulation = 2,
	waterNeed = 0.1,
	foodNeed = 0.5,
	shelterNeed = 0.2,
	preyOn = { "plains_hare", "pronghorn" },
	predators = {},
	preferredBiome = "plains",
	waterTolerance = { min = 0, max = 40 },
}

SpeciesData.hawk = {
	id = "hawk",
	name = "Prairie Hawk",
	category = "carnivore",
	baseGrowthRate = 1.01,
	carryingCapacity = 20,
	minViablePopulation = 2,
	waterNeed = 0.1,
	foodNeed = 0.4,
	shelterNeed = 0.2,
	preyOn = { "plains_hare" },
	predators = {},
	preferredBiome = "plains",
	waterTolerance = { min = 0, max = 50 },
}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

-- Get all species for a biome
function SpeciesData.getForBiome(biome: string): { Types.SpeciesDefinition }
	local result = {}
	for _, species in SpeciesData do
		if type(species) == "table" and species.preferredBiome == biome then
			table.insert(result, species)
		end
	end
	return result
end

-- Get species by category
function SpeciesData.getByCategory(category: Types.SpeciesCategory): { Types.SpeciesDefinition }
	local result = {}
	for _, species in SpeciesData do
		if type(species) == "table" and species.category == category then
			table.insert(result, species)
		end
	end
	return result
end

return SpeciesData
