--!strict
--[[
    DiscoveryDefinitions

    Defines all discoverable content: species, flora, locations, and lore.
    Following "implement in twos" - starting with 2 examples of each type.

    Usage:
        local DiscoveryDefinitions = require(script.Parent.DiscoveryDefinitions)
        local species = DiscoveryDefinitions.getByCategory("species")
]]

local DiscoveryDefinitions = {}

-- Types
export type DiscoveryCategory = "species" | "flora" | "locations" | "lore"

export type DiscoveryDefinition = {
	id: string,
	category: DiscoveryCategory,
	name: string,
	description: string,
	-- Discovery requirements
	discoverMethod: "observe" | "interact" | "proximity" | "quest",
	-- Optional metadata
	rarity: "common" | "uncommon" | "rare" | "legendary"?,
	biomes: { string }?, -- Which biomes this can be found in
	icon: string?, -- Asset ID for journal
	-- For species/flora
	speciesId: string?, -- Links to NPCDefinitions or ObjectDefinitions
	-- For locations
	position: Vector3?,
	radius: number?, -- Discovery radius in studs
	-- Rewards
	experienceReward: number?,
}

-- Discovery definitions: 2 of each type to find patterns
local DEFINITIONS: { DiscoveryDefinition } = {
	-- ============================================================
	-- SPECIES (2 examples)
	-- ============================================================
	{
		id = "species_forest_deer",
		category = "species",
		name = "Forest Deer",
		description = "A graceful herbivore that roams the verdant basin. They travel in small herds and are easily startled.",
		discoverMethod = "observe",
		rarity = "common",
		biomes = { "verdant_basin" },
		speciesId = "deer",
		experienceReward = 10,
	},
	{
		id = "species_golden_frog",
		category = "species",
		name = "Golden Frog",
		description = "A rare amphibian with shimmering golden skin. Often found near pristine water sources.",
		discoverMethod = "observe",
		rarity = "rare",
		biomes = { "verdant_basin" },
		speciesId = "golden_frog",
		experienceReward = 50,
	},

	-- ============================================================
	-- FLORA (2 examples)
	-- ============================================================
	{
		id = "flora_healing_herb",
		category = "flora",
		name = "Verdant Healing Herb",
		description = "A medicinal plant with soothing properties. The leaves can be used to restore health.",
		discoverMethod = "interact",
		rarity = "common",
		biomes = { "verdant_basin" },
		speciesId = "healing_herb",
		experienceReward = 5,
	},
	{
		id = "flora_moonpetal",
		category = "flora",
		name = "Moonpetal Flower",
		description = "A luminescent flower that only blooms under moonlight. Its petals glow with an ethereal blue light.",
		discoverMethod = "observe",
		rarity = "uncommon",
		biomes = { "verdant_basin" },
		speciesId = "moonpetal",
		experienceReward = 25,
	},

	-- ============================================================
	-- LOCATIONS (2 examples)
	-- World is 500x500 centered at origin, so X/Z range from -250 to 250
	-- ============================================================
	{
		id = "location_ancient_oak",
		category = "locations",
		name = "The Ancient Oak",
		description = "A massive oak tree that has stood for centuries. Local wildlife considers it sacred ground.",
		discoverMethod = "proximity",
		rarity = "uncommon",
		biomes = { "verdant_basin" },
		position = Vector3.new(120, 25, 80), -- Northeast quadrant, on higher ground
		radius = 30,
		experienceReward = 20,
	},
	{
		id = "location_crystal_spring",
		category = "locations",
		name = "Crystal Spring",
		description = "A natural spring with crystal-clear water. The ecosystem around it is particularly vibrant.",
		discoverMethod = "proximity",
		rarity = "rare",
		biomes = { "verdant_basin" },
		position = Vector3.new(60, 15, -40), -- East of spawn, in a low wetland area
		radius = 25,
		experienceReward = 35,
	},

	-- ============================================================
	-- LORE (2 examples)
	-- ============================================================
	{
		id = "lore_basin_history",
		category = "lore",
		name = "Origins of the Basin",
		description = "Long ago, this valley was carved by ancient rivers. The rich soil left behind became the foundation for the thriving ecosystem we see today.",
		discoverMethod = "quest",
		rarity = "common",
		experienceReward = 15,
	},
	{
		id = "lore_balance_principle",
		category = "lore",
		name = "The Principle of Balance",
		description = "Every action in an ecosystem has consequences. When one species thrives, others must adapt. True stewardship means understanding these connections.",
		discoverMethod = "quest",
		rarity = "uncommon",
		experienceReward = 25,
	},
}

-- Lookup tables (built on first access)
local byId: { [string]: DiscoveryDefinition }?
local byCategory: { [DiscoveryCategory]: { DiscoveryDefinition } }?
local byBiome: { [string]: { DiscoveryDefinition } }?

--------------------------------------------------------------------------------
-- BUILD INDEXES
--------------------------------------------------------------------------------

local function ensureIndexes()
	if byId then
		return
	end

	byId = {}
	byCategory = {
		species = {},
		flora = {},
		locations = {},
		lore = {},
	}
	byBiome = {}

	for _, def in DEFINITIONS do
		byId[def.id] = def
		table.insert(byCategory[def.category], def)

		if def.biomes then
			for _, biome in def.biomes do
				if not byBiome[biome] then
					byBiome[biome] = {}
				end
				table.insert(byBiome[biome], def)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function DiscoveryDefinitions.get(id: string): DiscoveryDefinition?
	ensureIndexes()
	return byId[id]
end

function DiscoveryDefinitions.getAll(): { DiscoveryDefinition }
	return DEFINITIONS
end

function DiscoveryDefinitions.getByCategory(category: DiscoveryCategory): { DiscoveryDefinition }
	ensureIndexes()
	return byCategory[category] or {}
end

function DiscoveryDefinitions.getByBiome(biome: string): { DiscoveryDefinition }
	ensureIndexes()
	return byBiome[biome] or {}
end

function DiscoveryDefinitions.getCategoryCount(category: DiscoveryCategory): number
	ensureIndexes()
	return #(byCategory[category] or {})
end

function DiscoveryDefinitions.getTotalCount(): number
	return #DEFINITIONS
end

return DiscoveryDefinitions
