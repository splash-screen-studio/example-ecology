# Audio & Sound Design

Research on immersive audio systems for Verdant Basin (2025).

## Overview

Audio is one of the most overlooked yet impactful elements in Roblox game development. A silent game feels empty and lifeless, even with stunning visuals. Sound creates:
- **Atmosphere** — Environmental presence and mood
- **Immersion** — Believable, reactive worlds
- **Feedback** — Player actions feel meaningful
- **Direction** — Spatial cues guide exploration

---

## Audio Architecture

### Legacy Sound System

The traditional `Sound` object, still widely used:

```lua
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://123456789"
sound.Volume = 0.5
sound.Parent = workspace.MyPart  -- 3D positioned
sound:Play()
```

**Key Properties**:
- `RollOffMode` — How sound fades with distance
- `RollOffMinDistance` / `RollOffMaxDistance` — Audibility range
- `Looped` — For ambient/music
- `PlaybackSpeed` — Pitch adjustment

### New Audio API (2024+)

The modern audio system with wiring-based routing:

```lua
-- Audio source
local player = Instance.new("AudioPlayer")
player.AssetId = "rbxassetid://123456789"
player.Parent = workspace

-- 3D emitter
local emitter = Instance.new("AudioEmitter")
emitter.Parent = workspace.MyPart

-- Wire them together
local wire = Instance.new("Wire")
wire.SourceInstance = player
wire.TargetInstance = emitter
wire.Parent = player

-- Listen from camera
local listener = Instance.new("AudioListener")
listener.Parent = workspace.CurrentCamera

-- Output to device
local output = Instance.new("AudioDeviceOutput")
output.Parent = workspace

player:Play()
```

**Key Components**:
- `AudioPlayer` — Loads and plays audio files
- `AudioEmitter` — Virtual speaker in 3D space
- `AudioListener` — Virtual microphone (usually on camera)
- `AudioDeviceOutput` — Routes to physical speakers
- `Wire` — Connects audio components

