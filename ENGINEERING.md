# Software Engineering Practices for Roblox/Luau

Best practices for version control, testing, CI/CD, and code architecture (2025).

## What Applies to Roblox/Luau

| Practice | Applies? | Notes |
|----------|----------|-------|
| Git version control | ✅ Yes | Via Rojo filesystem sync |
| Feature branches | ✅ Yes | Standard Git workflow |
| Pull requests | ✅ Yes | Code review before merge |
| GitHub Issues | ✅ Yes | Track bugs, features |
| Commit often | ✅ Yes | Small, atomic commits |
| Pre-commit hooks | ✅ Yes | Selene, StyLua |
| GitHub Actions | ✅ Yes | Lint, test, deploy |
| Unit testing | ✅ Yes | TestEZ, EzSpec |
| SOLID principles | ⚠️ Partial | Adapted for Luau (no classes) |
| APIE (OOP) | ⚠️ Partial | Luau uses modules, not traditional OOP |
| Type safety | ✅ Yes | Luau gradual typing |

---

## Toolchain Setup

### Recommended Tools

```bash
# Install Rokit (toolchain manager, successor to Aftman)
# Or use Aftman
```

**rokit.toml** (or aftman.toml):
```toml
[tools]
rojo = "rojo-rbx/rojo@7.7.0"
selene = "Kampfkarren/selene@0.28.0"
stylua = "JohnnyMorganz/StyLua@2.0.0"
wally = "UpliftGames/wally@0.3.2"
```

### Configuration Files

**selene.toml** — Linter config:
```toml
std = "roblox"

[config]
empty_if = "warn"
shadowing = "warn"

[rules]
global_usage = "deny"
if_same_then_else = "warn"
manual_table_clone = "warn"
```

**stylua.toml** — Formatter config:
```toml
column_width = 100
line_endings = "Unix"
indent_type = "Tabs"
indent_width = 4
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
sort_requires = true
```

**.luaurc** — Type checker config:
```json
{
    "languageMode": "strict",
    "lint": {
        "*": true
    }
}
```

---

## Git Workflow

### Branch Strategy

```
main
├── feature/water-system
├── feature/npc-spawning
├── fix/terrain-clipping
└── chore/update-deps
```

**Branch naming**:
- `feature/` — new functionality
- `fix/` — bug fixes
- `chore/` — tooling, deps, cleanup
- `refactor/` — code restructure (no behavior change)

### Commit Messages

```
feat: add swimming state machine
fix: prevent NPC spawning in water
chore: update Rojo to 7.7.0
refactor: extract ElevationService from TerrainGenerator
docs: add TERRAIN_WATER.md
test: add tests for PlacementService
```

