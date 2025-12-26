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

-- Client network (when needed)
-- local ClientNetwork = require(Shared.Network.ClientNetwork)
-- ClientNetwork:init()

print("Client started:", PlaceConfig.getCurrent().name)

-- Export to _G for debugging
_G.AudioController = AudioController
