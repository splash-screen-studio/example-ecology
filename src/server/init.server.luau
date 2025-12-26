local PlaceConfig = require(game:GetService("ReplicatedStorage").Shared.PlaceConfig)
local WorldBuilder = require(script.WorldBuilder)
local WaterController = require(script.Character.WaterController)
local PlayerDataService = require(script.Data.PlayerDataService)
local NetworkHandlers = require(script.Network.Handlers)
local EcologyService = require(script.Ecology.EcologyService)

-- Remove default Baseplate (we use generated terrain)
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end

-- Apply place-specific lighting
PlaceConfig.applyLighting()

-- Initialize core systems
PlayerDataService:init()
NetworkHandlers:init()
EcologyService:init()

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
_G.EcologyService = EcologyService

-- InventoryService is initialized by NetworkHandlers
local InventoryService = require(script.Inventory.InventoryService)
_G.InventoryService = InventoryService

print("WorldBuilder, WaterController, PlayerDataService, EcologyService, InventoryService available via _G")
