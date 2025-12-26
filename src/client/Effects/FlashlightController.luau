--!strict
--[[
    FlashlightController

    Automatic darkness-activated flashlight system.
    Uses hysteresis to prevent flickering during ambient light transitions.

    The flashlight activates when ambient light drops below threshold for a sustained
    period, and deactivates when light rises above a higher threshold. This prevents
    rapid on/off cycling during dawn/dusk transitions or brief shadows.

    Usage:
        local FlashlightController = require(script.Parent.FlashlightController)
        FlashlightController:init()
]]

local FlashlightController = {}

-- Services
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies (lazy loaded)
local TimeController: any = nil

-- Configuration
local CONFIG = {
	-- Hysteresis thresholds (ambient light 0-1 scale)
	-- Night preset OutdoorAmbient RGB(50,50,70) = ~0.20 luminance
	-- Day preset OutdoorAmbient RGB(128,128,128) = ~0.50 luminance
	TURN_ON_THRESHOLD = 0.25, -- Turn ON when ambient < this (triggers during night)
	TURN_OFF_THRESHOLD = 0.40, -- Turn OFF when ambient > this (triggers during day)
	HYSTERESIS_DURATION = 1.0, -- Seconds threshold must be sustained

	-- Light properties
	SPOTLIGHT_ANGLE = 35, -- Cone angle in degrees
	SPOTLIGHT_RANGE = 50, -- Range in studs
	SPOTLIGHT_COLOR = Color3.fromRGB(255, 244, 229), -- Warm white/slight yellow
	SPOTLIGHT_BRIGHTNESS = 1.5,

	-- Fade transitions
	FADE_DURATION = 0.4, -- Seconds for fade in/out

	-- Update frequency
	SAMPLE_INTERVAL = 0.1, -- How often to sample ambient light
}

-- State
local initialized = false
local isFlashlightOn = false
local spotlight: SpotLight? = nil
local spotlightAttachment: Attachment? = nil

-- Hysteresis tracking
local darkDuration = 0 -- Time spent below turn-on threshold
local brightDuration = 0 -- Time spent above turn-off threshold
local lastSampleTime = 0

-- Tween for smooth transitions
local currentTween: Tween? = nil

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not TimeController then
		local client = Players.LocalPlayer:WaitForChild("PlayerScripts")
		-- Try to find TimeController if it exists as a module
		local success, result = pcall(function()
			return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"))
		end)
		if success then
			-- TimeController is typically in client/Time
			-- We'll access time period directly from Lighting instead
		end
	end
end

--[[
    Calculate the current ambient light level (0-1 scale).

    Uses multiple signals for robust darkness detection:
    1. Lighting.Ambient - direct ambient color
    2. Lighting.OutdoorAmbient - outdoor environment color
    3. Lighting.Brightness - overall scene brightness
    4. Lighting.ClockTime - time of day (night is inherently darker)

    This multi-signal approach is more robust than relying on any single value,
    as lighting presets may vary between places.
]]
local function getAmbientLightLevel(): number
	-- Calculate perceived luminance using standard coefficients
	-- (human eye is most sensitive to green, then red, then blue)
	local function luminance(color: Color3): number
		return 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
	end

	local ambient = Lighting.Ambient
	local outdoor = Lighting.OutdoorAmbient

	local ambientLum = luminance(ambient)
	local outdoorLum = luminance(outdoor)

	-- Weight ambient luminance higher as it's the "true" darkness indicator
	-- OutdoorAmbient can remain somewhat bright even at night for sky reflections
	local colorLuminance = ambientLum * 0.7 + outdoorLum * 0.3

	-- Factor in Lighting.Brightness (typical range 0-3)
	-- Night brightness ~0.3, Day brightness ~2.0+
	local brightnessContribution = math.clamp(Lighting.Brightness / 3, 0, 1)

	-- Factor in time of day (ClockTime 0-24)
	-- This provides an additional signal independent of lighting presets
	local clockTime = Lighting.ClockTime
	local timeOfDayFactor: number
	if clockTime >= 7 and clockTime < 17 then
		-- Full daylight (7 AM - 5 PM)
		timeOfDayFactor = 1.0
	elseif clockTime >= 19 or clockTime < 5 then
		-- Night (7 PM - 5 AM)
		timeOfDayFactor = 0.1
	elseif clockTime >= 5 and clockTime < 7 then
		-- Dawn transition (5 AM - 7 AM)
		timeOfDayFactor = (clockTime - 5) / 2 * 0.9 + 0.1
	else
		-- Dusk transition (5 PM - 7 PM)
		timeOfDayFactor = 1.0 - ((clockTime - 17) / 2 * 0.9)
	end

	-- Combine signals with weights
	-- Color luminance: 40%, Brightness: 30%, Time of day: 30%
	local combinedLevel = colorLuminance * 0.4 + brightnessContribution * 0.3 + timeOfDayFactor * 0.3

	return math.clamp(combinedLevel, 0, 1)
