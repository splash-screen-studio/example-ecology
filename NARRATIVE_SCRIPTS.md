# Narrative Scripts & World Structure

Detailed scripts, dialogue, NPC placement, world pulls, multiplayer, and navigation structure.

---

## Game Name: Verdant Basin

The experience is called **Verdant Basin**. The first place shares this name — the Basin is the iconic starting location that defines the game's identity.

---

## World Structure

### Is It Linear?

**No, but guided.**

```
LINEAR:     A → B → C → D (forced order)
OPEN:       A ↔ B ↔ C ↔ D (go anywhere)
VERDANT BASIN: A → [B or C] → D → [E or F or G] → H (gated but branching)
```

The player MUST:
- Start in Verdant Basin (the place)
- Complete core understanding before leaving
- Restore the Basin-Driftplain connection eventually

The player CAN:
- Explore Verdant Basin fully before leaving
- Return to any unlocked place at any time
- Complete side objectives in any order
- Skip some content (but miss story/rewards)

### Place Unlock Structure

```
                    [The Source] (Final)
                          ↑
                    [Underground] (Story climax)
                          ↑
    ┌─────────────────────┼─────────────────────┐
    ↓                     ↓                     ↓
[Canopy Kingdom]   [Ashen Caldera]      [Coral Shallows]
    ↑                     ↑                     ↑
    │                     │                     │
[Frozen Reach]←──────────→│←──────────→[Sunken Forest]
    ↑                     │                     ↑
    │                     │                     │
    └─────[DRIFTPLAIN]────┴────[VERDANT BASIN]──┘
                          ↑
                    [START HERE]
```

### Unlock Requirements

| Place | Requires |
|-------|----------|
| Verdant Basin (Place) | None — starting point |
| Driftplain | Complete "The Missing Otter" quest step 4 |
| Sunken Forest | Restore Basin-Plain connection |
| Frozen Reach | Restore Basin-Plain connection |
| Coral Shallows | Visit either Sunken Forest OR Frozen Reach |
| Ashen Caldera | Visit Coral Shallows |
| Canopy Kingdom | Visit Frozen Reach |
| Underground | Activate 5 Lifeweave nodes (any places) |
| The Source | Complete Underground main quest |

### Can You Go Back?

**Yes, always.**

- Every unlocked place remains accessible
- Teleport hubs in each place (Lifeweave Stones)
- Some quests REQUIRE returning to previous places
- Ecosystem state persists — changes you made are still there

---

## Teleportation System

### How It Works

**Lifeweave Stones** — Ancient markers at key points in each place

```lua
-- When player approaches Lifeweave Stone
-- ProximityPrompt: "Attune" (first time) or "Travel" (after attuned)
```

**Attuning**: Stand near stone for 3 seconds. Stone glows, confirmed.

**Traveling**:
1. Interact with any attuned stone
2. See simple UI: icons of unlocked places (NOT a full map)
3. Select destination
4. Transition (fade to black, ambient sound of travel, fade in)

### Stone Locations Per Place

| Place | # Stones | Locations |
|-------|----------|-----------|
| Verdant Basin | 3 | Spawn, Ancient Tree, Basin Exit |
| Driftplain | 3 | Arrival, Last Oasis, The Spire |
| Sunken Forest | 2 | Shore, Sunken Temple |
| Frozen Reach | 2 | Pass Entrance, Migration Point |
| Coral Shallows | 2 | Beach, Reef Heart |
| Ashen Caldera | 2 | Rim, Crater Floor |
| Canopy Kingdom | 3 | Ground, Mid-Canopy, Emergent |
| Underground | 1 | Central Hub |
| The Source | 1 | Summit |

### Travel Restrictions

- Can only travel TO stones you've attuned
- Can only travel FROM any stone you're standing at
- No fast travel during combat/urgent events
- Some story moments temporarily disable travel

### Multiplayer Teleporting

- If in a party: "Bring party?" prompt
- Party members can decline
- If party splits: stay connected but in different places
- Can rejoin via mutual stone travel

---

## Quest Structure

### Must Complete (Main Quests)

These are REQUIRED to progress. Cannot reach endgame without them.

**Verdant Basin Main Quest: "The Missing Otter"**
1. Observe the Imbalance *(tutorial, cannot leave basin until done)*
2. Consult the Keeper *(introduces story)*
3. Find Otter Signs *(exploration)*
4. Discover the Blockage *(unlocks Driftplain)*
5. Clear the Path *(requires knowledge from Driftplain)*

**Driftplain Main Quest: "The Scattered Herds"**
1. Witness the Thirst *(immediate upon arrival)*
2. Find the Sand Burrower *(exploration)*
3. Trace the Missing River *(connects back to Basin)*
4. Discover the Connection *(revelation)*
5. Restore the Flow *(first major milestone)*

### Must Discover (Hidden Quests)

