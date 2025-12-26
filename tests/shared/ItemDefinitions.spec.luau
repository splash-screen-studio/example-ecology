--!strict
--[[
    ItemDefinitions Tests

    Tests for the shared item definitions module.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Items = require(ReplicatedStorage.Shared.Items)
local ItemDefinitions = Items.Definitions

return function()
	describe("ItemDefinitions", function()
		describe("get", function()
			it("should return item definition for valid id", function()
				local apple = ItemDefinitions.get("apple")
				expect(apple).to.be.ok()
				expect(apple.id).to.equal("apple")
				expect(apple.name).to.equal("Wild Apple")
			end)

			it("should return nil for invalid id", function()
				local fake = ItemDefinitions.get("fake_item_that_doesnt_exist")
				expect(fake).to.equal(nil)
			end)
		end)

		describe("getByCategory", function()
			it("should return all food items", function()
				local food = ItemDefinitions.getByCategory("food")
				expect(#food).to.be.ok()
				expect(#food > 0).to.equal(true)

				for _, item in food do
					expect(item.category).to.equal("food")
				end
			end)

			it("should return all seed items", function()
				local seeds = ItemDefinitions.getByCategory("seed")
				expect(#seeds).to.be.ok()

				for _, item in seeds do
					expect(item.category).to.equal("seed")
				end
			end)

			it("should return empty for invalid category", function()
				local fake = ItemDefinitions.getByCategory("not_a_category" :: any)
				expect(#fake).to.equal(0)
			end)
		end)

		describe("getAll", function()
			it("should return all items", function()
				local all = ItemDefinitions.getAll()
				expect(all).to.be.ok()

				local count = 0
				for _ in all do
					count = count + 1
				end
				expect(count > 0).to.equal(true)
			end)
		end)

		describe("item properties", function()
			it("food items should be consumable", function()
				local apple = ItemDefinitions.get("apple")
				expect(apple.consumable).to.equal(true)
				expect(apple.usable).to.equal(true)
			end)

			it("food items should restore hunger", function()
				local apple = ItemDefinitions.get("apple")
				expect(apple.effects).to.be.ok()
				expect(apple.effects.hungerRestore).to.be.ok()
				expect(apple.effects.hungerRestore > 0).to.equal(true)
			end)

			it("tools should not be consumable", function()
				local shovel = ItemDefinitions.get("shovel")
				if shovel then
					expect(shovel.consumable).to.equal(false)
				end
			end)

			it("stackable items should have maxStack", function()
				local apple = ItemDefinitions.get("apple")
				expect(apple.stackable).to.equal(true)
				expect(apple.maxStack).to.be.ok()
				expect(apple.maxStack > 1).to.equal(true)
			end)
		end)

		describe("seeds", function()
			it("seeds should have eco action effect", function()
				local grassSeeds = ItemDefinitions.get("grass_seeds")
				expect(grassSeeds).to.be.ok()
				expect(grassSeeds.effects).to.be.ok()
				expect(grassSeeds.effects.ecoAction).to.equal("plant")
				expect(grassSeeds.effects.targetSpecies).to.equal("wetland_grass")
			end)
		end)
	end)
end
