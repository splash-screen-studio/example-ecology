# NPC People (Human Characters)

Research on creating believable human NPCs for Verdant Basin (2025).

## Overview

Human NPCs in Verdant Basin serve as:
- **Quest givers** (The Keeper, Old Mira, Nomad, Wind Speaker)
- **Story vehicles** (environmental storytelling, lore delivery)
- **World inhabitants** (making the world feel alive)

Unlike animal NPCs, human NPCs require:
- Natural dialogue and conversation flow
- Expressive animations and gestures
- Quest/relationship state tracking
- Voice or text-to-speech (optional)

---

## NPC Creation & Appearance

### Rig Builder (Built-in)

**Steps**:
1. Avatar tab → Rig Builder
2. Select R15 (recommended) or R6 (classic blocky)
3. Choose body shape
4. Rename the model in Workspace

**R15 vs R6**:
- **R15**: 15 body parts, smoother animations, modern standard
- **R6**: 6 body parts, classic look, simpler but less expressive

### Custom-NPC Plugin

Community plugin for streamlined NPC creation with a clean UI. Useful for:
- Rapid prototyping of character appearances
- Consistent styling across multiple NPCs

**Link**: [Custom-NPC Plugin](https://devforum.roblox.com/t/custom-npc-customizing-npcs-just-got-a-lot-easier/2560183)

### Appearance Customization

```lua
-- Apply appearance from a template player
local Players = game:GetService("Players")
local description = Players:GetHumanoidDescriptionFromUserId(123456)

local npc = workspace.MyNPC
npc.Humanoid:ApplyDescription(description)
```

**Layered Clothing** (2023+):
- Realistic fabric that deforms with movement
- Requires specific mesh formatting
- Creates dynamic, professional-looking outfits

### Animation Override

```lua
local animator = npc.Humanoid:FindFirstChildOfClass("Animator")
local idleAnim = Instance.new("Animation")
idleAnim.AnimationId = "rbxassetid://YOUR_IDLE_ANIM"

local track = animator:LoadAnimation(idleAnim)
track:Play()
```

---

## Dialogue Systems

### Option 1: Built-in Dialog Object

Roblox's native dialogue system with speech bubbles.

**Pros**:
- No scripting needed for basic use
- Familiar to players
- Built-in proximity detection

**Cons**:
- Limited customization
- No typewriter effect
- Hard to integrate with quest state

**Usage**:
```lua
local dialog = Instance.new("Dialog")
dialog.InitialPrompt = "Hello, traveler. The Basin whispers of your arrival."
dialog.Parent = npc.Head

local choice1 = Instance.new("DialogChoice")
choice1.UserDialog = "What is this place?"
choice1.ResponseDialog = "This is Verdant Basin—where life remembers."
choice1.Parent = dialog
```

**Link**: [Dialog Documentation](https://create.roblox.com/docs/reference/engine/classes/Dialog)

### Option 2: Custom GUI Dialogue (Recommended)

Full control with ProximityPrompt + ScreenGui.

**Architecture**:
```
ReplicatedStorage/
  Shared/
    DialogueData.luau      -- All NPC dialogue trees
    DialogueController.luau -- Client-side UI logic

StarterGui/
  DialogueGui/
    Frame
      NPCName (TextLabel)
      DialogueText (TextLabel)
      ChoicesContainer (Frame)
```

**Dialogue Data Structure**:
```lua
-- src/shared/DialogueData.luau
local DialogueData = {}

DialogueData.TheKeeper = {
    initial = {
        speaker = "The Keeper",
        text = "You feel it too, don't you? The Lifeweave... it's unraveling.",
        choices = {
            { text = "The Lifeweave?", next = "explain_lifeweave" },
            { text = "Who are you?", next = "introduce_self" },
            { text = "I should go.", next = nil },  -- ends conversation
        },
    },
    explain_lifeweave = {
        speaker = "The Keeper",
        text = "The invisible threads connecting every living thing. When one species suffers, ripples spread to all others.",
        choices = {
            { text = "How can I help?", next = "first_quest" },
            { text = "I don't understand.", next = "simpler_explanation" },
        },
    },
    first_quest = {
        speaker = "The Keeper",
        text = "The herons haven't nested this season. Find out why. Watch. Listen. The Basin will show you.",
        action = "START_QUEST:heron_mystery",
        choices = {
            { text = "I'll investigate.", next = nil },
        },
    },
}

return DialogueData
```

**Typewriter Effect**:
```lua
local function typewriterText(textLabel, fullText, speed)
    speed = speed or 0.03
    textLabel.Text = ""
    for i = 1, #fullText do
        textLabel.Text = string.sub(fullText, 1, i)
        task.wait(speed)
    end
end
```

### Option 3: RoSpeak (Community Module)

Released June 2025 — easy-to-setup dialogue system with customization.

**Link**: [RoSpeak](https://devforum.roblox.com/t/rospeak-a-customizable-npc-chat-and-dialogue-system-version-1/3772098)

### Option 4: Grow a Garden Style

Popular 2025 pattern with clean UI and sell system integration.

**Link**: [NPC Dialogue System like Grow a Garden](https://devforum.roblox.com/t/npc-dialogue-system-like-grow-a-garden/4144102)

---

## AI Behavior Frameworks

For NPCs that move, react, and feel alive.

### Unstructured AI (Simplest)

If/else chains. Good for simple, single-purpose NPCs.

```lua
local function updateNPC()
    local nearestPlayer = findNearestPlayer()

    if nearestPlayer and distanceTo(nearestPlayer) < 20 then
        lookAtPlayer(nearestPlayer)
        if not isTalking then
            wave()
        end
    else
        idle()
    end
end
```

### Finite State Machines (FSM)

States with clear transitions. Good for most quest NPCs.

```lua
local States = {
    IDLE = "idle",
    GREETING = "greeting",
    TALKING = "talking",
    WALKING = "walking",
}

local NPCStateMachine = {}
NPCStateMachine.currentState = States.IDLE

function NPCStateMachine:update()
    if self.currentState == States.IDLE then
        playIdleAnimation()
        if playerNearby() then
            self.currentState = States.GREETING
        end

    elseif self.currentState == States.GREETING then
        playWaveAnimation()
        facePlayer()
        task.wait(1)
        self.currentState = States.TALKING

    elseif self.currentState == States.TALKING then
        -- Wait for dialogue system to signal end
        if not isDialogueActive() then
            self.currentState = States.IDLE
        end
    end
end
```

### Utility AI

Score-based decision making. Good for complex NPCs with multiple priorities.

```lua
local function calculateAction(npc, context)
    local actions = {
        { name = "greet", score = 0 },
        { name = "work", score = 0 },
        { name = "rest", score = 0 },
        { name = "wander", score = 0 },
    }

    -- Score greeting if player nearby and not recently greeted
    if context.playerNearby and not context.recentlyGreeted then
        actions[1].score = 80
    end

    -- Score work based on time of day
    if context.isDaytime then
        actions[2].score = 60
    end

    -- Score rest based on tiredness
    actions[3].score = context.tiredness * 100

    -- Default wander
    actions[4].score = 20

    table.sort(actions, function(a, b) return a.score > b.score end)
    return actions[1].name
end
```

### Behavior Trees

Hierarchical task nodes. Most flexible but most complex.

**Link**: [AI Behavior Frameworks Tutorial](https://devforum.roblox.com/t/using-ai-behavior-frameworks-for-npcs/3482097)

---

## Pathfinding & Movement

### PathfindingService

Built-in A* pathfinding with obstacle avoidance.

```lua
local PathfindingService = game:GetService("PathfindingService")

local function walkTo(npc, destination)
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    local rootPart = npc:FindFirstChild("HumanoidRootPart")

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = false,
    })

    path:ComputeAsync(rootPart.Position, destination)

    if path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, waypoint in waypoints do
            humanoid:MoveTo(waypoint.Position)
            humanoid.MoveToFinished:Wait()
        end
    end
end
```

### Patrol System

```lua
local patrolPoints = {
    Vector3.new(0, 0, 0),
    Vector3.new(50, 0, 0),
    Vector3.new(50, 0, 50),
    Vector3.new(0, 0, 50),
}

local currentPatrolIndex = 1

local function patrol(npc)
    while true do
        local destination = patrolPoints[currentPatrolIndex]
        walkTo(npc, destination)

        -- Wait at patrol point
        task.wait(math.random(3, 8))

        -- Move to next point
        currentPatrolIndex = (currentPatrolIndex % #patrolPoints) + 1
    end
end
```

### Dynamic Obstacle Avoidance

Handle path blocking events:

```lua
path.Blocked:Connect(function(blockedWaypointIndex)
    -- Recompute path from current position
    path:ComputeAsync(rootPart.Position, destination)
end)
```

**Links**:
- [Pathfinding Documentation](https://create.roblox.com/docs/characters/pathfinding)
- [Dynamic Obstacle Avoidance Guide](https://www.primalcam.com/post/how-to-create-npc-pathfinding-with-dynamic-obstacle-avoidance-in-roblox)
- [Roblox Pathfinding AI Toolkit](https://github.com/staplesserial133/Roblox-Pathfinding-AI)

---

## Quest System Integration

### Quest State Tracking

```lua
-- src/shared/QuestData.luau
local QuestData = {}

QuestData.Quests = {
    heron_mystery = {
        id = "heron_mystery",
        title = "The Silent Nests",
        giver = "TheKeeper",
        stages = {
            { type = "observe", target = "HeronNestingArea", description = "Find the heron nesting grounds" },
            { type = "discover", target = "PollutedStream", description = "Discover what's wrong" },
            { type = "return", target = "TheKeeper", description = "Report to The Keeper" },
        },
        rewards = {
            { type = "unlock", value = "EcologistTitle" },
            { type = "knowledge", value = "heron_behavior" },
        },
    },
}

return QuestData
```

### NPC Quest Awareness

```lua
local function getDialogueForQuestState(npcId, player)
    local questProgress = getPlayerQuestProgress(player)

    if npcId == "TheKeeper" then
        if not questProgress.heron_mystery then
            return DialogueData.TheKeeper.initial
        elseif questProgress.heron_mystery.stage == 3 then
            return DialogueData.TheKeeper.quest_complete
        else
            return DialogueData.TheKeeper.quest_in_progress
        end
    end
end
```

**Links**:
- [Quest System Tutorial](https://devforum.roblox.com/t/how-to-make-a-quest-system/1732100)
- [Udemy NPC Quest Course](https://www.udemy.com/course/roblox-concepts-01-create-your-own-npc-quest-giver/)

---

## Voice & Text-to-Speech

### Roblox TTS API (2025)

Released June 2025 — generate voice from text without audio production.

**Benefits**:
- No voice actors needed
- Dynamic dialogue possible
- Reduced asset size

**Implementation**:
```lua
local TextToSpeechService = game:GetService("TextToSpeechService")

local function speakDialogue(text, voiceId)
    local audioData = TextToSpeechService:Synthesize(text, {
        Voice = voiceId,  -- e.g., "en-US-Standard-A"
    })

    local sound = Instance.new("Sound")
    sound.SoundId = audioData
    sound.Parent = npc.Head
    sound:Play()

    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end
```

**Links**:
- [Text-to-Speech API Announcement](https://devforum.roblox.com/t/beta-text-to-speech-api-from-text-to-voice-content-instantly/3792085)
- [Add Text-to-Speech Tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/audio/add-text-to-speech)
- [Speech-to-Text API](https://devforum.roblox.com/t/beta-introducing-the-speech-to-text-api/4044579)

---

## Daily Routines & Schedules

### Time-Based Behavior

NPCs can follow schedules based on in-game time.

```lua
-- src/shared/NPCSchedules.luau
local NPCSchedules = {}

NPCSchedules.OldMira = {
    { startHour = 6, endHour = 9, location = "MirasCabin", action = "morning_routine" },
    { startHour = 9, endHour = 12, location = "HerbGarden", action = "tend_garden" },
    { startHour = 12, endHour = 14, location = "MirasCabin", action = "lunch" },
    { startHour = 14, endHour = 18, location = "ForestPath", action = "gather_herbs" },
    { startHour = 18, endHour = 21, location = "MirasCabin", action = "evening" },
    { startHour = 21, endHour = 6, location = "MirasCabin", action = "sleep" },
}

return NPCSchedules
```

**Schedule Controller**:
```lua
local function updateNPCSchedule(npc, npcId)
    local schedule = NPCSchedules[npcId]
    local currentHour = getGameTimeHour()

    for _, slot in schedule do
        if currentHour >= slot.startHour and currentHour < slot.endHour then
            if npc.CurrentAction ~= slot.action then
                transitionTo(npc, slot.location, slot.action)
            end
            return
        end
    end
end
```

**Link**: [NPC System V2](https://devforum.roblox.com/t/npc-system-v2-your-comprehensive-npc-system-for-your-roblox-game/4003818)

---

## Memory & Relationships

### Player-NPC Relationship Tracking

```lua
-- DataStore structure per player
local playerNPCRelations = {
    TheKeeper = {
        met = true,
        questsCompleted = { "heron_mystery" },
        dialoguesSeen = { "initial", "explain_lifeweave" },
        reputation = 50,  -- 0-100 scale
    },
    OldMira = {
        met = false,
        questsCompleted = {},
        dialoguesSeen = {},
        reputation = 0,
    },
}
```

**Dialogue Variation Based on Relationship**:
```lua
local function getGreeting(npcId, player)
    local relation = getPlayerRelation(player, npcId)

    if not relation.met then
        return DialogueData[npcId].first_meeting
    elseif relation.reputation < 20 then
        return DialogueData[npcId].cold_greeting
    elseif relation.reputation < 50 then
        return DialogueData[npcId].neutral_greeting
    elseif relation.reputation < 80 then
        return DialogueData[npcId].friendly_greeting
    else
        return DialogueData[npcId].warm_greeting
    end
end
```

### NPC Memory of Events

```lua
local worldEvents = {
    heronsMigrated = false,
    droughtStarted = false,
    playerSavedFawn = false,
}

local function getContextualDialogue(npcId, player)
    local base = getDialogueForQuestState(npcId, player)

    -- Add contextual comments
    if worldEvents.playerSavedFawn and npcId == "OldMira" then
        return {
            preamble = "I heard what you did for that fawn. The Basin remembers kindness.",
            main = base,
        }
    end

    return { main = base }
end
```

---

## Performance Optimization

### NPC System V2 (October 2025)

Production-ready, server-authoritative NPC system optimized for scale.

**Features**:
- Server-authoritative with client-side rendering
- Advanced pathfinding + sight detection
- Built for scalability

**Link**: [NPC System V2](https://devforum.roblox.com/t/npc-system-v2-your-comprehensive-npc-system-for-your-roblox-game/4003818)

### Optimization Techniques

1. **LOD for NPCs** — Simpler behavior at distance
2. **Staggered Updates** — Not all NPCs every frame
3. **Spatial Partitioning** — Only process nearby NPCs fully
4. **Animation Culling** — Don't animate off-screen NPCs

```lua
local function shouldFullUpdate(npc, nearestPlayer)
    local distance = (npc.Position - nearestPlayer.Position).Magnitude

    if distance < 50 then
        return true, 0.1  -- Full update, 10 FPS
    elseif distance < 150 then
        return true, 0.5  -- Full update, 2 FPS
    else
        return false, 2   -- Minimal update, 0.5 FPS
    end
end
```

---

## Recommended Architecture for Verdant Basin

### NPC Roster

| NPC | Location | Role | Behavior |
|-----|----------|------|----------|
| **The Keeper** | Lifeweave Stone | Tutorial, main quest | Stationary, mystical |
| **Old Mira** | Mira's Cabin | Herbalist, side quests | Daily schedule, tends garden |
| **Nomad** | Driftplain entrance | Guide, lore | Wanders, camps at night |
| **Wind Speaker** | Driftplain spire | Elder, deep lore | Stationary, appears at dusk |

### File Structure

```
src/
  server/
    NPC/
      NPCManager.luau           -- Spawns and manages all NPCs
      NPCController.luau        -- Base class for NPC behavior
      DialogueServer.luau       -- Handles quest state, rewards
      ScheduleManager.luau      -- Time-based behavior
  client/
    NPC/
      DialogueUI.luau           -- Dialogue GUI controller
      NPCHighlight.luau         -- Interaction prompts
  shared/
    DialogueData.luau           -- All dialogue trees
    NPCConfig.luau              -- NPC definitions, appearances
    NPCSchedules.luau           -- Daily routines
    QuestData.luau              -- Quest definitions
```

### NPCConfig Example

```lua
-- src/shared/NPCConfig.luau
local NPCConfig = {}

NPCConfig.NPCs = {
    TheKeeper = {
        displayName = "The Keeper",
        spawnLocation = Vector3.new(0, 5, 0),
        appearance = {
            bodyColors = { HeadColor = Color3.fromRGB(180, 140, 100) },
            clothing = {
                shirt = "rbxassetid://KEEPER_SHIRT",
                pants = "rbxassetid://KEEPER_PANTS",
            },
        },
        behavior = "Stationary",
        animations = {
            idle = "rbxassetid://KEEPER_IDLE",
            talk = "rbxassetid://KEEPER_TALK",
            gesture = "rbxassetid://KEEPER_GESTURE",
        },
        interactionRadius = 15,
    },

    OldMira = {
        displayName = "Old Mira",
        spawnLocation = Vector3.new(100, 5, -50),
        appearance = { ... },
        behavior = "Scheduled",
        schedule = "OldMira",  -- References NPCSchedules
        animations = { ... },
        interactionRadius = 10,
    },
}

return NPCConfig
```

### Key Design Principles

1. **Show, don't tell** — NPCs hint, they don't lecture
2. **Quest state awareness** — Dialogue changes based on progress
3. **Environmental integration** — NPCs react to world events
4. **Player agency** — Choices matter, relationships develop
5. **Performance first** — LOD, culling, staggered updates

---

## Sources

- [Dialog Documentation](https://create.roblox.com/docs/reference/engine/classes/Dialog)
- [Custom-NPC Plugin](https://devforum.roblox.com/t/custom-npc-customizing-npcs-just-got-a-lot-easier/2560183)
- [RoSpeak Dialogue System](https://devforum.roblox.com/t/rospeak-a-customizable-npc-chat-and-dialogue-system-version-1/3772098)
- [NPC Dialogue like Grow a Garden](https://devforum.roblox.com/t/npc-dialogue-system-like-grow-a-garden/4144102)
- [AI Behavior Frameworks Tutorial](https://devforum.roblox.com/t/using-ai-behavior-frameworks-for-npcs/3482097)
- [Pathfinding Documentation](https://create.roblox.com/docs/characters/pathfinding)
- [Dynamic Obstacle Avoidance](https://www.primalcam.com/post/how-to-create-npc-pathfinding-with-dynamic-obstacle-avoidance-in-roblox)
- [NPC Pathfinding Tutorial (Jan 2025)](https://kushaltimsina.com/blog/2025/01/06/how-to-script-npc-pathfinding-on-roblox/)
- [Quest System Tutorial](https://devforum.roblox.com/t/how-to-make-a-quest-system/1732100)
- [Text-to-Speech API](https://devforum.roblox.com/t/beta-text-to-speech-api-from-text-to-voice-content-instantly/3792085)
- [Speech-to-Text API](https://devforum.roblox.com/t/beta-introducing-the-speech-to-text-api/4044579)
- [NPC System V2](https://devforum.roblox.com/t/npc-system-v2-your-comprehensive-npc-system-for-your-roblox-game/4003818)
- [Roblox Pathfinding AI Toolkit](https://github.com/staplesserial133/Roblox-Pathfinding-AI)
