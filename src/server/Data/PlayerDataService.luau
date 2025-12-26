--!strict
--[[
    PlayerDataService

    Handles player data persistence using ProfileService.
    Provides session-locked profiles with automatic saving.

    Usage:
        local PlayerDataService = require(script.Parent.PlayerDataService)
        PlayerDataService:init()

        -- Get player data
        local data = PlayerDataService:getData(player)
        data.inventory.items["apple"] = 5

        -- Data auto-saves, or force save:
        PlayerDataService:save(player)
]]

local PlayerDataService = {}

-- Services
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

-- Dependencies
local ProfileService = require(ServerScriptService.ServerPackages.ProfileService)

-- Types
export type InventoryItem = {
	quantity: number,
	metadata: { [string]: any }?, -- durability, quality, etc.
}

export type QuestProgress = {
	questId: string,
	startedAt: number,
	objectives: { [string]: number }, -- objectiveId -> progress
	completed: boolean,
}

export type Discovery = {
	discoveredAt: number,
	location: string?, -- where first discovered
}

export type PlayerData = {
	-- Version for migrations
	schemaVersion: number,

	-- Survival stats
	stats: {
		hunger: number,
		thirst: number,
		maxHunger: number,
		maxThirst: number,
	},

	-- Inventory system
	inventory: {
		items: { [string]: InventoryItem }, -- itemId -> item data
		maxSlots: number,
		currency: number, -- in-game currency (not Robux)
	},

	-- Quest tracking
	quests: {
		active: { [string]: QuestProgress },
		completed: { [string]: number }, -- questId -> completion timestamp
	},

	-- Discovery journal
	discoveries: {
		species: { [string]: Discovery }, -- speciesId -> discovery info
		locations: { [string]: Discovery }, -- locationId -> discovery info
	},

	-- Player's ecological impact (per place)
	ecoImpact: {
		[string]: { -- placeId
			actionsPositive: number,
			actionsNegative: number,
			speciesHelped: { [string]: number },
			speciesHarmed: { [string]: number },
		},
	},

	-- Settings (synced to client)
	settings: {
		musicVolume: number,
		sfxVolume: number,
		showTutorials: boolean,
	},

	-- Metadata
	meta: {
		firstJoinAt: number,
		lastJoinAt: number,
		totalPlayTime: number, -- seconds
		currentSessionStart: number?,
	},
}

-- Default profile template
local ProfileTemplate: PlayerData = {
	schemaVersion = 1,

	stats = {
		hunger = 100,
		thirst = 100,
		maxHunger = 100,
		maxThirst = 100,
	},

	inventory = {
		items = {},
		maxSlots = 20,
		currency = 0,
	},

	quests = {
		active = {},
		completed = {},
	},

	discoveries = {
		species = {},
		locations = {},
	},

	ecoImpact = {},

	settings = {
		musicVolume = 0.7,
		sfxVolume = 1.0,
		showTutorials = true,
	},

	meta = {
		firstJoinAt = 0,
		lastJoinAt = 0,
		totalPlayTime = 0,
		currentSessionStart = nil,
	},
}

-- Profile store
local PROFILE_STORE_NAME = "PlayerData_v1"
local ProfileStore = ProfileService.GetProfileStore(PROFILE_STORE_NAME, ProfileTemplate)

-- Active profiles
local Profiles: { [Player]: any } = {}

--------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
--------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	-- Load profile with session locking
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)

	if profile == nil then
		-- Failed to load, kick player
		player:Kick("Failed to load your data. Please rejoin.")
		return
	end

	-- GDPR compliance: associate UserId with profile
	profile:AddUserId(player.UserId)

	-- Fill in missing values from template (schema migrations)
	profile:Reconcile()

	-- Handle session lock stolen (another server loaded this profile)
	profile:ListenToRelease(function()
		Profiles[player] = nil
		player:Kick("Your data was loaded on another server. Please rejoin.")
	end)

	-- Check if player is still in game
	if not player:IsDescendantOf(Players) then
		profile:Release()
		return
	end

	-- Store profile
	Profiles[player] = profile

	-- Update metadata
	local data = profile.Data :: PlayerData
	local now = os.time()

	if data.meta.firstJoinAt == 0 then
		data.meta.firstJoinAt = now
	end
	data.meta.lastJoinAt = now
	data.meta.currentSessionStart = now

	print(string.format("[PlayerDataService] Loaded profile for %s", player.Name))
end