end

--[[
    Check if it's currently night time based on ClockTime.
    This provides an additional signal for darkness detection.
]]
local function isNightTime(): boolean
	local clockTime = Lighting.ClockTime
	-- Night is roughly 19:00 to 5:00
	return clockTime >= 19 or clockTime < 5
end

--------------------------------------------------------------------------------
-- SPOTLIGHT MANAGEMENT
--------------------------------------------------------------------------------

--[[
    Create the spotlight and attach it to the player's head.
    The light points forward from the character's face direction.
]]
local function createSpotlight(): boolean
	local player = Players.LocalPlayer
	local character = player.Character
	if not character then
		return false
	end

	local head = character:FindFirstChild("Head")
	if not head then
		return false
	end

	-- Clean up existing spotlight if any
	if spotlight then
		spotlight:Destroy()
		spotlight = nil
	end
	if spotlightAttachment then
		spotlightAttachment:Destroy()
		spotlightAttachment = nil
	end

	-- Create attachment on head (front-facing)
	spotlightAttachment = Instance.new("Attachment")
	spotlightAttachment.Name = "FlashlightAttachment"
	-- Position slightly in front of face
	spotlightAttachment.Position = Vector3.new(0, 0.2, -0.5)
	spotlightAttachment.Parent = head

	-- Create the spotlight
	spotlight = Instance.new("SpotLight")
	spotlight.Name = "Flashlight"
	spotlight.Angle = CONFIG.SPOTLIGHT_ANGLE
	spotlight.Range = CONFIG.SPOTLIGHT_RANGE
	spotlight.Color = CONFIG.SPOTLIGHT_COLOR
	spotlight.Brightness = 0 -- Start off, will fade in
	spotlight.Face = Enum.NormalId.Front
	spotlight.Shadows = true
	spotlight.Parent = spotlightAttachment

	return true
end

--[[
    Smoothly fade the spotlight to target brightness.
]]
local function fadeSpotlight(targetBrightness: number, duration: number)
	if not spotlight then
		return
	end

	-- Cancel any existing tween
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end

	-- Create tween for smooth transition
	local tweenInfo = TweenInfo.new(
		duration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut
	)

	currentTween = TweenService:Create(spotlight, tweenInfo, {
		Brightness = targetBrightness,
	})
	currentTween:Play()
end

--[[
    Turn the flashlight on with a smooth fade.
]]
local function turnOn()
	if isFlashlightOn then
		return
	end

	-- Ensure spotlight exists
	if not spotlight or not spotlight.Parent then
		if not createSpotlight() then
			return -- Can't create spotlight, player may not have character
		end
	end

	isFlashlightOn = true
	fadeSpotlight(CONFIG.SPOTLIGHT_BRIGHTNESS, CONFIG.FADE_DURATION)
	-- Debug output (can be removed in production)
	-- print("[FlashlightController] Flashlight ON")
end

--[[
    Turn the flashlight off with a smooth fade.
]]
local function turnOff()
	if not isFlashlightOn then
		return
	end

	isFlashlightOn = false
	fadeSpotlight(0, CONFIG.FADE_DURATION)
	-- Debug output (can be removed in production)
	-- print("[FlashlightController] Flashlight OFF")
end

--------------------------------------------------------------------------------
-- HYSTERESIS LOGIC
--------------------------------------------------------------------------------

