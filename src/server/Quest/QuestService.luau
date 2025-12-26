--!strict
--[[
    QuestService

    Manages player quests: acceptance, progress tracking, and completion.
    Integrates with DiscoveryService and InventoryService.

    Usage:
        local QuestService = require(script.Parent.QuestService)
        QuestService:init()

        -- Give a quest
        QuestService:acceptQuest(player, "tutorial_first_steps")

        -- Check progress
        local progress = QuestService:getQuestProgress(player, "tutorial_first_steps")
]]

local QuestService = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies (lazy loaded)
local QuestDefinitions
local PlayerDataService
local DiscoveryService
local InventoryService
local Network

-- State
local initialized = false
local questConnections: { RBXScriptConnection } = {}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not QuestDefinitions then
		QuestDefinitions = require(script.Parent.QuestDefinitions)
	end
	if not PlayerDataService then
		PlayerDataService = require(script.Parent.Parent.Data.PlayerDataService)
	end
	if not Network then
		Network = require(ReplicatedStorage.Shared.Network)
	end
end

local function loadOptionalDependencies()
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

local function syncQuestToClient(player: Player, questId: string, progress: any?)
	loadDependencies()

	local definition = QuestDefinitions.get(questId)
	if not definition then
		return
	end

	Network.Events.QuestUpdate:FireClient(player, {
		action = if progress then "update" else "new",
		questId = questId,
		name = definition.name,
		description = definition.description,
		objectives = definition.objectives,
		progress = progress,
	})
end

--------------------------------------------------------------------------------
-- PREREQUISITES
--------------------------------------------------------------------------------

function QuestService:canAcceptQuest(player: Player, questId: string): (boolean, string?)
	loadDependencies()
	loadOptionalDependencies()

	local definition = QuestDefinitions.get(questId)
	if not definition then
		return false, "Quest not found"
	end

	local data = PlayerDataService:getData(player)
	if not data then
		return false, "Player data not loaded"
	end

	-- Check if already active
	if data.quests.active[questId] then
		return false, "Quest already active"
	end

	-- Check if already completed (and not repeatable)
	if data.quests.completed[questId] and not definition.isRepeatable then
		return false, "Quest already completed"
	end

	-- Check prerequisite quests
	if definition.prerequisiteQuests then
		for _, prereqId in definition.prerequisiteQuests do
			if not data.quests.completed[prereqId] then
				local prereq = QuestDefinitions.get(prereqId)
				local prereqName = if prereq then prereq.name else prereqId
				return false, "Requires: " .. prereqName
			end
		end
	end

	-- Check prerequisite discoveries
	if definition.prerequisiteDiscoveries and DiscoveryService then
		for _, discoveryId in definition.prerequisiteDiscoveries do
			if not DiscoveryService:hasDiscovered(player, discoveryId) then
				return false, "Discovery required"
			end
		end
	end

	return true, nil
end

--------------------------------------------------------------------------------
-- QUEST MANAGEMENT
--------------------------------------------------------------------------------

function QuestService:acceptQuest(player: Player, questId: string): (boolean, string?)
	loadDependencies()

	local canAccept, reason = self:canAcceptQuest(player, questId)
	if not canAccept then
		return false, reason
	end

	local definition = QuestDefinitions.get(questId)
	if not definition then
		return false, "Quest not found"
	end

	local data = PlayerDataService:getData(player)
	if not data then
		return false, "Player data not loaded"
	end

	-- Initialize quest progress
	local objectives: { [string]: number } = {}
	for _, obj in definition.objectives do
		objectives[obj.id] = 0
	end

	data.quests.active[questId] = {
		questId = questId,
		startedAt = os.time(),
		objectives = objectives,
		completed = false,
	}

	-- Sync to client
	syncQuestToClient(player, questId, data.quests.active[questId])

	print(string.format("[QuestService] %s accepted quest: %s", player.Name, definition.name))

	return true, nil
end

function QuestService:abandonQuest(player: Player, questId: string): boolean
	loadDependencies()

	local data = PlayerDataService:getData(player)
	if not data then
		return false
	end

	if not data.quests.active[questId] then
		return false
	end

	data.quests.active[questId] = nil

	Network.Events.QuestUpdate:FireClient(player, {
		action = "abandon",
		questId = questId,
	})

	return true
