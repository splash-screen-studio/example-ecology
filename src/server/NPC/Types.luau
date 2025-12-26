--!strict
--[[
    NPC Types

    Data structures for NPC management.
]]

local Types = {}

-- NPC categories
export type NPCCategory = "animal" | "human" | "creature"

-- AI states
export type AIState = "idle" | "wander" | "flee" | "chase" | "eat" | "drink" | "sleep" | "interact"

-- NPC definition (static data, matches species)
export type NPCDefinition = {
	id: string,
	name: string,
	category: NPCCategory,
	speciesId: string?, -- Links to EcologyService species

	-- Model
	modelId: string?, -- Asset ID or model name
	scale: number,

	-- Movement
	walkSpeed: number,
	runSpeed: number,
	turnSpeed: number,

	-- Behavior
	fleeDistance: number, -- Run from players within this range
	awarenessRadius: number, -- Detect threats/food in this range
	wanderRadius: number, -- How far to wander from spawn

	-- Needs (drives behavior)
	hungerRate: number, -- How fast hunger increases
	thirstRate: number,
	restRate: number,

	-- Combat (if applicable)
	aggressive: boolean,
	damage: number?,
	attackRange: number?,
	attackCooldown: number?,

	-- Sounds
	idleSounds: { string }?,
	alertSounds: { string }?,
	hurtSounds: { string }?,
}

-- NPC instance (runtime state)
export type NPCInstance = {
	id: string, -- Unique instance ID
	definitionId: string, -- Links to NPCDefinition
	regionId: string, -- Current ecology region

	-- State
	state: AIState,
	stateStartTime: number,
	targetPosition: Vector3?,
	targetEntity: string?, -- Another NPC or player

	-- Needs (0-100)
	hunger: number,
	thirst: number,
	energy: number,
	fear: number, -- Elevated when threats nearby

	-- Position
	spawnPosition: Vector3,
	currentPosition: Vector3,
	currentRotation: number,

	-- LOD
	lodLevel: number, -- 0 = full, 1 = reduced, 2 = minimal
	lastFullUpdate: number,

	-- Model reference
	model: Model?,
	isPooled: boolean,
}

-- Spawn point definition
export type SpawnPoint = {
	id: string,
	position: Vector3,
	radius: number, -- Spawn within this radius
	regionId: string,
	allowedSpecies: { string }, -- Which species can spawn here
	maxNPCs: number, -- Max NPCs from this point
	currentCount: number,
	cooldown: number, -- Seconds between spawns
	lastSpawn: number,
}

-- NPC event for logging
export type NPCEvent = {
	timestamp: number,
	npcId: string,
	eventType: "spawn" | "despawn" | "stateChange" | "death" | "interact",
	data: { [string]: any }?,
}

return Types
