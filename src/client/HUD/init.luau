--!strict
--[[
    HUD Controller

    Main controller for all player HUD elements.
    Manages stats display, inventory hotbar, and interaction prompts.

    Usage:
        local HUD = require(script.Parent.HUD)
        HUD:init()
]]

local HUD = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Components
local StatsBar = require(script.Components.StatsBar)
local InventoryHotbar = require(script.Components.InventoryHotbar)
local InteractionPrompt = require(script.Components.InteractionPrompt)
local NotificationToast = require(script.Components.NotificationToast)
local DeathScreen = require(script.Components.DeathScreen)

-- Dependencies (lazy loaded)
local Network

-- State
local player = Players.LocalPlayer
local playerGui: PlayerGui?
local screenGui: ScreenGui?

-- Widgets
local statsWidget: StatsBar.StatsBarWidget?
local hotbarWidget: InventoryHotbar.HotbarWidget?
local interactionWidget: InteractionPrompt.PromptWidget?
local toastWidget: NotificationToast.ToastWidget?
local deathWidget: DeathScreen.DeathScreenWidget?

-- Connection tracking
local connections: { RBXScriptConnection } = {}

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function loadDependencies()
	if not Network then
		local Shared = ReplicatedStorage:WaitForChild("Shared")
		Network = require(Shared.Network)
	end
end

local function createScreenGui(): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "GameHUD"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = false
	return gui
end

local function setupNetworkListeners()
	loadDependencies()

	-- Listen for stat updates from server
	local statUpdateConn = Network.Events.StatUpdate.OnClientEvent:Connect(function(data: { hunger: number?, thirst: number? })
		if statsWidget then
			if data.hunger then
				statsWidget:update("hunger", data.hunger, 100)
			end
			if data.thirst then
				statsWidget:update("thirst", data.thirst, 100)
			end
		end
	end)
	table.insert(connections, statUpdateConn)

	-- Listen for inventory updates from server
	local inventoryUpdateConn = Network.Events.InventoryUpdate.OnClientEvent:Connect(function(items: { [string]: { quantity: number } })
		if hotbarWidget then
			-- Convert server format to hotbar format
			-- For now, take first 5 items
			local hotbarItems: { InventoryHotbar.InventoryItem? } = {}
			local index = 1

			for itemId, itemData in items do
				if index > 5 then
					break
				end
				hotbarItems[index] = {
					itemId = itemId,
					quantity = itemData.quantity,
				}
				index = index + 1
			end

			hotbarWidget:setItems(hotbarItems)
		end
	end)
	table.insert(connections, inventoryUpdateConn)

	-- Listen for discovery notifications
	local discoveryConn = Network.Events.Discovery.OnClientEvent:Connect(function(data: any)
		if toastWidget and data.isNew then
			toastWidget:show("discovery", "New Discovery: " .. (data.name or "Unknown"), data.description, data.rarity)
		end
	end)
	table.insert(connections, discoveryConn)

	-- Listen for quest updates
	local questUpdateConn = Network.Events.QuestUpdate.OnClientEvent:Connect(function(data: any)
		if toastWidget then
			if data.action == "new" then
				toastWidget:show("quest", "Quest Started: " .. (data.name or "Unknown"), data.description)
			elseif data.action == "complete" then
				toastWidget:show("reward", "Quest Complete: " .. (data.name or "Unknown"), "Rewards received!")
			end
		end
	end)
	table.insert(connections, questUpdateConn)
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function HUD:init()
	playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	-- Create main screen GUI
	screenGui = createScreenGui()
	screenGui.Parent = playerGui

	-- Create stats bar (top-left)
	statsWidget = StatsBar.create(screenGui)

	-- Create inventory hotbar (bottom-center)
	hotbarWidget = InventoryHotbar.create(screenGui)

	-- Create interaction prompt (follows interactable objects)
	interactionWidget = InteractionPrompt.create(playerGui)

	-- Create notification toast (top-right popups)
	toastWidget = NotificationToast.create(screenGui)

	-- Create death screen overlay
	deathWidget = DeathScreen.create(screenGui)

	-- Setup hotbar item use callback
	hotbarWidget.onUseItem = function(item: InventoryHotbar.InventoryItem)
		loadDependencies()
		Network.Events.UseItem:FireServer({
			itemId = item.itemId,
		})
	end

	-- Setup network listeners
	setupNetworkListeners()

	-- Setup death/respawn handling
	local function onCharacterDied(character: Model)
		if deathWidget then
			-- Try to get death reason from attributes (set by StatDrainService)
			local deathReason = character:GetAttribute("DeathReason") or nil
			deathWidget:show(deathReason)
		end
	end

	local function onCharacterAdded(character: Model)
		-- Hide death screen when new character spawns
		if deathWidget then
			deathWidget:hide()
		end

		-- Listen for death
		local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
		if humanoid then
			local diedConn = humanoid.Died:Connect(function()
				onCharacterDied(character)
			end)
			table.insert(connections, diedConn)
		end
	end

	-- Connect to current and future characters
	if player.Character then
		onCharacterAdded(player.Character)
	end
	local charAddedConn = player.CharacterAdded:Connect(onCharacterAdded)
	table.insert(connections, charAddedConn)

	-- Initialize with default values
	statsWidget:update("hunger", 100, 100)
	statsWidget:update("thirst", 100, 100)

	print("[HUD] Initialized")
end

function HUD:destroy()
	-- Disconnect all connections
	for _, conn in connections do
		conn:Disconnect()
	end
	connections = {}

	-- Destroy widgets
	if statsWidget then
		statsWidget:destroy()
		statsWidget = nil
	end

	if hotbarWidget then
		hotbarWidget:destroy()
		hotbarWidget = nil
	end

	if interactionWidget then
		interactionWidget:destroy()
		interactionWidget = nil
	end

	if toastWidget then
		toastWidget:destroy()
		toastWidget = nil
	end

	if deathWidget then
		deathWidget:destroy()
		deathWidget = nil
	end

	-- Destroy GUI
	if screenGui then
		screenGui:Destroy()
		screenGui = nil
	end
end

function HUD:updateStat(statName: string, value: number, maxValue: number?)
	if statsWidget then
		statsWidget:update(statName, value, maxValue)
	end
end

function HUD:updateInventory(items: { InventoryHotbar.InventoryItem? })
	if hotbarWidget then
		hotbarWidget:setItems(items)
	end
end

function HUD:getSelectedItem(): InventoryHotbar.InventoryItem?
	if hotbarWidget then
		return hotbarWidget:getSelectedItem()
	end
	return nil
end

function HUD:show()
	if screenGui then
		screenGui.Enabled = true
	end
end

function HUD:hide()
	if screenGui then
		screenGui.Enabled = false
	end
end

function HUD:isVisible(): boolean
	return screenGui ~= nil and screenGui.Enabled
end

return HUD
