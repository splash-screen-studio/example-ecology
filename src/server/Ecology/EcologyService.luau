--!strict
--[[
    EcologyService

    Core ecology simulation service.
    Manages ecosystem state, runs simulation ticks, and handles player impacts.

    The simulation runs on a tick-based system:
    - Each tick updates population dynamics
    - Resources regenerate or deplete
    - Predator-prey interactions occur
    - Player actions are processed

    Usage:
        local EcologyService = require(script.Parent.EcologyService)
        EcologyService:init()

        -- Player performs action
        EcologyService:applyPlayerAction(player, regionId, "plant", "wetland_grass")

        -- Get ecosystem state
        local health = EcologyService:getRegionHealth("verdant_center")
]]

local EcologyService = {}

-- Services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies
local Types = require(script.Parent.Types)
local SpeciesData = require(script.Parent.SpeciesData)

-- Configuration
local CONFIG = {
	TICK_INTERVAL = 5, -- Seconds between simulation ticks
	MIN_POPULATION = 1, -- Below this, population is extinct
	RESOURCE_REGEN_RATE = 0.02, -- Per tick
	STRESS_DECAY = 0.1, -- Stress reduces over time
	PLAYER_IMPACT_DECAY = 0.01, -- Player influence fades
	MIGRATION_THRESHOLD = 0.3, -- Population stress level to trigger migration
	CRITICAL_HEALTH = 20, -- Below this, region is in crisis
}

-- State
local regions: { [string]: Types.EcoRegion } = {}
local eventLog: { Types.EcoEvent } = {}
local currentTick = 0
local isRunning = false

-- Network (loaded after init)
local Network: any = nil

--------------------------------------------------------------------------------
-- REGION MANAGEMENT
--------------------------------------------------------------------------------

local function createDefaultResources(biome: string): Types.ResourceState
	if biome == "wetland" then
		return { water = 80, vegetation = 70, prey = 50, shelter = 60 }
	elseif biome == "plains" then
		return { water = 20, vegetation = 50, prey = 30, shelter = 30 }
	else
		return { water = 50, vegetation = 50, prey = 40, shelter = 50 }
	end
end

local function createDefaultPopulations(biome: string): { [string]: Types.PopulationState }
	local populations: { [string]: Types.PopulationState } = {}
	local species = SpeciesData.getForBiome(biome)

	for _, sp in species do
		-- Start at 50% carrying capacity
		local startPop = math.floor(sp.carryingCapacity * 0.5)
		populations[sp.id] = {
			count = startPop,
			trend = "stable",
			lastChange = 0,
			stressLevel = 0,
		}
	end

	return populations
end

function EcologyService:createRegion(config: {
	id: string,
	name: string,
	biome: string,
	bounds: { min: Vector3, max: Vector3 },
	neighbors: { string }?,
}): Types.EcoRegion
	local region: Types.EcoRegion = {
		id = config.id,
		name = config.name,
		biome = config.biome,
		bounds = config.bounds,
		neighbors = config.neighbors or {},
		resources = createDefaultResources(config.biome),
		populations = createDefaultPopulations(config.biome),
		health = 75, -- Start healthy
		playerInfluence = 0,
	}

	regions[config.id] = region
	print(string.format("[EcologyService] Created region: %s (%s)", config.name, config.biome))

	return region
end

function EcologyService:getRegion(regionId: string): Types.EcoRegion?
	return regions[regionId]
end

function EcologyService:getAllRegions(): { [string]: Types.EcoRegion }
	return regions
end

--------------------------------------------------------------------------------
-- SIMULATION CORE
--------------------------------------------------------------------------------

local function calculateResourceAvailability(region: Types.EcoRegion, species: Types.SpeciesDefinition): number
	local resources = region.resources
	local availability = 1.0

	-- Water availability
	if species.waterNeed > 0 then
		local waterRatio = resources.water / 100
		availability = availability * math.min(1, waterRatio / species.waterNeed)
	end

	-- Food availability (vegetation for herbivores/omnivores, prey for carnivores)
	if species.foodNeed > 0 then
		local foodSource = 0
		if species.category == "producer" then
			foodSource = 1.0 -- Producers make their own food
		elseif species.category == "herbivore" then
			foodSource = resources.vegetation / 100
		elseif species.category == "carnivore" then
			foodSource = resources.prey / 100
		else -- omnivore
			foodSource = (resources.vegetation + resources.prey) / 200
		end
		availability = availability * math.min(1, foodSource / species.foodNeed)
	end

	-- Shelter
	if species.shelterNeed > 0 then
		local shelterRatio = resources.shelter / 100
		availability = availability * math.min(1, shelterRatio / species.shelterNeed)
	end

	return math.clamp(availability, 0, 1)
end

