--!strict
--[[
    RobloxFootstepProvider

    Default footstep provider that uses Roblox's built-in footstep system.
    This is the simplest, most reliable approach - just let Roblox handle it.

    Roblox automatically:
    - Plays footstep sounds based on material
    - Handles animation-synced timing
    - Manages sound cleanup

    We just control volume via the Running sound in HumanoidRootPart.
]]

local RobloxFootstepProvider = {}
RobloxFootstepProvider.__index = RobloxFootstepProvider

local Players = game:GetService("Players")

-- Types
local Types = require(script.Parent.FootstepTypes)
export type RobloxFootstepProvider = Types.FootstepProvider

--------------------------------------------------------------------------------
-- PRIVATE
--------------------------------------------------------------------------------

local function getPlayer(): Player
	return Players.LocalPlayer
end

local function getCharacter(): Model?
	return getPlayer().Character
end

local function getRunningSound(): Sound?
	local character = getCharacter()
	if not character then
		return nil
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return nil
	end

	return rootPart:FindFirstChild("Running") :: Sound?
end

--------------------------------------------------------------------------------
-- PROVIDER IMPLEMENTATION
--------------------------------------------------------------------------------

function RobloxFootstepProvider.new(): Types.FootstepProvider
	local self = setmetatable({}, RobloxFootstepProvider)

	self._enabled = true
	self._volume = 1
	self._baseVolume = 0.5 -- Roblox default Running sound volume
	self._characterConnection = nil :: RBXScriptConnection?

	return self :: any
end

function RobloxFootstepProvider:init()
	local player = getPlayer()

	-- Handle current character
	if player.Character then
		self:_onCharacterAdded(player.Character)
	end

	-- Handle future characters
	self._characterConnection = player.CharacterAdded:Connect(function(character)
		self:_onCharacterAdded(character)
	end)

	print("[RobloxFootstepProvider] Using default Roblox footstep sounds")
end

function RobloxFootstepProvider:_onCharacterAdded(character: Model)
	-- Wait for Running sound to be created
	task.spawn(function()
		local rootPart = character:WaitForChild("HumanoidRootPart", 10)
		if not rootPart then
			return
		end

		-- Wait a bit for sounds to be added by Roblox
		task.wait(0.2)

		-- Apply current volume settings
		self:_applyVolume()
	end)
end

function RobloxFootstepProvider:_applyVolume()
	local sound = getRunningSound()
	if sound then
		if self._enabled then
			sound.Volume = self._baseVolume * self._volume
		else
			sound.Volume = 0
		end
	end
end

function RobloxFootstepProvider:destroy()
	if self._characterConnection then
		self._characterConnection:Disconnect()
		self._characterConnection = nil
	end
end

function RobloxFootstepProvider:setEnabled(enabled: boolean)
	self._enabled = enabled
	self:_applyVolume()
end

function RobloxFootstepProvider:isEnabled(): boolean
	return self._enabled
end

function RobloxFootstepProvider:setVolume(volume: number)
	self._volume = math.clamp(volume, 0, 2)
	self:_applyVolume()
end

function RobloxFootstepProvider:getVolume(): number
	return self._volume
end

function RobloxFootstepProvider:getLastMaterial(): Enum.Material?
	-- Roblox doesn't expose current material, return nil
	return nil
end

return RobloxFootstepProvider
