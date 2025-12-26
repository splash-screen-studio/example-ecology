local PlaceConfig = require(game:GetService("ReplicatedStorage").Shared.PlaceConfig)
local WorldBuilder = require(script.WorldBuilder)

-- Apply place-specific lighting
PlaceConfig.applyLighting()

print("Server started:", PlaceConfig.getCurrent().name)

-- WorldBuilder is available for terrain generation
-- Call WorldBuilder:buildWorld() to generate terrain
-- Call WorldBuilder:clearWorld() to clear terrain
-- Call WorldBuilder:rebuildWorld() to clear and rebuild

-- Export to _G for easy Studio command bar access
_G.WorldBuilder = WorldBuilder
print("WorldBuilder available via _G.WorldBuilder")
