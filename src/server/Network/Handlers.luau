--!strict
--[[
    Network Handlers

    Server-side event handlers for all network events.
    All handlers validate input, check rate limits, and process requests.

    Usage:
        local Handlers = require(script.Parent.Handlers)
        Handlers:init()
]]

local Handlers = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies (loaded after init to avoid circular requires)
local Network: any
local PlayerDataService: any
local EcologyService: any
local InventoryService: any
local DialogueService: any
local RateLimiter: any
local Validators: any

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

local function wrapHandler(eventName: string, handler: (player: Player, data: any) -> any?)
	return function(player: Player, data: any)
		-- Rate limit check
		if not RateLimiter:check(player, eventName) then
			return { success = false, error = "Rate limited" }
		end

		-- Call actual handler
		local success, result = pcall(handler, player, data)

		if not success then
			warn(string.format("[Handlers] Error in %s: %s", eventName, result))
			return { success = false, error = "Internal error" }
		end

		return result
	end
end

--------------------------------------------------------------------------------
-- INVENTORY HANDLERS
--------------------------------------------------------------------------------

local function handleUseItem(player: Player, data: any)
	local isValid, cleanData = Validators.validateUseItem(data)
	if not isValid or not cleanData then
		return { success = false, error = "Invalid request" }
	end

	-- Use InventoryService for item usage
	local result = InventoryService:useItem(player, cleanData.itemId, cleanData.targetId)

	if result.success then
		print(string.format("[Handlers] %s used item: %s", player.Name, cleanData.itemId))
	else
		-- Send feedback to client about why item couldn't be used
		Network.Events.InventoryUpdate:FireClient(player, {
			useItemFailed = true,
			message = result.message or "Cannot use this item",
		})
	end

	return {
		success = result.success,
		data = {
			consumed = result.success,
			message = result.message,
		},
		error = if not result.success then result.message else nil,
	}
end

local function handleDropItem(player: Player, data: any)
	local isValid, cleanData = Validators.validateDropItem(data)
	if not isValid or not cleanData then
		return
	end

	local dropped = InventoryService:dropItem(player, cleanData.itemId, cleanData.quantity)
	if dropped then
		print(string.format("[Handlers] %s dropped %dx %s", player.Name, cleanData.quantity, cleanData.itemId))
	end
end

local function handlePickupItem(player: Player, data: any)
	local isValid, cleanData = Validators.validatePickupItem(data)
	if not isValid or not cleanData then
		return
	end

	-- Use InventoryService for pickup
	local success = InventoryService:pickupItem(player, cleanData.objectId)
	if success then
		print(string.format("[Handlers] %s picked up: %s", player.Name, cleanData.objectId))
	end
end

--------------------------------------------------------------------------------
-- INTERACTION HANDLERS
--------------------------------------------------------------------------------

local function handleInteract(player: Player, data: any)
	local isValid, cleanData = Validators.validateInteract(data)
	if not isValid or not cleanData then
		return { success = false, error = "Invalid request" }
	end

	local interactionType = cleanData.interactionType

	-- Handle dialogue response
	if interactionType == "dialogue_response" then
		if not DialogueService then
			return { success = false, error = "DialogueService not available" }
		end

		local responseIndex = cleanData.responseIndex
		if type(responseIndex) ~= "number" then
			return { success = false, error = "Invalid response index" }
		end

		local success = DialogueService:selectResponse(player, responseIndex)
		return {
			success = success,
			data = { dialogueAdvanced = success },
		}
	end

	-- Handle dialogue close
	if interactionType == "dialogue_close" then
		if DialogueService then
			DialogueService:endConversation(player)
		end
		return { success = true }
	end

	-- Default interaction handling
	print(string.format("[Handlers] %s interacted with %s (%s)", player.Name, cleanData.targetId or "unknown", interactionType))

	return {
		success = true,
		data = {
			interactionId = (cleanData.targetId or "interact") .. "_" .. os.time(),
			dialogueData = nil,
		},
	}
end

--------------------------------------------------------------------------------
-- QUEST HANDLERS
--------------------------------------------------------------------------------

local function handleAcceptQuest(player: Player, data: any)
	local isValid, cleanData = Validators.validateAcceptQuest(data)
	if not isValid or not cleanData then
		return
	end

	local playerData = PlayerDataService:getData(player)
	if not playerData then
		return
	end

	-- Check if already active or completed
	if playerData.quests.active[cleanData.questId] then
		return -- Already accepted
	end

	if playerData.quests.completed[cleanData.questId] then
		return -- Already completed (unless repeatable)
	end

	-- Add to active quests
	playerData.quests.active[cleanData.questId] = {
		questId = cleanData.questId,
		startedAt = os.time(),
		objectives = {},
		completed = false,
	}

	print(string.format("[Handlers] %s accepted quest: %s", player.Name, cleanData.questId))

	-- Notify client
	Network.Events.QuestUpdate:FireClient(player, {
		questId = cleanData.questId,
		objectiveId = "",
		progress = 0,
		completed = false,
	})
end

local function handleCompleteQuest(player: Player, data: any)
	local isValid, cleanData = Validators.validateCompleteQuest(data)
	if not isValid or not cleanData then
		return
	end

	local playerData = PlayerDataService:getData(player)
	if not playerData then
		return
	end

	local quest = playerData.quests.active[cleanData.questId]
	if not quest then
		return -- Quest not active
	end

	-- TODO: Verify all objectives are complete

	-- Move to completed
	playerData.quests.completed[cleanData.questId] = os.time()
	playerData.quests.active[cleanData.questId] = nil

	print(string.format("[Handlers] %s completed quest: %s", player.Name, cleanData.questId))

	-- TODO: Grant rewards
