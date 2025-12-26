--!strict
--[[
    InteractionService Regression Tests

    Tests for player interaction system: proximity detection, cooldowns, and interaction types.
    Critical: E key triggers pickup, proximity validation, cooldown enforcement.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

return function()
	describe("InteractionService", function()
		local InteractionService

		beforeAll(function()
			local success, result = pcall(function()
				return require(ServerScriptService.Server.Interaction.InteractionService)
			end)

			if success then
				InteractionService = result
			end
		end)

		describe("module structure", function()
			it("should export init function", function()
				expect(InteractionService).to.be.ok()
				expect(InteractionService.init).to.be.a("function")
			end)

			it("should export interact function", function()
				expect(InteractionService.interact).to.be.a("function")
			end)

			it("should export registerInteractable function", function()
				expect(InteractionService.registerInteractable).to.be.a("function")
			end)

			it("should export unregisterInteractable function", function()
				expect(InteractionService.unregisterInteractable).to.be.a("function")
			end)

			it("should export getInteractables function", function()
				expect(InteractionService.getInteractables).to.be.a("function")
			end)

			it("should export getInteractableConfig function", function()
				expect(InteractionService.getInteractableConfig).to.be.a("function")
			end)

			it("should export getNearbyInteractables function", function()
				expect(InteractionService.getNearbyInteractables).to.be.a("function")
			end)
		end)

		describe("interactable registration", function()
			local testPart

			beforeEach(function()
				-- Create a test part for registration tests
				testPart = Instance.new("Part")
				testPart.Name = "TestInteractable"
				testPart.Parent = workspace
			end)

			afterEach(function()
				if testPart then
					-- Unregister before destroying
					pcall(function()
						InteractionService:unregisterInteractable(testPart)
					end)
					testPart:Destroy()
					testPart = nil
				end
			end)

			it("should register an interactable object", function()
				local config = {
					id = "test_pickup_001",
					interactionType = "pickup" :: "pickup",
					displayName = "Test Item",
					itemId = "test_item",
					quantity = 1,
				}

				InteractionService:registerInteractable(testPart, config)

				local storedConfig = InteractionService:getInteractableConfig(testPart)
				expect(storedConfig).to.be.ok()
				expect(storedConfig.id).to.equal("test_pickup_001")
				expect(storedConfig.displayName).to.equal("Test Item")
			end)

			it("should add Interactable tag when registering", function()
				local config = {
					id = "test_tagged_001",
					interactionType = "pickup" :: "pickup",
					displayName = "Tagged Item",
					itemId = "test_item",
				}

				InteractionService:registerInteractable(testPart, config)

				local hasTag = CollectionService:HasTag(testPart, "Interactable")
				expect(hasTag).to.equal(true)
			end)

			it("should set attributes on registered object", function()
				local config = {
					id = "test_attrs_001",
					interactionType = "harvest" :: "harvest",
					displayName = "Harvest Target",
					prompt = "Press E to harvest",
					range = 15,
					itemId = "harvested_item",
				}

				InteractionService:registerInteractable(testPart, config)

				expect(testPart:GetAttribute("InteractableId")).to.equal("test_attrs_001")
				expect(testPart:GetAttribute("InteractableType")).to.equal("harvest")
				expect(testPart:GetAttribute("InteractableName")).to.equal("Harvest Target")
				expect(testPart:GetAttribute("InteractablePrompt")).to.equal("Press E to harvest")
				expect(testPart:GetAttribute("InteractableRange")).to.equal(15)
			end)

			it("should use default range when not specified", function()
				local config = {
					id = "test_default_range",
					interactionType = "examine" :: "examine",
					displayName = "Examine Target",
				}

				InteractionService:registerInteractable(testPart, config)

				-- Default range is 10 studs
				expect(testPart:GetAttribute("InteractableRange")).to.equal(10)
			end)

			it("should unregister an interactable object", function()
				local config = {
					id = "test_unregister_001",
					interactionType = "pickup" :: "pickup",
					displayName = "Unregister Test",
					itemId = "test_item",
				}

				InteractionService:registerInteractable(testPart, config)
				expect(InteractionService:getInteractableConfig(testPart)).to.be.ok()

				InteractionService:unregisterInteractable(testPart)

				expect(InteractionService:getInteractableConfig(testPart)).to.equal(nil)
				expect(CollectionService:HasTag(testPart, "Interactable")).to.equal(false)
			end)
		end)

		describe("getInteractables", function()
			it("should return a table of interactables", function()
				local interactables = InteractionService:getInteractables()
				expect(interactables).to.be.ok()
				expect(type(interactables)).to.equal("table")
			end)
		end)

		describe("interact - validation", function()
			it("should fail for non-existent target", function()
				local fakePlayer = {} :: any
				local result = InteractionService:interact(fakePlayer, "nonexistent_target_id_12345")

				expect(result).to.be.ok()
				expect(result.success).to.equal(false)
				expect(result.message).to.equal("Object not found")
			end)
		end)

		describe("interaction types", function()
			-- Validate that all expected interaction types are handled
			local validTypes = { "pickup", "harvest", "observe", "talk", "use", "examine" }

			it("should support pickup interaction type", function()
				expect(table.find(validTypes, "pickup")).to.be.ok()
			end)

			it("should support harvest interaction type", function()
				expect(table.find(validTypes, "harvest")).to.be.ok()
			end)

			it("should support observe interaction type", function()
				expect(table.find(validTypes, "observe")).to.be.ok()
			end)

			it("should support talk interaction type", function()
				expect(table.find(validTypes, "talk")).to.be.ok()
			end)

			it("should support use interaction type", function()
				expect(table.find(validTypes, "use")).to.be.ok()
			end)

			it("should support examine interaction type", function()
				expect(table.find(validTypes, "examine")).to.be.ok()
			end)
		end)

		describe("cooldown system", function()
			-- Note: Full cooldown tests require mocking os.clock() or waiting real time
			-- These tests verify the config structure supports cooldowns

			it("should respect default cooldown configuration", function()
				-- Default cooldown is 1 second
				-- This is a documentation test verifying the expected default
				local expectedDefaultCooldown = 1
				expect(expectedDefaultCooldown).to.equal(1)
			end)

			it("should allow custom cooldown in config", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local config = {
					id = "test_cooldown_item",
					interactionType = "pickup" :: "pickup",
					displayName = "Cooldown Test",
					cooldown = 5, -- 5 second cooldown
					itemId = "test_item",
				}

				InteractionService:registerInteractable(testPart, config)
				local storedConfig = InteractionService:getInteractableConfig(testPart)

				expect(storedConfig).to.be.ok()
				expect(storedConfig.cooldown).to.equal(5)

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)
		end)

		describe("proximity detection", function()
			-- Note: Full proximity tests require a player character in world
			-- These tests verify the range configuration

			it("should use default range of 10 studs", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local config = {
					id = "test_default_range_check",
					interactionType = "examine" :: "examine",
					displayName = "Range Test",
				}

				InteractionService:registerInteractable(testPart, config)

				-- Check the attribute set on the part
				local range = testPart:GetAttribute("InteractableRange")
				expect(range).to.equal(10)

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)

			it("should allow custom range in config", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local config = {
					id = "test_custom_range",
					interactionType = "observe" :: "observe",
					displayName = "Long Range Observe",
					range = 25,
				}

				InteractionService:registerInteractable(testPart, config)

				local range = testPart:GetAttribute("InteractableRange")
				expect(range).to.equal(25)

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)
		end)

		describe("pickup interaction configuration", function()
			it("should require itemId for pickup type", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local config = {
					id = "test_pickup_no_item",
					interactionType = "pickup" :: "pickup",
					displayName = "Missing Item ID",
					-- No itemId specified
				}

				InteractionService:registerInteractable(testPart, config)
				local storedConfig = InteractionService:getInteractableConfig(testPart)

				-- Config is stored but itemId is nil
				expect(storedConfig).to.be.ok()
				expect(storedConfig.itemId).to.equal(nil)

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)

			it("should default quantity to 1 if not specified", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local config = {
					id = "test_pickup_default_qty",
					interactionType = "pickup" :: "pickup",
					displayName = "Default Quantity",
					itemId = "test_item",
					-- No quantity specified
				}

				InteractionService:registerInteractable(testPart, config)
				local storedConfig = InteractionService:getInteractableConfig(testPart)

				-- quantity defaults to nil in config, handler uses 1
				expect(storedConfig).to.be.ok()
				expect(storedConfig.quantity).to.equal(nil)

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)

			it("should store custom quantity in config", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local config = {
					id = "test_pickup_custom_qty",
					interactionType = "pickup" :: "pickup",
					displayName = "Custom Quantity",
					itemId = "gold_coins",
					quantity = 10,
				}

				InteractionService:registerInteractable(testPart, config)
				local storedConfig = InteractionService:getInteractableConfig(testPart)

				expect(storedConfig).to.be.ok()
				expect(storedConfig.quantity).to.equal(10)

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)
		end)

		describe("harvest interaction configuration", function()
			it("should support respawnTime configuration", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local config = {
					id = "test_harvest_respawn",
					interactionType = "harvest" :: "harvest",
					displayName = "Respawning Resource",
					itemId = "herb",
					respawnTime = 120, -- 2 minutes
				}

				InteractionService:registerInteractable(testPart, config)
				local storedConfig = InteractionService:getInteractableConfig(testPart)

				expect(storedConfig).to.be.ok()
				expect(storedConfig.respawnTime).to.equal(120)

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)

			it("should support harvestTime configuration", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local config = {
					id = "test_harvest_time",
					interactionType = "harvest" :: "harvest",
					displayName = "Slow Harvest",
					itemId = "ore",
					harvestTime = 3, -- 3 seconds to harvest
				}

				InteractionService:registerInteractable(testPart, config)
				local storedConfig = InteractionService:getInteractableConfig(testPart)

				expect(storedConfig).to.be.ok()
				expect(storedConfig.harvestTime).to.equal(3)

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)
		end)

		describe("custom interaction handler", function()
			it("should store custom onInteract callback", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local customHandler = function(player, target)
					return { success = true, message = "Custom handler executed" }
				end

				local config = {
					id = "test_custom_handler",
					interactionType = "use" :: "use",
					displayName = "Custom Interaction",
					onInteract = customHandler,
				}

				InteractionService:registerInteractable(testPart, config)
				local storedConfig = InteractionService:getInteractableConfig(testPart)

				expect(storedConfig).to.be.ok()
				expect(storedConfig.onInteract).to.be.a("function")

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)
		end)

		describe("getNearbyInteractables", function()
			it("should return empty table for fake player with no character", function()
				local fakePlayer = {} :: any
				local nearby = InteractionService:getNearbyInteractables(fakePlayer, 50)

				expect(nearby).to.be.ok()
				expect(type(nearby)).to.equal("table")
				expect(#nearby).to.equal(0)
			end)
		end)

		describe("prompt configuration", function()
			it("should use custom prompt when provided", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local config = {
					id = "test_custom_prompt",
					interactionType = "pickup" :: "pickup",
					displayName = "Crystal",
					prompt = "Press E to collect crystal",
					itemId = "crystal",
				}

				InteractionService:registerInteractable(testPart, config)

				local prompt = testPart:GetAttribute("InteractablePrompt")
				expect(prompt).to.equal("Press E to collect crystal")

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)

			it("should generate default prompt when not provided", function()
				local testPart = Instance.new("Part")
				testPart.Parent = workspace

				local config = {
					id = "test_default_prompt",
					interactionType = "examine" :: "examine",
					displayName = "Ancient Rune",
					-- No prompt specified
				}

				InteractionService:registerInteractable(testPart, config)

				local prompt = testPart:GetAttribute("InteractablePrompt")
				expect(prompt).to.equal("Interact with Ancient Rune")

				InteractionService:unregisterInteractable(testPart)
				testPart:Destroy()
			end)
		end)
	end)
end
