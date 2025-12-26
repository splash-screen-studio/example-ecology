--!strict
--[[
    DialogueDefinitions

    Defines dialogue trees for NPCs.
    Following "implement in twos" - 2 NPCs with dialogue.

    Usage:
        local DialogueDefinitions = require(script.Parent.DialogueDefinitions)
        local dialogue = DialogueDefinitions.getForNPC("ranger_maya")
]]

local DialogueDefinitions = {}

-- Types
export type ConditionType = "quest_active" | "quest_complete" | "quest_available" | "has_discovery" | "has_item" | "none"

export type Condition = {
	type: ConditionType,
	id: string?, -- questId, discoveryId, or itemId
}

export type Effect = {
	type: "start_quest" | "complete_quest" | "give_item" | "take_item" | "trigger_discovery",
	id: string?,
	amount: number?,
}

export type DialogueResponse = {
	text: string,
	nextNode: string?, -- Node ID to go to, nil = end conversation
	conditions: { Condition }?, -- All must be true to show this response
	effects: { Effect }?, -- Effects when this response is chosen
}

export type DialogueNode = {
	id: string,
	speaker: string, -- NPC name or "player"
	text: string,
	responses: { DialogueResponse }?,
	-- Auto-advance after delay (for monologue)
	autoAdvance: number?, -- seconds, nil = wait for player
	nextNode: string?, -- For auto-advance
	-- Entry conditions (show this node if conditions met)
	conditions: { Condition }?,
}

export type DialogueTree = {
	npcId: string,
	npcName: string,
	startNode: string, -- Default starting node
	nodes: { DialogueNode },
}

