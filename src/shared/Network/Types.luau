--!strict
--[[
    Network Types

    Shared type definitions for client-server communication.
    All network payloads should be defined here for type safety.
]]

local Types = {}

-- Result type for server responses
export type Result<T> = {
	success: boolean,
	data: T?,
	error: string?,
}

--------------------------------------------------------------------------------
-- INVENTORY EVENTS
--------------------------------------------------------------------------------

export type UseItemRequest = {
	itemId: string,
	targetId: string?, -- Optional target (NPC, object, etc.)
}

export type UseItemResponse = Result<{
	consumed: boolean,
	effectApplied: string?,
}>

export type DropItemRequest = {
	itemId: string,
	quantity: number,
}

export type PickupItemRequest = {
	objectId: string, -- The world object to pick up
}

--------------------------------------------------------------------------------
-- INTERACTION EVENTS
--------------------------------------------------------------------------------

export type InteractRequest = {
	targetId: string,
	interactionType: string, -- "talk", "examine", "use", etc.
}

export type InteractResponse = Result<{
	interactionId: string?,
	dialogueData: any?, -- For NPC conversations
}>

--------------------------------------------------------------------------------
-- QUEST EVENTS
--------------------------------------------------------------------------------

export type AcceptQuestRequest = {
	questId: string,
	giverId: string?, -- NPC who gave the quest
}

export type CompleteQuestRequest = {
	questId: string,
}

export type QuestUpdatePayload = {
	questId: string,
	objectiveId: string,
	progress: number,
	completed: boolean,
}

--------------------------------------------------------------------------------
-- ECOLOGY EVENTS
--------------------------------------------------------------------------------

export type EcoActionRequest = {
	actionType: string, -- "plant", "water", "feed", "clean", etc.
	targetId: string?, -- Species or object affected
	position: Vector3?,
}

export type EcoActionResponse = Result<{
	impactPositive: boolean,
	message: string?,
}>

--------------------------------------------------------------------------------
-- DISCOVERY EVENTS
--------------------------------------------------------------------------------

export type DiscoveryPayload = {
	category: "species" | "locations",
	id: string,
	name: string,
	description: string?,
}

--------------------------------------------------------------------------------
-- PLAYER STATE SYNC
--------------------------------------------------------------------------------

export type StatUpdatePayload = {
	hunger: number?,
	thirst: number?,
}

export type SettingsUpdateRequest = {
	musicVolume: number?,
	sfxVolume: number?,
	showTutorials: boolean?,
}

--------------------------------------------------------------------------------
-- TELEPORT EVENTS
--------------------------------------------------------------------------------

export type TeleportRequest = {
	destination: string, -- Place name
	groupMembers: { number }?, -- UserIds to teleport with
}

--------------------------------------------------------------------------------
-- GROUP EVENTS
--------------------------------------------------------------------------------

export type GroupInviteRequest = {
	targetUserId: number,
}

export type GroupResponseRequest = {
	leaderId: number,
	accepted: boolean,
}

return Types
