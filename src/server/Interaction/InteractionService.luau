--!strict
--[[
    InteractionService

    Handles player interactions with world objects, NPCs, and items.
    Validates proximity, permissions, and executes interaction effects.

    Usage:
        local InteractionService = require(script.InteractionService)
        InteractionService:init()
        InteractionService:registerInteractable(object, config)
]]

local InteractionService = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Dependencies (lazy loaded)
local Network
local InventoryService
local PlayerDataService
local EcologyService
local DialogueService

-- Configuration
local CONFIG = {
	DEFAULT_RANGE = 10, -- studs
	COOLDOWN_DEFAULT = 1, -- seconds
	TAG_INTERACTABLE = "Interactable",
}

-- Types
export type InteractionType = "pickup" | "harvest" | "observe" | "talk" | "use" | "examine"

export type InteractableConfig = {
	id: string,
	interactionType: InteractionType,
	displayName: string,
	prompt: string?, -- e.g., "Press E to pick up"
	range: number?,
	cooldown: number?,
	onInteract: ((player: Player, target: Instance) -> { success: boolean, message: string? })?,
	-- For pickup interactions
	itemId: string?,
	quantity: number?,
	-- For harvest interactions
	harvestTime: number?,
	respawnTime: number?,
}

-- State
local interactables: { [Instance]: InteractableConfig } = {}
local cooldowns: { [Player]: { [string]: number } } = {}
local initialized = false

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not Network then
		Network = require(ReplicatedStorage.Shared.Network)
	end
end

local function isOnCooldown(player: Player, interactableId: string): boolean
	if not cooldowns[player] then
		return false
	end
	local lastUse = cooldowns[player][interactableId]
	if not lastUse then
		return false
	end

	local config = nil
	for _, cfg in interactables do
		if cfg.id == interactableId then
			config = cfg
			break
		end
	end

	local cooldownTime = if config then (config.cooldown or CONFIG.COOLDOWN_DEFAULT) else CONFIG.COOLDOWN_DEFAULT
	return (os.clock() - lastUse) < cooldownTime
end

local function setCooldown(player: Player, interactableId: string)
	if not cooldowns[player] then
		cooldowns[player] = {}
	end
	cooldowns[player][interactableId] = os.clock()
end

local function getDistance(player: Player, target: Instance): number?
	local character = player.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return nil
	end

	local targetPart: BasePart?
	if target:IsA("BasePart") then
		targetPart = target
	elseif target:IsA("Model") then
		targetPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
	end

	if not targetPart then
		return nil
	end

	return (rootPart.Position - targetPart.Position).Magnitude
end

--------------------------------------------------------------------------------
-- INTERACTION HANDLERS
--------------------------------------------------------------------------------

local function handlePickup(player: Player, target: Instance, config: InteractableConfig): { success: boolean, message: string? }
	if not config.itemId then
		return { success = false, message = "Invalid pickup configuration" }
	end

	local quantity = config.quantity or 1
	local success = InventoryService:addItem(player, config.itemId, quantity)

	if success then
		-- Get pickup position before destroying
		local pickupPosition = Vector3.zero
		if target:IsA("BasePart") then
			pickupPosition = target.Position
		elseif target:IsA("Model") then
			local primaryPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
			if primaryPart then
				pickupPosition = primaryPart.Position
			end
		end

		-- Get item definition to find pickup category
		local ItemDefinitions = require(ReplicatedStorage.Shared.Items.ItemDefinitions)
		local itemDef = ItemDefinitions.get(config.itemId)
		local pickupCategory = "organic" -- default
		if itemDef and itemDef.pickupCategory then
			pickupCategory = itemDef.pickupCategory
		end

		-- Fire pickup effect event to client (BEFORE destroying the model)
		-- This allows the client to play the scale/fade animation on the model
		loadDependencies()
		Network.Events.PickupEffect:FireClient(player, {
			itemId = config.itemId,
			pickupCategory = pickupCategory,
			position = pickupPosition,
			targetId = config.id, -- Pass the interactable ID so client can find the model
		})

		-- Delay destruction slightly to allow client to start animation
		-- The client will handle the actual visual destruction via tween
		task.delay(0.05, function()
			if target and target.Parent then
				-- Make invisible immediately (client handles animation)
				if target:IsA("BasePart") then
					target.CanCollide = false
					target.Transparency = 1
				elseif target:IsA("Model") then
					for _, desc in target:GetDescendants() do
						if desc:IsA("BasePart") then
							desc.CanCollide = false
							desc.Transparency = 1
						end
					end
				end
			end
		end)

		-- Fully destroy after animation would complete
		task.delay(0.4, function()
			if target and target.Parent then
				target:Destroy()
			end
		end)

		InteractionService:unregisterInteractable(target)

		return { success = true, message = string.format("Picked up %s", config.displayName) }
	else
		return { success = false, message = "Inventory full" }
	end
