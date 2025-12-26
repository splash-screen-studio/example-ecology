--!strict
--[[
    Validators

    Input validation for network requests.
    NEVER trust client data - validate everything.

    Usage:
        local Validators = require(script.Parent.Validators)

        local isValid, cleanData = Validators.validateUseItem(data)
        if not isValid then
            return { success = false, error = "Invalid request" }
        end
]]

local Validators = {}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function isString(value: any): boolean
	return type(value) == "string"
end

local function isNumber(value: any): boolean
	return type(value) == "number"
end

local function isBoolean(value: any): boolean
	return type(value) == "boolean"
end

local function isTable(value: any): boolean
	return type(value) == "table"
end

local function isValidString(value: any, minLen: number?, maxLen: number?): boolean
	if not isString(value) then
		return false
	end
	local str = value :: string
	minLen = minLen or 1
	maxLen = maxLen or 100

	return #str >= minLen and #str <= maxLen
end

local function isPositiveNumber(value: any): boolean
	return isNumber(value) and value > 0
end

local function isValidVector3(value: any): boolean
	return typeof(value) == "Vector3"
end

local function sanitizeString(value: string, maxLen: number?): string
	maxLen = maxLen or 100
	-- Remove control characters, limit length
	local sanitized = value:gsub("[%c]", ""):sub(1, maxLen)
	return sanitized
end

--------------------------------------------------------------------------------
-- INVENTORY VALIDATORS
--------------------------------------------------------------------------------

function Validators.validateUseItem(data: any): (boolean, { itemId: string, targetId: string? }?)
	if not isTable(data) then
		return false, nil
	end

	local itemId = data.itemId
	local targetId = data.targetId

	if not isValidString(itemId, 1, 50) then
		return false, nil
	end

	if targetId ~= nil and not isValidString(targetId, 1, 50) then
		return false, nil
	end

	return true, {
		itemId = sanitizeString(itemId, 50),
		targetId = if targetId then sanitizeString(targetId, 50) else nil,
	}
end

function Validators.validateDropItem(data: any): (boolean, { itemId: string, quantity: number }?)
	if not isTable(data) then
		return false, nil
	end

	local itemId = data.itemId
	local quantity = data.quantity

	if not isValidString(itemId, 1, 50) then
		return false, nil
	end

	if not isPositiveNumber(quantity) or quantity > 9999 then
		return false, nil
	end

	return true, {
		itemId = sanitizeString(itemId, 50),
		quantity = math.floor(quantity),
	}
end

function Validators.validatePickupItem(data: any): (boolean, { objectId: string }?)
	if not isTable(data) then
		return false, nil
	end

	local objectId = data.objectId

	if not isValidString(objectId, 1, 100) then
		return false, nil
	end

	return true, {
		objectId = sanitizeString(objectId, 100),
	}
end

--------------------------------------------------------------------------------
-- INTERACTION VALIDATORS
--------------------------------------------------------------------------------

function Validators.validateInteract(data: any): (boolean, { targetId: string?, interactionType: string, responseIndex: number? }?)
	if not isTable(data) then
		return false, nil
	end

	local interactionType = data.interactionType

	-- Valid interaction types
	local validTypes = {
		talk = true,
		examine = true,
		use = true,
		feed = true,
		pet = true,
		dialogue_response = true,
		dialogue_close = true,
	}

	if not isValidString(interactionType, 1, 30) or not validTypes[interactionType] then
		return false, nil
	end

	-- Dialogue interactions don't require targetId
	if interactionType == "dialogue_response" then
		local responseIndex = data.responseIndex
		if type(responseIndex) ~= "number" or responseIndex < 1 or responseIndex > 10 then
			return false, nil
		end
		return true, {
			interactionType = sanitizeString(interactionType, 30),
			responseIndex = math.floor(responseIndex),
		}
	end

	if interactionType == "dialogue_close" then
		return true, {
			interactionType = sanitizeString(interactionType, 30),
		}
	end

	-- Regular interactions require targetId
	local targetId = data.targetId
	if not isValidString(targetId, 1, 100) then
		return false, nil
	end

	return true, {
		targetId = sanitizeString(targetId, 100),
		interactionType = sanitizeString(interactionType, 30),
	}
