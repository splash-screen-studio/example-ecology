# Gameplay Mechanics

Research on core gameplay systems for Example Ecology (2025).

## Mechanics Overview

For an ecology simulation, key mechanics include:
- Picking up items (food, resources)
- Hunger/thirst systems (survival)
- Health and damage
- Interacting with environment
- Teleporting between places
- Audio/visual feedback

---

## Item Pickup System

### Basic Proximity Pickup

```lua
-- src/server/ItemSystem/ItemPickup.luau
local ItemPickup = {}

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local PICKUP_DISTANCE = 8

function ItemPickup.setup()
    -- Tag items with "Pickupable" in Studio
    for _, item in CollectionService:GetTagged("Pickupable") do
        ItemPickup.initItem(item)
    end

    CollectionService:GetInstanceAddedSignal("Pickupable"):Connect(function(item)
        ItemPickup.initItem(item)
    end)
end

function ItemPickup.initItem(item: BasePart)
    local promptAttachment = Instance.new("Attachment")
    promptAttachment.Parent = item

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Pick up"
    prompt.ObjectText = item.Name
    prompt.MaxActivationDistance = PICKUP_DISTANCE
    prompt.HoldDuration = 0.2
    prompt.Parent = promptAttachment

    prompt.Triggered:Connect(function(player)
        ItemPickup.onPickup(player, item)
    end)
end

function ItemPickup.onPickup(player: Player, item: BasePart)
    local itemData = {
        name = item.Name,
        type = item:GetAttribute("ItemType") or "generic",
        value = item:GetAttribute("Value") or 1,
    }

    -- Add to player inventory (fire event to inventory system)
    local inventoryEvent = game.ReplicatedStorage:FindFirstChild("AddToInventory")
    if inventoryEvent then
        inventoryEvent:Fire(player, itemData)
    end

    -- Play pickup effect
    ItemPickup.playPickupEffect(item.Position)

    -- Remove item from world
    item:Destroy()
end

function ItemPickup.playPickupEffect(position: Vector3)
    -- Particle burst, sound, etc.
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://YOUR_PICKUP_SOUND"
    sound.Parent = workspace
    sound.Position = position
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

return ItemPickup
```

### Touch-Based Pickup (Mobile Friendly)

```lua
-- Alternative: auto-pickup on touch
local function setupAutoPickup(item: BasePart)
    item.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            onPickup(player, item)
        end
    end)
end
```

---

## Inventory System

### Simple Slot-Based Inventory

```lua
-- src/shared/Inventory.luau
local Inventory = {}
Inventory.__index = Inventory

export type Item = {
    id: string,
    name: string,
    type: string,
    quantity: number,
    maxStack: number,
}

function Inventory.new(maxSlots: number)
    return setmetatable({
        slots = {},
        maxSlots = maxSlots,
    }, Inventory)
end

function Inventory:addItem(item: Item): boolean
    -- Try to stack with existing
    for _, slot in self.slots do
        if slot.id == item.id and slot.quantity < slot.maxStack then
            local spaceLeft = slot.maxStack - slot.quantity
            local toAdd = math.min(spaceLeft, item.quantity)
            slot.quantity += toAdd
            item.quantity -= toAdd
            if item.quantity <= 0 then
                return true
            end
        end
    end

    -- Add to new slot
    if #self.slots < self.maxSlots then
        table.insert(self.slots, item)
        return true
    end

    return false  -- inventory full
end

function Inventory:removeItem(itemId: string, quantity: number): boolean
    for i, slot in self.slots do
        if slot.id == itemId then
            slot.quantity -= quantity
            if slot.quantity <= 0 then
                table.remove(self.slots, i)
            end
            return true
        end
    end
    return false
end

function Inventory:hasItem(itemId: string, quantity: number?): boolean
    quantity = quantity or 1
    for _, slot in self.slots do
        if slot.id == itemId and slot.quantity >= quantity then
            return true
        end
    end
    return false
end

return Inventory
```

---

## Hunger & Thirst System

### Survival Stats

