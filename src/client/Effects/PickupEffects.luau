--!strict
--[[
    PickupEffects

    Client-side visual and audio feedback for item pickups.
    Provides satisfying feedback when players collect items.

    Features:
    - Category-based pickup sounds (organic, liquid, wood, stone, metal, fabric, special)
    - Item model scale down + fade animation (0.3s tween)
    - Particle burst at pickup location

    Usage:
        local PickupEffects = require(script.Parent.PickupEffects)
        PickupEffects:init()
        PickupEffects:playPickupEffect(itemId, worldPosition, targetModel)
]]

local PickupEffects = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

-- Dependencies (lazy loaded)
local Audio: any
local AudioConfig: any
local ItemDefinitions: any

-- Configuration
local CONFIG = {
	-- Animation
	PICKUP_DURATION = 0.3, -- seconds for scale/fade animation
	SCALE_TARGET = 0.1, -- shrink to 10% of original size

	-- Particles
	PARTICLE_COUNT = 8,
	PARTICLE_LIFETIME = 0.5,
	PARTICLE_SPEED = 5,
	PARTICLE_SPREAD = 1.5,

	-- Sound
	DEFAULT_CATEGORY = "organic", -- fallback if no category specified
}

-- Sound pool for pickup sounds
local pickupSoundFolder: Folder?
local soundPool: { Sound } = {}
local POOL_SIZE = 5

-- State
local initialized = false

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not Audio then
		Audio = require(ReplicatedStorage.Shared.Audio)
		AudioConfig = Audio.Config
	end
	if not ItemDefinitions then
		ItemDefinitions = require(ReplicatedStorage.Shared.Items.ItemDefinitions)
	end
end

local function getOrCreateSound(): Sound
	-- Find available sound from pool
	for _, sound in soundPool do
		if not sound.Playing then
			return sound
		end
	end

	-- Pool exhausted, create new sound (will be added to pool)
	local sound = Instance.new("Sound")
	sound.Name = "PickupSound"
	sound.Parent = pickupSoundFolder
	table.insert(soundPool, sound)

	return sound
end

--------------------------------------------------------------------------------
-- SOUND EFFECTS
--------------------------------------------------------------------------------

