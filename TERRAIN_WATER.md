# Terrain, Water & Character Handling

Research on robust terrain/water systems for Example Ecology (2025).

## The Hard Problems

1. **Flat water surfaces** — terrain water doesn't stay flat at edges
2. **Water at low points only** — water should pool realistically
3. **Real lake/river bottoms** — walkable terrain under water
4. **No swimming under terrain** — character can't clip through ground
5. **Smooth swim↔walk transitions** — no jank when entering/exiting water

---

## Terrain Generation

### Approach: Heightmap + Sea Level

**Tools**:
- [Heightmaster Plugin](https://github.com/JoeSmaller/Heightmaster) — generates terrain from heightmap with water controls
- [Terrain Generation Tool](https://devforum.roblox.com/t/terrain-generation-tool/3466351) (Feb 2025) — creates realistic terrain without heightmaps
- [World Machine](https://devforum.roblox.com/t/creating-large-scale-terrain-with-world-machine/2271535) — professional heightmap generation

**Heightmaster Water Settings**:
- `Water Height` — 0-255 value for water level
- `Water Size` — area coverage
- `Water Occupancy` — voxel fill amount

**Key Insight**: Generate terrain FIRST, then fill water to a fixed Y level. Don't try to paint water — fill a region.

### Luau Terrain API

```lua
local terrain = workspace.Terrain

-- Fill a flat water region (sea level approach)
terrain:FillRegion(
    Region3.new(
        Vector3.new(-500, 0, -500),   -- min corner
        Vector3.new(500, 10, 500)      -- max corner (Y=10 is water surface)
    ),
    4,                                 -- resolution (4 = voxel size)
    Enum.Material.Water
)

-- Fill terrain UNDER water (the lake/river bottom)
terrain:FillRegion(
    Region3.new(
        Vector3.new(-100, -20, -100),
        Vector3.new(100, 0, 100)        -- stops at Y=0, below water
    ),
    4,
    Enum.Material.Sand                  -- or Mud, Rock, etc.
)
```

### Guaranteeing Solid Bottoms

**Problem**: Water voxels can exist without terrain underneath → characters fall forever or clip weirdly.

**Solution**: Always generate terrain floor BEFORE water.

```lua
local function createLake(center, radius, depth, waterSurfaceY)
    local terrain = workspace.Terrain

    -- 1. Create the basin (solid ground)
    local basinRegion = Region3.new(
        center - Vector3.new(radius, depth, radius),
        center + Vector3.new(radius, 0, radius)
    )
    terrain:FillRegion(basinRegion, 4, Enum.Material.Mud)

    -- 2. Carve out the hollow (air above basin floor)
    local hollowRegion = Region3.new(
        center - Vector3.new(radius - 4, depth - 4, radius - 4),
        center + Vector3.new(radius - 4, waterSurfaceY, radius - 4)
    )
    terrain:FillRegion(hollowRegion, 4, Enum.Material.Air)

    -- 3. Fill with water up to surface
    local waterRegion = Region3.new(
        center - Vector3.new(radius - 4, depth - 4, radius - 4),
        center + Vector3.new(radius - 4, waterSurfaceY, radius - 4)
    )
    terrain:FillRegion(waterRegion, 4, Enum.Material.Water)
end
```

---

## Water Systems

### Option 1: Native Terrain Water

**Pros**:
- Built-in swimming physics
- Automatic buoyancy
- Shorelines beta for smooth edges
- No scripting needed for basic behavior

**Cons**:
- Water surface not perfectly flat at terrain edges
- Can't customize swimming speed easily
- Performance issues at scale
- Raycast detection is buggy (can't detect water reliably)

**Best for**: Simple lakes, rivers where minor edge imperfections are acceptable

### Option 2: Hybrid (Terrain Water + Custom Controller)

**Concept**: Use terrain water for visuals, but override swimming behavior with custom controller.

```lua
local humanoid = character:WaitForChild("Humanoid")

-- Disable default swimming
humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)

-- Custom water detection + movement
local function updateWaterState()
    local rootPos = character.HumanoidRootPart.Position
    local waterSurfaceY = 10  -- known water level

    if rootPos.Y < waterSurfaceY then
        -- In water - apply custom buoyancy
        applyCustomSwimming(rootPos, waterSurfaceY)
    end
end
```

### Option 3: Part-Based Water (No Terrain Water)

**Concept**: Use transparent parts for water volume, custom physics for everything.

**Pros**:
- Perfectly flat surfaces
- Full control over behavior
- No terrain water bugs

**Cons**:
- Must implement ALL water physics from scratch
- No built-in swimming animation triggers
- More complex

**Implementation**:
```lua
-- Water volume part (invisible, non-collidable)
local waterPart = Instance.new("Part")
waterPart.Size = Vector3.new(200, 20, 200)
waterPart.Position = Vector3.new(0, 0, 0)  -- Y=0 to Y=20 is water
waterPart.Transparency = 1
waterPart.CanCollide = false
waterPart.Anchored = true

-- Visual water surface (mesh or part at top)
local waterSurface = Instance.new("Part")
waterSurface.Size = Vector3.new(200, 0.1, 200)
waterSurface.Position = Vector3.new(0, 10, 0)
waterSurface.Material = Enum.Material.Glass
waterSurface.Color = Color3.fromRGB(30, 100, 150)
waterSurface.Transparency = 0.5
waterSurface.CanCollide = false
```

---

## Water Detection

### The Raycast Problem

**Issue**: `workspace:Raycast()` doesn't reliably detect water terrain even with `IgnoreWater = false`.

**Workarounds**:

1. **Known Water Level** — store water surface Y, check character Y against it
2. **Region Check** — use `terrain:ReadVoxels()` to check material at position
3. **Double Raycast** — cast down from above AND up from below

```lua
-- Method: ReadVoxels for water detection
local function isInWater(position)
    local terrain = workspace.Terrain
    local region = Region3.new(
        position - Vector3.new(2, 2, 2),
        position + Vector3.new(2, 2, 2)
    )
    local materials, occupancies = terrain:ReadVoxels(region, 4)

    for x, xMats in materials do
        for y, yMats in xMats do
            for z, material in yMats do
                if material == Enum.Material.Water then
                    return true
                end
            end
        end
    end
    return false
end
```

### Water Depth Detection

```lua
local function getWaterDepth(position, waterSurfaceY)
    local terrain = workspace.Terrain

    -- Raycast down to find bottom
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = {terrain}

    local result = workspace:Raycast(
        position,
        Vector3.new(0, -100, 0),
        rayParams
    )

    if result and result.Material ~= Enum.Material.Water then
        local bottomY = result.Position.Y
        return waterSurfaceY - bottomY
    end

    return 0  -- no bottom found
end
```

---

## Swimming ↔ Walking Transitions

### The Core Problem

Default Roblox behavior:
- Enter water → immediately swim (even if shallow)
- Exit water → can briefly swim on land (bug reported May 2025)

**What we want**:
- Shallow water → walk (splashing)
- Deep water → swim
- Smooth blend between states

### Custom State Machine

```lua
local WaterStates = {
    DRY = "dry",
    WADING = "wading",      -- feet in water, walking
    SWIMMING = "swimming",  -- fully in water
    SURFACING = "surfacing" -- transitioning out
}

local currentState = WaterStates.DRY

local function updateWaterState(character)
    local rootPart = character.HumanoidRootPart
    local humanoid = character.Humanoid
    local position = rootPart.Position

    local waterSurfaceY = getWaterSurfaceAt(position)
    local groundY = getGroundAt(position)
    local feetY = position.Y - 3  -- approximate feet position
    local headY = position.Y + 2  -- approximate head position

    local waterDepthAtFeet = waterSurfaceY - feetY
    local isHeadAboveWater = headY > waterSurfaceY
    local canTouchBottom = (position.Y - groundY) < 6

    if waterDepthAtFeet <= 0 then
        -- Not in water
        currentState = WaterStates.DRY
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        humanoid.WalkSpeed = 16

    elseif canTouchBottom and isHeadAboveWater then
        -- Wading (shallow)
        currentState = WaterStates.WADING
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
        humanoid.WalkSpeed = 10  -- slower in water

    else
        -- Swimming (deep)
        currentState = WaterStates.SWIMMING
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
        humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    end
end
```

### Preventing Underwater Terrain Clipping

**Problem**: Character can swim under terrain edges or clip through ground.

**Solutions**:

1. **Floor Clamping** — always keep character above terrain floor
```lua
local function clampToTerrain(character)
    local rootPart = character.HumanoidRootPart
    local position = rootPart.Position

    local groundY = getGroundAt(position)
    local minY = groundY + 3  -- keep feet above ground

    if position.Y < minY then
        rootPart.CFrame = rootPart.CFrame + Vector3.new(0, minY - position.Y, 0)
    end
end
```

2. **Collision Groups** — ensure character always collides with terrain
```lua
local PhysicsService = game:GetService("PhysicsService")

-- Create groups
PhysicsService:RegisterCollisionGroup("Characters")
PhysicsService:RegisterCollisionGroup("Terrain")

-- Characters ALWAYS collide with terrain
PhysicsService:CollisionGroupSetCollidable("Characters", "Terrain", true)
```

3. **Swim Ceiling** — prevent swimming above water surface
```lua
local function enforceSwimlimits(character, waterSurfaceY)
    local rootPart = character.HumanoidRootPart
    local humanoid = character.Humanoid

    if humanoid:GetState() == Enum.HumanoidStateType.Swimming then
        -- Don't let character swim above water
        if rootPart.Position.Y > waterSurfaceY - 1 then
            -- Push down or transition to walking
            rootPart.CFrame = rootPart.CFrame - Vector3.new(0, 0.5, 0)
        end
    end
end
```

---

## Custom Buoyancy

For characters and objects in water:

```lua
local function applyBuoyancy(part, waterSurfaceY, submergedRatio)
    -- submergedRatio: 0 = not in water, 1 = fully submerged

    local buoyancyForce = part:GetMass() * workspace.Gravity * submergedRatio * 1.2
    -- 1.2 multiplier = slight upward tendency (floating)

    local bodyForce = part:FindFirstChild("BuoyancyForce") or Instance.new("VectorForce")
    bodyForce.Name = "BuoyancyForce"
    bodyForce.Force = Vector3.new(0, buoyancyForce, 0)
    bodyForce.Attachment0 = part:FindFirstChild("RootAttachment") or part:FindFirstChildWhichIsA("Attachment")
    bodyForce.Parent = part
end

local function calculateSubmersion(position, partHeight, waterSurfaceY)
    local topY = position.Y + partHeight / 2
    local bottomY = position.Y - partHeight / 2

    if bottomY >= waterSurfaceY then
        return 0  -- above water
    elseif topY <= waterSurfaceY then
        return 1  -- fully submerged
    else
        return (waterSurfaceY - bottomY) / partHeight
    end
end
```

---

## Recommended Architecture for Example Ecology

### Water Regions Config

```lua
-- src/shared/WaterConfig.luau
local WaterConfig = {}

WaterConfig.VerdantBasin = {
    -- Main lake
    {
        type = "lake",
        center = Vector3.new(0, 0, 0),
        radius = 100,
        depth = 15,
        surfaceY = 5,
    },
    -- River
    {
        type = "river",
        path = {
            Vector3.new(-200, 3, 0),
            Vector3.new(-100, 3, 50),
            Vector3.new(0, 5, 0),  -- connects to lake
        },
        width = 20,
        depth = 4,
    },
}

WaterConfig.Driftplain = {
    -- Scattered water holes (scarce)
    {
        type = "pool",
        center = Vector3.new(100, 0, -50),
        radius = 15,
        depth = 3,
        surfaceY = 2,
    },
}

return WaterConfig
```

### File Structure

```
src/
  server/
    Terrain/
      TerrainGenerator.luau    -- heightmap + material placement
      WaterGenerator.luau      -- creates water bodies from config
    Character/
      WaterController.luau     -- swim/wade state machine
      BuoyancySystem.luau      -- physics for objects in water
  shared/
    WaterConfig.luau           -- water body definitions
    PlaceConfig.luau           -- (existing) extend with water settings
```

### Key Guarantees

1. **Terrain floor always exists under water** — generate bottom first
2. **Water surface at fixed Y** — don't rely on terrain water edges
3. **Character clamped above floor** — check every frame while swimming
4. **State machine for transitions** — wading vs swimming based on depth
5. **Custom buoyancy** — consistent physics for all entities

---

## Open Questions / Edge Cases

- **Waterfalls**: Vertical water flow? Particle effect + force zone?
- **Currents**: Apply horizontal force in rivers?
- **Underwater visibility**: Fog/blur effect when submerged?
- **Animal swimming**: Same controller for NPCs?

---

## Sources

- [Terrain Documentation](https://create.roblox.com/docs/parts/terrain)
- [Heightmaster Plugin](https://github.com/JoeSmaller/Heightmaster)
- [Terrain Water Announcement](https://devforum.roblox.com/t/terrain-water-water-everywhere-big-brushes/391388)
- [Flat Water Feature Request](https://devforum.roblox.com/t/flat-water-for-smooth-terrain/177765)
- [Swimming Transition Issues](https://devforum.roblox.com/t/i-cant-properly-transition-between-swimming-and-walking/3228453)
- [Terrain Water Bug (May 2025)](https://devforum.roblox.com/t/terrain-water-can-allow-you-to-swim-on-land/3635527)
- [Custom Water Simulation](https://devforum.roblox.com/t/realistic-water-simulation-in-roblox-custom-physics-no-terrain-water-used/3066997)
- [Custom Buoyancy Systems](https://devforum.roblox.com/t/custom-buoyancy-system/1575749)
- [Character Physics Controllers](https://devforum.roblox.com/t/releasing-character-physics-controllers/2623426)
- [Raycast Water Detection](https://devforum.roblox.com/t/raycast-doesnt-detect-water-terrain-in-any-way/1326422)
- [Realistic Boat System (2025)](https://devforum.roblox.com/t/realistic-boat-system-floats-on-terrain-water-optimized-free/3541235)