**Links**:
- [Audio API Deep Dive](https://devforum.roblox.com/t/robloxs-new-audio-api-a-somewhat-deep-dive/3156011)
- [Audio API Announcement](https://devforum.roblox.com/t/new-audio-api-beta-elevate-sound-and-voice-in-your-experiences/2848873)
- [Simple Audio API Guide](https://devforum.roblox.com/t/a-simple-guide-to-the-audio-api/3132049)

---

## Spatial Audio (3D Sound)

### Positioning Sounds in Space

Sounds parented to Parts are automatically spatialized:

```lua
-- Sound attached to a waterfall
local waterfallSound = Instance.new("Sound")
waterfallSound.SoundId = "rbxassetid://WATERFALL_SOUND"
waterfallSound.Looped = true
waterfallSound.RollOffMode = Enum.RollOffMode.InverseTapered
waterfallSound.RollOffMinDistance = 10
waterfallSound.RollOffMaxDistance = 100
waterfallSound.Volume = 0.8
waterfallSound.Parent = workspace.Waterfall
waterfallSound:Play()
```

### RollOff Modes

| Mode | Behavior |
|------|----------|
| `Inverse` | Quick falloff, realistic for small sources |
| `Linear` | Gradual linear fade |
| `InverseTapered` | Inverse near, linear far (recommended) |
| `LinearSquare` | Starts slow, drops fast at end |

### Directional Audio (December 2024)

`AngleAttenuation` makes sounds louder when facing them:

```lua
local emitter = Instance.new("AudioEmitter")
emitter.AngleAttenuationEnabled = true
emitter.AngleAttenuationAngle = 90  -- 90° cone
emitter.AngleAttenuationFalloff = 0.5
```

**Link**: [Directional Audio Announcement](https://devforum.roblox.com/t/new-audio-api-features-directional-audio-audiolimiter-and-more/3282100)

---

## Ambient Sound Systems

### Layered Ambient Design

The "Beyond the Dark" approach: combine 2D omnipresent soundbed with 3D spot ambiences.

```lua
-- src/client/Audio/AmbientController.luau
local AmbientController = {}

-- 2D base layer (always present)
local baseAmbient = Instance.new("Sound")
baseAmbient.SoundId = "rbxassetid://FOREST_BASE"
baseAmbient.Looped = true
baseAmbient.Volume = 0.3
baseAmbient.Parent = game.SoundService  -- Non-spatial

-- 3D spot ambiences (pull attention)
local spotAmbiences = {
    { position = Vector3.new(0, 5, 0), sound = "STREAM_BABBLE", radius = 30 },
    { position = Vector3.new(50, 10, -20), sound = "BIRD_CHORUS", radius = 50 },
    { position = Vector3.new(-30, 0, 40), sound = "INSECT_BUZZ", radius = 20 },
}

function AmbientController:init()
    baseAmbient:Play()

    for _, spot in spotAmbiences do
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Position = spot.position
        part.Parent = workspace.AmbientSources

        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. spot.sound
        sound.Looped = true
        sound.RollOffMaxDistance = spot.radius
        sound.Parent = part
        sound:Play()
    end
end

return AmbientController
```

### Biome-Specific Ambience

```lua
-- src/shared/AmbientConfig.luau
local AmbientConfig = {}

AmbientConfig.VerdantBasin = {
    baseLayer = "rbxassetid://LUSH_FOREST_BASE",
    layers = {
        { id = "WATER_GENTLE", volume = 0.4, condition = "nearWater" },
        { id = "WIND_LEAVES", volume = 0.3, condition = "always" },
        { id = "BIRD_CALLS", volume = 0.25, condition = "daytime" },
        { id = "FROG_CHORUS", volume = 0.35, condition = "nearWater,nighttime" },
        { id = "INSECT_NIGHT", volume = 0.2, condition = "nighttime" },
    },
}

AmbientConfig.Driftplain = {
    baseLayer = "rbxassetid://DRY_WIND_BASE",
    layers = {
        { id = "WIND_HOWL", volume = 0.5, condition = "always" },
        { id = "DISTANT_THUNDER", volume = 0.15, condition = "random,0.1" },
        { id = "GRASS_RUSTLE", volume = 0.3, condition = "playerMoving" },
        { id = "COYOTE_HOWL", volume = 0.2, condition = "nighttime,random,0.05" },
    },
}

return AmbientConfig
```

### Day/Night Transitions

```lua
local function updateAmbientForTime(hour)
    local isDaytime = hour >= 6 and hour < 20

    if isDaytime then
        tweenVolume(nightAmbient, 0, 3)
        tweenVolume(dayAmbient, 1, 3)
    else
        tweenVolume(dayAmbient, 0, 3)
        tweenVolume(nightAmbient, 1, 3)
    end
end
```

**Links**:
- [Creating Compelling Environmental Audio](https://devforum.roblox.com/t/ambientsorcery%E2%80%99s-tutorial-1-creating-compelling-environmental-audio/3507022)
- [Immersive Environments V2](https://devforum.roblox.com/t/immersive-environments-v2-advanced-package-based-audio-and-lighting-control/962709)
- [Beyond the Dark Sound Design](https://create.roblox.com/docs/resources/beyond-the-dark/sound-design)

---

## Music Systems

### Dynamic Soundtrack

Music that responds to gameplay state:

```lua
-- src/client/Audio/MusicController.luau
local MusicController = {}

local tracks = {
    exploration = { "rbxassetid://EXPLORE_1", "rbxassetid://EXPLORE_2" },
    discovery = { "rbxassetid://DISCOVERY_1" },
    tension = { "rbxassetid://TENSION_1" },
    peaceful = { "rbxassetid://PEACEFUL_1", "rbxassetid://PEACEFUL_2" },
}

local currentTrack = nil
local currentState = "exploration"

function MusicController:setState(state)
    if state == currentState then return end
    currentState = state

    -- Fade out current
    if currentTrack then
        local fadeOut = TweenService:Create(currentTrack, TweenInfo.new(2), { Volume = 0 })
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            currentTrack:Stop()
        end)
    end

    -- Fade in new
    local newTrackId = tracks[state][math.random(#tracks[state])]
    currentTrack = Instance.new("Sound")
    currentTrack.SoundId = newTrackId
    currentTrack.Volume = 0
    currentTrack.Looped = true
    currentTrack.Parent = game.SoundService
    currentTrack:Play()

    TweenService:Create(currentTrack, TweenInfo.new(2), { Volume = 0.4 }):Play()
end

function MusicController:onDiscovery()
    self:setState("discovery")
    task.delay(30, function()
        self:setState("exploration")
    end)
end

return MusicController
```

### Area-Based Music

```lua
local function updateMusicForArea(player)
    local position = player.Character.HumanoidRootPart.Position

    if isInArea(position, "LifeweaveStone") then
        MusicController:setState("mystical")
    elseif isInArea(position, "HeronNestingGrounds") then
        MusicController:setState("peaceful")
    elseif isInArea(position, "DriftplainEdge") then
        MusicController:setState("tension")
    else
        MusicController:setState("exploration")
    end
end
```

### Licensed Music

Roblox provides 100,000+ free sound effects and music tracks.

**Usage**:
- Up to 250 licensed tracks per game
- Browse via Creator Store
- Cannot be downloaded, platform-only

**Link**: [Using Licensed Music](https://en.help.roblox.com/hc/en-us/articles/360000927163-Using-Licensed-Music-on-Roblox)

---

## Reverb & Acoustic Simulation

### SoundService Ambient Reverb

Apply reverb presets globally:

```lua
local SoundService = game:GetService("SoundService")
SoundService.AmbientReverb = Enum.ReverbType.Forest  -- or Cave, Hangar, etc.
```

**Reverb Types**:
- `Forest` — Open, natural
- `Cave` — Echoing, enclosed
- `Hangar` — Large industrial space
- `Room` — Small interior
- `Underwater` — Muffled, submerged

### Dynamic Reverb (New Audio API)

Use `AudioReverb` for precise control:

```lua
local reverb = Instance.new("AudioReverb")
reverb.DecayTime = 2.5
reverb.Density = 0.8
reverb.Diffusion = 0.9
reverb.DryLevel = 0
reverb.WetLevel = -6
reverb.Parent = audioChain
```

### Raycasted Reverb Systems

Community systems that detect environment and apply appropriate reverb:

```lua
-- Simplified concept
local function calculateReverb(position)
    local hits = 0
    local totalDistance = 0

    for _, direction in RAYCAST_DIRECTIONS do
        local result = workspace:Raycast(position, direction * 50)
        if result then
            hits = hits + 1
            totalDistance = totalDistance + result.Distance
        end
    end

    if hits > 10 then
        -- Enclosed space
        return { type = "Room", intensity = 1 - (totalDistance / (hits * 50)) }
    else
        -- Open space
        return { type = "Forest", intensity = 0.3 }
    end
end
```

**Links**:
- [ReverbAPI](https://devforum.roblox.com/t/%F0%9F%8E%99%EF%B8%8F-introducing-reverbapi-super-immersive-audio-for-all/3622461)
- [Dynamic Audio Reverb System](https://devforum.roblox.com/t/dynamic-audio-reverb-environmental-acoustics-sampler-system/3168314)
- [Raycasted Audio System](https://devforum.roblox.com/t/raycasted-audio-system/3708073)

---

## Sound Effects (One-Shot)

### Categorized SFX Library

```lua
-- src/shared/SFXConfig.luau
local SFXConfig = {}

SFXConfig.Player = {
    footstep_grass = { "rbxassetid://FOOT_GRASS_1", "rbxassetid://FOOT_GRASS_2" },
    footstep_water = { "rbxassetid://FOOT_WATER_1", "rbxassetid://FOOT_WATER_2" },
    footstep_stone = { "rbxassetid://FOOT_STONE_1" },
    jump = { "rbxassetid://JUMP_1" },
    land = { "rbxassetid://LAND_1" },
}

SFXConfig.UI = {
    click = { "rbxassetid://UI_CLICK" },
    hover = { "rbxassetid://UI_HOVER" },
    open = { "rbxassetid://UI_OPEN" },
    close = { "rbxassetid://UI_CLOSE" },
    notification = { "rbxassetid://UI_NOTIFY" },
}

SFXConfig.World = {
    discovery = { "rbxassetid://DISCOVER_CHIME" },
    water_splash = { "rbxassetid://SPLASH_1", "rbxassetid://SPLASH_2" },
    bird_startled = { "rbxassetid://BIRD_STARTLE" },
    branch_snap = { "rbxassetid://BRANCH_SNAP" },
}

return SFXConfig
```

### SFX Player

```lua
-- src/client/Audio/SFXPlayer.luau
local SFXPlayer = {}

function SFXPlayer:play(category, name, options)
    options = options or {}
    local sounds = SFXConfig[category][name]
    if not sounds then return end

    local soundId = sounds[math.random(#sounds)]

    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = options.volume or 1
    sound.PlaybackSpeed = options.pitch or 1

    if options.position then
        -- 3D positioned
        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Position = options.position
        part.Parent = workspace.SFXSources
        sound.Parent = part

        sound.Ended:Connect(function()
            part:Destroy()
        end)
    else
        -- 2D (UI sounds)
        sound.Parent = game.SoundService
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end

    sound:Play()
    return sound
end

-- Usage
SFXPlayer:play("UI", "click")
SFXPlayer:play("World", "water_splash", { position = Vector3.new(10, 0, 5) })

return SFXPlayer
```

### Footstep System

```lua
local function getGroundMaterial(character)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return "grass" end

    local rayResult = workspace:Raycast(
        rootPart.Position,
        Vector3.new(0, -5, 0)
    )

    if rayResult then
        local material = rayResult.Material
        if material == Enum.Material.Water then
            return "water"
        elseif material == Enum.Material.Rock or material == Enum.Material.Slate then
            return "stone"
        else
            return "grass"
        end
    end

    return "grass"
end

local function onStep(character)
    local material = getGroundMaterial(character)
    SFXPlayer:play("Player", "footstep_" .. material, {
        position = character.HumanoidRootPart.Position,
        volume = 0.5,
        pitch = 0.9 + math.random() * 0.2,
    })
end
```

---

## Text-to-Speech (2025)

### Roblox TTS API

Generate voice from text without recording:

```lua
local TextToSpeechService = game:GetService("TextToSpeechService")

local function speakNPC(text, npcHead)
    local audioData = TextToSpeechService:Synthesize(text, {
        Voice = "en-US-Standard-D",  -- Male voice
    })

    local sound = Instance.new("Sound")
    sound.SoundId = audioData
    sound.Parent = npcHead
    sound:Play()

    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end
```

**Use Cases**:
- NPC dialogue without voice actors
- Dynamic narration
- Accessibility features

**Link**: [Text-to-Speech API](https://devforum.roblox.com/t/beta-text-to-speech-api-from-text-to-voice-content-instantly/3792085)

---

## Performance Optimization

### Sound Pooling

Reuse sound instances instead of creating/destroying:

```lua
local soundPool = {}

function getSoundFromPool()
    for _, sound in soundPool do
        if not sound.IsPlaying then
            return sound
        end
    end

    -- Create new if pool exhausted
    local newSound = Instance.new("Sound")
    newSound.Parent = game.SoundService
    table.insert(soundPool, newSound)
    return newSound
end
```

### Distance Culling

Don't play sounds player can't hear:

```lua
local function shouldPlaySound(position, maxDistance)
    local camera = workspace.CurrentCamera
    local distance = (position - camera.CFrame.Position).Magnitude
    return distance <= maxDistance * 1.5
end
```

### Audio Budget

Limit simultaneous sounds:

```lua
local MAX_SIMULTANEOUS_SOUNDS = 32
local activeSounds = {}

function playManagedSound(sound)
    if #activeSounds >= MAX_SIMULTANEOUS_SOUNDS then
        -- Stop oldest, lowest priority sound
        local oldest = table.remove(activeSounds, 1)
        oldest:Stop()
    end

    table.insert(activeSounds, sound)
    sound:Play()

    sound.Ended:Connect(function()
        local index = table.find(activeSounds, sound)
        if index then table.remove(activeSounds, index) end
    end)
end
```

---

## Recommended Architecture for Verdant Basin

### Audio Zones

```lua
-- src/shared/AudioZones.luau
local AudioZones = {}

AudioZones.Zones = {
    {
        name = "LifeweaveStone",
        center = Vector3.new(0, 0, 0),
        radius = 30,
        music = "mystical",
        reverb = Enum.ReverbType.Cave,
        ambientOverride = "LIFEWEAVE_HUM",
    },
    {
        name = "WaterfallGrove",
        center = Vector3.new(-50, 10, 30),
        radius = 40,
        music = "peaceful",
        reverb = Enum.ReverbType.Forest,
        ambientBoost = { "WATERFALL_ROAR", "MIST_SPRAY" },
    },
    {
        name = "DriftplainTransition",
        center = Vector3.new(200, 0, 0),
        radius = 50,
        music = "tension",
        reverb = Enum.ReverbType.Plain,
        crossfade = true,
    },
}

return AudioZones
```

### File Structure

```
src/
  client/
    Audio/
      AudioController.luau       -- Master controller
      AmbientController.luau     -- Ambient layers
      MusicController.luau       -- Dynamic music
      SFXPlayer.luau             -- One-shot effects
      ReverbController.luau      -- Dynamic reverb
  shared/
    AudioConfig.luau             -- Sound IDs, volumes
    AmbientConfig.luau           -- Per-biome ambience
    SFXConfig.luau               -- Effect categories
    AudioZones.luau              -- Spatial audio zones
```

### Immersion Priorities

1. **Ambient base layer** — Never silence, always presence
2. **Spatial spot ambiences** — Draw ear, create depth
3. **Reactive SFX** — Footsteps, interactions, discoveries
4. **Dynamic music** — Mood follows gameplay
5. **Environmental reverb** — Space awareness
6. **NPC voices** — TTS for dialogue (optional)

---

## Sound Sources & Assets

### Free Sound Libraries

- **Roblox Creator Store** — 100,000+ free sounds
- **Freesound.org** — CC-licensed effects
- **Pixabay** — Royalty-free music and SFX
- **MyNoise.net** — Ambient soundscapes

### Creating Custom Sounds

- **Audacity** — Free audio editor
- **BFXR** — Retro sound effect generator
- **ChipTone** — 8-bit sound creator

### Format Requirements

- Supported: `.ogg`, `.mp3`
- Max file size: 20MB
- Sample rate: 44.1kHz recommended

---

## Sources

- [Sound Design Documentation](https://create.roblox.com/docs/resources/beyond-the-dark/sound-design)
- [Audio API Deep Dive](https://devforum.roblox.com/t/robloxs-new-audio-api-a-somewhat-deep-dive/3156011)
- [New Audio API Announcement](https://devforum.roblox.com/t/new-audio-api-beta-elevate-sound-and-voice-in-your-experiences/2848873)
- [Directional Audio Features](https://devforum.roblox.com/t/new-audio-api-features-directional-audio-audiolimiter-and-more/3282100)
- [Creating Environmental Audio](https://devforum.roblox.com/t/ambientsorcery%E2%80%99s-tutorial-1-creating-compelling-environmental-audio/3507022)
- [Immersive Environments V2](https://devforum.roblox.com/t/immersive-environments-v2-advanced-package-based-audio-and-lighting-control/962709)
- [ReverbAPI](https://devforum.roblox.com/t/%F0%9F%8E%99%EF%B8%8F-introducing-reverbapi-super-immersive-audio-for-all/3622461)
- [Dynamic Audio Reverb](https://devforum.roblox.com/t/dynamic-audio-reverb-environmental-acoustics-sampler-system/3168314)
- [Text-to-Speech API](https://devforum.roblox.com/t/beta-text-to-speech-api-from-text-to-voice-content-instantly/3792085)
- [Three Ways Sound Design Improves Games](https://devforum.roblox.com/t/three-ways-sound-design-can-improve-your-games/1177025)
- [How to Immersify with Audio](https://devforum.roblox.com/t/ruskis-tutorial-4-how-to-immersify-your-experience-with-audio/3278500)
- [Using Licensed Music](https://en.help.roblox.com/hc/en-us/articles/360000927163-Using-Licensed-Music-on-Roblox)
