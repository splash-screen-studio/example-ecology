# Verdant Basin — Development Guide

An ecology simulation game. You are an Ecologist discovering what's wrong with interconnected ecosystems and choosing how to restore them.

**Opening Place**: Verdant Basin (lush wetland, too much abundance)
**Second Place**: Driftplain (arid plains, too little water)

## Quick Reference

### Game Design (Start Here)
| Document | Purpose |
|----------|---------|
| [GAME_DESIGN.md](./GAME_DESIGN.md) | Core concept, gameplay loop, detailed place content |
| [FUTURE_PLACES.md](./FUTURE_PLACES.md) | 7 future places outline, world structure |
| [NARRATIVE_SCRIPTS.md](./NARRATIVE_SCRIPTS.md) | NPC dialogue, quest flow, multiplayer, teleporting |
| [STORY_DESIGN.md](./STORY_DESIGN.md) | Environmental storytelling, show-don't-tell |

### Technical Design
| Document | Purpose |
|----------|---------|
| [DESIGN.md](./DESIGN.md) | Visual style, art direction |
| [WORLDBUILDING.md](./WORLDBUILDING.md) | Terrain, models, Blender workflow, MCP usage |
| [docs/ASSET_PIPELINE.md](./docs/ASSET_PIPELINE.md) | Blender to Roblox workflow, export settings |
| [TERRAIN_WATER.md](./TERRAIN_WATER.md) | Water systems, swimming, terrain generation |
| [PLACEMENT.md](./PLACEMENT.md) | Object/NPC placement, elevation service |
| [NPC_ANIMALS.md](./NPC_ANIMALS.md) | Animal animation, rigging, AI behavior |
| [NPC_PEOPLE.md](./NPC_PEOPLE.md) | Human NPCs, dialogue, quests, relationships |
| [AUDIO.md](./AUDIO.md) | Music, ambient, SFX, spatial audio, reverb |
| [UI_HUD.md](./UI_HUD.md) | Mobile-first UI, HUD, status bars, minimap |
| [GAMEPLAY_MECHANICS.md](./GAMEPLAY_MECHANICS.md) | Items, combat, survival, death/respawn, multiplayer |
| [MONETIZATION.md](./MONETIZATION.md) | Ethical monetization, game passes, subscriptions |
| [ENGINEERING.md](./ENGINEERING.md) | Git workflow, testing, CI/CD, code patterns |

---

## Implemented Systems

### Server-Side (`src/server/`)
| Module | Purpose | Key APIs |
|--------|---------|----------|
| `Data/PlayerDataService` | Session-locked player profiles | `:getData()`, `:addDiscovery()` |
| `Network/Handlers` | Server event handlers with validation | Auto-initializes |
| `Network/Validators` | Input sanitization | `Validators.validateUseItem()` |
| `Network/RateLimiter` | Exploit prevention | `RateLimiter:check()` |
| `Ecology/EcologyService` | Core simulation loop | `:applyPlayerAction()`, `:getRegionHealth()` |
| `Ecology/SpeciesData` | 15 species definitions | `.getForBiome()`, `.getByCategory()` |
| `Inventory/InventoryService` | Item management | `:addItem()`, `:useItem()`, `:transferItem()` |
| `NPC/NPCService` | Animal spawning, AI, LOD | `:spawnNPC()`, `:getNearbyNPCs()` |
| `NPC/NPCDefinitions` | 11 animal types | `.get()`, `.getBySpecies()` |
| `WorldBuilder/` | Terrain generation | `:buildWorld()`, `:rebuildWorld()` |
| `Character/WaterController` | Prevent swimming under terrain | Auto-initializes |
| `Character/SpawnService` | Safe player spawning | `:findSafeSpawn()`, `:teleportToSafePosition()` |
| `Character/StatDrainService` | Hunger/thirst drain, death | `:init()`, `:forceDrain()`, `:pauseDrain()` |
| `NPC/HumanNPCService` | Human NPC spawning | `:spawnNPC()`, `:spawnAllForPlace()` |
| `Interaction/InteractionService` | Player-world interactions | `:interact()`, `:registerInteractable()` |
| `WorldObjects/WorldObjectService` | Spawn/manage world objects | `:spawnForCurrentPlace()`, `:spawnObject()` |
| `WorldObjects/ObjectDefinitions` | 12 object types | `.get()`, `.getByBiome()` |
| `Discovery/DiscoveryService` | Track player discoveries | `:discover()`, `:hasDiscovered()` |
| `Discovery/DiscoveryDefinitions` | Species, flora, locations, lore | `.get()`, `.getByCategory()` |
| `Quest/QuestService` | Quest tracking, objectives | `:acceptQuest()`, `:updateObjective()` |
| `Quest/QuestDefinitions` | Tutorial and discovery quests | `.get()`, `.getByQuestGiver()` |
| `Dialogue/DialogueService` | NPC conversations | `:startConversation()`, `:selectResponse()` |
| `Dialogue/DialogueDefinitions` | Branching dialogue trees | `.getForNPC()`, `.getNode()` |

