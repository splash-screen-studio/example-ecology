--!strict
--[[
    ClientNetwork

    Client-side API for network communication.
    Provides clean, typed methods for all server interactions.

    Usage:
        local ClientNetwork = require(script.Parent.ClientNetwork)

        -- Fire-and-forget events
        ClientNetwork:useItem("apple")
        ClientNetwork:dropItem("stone", 5)

        -- Request-response functions
        local result = ClientNetwork:interact("npc_123", "talk")
        if result.success then
            print(result.data.dialogueData)
        end

        -- Listen to server pushes
        ClientNetwork:onStatUpdate(function(stats)
            print("Hunger:", stats.hunger)
        end)
]]

local ClientNetwork = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local Network = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"))
local Types = Network.Types

-- Callback storage
local callbacks: { [string]: { (any) -> () } } = {}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

local function fireEvent(eventName: string, data: any)
	local event = Network.Events[eventName]
	if event then
		event:FireServer(data)
	else
		warn("[ClientNetwork] Unknown event:", eventName)
	end
end

local function invokeFunction(functionName: string, data: any): any
	local func = Network.Functions[functionName]
	if func then
		return func:InvokeServer(data)
	else
		warn("[ClientNetwork] Unknown function:", functionName)
		return { success = false, error = "Unknown function" }
	end
end

local function registerCallback(eventName: string, callback: (any) -> ())
	if not callbacks[eventName] then
		callbacks[eventName] = {}

		-- Set up listener
		local event = Network.Events[eventName]
		if event then
			event.OnClientEvent:Connect(function(data)
				for _, cb in callbacks[eventName] do
					task.spawn(cb, data)
				end
			end)
		end
	end

	table.insert(callbacks[eventName], callback)
end

--------------------------------------------------------------------------------
-- INVENTORY API
--------------------------------------------------------------------------------

function ClientNetwork:useItem(itemId: string, targetId: string?)
	fireEvent("UseItem", {
		itemId = itemId,
		targetId = targetId,
	})
end

function ClientNetwork:dropItem(itemId: string, quantity: number)
	fireEvent("DropItem", {
		itemId = itemId,
		quantity = quantity,
	})
end

function ClientNetwork:pickupItem(objectId: string)
	fireEvent("PickupItem", {
		objectId = objectId,
	})
end

function ClientNetwork:onPickupEffect(callback: (Types.PickupEffectPayload) -> ())
	registerCallback("PickupEffect", callback)
end

--------------------------------------------------------------------------------
-- INTERACTION API
--------------------------------------------------------------------------------

function ClientNetwork:interact(targetId: string, interactionType: string): Types.InteractResponse
	return invokeFunction("Interact", {
		targetId = targetId,
		interactionType = interactionType,
	})
end

--------------------------------------------------------------------------------
-- QUEST API
--------------------------------------------------------------------------------

function ClientNetwork:acceptQuest(questId: string, giverId: string?)
	fireEvent("AcceptQuest", {
		questId = questId,
		giverId = giverId,
	})
end

function ClientNetwork:completeQuest(questId: string)
	fireEvent("CompleteQuest", {
		questId = questId,
	})
end

function ClientNetwork:onQuestUpdate(callback: (Types.QuestUpdatePayload) -> ())
	registerCallback("QuestUpdate", callback)
end

--------------------------------------------------------------------------------
-- ECOLOGY API
--------------------------------------------------------------------------------

function ClientNetwork:performEcoAction(actionType: string, targetId: string?, position: Vector3?): Types.EcoActionResponse
	return invokeFunction("EcoAction", {
		actionType = actionType,
		targetId = targetId,
		position = position,
	})
end

function ClientNetwork:onEcoStateUpdate(callback: (any) -> ())
	registerCallback("EcoStateUpdate", callback)
end

--------------------------------------------------------------------------------
-- DISCOVERY API
--------------------------------------------------------------------------------

function ClientNetwork:onDiscovery(callback: (Types.DiscoveryPayload) -> ())
	registerCallback("Discovery", callback)
end

--------------------------------------------------------------------------------
-- PLAYER STATE API
--------------------------------------------------------------------------------

function ClientNetwork:onStatUpdate(callback: (Types.StatUpdatePayload) -> ())
	registerCallback("StatUpdate", callback)
end

function ClientNetwork:updateSettings(settings: Types.SettingsUpdateRequest)
	fireEvent("UpdateSettings", settings)
end

--------------------------------------------------------------------------------
-- TELEPORT API
--------------------------------------------------------------------------------

function ClientNetwork:requestTeleport(destination: string, groupMembers: { number }?)
	fireEvent("RequestTeleport", {
		destination = destination,
		groupMembers = groupMembers,
	})
end

function ClientNetwork:onTeleportReady(callback: (any) -> ())
	registerCallback("TeleportReady", callback)
end

--------------------------------------------------------------------------------
-- GROUP API
--------------------------------------------------------------------------------

function ClientNetwork:inviteToGroup(targetUserId: number)
	fireEvent("GroupInvite", {
		targetUserId = targetUserId,
	})
end

function ClientNetwork:respondToGroupInvite(leaderId: number, accepted: boolean)
	fireEvent("GroupResponse", {
		leaderId = leaderId,
		accepted = accepted,
	})
end

function ClientNetwork:onGroupUpdate(callback: (any) -> ())
	registerCallback("GroupUpdate", callback)
end

return ClientNetwork
