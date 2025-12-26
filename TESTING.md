# Testing Guide

Comprehensive testing strategy for the Verdant Basin / Driftplain ecology simulation.

## Quick Start

### Running Tests in Studio

1. Open Roblox Studio with the project synced via Rojo
2. Open the **Command Bar** (View > Command Bar)
3. Run:
```lua
require(game.ReplicatedStorage.Tests)()
```

Tests run immediately and output results to the Output window.

### Test Output

```
=====================================
Tests: 42 passed, 0 failed, 0 skipped
=====================================
```

---

## Test Structure

```
tests/
├── init.luau                          # Test runner entry point
├── server/
│   ├── NPCDefinitions.spec.luau       # NPC data validation
│   ├── SpeciesData.spec.luau          # Ecology species validation
│   ├── StatDrainService.spec.luau     # Hunger/thirst drain behavior
│   ├── WaterController.spec.luau      # Water state detection
│   └── DialogueService.spec.luau      # Conversation flow
└── shared/
    ├── ItemDefinitions.spec.luau      # Item data validation
    └── AudioConfig.spec.luau          # Sound asset validation
```

---

## Test Categories

### 1. Data Validation Tests

Verify that definition files have correct structure and values.

| Test File | What It Validates |
|-----------|-------------------|
| `ItemDefinitions.spec` | Item properties, categories, effects |
| `NPCDefinitions.spec` | NPC stats, species linkage |
| `SpeciesData.spec` | Food web, population constraints |
| `AudioConfig.spec` | Sound asset IDs, volume ranges |

### 2. Behavior Tests

Verify service behavior and configuration.

| Test File | What It Validates |
|-----------|-------------------|
| `StatDrainService.spec` | Drain rates, config API |
| `WaterController.spec` | Module exports, state structure |
| `DialogueService.spec` | Conversation API, state management |

### 3. Regression Tests

Tests specifically added after bug fixes to prevent recurrence.

| Bug | Test Location | What We Check |
|-----|---------------|---------------|
| WaterController not loaded in StatDrainService | `StatDrainService.spec` | Config structure exists |
| Conversations stuck without timeout | `DialogueService.spec` | Module exports correctly |
| Placeholder sound IDs (rbxassetid://0) | `AudioConfig.spec` | Sound ID validation |
| StatsBar nil transparency | Fixed in code | N/A (type error) |

---

## Writing Tests

### Test File Pattern

```lua
--!strict
--[[
    ModuleName Tests

    Brief description of what this tests.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
    describe("ModuleName", function()
        local Module

        beforeAll(function()
            Module = require(ReplicatedStorage.Path.To.Module)
        end)

        describe("function_name", function()
            it("should do expected behavior", function()
                local result = Module.function_name()
                expect(result).to.equal(expected)
            end)

            it("should handle edge case", function()
                expect(function()
                    Module.function_name(nil)
                end).to.throw()
            end)
        end)
    end)
end
```

### TestEZ Assertions

```lua
expect(value).to.be.ok()              -- truthy
expect(value).to.equal(other)         -- strict equality
expect(value).to.be.a("string")       -- type check
expect(value).never.to.equal(other)   -- negation
expect(fn).to.throw()                 -- error thrown
```

### Testing Services

Server services are in `ServerScriptService.Server.*`:

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local MyService = require(ServerScriptService.Server.Category.MyService)
```

Shared modules are in `ReplicatedStorage.Shared.*`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MyModule = require(ReplicatedStorage.Shared.MyModule)
```

---

## CI/CD Integration (Future)

### GitHub Actions Setup

For automated testing on push/PR, add `.github/workflows/test.yml`:

```yaml
name: Run Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: Roblox/setup-foreman@v1
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      - run: rojo build -o test.rbxl
      - uses: rojo-rbx/run-in-roblox@v4
        with:
          place: test.rbxl
          script: |
            local passed = require(game.ReplicatedStorage.Tests)()
            if not passed then
              error("Tests failed!")
            end
```

### Requirements for CI

1. Install Foreman tools: `foreman install`
2. Ensure all tests pass locally first
3. Tests must not require player interaction

---

## Test Coverage Goals

### Critical Paths (Must Test)

- [ ] Player data save/load
- [ ] Inventory add/remove
- [ ] Stat drain calculations
- [ ] Water state detection
- [ ] Dialogue state machine
- [ ] Sound asset validity

### Nice to Have

- [ ] UI component rendering
- [ ] Network event flow
- [ ] NPC spawning
- [ ] Quest progression

---

## Debugging Failed Tests

### Common Issues

1. **Module not found**: Check the require path matches Rojo structure
2. **Nil errors**: Service may not be initialized - use `pcall` wrapper
3. **Timing issues**: Use `task.wait()` sparingly, prefer state checks

### Viewing Test Output

1. Open Output window in Studio (View > Output)
2. Filter to "Server" for server-side test logs
3. Look for `[FAIL]` markers in red

### Running Single Test File

Modify `tests/init.luau` temporarily:

```lua
local testRoots = {
    script.server.StatDrainService, -- Run just this spec
}
```

---

## Adding Tests After Bug Fixes

When you fix a bug:

1. **Identify the failure mode**: What condition caused the bug?
2. **Write a test that would have caught it**:
   - Test the configuration/API that was misconfigured
   - Test the code path that failed
3. **Verify the test passes** after your fix
4. **Add to this document** in the Regression Tests section

### Example: WaterController Loading Bug

Bug: `isPlayerInWater()` didn't call `loadDependencies()` before checking WaterController.

Test added to `StatDrainService.spec.luau`:
```lua
it("should have getConfig function", function()
    expect(StatDrainService.getConfig).to.be.a("function")
end)

it("should have hunger and thirst configs", function()
    local config = StatDrainService:getConfig()
    expect(config.hunger).to.be.ok()
    expect(config.thirst).to.be.ok()
end)
```

This ensures the module loads correctly and has the expected structure.

---

## Sound Asset Validation

The `AudioConfig.spec.luau` file includes special "PLACEHOLDER_CHECK" tests that warn about `rbxassetid://0` placeholder sounds.

### Current State

All sounds currently use placeholder IDs. When real sounds are added:

1. Replace `rbxassetid://0` with actual asset IDs
2. Uncomment the `expect(hasPlaceholders).to.equal(false)` lines
3. Tests will then fail if any placeholders remain

### Finding Sound Assets

Use the Roblox Toolbox or upload custom sounds:
1. Toolbox > Audio > Search for sounds
2. Get the asset ID from the URL
3. Format: `rbxassetid://1234567890`