local function onPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile == nil then
		return
	end

	-- Update total play time
	local data = profile.Data :: PlayerData
	if data.meta.currentSessionStart then
		local sessionTime = os.time() - data.meta.currentSessionStart
		data.meta.totalPlayTime = data.meta.totalPlayTime + sessionTime
		data.meta.currentSessionStart = nil
	end

	-- Release profile (triggers save)
	profile:Release()
	Profiles[player] = nil

	print(string.format("[PlayerDataService] Released profile for %s", player.Name))
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function PlayerDataService:init()
	-- Don't run in Studio test mode without DataStore access
	if RunService:IsStudio() then
		-- Use mock profile store for testing
		ProfileStore = ProfileService.GetProfileStore(PROFILE_STORE_NAME, ProfileTemplate)
	end

	-- Handle existing players (in case of late initialization)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	-- Handle new players
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	-- Handle server shutdown
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			onPlayerRemoving(player)
		end
	end)

	print("[PlayerDataService] Initialized")
end

function PlayerDataService:getProfile(player: Player): any?
	return Profiles[player]
end

function PlayerDataService:getData(player: Player): PlayerData?
	local profile = Profiles[player]
	if profile then
		return profile.Data :: PlayerData
	end
	return nil
end

function PlayerDataService:isLoaded(player: Player): boolean
	return Profiles[player] ~= nil
end

function PlayerDataService:waitForData(player: Player, timeout: number?): PlayerData?
	timeout = timeout or 10
	local startTime = tick()

	while not self:isLoaded(player) do
		if tick() - startTime > timeout then
			return nil
		end
		task.wait(0.1)
	end

	return self:getData(player)
end

-- Inventory helpers
function PlayerDataService:addItem(player: Player, itemId: string, quantity: number, metadata: { [string]: any }?): boolean
	local data = self:getData(player)
	if not data then
		return false
	end

	local existing = data.inventory.items[itemId]
	if existing then
		existing.quantity = existing.quantity + quantity
		if metadata then
			existing.metadata = metadata
		end
	else
		data.inventory.items[itemId] = {
			quantity = quantity,
			metadata = metadata,
		}
	end

	return true
end

function PlayerDataService:removeItem(player: Player, itemId: string, quantity: number): boolean
	local data = self:getData(player)
	if not data then
		return false
	end

	local existing = data.inventory.items[itemId]
	if not existing or existing.quantity < quantity then
		return false
	end

	existing.quantity = existing.quantity - quantity
	if existing.quantity <= 0 then
		data.inventory.items[itemId] = nil
	end

	return true
end

function PlayerDataService:hasItem(player: Player, itemId: string, quantity: number?): boolean
	local data = self:getData(player)
	if not data then
		return false
	end

	quantity = quantity or 1
	local existing = data.inventory.items[itemId]
	return existing ~= nil and existing.quantity >= quantity
end

-- Discovery helpers
function PlayerDataService:addDiscovery(player: Player, category: "species" | "locations", id: string, location: string?): boolean
	local data = self:getData(player)
	if not data then
		return false
	end

	local discoveries = if category == "species" then data.discoveries.species else data.discoveries.locations

	if discoveries[id] then
		return false -- Already discovered
	end

	discoveries[id] = {
		discoveredAt = os.time(),
		location = location,
	}

	return true
end

function PlayerDataService:hasDiscovery(player: Player, category: "species" | "locations", id: string): boolean
	local data = self:getData(player)
	if not data then
		return false
	end

	local discoveries = if category == "species" then data.discoveries.species else data.discoveries.locations
	return discoveries[id] ~= nil
end

-- Ecological impact tracking
function PlayerDataService:recordEcoAction(player: Player, placeId: string, positive: boolean, speciesId: string?)
	local data = self:getData(player)
	if not data then
		return
	end

	if not data.ecoImpact[placeId] then
		data.ecoImpact[placeId] = {
			actionsPositive = 0,
			actionsNegative = 0,
			speciesHelped = {},
			speciesHarmed = {},
		}
	end

	local impact = data.ecoImpact[placeId]

	if positive then
		impact.actionsPositive = impact.actionsPositive + 1
		if speciesId then
			impact.speciesHelped[speciesId] = (impact.speciesHelped[speciesId] or 0) + 1
		end
	else
		impact.actionsNegative = impact.actionsNegative + 1
		if speciesId then
			impact.speciesHarmed[speciesId] = (impact.speciesHarmed[speciesId] or 0) + 1
		end
	end
end

return PlayerDataService
