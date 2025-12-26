--!strict
--[[
    FootstepTypes

    Type definitions and interface contract for footstep providers.
    Follows Interface Segregation principle - small, focused interface.

    Any footstep provider must implement the FootstepProvider interface.
]]

export type FootstepProvider = {
	-- Initialize the provider (called once on startup)
	init: (self: FootstepProvider) -> (),

	-- Cleanup (called on destroy)
	destroy: (self: FootstepProvider) -> (),

	-- Enable/disable footstep sounds
	setEnabled: (self: FootstepProvider, enabled: boolean) -> (),
	isEnabled: (self: FootstepProvider) -> boolean,

	-- Volume control (0-2 range, 1 = normal)
	setVolume: (self: FootstepProvider, volume: number) -> (),
	getVolume: (self: FootstepProvider) -> number,

	-- Debug info (optional, for diagnostics)
	getLastMaterial: (self: FootstepProvider) -> Enum.Material?,
}

-- Provider factory function type
export type FootstepProviderFactory = () -> FootstepProvider

-- Configuration for which provider to use
export type FootstepConfig = {
	-- Provider name: "roblox" (default) or "custom"
	provider: string,
}

return {
	-- Default configuration
	DefaultConfig = {
		provider = "roblox", -- Use Roblox default footsteps by default
	} :: FootstepConfig,
}
