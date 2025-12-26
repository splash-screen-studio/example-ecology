--!strict
--[[
    WorldObjectService

    Manages spawning and lifecycle of world objects (plants, collectibles, resources).
    Handles biome-specific spawn rules and respawn timers.

    Usage:
        local WorldObjectService = require(script.WorldObjectService)
        WorldObjectService:init()
        WorldObjectService:spawnObjectsInRegion(center, size, biome)
]]

local WorldObjectService = {}

-- Services
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Dependencies (lazy loaded)
local ObjectDefinitions
local InteractionService
local ElevationService
local PlaceConfig
local ModelLoader

-- Configuration
local CONFIG = {
	SPAWN_GRID_SIZE = 20, -- studs per spawn cell
	MAX_OBJECTS_PER_CELL = 3,
	WATER_PROXIMITY_DISTANCE = 15, -- studs to be "near water"
	SPAWN_HEIGHT_OFFSET = 0.5, -- studs above ground
	UPDATE_INTERVAL = 5, -- seconds between respawn checks
}

-- State
local worldObjects: { [string]: { instance: Instance, definition: any, spawnTime: number, depleted: boolean, depleteTime: number? } } = {}
local spawnedCells: { [string]: boolean } = {}
local objectsFolder: Folder?
local initialized = false

-- Unique ID counter
local nextId = 1

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not ObjectDefinitions then
		ObjectDefinitions = require(script.Parent.ObjectDefinitions)
	end
	if not ElevationService then
		ElevationService = require(ReplicatedStorage.Shared.ElevationService)
	end
	if not PlaceConfig then
		PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)
	end
	if not ModelLoader then
		local Assets = ReplicatedStorage:FindFirstChild("Shared")
		if Assets then
			Assets = Assets:FindFirstChild("Assets")
			if Assets then
				ModelLoader = require(Assets.ModelLoader)
			end
		end
	end
end

local function getObjectsFolder(): Folder
	if objectsFolder and objectsFolder.Parent then
		return objectsFolder
	end

	objectsFolder = Workspace:FindFirstChild("WorldObjects") :: Folder?
	if not objectsFolder then
		objectsFolder = Instance.new("Folder")
		objectsFolder.Name = "WorldObjects"
		objectsFolder.Parent = Workspace
	end

	return objectsFolder
end

local function getCellKey(x: number, z: number): string
	local cellX = math.floor(x / CONFIG.SPAWN_GRID_SIZE)
	local cellZ = math.floor(z / CONFIG.SPAWN_GRID_SIZE)
	return string.format("%d,%d", cellX, cellZ)
end

local function generateObjectId(): string
	local id = string.format("obj_%d_%d", os.time(), nextId)
	nextId = nextId + 1
	return id
end

local function isNearWater(x: number, z: number): boolean
	loadDependencies()

	-- Check in a small radius
	for dx = -CONFIG.WATER_PROXIMITY_DISTANCE, CONFIG.WATER_PROXIMITY_DISTANCE, 5 do
		for dz = -CONFIG.WATER_PROXIMITY_DISTANCE, CONFIG.WATER_PROXIMITY_DISTANCE, 5 do
			local elevation = ElevationService:getElevation(x + dx, z + dz)
			if elevation.waterSurfaceY then
				return true
			end
		end
	end

	return false
end

local function createPlaceholderModel(definition: any): Model
	-- Create a simple placeholder if no model found
	local model = Instance.new("Model")
	model.Name = definition.id

	local part = Instance.new("Part")
	part.Name = "Root"
	part.Anchored = true
	part.CanCollide = false
	part.Size = Vector3.new(2, 2, 2)
	part.Material = Enum.Material.Grass
	part.BrickColor = BrickColor.new("Bright green")

	-- Set appearance based on object type
	local id = definition.id or ""
	if string.find(id, "stone") or string.find(id, "rock") then
		part.BrickColor = BrickColor.new("Medium stone grey")
		part.Material = Enum.Material.Slate
		part.Size = Vector3.new(1.5, 1, 1.5)
	elseif string.find(id, "berry") or string.find(id, "fruit") then
		part.BrickColor = BrickColor.new("Bright red")
		part.Material = Enum.Material.SmoothPlastic
		part.Size = Vector3.new(0.8, 0.8, 0.8)
	elseif string.find(id, "grass") or string.find(id, "plant") or string.find(id, "herb") then
		part.BrickColor = BrickColor.new("Bright green")
		part.Material = Enum.Material.Grass
		part.Size = Vector3.new(1, 1.5, 1)
	elseif string.find(id, "wood") or string.find(id, "stick") or string.find(id, "log") then
		part.BrickColor = BrickColor.new("Brown")
		part.Material = Enum.Material.Wood
		part.Size = Vector3.new(2, 1, 1)
	elseif definition.category == "resource" then
		part.BrickColor = BrickColor.new("Brown")
		part.Material = Enum.Material.Wood
	elseif definition.category == "collectible" then
		part.BrickColor = BrickColor.new("Bright violet")
		part.Material = Enum.Material.Neon
	end

	part.Parent = model
	model.PrimaryPart = part

	-- Add BillboardGui for name
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 2, 0)
	billboard.AlwaysOnTop = false
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = definition.name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = billboard

	return model
