# Mobile-First UI & HUD Design

Research on touch-friendly, responsive UI for Example Ecology (2025).

## Design Principles

### Mobile-First Philosophy

1. **Design for smallest screen first** — then scale up for tablet/desktop
2. **Thumb-reachable zones** — critical actions within easy reach
3. **Minimal, collapsible UI** — show only what's needed
4. **Large touch targets** — minimum 44x44 pixels (11x11 studs scaled)
5. **Avoid screen edges** — notches, camera cutouts, system UI

### Roblox Cross-Platform Reality

- **50%+ of Roblox players are on mobile**
- Phone screens: ~375x667 to ~428x926 logical pixels
- Tablets: ~768x1024 to ~1024x1366
- Desktop: ~1280x720 to ~2560x1440+

---

## Safe Areas & Notch Handling

### ScreenInsets Property

```lua
local screenGui = Instance.new("ScreenGui")
screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets  -- DEFAULT: respects notch + top bar
-- OR
screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets  -- respects notch only
-- OR
screenGui.ScreenInsets = Enum.ScreenInsets.None  -- DANGER: use only for backgrounds
```

**Recommendation**: Use `CoreUISafeInsets` for all interactive UI.

### TopbarInset API

Get the safe area within the Roblox top bar:

```lua
local GuiService = game:GetService("GuiService")
local topbarInset = GuiService.TopbarInset  -- Rect

-- Position UI below top bar
local frame = Instance.new("Frame")
frame.Position = UDim2.new(0, topbarInset.Min.X, 0, topbarInset.Max.Y)
```

### ClipToDeviceSafeArea

```lua
screenGui.ClipToDeviceSafeArea = true  -- clips UI to safe area
```

---

## Responsive Sizing

### Golden Rule: Scale > Offset

```lua
-- BAD: Fixed pixels (breaks on different screens)
frame.Size = UDim2.new(0, 200, 0, 50)

-- GOOD: Percentage-based (adapts to screen)
frame.Size = UDim2.new(0.25, 0, 0.08, 0)

-- BETTER: Hybrid (min size + scaling)
frame.Size = UDim2.new(0.2, 20, 0.05, 10)
```

### UIAspectRatioConstraint

Lock aspect ratio for consistent appearance:

```lua
local aspect = Instance.new("UIAspectRatioConstraint")
aspect.AspectRatio = 16/9  -- or 1 for square
aspect.AspectType = Enum.AspectType.FitWithinMaxSize
aspect.Parent = frame
```

### UISizeConstraint

Set min/max bounds:

```lua
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(100, 50)
sizeConstraint.MaxSize = Vector2.new(400, 200)
sizeConstraint.Parent = frame
```

### AutoScale Lite Plugin

Recommended plugin for converting Offset to Scale values easily.

---

## HUD Layout for Ecology Game

### Screen Zones (Mobile Portrait)

```
┌─────────────────────────┐
│     [NOTCH/CAMERA]      │ ← Safe area starts below
├─────────────────────────┤
│  ┌───┐           ┌───┐  │
│  │MAP│           │ ☰ │  │ ← Top corners: minimap, menu
│  └───┘           └───┘  │
│                         │
│                         │
│     [ GAME VIEW ]       │ ← Keep center clear!
│                         │
│                         │
│  ┌─────────────────┐    │
│  │ HP ████████░░░░ │    │ ← Bottom left: status bars
│  │ 🍖 ██████░░░░░░ │    │
│  │ 💧 ████████████ │    │
│  └─────────────────┘    │
│              ┌─────┐    │
│              │JUMP │    │ ← Bottom right: action buttons
│              └─────┘    │
└─────────────────────────┘
```

### Screen Zones (Mobile Landscape)

```
┌─────────────────────────────────────────┐
│                                         │
│ ┌───┐                           ┌───┐   │
│ │MAP│     [ GAME VIEW ]         │ ☰ │   │
│ └───┘                           └───┘   │
│ HP ████░░                               │
│ 🍖 ██░░░░               [JOYSTICK][JUMP]│
│ 💧 █████░                               │
└─────────────────────────────────────────┘
```

---

## Status Meters

### Health/Hunger/Thirst Bars