Use [Conventional Commits](https://www.conventionalcommits.org/) format.

### Pull Request Checklist

- [ ] Selene passes (no lint errors)
- [ ] StyLua formatted
- [ ] Type annotations added
- [ ] Tests pass (if applicable)
- [ ] No secrets committed
- [ ] Documentation updated

---

## Pre-commit Hooks

### Setup with pre-commit

**.pre-commit-config.yaml**:
```yaml
repos:
  - repo: https://github.com/JohnnyMorganz/StyLua
    rev: v2.0.0
    hooks:
      - id: stylua-github

  - repo: local
    hooks:
      - id: selene
        name: selene
        entry: selene
        language: system
        files: \.luau?$
        args: ["--config", "selene.toml"]
```

### Manual Git Hooks

**.git/hooks/pre-commit**:
```bash
#!/bin/bash
set -e

echo "Running StyLua..."
stylua --check src/

echo "Running Selene..."
selene src/

echo "Pre-commit checks passed!"
```

Make executable: `chmod +x .git/hooks/pre-commit`

---

## GitHub Actions

### Lint & Format Check

**.github/workflows/lint.yml**:
```yaml
name: Lint

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Rokit
        run: |
          curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/install.sh | bash
          echo "$HOME/.rokit/bin" >> $GITHUB_PATH

      - name: Install tools
        run: rokit install

      - name: Check formatting
        run: stylua --check src/

      - name: Lint
        run: selene src/
```

### Build & Test

**.github/workflows/test.yml**:
```yaml
name: Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Rokit
        run: |
          curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/install.sh | bash
          echo "$HOME/.rokit/bin" >> $GITHUB_PATH

      - name: Install tools
        run: rokit install

      - name: Install dependencies
        run: wally install

      - name: Build
        run: rojo build -o build.rbxl

      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: build
          path: build.rbxl
```

### Deploy to Roblox (Advanced)

Uses Open Cloud API for automated deployment:

**.github/workflows/deploy.yml**:
```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    concurrency:
      group: roblox-deploy
      cancel-in-progress: false

    steps:
      - uses: actions/checkout@v4

      - name: Install tools
        run: |
          # Install Rojo, etc.

      - name: Build place
        run: rojo build -o place.rbxl

      - name: Upload to Roblox
        env:
          ROBLOX_API_KEY: ${{ secrets.ROBLOX_API_KEY }}
        run: |
          # Use Open Cloud API to upload place
          # See: https://github.com/Roblox/place-ci-cd-demo
```

---

## Testing

### TestEZ (BDD-style)

```lua
-- tests/ElevationService.spec.luau
return function()
    local ElevationService = require(game.ReplicatedStorage.Shared.ElevationService)

    describe("ElevationService", function()
        describe("getGroundY", function()
            it("should return a number", function()
                local y = ElevationService.getGroundY(0, 0)
                expect(y).to.be.a("number")
            end)

            it("should return valid Y for known terrain", function()
                -- Assuming terrain exists at origin
                local y = ElevationService.getGroundY(0, 0)
                expect(y).to.be.near(0, 50)  -- within 50 studs of 0
            end)
        end)

        describe("canPlaceAt", function()
            it("should reject water positions", function()
                -- Mock or use known water position
                local canPlace = ElevationService.canPlaceAt(100, 100, {
                    allowWater = false
                })
                -- Assert based on your terrain
            end)
        end)
    end)
end
```

### Running Tests

With TestEZ installed via Wally:

```lua
-- ServerScriptService/RunTests.server.luau
local TestEZ = require(game.ReplicatedStorage.Packages.TestEZ)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Find all .spec files
local testModules = {}
for _, module in ReplicatedStorage.Tests:GetDescendants() do
    if module:IsA("ModuleScript") and module.Name:match("%.spec$") then
        table.insert(testModules, module)
    end
end

TestEZ.TestBootstrap:run(testModules)
```

### Test Structure

```
src/
  shared/
    ElevationService.luau
    PlacementService.luau
tests/
  ElevationService.spec.luau
  PlacementService.spec.luau
  __run__.server.luau
```

---

## Code Architecture

### SOLID for Luau (Adapted)

Since Luau uses modules (not classes), SOLID principles adapt:

**S - Single Responsibility**
```lua
-- GOOD: Each module does one thing
-- ElevationService.luau — ground detection only
-- PlacementService.luau — placing models only
-- NPCSpawner.luau — spawning NPCs only

-- BAD: One module does everything
-- Utils.luau — 2000 lines of random functions
```

**O - Open/Closed**
```lua
-- GOOD: Extend via configuration, not modification
local AnimalBehaviors = {
    idle = require(script.Behaviors.Idle),
    wander = require(script.Behaviors.Wander),
    flee = require(script.Behaviors.Flee),
}

-- Add new behavior without modifying existing code
AnimalBehaviors.hunt = require(script.Behaviors.Hunt)
```

**L - Liskov Substitution**
```lua
-- Modules with same interface can be swapped
local WaterDetector = require(script.WaterDetector)
-- or
local WaterDetector = require(script.MockWaterDetector)  -- for testing
```

**I - Interface Segregation**
```lua
-- GOOD: Small, focused interfaces
local Damageable = { takeDamage = function(self, amount) end }
local Moveable = { move = function(self, direction) end }

-- BAD: One giant interface
local Entity = { takeDamage, heal, move, attack, die, spawn, ... }
```

**D - Dependency Injection**
```lua
-- GOOD: Pass dependencies in
local function createNPCController(elevationService, placementService)
    return {
        spawn = function(x, z)
            local y = elevationService.getGroundY(x, z)
            return placementService.placeOnGround(...)
        end
    }
end

-- BAD: Hardcoded requires inside
local function createNPCController()
    local elevationService = require(somewhere.ElevationService)  -- hard to test
end
```

### Module Pattern

```lua
-- src/shared/MyService.luau
local MyService = {}

-- Private (by convention, prefix with _)
local function _privateHelper()
end

-- Public API
function MyService.publicMethod()
    _privateHelper()
end

-- Types
export type Config = {
    setting1: string,
    setting2: number,
}

return MyService
```

### Type Annotations

```lua
-- Full type annotations for public APIs
local ElevationService = {}

export type GroundInfo = {
    position: Vector3,
    normal: Vector3,
    material: Enum.Material,
    isValid: boolean,
}

function ElevationService.getGroundInfo(x: number, z: number): GroundInfo
    -- implementation
end

return ElevationService
```

---

## Project Structure

```
example-ecology/
├── .github/
│   └── workflows/
│       ├── lint.yml
│       └── test.yml
├── src/
│   ├── client/
│   ├── server/
│   └── shared/
├── tests/
│   └── *.spec.luau
├── Packages/              # Wally dependencies (gitignored)
├── default.project.json
├── wally.toml
├── selene.toml
├── stylua.toml
├── .luaurc
├── rokit.toml             # or aftman.toml
├── .gitignore
└── README.md
```

### wally.toml

```toml
[package]
name = "splash-screen-studio/example-ecology"
version = "0.1.0"
realm = "shared"

[dependencies]
TestEZ = "roblox/testez@0.4.1"

[dev-dependencies]
```

---

## File Organization Tips

1. **One module = one file** — don't cram multiple modules together
2. **Flat > nested** — avoid deep folder hierarchies
3. **Group by feature** — not by type (Controllers/, Services/, Utils/)
4. **Tests mirror src/** — `src/shared/Foo.luau` → `tests/Foo.spec.luau`
5. **Index files for folders** — `init.luau` exports folder's public API

---

## Sources

- [Rojo GitHub](https://github.com/rojo-rbx/rojo)
- [Place CI/CD Demo (Official)](https://github.com/Roblox/place-ci-cd-demo)
- [Selene Linter](https://kampfkarren.github.io/selene/)
- [StyLua Formatter](https://github.com/JohnnyMorganz/StyLua)
- [StyLua GitHub Action](https://github.com/JohnnyMorganz/stylua-action)
- [TestEZ Testing Framework](https://github.com/Roblox/testez)
- [EzSpec Testing](https://github.com/Synthetic-Dev/EzSpec)
- [Roblox Lua Style Guide](https://roblox.github.io/lua-style-guide/)
- [Kampfkarren's Luau Guidelines](https://github.com/Kampfkarren/kampfkarren-luau-guidelines)
- [SOLID in Lua Discussion](https://devforum.roblox.com/t/its-possible-to-use-solid-principles-in-lua/1475612)
- [CI/CD with Rojo + Wally + TestEZ](https://devforum.roblox.com/t/cicd-setup-with-rojo-wally-testez/3610450)
