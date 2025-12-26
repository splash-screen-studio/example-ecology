--!strict
--[[
    NPCService

    Manages all NPCs in the game.
    Features:
    - Object pooling for performance
    - Spawn control tied to EcologyService populations
    - LOD system for distant NPCs
    - AI state machine per NPC

    Usage:
        local NPCService = require(script.Parent.NPCService)
        NPCService:init()
]]

local NPCService = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local Types = require(script.Parent.Types)
local NPCDefinitions = require(script.Parent.NPCDefinitions)

-- Loaded after init
local EcologyService: any

-- Configuration
local CONFIG = {
	UPDATE_INTERVAL = 0.1, -- Seconds between AI updates
	SPAWN_INTERVAL = 2, -- Seconds between spawn checks
	LOD_DISTANCE_1 = 100, -- Reduced updates beyond this
	LOD_DISTANCE_2 = 200, -- Minimal updates beyond this
	DESPAWN_DISTANCE = 300, -- Remove NPCs beyond this from all players
	MAX_NPCS_PER_REGION = 50, -- Hard limit per region
	POOL_SIZE_PER_TYPE = 20, -- Pre-allocated models per NPC type
	POPULATION_TO_NPC_RATIO = 0.1, -- 10% of population becomes visible NPCs
}

-- State
local activeNPCs: { [string]: Types.NPCInstance } = {}
local spawnPoints: { [string]: Types.SpawnPoint } = {}
local npcPools: { [string]: { Model } } = {} -- Pooled models by definition ID
local npcFolder: Folder?
local isRunning = false
local lastSpawnCheck = 0
local nextNPCId = 1

--------------------------------------------------------------------------------
-- OBJECT POOLING
--------------------------------------------------------------------------------

local function createNPCModel(definitionId: string): Model?
	local def = NPCDefinitions.get(definitionId)
	if not def then
		return nil
	end

	-- Create placeholder model (replace with actual models later)
	local model = Instance.new("Model")
	model.Name = def.name

	-- Create simple body
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 2, 3) * def.scale
	body.BrickColor = BrickColor.new("Brown")
	body.Material = Enum.Material.SmoothPlastic
	body.CanCollide = true
	body.Anchored = false
	body.Parent = model

	-- Create head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.5, 1.5, 1.5) * def.scale
	head.BrickColor = BrickColor.new("Reddish brown")
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.Parent = model

	local headWeld = Instance.new("WeldConstraint")
	headWeld.Part0 = body
	headWeld.Part1 = head
	headWeld.Parent = head

	head.Position = body.Position + Vector3.new(1.5 * def.scale, 0.5 * def.scale, 0)

	model.PrimaryPart = body

	-- Add Humanoid for animations (optional)
	-- local humanoid = Instance.new("Humanoid")
	-- humanoid.Parent = model

	return model
end

local function getFromPool(definitionId: string): Model?
	if not npcPools[definitionId] then
		npcPools[definitionId] = {}
	end

	local pool = npcPools[definitionId]
	if #pool > 0 then
		return table.remove(pool)
	end

	-- Pool empty, create new
	return createNPCModel(definitionId)
end

local function returnToPool(definitionId: string, model: Model)
	if not npcPools[definitionId] then
		npcPools[definitionId] = {}
	end

	local pool = npcPools[definitionId]
	if #pool < CONFIG.POOL_SIZE_PER_TYPE then
		model.Parent = nil
		table.insert(pool, model)
	else
		model:Destroy()
	end
end

--------------------------------------------------------------------------------
-- SPAWN MANAGEMENT
--------------------------------------------------------------------------------

local function generateNPCId(): string
	local id = "npc_" .. nextNPCId
	nextNPCId = nextNPCId + 1
	return id
end

local function getRandomPositionInRadius(center: Vector3, radius: number): Vector3
	local angle = math.random() * math.pi * 2
	local distance = math.random() * radius
	return Vector3.new(
		center.X + math.cos(angle) * distance,
		center.Y,
		center.Z + math.sin(angle) * distance
	)
end