local function calculatePredationPressure(region: Types.EcoRegion, species: Types.SpeciesDefinition): number
	local pressure = 0

	for _, predatorId in species.predators do
		local predatorPop = region.populations[predatorId]
		if predatorPop and predatorPop.count > 0 then
			local predatorDef = SpeciesData[predatorId]
			if predatorDef then
				-- More predators = more pressure
				local predatorRatio = predatorPop.count / predatorDef.carryingCapacity
				pressure = pressure + predatorRatio * 0.3
			end
		end
	end

	return math.clamp(pressure, 0, 1)
end

local function calculateGrowthRate(
	region: Types.EcoRegion,
	species: Types.SpeciesDefinition,
	population: Types.PopulationState
): number
	local baseRate = species.baseGrowthRate

	-- Resource availability affects growth
	local resourceMod = calculateResourceAvailability(region, species)

	-- Predation pressure reduces growth
	local predationPressure = calculatePredationPressure(region, species)

	-- Carrying capacity limits growth
	local capacityRatio = population.count / species.carryingCapacity
	local capacityMod = 1 - (capacityRatio * 0.5) -- Slower growth as capacity fills

	-- Stress reduces growth
	local stressMod = 1 - (population.stressLevel * 0.5)

	-- Combine modifiers
	local finalRate = baseRate * resourceMod * capacityMod * stressMod * (1 - predationPressure * 0.5)

	-- Can't grow if below minimum resources
	if resourceMod < 0.2 then
		finalRate = math.min(finalRate, 0.95) -- Population declines
	end

	return finalRate
end

local function updatePopulation(region: Types.EcoRegion, speciesId: string)
	local population = region.populations[speciesId]
	if not population then
		return
	end

	local species = SpeciesData[speciesId]
	if not species or type(species) ~= "table" then
		return
	end

	local growthRate = calculateGrowthRate(region, species, population)
	local oldCount = population.count
	local newCount = math.floor(oldCount * growthRate)

	-- Apply carrying capacity hard limit
	newCount = math.min(newCount, species.carryingCapacity)

	-- Check for extinction
	if newCount < species.minViablePopulation then
		newCount = 0
		table.insert(eventLog, {
			tick = currentTick,
			regionId = region.id,
			eventType = "extinction",
			speciesId = speciesId,
			description = string.format("%s has gone extinct in %s!", species.name, region.name),
			magnitude = -1,
		})
	end

	-- Update trend
	local diff = newCount - oldCount
	if diff > oldCount * 0.05 then
		population.trend = "growing"
	elseif diff < -oldCount * 0.05 then
		if newCount < species.minViablePopulation * 2 then
			population.trend = "critical"
		else
			population.trend = "declining"
		end
	else
		population.trend = "stable"
	end

	population.count = newCount
	population.lastChange = currentTick

	-- Decay stress
	population.stressLevel = math.max(0, population.stressLevel - CONFIG.STRESS_DECAY)
end

local function updateResources(region: Types.EcoRegion)
	local resources = region.resources

	-- Vegetation regenerates based on water
	local waterFactor = resources.water / 100
	resources.vegetation = math.min(100, resources.vegetation + CONFIG.RESOURCE_REGEN_RATE * 100 * waterFactor)

	-- Herbivores consume vegetation
	local herbivoreConsumption = 0
	for speciesId, pop in region.populations do
		local species = SpeciesData[speciesId]
		if species and type(species) == "table" and species.category == "herbivore" then
			herbivoreConsumption = herbivoreConsumption + (pop.count * species.foodNeed * 0.01)
		end
	end
	resources.vegetation = math.max(0, resources.vegetation - herbivoreConsumption)

	-- Prey availability is based on herbivore populations
	local totalHerbivores = 0
	local maxHerbivores = 0
	for speciesId, pop in region.populations do
		local species = SpeciesData[speciesId]
		if species and type(species) == "table" and (species.category == "herbivore" or species.category == "omnivore") then
			totalHerbivores = totalHerbivores + pop.count
			maxHerbivores = maxHerbivores + species.carryingCapacity
		end
	end
	resources.prey = if maxHerbivores > 0 then (totalHerbivores / maxHerbivores) * 100 else 0

	-- Shelter slowly recovers
	resources.shelter = math.min(100, resources.shelter + CONFIG.RESOURCE_REGEN_RATE * 50)
end

