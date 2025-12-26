--!strict
--[[
    QuestDefinitions

    Defines all quests with objectives and rewards.
    Following "implement in twos" - starting with 2 quest types.

    Usage:
        local QuestDefinitions = require(script.Parent.QuestDefinitions)
        local quest = QuestDefinitions.get("tutorial_first_steps")
]]

local QuestDefinitions = {}

-- Types
export type ObjectiveType = "collect" | "discover" | "observe" | "interact" | "reach_location"

export type Objective = {
	id: string,
	type: ObjectiveType,
	targetId: string, -- itemId, discoveryId, speciesId, or locationId
	count: number, -- How many needed
	description: string,
}

export type Reward = {
	type: "item" | "currency" | "discovery" | "unlock",
	id: string?, -- itemId or unlockId
	amount: number?,
}

export type QuestDefinition = {
	id: string,
	name: string,
	description: string,
	category: "tutorial" | "discovery" | "restoration" | "collection",
	-- Objectives (all must be completed)
	objectives: { Objective },
	-- Rewards on completion
	rewards: { Reward },
	-- Prerequisites
	prerequisiteQuests: { string }?, -- Quest IDs that must be completed first
	prerequisiteDiscoveries: { string }?, -- Discovery IDs required
	-- Metadata
	isRepeatable: boolean?,
	timeLimit: number?, -- Seconds, nil = no limit
	questGiver: string?, -- NPC ID who gives this quest
}

-- Quest definitions: 2 types to find patterns
local DEFINITIONS: { QuestDefinition } = {
	-- ============================================================
	-- TUTORIAL QUESTS (teach mechanics)
	-- ============================================================
	{
		id = "tutorial_first_steps",
		name = "First Steps",
		description = "Learn the basics of survival in the verdant basin. Gather some food and water to sustain yourself.",
		category = "tutorial",
		objectives = {
			{
				id = "gather_berries",
				type = "collect",
				targetId = "berries",
				count = 3,
				description = "Gather 3 berries",
			},
			{
				id = "find_water",
				type = "reach_location",
				targetId = "location_crystal_spring",
				count = 1,
				description = "Find a water source",
			},
		},
		rewards = {
			{
				type = "item",
				id = "water_flask",
				amount = 1,
			},
			{
				type = "discovery",
				id = "lore_basin_history",
			},
		},
		questGiver = "ranger_maya",
	},
	{
		id = "tutorial_observation",
		name = "Nature's Observer",
		description = "The ecosystem is full of life. Learn to observe creatures without disturbing them.",
		category = "tutorial",
		objectives = {
			{
				id = "observe_deer",
				type = "observe",
				targetId = "deer",
				count = 1,
				description = "Observe a forest deer",
			},
			{
				id = "observe_any_species",
				type = "discover",
				targetId = "any_species",
				count = 2,
				description = "Discover 2 different species",
			},
		},
		rewards = {
			{
				type = "item",
				id = "field_journal",
				amount = 1,
			},
			{
				type = "currency",
				amount = 50,
			},
		},
		prerequisiteQuests = { "tutorial_first_steps" },
		questGiver = "ranger_maya",
	},

	-- ============================================================
	-- DISCOVERY QUESTS (explore the world)
	-- ============================================================
	{
		id = "discovery_rare_species",
		name = "The Golden Gleam",
		description = "Rumors speak of a rare golden frog in the basin. Find and observe this elusive creature.",
		category = "discovery",
		objectives = {
			{
				id = "find_golden_frog",
				type = "discover",
				targetId = "species_golden_frog",
				count = 1,
				description = "Discover the Golden Frog",
			},
		},
		rewards = {
			{
				type = "item",
				id = "golden_essence",
				amount = 1,
			},
			{
				type = "currency",
				amount = 100,
			},
			{
				type = "discovery",
				id = "lore_balance_principle",
			},
		},
		prerequisiteQuests = { "tutorial_observation" },
		questGiver = "researcher_sage",
	},
	{
		id = "discovery_ancient_places",
		name = "Echoes of the Past",
		description = "Ancient landmarks dot the landscape. Find the places where history still lingers.",
		category = "discovery",
		objectives = {
			{
				id = "find_ancient_oak",
				type = "reach_location",
				targetId = "location_ancient_oak",
				count = 1,
				description = "Find the Ancient Oak",
			},
			{
				id = "find_crystal_spring",
				type = "reach_location",
				targetId = "location_crystal_spring",
				count = 1,
				description = "Find the Crystal Spring",
			},
		},
		rewards = {
			{
				type = "item",
				id = "ancient_map",
				amount = 1,
			},
			{
				type = "currency",
				amount = 75,
			},
		},
		prerequisiteQuests = { "tutorial_first_steps" },
		questGiver = "researcher_sage",
	},
}

-- Lookup tables
local byId: { [string]: QuestDefinition }?
local byCategory: { [string]: { QuestDefinition } }?
local byQuestGiver: { [string]: { QuestDefinition } }?

--------------------------------------------------------------------------------
-- BUILD INDEXES
--------------------------------------------------------------------------------

local function ensureIndexes()
	if byId then
		return
	end

	byId = {}
	byCategory = {}
	byQuestGiver = {}

	for _, def in DEFINITIONS do
		byId[def.id] = def

		if not byCategory[def.category] then
			byCategory[def.category] = {}
		end
		table.insert(byCategory[def.category], def)

		if def.questGiver then
			if not byQuestGiver[def.questGiver] then
				byQuestGiver[def.questGiver] = {}
			end
			table.insert(byQuestGiver[def.questGiver], def)
		end
	end
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function QuestDefinitions.get(id: string): QuestDefinition?
	ensureIndexes()
	return byId[id]
end

function QuestDefinitions.getAll(): { QuestDefinition }
	return DEFINITIONS
end

function QuestDefinitions.getByCategory(category: string): { QuestDefinition }
	ensureIndexes()
	return byCategory[category] or {}
end

function QuestDefinitions.getByQuestGiver(npcId: string): { QuestDefinition }
	ensureIndexes()
	return byQuestGiver[npcId] or {}
end

function QuestDefinitions.getTotalCount(): number
	return #DEFINITIONS
end

return QuestDefinitions
