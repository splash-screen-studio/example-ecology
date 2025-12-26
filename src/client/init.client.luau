--!strict
--[[
    Client Entry Point

    Initializes all client-side systems.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for shared modules to load
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PlaceConfig = require(Shared.PlaceConfig)

-- Initialize client systems
local AudioController = require(script.Audio)
AudioController:init()

local TimeController = require(script.Time)
TimeController:init()

local HUD = require(script.HUD)
HUD:init()

local Effects = require(script.Effects)
Effects:init()

print("Client started:", PlaceConfig.getCurrent().name)

-- Export to _G for debugging
_G.AudioController = AudioController
_G.TimeController = TimeController
_G.HUD = HUD
_G.Effects = Effects