```lua
-- src/client/UI/StatusBars.luau
local StatusBars = {}

local TweenService = game:GetService("TweenService")

local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function StatusBars.create(parent: Frame)
    local container = Instance.new("Frame")
    container.Name = "StatusContainer"
    container.Size = UDim2.new(0.3, 0, 0.15, 0)
    container.Position = UDim2.new(0.02, 0, 0.8, 0)
    container.BackgroundTransparency = 1
    container.Parent = parent

    -- Add layout
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0.02, 0)
    layout.Parent = container

    -- Create bars
    local bars = {
        health = StatusBars.createBar(container, "Health", Color3.fromRGB(255, 80, 80), 1),
        hunger = StatusBars.createBar(container, "Hunger", Color3.fromRGB(200, 150, 50), 2),
        thirst = StatusBars.createBar(container, "Thirst", Color3.fromRGB(80, 150, 255), 3),
    }

    return bars
end

function StatusBars.createBar(parent: Frame, name: string, color: Color3, order: number)
    local bar = Instance.new("Frame")
    bar.Name = name
    bar.Size = UDim2.new(1, 0, 0.25, 0)
    bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bar.BorderSizePixel = 0
    bar.LayoutOrder = order
    bar.Parent = parent

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.3, 0)
    corner.Parent = bar

    -- Fill bar
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = bar

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0.3, 0)
    fillCorner.Parent = fill

    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0.15, 0, 0.8, 0)
    icon.Position = UDim2.new(0.02, 0, 0.1, 0)
    icon.BackgroundTransparency = 1
    icon.Parent = bar

    return {
        frame = bar,
        fill = fill,
        setValue = function(value: number)
            local clamped = math.clamp(value, 0, 1)
            TweenService:Create(fill, TWEEN_INFO, {
                Size = UDim2.new(clamped, 0, 1, 0)
            }):Play()
        end
    }
end

return StatusBars
```

### Coordinates Display (Debug/Optional)

```lua
-- src/client/UI/CoordinatesDisplay.luau
local CoordinatesDisplay = {}

local RunService = game:GetService("RunService")

function CoordinatesDisplay.create(parent: Frame)
    local label = Instance.new("TextLabel")
    label.Name = "Coordinates"
    label.Size = UDim2.new(0.2, 0, 0.05, 0)
    label.Position = UDim2.new(0.4, 0, 0.02, 0)  -- top center
    label.BackgroundTransparency = 0.5
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.RobotoMono
    label.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.2, 0)
    corner.Parent = label

    -- Update loop
    local character = game.Players.LocalPlayer.Character
    RunService.Heartbeat:Connect(function()
        if character and character.PrimaryPart then
            local pos = character.PrimaryPart.Position
            label.Text = string.format("X:%d Y:%d Z:%d",
                math.round(pos.X),
                math.round(pos.Y),
                math.round(pos.Z)
            )
        end
    end)

    return label
end

return CoordinatesDisplay
```

---

## Minimap

### Simple Radar-Style Minimap

```lua
-- src/client/UI/Minimap.luau
local Minimap = {}

local RunService = game:GetService("RunService")

local MAP_SCALE = 0.5  -- studs to pixels ratio

function Minimap.create(parent: Frame, mapSize: number)
    local container = Instance.new("Frame")
    container.Name = "MinimapContainer"
    container.Size = UDim2.new(0, mapSize, 0, mapSize)
    container.Position = UDim2.new(0.02, 0, 0.02, 0)  -- top left
    container.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = parent

    -- Circular mask
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.5, 0)  -- full circle
    corner.Parent = container

    -- Border
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(100, 120, 100)
    stroke.Parent = container

    -- Player indicator (center)
    local playerDot = Instance.new("Frame")
    playerDot.Name = "PlayerDot"
    playerDot.Size = UDim2.new(0, 8, 0, 8)
    playerDot.Position = UDim2.new(0.5, -4, 0.5, -4)
    playerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
    playerDot.BorderSizePixel = 0
    playerDot.ZIndex = 10
    playerDot.Parent = container

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(0.5, 0)
    dotCorner.Parent = playerDot

    -- Direction indicator
    local directionArrow = Instance.new("ImageLabel")
    directionArrow.Name = "Direction"
    directionArrow.Size = UDim2.new(0, 12, 0, 12)
    directionArrow.Position = UDim2.new(0.5, -6, 0.5, -12)
    directionArrow.BackgroundTransparency = 1
    directionArrow.Image = "rbxassetid://YOUR_ARROW_ASSET"  -- upload arrow image
    directionArrow.ZIndex = 10
    directionArrow.Parent = container

    return {
        container = container,
        playerDot = playerDot,
        markers = {},

        addMarker = function(self, worldPos: Vector3, color: Color3, name: string)
            local marker = Instance.new("Frame")
            marker.Name = name
            marker.Size = UDim2.new(0, 6, 0, 6)
            marker.BackgroundColor3 = color
            marker.BorderSizePixel = 0
            marker.Parent = container

            local markerCorner = Instance.new("UICorner")
            markerCorner.CornerRadius = UDim.new(0.5, 0)
            markerCorner.Parent = marker

            self.markers[name] = {frame = marker, worldPos = worldPos}
        end,

        update = function(self, playerPos: Vector3, playerLookDir: Vector3)
            -- Rotate direction arrow
            local angle = math.atan2(playerLookDir.X, playerLookDir.Z)
            directionArrow.Rotation = math.deg(angle)

            -- Update marker positions relative to player
            for _, markerData in self.markers do
                local relativePos = markerData.worldPos - playerPos
                local screenX = relativePos.X * MAP_SCALE
                local screenZ = relativePos.Z * MAP_SCALE

                -- Rotate to match player facing
                local rotatedX = screenX * math.cos(-angle) - screenZ * math.sin(-angle)
                local rotatedZ = screenX * math.sin(-angle) + screenZ * math.cos(-angle)

                markerData.frame.Position = UDim2.new(
                    0.5, rotatedX - 3,
                    0.5, rotatedZ - 3
                )

                -- Hide if too far
                local dist = math.sqrt(screenX^2 + screenZ^2)
                markerData.frame.Visible = dist < mapSize / 2
            end
        end
    }
end

return Minimap
```

