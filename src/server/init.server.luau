local PlaceConfig = require(game:GetService("ReplicatedStorage").Shared.PlaceConfig)
local WorldBuilder = require(script.WorldBuilder)
local WaterController = require(script.Character.WaterController)
local SpawnService = require(script.Character.SpawnService)
local StatDrainService = require(script.Character.StatDrainService)
local PlayerDataService = require(script.Data.PlayerDataService)
local NetworkHandlers = require(script.Network.Handlers)
local EcologyService = require(script.Ecology.EcologyService)
local InteractionService = require(script.Interaction.InteractionService)
local WorldObjectService = require(script.WorldObjects.WorldObjectService)
local NPCService = require(script.NPC.NPCService)
local HumanNPCService = require(script.NPC.HumanNPCService)
local DiscoveryService = require(script.Discovery.DiscoveryService)
local QuestService = require(script.Quest.QuestService)
local DialogueService = require(script.Dialogue.DialogueService)

-- Remove default Baseplate (we use generated terrain)
local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate then baseplate:Destroy() end

-- Apply place-specific lighting
PlaceConfig.applyLighting()

-- Initialize core systems
PlayerDataService:init()
NetworkHandlers:init()
EcologyService:init()
NPCService:init()
HumanNPCService:init()
DiscoveryService:init()
QuestService:init()
DialogueService:init()

print("Server started:", PlaceConfig.getCurrent().name)

-- Initialize WaterController to prevent swimming under terrain
WaterController:init()

-- Initialize SpawnService for safe player spawning
SpawnService:init()

-- Initialize StatDrainService for survival mechanics
StatDrainService:init()

-- Initialize InteractionService for player-world interactions
InteractionService:init()

-- Initialize WorldObjectService for spawning world objects
WorldObjectService:init()
WorldObjectService:spawnForCurrentPlace()

-- WorldBuilder is available for terrain generation
-- Call WorldBuilder:buildWorld() to generate terrain
-- Call WorldBuilder:clearWorld() to clear terrain
-- Call WorldBuilder:rebuildWorld() to clear and rebuild

-- Export to _G for easy Studio command bar access
_G.WorldBuilder = WorldBuilder
_G.WaterController = WaterController
_G.SpawnService = SpawnService
_G.StatDrainService = StatDrainService
_G.PlayerDataService = PlayerDataService
_G.EcologyService = EcologyService
_G.InteractionService = InteractionService
_G.WorldObjectService = WorldObjectService
_G.NPCService = NPCService
_G.HumanNPCService = HumanNPCService
_G.DiscoveryService = DiscoveryService
_G.QuestService = QuestService
_G.DialogueService = DialogueService

-- InventoryService is initialized by NetworkHandlers
local InventoryService = require(script.Inventory.InventoryService)
_G.InventoryService = InventoryService

print("All services available via _G (WorldBuilder, SpawnService, InteractionService, etc.)")