function PickupEffects:playPickupSound(pickupCategory: string, position: Vector3?)
	loadDependencies()

	local soundConfig = AudioConfig.getPickupSound(pickupCategory)
	if not soundConfig then
		soundConfig = AudioConfig.getPickupSound(CONFIG.DEFAULT_CATEGORY)
	end

	if not soundConfig or #soundConfig.sounds == 0 then
		return
	end

	-- Pick random sound from category
	local soundId = soundConfig.sounds[math.random(1, #soundConfig.sounds)]

	-- Get sound from pool
	local sound = getOrCreateSound()
	sound.SoundId = soundId
	sound.Volume = soundConfig.volume

	-- Apply pitch variation for variety
	local pitchVariation = soundConfig.pitchVariation or 0.1
	sound.PlaybackSpeed = 1 + (math.random() * 2 - 1) * pitchVariation

	-- Play spatially if position provided
	if position then
		-- Create temporary attachment for 3D sound
		local attachment = Instance.new("Attachment")
		attachment.WorldPosition = position
		attachment.Parent = workspace.Terrain

		sound.Parent = attachment
		sound.RollOffMinDistance = 5
		sound.RollOffMaxDistance = 30

		sound.Ended:Once(function()
			attachment:Destroy()
			sound.Parent = pickupSoundFolder
		end)
	else
		sound.Parent = pickupSoundFolder
	end

	sound:Play()
end

--------------------------------------------------------------------------------
-- VISUAL EFFECTS
--------------------------------------------------------------------------------

function PickupEffects:playScaleFadeAnimation(target: Instance)
	if not target then
		return
	end

	-- Get all BaseParts to animate
	local parts: { BasePart } = {}

	if target:IsA("BasePart") then
		table.insert(parts, target)
	elseif target:IsA("Model") then
		for _, desc in target:GetDescendants() do
			if desc:IsA("BasePart") then
				table.insert(parts, desc)
			end
		end
	end

	if #parts == 0 then
		return
	end

	-- Store original properties for each part
	local originalData: { [BasePart]: { size: Vector3, transparency: number, cframe: CFrame } } = {}
	for _, part in parts do
		originalData[part] = {
			size = part.Size,
			transparency = part.Transparency,
			cframe = part.CFrame,
		}
		-- Disable collisions during animation
		part.CanCollide = false
		part.Anchored = true
	end

	-- Tween info for pickup animation
	local tweenInfo = TweenInfo.new(
		CONFIG.PICKUP_DURATION,
		Enum.EasingStyle.Back,
		Enum.EasingDirection.In
	)

	-- Animate each part
	for _, part in parts do
		local original = originalData[part]
		local targetSize = original.size * CONFIG.SCALE_TARGET

		-- Calculate center-anchored position (so it shrinks toward center)
		local tween = TweenService:Create(part, tweenInfo, {
			Size = targetSize,
			Transparency = 1,
		})
		tween:Play()
	end

	-- Clean up after animation
	task.delay(CONFIG.PICKUP_DURATION + 0.05, function()
		if target and target.Parent then
			target:Destroy()
		end
	end)
end

function PickupEffects:spawnParticleBurst(position: Vector3, color: Color3?)
	-- Create temporary part for particle emission
	local emitterPart = Instance.new("Part")
	emitterPart.Name = "PickupParticles"
	emitterPart.Anchored = true
	emitterPart.CanCollide = false
	emitterPart.Transparency = 1
	emitterPart.Size = Vector3.new(0.5, 0.5, 0.5)
	emitterPart.Position = position
	emitterPart.Parent = workspace

	-- Create particle emitter
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "PickupBurst"

	-- Particle appearance
	emitter.Color = ColorSequence.new(color or Color3.fromRGB(255, 255, 200))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.2),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.LightEmission = 0.3
	emitter.LightInfluence = 0.5

	-- Particle behavior
	emitter.Lifetime = NumberRange.new(CONFIG.PARTICLE_LIFETIME * 0.8, CONFIG.PARTICLE_LIFETIME)
	emitter.Speed = NumberRange.new(CONFIG.PARTICLE_SPEED * 0.5, CONFIG.PARTICLE_SPEED)
	emitter.SpreadAngle = Vector2.new(180, 180) -- Burst in all directions
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-180, 180)
	emitter.Acceleration = Vector3.new(0, -5, 0) -- Slight gravity

	-- Emit settings
	emitter.Rate = 0 -- We'll use Emit() for burst
	emitter.Parent = emitterPart

	-- Emit burst of particles
	emitter.Enabled = true
	emitter:Emit(CONFIG.PARTICLE_COUNT)
	emitter.Enabled = false

	-- Clean up after particles fade
	Debris:AddItem(emitterPart, CONFIG.PARTICLE_LIFETIME + 0.1)
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

--[[
    Play complete pickup effect (sound + visuals)

    @param itemId string - The item being picked up
    @param position Vector3 - World position of the pickup
    @param targetModel Instance? - Optional model to animate (scale/fade)
]]
function PickupEffects:playPickupEffect(itemId: string, position: Vector3, targetModel: Instance?)
	loadDependencies()

	-- Get item definition to determine pickup category
	local itemDef = ItemDefinitions.get(itemId)
	local pickupCategory = CONFIG.DEFAULT_CATEGORY
	local particleColor: Color3? = nil

	if itemDef then
		pickupCategory = itemDef.pickupCategory or CONFIG.DEFAULT_CATEGORY

		-- Set particle color based on category
		if pickupCategory == "organic" then
			particleColor = Color3.fromRGB(144, 238, 144) -- Light green
		elseif pickupCategory == "liquid" then
			particleColor = Color3.fromRGB(135, 206, 250) -- Light blue
		elseif pickupCategory == "wood" then
			particleColor = Color3.fromRGB(210, 180, 140) -- Tan
		elseif pickupCategory == "stone" then
			particleColor = Color3.fromRGB(169, 169, 169) -- Gray
		elseif pickupCategory == "metal" then
			particleColor = Color3.fromRGB(192, 192, 192) -- Silver
		elseif pickupCategory == "fabric" then
			particleColor = Color3.fromRGB(255, 228, 196) -- Bisque
		elseif pickupCategory == "special" then
			particleColor = Color3.fromRGB(255, 215, 0) -- Gold
		end
	end

	-- Play category-appropriate sound
	self:playPickupSound(pickupCategory, position)

	-- Spawn particle burst
	self:spawnParticleBurst(position, particleColor)

	-- Animate model if provided
	if targetModel then
		self:playScaleFadeAnimation(targetModel)
	end
