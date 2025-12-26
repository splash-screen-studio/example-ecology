--!strict
--[[
    DialogueService

    Manages NPC conversations with branching dialogue trees.
    Handles conditions, effects, and quest integration.

    Usage:
        local DialogueService = require(script.Parent.DialogueService)
        DialogueService:init()

        -- Start conversation
        DialogueService:startConversation(player, "ranger_maya")

        -- Player selects response
        DialogueService:selectResponse(player, 1)
]]

local DialogueService = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies (lazy loaded)
local DialogueDefinitions
local PlayerDataService
local QuestService
local DiscoveryService
local InventoryService
local Network

-- Types
type ActiveConversation = {
	npcId: string,
	currentNodeId: string,
	startedAt: number,
}

-- State
local initialized = false
local activeConversations: { [Player]: ActiveConversation } = {}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not DialogueDefinitions then
		DialogueDefinitions = require(script.Parent.DialogueDefinitions)
	end
	if not PlayerDataService then
		PlayerDataService = require(script.Parent.Parent.Data.PlayerDataService)
	end
	if not Network then
		Network = require(ReplicatedStorage.Shared.Network)
	end
end

local function loadOptionalDependencies()
	if not QuestService then
		pcall(function()
			QuestService = require(script.Parent.Parent.Quest.QuestService)
		end)
	end
	if not DiscoveryService then
		pcall(function()
			DiscoveryService = require(script.Parent.Parent.Discovery.DiscoveryService)
		end)
	end
	if not InventoryService then
		pcall(function()
			InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
		end)
	end
end

--------------------------------------------------------------------------------
-- CONDITION CHECKING
--------------------------------------------------------------------------------

local function checkCondition(player: Player, condition: DialogueDefinitions.Condition): boolean
	loadOptionalDependencies()

	local data = PlayerDataService:getData(player)
	if not data then
		return false
	end

	if condition.type == "none" then
		return true
	end

	if condition.type == "quest_active" then
		return data.quests.active[condition.id] ~= nil
	end

	if condition.type == "quest_complete" then
		return data.quests.completed[condition.id] ~= nil
	end

	if condition.type == "quest_available" then
		if not QuestService then
			return false
		end
		local canAccept, _ = QuestService:canAcceptQuest(player, condition.id)
		return canAccept
	end

	if condition.type == "has_discovery" then
		if not DiscoveryService then
			return false
		end
		return DiscoveryService:hasDiscovered(player, condition.id)
	end

	if condition.type == "has_item" then
		return PlayerDataService:hasItem(player, condition.id, 1)
	end

	return true
end

local function checkAllConditions(player: Player, conditions: { DialogueDefinitions.Condition }?): boolean
	if not conditions or #conditions == 0 then
		return true
	end

	for _, condition in conditions do
		if not checkCondition(player, condition) then
			return false
		end
	end

	return true
end

--------------------------------------------------------------------------------
-- EFFECT APPLICATION
--------------------------------------------------------------------------------

local function applyEffect(player: Player, effect: DialogueDefinitions.Effect)
	loadOptionalDependencies()

	if effect.type == "start_quest" and QuestService and effect.id then
		QuestService:acceptQuest(player, effect.id)
	elseif effect.type == "complete_quest" and QuestService and effect.id then
		QuestService:completeQuest(player, effect.id)
	elseif effect.type == "give_item" and InventoryService and effect.id then
		InventoryService:addItem(player, effect.id, effect.amount or 1)
	elseif effect.type == "take_item" and effect.id then
		PlayerDataService:removeItem(player, effect.id, effect.amount or 1)
	elseif effect.type == "trigger_discovery" and DiscoveryService and effect.id then
		DiscoveryService:discover(player, effect.id)
	end
end

local function applyAllEffects(player: Player, effects: { DialogueDefinitions.Effect }?)
	if not effects then
		return
	end

	for _, effect in effects do
		applyEffect(player, effect)
	end
end

--------------------------------------------------------------------------------
-- DIALOGUE FLOW
--------------------------------------------------------------------------------

local function getFilteredResponses(player: Player, responses: { DialogueDefinitions.DialogueResponse }?): { DialogueDefinitions.DialogueResponse }
	if not responses then
		return {}
	end

	local filtered = {}
	for _, response in responses do
		if checkAllConditions(player, response.conditions) then
			table.insert(filtered, response)
		end
	end

	return filtered
end

local function findStartNode(player: Player, tree: DialogueDefinitions.DialogueTree): string
	-- Check for conditional entry points
	for _, node in tree.nodes do
		if node.conditions and checkAllConditions(player, node.conditions) then
			-- This node has conditions and they're all met - could be a special entry
			-- For now, still use the default startNode
		end
	end

	return tree.startNode
end

