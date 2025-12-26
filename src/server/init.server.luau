local PlaceConfig = require(game:GetService("ReplicatedStorage").Shared.PlaceConfig)
local WorldBuilder = require(script.WorldBuilder)
local WaterController = require(script.Character.WaterController)

-- Remove default Baseplate (we use generated terrain)
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end

-- Apply place-specific lighting
PlaceConfig.applyLighting()

print("Server started:", PlaceConfig.getCurrent().name)

-- Initialize WaterController to prevent swimming under terrain
WaterController:init()

-- WorldBuilder is available for terrain generation
-- Call WorldBuilder:buildWorld() to generate terrain
-- Call WorldBuilder:clearWorld() to clear terrain
-- Call WorldBuilder:rebuildWorld() to clear and rebuild

-- Export to _G for easy Studio command bar access
_G.WorldBuilder = WorldBuilder
_G.WaterController = WaterController
print("WorldBuilder and WaterController available via _G")
