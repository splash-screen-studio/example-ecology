--!strict
--[[
    NPCDefinitions

    Definitions for all NPC types in the game.
    Links to species in EcologyService.
]]

local Types = require(script.Parent.Types)

local NPCs: { [string]: Types.NPCDefinition } = {}

--------------------------------------------------------------------------------
-- WETLAND ANIMALS
--------------------------------------------------------------------------------

NPCs.marsh_rabbit = {
	id = "marsh_rabbit",
	name = "Marsh Rabbit",
	category = "animal",
	speciesId = "marsh_rabbit",
	scale = 0.8,
	walkSpeed = 8,
	runSpeed = 20,
	turnSpeed = 8,
	fleeDistance = 25,
	awarenessRadius = 30,
	wanderRadius = 40,
	hungerRate = 0.5,
	thirstRate = 0.3,
	restRate = 0.2,
	aggressive = false,
}

NPCs.wetland_deer = {
	id = "wetland_deer",
	name = "Wetland Deer",
	category = "animal",
	speciesId = "wetland_deer",
	scale = 1.2,
	walkSpeed = 10,
	runSpeed = 28,
	turnSpeed = 5,
	fleeDistance = 40,
	awarenessRadius = 50,
	wanderRadius = 80,
	hungerRate = 0.3,
	thirstRate = 0.4,
	restRate = 0.15,
	aggressive = false,
}

NPCs.pond_turtle = {
	id = "pond_turtle",
	name = "Pond Turtle",
	category = "animal",
	speciesId = "pond_turtle",
	scale = 0.6,
	walkSpeed = 3,
	runSpeed = 5,
	turnSpeed = 2,
	fleeDistance = 10,
	awarenessRadius = 15,
	wanderRadius = 20,
	hungerRate = 0.1,
	thirstRate = 0.05,
	restRate = 0.1,
	aggressive = false,
}

NPCs.pond_fish = {
	id = "pond_fish",
	name = "Basin Minnow",
	category = "animal",
	speciesId = "pond_fish",
	scale = 0.3,
	walkSpeed = 6, -- Swimming speed
	runSpeed = 12,
	turnSpeed = 10,
	fleeDistance = 15,
	awarenessRadius = 20,
	wanderRadius = 30,
	hungerRate = 0.2,
	thirstRate = 0, -- Always in water
	restRate = 0.1,
	aggressive = false,
}

NPCs.marsh_fox = {
	id = "marsh_fox",
	name = "Marsh Fox",
	category = "animal",
	speciesId = "marsh_fox",
	scale = 0.9,
	walkSpeed = 10,
	runSpeed = 24,
	turnSpeed = 7,
	fleeDistance = 20, -- Flees from wolves
	awarenessRadius = 60,
	wanderRadius = 100,
	hungerRate = 0.6,
	thirstRate = 0.3,
	restRate = 0.25,
	aggressive = true, -- Hunts rabbits
	damage = 15,
	attackRange = 3,
	attackCooldown = 2,
}

NPCs.heron = {
	id = "heron",
	name = "Great Heron",
	category = "animal",
	speciesId = "heron",
	scale = 1.1,
	walkSpeed = 5,
	runSpeed = 8,
	turnSpeed = 4,
	fleeDistance = 30,
	awarenessRadius = 70, -- Great eyesight
	wanderRadius = 60,
	hungerRate = 0.4,
	thirstRate = 0.2,
	restRate = 0.2,
	aggressive = true, -- Hunts fish
	damage = 10,
	attackRange = 4,
	attackCooldown = 3,
}

NPCs.marsh_wolf = {
	id = "marsh_wolf",
	name = "Marsh Wolf",
	category = "animal",
	speciesId = "marsh_wolf",
	scale = 1.3,
	walkSpeed = 12,
	runSpeed = 30,
	turnSpeed = 6,
	fleeDistance = 0, -- Apex predator, doesn't flee
	awarenessRadius = 80,
	wanderRadius = 150,
	hungerRate = 0.5,
	thirstRate = 0.3,
	restRate = 0.3,
	aggressive = true,
	damage = 25,
	attackRange = 4,
	attackCooldown = 1.5,
}

--------------------------------------------------------------------------------
-- PLAINS ANIMALS
--------------------------------------------------------------------------------

NPCs.plains_hare = {
	id = "plains_hare",
	name = "Prairie Hare",
	category = "animal",
	speciesId = "plains_hare",
	scale = 0.7,
	walkSpeed = 10,
	runSpeed = 28,
	turnSpeed = 10,
	fleeDistance = 35,
	awarenessRadius = 45,
	wanderRadius = 60,
	hungerRate = 0.4,
	thirstRate = 0.5, -- Needs to find water
	restRate = 0.2,
	aggressive = false,
}

NPCs.pronghorn = {
	id = "pronghorn",
	name = "Pronghorn",
	category = "animal",
	speciesId = "pronghorn",
	scale = 1.4,
	walkSpeed = 14,
	runSpeed = 40, -- Very fast!
	turnSpeed = 5,
	fleeDistance = 60,
	awarenessRadius = 100, -- Open plains, can see far
	wanderRadius = 200,
	hungerRate = 0.3,
	thirstRate = 0.4,
	restRate = 0.15,
	aggressive = false,
}

NPCs.coyote = {
	id = "coyote",
	name = "Plains Coyote",
	category = "animal",
	speciesId = "coyote",
	scale = 1.0,
	walkSpeed = 12,
	runSpeed = 32,
	turnSpeed = 7,
	fleeDistance = 15, -- Cautious of players
	awarenessRadius = 90,
	wanderRadius = 180,
	hungerRate = 0.5,
	thirstRate = 0.4,
	restRate = 0.25,
	aggressive = true,
	damage = 18,
	attackRange = 3,
	attackCooldown = 1.5,
}

NPCs.hawk = {
	id = "hawk",
	name = "Prairie Hawk",
	category = "animal",
	speciesId = "hawk",
	scale = 0.8,
	walkSpeed = 0, -- Always flying
	runSpeed = 35,
	turnSpeed = 8,
	fleeDistance = 25,
	awarenessRadius = 150, -- Incredible eyesight
	wanderRadius = 200,
	hungerRate = 0.3,
	thirstRate = 0.2,
	restRate = 0.2,
	aggressive = true,
	damage = 12,
	attackRange = 5,
	attackCooldown = 4,
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

local NPCDefinitions = {}

function NPCDefinitions.get(npcId: string): Types.NPCDefinition?
	return NPCs[npcId]
end

function NPCDefinitions.getAll(): { [string]: Types.NPCDefinition }
	return NPCs
end

function NPCDefinitions.getByCategory(category: Types.NPCCategory): { Types.NPCDefinition }
	local result = {}
	for _, npc in NPCs do
		if npc.category == category then
			table.insert(result, npc)
		end
	end
	return result
end

function NPCDefinitions.getBySpecies(speciesId: string): Types.NPCDefinition?
	for _, npc in NPCs do
		if npc.speciesId == speciesId then
			return npc
		end
	end
	return nil
end

function NPCDefinitions.exists(npcId: string): boolean
	return NPCs[npcId] ~= nil
end

return NPCDefinitions