end

--------------------------------------------------------------------------------
-- SPAWNING
--------------------------------------------------------------------------------

function WorldObjectService:spawnObject(definition: any, position: Vector3): Instance?
	loadDependencies()

	local objectId = generateObjectId()

	-- Try to get model from ModelLoader
	local model: Model? = nil

	if ModelLoader and definition.modelId then
		model = ModelLoader:cloneModel("WorldObjects", definition.modelId)
	end

	-- Use placeholder if no model found
	if not model then
		model = createPlaceholderModel(definition)
	end

	if not model then
		return nil
	end

	-- Apply scale
	if definition.scale and definition.scale ~= 1 then
		local scale = definition.scale
		for _, desc in model:GetDescendants() do
			if desc:IsA("BasePart") then
				desc.Size = desc.Size * scale
			end
		end
	end

	-- Apply random rotation
	if definition.randomRotation then
		local rotation = CFrame.Angles(0, math.random() * math.pi * 2, 0)
		if model.PrimaryPart then
			model:SetPrimaryPartCFrame(CFrame.new(position) * rotation)
		end
	else
		if model.PrimaryPart then
			model:SetPrimaryPartCFrame(CFrame.new(position))
		end
	end

	-- Setup attributes for interaction
	model:SetAttribute("ObjectId", objectId)
	model:SetAttribute("DefinitionId", definition.id)
	model.Name = definition.id .. "_" .. objectId

	-- Parent to folder
	model.Parent = getObjectsFolder()

	-- Register with InteractionService
	if InteractionService then
		local quantity = definition.quantity
		local qtyValue = 1
		if quantity then
			qtyValue = math.random(quantity.Min, quantity.Max)
		end

		InteractionService:registerInteractable(model, {
			id = objectId,
			interactionType = definition.interactionType,
			displayName = definition.name,
			prompt = string.format("%s %s", definition.interactionType == "pickup" and "Pick up" or "Harvest", definition.name),
			range = 8,
			cooldown = 1,
			itemId = definition.itemId,
			quantity = qtyValue,
			harvestTime = definition.harvestTime,
			respawnTime = definition.respawnTime,
		})
	end

	-- Track in state
	worldObjects[objectId] = {
		instance = model,
		definition = definition,
		spawnTime = os.clock(),
		depleted = false,
		depleteTime = nil,
	}

	return model
end

function WorldObjectService:spawnObjectsInCell(cellX: number, cellZ: number, biome: string)
	loadDependencies()

	local cellKey = getCellKey(cellX * CONFIG.SPAWN_GRID_SIZE, cellZ * CONFIG.SPAWN_GRID_SIZE)
	if spawnedCells[cellKey] then
		return -- Already spawned
	end
	spawnedCells[cellKey] = true

	local definitions = ObjectDefinitions.getByBiome(biome)
	local centerX = cellX * CONFIG.SPAWN_GRID_SIZE + CONFIG.SPAWN_GRID_SIZE / 2
	local centerZ = cellZ * CONFIG.SPAWN_GRID_SIZE + CONFIG.SPAWN_GRID_SIZE / 2

	local objectsInCell = 0

	for _, definition in definitions do
		if objectsInCell >= CONFIG.MAX_OBJECTS_PER_CELL then
			break
		end

		local rules = definition.spawnRules
		local density = rules.density or 1

		-- Calculate spawn chance based on density
		-- Density is objects per 100x100 area
		local cellArea = CONFIG.SPAWN_GRID_SIZE * CONFIG.SPAWN_GRID_SIZE
		local spawnChance = (density * cellArea) / 10000

		if math.random() < spawnChance then
			-- Random position within cell
			local x = centerX + (math.random() - 0.5) * CONFIG.SPAWN_GRID_SIZE
			local z = centerZ + (math.random() - 0.5) * CONFIG.SPAWN_GRID_SIZE

			-- Check elevation requirements
			local elevation = ElevationService:getElevation(x, z)

			if not elevation.isValid then
				continue
			end

			local groundY = elevation.groundY

			-- Check elevation bounds
			if rules.minElevation and groundY < rules.minElevation then
				continue
			end
			if rules.maxElevation and groundY > rules.maxElevation then
				continue
			end

			-- Check water proximity
			if rules.nearWater and not isNearWater(x, z) then
				continue
			end

			-- Don't spawn underwater (unless water plant)
			if elevation.waterSurfaceY and groundY < elevation.waterSurfaceY - 2 then
				if definition.id ~= "water_lily" then -- Exception for water plants
					continue
				end
			end

			local spawnY = groundY + CONFIG.SPAWN_HEIGHT_OFFSET
			local position = Vector3.new(x, spawnY, z)

			self:spawnObject(definition, position)
			objectsInCell = objectsInCell + 1
		end
	end