local function countNPCsInRegion(regionId: string): number
	local count = 0
	for _, npc in activeNPCs do
		if npc.regionId == regionId then
			count = count + 1
		end
	end
	return count
end

local function getClosestPlayerDistance(position: Vector3): number
	local closest = math.huge
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local dist = (root.Position - position).Magnitude
			if dist < closest then
				closest = dist
			end
		end
	end
	return closest
end

function NPCService:spawnNPC(definitionId: string, position: Vector3, regionId: string): Types.NPCInstance?
	local def = NPCDefinitions.get(definitionId)
	if not def then
		warn("[NPCService] Unknown NPC:", definitionId)
		return nil
	end

	-- Check region limit
	if countNPCsInRegion(regionId) >= CONFIG.MAX_NPCS_PER_REGION then
		return nil
	end

	-- Get model from pool
	local model = getFromPool(definitionId)
	if not model then
		return nil
	end

	-- Position model
	model:PivotTo(CFrame.new(position))
	model.Parent = npcFolder

	-- Create instance
	local instance: Types.NPCInstance = {
		id = generateNPCId(),
		definitionId = definitionId,
		regionId = regionId,
		state = "idle",
		stateStartTime = os.clock(),
		hunger = 50,
		thirst = 50,
		energy = 80,
		fear = 0,
		spawnPosition = position,
		currentPosition = position,
		currentRotation = math.random() * math.pi * 2,
		lodLevel = 0,
		lastFullUpdate = os.clock(),
		model = model,
		isPooled = false,
	}

	activeNPCs[instance.id] = instance
	return instance
end

function NPCService:despawnNPC(npcId: string)
	local npc = activeNPCs[npcId]
	if not npc then
		return
	end

	if npc.model then
		returnToPool(npc.definitionId, npc.model)
	end

	activeNPCs[npcId] = nil
end

--------------------------------------------------------------------------------
-- SPAWN CONTROLLER (Ties to Ecology)
--------------------------------------------------------------------------------

local function checkSpawns()
	if not EcologyService then
		return
	end

	local regions = EcologyService:getAllRegions()

	for regionId, region in regions do
		-- Get populations in this region
		for speciesId, population in region.populations do
			if population.count <= 0 then
				continue
			end

			-- Find NPC definition for this species
			local npcDef = NPCDefinitions.getBySpecies(speciesId)
			if not npcDef then
				continue
			end

			-- Calculate target NPC count based on population
			local targetCount = math.floor(population.count * CONFIG.POPULATION_TO_NPC_RATIO)
			targetCount = math.min(targetCount, 10) -- Cap per species

			-- Count current NPCs of this type in region
			local currentCount = 0
			for _, npc in activeNPCs do
				if npc.regionId == regionId and npc.definitionId == npcDef.id then
					currentCount = currentCount + 1
				end
			end

			-- Spawn if needed
			if currentCount < targetCount then
				-- Find a spawn position in the region
				local bounds = region.bounds
				local center = (bounds.min + bounds.max) / 2
				local radius = math.min(bounds.max.X - bounds.min.X, bounds.max.Z - bounds.min.Z) / 3

				local spawnPos = getRandomPositionInRadius(center, radius)

				-- Raycast to find ground
				local rayOrigin = Vector3.new(spawnPos.X, 200, spawnPos.Z)
				local rayDir = Vector3.new(0, -300, 0)
				local rayParams = RaycastParams.new()
				rayParams.FilterType = Enum.RaycastFilterType.Exclude
				rayParams.FilterDescendantsInstances = { npcFolder }

				local result = workspace:Raycast(rayOrigin, rayDir, rayParams)
				if result then
					spawnPos = result.Position + Vector3.new(0, 2, 0)

					-- Only spawn if players are somewhat close (but not too close)
					local playerDist = getClosestPlayerDistance(spawnPos)
					if playerDist > 50 and playerDist < CONFIG.DESPAWN_DISTANCE then
						NPCService:spawnNPC(npcDef.id, spawnPos, regionId)
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- AI STATE MACHINE
--------------------------------------------------------------------------------