### Client-Side (`src/client/`)
| Module | Purpose | Key APIs |
|--------|---------|----------|
| `Audio/AudioController` | Unified audio management | `:playSFX()`, `:setAmbientVolume()` |
| `Audio/AmbientService` | Biome-based ambient sounds | `:forceZone()`, crossfade |
| `Audio/FootstepService` | Material-aware footsteps | Auto-plays on movement |
| `Audio/SFXService` | 2D/3D sound effects | `:play()`, `:playAtPart()` |
| `Audio/SoundPool` | Object pooling for sounds | `:get()`, `:release()` |
| `HUD/` | Main HUD controller | `:init()`, `:updateStat()` |
| `HUD/Components/StatsBar` | Hunger/thirst display | `.create()`, `:update()` |
| `HUD/Components/InventoryHotbar` | 5-slot item hotbar | `.create()`, `:setItems()` |
| `HUD/Components/InteractionPrompt` | Proximity interaction UI | `.create()`, E key / tap |
| `HUD/Components/NotificationToast` | Discovery/quest popups | `.create()`, `:show()` |
| `HUD/Components/DeathScreen` | Death overlay, respawn countdown | `.create()`, `:show()` |

### Shared (`src/shared/`)
| Module | Purpose |
|--------|---------|
| `PlaceConfig` | Per-place settings (lighting, terrain, materials) |
| `ElevationService` | Ground height, water detection, slope checking |
| `Network/` | RemoteEvent/Function creation, types |
| `Items/ItemDefinitions` | 25+ item definitions with effects |
| `Items/ItemTypes` | Item type definitions |
| `Audio/AudioConfig` | Ambient zones, footsteps, SFX, music |
| `Assets/ModelLoader` | Asset loading with caching and LOD |

### Tests (`tests/`)
| File | Coverage |
|------|----------|
| `shared/ItemDefinitions.spec` | Item properties, categories |
| `shared/AudioConfig.spec` | Sound asset validation |
| `server/SpeciesData.spec` | Food web, population constraints |
| `server/NPCDefinitions.spec` | Species linkage, movement stats |
| `server/StatDrainService.spec` | Drain rates, config API |
| `server/WaterController.spec` | Water state detection |
| `server/DialogueService.spec` | Conversation flow |

Run tests: `require(game.ReplicatedStorage.Tests)()`

See [TESTING.md](./TESTING.md) for comprehensive testing guide.

---

## Project Structure

```
example-ecology/
├── src/
│   ├── client/
│   │   ├── Audio/           # AudioController, AmbientService, etc.
│   │   └── HUD/             # StatsBar, InventoryHotbar, InteractionPrompt
│   ├── server/
│   │   ├── Data/            # PlayerDataService
│   │   ├── Network/         # Handlers, Validators, RateLimiter
│   │   ├── Ecology/         # EcologyService, SpeciesData
│   │   ├── Inventory/       # InventoryService
│   │   ├── NPC/             # NPCService, NPCDefinitions
│   │   ├── WorldBuilder/    # TerrainGenerator, Terrarium
│   │   ├── Character/       # WaterController, SpawnService, StatDrainService
│   │   ├── Interaction/     # InteractionService
│   │   ├── WorldObjects/    # WorldObjectService, ObjectDefinitions
│   │   ├── Discovery/       # DiscoveryService, DiscoveryDefinitions
│   │   ├── Quest/           # QuestService, QuestDefinitions
│   │   └── Dialogue/        # DialogueService, DialogueDefinitions
│   └── shared/
│       ├── Network/         # Types, ClientNetwork
│       ├── Items/           # ItemDefinitions, ItemTypes
│       ├── Audio/           # AudioConfig, Types
│       └── Assets/          # ModelLoader
├── tests/                   # TestEZ specs
├── docs/                    # Additional documentation
├── marketing/               # Thumbnails, icons
├── default.project.json     # Rojo config
├── wally.toml               # Dependencies (ProfileService, TestEZ)
└── *.md                     # Design documentation
```

