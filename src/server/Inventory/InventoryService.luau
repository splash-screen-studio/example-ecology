--!strict
--[[
    InventoryService

    Server-side inventory management.
    Works with PlayerDataService for persistence.

    Usage:
        local InventoryService = require(script.Parent.InventoryService)

        InventoryService:addItem(player, "apple", 5)
        InventoryService:removeItem(player, "apple", 2)
        InventoryService:useItem(player, "apple")
]]

local InventoryService = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Dependencies (loaded after init)
local ItemDefinitions: any
local PlayerDataService: any
local EcologyService: any
local Network: any
local QuestService: any

-- Configuration
local CONFIG = {
	DEFAULT_MAX_SLOTS = 20,
	COOLDOWN_TOLERANCE = 0.1, -- Seconds of buffer for cooldowns
}

-- Track item cooldowns per player
local cooldowns: { [Player]: { [string]: number } } = {}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function getCooldownRemaining(player: Player, itemId: string): number
	if not cooldowns[player] then
		return 0
	end
	local lastUse = cooldowns[player][itemId]
	if not lastUse then
		return 0
	end

	local itemDef = ItemDefinitions.get(itemId)
	if not itemDef or not itemDef.cooldown then
		return 0
	end

	local elapsed = os.clock() - lastUse
	return math.max(0, itemDef.cooldown - elapsed)
end

local function setCooldown(player: Player, itemId: string)
	if not cooldowns[player] then
		cooldowns[player] = {}
	end
	cooldowns[player][itemId] = os.clock()
end

--------------------------------------------------------------------------------
-- CORE INVENTORY OPERATIONS
--------------------------------------------------------------------------------

function InventoryService:getInventory(player: Player): { [string]: any }?
	local data = PlayerDataService:getData(player)
	if not data then
		return nil
	end
	return data.inventory
end

function InventoryService:addItem(player: Player, itemId: string, quantity: number, metadata: { [string]: any }?): boolean
	local itemDef = ItemDefinitions.get(itemId)
	if not itemDef then
		warn("[InventoryService] Unknown item:", itemId)
		return false
	end

	local inventory = self:getInventory(player)
	if not inventory then
		return false
	end

	local existing = inventory.items[itemId]

	if existing then
		-- Check stack limit
		if itemDef.stackable then
			local newQuantity = existing.quantity + quantity
			if newQuantity > itemDef.maxStack then
				-- Can only add up to max stack
				local canAdd = itemDef.maxStack - existing.quantity
				if canAdd <= 0 then
					return false -- Stack full
				end
				existing.quantity = itemDef.maxStack
				-- Could handle overflow here (new stack or drop)
			else
				existing.quantity = newQuantity
			end
		else
			-- Non-stackable, can't add more
			return false
		end
	else
		-- Check slot limit
		local slotCount = 0
		for _ in inventory.items do
			slotCount = slotCount + 1
		end

		if slotCount >= inventory.maxSlots then
			return false -- Inventory full
		end

		-- Add new item
		inventory.items[itemId] = {
			quantity = math.min(quantity, itemDef.maxStack),
			metadata = metadata,
		}
	end

	-- Notify client of full inventory update
	if Network then
		Network.Events.InventoryUpdate:FireClient(player, inventory.items)
	end

	-- Notify QuestService for collection quests
	if QuestService then
		QuestService:onItemCollected(player, itemId, quantity)
	end

	return true
end

function InventoryService:removeItem(player: Player, itemId: string, quantity: number): boolean
	local inventory = self:getInventory(player)
	if not inventory then
		return false
	end

	local existing = inventory.items[itemId]
	if not existing then
		return false
	end

	if existing.quantity < quantity then
		return false -- Not enough
	end

	existing.quantity = existing.quantity - quantity

	if existing.quantity <= 0 then
		inventory.items[itemId] = nil
	end

	-- Notify client of full inventory update
	if Network then
		Network.Events.InventoryUpdate:FireClient(player, inventory.items)
	end

	return true
end

function InventoryService:hasItem(player: Player, itemId: string, quantity: number?): boolean
	quantity = quantity or 1
	local inventory = self:getInventory(player)
	if not inventory then
		return false
	end

	local existing = inventory.items[itemId]
	return existing ~= nil and existing.quantity >= quantity
end

function InventoryService:getItemCount(player: Player, itemId: string): number
	local inventory = self:getInventory(player)
	if not inventory then
		return 0
	end

	local existing = inventory.items[itemId]
	return if existing then existing.quantity else 0
end

function InventoryService:getAllItems(player: Player): { [string]: number }
	local result = {}
	local inventory = self:getInventory(player)
	if not inventory then
		return result
	end

	for itemId, slot in inventory.items do
		result[itemId] = slot.quantity
	end
	return result
end

--------------------------------------------------------------------------------
-- ITEM USAGE
--------------------------------------------------------------------------------

