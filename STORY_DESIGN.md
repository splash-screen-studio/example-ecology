# Story Design & Environmental Narrative

Research on communicating story and mechanics naturally without text overlays (2025).

## Design Philosophy

**Core Principle**: Show, don't tell.

Players don't want to read walls of text. The goal is for learning to blend so seamlessly into the experience that players can't tell where the tutorial ends and the game begins.

---

## Narrative Structure

### Two Places as Starting Point

**Verdant Basin** — Abundance, interconnection
- Theme: Small actions ripple through the ecosystem
- Mood: Wonder, discovery, nurturing
- Conflict: Fragile balance easily disrupted

**Driftplain** — Scarcity, adaptation
- Theme: Survival requires change
- Mood: Harsh beauty, resilience
- Conflict: Resources migrate, must follow or adapt

### Narrative Arc Possibilities

1. **Discovery** → Player learns each ecosystem's rules
2. **Disruption** → Something threatens the balance
3. **Connection** → Player discovers places are linked
4. **Choice** → Player must decide how to restore balance

---

## Environmental Storytelling

### Visual Narrative Cues

**Tell stories through the environment:**

| Element | What it Communicates |
|---------|---------------------|
| Animal trails worn in grass | "Animals travel this path" |
| Bones near water hole | "Predators hunt here" |
| Dried riverbed | "Water used to flow here" |
| Overgrown ruins | "Something was here before" |
| Healthy vs. wilted plants | "This area thrives/struggles" |
| Animal gathering spots | "Resources are here" |

**Verdant Basin examples:**
- Waterfall feeding multiple streams → interconnection
- Dense foliage hiding secrets → reward exploration
- Animal footprints converging at water → ecosystem hub

**Driftplain examples:**
- Lone dead tree → once there was life here
- Bones half-buried in sand → harsh environment
- Distant oasis visible from high ground → goal/hope
- Wind-carved rock formations → time and patience

### Landmarks That Pull Players

Design "weenies" (Disney term) — visual magnets that draw the eye:

```
Verdant Basin:
- Ancient tree on hilltop (visible from spawn)
- Waterfall with rainbow mist
- Glowing mushroom grove at night

Driftplain:
- Monolithic spire (from marketing art)
- Distant mountains with snow peaks
- Oasis with single large tree
```

**Key rule**: If player can see it, they should be able to reach it. Reward their curiosity.

---

## Teaching Mechanics Without Text

### Progressive Disclosure

Don't explain everything at once. Let players discover naturally.

**Level 1: Safe space**
- Player spawns in area with no threats
- Food nearby, easily visible
- Water close by
- Player can experiment freely

**Level 2: Gentle pressure**
- Hunger/thirst start to matter
- Food requires short journey
- Introduce one small challenge

**Level 3: Real stakes**
- Predators exist but avoidable
- Resources require planning
- Player applies what they learned

### Affordances (Visual Action Hints)

Players understand intuitively:

| Visual Cue | Meaning |
|------------|---------|
| Glowing outline | Interactable |
| Particle effects | Important/active |
| Color contrast | Stand out = significant |
| Size difference | Big = important |
| Movement/animation | Alive, reactive |
| Sound | Draws attention |

### Learning Through Failure

**Safe failures early:**
- Run out of hunger near food → teaches "eat before empty"
- Get thirsty near water → teaches water importance
- See animal flee → teaches "you affect the world"

**NOT punishing deaths** — respawn nearby, keep progress.

### Imitation Learning

**Show NPCs/animals doing things:**
- Animal drinks from water → player learns water location
- Animal eats berries → player learns food source
- Animal flees predator → player learns danger

```lua
-- Animal behavior teaches player
local function animalDemonstration()
    -- Animal walks to water, drinks
    -- Player observes, learns water location
    -- Animal becomes hungry indicator
end
```

---

## NPC Dialogue

### Principles

1. **Short** — Mobile screens are small
2. **Character voice** — Each NPC sounds distinct
3. **Useful** — Hints, not exposition dumps
4. **Optional** — Player can skip and still play

### Dialogue System

```lua
-- Dialogue appears above NPC's head in world
-- NOT a full-screen overlay
-- Tap to advance, auto-dismiss after time

local dialogue = {
    {
        speaker = "Old Warden",
        lines = {
            "Water flows downhill.",
            "Follow it to find life.",
        },
        hint = "water_location"  -- track if player saw this
    }
}
```

### NPC Types

**Guide NPCs:**
- Sparse dialogue, poetic/cryptic
- Point toward discoveries without spoiling
- "The tall grass hides more than you'd think."

**Ambient NPCs:**
- React to player presence
- One-liners that build world
- "Rain hasn't come in weeks..."

**Quest NPCs:**
- Clear objectives when needed
- "Bring me three moon berries."
- Minimal — ecology sim, not quest grind

---

## Signposts & Environmental Text

### Physical Signs in World

**Double-sided signs** — different message on each side:

```
Front (approaching): "Driftplain Ahead — Bring Water"
Back (leaving): "Verdant Basin — Follow the River"
```

**Signpost types:**
- Wooden posts with carved symbols
- Stone markers with simple icons
- Fabric banners (for temporary/player-made)

### Icon Language

Develop consistent visual vocabulary:

