--!strict
--[[
    HumanNPCService

    Spawns and manages human NPCs (quest givers, guides, researchers).
    Separate from NPCService which handles animals with AI behaviors.

    Usage:
        local HumanNPCService = require(script.Parent.HumanNPCService)
        HumanNPCService:init()
]]

local HumanNPCService = {}

-- Services
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Dependencies (lazy loaded)
local InteractionService
local PlaceConfig
local ElevationService

-- Types
export type HumanNPCDefinition = {
	id: string,
	name: string,
	title: string?, -- e.g., "Ranger", "Researcher"
	description: string,
	-- Spawn location
	spawnPosition: Vector3,
	spawnRotation: number?, -- Y rotation in degrees
	-- Appearance
	shirtColor: Color3?,
	pantsColor: Color3?,
	skinTone: Color3?,
	-- Behavior
	idleAnimation: string?, -- Animation ID
}

-- NPC Definitions: 2 NPCs to start (implement in twos)
local NPC_DEFINITIONS: { HumanNPCDefinition } = {
	{
		id = "ranger_maya",
		name = "Ranger Maya",
		title = "Wildlife Guardian",
		description = "A friendly ranger who helps newcomers learn to survive in the basin.",
		spawnPosition = Vector3.new(15, 0, 15), -- Near spawn, will be adjusted to terrain
		spawnRotation = 180, -- Face toward spawn
		shirtColor = Color3.fromRGB(34, 139, 34), -- Forest green
		pantsColor = Color3.fromRGB(139, 90, 43), -- Brown
		skinTone = Color3.fromRGB(197, 140, 103),
	},
	{
		id = "researcher_sage",
		name = "Dr. Sage",
		title = "Ecologist",
		description = "A scientist studying the unique ecosystem of the basin.",
		spawnPosition = Vector3.new(100, 0, 60), -- Near the Ancient Oak area
		spawnRotation = -90,
		shirtColor = Color3.fromRGB(240, 240, 240), -- White lab coat
		pantsColor = Color3.fromRGB(50, 50, 50), -- Dark pants
		skinTone = Color3.fromRGB(180, 140, 100),
	},
}

-- State
local spawnedNPCs: { [string]: Model } = {}
local npcFolder: Folder?
local initialized = false

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not InteractionService then
		pcall(function()
			InteractionService = require(script.Parent.Parent.Interaction.InteractionService)
		end)
	end
	if not PlaceConfig then
		PlaceConfig = require(ReplicatedStorage.Shared.PlaceConfig)
	end
	if not ElevationService then
		ElevationService = require(ReplicatedStorage.Shared.ElevationService)
	end
end

local function getNPCFolder(): Folder
	if npcFolder and npcFolder.Parent then
		return npcFolder
	end

	npcFolder = Workspace:FindFirstChild("HumanNPCs") :: Folder?
	if not npcFolder then
		npcFolder = Instance.new("Folder")
		npcFolder.Name = "HumanNPCs"
		npcFolder.Parent = Workspace
	end

	return npcFolder
end

local function getGroundPosition(position: Vector3): Vector3
	loadDependencies()

	local elevation = ElevationService:getElevation(position.X, position.Z)
	if elevation.isValid then
		return Vector3.new(position.X, elevation.groundY + 3, position.Z)
	end

	-- Fallback: raycast down
	local rayOrigin = Vector3.new(position.X, 500, position.Z)
	local rayDirection = Vector3.new(0, -1000, 0)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { getNPCFolder() }

	local result = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
	if result then
		return result.Position + Vector3.new(0, 3, 0)
	end

	return position + Vector3.new(0, 10, 0)
end

--------------------------------------------------------------------------------
-- NPC CREATION
--------------------------------------------------------------------------------

