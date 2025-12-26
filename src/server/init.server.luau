local PlaceConfig = require(game:GetService("ReplicatedStorage").Shared.PlaceConfig)
local WorldBuilder = require(script.WorldBuilder)
local WaterController = require(script.Character.WaterController)
local PlayerDataService = require(script.Data.PlayerDataService)
local NetworkHandlers = require(script.Network.Handlers)

-- Remove default Baseplate (we use generated terrain)
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end

-- Apply place-specific lighting
PlaceConfig.applyLighting()

-- Initialize core systems
PlayerDataService:init()
NetworkHandlers:init()

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
_G.PlayerDataService = PlayerDataService
print("WorldBuilder, WaterController, PlayerDataService available via _G")
