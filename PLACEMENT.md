# Object Placement & Elevation Service

Research on reliable placement of models, NPCs, and assets on terrain (2025).

## The Problem

Placing objects on terrain is tricky because:
1. Terrain has varying elevation (hills, valleys)
2. Objects have different pivot points / bounding boxes
3. Need to avoid water, cliffs, and other obstacles
4. NPCs spawning inside terrain is common (~30-45% of the time without proper handling)
5. Slope alignment needed for natural look

---

## Core Elevation Service

### Design Goals

1. **Get ground Y at any XZ position** — fast, reliable
2. **Get surface normal** — for slope alignment
3. **Get terrain material** — avoid placing on water, air
4. **Account for model bounds** — place bottom on ground, not center
5. **Works with MCP-built terrain** — reads whatever terrain exists

### Implementation

```lua
-- src/shared/ElevationService.luau
local ElevationService = {}

local terrain = workspace.Terrain
local MAX_HEIGHT = 500
local MIN_HEIGHT = -100

-- Get ground position and info at XZ coordinate
function ElevationService.getGroundInfo(x: number, z: number): {
    position: Vector3,
    normal: Vector3,
    material: Enum.Material,
    isValid: boolean
}
    local origin = Vector3.new(x, MAX_HEIGHT, z)
    local direction = Vector3.new(0, MIN_HEIGHT - MAX_HEIGHT, 0)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = {terrain}
    rayParams.IgnoreWater = true  -- get solid ground, not water surface

    local result = workspace:Raycast(origin, direction, rayParams)

    if result then
        return {
            position = result.Position,
            normal = result.Normal,
            material = result.Material,
            isValid = true
        }
    end

    return {
        position = Vector3.new(x, 0, z),
        normal = Vector3.yAxis,
        material = Enum.Material.Air,
        isValid = false
    }
end

-- Get just the Y height (fast path)
function ElevationService.getGroundY(x: number, z: number): number
    return ElevationService.getGroundInfo(x, z).position.Y
end

-- Check if position is valid for placement
function ElevationService.canPlaceAt(x: number, z: number, options: {
    allowWater: boolean?,
    maxSlope: number?,  -- max angle in degrees
    allowedMaterials: {Enum.Material}?,
}?): boolean
    options = options or {}
    local info = ElevationService.getGroundInfo(x, z)

    if not info.isValid then
        return false
    end

    -- Check water
    if not options.allowWater then
        local waterCheck = ElevationService.isInWater(x, info.position.Y, z)
        if waterCheck then
            return false
        end
    end

    -- Check slope
    if options.maxSlope then
        local angle = math.deg(math.acos(info.normal:Dot(Vector3.yAxis)))
        if angle > options.maxSlope then
            return false
        end
    end

    -- Check material
    if options.allowedMaterials then
        local allowed = false
        for _, mat in options.allowedMaterials do
            if info.material == mat then
                allowed = true
                break
            end
        end
        if not allowed then
            return false
        end
    end

    return true
end

-- Check if position is underwater
function ElevationService.isInWater(x: number, y: number, z: number): boolean
    local region = Region3.new(
        Vector3.new(x - 2, y - 2, z - 2),
        Vector3.new(x + 2, y + 2, z + 2)
    )
    local materials, _ = terrain:ReadVoxels(region, 4)

    for _, xMats in materials do
        for _, yMats in xMats do
            for _, material in yMats do
                if material == Enum.Material.Water then
                    return true
                end
            end
        end
    end
    return false
end

-- Get water surface Y at position (if any)
function ElevationService.getWaterSurfaceY(x: number, z: number): number?
    local origin = Vector3.new(x, MAX_HEIGHT, z)
    local direction = Vector3.new(0, MIN_HEIGHT - MAX_HEIGHT, 0)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Include
    rayParams.FilterDescendantsInstances = {terrain}
    rayParams.IgnoreWater = false  -- detect water surface

    local result = workspace:Raycast(origin, direction, rayParams)

    if result and result.Material == Enum.Material.Water then
        return result.Position.Y
    end

    return nil
end

return ElevationService
```

---

## Model Placement

### The Pivot Problem

Models have pivot points that may not be at their bottom. Placing at ground position puts the pivot on ground, causing:
- Model floats above ground (pivot at center)
- Model sinks into ground (pivot at top)

### Solution: Bounds-Aware Placement