These are NOT marked. Player finds them through exploration.

**Examples in Verdant Basin:**
- "The Night Bloom" — Find the Moonpetal (only blooms at night)
- "Old Shell" — Locate the ancient snapping turtle
- "Strangler's Grip" — Notice invasive vines, learn to remove them

**How Discovery Works:**
- No quest markers until quest is discovered
- Discovery triggers: observation, NPC hint, environmental clue
- Once discovered: appears in Field Journal
- Still no map markers — player must remember/explore

### Backtracking Quests

**Yes, some quests require returning to earlier places.**

Examples:
- "Restore the Flow" requires visiting BOTH Basin AND Driftplain
- "Coral Sickness" (in Coral Shallows) requires fixing upstream pollution in Basin
- "The Ancient's Memory" (Underground) asks you to observe species in 3 different places

**Design Philosophy:**
- Backtracking reveals how places connect
- Ecosystem changes you caused are visible when returning
- New content unlocks in old places as story progresses
- NPCs have new dialogue when you return

---

## NPCs: Who, Where, What They Say

### NPC Types

1. **Spirits** — Ancient beings, cryptic guidance
2. **Ecologists** — Other travelers like you, practical advice
3. **Animals** — Not speaking, but "communicate" through behavior
4. **Ambient Voices** — Whispers from the Lifeweave itself

### Verdant Basin NPCs

#### The Keeper (Spirit)
**Location**: Ancient Tree, Central Lake island
**Role**: Primary guide for Basin

**First Meeting:**
```
KEEPER: You feel it, don't you?
        The abundance. The... wrongness within it.

        [Player approaches]

KEEPER: Too much of a good thing.
        The fish swarm. The birds fight.
        Something is missing.

        [Pause]

KEEPER: Or perhaps... someone.
```

**After Observing Fish:**
```
KEEPER: The trout multiply without check.
        Who checked them, before?

        Follow the water. It remembers.
```

**After Finding Otter Den:**
```
KEEPER: The river otter. Yes.
        They hunted the trout.
        Kept the balance.

        [Looks toward basin exit]

KEEPER: They followed the water.
        When it stopped flowing...
        they left to find more.

        They never returned.
```

**After Visiting Driftplain:**
```
KEEPER: You've seen both sides now.
        Abundance and scarcity.
        Two halves of one broken whole.

        The water that drowns us here...
        should be giving life there.

        Find the blockage.
        The path between worlds.
```

#### Old Mira (Ecologist)
**Location**: Near Frog Marsh, sitting on log
**Role**: Teaches observation mechanics

**First Meeting:**
```
OLD MIRA: [Looking at frogs]
          Shh. Watch.

          [Pause as frog catches insect]

OLD MIRA: That's how you learn here.
          Not by doing. By watching.

          [Gestures at Field Journal]

OLD MIRA: Write down what you see.
          Patterns emerge.
          The marsh will teach you.

          [Beat]

OLD MIRA: I've been watching these frogs
          for thirty years.
          They're still surprising me.
```

**After Player Observes Species:**
```
OLD MIRA: You're getting it.
          The herons are hungry.
          Too many of them.
          Not enough variety in the fish.

          [Shakes head]

OLD MIRA: Used to be different.
          Before the otters left.
```

#### The Wading Child (Spirit)
**Location**: Wanders near Reed Maze
**Role**: Hints about hidden areas

**Random Encounters:**
```
WADING CHILD: [Giggling]
              The reeds move when the water rises.
              Paths open. Paths close.

              [Points vaguely]

WADING CHILD: Something sleeps in the deepest part.
              Shhh.
```

```
WADING CHILD: Do you like mushrooms?
              The grove glows at night.
              But only if you're quiet.
```

```
WADING CHILD: [Sad]
              The birds are angry.
              Too many nests. Not enough room.

              [Brightens]

              You could help them.
              Maybe.
```

### Driftplain NPCs

#### The Nomad (Ecologist)
**Location**: Near Last Oasis
**Role**: Driftplain guide, practical survival

**First Meeting:**
```
NOMAD: [Looks up from water hole]
       Another one from the wet lands.

       [Stands]

NOMAD: Don't drink too fast.
       Your body isn't used to thirst.

       [Gestures at dying animals nearby]

NOMAD: They're not either. Not like this.
       Used to be more water. More spread out.
       Now... just this.

       [Grim]

NOMAD: Too many bodies at one well.
       Trouble follows.
```

**After Learning About Water:**
```
NOMAD: The river that should feed us...
       comes from your green place.

       [Points toward Basin Inlet]

NOMAD: A trickle now. Used to be a flow.
       My grandmother told stories of it.
       Wide enough to swim.

       [Beat]

NOMAD: Something stopped it.
       Find what.
```

#### Wind Speaker (Spirit)
**Location**: The Spire, summit
**Role**: Deep lore, Lifeweave hints