---

## Key Dependencies (wally.toml)

```toml
[server-dependencies]
ProfileService = "etheroit/profileservice@1.2.0"

[dev-dependencies]
TestEZ = "roblox/testez@0.4.1"
```

---

## Place Configuration

Both places share code via `src/shared/PlaceConfig.luau`:

```lua
local PlaceConfig = require(game.ReplicatedStorage.Shared.PlaceConfig)

-- Get current place settings
local config = PlaceConfig.getCurrent()
print(config.name)   -- "Verdant Basin" or "Driftplain"
print(config.biome)  -- "wetland" or "plains"

-- Get terrain config with biome-specific materials
local terrain = PlaceConfig.getTerrainConfig()
print(terrain.materials.primary)  -- Sand for Driftplain, Grass for Verdant

-- Apply lighting for current place
PlaceConfig.applyLighting()
```

### Biome Materials
| Place | Primary | Secondary | Dry | Grass % |
|-------|---------|-----------|-----|---------|
| Verdant Basin | Grass | LeafyGrass | Ground | 70% |
| Driftplain | Sand | Ground | Sandstone | 15% |

---

## Server Initialization Order

In `src/server/init.server.luau`:
1. PlayerDataService
2. NetworkHandlers (includes InventoryService)
3. EcologyService
4. NPCService
5. DiscoveryService
6. QuestService
7. DialogueService
8. WaterController
9. SpawnService
10. StatDrainService
11. InteractionService
12. WorldObjectService

All services exported to `_G` for Studio debugging.

---

## HUD System

The HUD is initialized automatically on client start:

```lua
-- Client gets stats/inventory automatically on join
-- Updates via Network.Events.StatUpdate and InventoryUpdate

-- Hotbar keyboard shortcuts: 1-5 to select slot
-- E key or tap to interact with nearby objects
```

### StatsBar (top-left)
- Hunger bar (orange, warns at <25%)
- Thirst bar (blue, warns at <25%)
- Animated transitions, color warnings

### InventoryHotbar (bottom-center)
- 5 item slots with icons and quantity
- Keyboard shortcuts 1-5
- Click/tap to use selected item

### InteractionPrompt (follows objects)
- Auto-detects nearby interactables
- Shows "Press E to..." or "Tap to..."
- Positioned above target object

---

## World Objects

### Spawning Objects

```lua
-- Spawn objects for current biome
_G.WorldObjectService:spawnForCurrentPlace()

-- Spawn in specific region
_G.WorldObjectService:spawnObjectsInRegion(center, size, "wetland")

-- Manually spawn single object
local def = require(script.WorldObjects.ObjectDefinitions).wetland_berries
_G.WorldObjectService:spawnObject(def, Vector3.new(0, 10, 0))
```

### Object Types

| Object | Biome | Type | Gives | Respawn |
|--------|-------|------|-------|---------|
| Marsh Berries | wetland | harvest | berries (2-5) | 2 min |
| Water Lily | wetland | harvest | lily_seeds (1-2) | 3 min |
| Driftwood | wetland | pickup | wood (1-3) | 5 min |
| River Stone | wetland | pickup | stone (1-2) | 4 min |
| Marsh Herb | wetland | harvest | fiber (2-4) | 1.5 min |
| Prairie Grass | plains | harvest | fiber (1-3) | 1 min |
| Sandstone | plains | pickup | stone (1-2) | 3 min |
| Cactus Fruit | plains | harvest | apple (1-2) | 5 min |
| Wild Apple | all | harvest | apple (1-3) | 2.5 min |
| Basin Orchid | wetland | pickup | rare_flower (1) | 10 min |

---

## Interaction System

### Registering Interactables

```lua
local InteractionService = require(script.Interaction.InteractionService)

InteractionService:registerInteractable(model, {
    id = "unique_id",
    interactionType = "harvest", -- pickup, harvest, observe, examine, talk, use
    displayName = "Berry Bush",
    prompt = "Pick berries",
    range = 8,
    cooldown = 1,
    itemId = "berries",
    quantity = 3,
    respawnTime = 120,
})
```