end

--------------------------------------------------------------------------------
-- QUEST VALIDATORS
--------------------------------------------------------------------------------

function Validators.validateAcceptQuest(data: any): (boolean, { questId: string, giverId: string? }?)
	if not isTable(data) then
		return false, nil
	end

	local questId = data.questId
	local giverId = data.giverId

	if not isValidString(questId, 1, 50) then
		return false, nil
	end

	if giverId ~= nil and not isValidString(giverId, 1, 50) then
		return false, nil
	end

	return true, {
		questId = sanitizeString(questId, 50),
		giverId = if giverId then sanitizeString(giverId, 50) else nil,
	}
end

function Validators.validateCompleteQuest(data: any): (boolean, { questId: string }?)
	if not isTable(data) then
		return false, nil
	end

	local questId = data.questId

	if not isValidString(questId, 1, 50) then
		return false, nil
	end

	return true, {
		questId = sanitizeString(questId, 50),
	}
end

--------------------------------------------------------------------------------
-- ECOLOGY VALIDATORS
--------------------------------------------------------------------------------

function Validators.validateEcoAction(data: any): (boolean, { actionType: string, targetId: string?, position: Vector3? }?)
	if not isTable(data) then
		return false, nil
	end

	local actionType = data.actionType
	local targetId = data.targetId
	local position = data.position

	local validActions = { plant = true, water = true, feed = true, clean = true, heal = true, remove = true }
	if not isValidString(actionType, 1, 20) or not validActions[actionType] then
		return false, nil
	end

	if targetId ~= nil and not isValidString(targetId, 1, 50) then
		return false, nil
	end

	if position ~= nil and not isValidVector3(position) then
		return false, nil
	end

	return true, {
		actionType = sanitizeString(actionType, 20),
		targetId = if targetId then sanitizeString(targetId, 50) else nil,
		position = position,
	}
end

--------------------------------------------------------------------------------
-- SETTINGS VALIDATORS
--------------------------------------------------------------------------------

function Validators.validateUpdateSettings(data: any): (boolean, { musicVolume: number?, sfxVolume: number?, showTutorials: boolean? }?)
	if not isTable(data) then
		return false, nil
	end

	local result: { musicVolume: number?, sfxVolume: number?, showTutorials: boolean? } = {}

	if data.musicVolume ~= nil then
		if not isNumber(data.musicVolume) or data.musicVolume < 0 or data.musicVolume > 1 then
			return false, nil
		end
		result.musicVolume = data.musicVolume
	end

	if data.sfxVolume ~= nil then
		if not isNumber(data.sfxVolume) or data.sfxVolume < 0 or data.sfxVolume > 1 then
			return false, nil
		end
		result.sfxVolume = data.sfxVolume
	end

	if data.showTutorials ~= nil then
		if not isBoolean(data.showTutorials) then
			return false, nil
		end
		result.showTutorials = data.showTutorials
	end

	return true, result
end

--------------------------------------------------------------------------------
-- TELEPORT VALIDATORS
--------------------------------------------------------------------------------

function Validators.validateTeleportRequest(data: any): (boolean, { destination: string, groupMembers: { number }? }?)
	if not isTable(data) then
		return false, nil
	end

	local destination = data.destination
	local groupMembers = data.groupMembers

	-- Valid destinations
	local validDestinations = { VerdantBasin = true, Driftplain = true }
	if not isValidString(destination, 1, 50) or not validDestinations[destination] then
		return false, nil
	end

	-- Validate group members if provided
	local cleanMembers: { number }? = nil
	if groupMembers ~= nil then
		if not isTable(groupMembers) then
			return false, nil
		end
		cleanMembers = {}
		for _, userId in groupMembers do
			if not isNumber(userId) or userId <= 0 then
				return false, nil
			end
			table.insert(cleanMembers, math.floor(userId))
		end
		-- Limit group size
		if #cleanMembers > 8 then
			return false, nil
		end
	end

	return true, {
		destination = destination,
		groupMembers = cleanMembers,
	}
end

return Validators