end

--------------------------------------------------------------------------------
-- ECOLOGY HANDLERS
--------------------------------------------------------------------------------

local function handleEcoAction(player: Player, data: any)
	local isValid, cleanData = Validators.validateEcoAction(data)
	if not isValid or not cleanData then
		return { success = false, error = "Invalid request" }
	end

	-- Find region at player position
	local character = player.Character
	if not character then
		return { success = false, error = "No character" }
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return { success = false, error = "No character" }
	end

	local position = cleanData.position or rootPart.Position
	local region = EcologyService:getRegionAtPosition(position)

	if not region then
		return { success = false, error = "Not in an ecological region" }
	end

	-- Apply action through EcologyService
	local result = EcologyService:applyPlayerAction(
		player,
		region.id,
		cleanData.actionType,
		cleanData.targetId
	)

	-- Track in player data
	local placeId = tostring(game.PlaceId)
	local positive = cleanData.actionType ~= "remove"
	PlayerDataService:recordEcoAction(player, placeId, positive, cleanData.targetId)

	print(string.format("[Handlers] %s performed eco action: %s in %s", player.Name, cleanData.actionType, region.name))

	return {
		success = result.success,
		data = {
			impactPositive = positive,
			message = result.message,
		},
	}
end

--------------------------------------------------------------------------------
-- SETTINGS HANDLERS
--------------------------------------------------------------------------------

local function handleUpdateSettings(player: Player, data: any)
	local isValid, cleanData = Validators.validateUpdateSettings(data)
	if not isValid or not cleanData then
		return
	end

	local playerData = PlayerDataService:getData(player)
	if not playerData then
		return
	end

	-- Update settings
	if cleanData.musicVolume ~= nil then
		playerData.settings.musicVolume = cleanData.musicVolume
	end
	if cleanData.sfxVolume ~= nil then
		playerData.settings.sfxVolume = cleanData.sfxVolume
	end
	if cleanData.showTutorials ~= nil then
		playerData.settings.showTutorials = cleanData.showTutorials
	end

	print(string.format("[Handlers] %s updated settings", player.Name))
end

--------------------------------------------------------------------------------
-- TELEPORT HANDLERS
--------------------------------------------------------------------------------

local function handleRequestTeleport(player: Player, data: any)
	local isValid, cleanData = Validators.validateTeleportRequest(data)
	if not isValid or not cleanData then
		return
	end

	-- TODO: Use TeleportService to teleport player
	-- TODO: Handle group teleports
	print(string.format("[Handlers] %s requested teleport to: %s", player.Name, cleanData.destination))

	-- Notify client of pending teleport
	Network.Events.TeleportReady:FireClient(player, {
		destination = cleanData.destination,
		countdown = 3,
	})
end

--------------------------------------------------------------------------------
-- PLAYER DATA SYNC
--------------------------------------------------------------------------------

local function sendPlayerStats(player: Player)
	local data = PlayerDataService:getData(player)
	if not data then
		return
	end

	Network.Events.StatUpdate:FireClient(player, {
		hunger = data.stats.hunger,
		thirst = data.stats.thirst,
	})
end

local function sendPlayerInventory(player: Player)
	local data = PlayerDataService:getData(player)
	if not data then
		return
	end

	Network.Events.InventoryUpdate:FireClient(player, data.inventory.items)
end

local function onPlayerReady(player: Player)
	-- Wait for player data to load
	local data = PlayerDataService:waitForData(player, 10)
	if not data then
		warn("[Handlers] Could not load data for", player.Name)
		return
	end

	-- Send initial stats and inventory
	sendPlayerStats(player)
	sendPlayerInventory(player)
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function Handlers:init()
	-- Load dependencies
	Network = require(ReplicatedStorage.Shared.Network)
	PlayerDataService = require(script.Parent.Parent.Data.PlayerDataService)
	EcologyService = require(script.Parent.Parent.Ecology.EcologyService)
	InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
	RateLimiter = require(script.Parent.RateLimiter)
	Validators = require(script.Parent.Validators)

	-- Load DialogueService (optional, may not exist in all places)
	pcall(function()
		DialogueService = require(script.Parent.Parent.Dialogue.DialogueService)
	end)

	-- Initialize InventoryService
	InventoryService:init()

	-- Initialize network (creates remotes)
	Network.init()

	-- Send initial data to existing players
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerReady, player)
	end

	-- Send initial data to new players
	Players.PlayerAdded:Connect(function(player)
		task.spawn(onPlayerReady, player)
	end)

	-- Connect event handlers
	Network.Events.UseItem.OnServerEvent:Connect(wrapHandler("UseItem", handleUseItem))
	Network.Events.DropItem.OnServerEvent:Connect(wrapHandler("DropItem", handleDropItem))
	Network.Events.PickupItem.OnServerEvent:Connect(wrapHandler("PickupItem", handlePickupItem))

	Network.Events.AcceptQuest.OnServerEvent:Connect(wrapHandler("AcceptQuest", handleAcceptQuest))
	Network.Events.CompleteQuest.OnServerEvent:Connect(wrapHandler("CompleteQuest", handleCompleteQuest))

	Network.Events.UpdateSettings.OnServerEvent:Connect(wrapHandler("UpdateSettings", handleUpdateSettings))

	Network.Events.RequestTeleport.OnServerEvent:Connect(wrapHandler("RequestTeleport", handleRequestTeleport))

	-- RemoteFunctions (return values)
	Network.Functions.Interact.OnServerInvoke = wrapHandler("Interact", handleInteract)
	Network.Functions.EcoAction.OnServerInvoke = wrapHandler("EcoAction", handleEcoAction)

	print("[Handlers] Network handlers initialized")
end

return Handlers
