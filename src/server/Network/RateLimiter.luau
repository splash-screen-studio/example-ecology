--!strict
--[[
    RateLimiter

    Prevents event spam and potential exploits.
    Tracks request counts per player per event type.

    Usage:
        local RateLimiter = require(script.Parent.RateLimiter)

        if not RateLimiter:check(player, "UseItem") then
            return -- Rate limited
        end
]]

local RateLimiter = {}

-- Configuration per event type
local Limits: { [string]: { requests: number, windowSeconds: number } } = {
	-- Inventory actions (moderate rate)
	UseItem = { requests = 10, windowSeconds = 5 },
	DropItem = { requests = 5, windowSeconds = 5 },
	PickupItem = { requests = 20, windowSeconds = 5 },

	-- Interactions (lower rate - prevent spam clicking)
	Interact = { requests = 5, windowSeconds = 3 },

	-- Quests (very low - rare actions)
	AcceptQuest = { requests = 3, windowSeconds = 10 },
	CompleteQuest = { requests = 3, windowSeconds = 10 },

	-- Ecology actions (moderate)
	EcoAction = { requests = 15, windowSeconds = 10 },

	-- Settings (low - shouldn't change often)
	UpdateSettings = { requests = 5, windowSeconds = 30 },

	-- Teleport (very low)
	RequestTeleport = { requests = 2, windowSeconds = 30 },

	-- Group (low)
	GroupInvite = { requests = 5, windowSeconds = 30 },
	GroupResponse = { requests = 5, windowSeconds = 10 },

	-- Default for unlisted events
	_default = { requests = 30, windowSeconds = 10 },
}

-- Track requests: [player] -> [eventType] -> { count, windowStart }
local RequestTracker: { [Player]: { [string]: { count: number, windowStart: number } } } = {}

-- Services
local Players = game:GetService("Players")

--------------------------------------------------------------------------------
-- CORE
--------------------------------------------------------------------------------

function RateLimiter:check(player: Player, eventType: string): boolean
	local now = os.clock()
	local limit = Limits[eventType] or Limits._default

	-- Initialize player tracking
	if not RequestTracker[player] then
		RequestTracker[player] = {}
	end

	local playerTracker = RequestTracker[player]

	-- Initialize event tracking
	if not playerTracker[eventType] then
		playerTracker[eventType] = {
			count = 0,
			windowStart = now,
		}
	end

	local eventTracker = playerTracker[eventType]

	-- Check if window expired, reset if so
	if now - eventTracker.windowStart >= limit.windowSeconds then
		eventTracker.count = 0
		eventTracker.windowStart = now
	end

	-- Check if over limit
	if eventTracker.count >= limit.requests then
		warn(string.format("[RateLimiter] %s exceeded rate limit for %s", player.Name, eventType))
		return false
	end

	-- Increment count
	eventTracker.count = eventTracker.count + 1
	return true
end

function RateLimiter:reset(player: Player, eventType: string?)
	if not RequestTracker[player] then
		return
	end

	if eventType then
		RequestTracker[player][eventType] = nil
	else
		RequestTracker[player] = {}
	end
end

function RateLimiter:getRemaining(player: Player, eventType: string): number
	local limit = Limits[eventType] or Limits._default

	if not RequestTracker[player] or not RequestTracker[player][eventType] then
		return limit.requests
	end

	local eventTracker = RequestTracker[player][eventType]
	local now = os.clock()

	-- Window expired
	if now - eventTracker.windowStart >= limit.windowSeconds then
		return limit.requests
	end

	return math.max(0, limit.requests - eventTracker.count)
end

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
	RequestTracker[player] = nil
end)

return RateLimiter
