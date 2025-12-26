--!strict
--[[
    Test Runner

    Discovers and runs all tests using TestEZ.
    Run via command bar: require(game.ReplicatedStorage.Tests)()
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)

local function runTests()
	local testRoots = {
		script.server,
		script.shared,
	}

	local results = TestEZ.TestBootstrap:run(testRoots)

	-- Print summary
	local passed = results.successCount
	local failed = results.failureCount
	local skipped = results.skippedCount

	print("=====================================")
	print(string.format("Tests: %d passed, %d failed, %d skipped", passed, failed, skipped))
	print("=====================================")

	return results.failureCount == 0
end

return runTests
