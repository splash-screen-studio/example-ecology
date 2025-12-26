--!strict
--[[
    TimeController (Client)

    Receives time updates from server and smoothly transitions lighting.
    Handles day/night cycle visuals.

    Usage:
        local TimeController = require(script.Parent.Time)
        TimeController:init()
]]

local TimeController = {}

-- Services
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies (lazy loaded)
local PlaceConfig
local Network

-- State
local currentTime: number = 10
local currentPeriod: string = "day"
local targetLighting: { [string]: any } = {}
local initialized = false

-- Configuration
local CONFIG = {
	LIGHTING_LERP_SPEED = 0.02, -- How fast lighting transitions (per frame)
	CLOCK_UPDATE_INTERVAL = 0.1, -- How often to update ClockTime
}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not PlaceConfig then
		PlaceConfig = require(ReplicatedStorage:WaitForChild("Shared").PlaceConfig)
	end
	if not Network then
		Network = require(ReplicatedStorage:WaitForChild("Shared").Network)
	end
end

local function lerpColor3(a: Color3, b: Color3, t: number): Color3
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function lerpNumber(a: number, b: number, t: number): number
	return a + (b - a) * t
end

--------------------------------------------------------------------------------
-- LIGHTING CALCULATION
--------------------------------------------------------------------------------

-- Get lighting preset for current time period
local function getLightingForPeriod(period: string): { [string]: any }
	loadDependencies()
	local presets = PlaceConfig.getLightingPresets()

	local preset = presets[period]
	if not preset then
		-- Fallback to day
		preset = presets.day or {
			Ambient = Color3.fromRGB(128, 128, 128),
			Brightness = 2,
			OutdoorAmbient = Color3.fromRGB(128, 128, 128),
		}
	end

	return preset
end

-- Calculate blend factor for smooth transitions between periods
local function getTransitionFactor(time: number, period: string): number
	-- Time ranges
	local ranges = {
		dawn = { start = 5, mid = 6, finish = 7 },
		day = { start = 7, mid = 12, finish = 17 },
		dusk = { start = 17, mid = 18, finish = 19 },
		night = { start = 19, mid = 0, finish = 5 },
	}

	local range = ranges[period]
	if not range then
		return 1
	end

	-- Calculate progress through this period (0-1)
	if period == "night" then
		-- Handle wrap around midnight
		if time >= range.start then
			return (time - range.start) / (24 - range.start + range.finish)
		else
			return (24 - range.start + time) / (24 - range.start + range.finish)
		end
	else
		local duration = range.finish - range.start
		return math.clamp((time - range.start) / duration, 0, 1)
	end
end

-- Calculate blended lighting based on time
local function calculateTargetLighting(time: number, period: string)
	local currentPreset = getLightingForPeriod(period)

	-- Determine next period for blending
	local nextPeriod = "day"
	if period == "dawn" then
		nextPeriod = "day"
	elseif period == "day" then
		nextPeriod = "dusk"
	elseif period == "dusk" then
		nextPeriod = "night"
	elseif period == "night" then
		nextPeriod = "dawn"
	end

	local nextPreset = getLightingForPeriod(nextPeriod)
	local factor = getTransitionFactor(time, period)

	-- Blend between current and next period
	targetLighting = {
		Ambient = lerpColor3(currentPreset.Ambient, nextPreset.Ambient, factor * 0.3),
		Brightness = lerpNumber(currentPreset.Brightness, nextPreset.Brightness, factor * 0.3),
		OutdoorAmbient = lerpColor3(
			currentPreset.OutdoorAmbient or currentPreset.Ambient,
			nextPreset.OutdoorAmbient or nextPreset.Ambient,
			factor * 0.3
		),
	}
end

--------------------------------------------------------------------------------
-- LIGHTING APPLICATION
--------------------------------------------------------------------------------

local function applyLightingSmooth()
	-- Lerp current lighting toward target
	if targetLighting.Ambient then
		Lighting.Ambient = lerpColor3(Lighting.Ambient, targetLighting.Ambient, CONFIG.LIGHTING_LERP_SPEED)
	end

	if targetLighting.Brightness then
		Lighting.Brightness = lerpNumber(Lighting.Brightness, targetLighting.Brightness, CONFIG.LIGHTING_LERP_SPEED)
	end

	if targetLighting.OutdoorAmbient then
		Lighting.OutdoorAmbient = lerpColor3(
			Lighting.OutdoorAmbient,
			targetLighting.OutdoorAmbient,
			CONFIG.LIGHTING_LERP_SPEED
		)
	end
end

local function updateClockTime(time: number)
	-- ClockTime is 0-24
	Lighting.ClockTime = time
end

--------------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------------

local function onTimeUpdate(data: { time: number, period: string, enabled: boolean })
	currentTime = data.time
	currentPeriod = data.period

	-- Calculate new target lighting
	calculateTargetLighting(currentTime, currentPeriod)
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function TimeController:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()

	-- Apply initial lighting from PlaceConfig
	PlaceConfig.applyLighting()

	-- Initialize target lighting
	calculateTargetLighting(currentTime, currentPeriod)

	-- Listen for time updates
	Network.Events.TimeUpdate.OnClientEvent:Connect(onTimeUpdate)

	-- Smooth lighting update loop
	RunService.RenderStepped:Connect(function()
		applyLightingSmooth()
	end)

	-- Clock time update (less frequent)
	local clockAccumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		clockAccumulator = clockAccumulator + dt
		if clockAccumulator >= CONFIG.CLOCK_UPDATE_INTERVAL then
			clockAccumulator = 0
			updateClockTime(currentTime)
		end
	end)

	print("[TimeController] Initialized")
end

function TimeController:getTime(): number
	return currentTime
end

function TimeController:getPeriod(): string
	return currentPeriod
end

function TimeController:isNight(): boolean
	return currentPeriod == "night"
end

function TimeController:isDay(): boolean
	return currentPeriod == "day"
end

return TimeController
