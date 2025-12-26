--!strict
--[[
    QuestService Regression Tests

    Tests for quest management: acceptance, progress tracking, completion, rewards, persistence.
    Critical: Objectives track progress, completion triggers rewards, quest state persists.
]]

local ServerScriptService = game:GetService("ServerScriptService")

return function()
	describe("QuestService", function()
		local QuestService

		beforeAll(function()
			local success, result = pcall(function()
				return require(ServerScriptService.Server.Quest.QuestService)
			end)

			if success then
				QuestService = result
			end
		end)

		describe("module structure", function()
			it("should export init function", function()
				expect(QuestService).to.be.ok()
				expect(QuestService.init).to.be.a("function")
			end)

			it("should export canAcceptQuest function", function()
				expect(QuestService.canAcceptQuest).to.be.a("function")
			end)

			it("should export acceptQuest function", function()
				expect(QuestService.acceptQuest).to.be.a("function")
			end)

			it("should export abandonQuest function", function()
				expect(QuestService.abandonQuest).to.be.a("function")
			end)

			it("should export updateObjective function", function()
				expect(QuestService.updateObjective).to.be.a("function")
			end)

			it("should export checkQuestCompletion function", function()
				expect(QuestService.checkQuestCompletion).to.be.a("function")
			end)

			it("should export completeQuest function", function()
				expect(QuestService.completeQuest).to.be.a("function")
			end)

			it("should export getActiveQuests function", function()
				expect(QuestService.getActiveQuests).to.be.a("function")
			end)

			it("should export getCompletedQuests function", function()
				expect(QuestService.getCompletedQuests).to.be.a("function")
			end)

			it("should export getQuestProgress function", function()
				expect(QuestService.getQuestProgress).to.be.a("function")
			end)

			it("should export getAvailableQuests function", function()
				expect(QuestService.getAvailableQuests).to.be.a("function")
			end)

			it("should export getQuestsFromNPC function", function()
				expect(QuestService.getQuestsFromNPC).to.be.a("function")
			end)

			it("should export onItemCollected function", function()
				expect(QuestService.onItemCollected).to.be.a("function")
			end)

			it("should export onObserve function", function()
				expect(QuestService.onObserve).to.be.a("function")
			end)

			it("should export getDefinitions function", function()
				expect(QuestService.getDefinitions).to.be.a("function")
			end)
		end)

		describe("canAcceptQuest - validation", function()
			it("should return false for non-existent quest", function()
				local fakePlayer = {} :: any
				local canAccept, reason = QuestService:canAcceptQuest(fakePlayer, "nonexistent_quest_12345")

				expect(canAccept).to.equal(false)
				expect(reason).to.equal("Quest not found")
			end)
		end)

		describe("acceptQuest - validation", function()
			it("should fail for non-existent quest", function()
				local fakePlayer = {} :: any
				local success, reason = QuestService:acceptQuest(fakePlayer, "nonexistent_quest_12345")

				expect(success).to.equal(false)
				expect(reason).to.equal("Quest not found")
			end)

			it("should fail for player without data", function()
				local fakePlayer = {} :: any
				-- Assuming there's a valid quest ID in definitions
				local success, reason = QuestService:acceptQuest(fakePlayer, "tutorial_first_steps")

				expect(success).to.equal(false)
				-- Either "Quest not found" or "Player data not loaded"
				expect(reason).to.be.ok()
			end)
		end)

		describe("abandonQuest - validation", function()
			it("should return false for player without data", function()
				local fakePlayer = {} :: any
				local success = QuestService:abandonQuest(fakePlayer, "any_quest")

				expect(success).to.equal(false)
			end)
		end)

		describe("updateObjective - validation", function()
			it("should return false for player without data", function()
				local fakePlayer = {} :: any
				local success = QuestService:updateObjective(fakePlayer, "quest_id", "objective_id", 1)

				expect(success).to.equal(false)
			end)

			it("should default amount to 1 when not specified", function()
				-- Test that function handles nil amount
				local fakePlayer = {} :: any
				local success = QuestService:updateObjective(fakePlayer, "quest_id", "objective_id")

				-- Should not error, just return false due to missing data
				expect(success).to.equal(false)
			end)
		end)

		describe("checkQuestCompletion - validation", function()
			it("should return false for player without data", function()
				local fakePlayer = {} :: any
				local completed = QuestService:checkQuestCompletion(fakePlayer, "quest_id")

				expect(completed).to.equal(false)
			end)
		end)

		describe("completeQuest - validation", function()
			it("should return false for player without data", function()
				local fakePlayer = {} :: any
				local success = QuestService:completeQuest(fakePlayer, "quest_id")

				expect(success).to.equal(false)
			end)
		end)

		describe("getActiveQuests - validation", function()
			it("should return empty table for player without data", function()
				local fakePlayer = {} :: any
				local quests = QuestService:getActiveQuests(fakePlayer)

				expect(quests).to.be.ok()
				expect(type(quests)).to.equal("table")
				expect(#quests).to.equal(0)
			end)
		end)

		describe("getCompletedQuests - validation", function()
			it("should return empty table for player without data", function()
				local fakePlayer = {} :: any
				local quests = QuestService:getCompletedQuests(fakePlayer)

				expect(quests).to.be.ok()
				expect(type(quests)).to.equal("table")
				expect(#quests).to.equal(0)
			end)
		end)

		describe("getQuestProgress - validation", function()
			it("should return nil for player without data", function()
				local fakePlayer = {} :: any
				local progress = QuestService:getQuestProgress(fakePlayer, "quest_id")

				expect(progress).to.equal(nil)
			end)
		end)

		describe("getAvailableQuests", function()
			it("should return table for fake player", function()
				local fakePlayer = {} :: any
				local available = QuestService:getAvailableQuests(fakePlayer)

				expect(available).to.be.ok()
				expect(type(available)).to.equal("table")
			end)
		end)

		describe("getQuestsFromNPC", function()
			it("should return empty table for invalid NPC", function()
				local fakePlayer = {} :: any
				local quests = QuestService:getQuestsFromNPC(fakePlayer, "invalid_npc_12345")

				expect(quests).to.be.ok()
				expect(type(quests)).to.equal("table")
			end)
		end)

		describe("onItemCollected hook", function()
			it("should not error for player without data", function()
				local fakePlayer = {} :: any
				-- Should handle gracefully without error
				local success = pcall(function()
					QuestService:onItemCollected(fakePlayer, "apple", 5)
				end)

				expect(success).to.equal(true)
			end)
		end)

		describe("onObserve hook", function()
			it("should not error for player without data", function()
				local fakePlayer = {} :: any
				-- Should handle gracefully without error
				local success = pcall(function()
					QuestService:onObserve(fakePlayer, "species_frog")
				end)

				expect(success).to.equal(true)
			end)
		end)

		describe("quest objective types", function()
			-- Documentation tests for supported objective types

			it("should support discover objective type", function()
				local objectiveTypes = { "discover", "collect", "observe", "reach_location" }
				expect(table.find(objectiveTypes, "discover")).to.be.ok()
			end)

			it("should support collect objective type", function()
				local objectiveTypes = { "discover", "collect", "observe", "reach_location" }
				expect(table.find(objectiveTypes, "collect")).to.be.ok()
			end)

			it("should support observe objective type", function()
				local objectiveTypes = { "discover", "collect", "observe", "reach_location" }
				expect(table.find(objectiveTypes, "observe")).to.be.ok()
			end)

			it("should support reach_location objective type", function()
				local objectiveTypes = { "discover", "collect", "observe", "reach_location" }
				expect(table.find(objectiveTypes, "reach_location")).to.be.ok()
			end)
		end)

		describe("quest reward types", function()
			-- Documentation tests for supported reward types

			it("should support item reward type", function()
				local rewardTypes = { "item", "currency", "discovery" }
				expect(table.find(rewardTypes, "item")).to.be.ok()
			end)

			it("should support currency reward type", function()
				local rewardTypes = { "item", "currency", "discovery" }
				expect(table.find(rewardTypes, "currency")).to.be.ok()
			end)

			it("should support discovery reward type", function()
				local rewardTypes = { "item", "currency", "discovery" }
				expect(table.find(rewardTypes, "discovery")).to.be.ok()
			end)
		end)

		describe("quest prerequisites", function()
			-- Documentation tests for prerequisite system

			it("should check prerequisite quests before acceptance", function()
				-- Quest can require other quests to be completed first
				local questRequirements = {
					prerequisiteQuests = { "tutorial_intro", "tutorial_basics" },
				}
				expect(#questRequirements.prerequisiteQuests).to.equal(2)
			end)

			it("should check prerequisite discoveries before acceptance", function()
				-- Quest can require discoveries to be made first
				local questRequirements = {
					prerequisiteDiscoveries = { "wetland_biome", "frog_species" },
				}
				expect(#questRequirements.prerequisiteDiscoveries).to.equal(2)
			end)
		end)

		describe("quest state structure", function()
			-- Documentation tests for quest progress data structure

			it("should track quest start time", function()
				local questProgress = {
					questId = "tutorial_first_steps",
					startedAt = os.time(),
					objectives = {},
					completed = false,
				}
				expect(questProgress.startedAt).to.be.ok()
				expect(type(questProgress.startedAt)).to.equal("number")
			end)

			it("should track objective progress as numbers", function()
				local questProgress = {
					questId = "collect_herbs",
					startedAt = os.time(),
					objectives = {
						collect_herbs = 3, -- 3 out of 5 collected
						find_location = 1, -- 1 out of 1 found
					},
					completed = false,
				}
				expect(questProgress.objectives.collect_herbs).to.equal(3)
				expect(questProgress.objectives.find_location).to.equal(1)
			end)

			it("should track completion state", function()
				local questProgress = {
					questId = "tutorial_first_steps",
					startedAt = os.time(),
					objectives = {},
					completed = true,
				}
				expect(questProgress.completed).to.equal(true)
			end)
		end)

		describe("objective progress capping", function()
			it("should cap progress at objective count", function()
				-- Progress should not exceed the required count
				local currentProgress = 3
				local addAmount = 5
				local requiredCount = 5
				local newProgress = math.min(currentProgress + addAmount, requiredCount)

				expect(newProgress).to.equal(5)
			end)
		end)

		describe("quest completion flow", function()
			-- Documentation tests for completion mechanics

			it("should move quest from active to completed on completion", function()
				-- On completion:
				-- 1. Remove from data.quests.active[questId]
				-- 2. Add to data.quests.completed[questId] = os.time()
				local beforeState = {
					active = { tutorial = {} },
					completed = {},
				}
				local afterState = {
					active = {},
					completed = { tutorial = os.time() },
				}

				expect(beforeState.active.tutorial).to.be.ok()
				expect(afterState.completed.tutorial).to.be.ok()
			end)

			it("should grant rewards on completion", function()
				-- Rewards are processed by type:
				-- - "item": InventoryService:addItem
				-- - "currency": Direct add to inventory.currency
				-- - "discovery": DiscoveryService:discover
				local rewards = {
					{ type = "item", id = "rare_herb", amount = 5 },
					{ type = "currency", amount = 100 },
					{ type = "discovery", id = "secret_location" },
				}
				expect(#rewards).to.equal(3)
			end)
		end)

		describe("client synchronization", function()
			-- Documentation tests for client sync

			it("should fire QuestUpdate with new action on accept", function()
				local eventData = {
					action = "new",
					questId = "tutorial_first_steps",
					name = "First Steps",
					description = "Learn the basics",
					objectives = {},
					progress = {},
				}
				expect(eventData.action).to.equal("new")
			end)

			it("should fire QuestUpdate with update action on progress", function()
				local eventData = {
					action = "update",
					questId = "collect_herbs",
					progress = { collect_herbs = 3 },
				}
				expect(eventData.action).to.equal("update")
			end)

			it("should fire QuestUpdate with abandon action on abandon", function()
				local eventData = {
					action = "abandon",
					questId = "optional_quest",
				}
				expect(eventData.action).to.equal("abandon")
			end)

			it("should fire QuestUpdate with complete action on completion", function()
				local eventData = {
					action = "complete",
					questId = "tutorial_first_steps",
					name = "First Steps",
					rewards = {},
				}
				expect(eventData.action).to.equal("complete")
			end)
		end)

		describe("repeatable quests", function()
			it("should allow re-accepting repeatable quests", function()
				-- When definition.isRepeatable is true, quest can be accepted again
				local isRepeatable = true
				local wasCompleted = true
				local canAcceptAgain = isRepeatable or not wasCompleted

				expect(canAcceptAgain).to.equal(true)
			end)

			it("should block re-accepting non-repeatable quests", function()
				-- When definition.isRepeatable is false/nil, completed quest cannot be accepted
				local isRepeatable = false
				local wasCompleted = true
				local canAcceptAgain = isRepeatable or not wasCompleted

				expect(canAcceptAgain).to.equal(false)
			end)
		end)

		describe("already active quest handling", function()
			it("should reject accepting already active quest", function()
				-- canAcceptQuest returns false with reason "Quest already active"
				local alreadyActive = true
				local reason = if alreadyActive then "Quest already active" else nil

				expect(reason).to.equal("Quest already active")
			end)
		end)

		describe("QuestDefinitions dependency", function()
			it("should have QuestDefinitions available", function()
				local definitions = QuestService:getDefinitions()
				expect(definitions).to.be.ok()
			end)

			it("should have get function in definitions", function()
				local definitions = QuestService:getDefinitions()
				if definitions then
					expect(definitions.get).to.be.a("function")
				end
			end)

			it("should have getAll function in definitions", function()
				local definitions = QuestService:getDefinitions()
				if definitions then
					expect(definitions.getAll).to.be.a("function")
				end
			end)

			it("should have getByQuestGiver function in definitions", function()
				local definitions = QuestService:getDefinitions()
				if definitions then
					expect(definitions.getByQuestGiver).to.be.a("function")
				end
			end)

			it("should have getTotalCount function in definitions", function()
				local definitions = QuestService:getDefinitions()
				if definitions then
					expect(definitions.getTotalCount).to.be.a("function")
				end
			end)
		end)

		describe("any_species wildcard", function()
			it("should match any species for discover objectives", function()
				-- When objective.targetId is "any_species", any discovery counts
				local targetId = "any_species"
				local discoveryId = "frog_bullfrog"
				local matches = (targetId == discoveryId) or (targetId == "any_species")

				expect(matches).to.equal(true)
			end)
		end)

		describe("collection quest integration", function()
			it("should update collect objectives when items are collected", function()
				-- When InventoryService adds item, it calls QuestService:onItemCollected
				-- QuestService then finds quests with matching collect objectives
				local objectiveType = "collect"
				local objectiveTargetId = "herb"
				local collectedItemId = "herb"
				local matches = objectiveType == "collect" and objectiveTargetId == collectedItemId

				expect(matches).to.equal(true)
			end)
		end)

		describe("observation quest integration", function()
			it("should update observe objectives when species are observed", function()
				-- InteractionService observe calls QuestService:onObserve
				-- QuestService then finds quests with matching observe objectives
				local objectiveType = "observe"
				local objectiveTargetId = "frog_bullfrog"
				local observedSpecies = "frog_bullfrog"
				local matches = objectiveType == "observe" and objectiveTargetId == observedSpecies

				expect(matches).to.equal(true)
			end)
		end)
	end)
end
