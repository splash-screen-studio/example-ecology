--!strict
--[[
    Network

    Central module for client-server communication.
    Creates and exposes RemoteEvents and RemoteFunctions.

    Usage (Server):
        local Network = require(game.ReplicatedStorage.Shared.Network)
        Network.Events.UseItem.OnServerEvent:Connect(function(player, data)
            -- Handle event
        end)

    Usage (Client):
        local Network = require(game.ReplicatedStorage.Shared.Network)
        Network.Events.UseItem:FireServer({ itemId = "apple" })
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(script.Types)

local Network = {}
Network.Types = Types

-- Event definitions: { name, type }
-- type: "event" for RemoteEvent, "function" for RemoteFunction
local EventDefinitions = {
	-- Inventory
	{ name = "UseItem", type = "event" },
	{ name = "DropItem", type = "event" },
	{ name = "PickupItem", type = "event" },

	-- Interactions
	{ name = "Interact", type = "function" }, -- Returns response
	{ name = "InteractComplete", type = "event" }, -- Notify completion

	-- Quests
	{ name = "AcceptQuest", type = "event" },
	{ name = "CompleteQuest", type = "event" },
	{ name = "QuestUpdate", type = "event" }, -- Server -> Client

	-- Ecology
	{ name = "EcoAction", type = "function" }, -- Returns impact result
	{ name = "EcoStateUpdate", type = "event" }, -- Server -> Client broadcast

	-- Discovery
	{ name = "Discovery", type = "event" }, -- Server -> Client notification

	-- Player State
	{ name = "StatUpdate", type = "event" }, -- Server -> Client
	{ name = "UpdateSettings", type = "event" }, -- Client -> Server

	-- Teleport
	{ name = "RequestTeleport", type = "event" },
	{ name = "TeleportReady", type = "event" }, -- Server -> Client countdown

	-- Group
	{ name = "GroupInvite", type = "event" },
	{ name = "GroupResponse", type = "event" },
	{ name = "GroupUpdate", type = "event" }, -- Server -> Client
}

-- Container for events
local NetworkFolder: Folder

local function ensureNetworkFolder(): Folder
	if NetworkFolder then
		return NetworkFolder
	end

	NetworkFolder = ReplicatedStorage:FindFirstChild("Network") :: Folder
	if not NetworkFolder then
		if RunService:IsServer() then
			NetworkFolder = Instance.new("Folder")
			NetworkFolder.Name = "Network"
			NetworkFolder.Parent = ReplicatedStorage
		else
			NetworkFolder = ReplicatedStorage:WaitForChild("Network", 10) :: Folder
			if not NetworkFolder then
				error("[Network] Failed to find Network folder")
			end
		end
	end

	return NetworkFolder
end

local function createOrGetRemote(name: string, remoteType: "event" | "function"): RemoteEvent | RemoteFunction
	local folder = ensureNetworkFolder()
	local existing = folder:FindFirstChild(name)

	if existing then
		return existing :: RemoteEvent | RemoteFunction
	end

	if RunService:IsServer() then
		local remote: RemoteEvent | RemoteFunction
		if remoteType == "event" then
			remote = Instance.new("RemoteEvent")
		else
			remote = Instance.new("RemoteFunction")
		end
		remote.Name = name
		remote.Parent = folder
		return remote
	else
		-- Client waits for server to create
		local remote = folder:WaitForChild(name, 10)
		if not remote then
			error(string.format("[Network] Failed to find remote: %s", name))
		end
		return remote :: RemoteEvent | RemoteFunction
	end
end

-- Initialize network (creates all remotes on server)
function Network.init()
	if not RunService:IsServer() then
		warn("[Network] init() should only be called on server")
		return
	end

	ensureNetworkFolder()

	for _, def in EventDefinitions do
		createOrGetRemote(def.name, def.type)
	end

	print("[Network] Initialized with", #EventDefinitions, "remotes")
end

-- Lazy-loaded event accessors
Network.Events = setmetatable({}, {
	__index = function(self, key)
		for _, def in EventDefinitions do
			if def.name == key then
				local remote = createOrGetRemote(def.name, def.type)
				rawset(self, key, remote)
				return remote
			end
		end
		error(string.format("[Network] Unknown event: %s", key))
	end,
})

-- Alias for RemoteFunctions (clearer API)
Network.Functions = Network.Events

return Network