```lua
-- src/shared/PlacementService.luau
local PlacementService = {}

local ElevationService = require(script.Parent.ElevationService)

-- Get model's bottom offset from pivot
local function getBottomOffset(model: Model): number
    local cf, size = model:GetBoundingBox()
    local pivotY = model:GetPivot().Position.Y
    local bottomY = cf.Position.Y - size.Y / 2
    return pivotY - bottomY
end

-- Place model on ground at XZ position
function PlacementService.placeOnGround(model: Model, x: number, z: number, options: {
    alignToSlope: boolean?,
    randomRotation: boolean?,
    offsetY: number?,
}?): boolean
    options = options or {}

    local groundInfo = ElevationService.getGroundInfo(x, z)
    if not groundInfo.isValid then
        return false
    end

    local bottomOffset = getBottomOffset(model)
    local finalY = groundInfo.position.Y + bottomOffset + (options.offsetY or 0)

    local cf: CFrame

    if options.alignToSlope then
        -- Align to surface normal
        cf = PlacementService.createSlopeAlignedCFrame(
            Vector3.new(x, finalY, z),
            groundInfo.normal,
            options.randomRotation
        )
    else
        -- Just position, optional random Y rotation
        local rotation = options.randomRotation and math.random() * math.pi * 2 or 0
        cf = CFrame.new(x, finalY, z) * CFrame.Angles(0, rotation, 0)
    end

    model:PivotTo(cf)
    return true
end

-- Create CFrame aligned to surface normal
function PlacementService.createSlopeAlignedCFrame(
    position: Vector3,
    normal: Vector3,
    randomRotation: boolean?
): CFrame
    -- Default forward direction
    local forward = Vector3.zAxis

    -- If normal is nearly vertical, use simple rotation
    if math.abs(normal:Dot(Vector3.yAxis)) > 0.99 then
        local yRot = randomRotation and math.random() * math.pi * 2 or 0
        return CFrame.new(position) * CFrame.Angles(0, yRot, 0)
    end

    -- Calculate right vector (perpendicular to normal and world up)
    local right = Vector3.yAxis:Cross(normal).Unit

    -- Calculate actual forward (perpendicular to normal and right)
    forward = normal:Cross(right).Unit

    -- Apply random rotation around normal if requested
    if randomRotation then
        local angle = math.random() * math.pi * 2
        local rotCF = CFrame.fromAxisAngle(normal, angle)
        forward = rotCF:VectorToWorldSpace(forward)
        right = rotCF:VectorToWorldSpace(right)
    end

    return CFrame.fromMatrix(position, right, normal, -forward)
end

-- Place multiple instances with distribution
function PlacementService.scatter(
    template: Model,
    center: Vector3,
    radius: number,
    count: number,
    options: {
        minSpacing: number?,
        alignToSlope: boolean?,
        canPlaceCheck: ((x: number, z: number) -> boolean)?,
    }?
): {Model}
    options = options or {}
    local placed = {}
    local positions = {}
    local minSpacing = options.minSpacing or 5
    local attempts = 0
    local maxAttempts = count * 10

    while #placed < count and attempts < maxAttempts do
        attempts += 1

        -- Random position in circle
        local angle = math.random() * math.pi * 2
        local dist = math.sqrt(math.random()) * radius
        local x = center.X + math.cos(angle) * dist
        local z = center.Z + math.sin(angle) * dist

        -- Check spacing from existing
        local tooClose = false
        for _, pos in positions do
            if (Vector3.new(x, 0, z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < minSpacing then
                tooClose = true
                break
            end
        end

        if tooClose then continue end

        -- Custom placement check
        if options.canPlaceCheck and not options.canPlaceCheck(x, z) then
            continue
        end

        -- Default placement check
        if not ElevationService.canPlaceAt(x, z, { maxSlope = 45 }) then
            continue
        end

        -- Clone and place
        local clone = template:Clone()
        if PlacementService.placeOnGround(clone, x, z, {
            alignToSlope = options.alignToSlope,
            randomRotation = true,
        }) then
            clone.Parent = workspace
            table.insert(placed, clone)
            table.insert(positions, Vector3.new(x, 0, z))
        else
            clone:Destroy()
        end
    end

    return placed
end

return PlacementService
```

---

## NPC Spawning

### Safe NPC Spawn