end

local function handleHarvest(player: Player, target: Instance, config: InteractableConfig): { success: boolean, message: string? }
	if not config.itemId then
		return { success = false, message = "Invalid harvest configuration" }
	end

	local quantity = config.quantity or 1
	local success = InventoryService:addItem(player, config.itemId, quantity)

	if success then
		-- Get harvest position for effects
		local harvestPosition = Vector3.zero
		if target:IsA("BasePart") then
			harvestPosition = target.Position
		elseif target:IsA("Model") then
			local primaryPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
			if primaryPart then
				harvestPosition = primaryPart.Position
			end
		end

		-- Get item definition to find pickup category
		local ItemDefinitions = require(ReplicatedStorage.Shared.Items.ItemDefinitions)
		local itemDef = ItemDefinitions.get(config.itemId)
		local pickupCategory = "organic" -- default for harvested items
		if itemDef and itemDef.pickupCategory then
			pickupCategory = itemDef.pickupCategory
		end

		-- Fire pickup effect event to client (for audio/particles)
		loadDependencies()
		Network.Events.PickupEffect:FireClient(player, {
			itemId = config.itemId,
			pickupCategory = pickupCategory,
			position = harvestPosition,
			targetId = config.id,
		})

		-- Hide temporarily for respawn
		if target:IsA("Model") or target:IsA("BasePart") then
			local respawnTime = config.respawnTime or 60

			-- Visual feedback - make transparent or hide
			for _, desc in target:GetDescendants() do
				if desc:IsA("BasePart") then
					desc.Transparency = 1
					desc.CanCollide = false
				end
			end
			if target:IsA("BasePart") then
				target.Transparency = 1
				target.CanCollide = false
			end

			-- Respawn after delay
			task.delay(respawnTime, function()
				if target.Parent then
					for _, desc in target:GetDescendants() do
						if desc:IsA("BasePart") then
							desc.Transparency = 0
							desc.CanCollide = true
						end
					end
					if target:IsA("BasePart") then
						target.Transparency = 0
						target.CanCollide = true
					end
				end
			end)
		end

		return { success = true, message = string.format("Harvested %s", config.displayName) }
	else
		return { success = false, message = "Inventory full" }
	end
end

local function handleObserve(player: Player, target: Instance, config: InteractableConfig): { success: boolean, message: string? }
	-- Add to discoveries
	local category = "species"
	local discoveryId = config.id

	local isNew = PlayerDataService:addDiscovery(player, category, discoveryId, "Observed")

	if isNew then
		-- Notify client of new discovery
		loadDependencies()
		Network.Events.Discovery:FireClient(player, {
			category = category,
			id = discoveryId,
			name = config.displayName,
			description = "Observed in the wild.",
		})

		return { success = true, message = string.format("Discovered: %s!", config.displayName) }
	else
		return { success = true, message = string.format("Observed: %s", config.displayName) }
	end
end

local function handleExamine(player: Player, target: Instance, config: InteractableConfig): { success: boolean, message: string? }
	-- Send description to client
	loadDependencies()
	Network.Events.Discovery:FireClient(player, {
		category = "examine",
		id = config.id,
		name = config.displayName,
		description = config.prompt or "You examine the object closely.",
	})

	return { success = true, message = nil }
end

--------------------------------------------------------------------------------
-- CORE INTERACTION
--------------------------------------------------------------------------------

