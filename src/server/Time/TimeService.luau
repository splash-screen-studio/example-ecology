--!strict
--[[
    TimeService

    Manages game time and syncs to all clients.
    Time advances continuously, driving day/night cycle.

    Usage:
        local TimeService = require(script.Parent.TimeService)
        TimeService:init()

        -- Get current time (0-24)
        local hour = TimeService:getTime()

        -- Check time of day
        local isNight = TimeService:isNight()
]]

local TimeService = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies (lazy loaded)
local PlaceConfig
local Network

-- State
local currentTime: number = 10 -- Current game hour (0-24)
local timeEnabled: boolean = true
local dayLengthMinutes: number = 12
local initialized = false

-- Constants
local SYNC_INTERVAL = 5 -- Seconds between client syncs
local HOURS_PER_DAY = 24

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not PlaceConfig then
		PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)
	end
	if not Network then
		Network = require(ReplicatedStorage.Shared.Network)
	end
end

local function getTimeConfig()
	loadDependencies()
	return PlaceConfig.getTimeConfig()
end

--------------------------------------------------------------------------------
-- TIME CALCULATION
--------------------------------------------------------------------------------

-- Convert real seconds to game hours
local function realSecondsToGameHours(realSeconds: number): number
	local realMinutesPerDay = dayLengthMinutes
	local realSecondsPerDay = realMinutesPerDay * 60
	local gameHoursPerRealSecond = HOURS_PER_DAY / realSecondsPerDay
	return realSeconds * gameHoursPerRealSecond
end

-- Normalize time to 0-24 range
local function normalizeTime(time: number): number
	return time % HOURS_PER_DAY
end

--------------------------------------------------------------------------------
-- TIME OF DAY HELPERS
--------------------------------------------------------------------------------

-- Time ranges for different periods
local TIME_PERIODS = {
	dawn = { start = 5, finish = 7 },
	day = { start = 7, finish = 17 },
	dusk = { start = 17, finish = 19 },
	night = { start = 19, finish = 5 }, -- Wraps around midnight
}

local function isInPeriod(time: number, period: { start: number, finish: number }): boolean
	if period.start < period.finish then
		return time >= period.start and time < period.finish
	else
		-- Wraps around midnight (e.g., night: 19-5)
		return time >= period.start or time < period.finish
	end
end

local function getCurrentPeriod(time: number): string
	for name, period in TIME_PERIODS do
		if isInPeriod(time, period) then
			return name
		end
	end
	return "day" -- Fallback
end

--------------------------------------------------------------------------------
-- SYNC TO CLIENTS
--------------------------------------------------------------------------------

local function syncToAllClients()
	loadDependencies()

	local timeData = {
		time = currentTime,
		period = getCurrentPeriod(currentTime),
		enabled = timeEnabled,
	}

	Network.Events.TimeUpdate:FireAllClients(timeData)
end

local function syncToPlayer(player: Player)
	loadDependencies()

	local timeData = {
		time = currentTime,
		period = getCurrentPeriod(currentTime),
		enabled = timeEnabled,
	}

	Network.Events.TimeUpdate:FireClient(player, timeData)
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function TimeService:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()

	-- Load config
	local config = getTimeConfig()
	currentTime = config.startTime or 10
	timeEnabled = config.timeEnabled ~= false
	dayLengthMinutes = config.dayLengthMinutes or 12

	-- Sync to new players
	Players.PlayerAdded:Connect(function(player)
		-- Small delay to ensure client is ready
		task.delay(1, function()
			if player.Parent then
				syncToPlayer(player)
			end
		end)
	end)

	-- Sync existing players
	for _, player in Players:GetPlayers() do
		syncToPlayer(player)
	end

	-- Time advancement loop
	local lastUpdate = os.clock()
	local syncAccumulator = 0

	RunService.Heartbeat:Connect(function()
		if not timeEnabled then
			return
		end

		local now = os.clock()
		local deltaTime = now - lastUpdate
		lastUpdate = now

		-- Advance time
		local gameHoursDelta = realSecondsToGameHours(deltaTime)
		currentTime = normalizeTime(currentTime + gameHoursDelta)

		-- Periodic sync to clients
		syncAccumulator = syncAccumulator + deltaTime
		if syncAccumulator >= SYNC_INTERVAL then
			syncAccumulator = 0
			syncToAllClients()
		end
	end)

	print(string.format(
		"[TimeService] Initialized - starting at %.1f:00, %d min/day cycle",
		currentTime,
		dayLengthMinutes
	))
end

function TimeService:getTime(): number
	return currentTime
end

function TimeService:getPeriod(): string
	return getCurrentPeriod(currentTime)
end

function TimeService:isDay(): boolean
	return isInPeriod(currentTime, TIME_PERIODS.day)
end

function TimeService:isNight(): boolean
	return isInPeriod(currentTime, TIME_PERIODS.night)
end

function TimeService:isDawn(): boolean
	return isInPeriod(currentTime, TIME_PERIODS.dawn)
end

function TimeService:isDusk(): boolean
	return isInPeriod(currentTime, TIME_PERIODS.dusk)
end

-- Set time directly (for debugging/admin)
function TimeService:setTime(hour: number)
	currentTime = normalizeTime(hour)
	syncToAllClients()
	print(string.format("[TimeService] Time set to %.1f:00", currentTime))
end

-- Pause/resume time
function TimeService:setEnabled(enabled: boolean)
	timeEnabled = enabled
	syncToAllClients()
	print(string.format("[TimeService] Time %s", enabled and "enabled" or "paused"))
end

-- Change day length
function TimeService:setDayLength(minutes: number)
	dayLengthMinutes = math.max(1, minutes)
	print(string.format("[TimeService] Day length set to %d minutes", dayLengthMinutes))
end

-- Get time periods for external use
function TimeService:getTimePeriods()
	return TIME_PERIODS
end

return TimeService
