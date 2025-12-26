--!strict
--[[
    DiscoveryService

    Manages player discoveries of species, flora, locations, and lore.
    Tracks progress, sends notifications, and integrates with quests.

    Usage:
        local DiscoveryService = require(script.Parent.DiscoveryService)
        DiscoveryService:init()

        -- Trigger a discovery
        DiscoveryService:discover(player, "species_forest_deer")

        -- Check if discovered
        local hasIt = DiscoveryService:hasDiscovered(player, "species_forest_deer")
]]

local DiscoveryService = {}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Dependencies (lazy loaded)
local DiscoveryDefinitions
local PlayerDataService
local Network

-- Configuration
local CONFIG = {
	PROXIMITY_CHECK_INTERVAL = 2, -- Seconds between location proximity checks
	PROXIMITY_CHECK_DISTANCE = 100, -- Only check locations within this distance
}

-- State
local initialized = false
local locationCheckConnections: { [Player]: RBXScriptConnection } = {}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not DiscoveryDefinitions then
		DiscoveryDefinitions = require(script.Parent.DiscoveryDefinitions)
	end
	if not PlayerDataService then
		PlayerDataService = require(script.Parent.Parent.Data.PlayerDataService)
	end
	if not Network then
		Network = require(ReplicatedStorage.Shared.Network)
	end
end

local function getPlayerPosition(player: Player): Vector3?
	local character = player.Character
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return nil
	end

	return rootPart.Position
end

local function getCategoryKey(category: string): "species" | "locations"
	-- Map discovery categories to PlayerData categories
	if category == "species" or category == "flora" then
		return "species"
	else
		return "locations"
	end
end

--------------------------------------------------------------------------------
-- DISCOVERY LOGIC
--------------------------------------------------------------------------------

function DiscoveryService:discover(player: Player, discoveryId: string): boolean
	loadDependencies()

	local definition = DiscoveryDefinitions.get(discoveryId)
	if not definition then
		warn("[DiscoveryService] Unknown discovery:", discoveryId)
		return false
	end

	-- Check if already discovered
	local categoryKey = getCategoryKey(definition.category)
	if PlayerDataService:hasDiscovery(player, categoryKey, discoveryId) then
		return false -- Already known
	end

	-- Add to player data
	local placeName = "verdant_basin" -- TODO: Get from PlaceConfig
	local isNew = PlayerDataService:addDiscovery(player, categoryKey, discoveryId, placeName)

	if not isNew then
		return false
	end

	-- Send notification to client
	Network.Events.Discovery:FireClient(player, {
		isNew = true,
		id = discoveryId,
		category = definition.category,
		name = definition.name,
		description = definition.description,
		rarity = definition.rarity or "common",
		experienceReward = definition.experienceReward,
	})

	print(string.format("[DiscoveryService] %s discovered: %s (%s)", player.Name, definition.name, definition.category))

	-- Fire event for quest system integration
	-- QuestService can listen to this
	self._onDiscovery:Fire(player, discoveryId, definition)

	return true
end

function DiscoveryService:hasDiscovered(player: Player, discoveryId: string): boolean
	loadDependencies()

	local definition = DiscoveryDefinitions.get(discoveryId)
	if not definition then
		return false
	end

	local categoryKey = getCategoryKey(definition.category)
	return PlayerDataService:hasDiscovery(player, categoryKey, discoveryId)
end

function DiscoveryService:getDiscoveryProgress(player: Player): { [string]: { discovered: number, total: number } }
	loadDependencies()

	local progress = {}

	for _, category in { "species", "flora", "locations", "lore" } do
		local total = DiscoveryDefinitions.getCategoryCount(category)
		local discovered = 0

		for _, def in DiscoveryDefinitions.getByCategory(category) do
			if self:hasDiscovered(player, def.id) then
				discovered = discovered + 1
			end
		end

		progress[category] = {
			discovered = discovered,
			total = total,
		}
	end

	return progress
end

function DiscoveryService:getAllDiscoveries(player: Player): { string }
	loadDependencies()

	local discoveries = {}

	for _, def in DiscoveryDefinitions.getAll() do
		if self:hasDiscovered(player, def.id) then
			table.insert(discoveries, def.id)
		end
	end

	return discoveries
end

--------------------------------------------------------------------------------
-- PROXIMITY-BASED DISCOVERIES
--------------------------------------------------------------------------------

local function checkLocationDiscoveries(player: Player)
	local playerPos = getPlayerPosition(player)
	if not playerPos then
		return
	end

	for _, def in DiscoveryDefinitions.getByCategory("locations") do
		if def.position and def.radius then
			local distance = (playerPos - def.position).Magnitude

			if distance <= def.radius then
				DiscoveryService:discover(player, def.id)
			end
		end
	end
end

local function startLocationChecking(player: Player)
	if locationCheckConnections[player] then
		return
	end

	local accumulator = 0
	locationCheckConnections[player] = RunService.Heartbeat:Connect(function(dt)
		accumulator = accumulator + dt
		if accumulator < CONFIG.PROXIMITY_CHECK_INTERVAL then
			return
		end
		accumulator = 0

		checkLocationDiscoveries(player)
	end)
end

local function stopLocationChecking(player: Player)
	local conn = locationCheckConnections[player]
	if conn then
		conn:Disconnect()
		locationCheckConnections[player] = nil
	end
end

--------------------------------------------------------------------------------
-- OBSERVATION-BASED DISCOVERIES
--------------------------------------------------------------------------------

-- Called when a player observes an NPC/creature
function DiscoveryService:onObserve(player: Player, speciesId: string)
	loadDependencies()

	-- Find discovery by species ID
	for _, def in DiscoveryDefinitions.getByCategory("species") do
		if def.speciesId == speciesId then
			self:discover(player, def.id)
			return
		end
	end
end

-- Called when a player interacts with flora
function DiscoveryService:onFloraInteract(player: Player, floraId: string)
	loadDependencies()

	-- Find discovery by flora ID
	for _, def in DiscoveryDefinitions.getByCategory("flora") do
		if def.speciesId == floraId then
			self:discover(player, def.id)
			return
		end
	end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function DiscoveryService:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()

	-- Create bindable event for other services to listen
	self._onDiscovery = Instance.new("BindableEvent")

	-- Start location checking for existing players
	for _, player in Players:GetPlayers() do
		startLocationChecking(player)
	end

	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		-- Wait for character to spawn
		player.CharacterAdded:Connect(function()
			startLocationChecking(player)
		end)

		if player.Character then
			startLocationChecking(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		stopLocationChecking(player)
	end)

	print("[DiscoveryService] Initialized with", DiscoveryDefinitions.getTotalCount(), "discoveries")
end

-- Event for quest system integration
function DiscoveryService:onDiscoveryMade(): RBXScriptSignal
	return self._onDiscovery.Event
end

-- Utility to get definition
function DiscoveryService:getDefinition(discoveryId: string)
	loadDependencies()
	return DiscoveryDefinitions.get(discoveryId)
end

function DiscoveryService:getDefinitions()
	loadDependencies()
	return DiscoveryDefinitions
end

return DiscoveryService