end

--[[
    Play pickup effect for a specific category (when item ID is unknown)

    @param pickupCategory string - The pickup category
    @param position Vector3 - World position of the pickup
    @param targetModel Instance? - Optional model to animate
]]
function PickupEffects:playPickupEffectByCategory(pickupCategory: string, position: Vector3, targetModel: Instance?)
	-- Play sound
	self:playPickupSound(pickupCategory, position)

	-- Determine particle color
	local particleColor: Color3? = nil
	if pickupCategory == "organic" then
		particleColor = Color3.fromRGB(144, 238, 144)
	elseif pickupCategory == "liquid" then
		particleColor = Color3.fromRGB(135, 206, 250)
	elseif pickupCategory == "wood" then
		particleColor = Color3.fromRGB(210, 180, 140)
	elseif pickupCategory == "stone" then
		particleColor = Color3.fromRGB(169, 169, 169)
	elseif pickupCategory == "metal" then
		particleColor = Color3.fromRGB(192, 192, 192)
	elseif pickupCategory == "fabric" then
		particleColor = Color3.fromRGB(255, 228, 196)
	elseif pickupCategory == "special" then
		particleColor = Color3.fromRGB(255, 215, 0)
	end

	-- Spawn particle burst
	self:spawnParticleBurst(position, particleColor)

	-- Animate model if provided
	if targetModel then
		self:playScaleFadeAnimation(targetModel)
	end
end

--------------------------------------------------------------------------------
-- NETWORK LISTENER
--------------------------------------------------------------------------------

local function onPickupEffectReceived(data: any)
	if type(data) ~= "table" then
		return
	end

	local itemId = data.itemId
	local pickupCategory = data.pickupCategory or CONFIG.DEFAULT_CATEGORY
	local position = data.position

	if not position then
		return
	end

	-- Find the target model if targetId was provided
	-- The server sends the interactable ID, we need to find it by attribute
	local targetModel: Instance? = nil
	if data.targetId then
		-- Search for the interactable with matching ID
		local CollectionService = game:GetService("CollectionService")
		local interactables = CollectionService:GetTagged("Interactable")
		for _, obj in interactables do
			if obj:GetAttribute("InteractableId") == data.targetId then
				targetModel = obj
				break
			end
		end
	end

	-- Play the pickup effect
	PickupEffects:playPickupEffectByCategory(pickupCategory, position, targetModel)
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

function PickupEffects:init()
	if initialized then
		return
	end
	initialized = true

	loadDependencies()

	-- Create folder for pickup sounds
	pickupSoundFolder = Instance.new("Folder")
	pickupSoundFolder.Name = "PickupSounds"
	pickupSoundFolder.Parent = SoundService

	-- Pre-create sound pool
	for _ = 1, POOL_SIZE do
		local sound = Instance.new("Sound")
		sound.Name = "PickupSound"
		sound.Parent = pickupSoundFolder
		table.insert(soundPool, sound)
	end

	-- Listen for pickup effect events from server
	local Network = require(ReplicatedStorage.Shared.Network)
	Network.Events.PickupEffect.OnClientEvent:Connect(onPickupEffectReceived)

	print("[PickupEffects] Initialized")
end

return PickupEffects