```lua
-- src/server/SurvivalSystem.luau
local SurvivalSystem = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local HUNGER_DRAIN = 0.5    -- per second
local THIRST_DRAIN = 0.8    -- per second
local STARVING_DAMAGE = 2   -- damage per second when starving
local DEHYDRATION_DAMAGE = 3

local playerStats = {}

function SurvivalSystem.initPlayer(player: Player)
    playerStats[player] = {
        hunger = 100,
        thirst = 100,
        maxHunger = 100,
        maxThirst = 100,
    }

    -- Sync to client
    local statsFolder = Instance.new("Folder")
    statsFolder.Name = "SurvivalStats"
    statsFolder.Parent = player

    local hungerValue = Instance.new("NumberValue")
    hungerValue.Name = "Hunger"
    hungerValue.Value = 100
    hungerValue.Parent = statsFolder

    local thirstValue = Instance.new("NumberValue")
    thirstValue.Name = "Thirst"
    thirstValue.Value = 100
    thirstValue.Parent = statsFolder
end

function SurvivalSystem.update(dt: number)
    for player, stats in playerStats do
        if not player.Parent then
            playerStats[player] = nil
            continue
        end

        -- Drain stats
        stats.hunger = math.max(0, stats.hunger - HUNGER_DRAIN * dt)
        stats.thirst = math.max(0, stats.thirst - THIRST_DRAIN * dt)

        -- Apply damage if starving/dehydrated
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")

        if humanoid then
            if stats.hunger <= 0 then
                humanoid:TakeDamage(STARVING_DAMAGE * dt)
            end
            if stats.thirst <= 0 then
                humanoid:TakeDamage(DEHYDRATION_DAMAGE * dt)
            end
        end

        -- Sync values
        local statsFolder = player:FindFirstChild("SurvivalStats")
        if statsFolder then
            statsFolder.Hunger.Value = stats.hunger
            statsFolder.Thirst.Value = stats.thirst
        end
    end
end

function SurvivalSystem.feed(player: Player, amount: number)
    local stats = playerStats[player]
    if stats then
        stats.hunger = math.min(stats.maxHunger, stats.hunger + amount)
    end
end

function SurvivalSystem.hydrate(player: Player, amount: number)
    local stats = playerStats[player]
    if stats then
        stats.thirst = math.min(stats.maxThirst, stats.thirst + amount)
    end
end

-- Setup
Players.PlayerAdded:Connect(SurvivalSystem.initPlayer)
Players.PlayerRemoving:Connect(function(player)
    playerStats[player] = nil
end)

RunService.Heartbeat:Connect(SurvivalSystem.update)

return SurvivalSystem
```

### Consuming Food

```lua
-- When player uses food item
local function consumeFood(player: Player, foodItem: Item)
    local foodConfig = {
        apple = { hunger = 20, thirst = 5 },
        berries = { hunger = 10, thirst = 2 },
        water = { hunger = 0, thirst = 30 },
        meat = { hunger = 40, thirst = -5 },
    }

    local config = foodConfig[foodItem.id]
    if config then
        SurvivalSystem.feed(player, config.hunger)
        SurvivalSystem.hydrate(player, config.thirst)

        -- Play eating sound/animation
        playFeedback(player, "eat")
    end
end
```

---

## Health & Damage System

### Damage Types

```lua
-- src/shared/DamageTypes.luau
local DamageTypes = {
    Physical = "Physical",
    Fire = "Fire",
    Poison = "Poison",
    Fall = "Fall",
    Starvation = "Starvation",
    Dehydration = "Dehydration",
    Environmental = "Environmental",
}

return DamageTypes
```

### Damage Handler

```lua
-- src/server/DamageSystem.luau
local DamageSystem = {}

local DamageTypes = require(script.Parent.DamageTypes)

function DamageSystem.applyDamage(
    target: Humanoid,
    amount: number,
    damageType: string,
    source: Instance?
)
    -- Check for resistances
    local resistance = DamageSystem.getResistance(target, damageType)
    local finalDamage = amount * (1 - resistance)

    -- Apply damage
    target:TakeDamage(finalDamage)

    -- Fire damage event for UI feedback
    local damageEvent = game.ReplicatedStorage:FindFirstChild("DamageDealt")
    if damageEvent then
        local player = game.Players:GetPlayerFromCharacter(target.Parent)
        if player then
            damageEvent:FireClient(player, finalDamage, damageType)
        end
    end

    -- Play damage effect
    DamageSystem.playDamageEffect(target.Parent, damageType)
end

function DamageSystem.getResistance(humanoid: Humanoid, damageType: string): number
    local resistances = humanoid:GetAttribute("Resistances") or {}
    return resistances[damageType] or 0
end

function DamageSystem.playDamageEffect(character: Model, damageType: string)
    -- Red flash, particles, etc.
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Play hurt sound
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://YOUR_HURT_SOUND"
    sound.Parent = rootPart
    sound:Play()
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

return DamageSystem
```

### Being Attacked (By Animals/Environment)

```lua
-- src/server/AnimalAttack.luau
local function attackPlayer(animal: Model, player: Player, damage: number)
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if not humanoid then return end

    DamageSystem.applyDamage(humanoid, damage, "Physical", animal)

    -- Play attack animation on animal
    local animator = animal:FindFirstChildWhichIsA("Animator")
    if animator then
        local attackAnim = animator:LoadAnimation(animal.Animations.Attack)
        attackAnim:Play()
    end

    -- Knockback
    local rootPart = player.Character.HumanoidRootPart
    local direction = (rootPart.Position - animal.PrimaryPart.Position).Unit
    rootPart.Velocity = direction * 30 + Vector3.new(0, 20, 0)
end
```

