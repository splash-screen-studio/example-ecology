local PlaceConfig = require(game:GetService("ReplicatedStorage").Shared.PlaceConfig)

PlaceConfig.applyLighting()

print("Server started:", PlaceConfig.getCurrent().name)