local function updateNPCState(npc: Types.NPCInstance, dt: number)
	local def = NPCDefinitions.get(npc.definitionId)
	if not def or not npc.model then
		return
	end

	-- Update needs
	npc.hunger = math.min(100, npc.hunger + def.hungerRate * dt)
	npc.thirst = math.min(100, npc.thirst + def.thirstRate * dt)
	npc.energy = math.max(0, npc.energy - def.restRate * dt)

	-- Check for nearby threats (players)
	local playerDist = getClosestPlayerDistance(npc.currentPosition)
	if playerDist < def.fleeDistance and def.fleeDistance > 0 then
		npc.fear = math.min(100, npc.fear + 30 * dt)
		if npc.state ~= "flee" then
			npc.state = "flee"
			npc.stateStartTime = os.clock()
		end
	else
		npc.fear = math.max(0, npc.fear - 10 * dt)
	end

	-- State machine
	local stateTime = os.clock() - npc.stateStartTime

	if npc.state == "flee" then
		-- Run away from player
		if npc.fear < 20 or playerDist > def.fleeDistance * 2 then
			npc.state = "idle"
			npc.stateStartTime = os.clock()
		else
			-- Move away from nearest player
			for _, player in Players:GetPlayers() do
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					local toNPC = (npc.currentPosition - root.Position).Unit
					npc.targetPosition = npc.currentPosition + toNPC * 20
					break
				end
			end
		end

	elseif npc.state == "idle" then
		-- Stand still, occasionally switch to wander
		if stateTime > 2 + math.random() * 3 then
			npc.state = "wander"
			npc.stateStartTime = os.clock()
			-- Pick random target within wander radius
			npc.targetPosition = getRandomPositionInRadius(npc.spawnPosition, def.wanderRadius)
		end

	elseif npc.state == "wander" then
		-- Move toward target
		if not npc.targetPosition then
			npc.state = "idle"
			npc.stateStartTime = os.clock()
		else
			local dist = (npc.targetPosition - npc.currentPosition).Magnitude
			if dist < 3 or stateTime > 10 then
				npc.state = "idle"
				npc.stateStartTime = os.clock()
				npc.targetPosition = nil
			end
		end

	elseif npc.state == "eat" then
		-- Eating animation/behavior
		if stateTime > 3 then
			npc.hunger = math.max(0, npc.hunger - 30)
			npc.state = "idle"
			npc.stateStartTime = os.clock()
		end

	elseif npc.state == "drink" then
		-- Drinking
		if stateTime > 2 then
			npc.thirst = math.max(0, npc.thirst - 40)
			npc.state = "idle"
			npc.stateStartTime = os.clock()
		end
	end

	-- Trigger needs-based behaviors
	if npc.state == "idle" or npc.state == "wander" then
		if npc.hunger > 70 then
			npc.state = "eat" -- Would seek food in full implementation
			npc.stateStartTime = os.clock()
		elseif npc.thirst > 70 then
			npc.state = "drink" -- Would seek water
			npc.stateStartTime = os.clock()
		end
	end
end

local function moveNPC(npc: Types.NPCInstance, dt: number)
	local def = NPCDefinitions.get(npc.definitionId)
	if not def or not npc.model or not npc.model.PrimaryPart then
		return
	end

	if not npc.targetPosition then
		return
	end

	local currentPos = npc.model.PrimaryPart.Position
	local targetPos = npc.targetPosition
	local direction = (targetPos - currentPos)
	direction = Vector3.new(direction.X, 0, direction.Z) -- Keep horizontal

	if direction.Magnitude < 0.1 then
		return
	end

	direction = direction.Unit

	-- Choose speed based on state
	local speed = def.walkSpeed
	if npc.state == "flee" or npc.state == "chase" then
		speed = def.runSpeed
	end

	-- Move
	local movement = direction * speed * dt
	local newPos = currentPos + movement
	npc.currentPosition = newPos

	-- Rotate toward movement direction
	local targetRotation = math.atan2(direction.X, direction.Z)
	npc.currentRotation = targetRotation

	-- Apply to model
	npc.model:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, targetRotation, 0))