---

## Touch-Friendly Buttons

### Mobile Button Guidelines

- **Minimum size**: 44x44 points (iOS), 48x48 dp (Android)
- **Spacing**: At least 8px between buttons
- **Feedback**: Visual press state, haptic if possible
- **Position**: Bottom third of screen for thumb reach

### Button Component

```lua
-- src/client/UI/TouchButton.luau
local TouchButton = {}

local TweenService = game:GetService("TweenService")
local HapticService = game:GetService("HapticService")
local UserInputService = game:GetService("UserInputService")

local PRESS_TWEEN = TweenInfo.new(0.1, Enum.EasingStyle.Quad)

function TouchButton.create(config: {
    parent: Frame,
    size: UDim2,
    position: UDim2,
    text: string?,
    icon: string?,
    color: Color3?,
    onActivated: () -> ()
})
    local button = Instance.new("TextButton")
    button.Name = config.text or "Button"
    button.Size = config.size
    button.Position = config.position
    button.BackgroundColor3 = config.color or Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.Text = config.text or ""
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.Font = Enum.Font.GothamBold
    button.AutoButtonColor = false  -- custom handling
    button.Parent = config.parent

    -- Rounded corners
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.15, 0)
    corner.Parent = button

    -- Icon (if provided)
    if config.icon then
        local icon = Instance.new("ImageLabel")
        icon.Size = UDim2.new(0.6, 0, 0.6, 0)
        icon.Position = UDim2.new(0.2, 0, 0.2, 0)
        icon.BackgroundTransparency = 1
        icon.Image = config.icon
        icon.Parent = button
        button.Text = ""
    end

    -- Press feedback
    local originalColor = button.BackgroundColor3
    local pressedColor = originalColor:Lerp(Color3.new(1, 1, 1), 0.3)

    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, PRESS_TWEEN, {
            BackgroundColor3 = pressedColor,
            Size = config.size - UDim2.new(0.02, 0, 0.02, 0)
        }):Play()

        -- Haptic feedback on mobile
        if UserInputService.TouchEnabled then
            pcall(function()
                HapticService:SetMotor(
                    Enum.UserInputType.Gamepad1,
                    Enum.VibrationMotor.Small,
                    0.5
                )
            end)
        end
    end)

    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, PRESS_TWEEN, {
            BackgroundColor3 = originalColor,
            Size = config.size
        }):Play()
    end)

    button.Activated:Connect(config.onActivated)

    return button
end

return TouchButton
```

---

## Collapsible Menu

Keep HUD minimal, expand on demand:

```lua
-- src/client/UI/CollapsibleMenu.luau
local CollapsibleMenu = {}

local TweenService = game:GetService("TweenService")

local EXPAND_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local COLLAPSE_TWEEN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

function CollapsibleMenu.create(parent: Frame)
    local isExpanded = false

    -- Menu button (always visible)
    local menuButton = Instance.new("TextButton")
    menuButton.Name = "MenuButton"
    menuButton.Size = UDim2.new(0, 44, 0, 44)
    menuButton.Position = UDim2.new(1, -54, 0, 10)
    menuButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    menuButton.Text = "☰"
    menuButton.TextColor3 = Color3.new(1, 1, 1)
    menuButton.TextScaled = true
    menuButton.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.2, 0)
    corner.Parent = menuButton

    -- Expandable panel
    local panel = Instance.new("Frame")
    panel.Name = "MenuPanel"
    panel.Size = UDim2.new(0, 0, 0, 200)  -- starts collapsed
    panel.Position = UDim2.new(1, -10, 0, 60)
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    panel.BackgroundTransparency = 0.2
    panel.ClipsDescendants = true
    panel.Parent = parent

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 10)
    panelCorner.Parent = panel

    -- Menu items container
    local itemsContainer = Instance.new("Frame")
    itemsContainer.Size = UDim2.new(1, -20, 1, -20)
    itemsContainer.Position = UDim2.new(0, 10, 0, 10)
    itemsContainer.BackgroundTransparency = 1
    itemsContainer.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = itemsContainer

    -- Toggle function
    local function toggle()
        isExpanded = not isExpanded

        if isExpanded then
            TweenService:Create(panel, EXPAND_TWEEN, {
                Size = UDim2.new(0, 180, 0, 200)
            }):Play()
            menuButton.Text = "✕"
        else
            TweenService:Create(panel, COLLAPSE_TWEEN, {
                Size = UDim2.new(0, 0, 0, 200)
            }):Play()
            menuButton.Text = "☰"
        end
    end

    menuButton.Activated:Connect(toggle)

    return {
        panel = panel,
        itemsContainer = itemsContainer,
        toggle = toggle,
        addItem = function(text: string, callback: () -> ())
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 36)
            item.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            item.Text = text
            item.TextColor3 = Color3.new(1, 1, 1)
            item.TextScaled = true
            item.Parent = itemsContainer

            local itemCorner = Instance.new("UICorner")
            itemCorner.CornerRadius = UDim.new(0.15, 0)
            itemCorner.Parent = item

            item.Activated:Connect(callback)
        end
    }
end

return CollapsibleMenu
```

---

## Performance Tips

1. **Update HUD max 30fps** — don't update every Heartbeat
2. **Object pooling** — reuse damage numbers, markers
3. **Visibility culling** — hide off-screen elements
4. **Batch text updates** — change multiple labels at once
5. **Avoid Layout recalculation** — use manual positioning when possible

```lua
-- Throttled update example
local UPDATE_RATE = 1/30  -- 30 fps
local lastUpdate = 0

RunService.Heartbeat:Connect(function(dt)
    lastUpdate += dt
    if lastUpdate >= UPDATE_RATE then
        lastUpdate = 0
        updateHUD()  -- your update function
    end
end)
```

---

## File Structure

```
src/
  client/
    UI/
      HUDController.luau      -- orchestrates all UI
      StatusBars.luau         -- health, hunger, thirst
      Minimap.luau            -- radar-style map
      CoordinatesDisplay.luau -- XYZ debug display
      CollapsibleMenu.luau    -- expandable menu
      TouchButton.luau        -- mobile-friendly buttons
      init.client.luau        -- setup script
  shared/
    UIConfig.luau             -- colors, sizes, constants
```

---

## Device Detection

```lua
local UserInputService = game:GetService("UserInputService")

local function getDeviceType()
    if UserInputService.TouchEnabled then
        if UserInputService.KeyboardEnabled then
            return "Tablet"  -- touch + keyboard = tablet or laptop
        else
            return "Phone"
        end
    else
        return "Desktop"
    end
end

-- Adjust UI based on device
local device = getDeviceType()
if device == "Phone" then
    -- Larger buttons, simpler HUD
elseif device == "Tablet" then
    -- Medium UI
else
    -- Full desktop UI
end
```

---

## Sources

- [Roblox UI Documentation](https://create.roblox.com/docs/ui)
- [UI/UX Design Guide](https://create.roblox.com/docs/production/game-design/ui-ux-design)
- [HUD Meters Tutorial](https://github.com/Roblox/creator-docs/blob/main/content/en-us/tutorials/use-case-tutorials/ui/create-hud-meters.md)
- [Designing UI - Tips and Best Practices](https://devforum.roblox.com/t/designing-ui-tips-and-best-practices/3074034)
- [Mobile Buttons Tutorial](https://devforum.roblox.com/t/the-correct-way-to-design-mobile-buttons/2494558)
- [Notched Screen Support](https://devforum.roblox.com/t/notched-screen-support-full-release/2074324)
- [PreferredInput API (June 2025)](https://devforum.roblox.com/t/full-release-introducing-preferredinput-and-improved-touch-capabilities/3750890)
- [Minimap System Documentation](https://create.roblox.com/docs/resources/battle-royale/minimap-system)
- [Radar System Tutorial](https://devforum.roblox.com/t/radar-system-on-screengui/2728090)
- [Hunger System Tutorial](https://devforum.roblox.com/t/how-to-create-a-rpg-hunger-system/476723)
- [Roblox Minimap System (Oct 2025)](https://itch.io/devlog/1084851/roblox-minimap-system-real-time-navigation-ui.amp)