end

function QuestService:updateObjective(player: Player, questId: string, objectiveId: string, amount: number?): boolean
	loadDependencies()

	amount = amount or 1

	local data = PlayerDataService:getData(player)
	if not data then
		return false
	end

	local questProgress = data.quests.active[questId]
	if not questProgress then
		return false
	end

	local definition = QuestDefinitions.get(questId)
	if not definition then
		return false
	end

	-- Find objective definition
	local objDef = nil
	for _, obj in definition.objectives do
		if obj.id == objectiveId then
			objDef = obj
			break
		end
	end

	if not objDef then
		return false
	end

	-- Update progress
	local currentProgress = questProgress.objectives[objectiveId] or 0
	local newProgress = math.min(currentProgress + amount, objDef.count)
	questProgress.objectives[objectiveId] = newProgress

	-- Sync to client
	syncQuestToClient(player, questId, questProgress)

	-- Check if all objectives complete
	self:checkQuestCompletion(player, questId)

	return true
end

function QuestService:checkQuestCompletion(player: Player, questId: string): boolean
	loadDependencies()
	loadOptionalDependencies()

	local data = PlayerDataService:getData(player)
	if not data then
		return false
	end

	local questProgress = data.quests.active[questId]
	if not questProgress or questProgress.completed then
		return false
	end

	local definition = QuestDefinitions.get(questId)
	if not definition then
		return false
	end

	-- Check all objectives
	for _, obj in definition.objectives do
		local progress = questProgress.objectives[obj.id] or 0
		if progress < obj.count then
			return false -- Not complete
		end
	end

	-- Quest complete!
	return self:completeQuest(player, questId)
end

function QuestService:completeQuest(player: Player, questId: string): boolean
	loadDependencies()
	loadOptionalDependencies()

	local data = PlayerDataService:getData(player)
	if not data then
		return false
	end

	local questProgress = data.quests.active[questId]
	if not questProgress then
		return false
	end

	local definition = QuestDefinitions.get(questId)
	if not definition then
		return false
	end

	-- Move from active to completed
	data.quests.active[questId] = nil
	data.quests.completed[questId] = os.time()

	-- Grant rewards
	for _, reward in definition.rewards do
		if reward.type == "item" and reward.id and InventoryService then
			InventoryService:addItem(player, reward.id, reward.amount or 1)
		elseif reward.type == "currency" and reward.amount then
			data.inventory.currency = data.inventory.currency + reward.amount
		elseif reward.type == "discovery" and reward.id and DiscoveryService then
			DiscoveryService:discover(player, reward.id)
		end
	end

	-- Notify client
	Network.Events.QuestUpdate:FireClient(player, {
		action = "complete",
		questId = questId,
		name = definition.name,
		rewards = definition.rewards,
	})

	print(string.format("[QuestService] %s completed quest: %s", player.Name, definition.name))

	return true
end

--------------------------------------------------------------------------------
-- PROGRESS TRACKING HOOKS
--------------------------------------------------------------------------------

local function onDiscovery(player: Player, discoveryId: string, definition: any)
	local data = PlayerDataService:getData(player)
	if not data then
		return
	end

	-- Check all active quests for discovery objectives
	for questId, questProgress in data.quests.active do
		local questDef = QuestDefinitions.get(questId)
		if not questDef then
			continue
		end

		for _, obj in questDef.objectives do
			if obj.type == "discover" then
				-- Check if this discovery matches
				if obj.targetId == discoveryId or obj.targetId == "any_species" then
					QuestService:updateObjective(player, questId, obj.id, 1)
				end
			elseif obj.type == "reach_location" then
				-- Location discoveries
				if obj.targetId == discoveryId then
					QuestService:updateObjective(player, questId, obj.id, 1)
				end
			end
		end
	end
end

