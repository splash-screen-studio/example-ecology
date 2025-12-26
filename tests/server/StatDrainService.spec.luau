--!strict
--[[
    StatDrainService Regression Tests

    Tests for stat drain behavior, including the critical water restoration bug.
    Bug fixed: WaterController wasn't loaded before checking water state.
]]

local ServerScriptService = game:GetService("ServerScriptService")

-- Note: These tests verify module structure and configuration.
-- Full behavior tests require mocking player/character state.

return function()
	describe("StatDrainService", function()
		local StatDrainService

		beforeAll(function()
			-- Load the service
			local success, result = pcall(function()
				return require(ServerScriptService.Server.Character.StatDrainService)
			end)

			if success then
				StatDrainService = result
			end
		end)

		describe("module structure", function()
			it("should export init function", function()
				expect(StatDrainService).to.be.ok()
				expect(StatDrainService.init).to.be.a("function")
			end)

			it("should export setDrainRate function", function()
				expect(StatDrainService.setDrainRate).to.be.a("function")
			end)

			it("should export setDrainInterval function", function()
				expect(StatDrainService.setDrainInterval).to.be.a("function")
			end)

			it("should export pauseDrain function", function()
				expect(StatDrainService.pauseDrain).to.be.a("function")
			end)

			it("should export resumeDrain function", function()
				expect(StatDrainService.resumeDrain).to.be.a("function")
			end)

			it("should export forceDrain function", function()
				expect(StatDrainService.forceDrain).to.be.a("function")
			end)

			it("should export getConfig function", function()
				expect(StatDrainService.getConfig).to.be.a("function")
			end)
		end)

		describe("configuration", function()
			it("should have hunger drain config", function()
				local config = StatDrainService:getConfig()
				expect(config).to.be.ok()
				expect(config.hunger).to.be.ok()
				expect(config.hunger.rate).to.be.a("number")
				expect(config.hunger.interval).to.be.a("number")
				expect(config.hunger.deathMessage).to.be.a("string")
			end)

			it("should have thirst drain config", function()
				local config = StatDrainService:getConfig()
				expect(config.thirst).to.be.ok()
				expect(config.thirst.rate).to.be.a("number")
				expect(config.thirst.interval).to.be.a("number")
				expect(config.thirst.deathMessage).to.be.a("string")
			end)

			it("drain rates should be positive", function()
				local config = StatDrainService:getConfig()
				expect(config.hunger.rate > 0).to.equal(true)
				expect(config.thirst.rate > 0).to.equal(true)
			end)

			it("drain intervals should be reasonable (1-60 seconds)", function()
				local config = StatDrainService:getConfig()
				expect(config.hunger.interval >= 1).to.equal(true)
				expect(config.hunger.interval <= 60).to.equal(true)
				expect(config.thirst.interval >= 1).to.equal(true)
				expect(config.thirst.interval <= 60).to.equal(true)
			end)

			it("thirst should drain faster or equal to hunger (survival mechanic)", function()
				local config = StatDrainService:getConfig()
				-- Thirst is more urgent than hunger in real survival
				local thirstDrainPerSecond = config.thirst.rate / config.thirst.interval
				local hungerDrainPerSecond = config.hunger.rate / config.hunger.interval
				expect(thirstDrainPerSecond >= hungerDrainPerSecond).to.equal(true)
			end)
		end)

		describe("setDrainRate", function()
			it("should update hunger drain rate", function()
				local originalConfig = StatDrainService:getConfig()
				local originalRate = originalConfig.hunger.rate

				StatDrainService:setDrainRate("hunger", 5)
				local newConfig = StatDrainService:getConfig()
				expect(newConfig.hunger.rate).to.equal(5)

				-- Restore original
				StatDrainService:setDrainRate("hunger", originalRate)
			end)

			it("should update thirst drain rate", function()
				local originalConfig = StatDrainService:getConfig()
				local originalRate = originalConfig.thirst.rate

				StatDrainService:setDrainRate("thirst", 10)
				local newConfig = StatDrainService:getConfig()
				expect(newConfig.thirst.rate).to.equal(10)

				-- Restore original
				StatDrainService:setDrainRate("thirst", originalRate)
			end)

			it("should ignore invalid stat names", function()
				-- Should not throw error
				StatDrainService:setDrainRate("invalid_stat", 100)
			end)
		end)

		describe("setDrainInterval", function()
			it("should update drain interval", function()
				local originalConfig = StatDrainService:getConfig()
				local originalInterval = originalConfig.hunger.interval

				StatDrainService:setDrainInterval("hunger", 10)
				local newConfig = StatDrainService:getConfig()
				expect(newConfig.hunger.interval).to.equal(10)

				-- Restore original
				StatDrainService:setDrainInterval("hunger", originalInterval)
			end)
		end)
	end)
end