--[[
    Update the hysteresis state machine based on current ambient light.
    This prevents flickering by requiring sustained light changes before toggling.

    State transitions:
    - OFF -> ON: Ambient light < TURN_ON_THRESHOLD for > HYSTERESIS_DURATION
    - ON -> OFF: Ambient light > TURN_OFF_THRESHOLD for > HYSTERESIS_DURATION

    The different thresholds (0.2 vs 0.35) create a "dead zone" that prevents
    rapid cycling when light hovers near a single threshold value.
]]
local function updateHysteresis(dt: number)
	local ambientLevel = getAmbientLightLevel()

	if isFlashlightOn then
		-- Currently ON: check if we should turn OFF
		if ambientLevel > CONFIG.TURN_OFF_THRESHOLD then
			brightDuration = brightDuration + dt
			darkDuration = 0 -- Reset dark counter

			if brightDuration >= CONFIG.HYSTERESIS_DURATION then
				turnOff()
				brightDuration = 0
			end
		else
			-- Not bright enough to turn off, reset counter
			brightDuration = 0
		end
	else
		-- Currently OFF: check if we should turn ON
		if ambientLevel < CONFIG.TURN_ON_THRESHOLD then
			darkDuration = darkDuration + dt
			brightDuration = 0 -- Reset bright counter

			if darkDuration >= CONFIG.HYSTERESIS_DURATION then
				turnOn()
				darkDuration = 0
			end
		else
			-- Not dark enough to turn on, reset counter
			darkDuration = 0
		end
	end
end

--------------------------------------------------------------------------------
-- CHARACTER HANDLING
--------------------------------------------------------------------------------

local function onCharacterAdded(character: Model)
	-- Wait for head to load
	local head = character:WaitForChild("Head", 5)
	if not head then
		return
	end

	-- Recreate spotlight if it was on
	if isFlashlightOn then
		if createSpotlight() then
			-- Immediately set to on state (no fade since we're restoring state)
			if spotlight then
				spotlight.Brightness = CONFIG.SPOTLIGHT_BRIGHTNESS
			end
		end
	end
end

local function onCharacterRemoving(_character: Model)
	-- Clean up spotlight references (Instance will be destroyed with character)
	spotlight = nil
	spotlightAttachment = nil

	-- Cancel any active tween
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end
end

--------------------------------------------------------------------------------
-- UPDATE LOOP
--------------------------------------------------------------------------------

local function update(dt: number)
	lastSampleTime = lastSampleTime + dt

	if lastSampleTime >= CONFIG.SAMPLE_INTERVAL then
		lastSampleTime = 0
		updateHysteresis(CONFIG.SAMPLE_INTERVAL)
	end
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

--[[
    Initialize the flashlight controller.
    Sets up character events and starts the ambient light monitoring loop.
]]
function FlashlightController:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()

	local player = Players.LocalPlayer

	-- Handle current character
	if player.Character then
		onCharacterAdded(player.Character)
	end

	-- Handle future characters (respawn)
	player.CharacterAdded:Connect(onCharacterAdded)
	player.CharacterRemoving:Connect(onCharacterRemoving)

	-- Start monitoring loop
	RunService.Heartbeat:Connect(update)

	print("[FlashlightController] Initialized")
end

--[[
    Check if the flashlight is currently on.
]]
function FlashlightController:isOn(): boolean
	return isFlashlightOn
end

--[[
    Get the current ambient light level (for debugging).
]]
function FlashlightController:getAmbientLevel(): number
	return getAmbientLightLevel()
end

--[[
    Force the flashlight on (override automatic behavior).
    Useful for testing or manual override.
]]
function FlashlightController:forceOn()
	turnOn()
	-- Reset hysteresis to prevent immediate auto-off
	brightDuration = 0
end

--[[
    Force the flashlight off (override automatic behavior).
]]
function FlashlightController:forceOff()
	turnOff()
	-- Reset hysteresis to prevent immediate auto-on
	darkDuration = 0
end

--[[
    Get the current configuration (for debugging).
]]
function FlashlightController:getConfig()
	return {
		turnOnThreshold = CONFIG.TURN_ON_THRESHOLD,
		turnOffThreshold = CONFIG.TURN_OFF_THRESHOLD,
		hysteresisDuration = CONFIG.HYSTERESIS_DURATION,
		spotlightAngle = CONFIG.SPOTLIGHT_ANGLE,
		spotlightRange = CONFIG.SPOTLIGHT_RANGE,
	}
end

return FlashlightController