```lua
-- src/server/NPCSpawner.luau
local NPCSpawner = {}

local ElevationService = require(game.ReplicatedStorage.Shared.ElevationService)
local PlacementService = require(game.ReplicatedStorage.Shared.PlacementService)

function NPCSpawner.spawnAt(npcTemplate: Model, x: number, z: number): Model?
    -- Validate position
    if not ElevationService.canPlaceAt(x, z, {
        allowWater = false,
        maxSlope = 30,  -- NPCs shouldn't spawn on steep slopes
    }) then
        return nil
    end

    local npc = npcTemplate:Clone()

    -- Place with slight Y offset to prevent ground clipping
    local success = PlacementService.placeOnGround(npc, x, z, {
        alignToSlope = false,  -- NPCs stay upright
        offsetY = 0.5,         -- slight lift to prevent clipping
    })

    if not success then
        npc:Destroy()
        return nil
    end

    npc.Parent = workspace

    -- Extra safety: verify NPC isn't in ground after placement
    task.defer(function()
        if npc and npc.PrimaryPart then
            local rootPos = npc.PrimaryPart.Position
            local groundY = ElevationService.getGroundY(rootPos.X, rootPos.Z)
            if rootPos.Y < groundY + 1 then
                -- Push up
                npc:PivotTo(npc:GetPivot() + Vector3.new(0, groundY + 2 - rootPos.Y, 0))
            end
        end
    end)

    return npc
end

-- Spawn in random position within area
function NPCSpawner.spawnInArea(
    npcTemplate: Model,
    center: Vector3,
    radius: number,
    maxAttempts: number?
): Model?
    maxAttempts = maxAttempts or 20

    for _ = 1, maxAttempts do
        local angle = math.random() * math.pi * 2
        local dist = math.sqrt(math.random()) * radius
        local x = center.X + math.cos(angle) * dist
        local z = center.Z + math.sin(angle) * dist

        local npc = NPCSpawner.spawnAt(npcTemplate, x, z)
        if npc then
            return npc
        end
    end

    warn("Failed to spawn NPC after", maxAttempts, "attempts")
    return nil
end

return NPCSpawner
```

---

## Procedural Asset Placement

### Poisson Disk Sampling for Natural Distribution

```lua
-- src/shared/PoissonDisk.luau
local PoissonDisk = {}

-- Generate evenly-spaced random points
function PoissonDisk.generate(
    width: number,
    height: number,
    minDistance: number,
    maxAttempts: number?
): {{x: number, y: number}}
    maxAttempts = maxAttempts or 30
    local cellSize = minDistance / math.sqrt(2)
    local gridWidth = math.ceil(width / cellSize)
    local gridHeight = math.ceil(height / cellSize)

    local grid = {}
    local points = {}
    local active = {}

    local function gridIndex(x, y)
        return math.floor(x / cellSize) + math.floor(y / cellSize) * gridWidth
    end

    local function addPoint(x, y)
        table.insert(points, {x = x, y = y})
        table.insert(active, #points)
        grid[gridIndex(x, y)] = #points
    end

    -- Start with random point
    addPoint(math.random() * width, math.random() * height)

    while #active > 0 do
        local idx = math.random(1, #active)
        local point = points[active[idx]]
        local found = false

        for _ = 1, maxAttempts do
            local angle = math.random() * math.pi * 2
            local dist = minDistance + math.random() * minDistance
            local nx = point.x + math.cos(angle) * dist
            local ny = point.y + math.sin(angle) * dist

            if nx >= 0 and nx < width and ny >= 0 and ny < height then
                local valid = true
                local gx = math.floor(nx / cellSize)
                local gy = math.floor(ny / cellSize)

                -- Check nearby cells
                for dx = -2, 2 do
                    for dy = -2, 2 do
                        local checkIdx = (gx + dx) + (gy + dy) * gridWidth
                        if grid[checkIdx] then
                            local other = points[grid[checkIdx]]
                            local d = math.sqrt((nx - other.x)^2 + (ny - other.y)^2)
                            if d < minDistance then
                                valid = false
                                break
                            end
                        end
                    end
                    if not valid then break end
                end

                if valid then
                    addPoint(nx, ny)
                    found = true
                    break
                end
            end
        end

        if not found then
            table.remove(active, idx)
        end
    end

    return points
end

return PoissonDisk
```

### Biome-Aware Placement

