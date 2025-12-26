# Asset Pipeline: Blender to Roblox

This document describes the workflow for creating 3D models in Blender and importing them into Roblox Studio.

## Quick Reference

| Setting | Value |
|---------|-------|
| Blender Scale | 1 unit = 1 stud |
| Export Format | FBX |
| FBX Scale | 1.0 |
| Up Axis | Y Up |
| Forward | -Z Forward |
| Max Texture Size | 1024x1024 |
| Texture Format | PNG (no alpha) or TGA |

## Blender Setup

### Unit Scale

Configure Blender to work in Roblox studs:

1. Open **Scene Properties** (cone icon)
2. Under **Units**:
   - Unit System: **Metric**
   - Unit Scale: **0.01** (1 Blender unit = 1 stud)
   - Length: **Centimeters**

### Orientation

Roblox uses Y-up coordinate system:
- **Y** = Up
- **Z** = Forward (character facing direction)
- **X** = Right

## Modeling Standards

### Naming Conventions

Use lowercase with underscores. Prefix indicates purpose:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `mesh_` | Visual mesh | `mesh_rabbit_body` |
| `col_` | Collision mesh | `col_rabbit_body` |
| `attach_` | Attachment point | `attach_head` |
| `bone_` | Armature bone | `bone_spine_01` |

### Model Structure

```
rabbit (Empty/Armature)
├── mesh_body
├── mesh_head
├── mesh_ears
├── col_body (simplified collision)
├── attach_saddle (attachment point)
└── Armature
    ├── bone_root
    ├── bone_spine
    └── ...
```

### Poly Counts (Guidelines)

| Asset Type | Target Tris | Max Tris |
|------------|-------------|----------|
| Small props | 100-500 | 1,000 |
| Medium animals | 500-2,000 | 4,000 |
| Large animals | 1,000-4,000 | 8,000 |
| Environment | 200-1,000 | 2,000 |
| Player visible | 2,000-5,000 | 10,000 |

### Collision Meshes

Create simplified collision geometry:

1. Duplicate the visual mesh
2. Rename with `col_` prefix
3. Apply **Decimate** modifier (ratio ~0.1-0.3)
4. Make convex if possible (faster physics)
5. Hide from render (outliner: disable camera icon)

## Texturing

### Resolution Limits

| Asset Type | Max Size |
|------------|----------|
| Props | 256x256 |
| Animals | 512x512 |
| Large/Hero | 1024x1024 |

### Texture Types

| Texture | Suffix | Notes |
|---------|--------|-------|
| Diffuse/Color | `_diffuse` | RGB, no alpha |
| Normal Map | `_normal` | Tangent space |
| Roughness | `_roughness` | Grayscale |
| Metallic | `_metallic` | Grayscale |

### Format

- **PNG** for opaque textures
- **TGA** if alpha needed (but avoid transparency)
- **Power of 2** dimensions (256, 512, 1024)

## Export Settings (FBX)

### Step-by-Step

1. Select all objects to export
2. **File → Export → FBX (.fbx)**
3. Configure settings:

### Include

- [x] Limit to Selected Objects
- [x] Object Types: Mesh, Armature, Empty
- [ ] Custom Properties (off)

### Transform

- Scale: **1.0**
- Apply Scalings: **FBX All**
- Forward: **-Z Forward**
- Up: **Y Up**
- Apply Unit: **ON**
- Use Space Transform: **ON**
- Apply Transform: **ON**

### Geometry

- [x] Apply Modifiers
- Smoothing: **Face**
- [x] Export Subdivision Surface (if used)
- [ ] Loose Edges
- [ ] Tangent Space (only if using normal maps)

### Armature (if animated)

- [x] Only Deform Bones
- Add Leaf Bones: **OFF**
- Primary Bone Axis: **Y**
- Secondary Bone Axis: **X**

### Animation (if exporting animations)

- [x] Baked Animation
- Key All Bones: **ON**
- NLA Strips: **OFF**
- Force Start/End Keying: **ON**

### Save Settings

Click **+** next to presets and save as `Roblox_Export` for reuse.

