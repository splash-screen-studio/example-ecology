--!strict
--[[
    Footsteps Module

    SOLID/APIE component wrapper for footstep audio systems.
    Supports swapping between different footstep providers via configuration.

    Architecture (Open/Closed Principle):
    - FootstepTypes: Interface contract all providers must implement
    - RobloxFootstepProvider: Uses default Roblox footstep sounds
    - CustomFootstepProvider: Material-aware with hysteresis algorithm
    - This controller: Loads configured provider and delegates to it

    Usage:
        local Footsteps = require(script.Parent.Footsteps)
        Footsteps:init()  -- Uses configured provider (default: "roblox")
        Footsteps:setVolume(0.5)

    Configuration:
        Change DEFAULT_PROVIDER to switch implementations:
        - "roblox": Simple, reliable Roblox default sounds
        - "custom": Material-aware with hysteresis (more complex)
]]

local FootstepController = {}

-- Types
local Types = require(script.FootstepTypes)
export type FootstepProvider = Types.FootstepProvider
export type FootstepConfig = Types.FootstepConfig

-- Providers (lazy loaded)
local providers: { [string]: () -> FootstepProvider } = {
	roblox = function()
		return require(script.RobloxFootstepProvider).new()
	end,
	custom = function()
		return require(script.CustomFootstepProvider).new()
	end,
}

-- Configuration
-- Change this to switch footstep implementations
local DEFAULT_PROVIDER = "roblox"

-- State
local activeProvider: FootstepProvider? = nil
local isInitialized = false

--------------------------------------------------------------------------------
-- PROVIDER MANAGEMENT
--------------------------------------------------------------------------------

--[[
    Get a provider factory by name.
    Returns nil if provider doesn't exist.
]]
function FootstepController:getProviderFactory(name: string): (() -> FootstepProvider)?
	return providers[name]
end

--[[
    Register a new provider factory.
    Allows extending with custom implementations.
    (Open/Closed Principle - open for extension)
]]
function FootstepController:registerProvider(name: string, factory: () -> FootstepProvider)
	providers[name] = factory
end

--[[
    Get the currently active provider instance.
    Returns nil if not initialized.
]]
function FootstepController:getActiveProvider(): FootstepProvider?
	return activeProvider
end

--[[
    Get list of available provider names.
]]
function FootstepController:getAvailableProviders(): { string }
	local names = {}
	for name in providers do
		table.insert(names, name)
	end
	return names
end

--------------------------------------------------------------------------------
-- PUBLIC API (Delegates to active provider)
--------------------------------------------------------------------------------

function FootstepController:setEnabled(enabled: boolean)
	if activeProvider then
		activeProvider:setEnabled(enabled)
	end
end

function FootstepController:isEnabled(): boolean
	if activeProvider then
		return activeProvider:isEnabled()
	end
	return false
end

function FootstepController:setVolume(volume: number)
	if activeProvider then
		activeProvider:setVolume(volume)
	end
end

function FootstepController:getVolume(): number
	if activeProvider then
		return activeProvider:getVolume()
	end
	return 1
end

function FootstepController:getLastMaterial(): Enum.Material?
	if activeProvider then
		return activeProvider:getLastMaterial()
	end
	return nil
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

--[[
    Initialize with a specific provider.
    If providerName is nil, uses DEFAULT_PROVIDER.
]]
function FootstepController:init(providerName: string?)
	if isInitialized then
		warn("[FootstepController] Already initialized")
		return
	end

	local name = providerName or DEFAULT_PROVIDER
	local factory = providers[name]

	if not factory then
		warn("[FootstepController] Unknown provider: " .. name .. ", falling back to 'roblox'")
		factory = providers.roblox
		name = "roblox"
	end

	-- Create and initialize provider
	activeProvider = factory()
	activeProvider:init()

	isInitialized = true
	print("[FootstepController] Initialized with provider: " .. name)
end

--[[
    Switch to a different provider at runtime.
    Destroys current provider and initializes new one.
]]
function FootstepController:switchProvider(providerName: string)
	local factory = providers[providerName]
	if not factory then
		warn("[FootstepController] Unknown provider: " .. providerName)
		return
	end

	-- Store current settings
	local wasEnabled = self:isEnabled()
	local volume = self:getVolume()

	-- Destroy current provider
	if activeProvider then
		activeProvider:destroy()
	end

	-- Create and initialize new provider
	activeProvider = factory()
	activeProvider:init()

	-- Restore settings
	activeProvider:setEnabled(wasEnabled)
	activeProvider:setVolume(volume)

	print("[FootstepController] Switched to provider: " .. providerName)
end

function FootstepController:destroy()
	if activeProvider then
		activeProvider:destroy()
		activeProvider = nil
	end
	isInitialized = false
end

return FootstepController
