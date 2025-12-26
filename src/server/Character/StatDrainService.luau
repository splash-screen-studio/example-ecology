--!strict
--[[
    StatDrainService

    Decreases player hunger and thirst over time.
    Triggers death when stats hit zero.

    Usage:
        local StatDrainService = require(script.StatDrainService)
        StatDrainService:init()
]]

local StatDrainService = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies (lazy loaded)
local PlayerDataService
local SpawnService
local WaterController
local Network

-- Configuration: Two stats to find common patterns
local DRAIN_CONFIG = {
	hunger = {
		rate = 2, -- Amount to drain per tick
		interval = 5, -- Seconds between drains (faster for testing)
		deathMessage = "You starved!",
	},
	thirst = {
		rate = 3, -- Thirst drains faster than hunger
		interval = 5, -- Seconds between drains
		deathMessage = "You died of thirst!",
	},
}

-- Water restoration config
local WATER_CONFIG = {
	thirstRestoreRate = 8, -- Amount to restore per interval while in water (fast, noticeable)
	restoreInterval = 1, -- Seconds between restoration ticks (frequent updates)
}

local CONFIG = {
	UPDATE_INTERVAL = 1, -- How often to check (seconds)
	RESPAWN_DELAY = 3, -- Seconds before respawn
	RESET_STATS_ON_DEATH = true,
	PAUSE_WHEN_DEAD = true,
}

-- State
local playerTimers: { [Player]: { [string]: number } } = {}
local waterRestoreTimers: { [Player]: number } = {}
local initialized = false

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not PlayerDataService then
		PlayerDataService = require(script.Parent.Parent.Data.PlayerDataService)
	end
	if not SpawnService then
		SpawnService = require(script.Parent.SpawnService)
	end
	if not WaterController then
		WaterController = require(script.Parent.WaterController)
	end
	if not Network then
		Network = require(ReplicatedStorage.Shared.Network)
	end
end

local function isPlayerInWater(player: Player): boolean
	loadDependencies() -- Ensure WaterController is loaded
	if not WaterController then
		return false
	end
	local state = WaterController:getPlayerState(player)
	local inWater = state ~= nil and (state.mode == "swimming" or state.mode == "wading")
	if inWater then
		print(string.format("[StatDrainService] %s is in water (mode: %s)", player.Name, state.mode))
	end
	return inWater
end

local function syncStatsToClient(player: Player)
	local data = PlayerDataService:getData(player)
	if data then
		Network.Events.StatUpdate:FireClient(player, {
			hunger = data.stats.hunger,
			thirst = data.stats.thirst,
		})
	end
end

local function resetStats(player: Player)
	local data = PlayerDataService:getData(player)
	if data then
		data.stats.hunger = data.stats.maxHunger
		data.stats.thirst = data.stats.maxThirst
		syncStatsToClient(player)
	end
end

