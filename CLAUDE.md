# Example Ecology — Development Guide

An ecology simulation with two contrasting biomes: **Verdant Basin** (lush, interconnected) and **Driftplain** (harsh, migratory).

## Quick Reference

| Document | Purpose |
|----------|---------|
| [DESIGN.md](./DESIGN.md) | Game concept, place descriptions, visual style |
| [WORLDBUILDING.md](./WORLDBUILDING.md) | Terrain, models, Blender workflow, MCP usage |
| [TERRAIN_WATER.md](./TERRAIN_WATER.md) | Water systems, swimming, terrain generation |
| [PLACEMENT.md](./PLACEMENT.md) | Object/NPC placement, elevation service |
| [NPC_ANIMALS.md](./NPC_ANIMALS.md) | Animal animation, rigging, AI behavior |
| [UI_HUD.md](./UI_HUD.md) | Mobile-first UI, HUD, status bars, minimap |
| [GAMEPLAY_MECHANICS.md](./GAMEPLAY_MECHANICS.md) | Items, combat, survival, teleporting |
| [STORY_DESIGN.md](./STORY_DESIGN.md) | Narrative, environmental storytelling, no-text tutorials |
| [ENGINEERING.md](./ENGINEERING.md) | Git workflow, testing, CI/CD, code patterns |

---

## Project Structure

```
example-ecology/
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
3. **Mechanics** → [GAMEPLAY_MECHANICS.md](./GAMEPLAY_MECHANICS.md)
4. **UI** → [UI_HUD.md](./UI_HUD.md)
5. **Story** → [STORY_DESIGN.md](./STORY_DESIGN.md)