local function sendDialogueToClient(player: Player, npcName: string, node: DialogueDefinitions.DialogueNode, filteredResponses: { DialogueDefinitions.DialogueResponse })
	loadDependencies()

	-- Convert responses to client format (without conditions/effects)
	local clientResponses = {}
	for i, response in filteredResponses do
		table.insert(clientResponses, {
			index = i,
			text = response.text,
		})
	end

	-- Send via Interact network (reusing existing event for dialogue)
	Network.Events.InteractComplete:FireClient(player, {
		type = "dialogue",
		npcName = npcName,
		speaker = node.speaker,
		text = node.text,
		responses = clientResponses,
		autoAdvance = node.autoAdvance,
	})
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function DialogueService:startConversation(player: Player, npcId: string): boolean
	loadDependencies()

	-- Check if already in conversation
	if activeConversations[player] then
		return false
	end

	local tree = DialogueDefinitions.getForNPC(npcId)
	if not tree then
		warn("[DialogueService] No dialogue tree for NPC:", npcId)
		return false
	end

	local startNodeId = findStartNode(player, tree)
	local startNode = DialogueDefinitions.getNode(npcId, startNodeId)

	if not startNode then
		warn("[DialogueService] Start node not found:", startNodeId)
		return false
	end

	-- Start conversation
	activeConversations[player] = {
		npcId = npcId,
		currentNodeId = startNodeId,
		startedAt = os.clock(),
	}

	-- Get filtered responses for this player
	local filteredResponses = getFilteredResponses(player, startNode.responses)

	-- Send to client
	sendDialogueToClient(player, tree.npcName, startNode, filteredResponses)

	print(string.format("[DialogueService] %s started conversation with %s", player.Name, tree.npcName))

	-- Handle auto-advance
	if startNode.autoAdvance and startNode.nextNode then
		task.delay(startNode.autoAdvance, function()
			if activeConversations[player] and activeConversations[player].currentNodeId == startNodeId then
				self:advanceToNode(player, startNode.nextNode)
			end
		end)
	end

	return true
end

function DialogueService:selectResponse(player: Player, responseIndex: number): boolean
	loadDependencies()

	local conversation = activeConversations[player]
	if not conversation then
		return false
	end

	local node = DialogueDefinitions.getNode(conversation.npcId, conversation.currentNodeId)
	if not node then
		self:endConversation(player)
		return false
	end

	local filteredResponses = getFilteredResponses(player, node.responses)

	if responseIndex < 1 or responseIndex > #filteredResponses then
		return false
	end

	local selectedResponse = filteredResponses[responseIndex]

	-- Apply effects
	applyAllEffects(player, selectedResponse.effects)

	-- Advance to next node or end
	if selectedResponse.nextNode then
		self:advanceToNode(player, selectedResponse.nextNode)
	else
		self:endConversation(player)
	end

	return true
end

function DialogueService:advanceToNode(player: Player, nodeId: string)
	loadDependencies()

	local conversation = activeConversations[player]
	if not conversation then
		return
	end

	local tree = DialogueDefinitions.getForNPC(conversation.npcId)
	if not tree then
		self:endConversation(player)
		return
	end

	local node = DialogueDefinitions.getNode(conversation.npcId, nodeId)
	if not node then
		self:endConversation(player)
		return
	end

	-- Update current node
	conversation.currentNodeId = nodeId

	-- Get filtered responses
	local filteredResponses = getFilteredResponses(player, node.responses)

	-- Send to client
	sendDialogueToClient(player, tree.npcName, node, filteredResponses)

	-- Handle auto-advance
	if node.autoAdvance and node.nextNode then
		task.delay(node.autoAdvance, function()
			if activeConversations[player] and activeConversations[player].currentNodeId == nodeId then
				self:advanceToNode(player, node.nextNode)
			end
		end)
	end
end

function DialogueService:endConversation(player: Player)
	loadDependencies()

	local conversation = activeConversations[player]
	if not conversation then
		return
	end

	activeConversations[player] = nil

	-- Notify client conversation ended
	Network.Events.InteractComplete:FireClient(player, {
		type = "dialogue_end",
	})

	print(string.format("[DialogueService] %s ended conversation", player.Name))
end

function DialogueService:isInConversation(player: Player): boolean
	return activeConversations[player] ~= nil
end

function DialogueService:getCurrentConversation(player: Player): ActiveConversation?
	return activeConversations[player]
end

--------------------------------------------------------------------------------
-- NPC TALK INTEGRATION
--------------------------------------------------------------------------------

-- Called when player initiates talk with an NPC
function DialogueService:onTalk(player: Player, npcId: string): { success: boolean, message: string? }
	local started = self:startConversation(player, npcId)

	if started then
		return { success = true }
	else
		-- Check if NPC has no dialogue
		local tree = DialogueDefinitions.getForNPC(npcId)
		if not tree then
			return { success = false, message = "This character has nothing to say." }
		end

		return { success = false, message = "Cannot start conversation." }
	end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function DialogueService:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()
	loadOptionalDependencies()

	-- Handle dialogue response from client (could be a new network event)
	-- For now, reuse Interact for dialogue responses
	-- This could be extended with a dedicated DialogueResponse event

	-- Cleanup on player leave
	Players.PlayerRemoving:Connect(function(player)
		activeConversations[player] = nil
	end)

	local npcCount = #DialogueDefinitions.getNPCList()
	print("[DialogueService] Initialized with dialogue for", npcCount, "NPCs")
end

-- Get available dialogue NPCs
function DialogueService:getDialogueNPCs(): { string }
	loadDependencies()
	return DialogueDefinitions.getNPCList()
end

function DialogueService:getDefinitions()
	loadDependencies()
	return DialogueDefinitions
end

return DialogueService
