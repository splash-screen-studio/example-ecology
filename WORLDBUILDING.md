# World Building Approaches

Research on building static environments for Example Ecology (2025).

## Approaches Compared

### 1. Studio MCP Server (Rust) + Claude
**What**: Official Roblox MCP server lets AI (Claude) run Luau code and insert models directly in Studio.

**CRITICAL USAGE RULES**:
- **One-shot commands only** — do ONE thing, return fast, fail fast
- **No long/complex batch operations** — break into separate calls
- **Not for game logic** — use Rojo + Luau for anything that belongs in version control
- MCP is for **quick inspection, placement tweaks, and iteration** — not building systems

**Pros**:
- Direct manipulation of Studio scene
- Real-time feedback loop with AI
- Official Roblox support (released May 2025)

**Cons**:
- Requires Studio running
- Limited to `run_code` and `insert_model` tools
- No headless/batch mode

**Best for**: Quick tweaks, inspecting scene state, placing individual objects

**NOT for**: Terrain generation, game systems, anything that should live in code

**Links**:
- [Official GitHub](https://github.com/Roblox/studio-rust-mcp-server)
- [Community MCP (18 tools)](https://github.com/boshyxd/robloxstudio-mcp)

---

### 2. Rojo + Luau Scripts
**What**: Define world in code, sync via Rojo, run scripts to generate terrain/place objects.

**Pros**:
- Version controlled
- Reproducible builds
- Can use Perlin noise, algorithms
- No external tools needed

**Cons**:
- Terrain API is limited (voxel-based)
- Complex meshes need external modeling
- Slower iteration than visual tools

**Best for**: Procedural terrain, algorithmic placement, code-driven layouts

---

### 3. Blender + Manual Import
**What**: Model in Blender, export FBX/OBJ, import to Studio as MeshParts.

**Pros**:
- Full artistic control
- Complex geometry possible
- Industry-standard workflow
- Good for unique landmarks (Driftplain spire)

**Cons**:
- Manual export/import cycle
- No automation without scripting
- Texture/material limitations in Roblox
- Must apply transforms (Ctrl+A) before export

**Best for**: Hero assets, custom models, organic shapes

**Tips**:
- Export as FBX, keep low-poly
- 1 Blender unit = 1 Roblox stud
- Apply all transforms before export

---

### 4. Blender Headless + Scripting Pipeline
**What**: Use Blender's Python API headlessly to generate/export models, then import to Roblox.

**Pros**:
- Batch generation possible
- Procedural modeling in Blender
- Can automate entire pipeline

**Cons**:
- Complex setup
- Still need import step to Studio
- Overkill for simple scenes

**Best for**: Mass asset generation, procedural variations

---

### 5. Studio Terrain Tools (Manual)
**What**: Use built-in terrain editor in Studio.

**Pros**:
- Visual, intuitive
- Native water with Shorelines beta
- Sea Level feature for large maps
- Real-time preview

**Cons**:
- Not reproducible
- Hard to version control
- Manual = slow for large worlds

**Best for**: Quick prototyping, final polish

---

### 6. Terrain Generation Plugins
**What**: Studio plugins that generate terrain from noise/heightmaps.

**Pros**:
- Fast large-scale terrain
- Configurable parameters
- Some generate rivers, forests

**Cons**:
- Plugin quality varies
- Less control than code
- May not match art style

**Links**:
- [Terrain Generator Plugin](https://devforum.roblox.com/t/terrain-generator-the-best-terrain-generation-plugin-on-roblox/1344504)
- [RTerrainGenerator (GitHub)](https://github.com/TheArturZh/RTerrainGenerator)

---

## Environment Systems

### Lighting
- `Lighting` service controls global light
- `Atmosphere` object for fog, haze, glare
- Requires `Sky` object for Atmosphere to work
- 60 stud limit on local lights

### Weather
- Open-source [Day/Night Weather Cycle](https://devforum.roblox.com/t/day-night-weather-cycle-lighting-terrain-shader-algorithm-artificial-sun-clean-efficient-open-source/3064511)
- Particles for rain/snow
- Atmosphere + Lighting tweening for transitions
- [Dynamic Lighting Plugin (Nov 2025)](https://devforum.roblox.com/t/do-you-want-a-dynamic-lighting-plugin-that-lets-you-make-daynight-weather-easily/4067125) - regional lighting for caves/buildings

### Water
- `Terrain.WaterColor` and `Terrain.WaterTransparency`
- Shorelines Beta for smooth terrain-water edges
- Sea Level feature for large maps

---

## Recommended Approach for Example Ecology

Given the project goals (static world, two contrasting biomes, artistic style):

### Hybrid Pipeline

1. **Terrain Base** → Rojo + Luau
   - Use `Terrain:FillRegion()` and `Terrain:FillBlock()` for landmass
   - Water via terrain with custom color per place
   - Algorithmic placement of terrain materials

2. **Hero Assets** → Blender + Manual Import
   - Driftplain spire
   - Verdant Basin waterfall rocks
   - Any unique landmarks

3. **Lighting/Atmosphere** → PlaceConfig.luau (already built)
   - Extend to include Atmosphere properties
   - Weather presets per biome

4. **Placement/Iteration** → Studio MCP Server
   - One-shot commands only: inspect, nudge, test
   - NOT for batch operations or system building
   - Quick checks: "what's at this position?", "move this part 5 studs"

5. **Borders/Enclosure** → Glass dome or invisible walls
   - MeshPart dome from Blender, or
   - Invisible parts with collision

### Local Assets Available
```
~/roblox-assets/
  MapleLeafTree_S3/
    MapleLeafTree_Skinned.fbx    -- skinned tree mesh
    BroadLeafTree 01_Leaves_ALB.tga
    BroadLeafTree 01_Trunk_ALB.tga
    BroadLeafTree 01_Soil_ALB.tga
```
Useful for Verdant Basin vegetation. Import FBX to Studio, apply textures.

### File Structure
```
src/
  server/
    WorldBuilder.luau      -- terrain generation
    PlaceSetup.luau        -- runs on start, builds world
  shared/
    PlaceConfig.luau       -- exists, extend for atmosphere
    TerrainData.luau       -- heightmaps, material maps
assets/
  models/                  -- FBX exports from Blender
```

---

## Sources

- [Official Roblox MCP Server](https://github.com/Roblox/studio-rust-mcp-server)
- [Community MCP Server (18 tools)](https://github.com/boshyxd/robloxstudio-mcp)
- [Atmosphere Documentation](https://create.roblox.com/docs/environment/atmosphere)
- [Terrain Documentation](https://create.roblox.com/docs/parts/terrain)
- [Day/Night Weather Cycle](https://devforum.roblox.com/t/day-night-weather-cycle-lighting-terrain-shader-algorithm-artificial-sun-clean-efficient-open-source/3064511)
- [Blender to Roblox Guide](https://www.tripo3d.ai/blog/collect/how-to-import-blender-models-into-roblox-wsuz87xrkxs)
- [RTerrainGenerator](https://github.com/TheArturZh/RTerrainGenerator)