function InteractionService:interact(player: Player, targetId: string): { success: boolean, message: string? }
	loadDependencies()

	-- Find target by ID
	local target: Instance? = nil
	local config: InteractableConfig? = nil

	for obj, cfg in interactables do
		if cfg.id == targetId then
			target = obj
			config = cfg
			break
		end
	end

	if not target or not config then
		return { success = false, message = "Object not found" }
	end

	-- Check cooldown
	if isOnCooldown(player, config.id) then
		return { success = false, message = "Please wait..." }
	end

	-- Check range
	local distance = getDistance(player, target)
	local maxRange = config.range or CONFIG.DEFAULT_RANGE

	if not distance or distance > maxRange then
		return { success = false, message = "Too far away" }
	end

	-- Set cooldown
	setCooldown(player, config.id)

	-- Handle custom interaction
	if config.onInteract then
		return config.onInteract(player, target)
	end

	-- Handle built-in interaction types
	local interactionType = config.interactionType

	if interactionType == "pickup" then
		return handlePickup(player, target, config)
	elseif interactionType == "harvest" then
		return handleHarvest(player, target, config)
	elseif interactionType == "observe" then
		return handleObserve(player, target, config)
	elseif interactionType == "examine" then
		return handleExamine(player, target, config)
	elseif interactionType == "talk" then
		-- Use dialogue system
		if not DialogueService then
			pcall(function()
				DialogueService = require(script.Parent.Parent.Dialogue.DialogueService)
			end)
		end

		if DialogueService then
			local npcId = config.id -- Use the interaction ID as NPC ID
			return DialogueService:onTalk(player, npcId)
		else
			return { success = false, message = config.displayName .. " has nothing to say." }
		end
	elseif interactionType == "use" then
		-- Generic use - requires custom handler
		return { success = false, message = "Cannot use this" }
	end

	return { success = false, message = "Unknown interaction type" }
end

--------------------------------------------------------------------------------
-- REGISTRATION
--------------------------------------------------------------------------------

function InteractionService:registerInteractable(target: Instance, config: InteractableConfig)
	interactables[target] = config

	-- Tag for client proximity detection
	CollectionService:AddTag(target, CONFIG.TAG_INTERACTABLE)

	-- Store config data as attributes for client
	if target:IsA("BasePart") or target:IsA("Model") then
		target:SetAttribute("InteractableId", config.id)
		target:SetAttribute("InteractableType", config.interactionType)
		target:SetAttribute("InteractableName", config.displayName)
		target:SetAttribute("InteractablePrompt", config.prompt or ("Interact with " .. config.displayName))
		target:SetAttribute("InteractableRange", config.range or CONFIG.DEFAULT_RANGE)
	end
end

function InteractionService:unregisterInteractable(target: Instance)
	interactables[target] = nil
	CollectionService:RemoveTag(target, CONFIG.TAG_INTERACTABLE)
end

function InteractionService:getInteractables(): { [Instance]: InteractableConfig }
	return interactables
end

function InteractionService:getInteractableConfig(target: Instance): InteractableConfig?
	return interactables[target]
end

function InteractionService:getNearbyInteractables(player: Player, maxRange: number?): { { target: Instance, config: InteractableConfig, distance: number } }
	maxRange = maxRange or 50
	local results = {}

	for target, config in interactables do
		local distance = getDistance(player, target)
		if distance and distance <= maxRange then
			table.insert(results, {
				target = target,
				config = config,
				distance = distance,
			})
		end
	end

	-- Sort by distance
	table.sort(results, function(a, b)
		return a.distance < b.distance
	end)

	return results
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function InteractionService:init()
	if initialized then
		return
	end
	initialized = true

	-- Load dependencies
	loadDependencies()
	InventoryService = require(script.Parent.Parent.Inventory.InventoryService)
	PlayerDataService = require(script.Parent.Parent.Data.PlayerDataService)

	pcall(function()
		EcologyService = require(script.Parent.Parent.Ecology.EcologyService)
	end)

	-- Clean up cooldowns when players leave
	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)

	-- Handle interaction requests
	Network.Functions.Interact.OnServerInvoke = function(player: Player, data: any)
		if type(data) ~= "table" or type(data.targetId) ~= "string" then
			return { success = false, error = "Invalid request" }
		end

		local result = self:interact(player, data.targetId)
		return {
			success = result.success,
			data = { message = result.message },
			error = if not result.success then result.message else nil,
		}
	end

	print("[InteractionService] Initialized")
end

return InteractionService