function InventoryService:useItem(player: Player, itemId: string, targetId: string?): { success: boolean, message: string }
	local itemDef = ItemDefinitions.get(itemId)
	if not itemDef then
		return { success = false, message = "Unknown item" }
	end

	if not itemDef.usable then
		return { success = false, message = "This item cannot be used" }
	end

	-- Check if player has the item
	if not self:hasItem(player, itemId) then
		return { success = false, message = "You don't have this item" }
	end

	-- Check cooldown
	local cooldownLeft = getCooldownRemaining(player, itemId)
	if cooldownLeft > CONFIG.COOLDOWN_TOLERANCE then
		return { success = false, message = string.format("Wait %.1f seconds", cooldownLeft) }
	end

	-- Apply effects
	local effects = itemDef.effects
	local message = "Used " .. itemDef.name

	if effects then
		local playerData = PlayerDataService:getData(player)
		if playerData then
			-- Hunger/Thirst restoration
			if effects.hungerRestore then
				playerData.stats.hunger = math.min(
					playerData.stats.maxHunger,
					playerData.stats.hunger + effects.hungerRestore
				)
			end
			if effects.thirstRestore then
				playerData.stats.thirst = math.min(
					playerData.stats.maxThirst,
					playerData.stats.thirst + effects.thirstRestore
				)
			end

			-- Health restoration
			if effects.healthRestore then
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + effects.healthRestore)
				end
			end

			-- Ecology action
			if effects.ecoAction and EcologyService then
				local character = player.Character
				local rootPart = character and character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					local region = EcologyService:getRegionAtPosition(rootPart.Position)
					if region then
						local result = EcologyService:applyPlayerAction(
							player,
							region.id,
							effects.ecoAction,
							effects.targetSpecies or targetId
						)
						message = result.message
					else
						message = "No ecosystem here to affect"
					end
				end
			end

			-- Notify client of stat changes
			if Network and (effects.hungerRestore or effects.thirstRestore) then
				Network.Events.StatUpdate:FireClient(player, {
					hunger = playerData.stats.hunger,
					thirst = playerData.stats.thirst,
				})
			end
		end
	end

	-- Consume item if consumable
	if itemDef.consumable then
		self:removeItem(player, itemId, 1)
	end

	-- Set cooldown
	if itemDef.cooldown then
		setCooldown(player, itemId)
	end

	return { success = true, message = message }
end

--------------------------------------------------------------------------------
-- CURRENCY
--------------------------------------------------------------------------------

function InventoryService:getCurrency(player: Player): number
	local inventory = self:getInventory(player)
	return if inventory then inventory.currency else 0
end

function InventoryService:addCurrency(player: Player, amount: number): boolean
	local inventory = self:getInventory(player)
	if not inventory then
		return false
	end

	inventory.currency = inventory.currency + amount
	return true
end

function InventoryService:removeCurrency(player: Player, amount: number): boolean
	local inventory = self:getInventory(player)
	if not inventory then
		return false
	end

	if inventory.currency < amount then
		return false
	end

	inventory.currency = inventory.currency - amount
	return true
end

function InventoryService:hasCurrency(player: Player, amount: number): boolean
	return self:getCurrency(player) >= amount
end

--------------------------------------------------------------------------------
-- TRADING / TRANSFER
--------------------------------------------------------------------------------

function InventoryService:transferItem(from: Player, to: Player, itemId: string, quantity: number): boolean
	if not self:hasItem(from, itemId, quantity) then
		return false
	end

	-- Try to add to recipient first
	if not self:addItem(to, itemId, quantity) then
		return false -- Recipient can't receive
	end

	-- Remove from sender
	self:removeItem(from, itemId, quantity)
	return true
end

--------------------------------------------------------------------------------
-- DROPS / WORLD ITEMS
--------------------------------------------------------------------------------

function InventoryService:dropItem(player: Player, itemId: string, quantity: number): boolean
	if not self:removeItem(player, itemId, quantity) then
		return false
	end

	-- TODO: Spawn world item at player position
	-- For now, items are just deleted when dropped

	return true
end

function InventoryService:pickupItem(player: Player, worldItemId: string): boolean
	-- TODO: Find world item, validate proximity, add to inventory, remove from world
	-- This requires a WorldItem system to track items in the world

	return false
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function InventoryService:init()
	-- Load dependencies
	ItemDefinitions = require(ReplicatedStorage.Shared.Items.ItemDefinitions)
	PlayerDataService = require(ServerScriptService.Server.Data.PlayerDataService)

	pcall(function()
		EcologyService = require(ServerScriptService.Server.Ecology.EcologyService)
	end)

	pcall(function()
		Network = require(ReplicatedStorage.Shared.Network)
	end)

	pcall(function()
		QuestService = require(ServerScriptService.Server.Quest.QuestService)
	end)

	-- Clean up cooldowns when players leave
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
	end)

	print("[InventoryService] Initialized")
end

return InventoryService