local function createHumanoidModel(definition: HumanNPCDefinition): Model
	local model = Instance.new("Model")
	model.Name = definition.name -- Use display name, not ID
	model:SetAttribute("npcId", definition.id) -- Store ID for lookups

	-- Create humanoid (hide default name display - we use custom billboard)
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.Parent = model

	-- Create basic body parts
	local torso = Instance.new("Part")
	torso.Name = "HumanoidRootPart"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Anchored = true
	torso.CanCollide = false
	torso.Transparency = 1
	torso.Parent = model
	model.PrimaryPart = torso

	-- Visible torso (with collision for player interaction)
	local upperTorso = Instance.new("Part")
	upperTorso.Name = "UpperTorso"
	upperTorso.Size = Vector3.new(2, 1.6, 1)
	upperTorso.Anchored = true
	upperTorso.CanCollide = true
	upperTorso.BrickColor = BrickColor.new(definition.shirtColor or Color3.fromRGB(100, 100, 100))
	upperTorso.Material = Enum.Material.Fabric
	upperTorso.CFrame = torso.CFrame * CFrame.new(0, 0.3, 0)
	upperTorso.Parent = model

	local lowerTorso = Instance.new("Part")
	lowerTorso.Name = "LowerTorso"
	lowerTorso.Size = Vector3.new(2, 0.8, 1)
	lowerTorso.Anchored = true
	lowerTorso.CanCollide = false
	lowerTorso.BrickColor = BrickColor.new(definition.pantsColor or Color3.fromRGB(50, 50, 100))
	lowerTorso.Material = Enum.Material.Fabric
	lowerTorso.CFrame = torso.CFrame * CFrame.new(0, -0.9, 0)
	lowerTorso.Parent = model

	-- Head
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.Anchored = true
	head.CanCollide = false
	head.BrickColor = BrickColor.new(definition.skinTone or Color3.fromRGB(197, 140, 103))
	head.Material = Enum.Material.SmoothPlastic
	head.CFrame = torso.CFrame * CFrame.new(0, 1.7, 0)
	head.Parent = model

	-- Face
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head

	-- Arms
	local leftArm = Instance.new("Part")
	leftArm.Name = "LeftUpperArm"
	leftArm.Size = Vector3.new(0.6, 1.4, 0.6)
	leftArm.Anchored = true
	leftArm.CanCollide = false
	leftArm.BrickColor = BrickColor.new(definition.shirtColor or Color3.fromRGB(100, 100, 100))
	leftArm.Material = Enum.Material.Fabric
	leftArm.CFrame = torso.CFrame * CFrame.new(-1.3, 0.1, 0)
	leftArm.Parent = model

	local rightArm = Instance.new("Part")
	rightArm.Name = "RightUpperArm"
	rightArm.Size = Vector3.new(0.6, 1.4, 0.6)
	rightArm.Anchored = true
	rightArm.CanCollide = false
	rightArm.BrickColor = BrickColor.new(definition.shirtColor or Color3.fromRGB(100, 100, 100))
	rightArm.Material = Enum.Material.Fabric
	rightArm.CFrame = torso.CFrame * CFrame.new(1.3, 0.1, 0)
	rightArm.Parent = model

	-- Legs
	local leftLeg = Instance.new("Part")
	leftLeg.Name = "LeftUpperLeg"
	leftLeg.Size = Vector3.new(0.7, 1.4, 0.7)
	leftLeg.Anchored = true
	leftLeg.CanCollide = false
	leftLeg.BrickColor = BrickColor.new(definition.pantsColor or Color3.fromRGB(50, 50, 100))
	leftLeg.Material = Enum.Material.Fabric
	leftLeg.CFrame = torso.CFrame * CFrame.new(-0.5, -2, 0)
	leftLeg.Parent = model

	local rightLeg = Instance.new("Part")
	rightLeg.Name = "RightUpperLeg"
	rightLeg.Size = Vector3.new(0.7, 1.4, 0.7)
	rightLeg.Anchored = true
	rightLeg.CanCollide = false
	rightLeg.BrickColor = BrickColor.new(definition.pantsColor or Color3.fromRGB(50, 50, 100))
	rightLeg.Material = Enum.Material.Fabric
	rightLeg.CFrame = torso.CFrame * CFrame.new(0.5, -2, 0)
	rightLeg.Parent = model

	-- Name display
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameDisplay"
	billboard.Size = UDim2.new(0, 150, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 50
	billboard.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.6, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = definition.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.Parent = billboard

	if definition.title then
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
		titleLabel.Position = UDim2.new(0, 0, 0.6, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Text = definition.title
		titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		titleLabel.TextStrokeTransparency = 0.7
		titleLabel.Font = Enum.Font.Gotham
		titleLabel.TextSize = 12
		titleLabel.Parent = billboard
	end

	return model
end

local function positionNPC(model: Model, position: Vector3, rotation: number?)
	local groundPos = getGroundPosition(position)
	local rotationCFrame = CFrame.Angles(0, math.rad(rotation or 0), 0)
	model:PivotTo(CFrame.new(groundPos) * rotationCFrame)

	-- Update all anchored parts
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= model.PrimaryPart then
			local offset = model.PrimaryPart.CFrame:ToObjectSpace(part.CFrame)
			part.CFrame = model.PrimaryPart.CFrame * offset
		end
	end
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function HumanNPCService:spawnNPC(definition: HumanNPCDefinition): Model?
	loadDependencies()

	if spawnedNPCs[definition.id] then
		-- Already spawned
		return spawnedNPCs[definition.id]
	end

	local model = createHumanoidModel(definition)
	positionNPC(model, definition.spawnPosition, definition.spawnRotation)
	model.Parent = getNPCFolder()

	-- Register with InteractionService
	if InteractionService then
		InteractionService:registerInteractable(model, {
			id = definition.id,
			interactionType = "talk",
			displayName = definition.name,
			prompt = "Talk to " .. definition.name,
			range = 8,
			cooldown = 0.5,
		})
	end

	spawnedNPCs[definition.id] = model

	print(string.format("[HumanNPCService] Spawned %s at %s", definition.name, tostring(definition.spawnPosition)))

	return model
end

function HumanNPCService:despawnNPC(npcId: string)
	local model = spawnedNPCs[npcId]
	if model then
		if InteractionService then
			InteractionService:unregisterInteractable(model)
		end
		model:Destroy()
		spawnedNPCs[npcId] = nil
	end
end

function HumanNPCService:getNPC(npcId: string): Model?
	return spawnedNPCs[npcId]
end

function HumanNPCService:getAllNPCs(): { [string]: Model }
	return spawnedNPCs
end

function HumanNPCService:spawnAllForPlace()
	loadDependencies()

	local config = PlaceConfig.getCurrent()
	print(string.format("[HumanNPCService] Spawning NPCs for %s", config.name))

	for _, definition in NPC_DEFINITIONS do
		self:spawnNPC(definition)
	end
end

function HumanNPCService:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()

	-- Spawn NPCs after a short delay to let terrain generate
	task.delay(2, function()
		self:spawnAllForPlace()
	end)

	print("[HumanNPCService] Initialized with", #NPC_DEFINITIONS, "NPC definitions")
end

-- Get definition for external use
function HumanNPCService:getDefinition(npcId: string): HumanNPCDefinition?
	for _, def in NPC_DEFINITIONS do
		if def.id == npcId then
			return def
		end
	end
	return nil
end

return HumanNPCService
