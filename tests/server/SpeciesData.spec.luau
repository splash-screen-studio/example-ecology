--!strict
--[[
    SpeciesData Tests

    Tests for the ecology species data module.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local SpeciesData = require(ServerScriptService.Server.Ecology.SpeciesData)

return function()
	describe("SpeciesData", function()
		describe("species definitions", function()
			it("should have wetland_grass producer", function()
				local grass = SpeciesData.wetland_grass
				expect(grass).to.be.ok()
				expect(grass.id).to.equal("wetland_grass")
				expect(grass.category).to.equal("producer")
			end)

			it("should have marsh_rabbit herbivore", function()
				local rabbit = SpeciesData.marsh_rabbit
				expect(rabbit).to.be.ok()
				expect(rabbit.category).to.equal("herbivore")
				expect(rabbit.carryingCapacity > 0).to.equal(true)
			end)

			it("should have marsh_wolf carnivore", function()
				local wolf = SpeciesData.marsh_wolf
				expect(wolf).to.be.ok()
				expect(wolf.category).to.equal("carnivore")
				expect(#wolf.preyOn > 0).to.equal(true)
			end)

			it("species should have valid growth rates", function()
				local grass = SpeciesData.wetland_grass
				expect(grass.baseGrowthRate >= 1.0).to.equal(true)
				expect(grass.baseGrowthRate <= 1.2).to.equal(true)
			end)

			it("carnivores should have prey", function()
				local fox = SpeciesData.marsh_fox
				expect(fox.category).to.equal("carnivore")
				expect(#fox.preyOn > 0).to.equal(true)
			end)

			it("herbivores should have predators", function()
				local rabbit = SpeciesData.marsh_rabbit
				expect(#rabbit.predators > 0).to.equal(true)
			end)
		end)

		describe("getForBiome", function()
			it("should return wetland species", function()
				local wetlandSpecies = SpeciesData.getForBiome("wetland")
				expect(#wetlandSpecies > 0).to.equal(true)

				for _, species in wetlandSpecies do
					expect(species.preferredBiome).to.equal("wetland")
				end
			end)

			it("should return plains species", function()
				local plainsSpecies = SpeciesData.getForBiome("plains")
				expect(#plainsSpecies > 0).to.equal(true)

				for _, species in plainsSpecies do
					expect(species.preferredBiome).to.equal("plains")
				end
			end)

			it("should return empty for invalid biome", function()
				local invalidSpecies = SpeciesData.getForBiome("ocean")
				expect(#invalidSpecies).to.equal(0)
			end)
		end)

		describe("getByCategory", function()
			it("should return all producers", function()
				local producers = SpeciesData.getByCategory("producer")
				expect(#producers > 0).to.equal(true)

				for _, species in producers do
					expect(species.category).to.equal("producer")
					expect(species.foodNeed).to.equal(0) -- Producers don't need food
				end
			end)

			it("should return all herbivores", function()
				local herbivores = SpeciesData.getByCategory("herbivore")
				expect(#herbivores > 0).to.equal(true)

				for _, species in herbivores do
					expect(species.category).to.equal("herbivore")
					expect(species.foodNeed > 0).to.equal(true)
				end
			end)

			it("should return all carnivores", function()
				local carnivores = SpeciesData.getByCategory("carnivore")
				expect(#carnivores > 0).to.equal(true)

				for _, species in carnivores do
					expect(species.category).to.equal("carnivore")
					expect(#species.preyOn > 0).to.equal(true)
				end
			end)
		end)

		describe("food web integrity", function()
			it("prey references should exist", function()
				local fox = SpeciesData.marsh_fox
				for _, preyId in fox.preyOn do
					local prey = SpeciesData[preyId]
					expect(prey).to.be.ok()
				end
			end)

			it("predator references should exist", function()
				local rabbit = SpeciesData.marsh_rabbit
				for _, predatorId in rabbit.predators do
					local predator = SpeciesData[predatorId]
					expect(predator).to.be.ok()
				end
			end)

			it("prey-predator relationships should be bidirectional", function()
				-- If A preys on B, then B should list A as a predator
				local fox = SpeciesData.marsh_fox
				for _, preyId in fox.preyOn do
					local prey = SpeciesData[preyId]
					if prey and type(prey) == "table" then
						local foundPredator = false
						for _, predId in prey.predators do
							if predId == "marsh_fox" then
								foundPredator = true
								break
							end
						end
						expect(foundPredator).to.equal(true)
					end
				end
			end)
		end)

		describe("population constraints", function()
			it("minViablePopulation should be less than carryingCapacity", function()
				local allSpecies = {}
				for key, value in SpeciesData do
					if type(value) == "table" and value.id then
						table.insert(allSpecies, value)
					end
				end

				for _, species in allSpecies do
					expect(species.minViablePopulation < species.carryingCapacity).to.equal(true)
				end
			end)

			it("apex predators should have smaller carrying capacity", function()
				local wolf = SpeciesData.marsh_wolf
				local rabbit = SpeciesData.marsh_rabbit
				expect(wolf.carryingCapacity < rabbit.carryingCapacity).to.equal(true)
			end)
		end)
	end)
end