local function onItemCollected(player: Player, itemId: string, quantity: number)
	local data = PlayerDataService:getData(player)
	if not data then
		return
	end

	-- Check all active quests for collect objectives
	for questId, questProgress in data.quests.active do
		local questDef = QuestDefinitions.get(questId)
		if not questDef then
			continue
		end

		for _, obj in questDef.objectives do
			if obj.type == "collect" and obj.targetId == itemId then
				QuestService:updateObjective(player, questId, obj.id, quantity)
			end
		end
	end
end

local function onObserve(player: Player, speciesId: string)
	local data = PlayerDataService:getData(player)
	if not data then
		return
	end

	-- Check all active quests for observe objectives
	for questId, questProgress in data.quests.active do
		local questDef = QuestDefinitions.get(questId)
		if not questDef then
			continue
		end

		for _, obj in questDef.objectives do
			if obj.type == "observe" and obj.targetId == speciesId then
				QuestService:updateObjective(player, questId, obj.id, 1)
			end
		end
	end
end

--------------------------------------------------------------------------------
-- QUERY FUNCTIONS
--------------------------------------------------------------------------------

function QuestService:getActiveQuests(player: Player): { string }
	loadDependencies()

	local data = PlayerDataService:getData(player)
	if not data then
		return {}
	end

	local quests = {}
	for questId in data.quests.active do
		table.insert(quests, questId)
	end

	return quests
end

function QuestService:getCompletedQuests(player: Player): { string }
	loadDependencies()

	local data = PlayerDataService:getData(player)
	if not data then
		return {}
	end

	local quests = {}
	for questId in data.quests.completed do
		table.insert(quests, questId)
	end

	return quests
end

function QuestService:getQuestProgress(player: Player, questId: string): any?
	loadDependencies()

	local data = PlayerDataService:getData(player)
	if not data then
		return nil
	end

	return data.quests.active[questId]
end

function QuestService:getAvailableQuests(player: Player): { QuestDefinitions.QuestDefinition }
	loadDependencies()

	local available = {}

	for _, def in QuestDefinitions.getAll() do
		local canAccept, _ = self:canAcceptQuest(player, def.id)
		if canAccept then
			table.insert(available, def)
		end
	end

	return available
end

function QuestService:getQuestsFromNPC(player: Player, npcId: string): { { definition: any, canAccept: boolean, reason: string? } }
	loadDependencies()

	local quests = {}

	for _, def in QuestDefinitions.getByQuestGiver(npcId) do
		local canAccept, reason = self:canAcceptQuest(player, def.id)
		table.insert(quests, {
			definition = def,
			canAccept = canAccept,
			reason = reason,
		})
	end

	return quests
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function QuestService:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()
	loadOptionalDependencies()

	-- Listen for discoveries
	if DiscoveryService then
		local conn = DiscoveryService:onDiscoveryMade():Connect(onDiscovery)
		table.insert(questConnections, conn)
	end

	-- Handle quest accept requests from client
	Network.Events.AcceptQuest.OnServerEvent:Connect(function(player: Player, data: any)
		if type(data) ~= "table" or type(data.questId) ~= "string" then
			return
		end

		local success, reason = self:acceptQuest(player, data.questId)
		if not success then
			-- Optionally notify client of failure
			print(string.format("[QuestService] %s failed to accept %s: %s", player.Name, data.questId, reason or "unknown"))
		end
	end)

	-- Handle quest complete requests (for quests that need manual turn-in)
	Network.Events.CompleteQuest.OnServerEvent:Connect(function(player: Player, data: any)
		if type(data) ~= "table" or type(data.questId) ~= "string" then
			return
		end

		self:checkQuestCompletion(player, data.questId)
	end)

	-- Cleanup on player leave
	Players.PlayerRemoving:Connect(function(player)
		-- Any cleanup needed
	end)

	print("[QuestService] Initialized with", QuestDefinitions.getTotalCount(), "quests")
end

-- Expose for external item collection tracking
function QuestService:onItemCollected(player: Player, itemId: string, quantity: number)
	onItemCollected(player, itemId, quantity)
end

-- Expose for external observation tracking
function QuestService:onObserve(player: Player, speciesId: string)
	onObserve(player, speciesId)
end

function QuestService:getDefinitions()
	loadDependencies()
	return QuestDefinitions
end

return QuestService