---

## Attacking / Combat (Simple)

### Basic Melee Attack

```lua
-- src/client/Combat/MeleeAttack.luau
local MeleeAttack = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local attackEvent = ReplicatedStorage:WaitForChild("AttackEvent")

local ATTACK_RANGE = 8
local ATTACK_COOLDOWN = 0.5
local lastAttack = 0

function MeleeAttack.setup()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.KeyCode == Enum.KeyCode.E then
            MeleeAttack.tryAttack()
        end
    end)
end

function MeleeAttack.tryAttack()
    if tick() - lastAttack < ATTACK_COOLDOWN then return end
    lastAttack = tick()

    local character = player.Character
    if not character then return end

    -- Play attack animation locally
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        local animator = humanoid:FindFirstChild("Animator")
        if animator then
            local attackAnim = animator:LoadAnimation(
                ReplicatedStorage.Animations.PlayerAttack
            )
            attackAnim:Play()
        end
    end

    -- Send attack to server
    attackEvent:FireServer()
end

return MeleeAttack
```

### Server-Side Attack Validation

```lua
-- src/server/Combat/AttackHandler.server.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local attackEvent = ReplicatedStorage:WaitForChild("AttackEvent")

local ATTACK_RANGE = 8
local ATTACK_DAMAGE = 15
local ATTACK_ANGLE = 90  -- degrees in front

attackEvent.OnServerEvent:Connect(function(player)
    local character = player.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Find targets in range
    for _, target in workspace:GetDescendants() do
        if target:IsA("Humanoid") and target.Parent ~= character then
            local targetRoot = target.Parent:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (targetRoot.Position - rootPart.Position).Magnitude
                if distance <= ATTACK_RANGE then
                    -- Check if in front
                    local toTarget = (targetRoot.Position - rootPart.Position).Unit
                    local forward = rootPart.CFrame.LookVector
                    local angle = math.deg(math.acos(forward:Dot(toTarget)))

                    if angle <= ATTACK_ANGLE / 2 then
                        -- Hit!
                        DamageSystem.applyDamage(target, ATTACK_DAMAGE, "Physical", character)
                    end
                end
            end
        end
    end
end)
```

---

## Teleporting Between Places

### TeleportService Usage

```lua
-- src/server/TeleportHandler.luau
local TeleportHandler = {}

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local PlaceConfig = require(game.ReplicatedStorage.Shared.PlaceConfig)

function TeleportHandler.teleportToPlace(player: Player, placeName: string)
    local placeId = PlaceConfig.PlaceIds[placeName]
    if not placeId then
        warn("Unknown place:", placeName)
        return
    end

    -- Teleport with retry
    local success, result = pcall(function()
        return TeleportService:TeleportAsync(placeId, {player})
    end)

    if not success then
        warn("Teleport failed:", result)
        -- Retry logic
        task.delay(2, function()
            TeleportHandler.teleportToPlace(player, placeName)
        end)
    end
end

-- Group teleport
function TeleportHandler.teleportGroup(players: {Player}, placeName: string)
    local placeId = PlaceConfig.PlaceIds[placeName]
    if not placeId then return end

    local success, result = pcall(function()
        return TeleportService:TeleportAsync(placeId, players)
    end)

    if not success then
        warn("Group teleport failed:", result)
    end
end

-- Handle teleport failures
TeleportService.TeleportInitFailed:Connect(function(player, result, errorMessage)
    warn("Teleport init failed for", player.Name, ":", errorMessage)
end)

return TeleportHandler
```

### Teleport Zones

```lua
-- Teleport zone (part in workspace)
local teleportZone = workspace.TeleportToDriftplain  -- a Part

teleportZone.Touched:Connect(function(hit)
    local player = Players:GetPlayerFromCharacter(hit.Parent)
    if player then
        TeleportHandler.teleportToPlace(player, "Driftplain")
    end
end)
```

---

## Sound Effects & Animation Feedback

### Feedback System

