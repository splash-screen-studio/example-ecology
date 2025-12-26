--!strict
--[[
    Ecology Types

    Core data structures for the ecology simulation.
]]

local Types = {}

-- Species categories for different interaction rules
export type SpeciesCategory = "producer" | "herbivore" | "carnivore" | "omnivore" | "decomposer"

-- Species definition (static data)
export type SpeciesDefinition = {
	id: string,
	name: string,
	category: SpeciesCategory,

	-- Population dynamics
	baseGrowthRate: number, -- Per tick multiplier (1.0 = stable)
	carryingCapacity: number, -- Max population per region
	minViablePopulation: number, -- Below this, species dies out

	-- Resource needs (per population unit per tick)
	waterNeed: number,
	foodNeed: number,
	shelterNeed: number,

	-- Interactions
	preyOn: { string }, -- Species IDs this species eats
	predators: { string }, -- Species IDs that eat this species

	-- Environmental preferences
	preferredBiome: string?, -- "wetland", "plains", etc.
	waterTolerance: { min: number, max: number }, -- Water level range
}

-- Population state (dynamic, per region)
export type PopulationState = {
	count: number,
	trend: "growing" | "stable" | "declining" | "critical",
	lastChange: number, -- Tick when last changed
	stressLevel: number, -- 0-1, affects growth
}

-- Resource state (per region)
export type ResourceState = {
	water: number, -- 0-100
	vegetation: number, -- 0-100 (food for herbivores)
	prey: number, -- Derived from herbivore populations
	shelter: number, -- 0-100
}

-- Region definition
export type EcoRegion = {
	id: string,
	name: string,
	biome: string,
	bounds: { min: Vector3, max: Vector3 },
	neighbors: { string }, -- Adjacent region IDs

	-- Current state
	resources: ResourceState,
	populations: { [string]: PopulationState }, -- speciesId -> state
	health: number, -- 0-100 overall ecosystem health
	playerInfluence: number, -- -100 to 100 (negative = harmful)
}

-- Simulation event for logging/feedback
export type EcoEvent = {
	tick: number,
	regionId: string,
	eventType: "population_change" | "extinction" | "migration" | "resource_depleted" | "player_action",
	speciesId: string?,
	description: string,
	magnitude: number, -- How significant (-1 to 1)
}

-- Player action impact
export type PlayerImpact = {
	playerId: number,
	regionId: string,
	actionType: string,
	speciesAffected: { string },
	resourcesAffected: { string },
	magnitude: number, -- -1 to 1
	timestamp: number,
}

return Types