**First Meeting:**
```
WIND SPEAKER: [Wind sounds form words]
              You climbed.

              Most don't.

              [Pause]

WIND SPEAKER: From here you see the pattern.
              Where water was. Where it should be.
              The lines that connected.

              [Wind intensifies]

WIND SPEAKER: They are broken.
              But not gone.
              Never gone.

              The web beneath waits.
              To be woven again.
```

#### The Burrower (Animal/Guide)
**Location**: Appears when player is near hidden water
**Role**: Non-verbal guide to underground water

**Behavior:**
```
- Appears from ground
- Looks at player
- Digs, disappears
- Resurfaces further away
- Repeats until player follows
- Leads to underground water cache
```

No dialogue. Communication through action.

---

## Signposts & Environmental Text

### Double-Sided Signs

Signs at major junctions, different message each side:

**Basin Exit Sign:**
```
FRONT (leaving Basin):
[Icon: Sun + Dry grass]
"DRIFTPLAIN BEYOND"
"Water is scarce. Prepare."

BACK (entering Basin):
[Icon: Water + Trees]
"VERDANT BASIN"
"The waters remember."
```

**At Lifeweave Stone (Basin):**
```
FRONT:
[Icon: Spiral]
"LIFEWEAVE STONE"
"Attune to travel."

BACK:
[Icon: Spiral]
"The web connects all."
```

**At Cave Mouth:**
```
FRONT:
[Icon: Down arrow + Warning]
"THE DEEP"
"Not yet."

BACK:
[Icon: Up arrow + Sun]
"RETURN TO LIGHT"
```

### Ground Markings

Ancient carved stone markers:
- **Circle** = Water source
- **Triangle** = Danger
- **Spiral** = Lifeweave node
- **Footprints** = Migration route
- **Crossed lines** = Boundary/end

### Environmental Text (Minimal)

Cave paintings, carved stones with simple images — NOT words:
- Pictographs showing animals, water, connections
- Player interprets meaning
- No language barrier

---

## Visual & Auditory Pulls

### Drawing the Eye

**Landmarks visible from distance:**

| Landmark | Visible From | Pulls Player Toward |
|----------|--------------|---------------------|
| Ancient Tree | Anywhere in Basin | Central hub, story |
| Waterfall Vista | Multiple points | High ground, vista |
| Mushroom Glow | Night, from distance | Hidden area |
| The Spire | Anywhere in Driftplain | Lifeweave node |
| Oasis Palms | Across plains | Water, safety |
| Smoke from Caldera | Multiple places | Future content |

**Color contrast:**
- Important things are colored differently than surroundings
- Interactive objects have subtle glow/shimmer
- Lifeweave nodes pulse faintly

**Movement:**
- Animals moving toward something = follow them
- Water flowing = follow it
- Leaves/particles drifting toward points of interest

### Auditory Pulls

**Sounds that call the player:**

| Sound | Meaning | Distance |
|-------|---------|----------|
| Waterfall roar | Water source ahead | Far |
| Bird calls (specific) | Rookery nearby | Medium |
| Frog chorus | Marsh ecosystem | Medium |
| Wind whistle | High point ahead | Far |
| Humming/resonance | Lifeweave node | Close |
| Distressed animal | Event/opportunity | Medium |
| Music swell | Discovery imminent | Close |

**Silence as pull:**
- Quiet areas = something wrong OR something sacred
- Player notices absence and investigates

**NPC Calls:**
- Spirits sometimes call player's attention with non-verbal sounds
- Animals make sounds that suggest "follow me"

---

## Discovery Design

### How Players Find Things

**Concentric rings of discovery:**

```
OBVIOUS (Can't miss):
├── Main quest objectives
├── Primary NPCs
├── Major landmarks
└── Lifeweave Stones

NOTICEABLE (Attentive players find):
├── Environmental clues (tracks, bones, markings)
├── NPC hints that suggest exploration
├── Animals heading somewhere
└── Sounds drawing attention

HIDDEN (Explorers find):
├── Secret areas behind waterfalls, in caves
├── Night-only content
├── Rare species in obscure locations
└── Lore items

DEEP (Dedicated players find):
├── Connections between distant clues
├── Seasonal/time-based secrets
├── Full codex entries
└── Easter eggs
```

### Breadcrumb Design

Never more than 30 seconds between "something interesting":
- Seeds → plant → animal eating it
- Footprints → animal → nest
- Sound → source → discovery

### No Hand-Holding

- No minimap markers for objectives
- No "go here" arrows
- Field Journal records what you've SEEN, not what to DO
- NPCs give directions, not GPS

---

## Multiplayer Handling

### Philosophy

**Together but independent.**

Players in same place see each other. Each has their own ecosystem state. Actions don't conflict.

### How It Works