local function updateRegionHealth(region: Types.EcoRegion)
	-- Health based on:
	-- 1. Species diversity (how many species exist)
	-- 2. Population balance (not too many/few of any species)
	-- 3. Resource levels

	local totalSpecies = 0
	local healthySpecies = 0
	local totalBalance = 0

	for speciesId, pop in region.populations do
		local species = SpeciesData[speciesId]
		if species and type(species) == "table" then
			totalSpecies = totalSpecies + 1
			if pop.count > 0 then
				healthySpecies = healthySpecies + 1
				-- Balance score: closer to 50% capacity is better
				local capacityRatio = pop.count / species.carryingCapacity
				local balance = 1 - math.abs(0.5 - capacityRatio) * 2
				totalBalance = totalBalance + balance
			end
		end
	end

	local diversityScore = if totalSpecies > 0 then (healthySpecies / totalSpecies) * 40 else 0
	local balanceScore = if healthySpecies > 0 then (totalBalance / healthySpecies) * 30 else 0
	local resourceScore = (region.resources.water + region.resources.vegetation + region.resources.shelter) / 3 * 0.3

	region.health = math.clamp(diversityScore + balanceScore + resourceScore, 0, 100)

	-- Decay player influence over time
	if region.playerInfluence > 0 then
		region.playerInfluence = math.max(0, region.playerInfluence - CONFIG.PLAYER_IMPACT_DECAY * 100)
	elseif region.playerInfluence < 0 then
		region.playerInfluence = math.min(0, region.playerInfluence + CONFIG.PLAYER_IMPACT_DECAY * 100)
	end
end

local function simulateTick()
	currentTick = currentTick + 1

	for _, region in regions do
		-- Update each species population
		for speciesId in region.populations do
			updatePopulation(region, speciesId)
		end

		-- Update resources
		updateResources(region)

		-- Update overall health
		updateRegionHealth(region)
	end

	-- Broadcast state updates (throttled)
	if currentTick % 3 == 0 and Network then
		EcologyService:broadcastState()
	end
end

--------------------------------------------------------------------------------
-- PLAYER ACTIONS
--------------------------------------------------------------------------------

function EcologyService:applyPlayerAction(
	player: Player,
	regionId: string,
	actionType: string,
	targetSpecies: string?,
	magnitude: number?
): { success: boolean, message: string }
	local region = regions[regionId]
	if not region then
		return { success = false, message = "Unknown region" }
	end

	magnitude = magnitude or 1
	local impact: Types.PlayerImpact = {
		playerId = player.UserId,
		regionId = regionId,
		actionType = actionType,
		speciesAffected = {},
		resourcesAffected = {},
		magnitude = 0,
		timestamp = os.time(),
	}

	local message = ""

	if actionType == "plant" then
		-- Increase vegetation
		region.resources.vegetation = math.min(100, region.resources.vegetation + 10 * magnitude)
		impact.resourcesAffected = { "vegetation" }
		impact.magnitude = 0.2 * magnitude
		message = "You planted new growth!"

		-- If specific species, boost that population
		if targetSpecies and region.populations[targetSpecies] then
			local pop = region.populations[targetSpecies]
			local species = SpeciesData[targetSpecies]
			if species and type(species) == "table" and species.category == "producer" then
				pop.count = math.min(species.carryingCapacity, pop.count + math.floor(10 * magnitude))
				table.insert(impact.speciesAffected, targetSpecies)
			end
		end

	elseif actionType == "water" then
		region.resources.water = math.min(100, region.resources.water + 15 * magnitude)
		impact.resourcesAffected = { "water" }
		impact.magnitude = 0.3 * magnitude
		message = "The area is now better hydrated!"

	elseif actionType == "feed" then
		if targetSpecies and region.populations[targetSpecies] then
			local pop = region.populations[targetSpecies]
			pop.stressLevel = math.max(0, pop.stressLevel - 0.3 * magnitude)
			table.insert(impact.speciesAffected, targetSpecies)
			impact.magnitude = 0.2 * magnitude
			message = "The animals are grateful!"
		else
			message = "No animals nearby to feed."
			impact.magnitude = 0
		end

	elseif actionType == "clean" then
		-- Reduces stress on all species, improves resources
		for _, pop in region.populations do
			pop.stressLevel = math.max(0, pop.stressLevel - 0.2 * magnitude)
		end
		region.resources.shelter = math.min(100, region.resources.shelter + 10 * magnitude)
		impact.resourcesAffected = { "shelter" }
		impact.magnitude = 0.25 * magnitude
		message = "The ecosystem feels healthier!"

	elseif actionType == "remove" then
		-- Negative action - removes vegetation/species
		if targetSpecies and region.populations[targetSpecies] then
			local pop = region.populations[targetSpecies]
			pop.count = math.max(0, pop.count - math.floor(5 * magnitude))
			pop.stressLevel = math.min(1, pop.stressLevel + 0.4 * magnitude)
			table.insert(impact.speciesAffected, targetSpecies)
			impact.magnitude = -0.3 * magnitude
			message = "This may have consequences..."
		else
			region.resources.vegetation = math.max(0, region.resources.vegetation - 15 * magnitude)
			impact.resourcesAffected = { "vegetation" }
			impact.magnitude = -0.2 * magnitude
			message = "Vegetation removed."
		end

	else
		return { success = false, message = "Unknown action type" }
	end

	-- Update player influence
	region.playerInfluence = math.clamp(region.playerInfluence + impact.magnitude * 50, -100, 100)

	-- Log event
	table.insert(eventLog, {
		tick = currentTick,
		regionId = regionId,
		eventType = "player_action",
		speciesId = targetSpecies,
		description = string.format("%s performed %s in %s", player.Name, actionType, region.name),
		magnitude = impact.magnitude,
	})

	return { success = true, message = message }
