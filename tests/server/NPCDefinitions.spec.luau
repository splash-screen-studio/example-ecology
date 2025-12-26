--!strict
--[[
    NPCDefinitions Tests

    Tests for the NPC definitions module.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local NPCDefinitions = require(ServerScriptService.Server.NPC.NPCDefinitions)
local SpeciesData = require(ServerScriptService.Server.Ecology.SpeciesData)

return function()
	describe("NPCDefinitions", function()
		describe("get", function()
			it("should return NPC definition for valid id", function()
				local rabbit = NPCDefinitions.get("marsh_rabbit")
				expect(rabbit).to.be.ok()
				expect(rabbit.id).to.equal("marsh_rabbit")
				expect(rabbit.name).to.equal("Marsh Rabbit")
			end)

			it("should return nil for invalid id", function()
				local fake = NPCDefinitions.get("fake_npc")
				expect(fake).to.equal(nil)
			end)
		end)

		describe("getAll", function()
			it("should return all NPCs", function()
				local all = NPCDefinitions.getAll()
				expect(all).to.be.ok()

				local count = 0
				for _ in all do
					count = count + 1
				end
				expect(count > 0).to.equal(true)
			end)
		end)

		describe("getByCategory", function()
			it("should return all animal NPCs", function()
				local animals = NPCDefinitions.getByCategory("animal")
				expect(#animals > 0).to.equal(true)

				for _, npc in animals do
					expect(npc.category).to.equal("animal")
				end
			end)
		end)

		describe("getBySpecies", function()
			it("should find NPC by species id", function()
				local rabbitNPC = NPCDefinitions.getBySpecies("marsh_rabbit")
				expect(rabbitNPC).to.be.ok()
				expect(rabbitNPC.speciesId).to.equal("marsh_rabbit")
			end)

			it("should return nil for non-existent species", function()
				local fake = NPCDefinitions.getBySpecies("fake_species")
				expect(fake).to.equal(nil)
			end)
		end)

		describe("exists", function()
			it("should return true for existing NPC", function()
				expect(NPCDefinitions.exists("marsh_rabbit")).to.equal(true)
			end)

			it("should return false for non-existent NPC", function()
				expect(NPCDefinitions.exists("fake_npc")).to.equal(false)
			end)
		end)

		describe("NPC properties", function()
			it("should have valid movement speeds", function()
				local wolf = NPCDefinitions.get("marsh_wolf")
				expect(wolf.walkSpeed > 0).to.equal(true)
				expect(wolf.runSpeed > wolf.walkSpeed).to.equal(true)
			end)

			it("aggressive NPCs should have combat stats", function()
				local wolf = NPCDefinitions.get("marsh_wolf")
				expect(wolf.aggressive).to.equal(true)
				expect(wolf.damage).to.be.ok()
				expect(wolf.damage > 0).to.equal(true)
				expect(wolf.attackRange).to.be.ok()
				expect(wolf.attackCooldown).to.be.ok()
			end)

			it("non-aggressive NPCs should have flee distance", function()
				local rabbit = NPCDefinitions.get("marsh_rabbit")
				expect(rabbit.aggressive).to.equal(false)
				expect(rabbit.fleeDistance > 0).to.equal(true)
			end)

			it("should have awareness radius", function()
				local deer = NPCDefinitions.get("wetland_deer")
				expect(deer.awarenessRadius > 0).to.equal(true)
				expect(deer.awarenessRadius >= deer.fleeDistance).to.equal(true)
			end)
		end)

		describe("species linkage", function()
			it("all NPCs should link to valid species", function()
				local allNPCs = NPCDefinitions.getAll()
				for npcId, npc in allNPCs do
					if npc.speciesId then
						local species = SpeciesData[npc.speciesId]
						expect(species).to.be.ok()
					end
				end
			end)

			it("NPC ids should match species ids", function()
				local allNPCs = NPCDefinitions.getAll()
				for npcId, npc in allNPCs do
					if npc.speciesId then
						expect(npc.id).to.equal(npc.speciesId)
					end
				end
			end)
		end)

		describe("wetland NPCs", function()
			it("should have marsh_rabbit", function()
				local rabbit = NPCDefinitions.get("marsh_rabbit")
				expect(rabbit).to.be.ok()
			end)

			it("should have wetland_deer", function()
				local deer = NPCDefinitions.get("wetland_deer")
				expect(deer).to.be.ok()
			end)

			it("should have marsh_wolf (apex predator)", function()
				local wolf = NPCDefinitions.get("marsh_wolf")
				expect(wolf).to.be.ok()
				expect(wolf.fleeDistance).to.equal(0) -- Apex doesn't flee
			end)
		end)

		describe("plains NPCs", function()
			it("should have plains_hare", function()
				local hare = NPCDefinitions.get("plains_hare")
				expect(hare).to.be.ok()
			end)

			it("should have pronghorn (fast)", function()
				local pronghorn = NPCDefinitions.get("pronghorn")
				expect(pronghorn).to.be.ok()
				expect(pronghorn.runSpeed >= 40).to.equal(true) -- Very fast
			end)

			it("should have hawk (great awareness)", function()
				local hawk = NPCDefinitions.get("hawk")
				expect(hawk).to.be.ok()
				expect(hawk.awarenessRadius >= 150).to.equal(true)
			end)
		end)
	end)
end
