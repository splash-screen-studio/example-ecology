--!strict
--[[
    Effects Module

    Client-side visual effects including automatic flashlight and pickup feedback.

    Usage:
        local Effects = require(script.Parent.Effects)
        Effects:init()
        Effects.Pickup:playPickupEffect(itemId, position, targetModel)
]]

local Effects = {}

-- Sub-modules
local FlashlightController = require(script.FlashlightController)
local PickupEffects = require(script.PickupEffects)

-- State
local initialized = false

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function Effects:init()
	if initialized then
		return
	end
	initialized = true

	-- Initialize flashlight system
	FlashlightController:init()

	-- Initialize pickup effects system
	PickupEffects:init()

	print("[Effects] Initialized")
end

-- Re-export sub-modules for direct access
Effects.Flashlight = FlashlightController
Effects.Pickup = PickupEffects

return Effects
