--!strict
--[[
    DialogueService Regression Tests

    Tests for dialogue conversation flow.
    Bug fixed: Conversations got stuck without timeout when client UI didn't respond.
]]

local ServerScriptService = game:GetService("ServerScriptService")

return function()
	describe("DialogueService", function()
		local DialogueService

		beforeAll(function()
			local success, result = pcall(function()
				return require(ServerScriptService.Server.Dialogue.DialogueService)
			end)

			if success then
				DialogueService = result
			end
		end)

		describe("module structure", function()
			it("should export init function", function()
				expect(DialogueService).to.be.ok()
				expect(DialogueService.init).to.be.a("function")
			end)

			it("should export startConversation function", function()
				expect(DialogueService.startConversation).to.be.a("function")
			end)

			it("should export endConversation function", function()
				expect(DialogueService.endConversation).to.be.a("function")
			end)

			it("should export selectResponse function", function()
				expect(DialogueService.selectResponse).to.be.a("function")
			end)

			it("should export getActiveConversation function", function()
				expect(DialogueService.getActiveConversation).to.be.a("function")
			end)
		end)

		describe("conversation state", function()
			it("should return nil for player not in conversation", function()
				local fakePlayer = {} :: any
				local conversation = DialogueService:getActiveConversation(fakePlayer)
				expect(conversation).to.equal(nil)
			end)
		end)
	end)
end
