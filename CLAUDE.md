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

## Project Structure

```
verdant-basin/
├── src/
│   ├── client/           # Client-side scripts
│   ├── server/           # Server-side scripts
│   └── shared/           # Shared modules (PlaceConfig, etc.)
├── marketing/            # Thumbnails, icons
├── default.project.json  # Rojo config (single file for both places)
├── .env                  # Secrets (gitignored)
├── wally.toml            # Dependencies
├── selene.toml           # Linter config
├── stylua.toml           # Formatter config
└── *.md                  # Documentation
```

---

## Key IDs

Stored in `.env` (gitignored):
- `EXPERIENCE_ID` — shared experience
- `VERDANT_BASIN_PLACE_ID`
- `DRIFTPLAIN_PLACE_ID`
- `ROBLOX_API_KEY`

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

### Git Workflow

```bash
# Feature branch
git checkout -b feature/my-feature

# Commit often
git add .
git commit -m "feat: add thing"

# Push and PR
git push -u origin feature/my-feature
```

---

## MCP Server Usage

**CRITICAL RULES:**
1. **One-shot commands only** — do ONE thing, return fast
2. **No batch/complex operations** — break into separate calls
3. **Not for game logic** — that goes in Rojo/Luau code
4. **Use for**: inspection, quick placement, iteration

See [WORLDBUILDING.md](./WORLDBUILDING.md) for details.

---

## Place Configuration

Both places share code via `src/shared/PlaceConfig.luau`:

```lua
local PlaceConfig = require(game.ReplicatedStorage.Shared.PlaceConfig)

-- Get current place settings
local config = PlaceConfig.getCurrent()
print(config.name)  -- "Verdant Basin" or "Driftplain"

-- Apply lighting for current place
PlaceConfig.applyLighting()
```

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

---

## Places Overview

### Verdant Basin
Dense, lowland ecosystem. Water, plants, animals interconnected. Small changes ripple quickly.

- Lush greens, soft light
- Rivers, waterfalls, wetlands
- Dense vegetation, hidden secrets
- Teaches: interconnection, nurturing

### Driftplain
Harsh, open region. Resources migrate. Survival depends on adaptation.

- Muted browns, harsh light
- Sparse grass, scattered water holes
- Monolithic spire landmark
- Teaches: scarcity, resilience

---

## Next Steps

See individual docs for implementation details:

1. **Terrain** → [TERRAIN_WATER.md](./TERRAIN_WATER.md)
2. **Animals** → [NPC_ANIMALS.md](./NPC_ANIMALS.md)
3. **Human NPCs** → [NPC_PEOPLE.md](./NPC_PEOPLE.md)
4. **Audio** → [AUDIO.md](./AUDIO.md)
5. **Mechanics** → [GAMEPLAY_MECHANICS.md](./GAMEPLAY_MECHANICS.md)
6. **UI** → [UI_HUD.md](./UI_HUD.md)
7. **Story** → [STORY_DESIGN.md](./STORY_DESIGN.md)