end

--------------------------------------------------------------------------------
-- LOD SYSTEM
--------------------------------------------------------------------------------

local function updateLOD(npc: Types.NPCInstance)
	local playerDist = getClosestPlayerDistance(npc.currentPosition)

	if playerDist > CONFIG.DESPAWN_DISTANCE then
		-- Too far, despawn
		NPCService:despawnNPC(npc.id)
		return true -- Signal removal
	elseif playerDist > CONFIG.LOD_DISTANCE_2 then
		npc.lodLevel = 2
	elseif playerDist > CONFIG.LOD_DISTANCE_1 then
		npc.lodLevel = 1
	else
		npc.lodLevel = 0
	end

	return false
end

--------------------------------------------------------------------------------
-- MAIN UPDATE LOOP
--------------------------------------------------------------------------------

local lastUpdate = 0

local function onHeartbeat(dt: number)
	if not isRunning then
		return
	end

	lastUpdate = lastUpdate + dt

	-- Check spawns periodically
	lastSpawnCheck = lastSpawnCheck + dt
	if lastSpawnCheck >= CONFIG.SPAWN_INTERVAL then
		lastSpawnCheck = 0
		checkSpawns()
	end

	-- Update NPCs
	if lastUpdate < CONFIG.UPDATE_INTERVAL then
		return
	end
	lastUpdate = 0

	local toRemove = {}

	for npcId, npc in activeNPCs do
		-- Update LOD
		local shouldRemove = updateLOD(npc)
		if shouldRemove then
			table.insert(toRemove, npcId)
			continue
		end

		-- Skip updates based on LOD
		local updateInterval = CONFIG.UPDATE_INTERVAL
		if npc.lodLevel == 1 then
			updateInterval = updateInterval * 3
		elseif npc.lodLevel == 2 then
			updateInterval = updateInterval * 10
		end

		local timeSinceUpdate = os.clock() - npc.lastFullUpdate
		if timeSinceUpdate < updateInterval then
			continue
		end
		npc.lastFullUpdate = os.clock()

		-- Update AI state
		updateNPCState(npc, timeSinceUpdate)

		-- Move NPC
		moveNPC(npc, timeSinceUpdate)
	end

	-- Remove despawned NPCs
	for _, npcId in toRemove do
		activeNPCs[npcId] = nil
	end
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function NPCService:getNPC(npcId: string): Types.NPCInstance?
	return activeNPCs[npcId]
end

function NPCService:getAllNPCs(): { [string]: Types.NPCInstance }
	return activeNPCs
end

function NPCService:getNPCCount(): number
	local count = 0
	for _ in activeNPCs do
		count = count + 1
	end
	return count
end

function NPCService:getNPCsInRegion(regionId: string): { Types.NPCInstance }
	local result = {}
	for _, npc in activeNPCs do
		if npc.regionId == regionId then
			table.insert(result, npc)
		end
	end
	return result
end

function NPCService:getNearbyNPCs(position: Vector3, radius: number): { Types.NPCInstance }
	local result = {}
	for _, npc in activeNPCs do
		if (npc.currentPosition - position).Magnitude <= radius then
			table.insert(result, npc)
		end
	end
	return result
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function NPCService:init()
	-- Create NPC folder
	npcFolder = Instance.new("Folder")
	npcFolder.Name = "NPCs"
	npcFolder.Parent = workspace

	-- Load EcologyService
	pcall(function()
		local ServerScriptService = game:GetService("ServerScriptService")
		EcologyService = require(ServerScriptService.Server.Ecology.EcologyService)
	end)

	-- Start update loop
	isRunning = true
	RunService.Heartbeat:Connect(onHeartbeat)

	print("[NPCService] Initialized")
end

function NPCService:stop()
	isRunning = false

	-- Despawn all NPCs
	for npcId in activeNPCs do
		self:despawnNPC(npcId)
	end
end

return NPCService