local function triggerDeath(player: Player, reason: string)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return -- Already dead
	end

	print(string.format("[StatDrainService] %s died: %s", player.Name, reason))

	-- Set death reason attribute for client death screen
	character:SetAttribute("DeathReason", reason)

	-- Kill the player
	humanoid.Health = 0

	-- Reset stats after respawn delay
	if CONFIG.RESET_STATS_ON_DEATH then
		task.delay(CONFIG.RESPAWN_DELAY + 0.5, function()
			if player.Parent then
				resetStats(player)
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- WATER RESTORATION LOGIC
--------------------------------------------------------------------------------

local function restoreThirstInWater(player: Player)
	local data = PlayerDataService:getData(player)
	if not data then
		return
	end

	-- Check if player is alive
	if CONFIG.PAUSE_WHEN_DEAD then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
	end

	-- Restore thirst up to max
	local currentThirst = data.stats.thirst
	local maxThirst = data.stats.maxThirst
	if currentThirst < maxThirst then
		local newThirst = math.min(maxThirst, currentThirst + WATER_CONFIG.thirstRestoreRate)
		data.stats.thirst = newThirst
		print(string.format("[StatDrainService] Restoring thirst for %s: %.1f -> %.1f", player.Name, currentThirst, newThirst))
		syncStatsToClient(player)
	end
end

--------------------------------------------------------------------------------
-- DRAIN LOGIC
--------------------------------------------------------------------------------

local function drainStat(player: Player, statName: string, config: typeof(DRAIN_CONFIG.hunger))
	local data = PlayerDataService:getData(player)
	if not data then
		return
	end

	-- Check if player is alive
	if CONFIG.PAUSE_WHEN_DEAD then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return
		end
	end

	-- Drain the stat
	local currentValue = data.stats[statName]
	local newValue = math.max(0, currentValue - config.rate)
	data.stats[statName] = newValue

	-- Sync to client
	syncStatsToClient(player)

	-- Check for death
	if newValue <= 0 then
		triggerDeath(player, config.deathMessage)
	end
end

local function updatePlayer(player: Player, deltaTime: number)
	local timers = playerTimers[player]
	if not timers then
		return
	end

	-- Check if player is in water for thirst restoration
	local inWater = isPlayerInWater(player)
	if inWater then
		waterRestoreTimers[player] = (waterRestoreTimers[player] or 0) + deltaTime
		if waterRestoreTimers[player] >= WATER_CONFIG.restoreInterval then
			waterRestoreTimers[player] = waterRestoreTimers[player] - WATER_CONFIG.restoreInterval
			restoreThirstInWater(player)
		end
	else
		waterRestoreTimers[player] = 0
	end

	-- Update each stat timer
	for statName, config in DRAIN_CONFIG do
		timers[statName] = timers[statName] + deltaTime

		if timers[statName] >= config.interval then
			timers[statName] = timers[statName] - config.interval
			-- Skip thirst drain if in water (water restores instead)
			if statName == "thirst" and inWater then
				continue
			end
			drainStat(player, statName, config)
		end
	end
end

--------------------------------------------------------------------------------
-- PLAYER MANAGEMENT
--------------------------------------------------------------------------------

local function initPlayerTimers(player: Player)
	playerTimers[player] = {}
	for statName, _ in DRAIN_CONFIG do
		playerTimers[player][statName] = 0
	end
end

local function cleanupPlayer(player: Player)
	playerTimers[player] = nil
	waterRestoreTimers[player] = nil
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function StatDrainService:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()

	-- Initialize existing players
	for _, player in Players:GetPlayers() do
		initPlayerTimers(player)
	end

	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		initPlayerTimers(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		cleanupPlayer(player)
	end)

	-- Main update loop
	local accumulator = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		accumulator = accumulator + deltaTime
		if accumulator < CONFIG.UPDATE_INTERVAL then
			return
		end

		local dt = accumulator
		accumulator = 0

		for player, _ in playerTimers do
			updatePlayer(player, dt)
		end
	end)

	print("[StatDrainService] Initialized - hunger drains every", DRAIN_CONFIG.hunger.interval, "s, thirst every", DRAIN_CONFIG.thirst.interval, "s")
end

function StatDrainService:setDrainRate(statName: string, rate: number)
	if DRAIN_CONFIG[statName] then
		DRAIN_CONFIG[statName].rate = rate
	end
end

function StatDrainService:setDrainInterval(statName: string, interval: number)
	if DRAIN_CONFIG[statName] then
		DRAIN_CONFIG[statName].interval = interval
	end
end

function StatDrainService:pauseDrain(player: Player)
	playerTimers[player] = nil
end

function StatDrainService:resumeDrain(player: Player)
	if not playerTimers[player] then
		initPlayerTimers(player)
	end
end

function StatDrainService:forceDrain(player: Player, statName: string, amount: number)
	local data = PlayerDataService:getData(player)
	if not data then
		return
	end

	local currentValue = data.stats[statName]
	if currentValue then
		data.stats[statName] = math.max(0, currentValue - amount)
		syncStatsToClient(player)

		if data.stats[statName] <= 0 and DRAIN_CONFIG[statName] then
			triggerDeath(player, DRAIN_CONFIG[statName].deathMessage)
		end
	end
end

function StatDrainService:getConfig(): typeof(DRAIN_CONFIG)
	return DRAIN_CONFIG
end

return StatDrainService