end

--------------------------------------------------------------------------------
-- QUERIES
--------------------------------------------------------------------------------

function EcologyService:getRegionHealth(regionId: string): number
	local region = regions[regionId]
	return if region then region.health else 0
end

function EcologyService:getPopulation(regionId: string, speciesId: string): number
	local region = regions[regionId]
	if not region then
		return 0
	end
	local pop = region.populations[speciesId]
	return if pop then pop.count else 0
end

function EcologyService:getRecentEvents(count: number?): { Types.EcoEvent }
	count = count or 10
	local result = {}
	local start = math.max(1, #eventLog - count + 1)
	for i = start, #eventLog do
		table.insert(result, eventLog[i])
	end
	return result
end

function EcologyService:getRegionAtPosition(position: Vector3): Types.EcoRegion?
	for _, region in regions do
		local bounds = region.bounds
		if position.X >= bounds.min.X and position.X <= bounds.max.X
			and position.Y >= bounds.min.Y and position.Y <= bounds.max.Y
			and position.Z >= bounds.min.Z and position.Z <= bounds.max.Z then
			return region
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- STATE BROADCAST
--------------------------------------------------------------------------------

function EcologyService:broadcastState()
	if not Network then
		return
	end

	-- Summarize state for clients
	local summary = {}
	for regionId, region in regions do
		summary[regionId] = {
			health = region.health,
			playerInfluence = region.playerInfluence,
			resources = region.resources,
		}
	end

	Network.Events.EcoStateUpdate:FireAllClients(summary)
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function EcologyService:init()
	-- Load network module
	pcall(function()
		Network = require(ReplicatedStorage.Shared.Network)
	end)

	-- Create default regions for current place
	local PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)
	local placeName = PlaceConfig.getCurrent().name
	local dims = PlaceConfig.getWorldDimensions()
	local halfSize = dims.size / 2

	if placeName == "Verdant Basin" then
		-- Create wetland regions
		self:createRegion({
			id = "verdant_center",
			name = "Central Marsh",
			biome = "wetland",
			bounds = {
				min = Vector3.new(-halfSize.X/2, -50, -halfSize.Z/2),
				max = Vector3.new(halfSize.X/2, 100, halfSize.Z/2),
			},
			neighbors = { "verdant_north", "verdant_south", "verdant_east", "verdant_west" },
		})

		self:createRegion({
			id = "verdant_north",
			name = "Northern Wetlands",
			biome = "wetland",
			bounds = {
				min = Vector3.new(-halfSize.X, -50, halfSize.Z/2),
				max = Vector3.new(halfSize.X, 100, halfSize.Z),
			},
			neighbors = { "verdant_center" },
		})

		self:createRegion({
			id = "verdant_south",
			name = "Southern Pond",
			biome = "wetland",
			bounds = {
				min = Vector3.new(-halfSize.X, -50, -halfSize.Z),
				max = Vector3.new(halfSize.X, 100, -halfSize.Z/2),
			},
			neighbors = { "verdant_center" },
		})

	elseif placeName == "Driftplain" then
		-- Create plains regions
		self:createRegion({
			id = "drift_center",
			name = "Central Plains",
			biome = "plains",
			bounds = {
				min = Vector3.new(-halfSize.X/2, -50, -halfSize.Z/2),
				max = Vector3.new(halfSize.X/2, 100, halfSize.Z/2),
			},
			neighbors = { "drift_oasis" },
		})

		self:createRegion({
			id = "drift_oasis",
			name = "Hidden Oasis",
			biome = "wetland", -- Small wetland in the plains
			bounds = {
				min = Vector3.new(halfSize.X/2, -50, -halfSize.Z/4),
				max = Vector3.new(halfSize.X, 100, halfSize.Z/4),
			},
			neighbors = { "drift_center" },
		})
	end

	-- Start simulation loop
	isRunning = true
	task.spawn(function()
		while isRunning do
			task.wait(CONFIG.TICK_INTERVAL)
			simulateTick()
		end
	end)

	print(string.format("[EcologyService] Initialized with %d regions, tick interval: %ds",
		self:getRegionCount(), CONFIG.TICK_INTERVAL))
end

function EcologyService:getRegionCount(): number
	local count = 0
	for _ in regions do
		count = count + 1
	end
	return count
end

function EcologyService:stop()
	isRunning = false
end

return EcologyService