end

function WorldObjectService:spawnObjectsInRegion(center: Vector3, size: Vector3, biome: string)
	loadDependencies()

	local minX = math.floor((center.X - size.X / 2) / CONFIG.SPAWN_GRID_SIZE)
	local maxX = math.ceil((center.X + size.X / 2) / CONFIG.SPAWN_GRID_SIZE)
	local minZ = math.floor((center.Z - size.Z / 2) / CONFIG.SPAWN_GRID_SIZE)
	local maxZ = math.ceil((center.Z + size.Z / 2) / CONFIG.SPAWN_GRID_SIZE)

	local count = 0
	for cellX = minX, maxX do
		for cellZ = minZ, maxZ do
			self:spawnObjectsInCell(cellX, cellZ, biome)
			count = count + 1
		end

		-- Yield periodically to prevent timeout
		if count % 50 == 0 then
			task.wait()
		end
	end

	print(string.format("[WorldObjectService] Spawned objects in %d cells", count))
end

--------------------------------------------------------------------------------
-- RESPAWNING
--------------------------------------------------------------------------------

local function checkRespawns()
	local now = os.clock()

	for objectId, data in worldObjects do
		if data.depleted and data.depleteTime then
			local respawnTime = data.definition.respawnTime or 60
			if now - data.depleteTime >= respawnTime then
				-- Respawn the object
				local instance = data.instance
				if instance and instance.Parent then
					-- Make visible again
					for _, desc in instance:GetDescendants() do
						if desc:IsA("BasePart") then
							desc.Transparency = 0
							desc.CanCollide = true
						end
					end

					data.depleted = false
					data.depleteTime = nil
				else
					-- Instance was destroyed, remove from tracking
					worldObjects[objectId] = nil
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- MANAGEMENT
--------------------------------------------------------------------------------

function WorldObjectService:depleteObject(objectId: string)
	local data = worldObjects[objectId]
	if data then
		data.depleted = true
		data.depleteTime = os.clock()
	end
end

function WorldObjectService:removeObject(objectId: string)
	local data = worldObjects[objectId]
	if data then
		if data.instance and data.instance.Parent then
			data.instance:Destroy()
		end
		if InteractionService then
			InteractionService:unregisterInteractable(data.instance)
		end
		worldObjects[objectId] = nil
	end
end

function WorldObjectService:clearAll()
	for objectId, _ in worldObjects do
		self:removeObject(objectId)
	end
	spawnedCells = {}

	local folder = getObjectsFolder()
	for _, child in folder:GetChildren() do
		child:Destroy()
	end
end

function WorldObjectService:getObjectCount(): number
	local count = 0
	for _ in worldObjects do
		count = count + 1
	end
	return count
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function WorldObjectService:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()

	-- Load InteractionService
	pcall(function()
		InteractionService = require(script.Parent.Parent.Interaction.InteractionService)
	end)

	-- Start respawn check loop
	task.spawn(function()
		while true do
			task.wait(CONFIG.UPDATE_INTERVAL)
			checkRespawns()
		end
	end)

	print("[WorldObjectService] Initialized")
end

function WorldObjectService:spawnForCurrentPlace()
	loadDependencies()

	local config = PlaceConfig.getCurrent()
	local worldDims = PlaceConfig.getWorldDimensions()

	print(string.format("[WorldObjectService] Spawning objects for %s (%s biome)", config.name, config.biome))

	self:spawnObjectsInRegion(worldDims.center, worldDims.size, config.biome)
end

return WorldObjectService