-- Dialogue trees: 2 NPCs to find patterns
local TREES: { DialogueTree } = {
	-- ============================================================
	-- RANGER MAYA - Tutorial guide and quest giver
	-- ============================================================
	{
		npcId = "ranger_maya",
		npcName = "Ranger Maya",
		startNode = "greeting",
		nodes = {
			-- Greeting branches based on quest state
			{
				id = "greeting",
				speaker = "Ranger Maya",
				text = "Welcome to the Verdant Basin! I'm Ranger Maya, the local wildlife guardian.",
				responses = {
					{
						text = "I'm new here. What should I do?",
						nextNode = "intro_new",
						conditions = { { type = "quest_available", id = "tutorial_first_steps" } },
					},
					{
						text = "How's my quest going?",
						nextNode = "quest_progress",
						conditions = { { type = "quest_active", id = "tutorial_first_steps" } },
					},
					{
						text = "I've completed your quest!",
						nextNode = "quest_complete_tutorial",
						conditions = { { type = "quest_active", id = "tutorial_first_steps" } },
					},
					{
						text = "Any new tasks for me?",
						nextNode = "check_observation_quest",
						conditions = { { type = "quest_complete", id = "tutorial_first_steps" } },
					},
					{
						text = "Just passing through. Goodbye!",
						nextNode = nil,
					},
				},
			},

			-- New player introduction
			{
				id = "intro_new",
				speaker = "Ranger Maya",
				text = "Ah, a newcomer! This basin is teeming with life, but survival requires preparation. Let me give you your first task.",
				responses = {
					{
						text = "I'm ready to learn!",
						nextNode = "give_first_quest",
						effects = { { type = "start_quest", id = "tutorial_first_steps" } },
					},
					{
						text = "Maybe later.",
						nextNode = "farewell_casual",
					},
				},
			},

			{
				id = "give_first_quest",
				speaker = "Ranger Maya",
				text = "Gather some berries for food and find a water source. The crystal spring to the east is a good place to start. Good luck!",
				responses = {
					{
						text = "I'll get right on it!",
						nextNode = nil,
					},
				},
			},

			-- Quest progress check
			{
				id = "quest_progress",
				speaker = "Ranger Maya",
				text = "How's the foraging going? Remember, berries grow near bushes and the crystal spring is east of here.",
				responses = {
					{
						text = "I'm still working on it.",
						nextNode = "encouragement",
					},
					{
						text = "Thanks for the reminder!",
						nextNode = nil,
					},
				},
			},

			{
				id = "encouragement",
				speaker = "Ranger Maya",
				text = "Take your time. Survival is about patience and observation. You'll find what you need.",
				responses = {
					{
						text = "I'll keep looking.",
						nextNode = nil,
					},
				},
			},

			-- First quest complete
			{
				id = "quest_complete_tutorial",
				speaker = "Ranger Maya",
				text = "Excellent work! You've proven you can survive here. Take this water flask - it'll help you stay hydrated on longer journeys.",
				responses = {
					{
						text = "Thank you! What's next?",
						nextNode = "intro_observation",
					},
				},
			},

			-- Second quest introduction
			{
				id = "check_observation_quest",
				speaker = "Ranger Maya",
				text = "You've mastered the basics. Now it's time to learn about the wildlife here.",
				conditions = { { type = "quest_available", id = "tutorial_observation" } },
				responses = {
					{
						text = "Tell me more.",
						nextNode = "intro_observation",
					},
					{
						text = "I'm not ready yet.",
						nextNode = nil,
					},
				},
			},

			{
				id = "intro_observation",
				speaker = "Ranger Maya",
				text = "The basin is home to many creatures. Learn to observe them without disturbing their natural behavior. Watch the deer in the meadows.",
				responses = {
					{
						text = "I'll become a nature observer!",
						nextNode = "give_observation_quest",
						effects = { { type = "start_quest", id = "tutorial_observation" } },
					},
					{
						text = "Maybe later.",
						nextNode = nil,
					},
				},
			},

			{
				id = "give_observation_quest",
				speaker = "Ranger Maya",
				text = "Move slowly, stay downwind, and be patient. Your field journal will help you record what you find. May your eyes be sharp!",
				responses = {
					{
						text = "I'll observe carefully!",
						nextNode = nil,
					},
				},
			},

			-- Generic farewell
			{
				id = "farewell_casual",
				speaker = "Ranger Maya",
				text = "Come back when you're ready. The basin will be waiting.",
				responses = {
					{
						text = "Goodbye!",
						nextNode = nil,
					},
				},
			},
		},
	},

	-- ============================================================
	-- RESEARCHER CHEN - Discovery and science quests
	-- ============================================================
	{
		npcId = "researcher_chen",
		npcName = "Dr. Chen",
		startNode = "greeting",
		nodes = {
			{
				id = "greeting",
				speaker = "Dr. Chen",
				text = "Ah, a fellow explorer! I'm Dr. Chen, studying the unique ecosystem here. The biodiversity is remarkable!",
				responses = {
					{
						text = "What kind of research do you do?",
						nextNode = "explain_research",
					},
					{
						text = "Need help with anything?",
						nextNode = "check_quests",
					},
					{
						text = "Just browsing. Goodbye!",
						nextNode = nil,
					},
				},
			},

			{
				id = "explain_research",
				speaker = "Dr. Chen",
				text = "I document rare species and ancient landmarks. This basin holds secrets from before recorded history. The ecological balance here is... delicate.",
				responses = {
					{
						text = "Sounds fascinating! Can I help?",
						nextNode = "check_quests",
					},
					{
						text = "Interesting. I should go.",
						nextNode = nil,
					},
				},
			},

			{
				id = "check_quests",
				speaker = "Dr. Chen",
				text = "Help? Always! Science needs many eyes.",
				responses = {
					{
						text = "Tell me about rare species.",
						nextNode = "golden_frog_intro",
						conditions = { { type = "quest_available", id = "discovery_rare_species" } },
					},
					{
						text = "Any ancient sites to explore?",
						nextNode = "ancient_places_intro",
						conditions = { { type = "quest_available", id = "discovery_ancient_places" } },
					},
					{
						text = "I'll come back later.",
						nextNode = nil,
					},
				},
			},

			-- Golden Frog quest
			{
				id = "golden_frog_intro",
				speaker = "Dr. Chen",
				text = "There are whispers of a golden frog in this basin - extremely rare! Its skin shimmers like sunlight on water. I've never seen one myself.",
				responses = {
					{
						text = "I'll find it for you!",
						nextNode = "golden_frog_accept",
						effects = { { type = "start_quest", id = "discovery_rare_species" } },
					},
					{
						text = "Sounds too difficult.",
						nextNode = "encouragement_research",
					},
				},
			},

			{
				id = "golden_frog_accept",
				speaker = "Dr. Chen",
				text = "Wonderful! They're said to live near the purest water sources. Be patient and quiet - they startle easily. Bring proof of your observation!",
				responses = {
					{
						text = "I'm on it!",
						nextNode = nil,
					},
				},
			},

			-- Ancient places quest
			{
				id = "ancient_places_intro",
				speaker = "Dr. Chen",
				text = "The basin has landmarks older than any maps. There's an ancient oak said to be centuries old, and a crystal spring that the locals consider sacred.",
				responses = {
					{
						text = "I'll explore these places!",
						nextNode = "ancient_places_accept",
						effects = { { type = "start_quest", id = "discovery_ancient_places" } },
					},
					{
						text = "Maybe another time.",
						nextNode = nil,
					},
				},
			},

			{
				id = "ancient_places_accept",
				speaker = "Dr. Chen",
				text = "Excellent! Document what you find. The oak is to the northeast, and the spring is to the east. History awaits!",
				responses = {
					{
						text = "I'll report back!",
						nextNode = nil,
					},
				},
			},

			-- Encouragement for hesitant players
			{
				id = "encouragement_research",
				speaker = "Dr. Chen",
				text = "Science isn't easy, but the rewards are worth it. Come back when you feel ready - the mysteries will still be here.",
				responses = {
					{
						text = "I'll think about it.",
						nextNode = nil,
					},
				},
			},
		},
	},
}

-- Lookup tables
local byNpcId: { [string]: DialogueTree }?

--------------------------------------------------------------------------------
-- BUILD INDEXES
--------------------------------------------------------------------------------

local function ensureIndexes()
	if byNpcId then
		return
	end

	byNpcId = {}
	for _, tree in TREES do
		byNpcId[tree.npcId] = tree
	end
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function DialogueDefinitions.getForNPC(npcId: string): DialogueTree?
	ensureIndexes()
	return byNpcId[npcId]
end

function DialogueDefinitions.getNode(npcId: string, nodeId: string): DialogueNode?
	ensureIndexes()

	local tree = byNpcId[npcId]
	if not tree then
		return nil
	end

	for _, node in tree.nodes do
		if node.id == nodeId then
			return node
		end
	end

	return nil
end

function DialogueDefinitions.getAll(): { DialogueTree }
	return TREES
end

function DialogueDefinitions.getNPCList(): { string }
	local npcs = {}
	for _, tree in TREES do
		table.insert(npcs, tree.npcId)
	end
	return npcs
end

return DialogueDefinitions