**Same Place:**
- See each other's avatars
- Can emote, communicate
- Each sees their own ecosystem state
- My actions don't affect your world (or vice versa)

**Why?**
- No griefing (can't mess up someone's ecosystem)
- Personal story (your choices matter to your world)
- Cooperation is social, not mechanical

**Party System:**
- Form party to travel together
- Party chat
- Can "share" discoveries (if I find something, you get a hint)
- Achievements can be party-wide

### Multiplayer Activities

**What you CAN do together:**
- Explore
- Find things (each gets credit)
- Share discoveries via chat
- Race to landmarks
- Take screenshots together
- Solve puzzles in parallel

**What you CANNOT do together:**
- Change each other's ecosystem
- Share inventory
- Complete each other's quests
- Compete directly

### Server Structure

- Each Place = one server
- Players phase in/out based on capacity
- Party members always same phase
- NPCs/Spirits visible to all

---

## Narrative Clarity

### Keeping Players Oriented

**The Field Journal:**
- Records what player has learned
- Tabs: Species, Places, Lore, Quests
- Quests show status but NOT objectives
- Player must remember what NPC said

**Keeper Reminders:**
- If player seems stuck (no progress for X time)
- Keeper offers gentle reminder via ambient whisper
- NOT a quest marker, just a hint

**Environmental Recaps:**
- Returning to a place: environmental cues show what changed
- NPCs acknowledge your actions
- World reflects your progress

### Story Through Environment

**Each Place tells its story visually:**

Verdant Basin:
- Overfull streams, aggressive birds = too much
- Empty otter dens = something missing
- Blocked exit = connection severed

Driftplain:
- Dry riverbeds, bones = not enough
- Animals at single water source = desperation
- Visible path to Basin = connection exists

### Player's Role in Narrative

**You are the lens, not the hero.**

- Story is about the world, not about you
- You discover, observe, nudge
- World would continue without you (just worse)
- Your reward is understanding, not glory

---

## Quest Flow Example

### "The Missing Otter" — Full Flow

**Step 1: Observe the Imbalance**
- TRIGGER: Player enters basin, first 5 minutes
- OBJECTIVE: Watch the ecosystem (hidden timer, ~3 minutes of being in world)
- PROMPT: Environmental (fish swarming, birds fighting)
- COMPLETE WHEN: Player observes fish OR birds closely (camera focus for 10 seconds)
- FEEDBACK: Field Journal updates, Keeper calls to player

**Step 2: Consult the Keeper**
- TRIGGER: Step 1 complete
- OBJECTIVE: Go to Ancient Tree, talk to Keeper
- PROMPT: Visual (Ancient Tree visible from anywhere), Audio (Keeper's call)
- COMPLETE WHEN: Dialogue finished
- FEEDBACK: Keeper mentions otters, Journal updates

**Step 3: Find Otter Signs**
- TRIGGER: Step 2 complete
- OBJECTIVE: Locate otter den (player must explore, no marker)
- PROMPT: NPC dialogue mentioned "follow the water"
- CLUES:
  - Old Mira says "near the reeds"
  - Scratch marks on trees along water
  - Empty shells (otter food) trail
- COMPLETE WHEN: Player enters otter den area
- FEEDBACK: Visual discovery, Journal updates with detailed otter entry

**Step 4: Discover the Blockage**
- TRIGGER: Step 3 complete
- OBJECTIVE: Find basin exit, understand the problem
- PROMPT: Otter tracks lead toward exit
- CLUES:
  - River flow visibly reduced at exit
  - Driftplain visible in distance (dusty, dry)
  - Sign at exit warns of dryness
- COMPLETE WHEN: Player examines blocked/reduced water flow
- FEEDBACK: Revelation dialogue, Driftplain unlocks

**Step 5: Clear the Path**
- TRIGGER: Visit Driftplain, complete "Scattered Herds" step 3
- OBJECTIVE: Find and clear the blockage between places
- LOCATION: Cave system between Basin and Driftplain
- REQUIRES: Understanding from BOTH places
- COMPLETE WHEN: Lifeweave node in cave activated
- FEEDBACK: Water flows, both ecosystems begin rebalancing

---

## Summary

| Aspect | Approach |
|--------|----------|
| Structure | Gated branching (not linear, not fully open) |
| Teleporting | Lifeweave Stones, unlocked by attuning, can always return |
| Quests | Main = required, Side = discoverable, Hidden = exploration |
| Backtracking | Yes, encouraged, world changed when you return |
| NPCs | Sparse, meaningful, location-based, cryptic but helpful |
| Multiplayer | See others, independent ecosystems, party travel |
| Pulls | Visual landmarks, audio cues, animal behavior |
| Discovery | Layered (obvious → hidden → deep) |
| Signposts | Double-sided, iconic, minimal text |
| Clarity | Field Journal records, environment shows, NPCs remind |