```
💧 = Water
🍖 = Food
⚠️ = Danger
🏠 = Shelter/Safe
↑ = Direction
👁️ = Point of Interest
```

Use shapes/colors that work without text:
- Circle = safe/resource
- Triangle = danger/attention
- Square = structure/location

### Discovered Lore

**Found objects that tell stories:**
- Old journals (optional reading)
- Cave paintings
- Abandoned camps
- Broken tools

Player who wants lore can find it. Player who doesn't can ignore it.

---

## Audio Narrative

### Ambient Sound Design

**Verdant Basin:**
- Constant: flowing water, birds, rustling leaves
- Dynamic: changes based on time, weather, nearby animals
- Spatial: sounds lead player to points of interest

**Driftplain:**
- Constant: wind, distant howls, sand shifting
- Dynamic: silence in dangerous areas, relief at oases
- Spatial: echo in canyons, muffled in sandstorms

### Audio Cues for Mechanics

| Sound | Meaning |
|-------|---------|
| Stomach rumble | Low hunger |
| Heartbeat | Low health |
| Triumphant sting | Discovery/achievement |
| Soft chime | Item pickup |
| Tense strings | Danger nearby |
| Relief sigh | Safe zone entered |

### Music as Narrative

- Each biome has distinct musical identity
- Layers add/remove based on danger level
- Discovery moments get musical flourish
- Don't overuse — silence is powerful

---

## Reward Discovery

### Things That Reward Exploration

1. **Vistas** — Beautiful views from high points
2. **Resources** — Better food, materials in hidden spots
3. **Secrets** — Easter eggs, lore items
4. **Shortcuts** — Faster routes between areas
5. **Wildlife** — Rare animals in specific locations
6. **Safe zones** — Places to rest and recover

### Path Design

**Guide without railroading:**

```
    [Spawn]
       |
   [Open area with food/water]
       |
   [Fork in path]
      / \
  [Easy]  [Challenge]
    |         |
[Basic reward] [Better reward]
```

**Breadcrumb design:**
- Place small rewards along intended paths
- Visible from previous reward
- Creates natural flow without arrows

---

## Avoiding UI Text

### Replace Text With...

| Instead of... | Use... |
|---------------|--------|
| "Press E to interact" | Glowing highlight when near |
| "You are hungry" | Stomach rumble + visual vignette |
| "Quest: Find water" | NPC points toward water |
| "Tutorial: How to jump" | Gap player naturally tries to cross |
| "Loading..." | Environmental transition (fade, mist) |
| Health number | Health bar (no numbers) |

### Minimal UI Philosophy

```
Essential UI:
- Health bar (bottom corner, small)
- Hunger/thirst bars (same area)
- Minimap (toggle-able, off by default?)

NO:
- Quest tracker overlay
- Damage numbers
- Tutorial popups
- Objective markers unless requested
```

---

## Mobile-First Narrative

### Small Screen Considerations

1. **Large touch targets** for dialogue advance
2. **Brief text** — 2 lines max per dialogue bubble
3. **Bottom of screen** for dialogue (thumb-reachable)
4. **Auto-advance option** with pause on touch
5. **Skip button** always visible

### Readable World Text

If using signs in world:
- Large, simple fonts
- High contrast
- Icons alongside text
- Short phrases (3-5 words)

---

## Implementation Notes

### Dialogue System Structure

```
src/
  client/
    Dialogue/
      DialogueUI.luau         -- renders dialogue above NPCs
      DialogueController.luau -- handles player interaction
  shared/
    DialogueData/
      Verdant/
        OldWarden.luau
        ForestSpirit.luau
      Driftplain/
        Nomad.luau
        WindSpeaker.luau
```

### Environmental Storytelling Checklist

For each area, ask:
- [ ] What happened here before?
- [ ] What is happening now?
- [ ] What does this place teach the player?
- [ ] What draws the eye?
- [ ] What sound does this place have?
- [ ] What reward is here for explorers?

---

## Sources

- [Environmental Storytelling in Video Games](https://www.intechopen.com/online-first/1225186)
- [How to Communicate Without Text](https://www.gamedeveloper.com/design/how-to-communicate-with-your-players-without-using-text)
- [Teaching the Player: Don't Use Words](https://www.gamedeveloper.com/design/teaching-the-player-don-t-use-words)
- [Methods of Creating Invisible Tutorials](https://www.gamedeveloper.com/design/methods-of-creating-invisible-tutorials)
- [Designing Immersive Tutorials](https://medium.com/teeny-tiny-game-dev-essays/a-short-guide-to-designing-immersive-fun-game-tutorials-948959b2c6dd)
- [No More Tutorials: Convey Through Design](https://www.gamedeveloper.com/audio/no-more-tutorials-how-to-convey-information-through-design)
- [Exploring Narrative Design in Roblox](https://moldstud.com/articles/p-exploring-narrative-design-in-roblox-games-crafting-compelling-stories)
- [NPC Dialogue System (Roblox)](https://devforum.roblox.com/t/npc-dialogue-system/3784395)
- [RoSpeak Dialogue System](https://devforum.roblox.com/t/rospeak-a-customizable-npc-chat-and-dialogue-system-version-1/3772098)
- [Roblox NPC Dialog Tutorial](https://www.idtech.com/blog/how-to-make-an-npc-dialog-system-in-roblox)