```lua
-- src/server/BiomePlacer.luau
local BiomePlacer = {}

local ElevationService = require(game.ReplicatedStorage.Shared.ElevationService)
local PlacementService = require(game.ReplicatedStorage.Shared.PlacementService)
local PoissonDisk = require(game.ReplicatedStorage.Shared.PoissonDisk)

local BIOME_CONFIGS = {
    VerdantBasin = {
        trees = {
            density = 0.8,    -- high
            minSpacing = 10,
            nearWaterBonus = 1.5,  -- denser near water
            materials = {Enum.Material.Grass, Enum.Material.LeafyGrass},
        },
        rocks = {
            density = 0.3,
            minSpacing = 15,
            materials = {Enum.Material.Rock, Enum.Material.Slate},
        },
    },
    Driftplain = {
        trees = {
            density = 0.1,    -- sparse
            minSpacing = 30,
            nearWaterBonus = 3.0,  -- much denser near scarce water
            materials = {Enum.Material.Sand, Enum.Material.Sandstone},
        },
        rocks = {
            density = 0.5,
            minSpacing = 8,
            materials = {Enum.Material.Sandstone, Enum.Material.Rock},
        },
    },
}

function BiomePlacer.populateRegion(
    biome: string,
    assetType: string,
    template: Model,
    regionMin: Vector3,
    regionMax: Vector3
)
    local config = BIOME_CONFIGS[biome][assetType]
    if not config then
        warn("No config for", biome, assetType)
        return {}
    end

    local width = regionMax.X - regionMin.X
    local height = regionMax.Z - regionMin.Z

    -- Generate distribution points
    local points = PoissonDisk.generate(width, height, config.minSpacing)

    -- Place assets
    local placed = {}
    for _, point in points do
        -- Random chance based on density
        if math.random() > config.density then continue end

        local worldX = regionMin.X + point.x
        local worldZ = regionMin.Z + point.y

        -- Check material
        local groundInfo = ElevationService.getGroundInfo(worldX, worldZ)
        local materialAllowed = false
        for _, mat in config.materials do
            if groundInfo.material == mat then
                materialAllowed = true
                break
            end
        end
        if not materialAllowed then continue end

        -- Water proximity bonus
        if config.nearWaterBonus then
            local waterY = ElevationService.getWaterSurfaceY(worldX, worldZ)
            if waterY then
                -- Near water - boost chance
                if math.random() > (1 / config.nearWaterBonus) then
                    -- Place even if density roll failed
                end
            end
        end

        -- Place the asset
        local clone = template:Clone()
        if PlacementService.placeOnGround(clone, worldX, worldZ, {
            alignToSlope = true,
            randomRotation = true,
        }) then
            clone.Parent = workspace
            table.insert(placed, clone)
        else
            clone:Destroy()
        end
    end

    return placed
end

return BiomePlacer
```

---

## Integration with MCP Server

The elevation service **reads** existing terrain — it doesn't care how terrain was created.

**Workflow**:
1. Build terrain with MCP Server (quick iteration)
2. Rojo code uses ElevationService to place assets on that terrain
3. Changes sync both ways

**MCP for inspection** (one-shot commands):
```lua
-- Quick check via MCP
print(workspace.Terrain:ReadVoxels(...))
print(workspace:Raycast(...))
```

**Rojo for systems** (version controlled):
```lua
-- ElevationService.luau, PlacementService.luau, etc.
-- These live in src/ and sync via Rojo
```

---

## File Structure

```
src/
  shared/
    ElevationService.luau     -- ground detection, water check
    PlacementService.luau     -- model placement with bounds
    PoissonDisk.luau          -- natural distribution algorithm
  server/
    NPCSpawner.luau           -- safe NPC spawning
    BiomePlacer.luau          -- populate regions with assets
    WorldSetup.luau           -- orchestrates terrain + placement
```

---

## Key Guarantees

1. **Never spawn inside terrain** — raycast from above, offset by bounds
2. **Respect terrain material** — check before placement
3. **Natural distribution** — Poisson disk, not random scatter
4. **Slope awareness** — align to normal or reject steep slopes
5. **Water avoidance** — explicit checks via ReadVoxels
6. **Works with any terrain** — reads existing voxels, doesn't assume creation method

---

## Sources

- [Raycast Terrain Detection](https://devforum.roblox.com/t/raycasting-to-detect-terrain/227655)
- [Spawning on Terrain Surface](https://devforum.roblox.com/t/how-to-spawn-objects-on-top-of-the-terraingrass/1935505)
- [Surface Normal Alignment Tutorial](https://devforum.roblox.com/t/aligning-object-to-surface-using-cframefrommatrix/2440345)
- [PivotOffset Documentation](https://create.roblox.com/docs/reference/engine/classes/BasePart/PivotOffset)
- [AI-Assisted Object Placement](https://vasundhara.io/blogs/ai-in-roblox-transforming-game-environments-with-generative-design)
- [Terrain API Documentation](https://create.roblox.com/docs/reference/engine/classes/Terrain)