## Import into Roblox

### Method 1: Asset Manager (Recommended)

1. Open **Asset Manager** (View → Asset Manager)
2. Right-click in folder → **Import 3D**
3. Select FBX file
4. Configure import settings:
   - [x] Import as single mesh
   - [x] Use file dimensions
5. Click **Import**

### Method 2: MeshPart Direct

1. Insert → MeshPart
2. Select the MeshPart
3. In Properties, click **MeshId** → **Import**
4. Select FBX file

### Post-Import Checklist

- [ ] Scale correct? (compare to R15 rig: ~5 studs tall)
- [ ] Orientation correct? (facing forward = positive Z)
- [ ] Collision working? (test with physics)
- [ ] Materials assigned?
- [ ] Anchored if static?

## Organization in Studio

### Folder Structure

```
ReplicatedStorage/
└── Assets/
    ├── Animals/
    │   ├── Wetland/
    │   │   ├── marsh_rabbit
    │   │   ├── wetland_deer
    │   │   └── pond_turtle
    │   └── Plains/
    │       ├── plains_hare
    │       └── pronghorn
    ├── Props/
    │   ├── Vegetation/
    │   └── Rocks/
    └── Effects/
```

### Naming in Studio

Match the NPC/item IDs:

| System ID | Model Name |
|-----------|------------|
| `marsh_rabbit` | `marsh_rabbit` |
| `wetland_deer` | `wetland_deer` |
| `grass_seeds` | `grass_seeds` |

### Model Configuration

Each model should be a **Model** with:

```
marsh_rabbit (Model)
├── Body (MeshPart) ← PrimaryPart
├── Head (MeshPart)
├── Collision (Part, CanCollide=true, Transparency=1)
└── Attachments (Folder)
    ├── RootAttachment
    └── HeadAttachment
```

## Rojo Considerations

### What Rojo Can Sync

- Scripts (.luau files)
- JSON data
- Simple models (.rbxm/.rbxmx)

### What Rojo Cannot Sync Well

- Complex meshes (use Asset Manager instead)
- Textures
- Animations

### Recommended Workflow

1. **Create models** in Blender
2. **Import to Studio** via Asset Manager
3. **Organize** in ReplicatedStorage/Assets
4. **Save place** (models live in .rbxl file)
5. **Reference** models in code via paths

### Code Example

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local function getAnimalModel(animalId: string): Model?
    local category = -- determine category from NPC definition
    local folder = Assets.Animals:FindFirstChild(category)
    return folder and folder:FindFirstChild(animalId)
end
```

## LOD Strategy

For distant NPCs, use simpler meshes:

| Distance | LOD Level | Approach |
|----------|-----------|----------|
| 0-50 studs | Full | Original mesh |
| 50-150 studs | Medium | 50% poly reduction |
| 150+ studs | Low | Billboard or box |

### Implementation

Store LOD variants as children:

```
marsh_rabbit (Model)
├── LOD0 (full detail)
├── LOD1 (medium)
└── LOD2 (low/billboard)
```

## Troubleshooting

### Model Too Big/Small

- Check Blender unit scale (should be 0.01)
- Check FBX export scale (should be 1.0)
- Compare to R15 rig in Studio

### Model Rotated Wrong

- Check FBX export axes (-Z Forward, Y Up)
- May need to apply rotation in Blender (Ctrl+A → Rotation)

### Collision Not Working

- Ensure collision mesh is convex
- Check CanCollide property
- For MeshParts: set CollisionFidelity

### Textures Missing

- Re-import textures via Asset Manager
- Check texture paths in material
- Ensure textures are power-of-2 dimensions

## Asset Checklist

Before exporting any model:

- [ ] Named correctly (lowercase, underscores)
- [ ] Origin at base/center
- [ ] Scale applied (Ctrl+A → Scale)
- [ ] Rotation applied (Ctrl+A → Rotation)
- [ ] No n-gons (triangulate if needed)
- [ ] Collision mesh created
- [ ] Textures at correct resolution
- [ ] Materials assigned
- [ ] Tested in-game