### Interaction Types
- **pickup**: Adds item to inventory, destroys object
- **harvest**: Adds item, object respawns after timer
- **observe**: Adds to discovery journal
- **examine**: Shows description popup
- **talk**: Triggers NPC dialogue via DialogueService
- **use**: Custom handler required

---

## Development Workflow

### Daily Commands

```bash
# Start Rojo
rojo serve

# Lint
selene src/

# Format
stylua src/

# Build
rojo build -o build.rbxl
```

### Regenerate Terrain (in Studio command bar, Server context)

```lua
_G.WorldBuilder:rebuildWorld()
```

### Spawn World Objects

```lua
_G.WorldObjectService:spawnForCurrentPlace()
```

### Git Workflow

```bash
git checkout -b feature/my-feature
git add .
git commit -m "feat: add thing"
git push -u origin feature/my-feature
```

---

## Current Open Issues

| # | Issue | Status |
|---|-------|--------|
| 22 | Camera System | Open |
| 30 | Item Pickup Audio/Visual Feedback | Open |
| 31 | Dialogue UI Implementation | Open |
| 32 | Regression Tests | Open |
| 33 | Flashlight System | Open |

### Recently Completed
- #29 Discovery Locations - Real positions for proximity discoveries
- #28 Death/Respawn Flow - Death screen, respawn countdown
- #27 Quest-Inventory Integration - Collection quests track items
- #26 Human NPC Spawning - Quest givers in the world
- #25 Stat Drain - Hunger/thirst decrease over time, death trigger
- #21 NPC Dialogue - Branching dialogue trees, quest integration
- #20 Discovery System - Species, flora, locations, lore tracking
- #19 Quest System - Objectives, rewards, prerequisites
- #24 Player Spawn - Safe spawn point detection
- #16 Player HUD - Stats bars, inventory hotbar
- #17 Interaction System - Proximity detection, E key / tap
- #18 World Objects - Harvestable plants, collectibles

---

## Design Principles

### Mobile-First
- Design for smallest screen first
- Large touch targets (44x44 min)
- Minimal HUD, collapsible menus
- No text walls

### Show, Don't Tell
- Environmental storytelling
- Audio/visual feedback over text
- Let players discover through play
- NPC hints, not tutorials

### Code Quality
- Use Selene + StyLua
- Type annotations on public APIs
- Single responsibility modules
- Test critical systems

### Version Numbers
- Include version numbers in all components and subsystems
- Bump versions when making changes
- Display version in output/logs when component loads
- Use independent versioning per subcomponent (e.g., `InventoryHotbar v1.2.0`)
- Format: `local VERSION = "X.Y.Z"` at top of module
- Log format: `print("[ModuleName v" .. VERSION .. "] Initialized")`

### Testing Requirements
- **After every bug fix**: Add a regression test that would have caught the bug
- **Before PR merge**: Run `require(game.ReplicatedStorage.Tests)()` in Studio
- **Data validation**: All definition modules (Items, NPCs, Audio) must have spec files
- **Service behavior**: Critical services need module structure and config tests
- **Sound assets**: No `rbxassetid://0` placeholders in production
- See [TESTING.md](./TESTING.md) for full testing guide

### NPC Naming
- Use nature-themed names (e.g., Dr. Sage, Ranger Maya)
- Avoid real-world first/last name combinations
- No characters named Marcus, Chen, or other culturally-specific names
- NPC IDs use snake_case (e.g., `researcher_sage`)
- Display names use proper casing (e.g., "Dr. Sage")

### Implement in Twos
- Build two instances of a feature to identify shared patterns
- Extract frameworks/abstractions after seeing the commonality
- Keep to 2-3 instances until the pattern is proven
- Avoid fixing early bugs across many places
- Examples:
  - Two biomes (Verdant Basin, Driftplain) → PlaceConfig abstraction
  - Two object types before ObjectDefinitions framework
  - Two quest types before Quest system architecture

---

## Places Overview

### Verdant Basin
Dense, lowland ecosystem. Water, plants, animals interconnected.

- Lush greens, soft light
- Rivers, waterfalls, wetlands
- 70% grass coverage
- Teaches: interconnection, nurturing

### Driftplain
Harsh, open region. Resources scarce. Survival depends on adaptation.

- Muted browns, harsh light
- Sandy terrain, sparse vegetation
- 15% grass coverage
- Teaches: scarcity, resilience