```lua
-- src/client/FeedbackSystem.luau
local FeedbackSystem = {}

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local sounds = {
    pickup = "rbxassetid://123456789",
    eat = "rbxassetid://123456790",
    drink = "rbxassetid://123456791",
    hurt = "rbxassetid://123456792",
    attack = "rbxassetid://123456793",
    footstep_grass = "rbxassetid://123456794",
    footstep_water = "rbxassetid://123456795",
    ambient_verdant = "rbxassetid://123456796",
    ambient_driftplain = "rbxassetid://123456797",
}

function FeedbackSystem.playSound(soundName: string, position: Vector3?)
    local soundId = sounds[soundName]
    if not soundId then return end

    local sound = Instance.new("Sound")
    sound.SoundId = soundId

    if position then
        -- 3D spatial sound
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(1, 1, 1)
        part.Position = position
        part.Parent = workspace

        sound.Parent = part
        sound.RollOffMode = Enum.RollOffMode.Linear
        sound.RollOffMaxDistance = 50

        sound.Ended:Connect(function()
            part:Destroy()
        end)
    else
        -- 2D UI sound
        sound.Parent = SoundService
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end

    sound:Play()
end

function FeedbackSystem.screenShake(intensity: number, duration: number)
    local camera = workspace.CurrentCamera
    local originalCF = camera.CFrame

    local elapsed = 0
    local connection
    connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
        elapsed += dt
        if elapsed >= duration then
            connection:Disconnect()
            return
        end

        local decay = 1 - (elapsed / duration)
        local offset = Vector3.new(
            (math.random() - 0.5) * intensity * decay,
            (math.random() - 0.5) * intensity * decay,
            0
        )
        camera.CFrame = camera.CFrame * CFrame.new(offset)
    end)
end

function FeedbackSystem.flashScreen(color: Color3, duration: number)
    local player = game.Players.LocalPlayer
    local gui = player:WaitForChild("PlayerGui")

    local flash = Instance.new("ScreenGui")
    flash.IgnoreGuiInset = true
    flash.Parent = gui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = color
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = flash

    TweenService:Create(frame, TweenInfo.new(duration), {
        BackgroundTransparency = 1
    }):Play()

    task.delay(duration, function()
        flash:Destroy()
    end)
end

function FeedbackSystem.damageFlash()
    FeedbackSystem.flashScreen(Color3.fromRGB(255, 0, 0), 0.3)
    FeedbackSystem.screenShake(0.5, 0.2)
    FeedbackSystem.playSound("hurt")
end

function FeedbackSystem.pickupFlash()
    FeedbackSystem.playSound("pickup")
    -- Could add sparkle particle effect here
end

return FeedbackSystem
```

### Animation Markers for Sound Sync

```lua
-- Sync sounds to animation keyframes
local function setupAnimationSounds(animator: Animator, animation: Animation)
    local track = animator:LoadAnimation(animation)

    track:GetMarkerReachedSignal("Footstep"):Connect(function()
        local material = getGroundMaterial()
        if material == Enum.Material.Water then
            FeedbackSystem.playSound("footstep_water")
        else
            FeedbackSystem.playSound("footstep_grass")
        end
    end)

    track:GetMarkerReachedSignal("Impact"):Connect(function()
        FeedbackSystem.playSound("attack")
        FeedbackSystem.screenShake(0.3, 0.1)
    end)

    return track
end
```

---

## Event Flow Summary

```
Player Action → Client Script → RemoteEvent → Server Validation → Apply Effect
                                                    ↓
Client Feedback ← RemoteEvent/Replication ← Update State
```

### Example: Eating Food

1. Player clicks food in inventory (Client)
2. Client sends `UseItem` event to server
3. Server validates player has item
4. Server removes item from inventory
5. Server updates hunger/thirst stats
6. Server fires `ItemUsed` event to client
7. Client plays eating animation + sound
8. Client updates UI (hunger bar fills)

---

## File Structure

```
src/
  client/
    Combat/
      MeleeAttack.luau
    FeedbackSystem.luau
    init.client.luau
  server/
    ItemSystem/
      ItemPickup.luau
      ItemSpawner.luau
    Combat/
      AttackHandler.server.luau
      DamageSystem.luau
    SurvivalSystem.luau
    TeleportHandler.luau
  shared/
    Inventory.luau
    DamageTypes.luau
    ItemDefinitions.luau
```

---

## Sources

- [Pickup System Documentation](https://create.roblox.com/docs/resources/battle-royale/pickup-system)
- [Inventory Cloud Guide](https://create.roblox.com/docs/cloud/guides/inventory)
- [Open Source Inventory System](https://devforum.roblox.com/t/open-sourced-inventory-and-hotbar-system/1780963)
- [RPG Inventory Tutorial](https://devforum.roblox.com/t/making-an-rpg-inventory-system-youtube/3063238)
- [Combat Health & Damage](https://devforum.roblox.com/t/the-basics-of-combat-games-health-and-damage/2994963)
- [Advanced Melee System](https://devforum.roblox.com/t/open-source-advanced-melee-system/1579485)
- [Teleporting Between Places](https://create.roblox.com/docs/projects/teleport)
- [Sound Marker Plugin](https://devforum.roblox.com/t/sound-marker-add-sounds-to-animations-with-ease-fixed/2480416)
- [Hunger System Tutorial](https://devforum.roblox.com/t/how-to-create-a-rpg-hunger-system/476723)
