# World-Class Animated NPCs & Animals

Research on creating high-quality animated wildlife for Verdant Basin (2025).

## Overview

For an ecology simulation, animals need:
- Natural movement (walk, run, idle, eat, drink)
- Responsive behavior (flee, follow, flock)
- Smooth mesh deformation (no rigid robot joints)
- Performance at scale (dozens of animals on screen)

---

## Approach Options

### 1. Skinned Mesh + Blender Animation Pipeline

**What**: Model and rig animals in Blender, animate there, export FBX to Roblox.

**Workflow**:
1. Model animal in Blender (low-poly, ~1-5k tris)
2. Rig with armature (bones for spine, legs, head, tail)
3. Skin weights for smooth deformation
4. Animate: idle, walk, run, eat, drink, etc.
5. Export FBX (scale 0.01 to match Roblox units)
6. Import via AvatarImporter plugin → creates Bones + AnimationController
7. Play animations via Luau script

**Pros**:
- Full artistic control
- Smooth deformation with skinned meshes
- Professional quality possible

**Cons**:
- Time-intensive per animal
- Requires Blender skills
- Animation Editor import can be finicky

**Key Tips**:
- Use FBX 7.4 format
- Apply all transforms before export (Ctrl+A)
- No scale in animation data (Roblox limitation)
- Keep skeleton simple for performance

**Links**:
- [Skinned MeshParts Documentation](https://devforum.roblox.com/t/skinned-meshparts-are-live/831011)
- [Full Custom Mesh Deform Setup](https://devforum.roblox.com/t/fully-custom-mesh-deform-character-setup-skinned-meshes/1193941)
- [Blender FBX Scale Guide](https://www.katsbits.com/codex/fbx-scale-roblox/)

---

### 2. Mixamo / Mesh2Motion for Quick Animations

**What**: Use auto-rigging services to speed up animation.

**Mixamo** (Adobe):
- Web-based auto-rigger
- Large animation library
- Quadruped support limited (dogs, horses, wolves announced but patchy)
- Free tier available

**Mesh2Motion** (Open Source):
- Free alternative to Mixamo
- Supports quadrupeds (foxes, cats, horses)
- Supports birds/avians
- Better for animal variety

**Workflow**:
1. Upload mesh to service
2. Auto-rig or select skeleton
3. Apply animations from library
4. Download FBX
5. Import to Roblox

**Pros**:
- Fast iteration
- No manual rigging needed
- Large animation libraries

**Cons**:
- Less control than manual
- May not match art style
- Quadruped support still maturing

**Links**:
- [Mixamo to Roblox Tutorial](https://devforum.roblox.com/t/using-mixamo-to-make-easy-animations-for-skinned-meshes-a-full-tutorial-be-prepared-bug-fix-included/2644018)
- [Mesh2Motion (Mixamo Alternative)](https://gamefromscratch.com/mesh2motion-open-source-mixamo-alternative/)

---

### 3. Procedural Animation + Inverse Kinematics

**What**: Generate animation in real-time via code, not pre-baked.

**IKControl** (Official Roblox):
- Built-in IK system
- Target-based limb positioning
- Good for foot planting, head look-at

**Use Cases**:
- Feet conform to terrain slopes
- Head tracks player or prey
- Legs adjust to movement speed
- Tails react to turning

**Community Resources**:
- IKPF (Inverse Kinematics Procedural Footplanting) — discontinued but code available
- FABRIK-based IK solvers

**Pros**:
- Responsive to environment
- No animation for every scenario needed
- Natural-looking adaptation

**Cons**:
- Complex to implement
- CPU cost per animal
- Best combined with base animations

**Links**:
- [IKControl Documentation](https://create.roblox.com/docs/animation/inverse-kinematics)
- [Experimental IK Module](https://devforum.roblox.com/t/experimental-inverse-kinematic-and-procedural-animations/518798)
- [R15 IKPF System](https://devforum.roblox.com/t/free-r15-ikpf-system-inverse-kinematics-procedural-footplanting/706574)

---

### 4. Adaptive Animation (New 2025)

**What**: Roblox's new HumanoidRigDescription (HRD) enables animation sharing across rig types.

**Benefits**:
- Custom rigs can use R15 animation library
- R15 avatars can use custom rig animations
- Unified animation compatibility

**Status**: Studio Beta (announced December 2025)

**Links**:
- [Adaptive Animation Announcement](https://devforum.roblox.com/t/studio-beta-adaptive-animation-seamlessly-play-animations-across-various-rigs/4116008)

---

## AI Behavior Systems

### Pathfinding

**PathfindingService** (Official):
- A* algorithm with improvements (March 2025 update)
- Handles terrain, obstacles
- Waypoint-based navigation

**Key Methods**:
```lua
local path = PathfindingService:CreatePath({
    AgentRadius = 2,
    AgentHeight = 5,
    AgentCanJump = false,
})
path:ComputeAsync(start, goal)
```

### Behavior Frameworks

**Options** (simplest → most complex):

1. **Unstructured AI** — if/else chains, quick and dirty
2. **Finite State Machines (FSM)** — states like Idle, Wander, Flee, Eat
3. **Utility AI** — score-based decision making
4. **Behavior Trees** — hierarchical task nodes, most flexible

**For Ecology Simulation**:
- FSM for simple animals (insects, fish)
- Utility AI for complex animals (predators deciding hunt vs rest)
- Drives: hunger, thirst, fear, rest

### Community Resources

**NPC System V2** (October 2025):
- Production-ready, server-authoritative
- Client-side rendering optimization
- Advanced pathfinding + sight detection
- Built for scalability

**Links**:
- [Pathfinding Algorithm Improvements](https://devforum.roblox.com/t/improving-pathfinding-quality-with-new-algorithm/3258657)
- [AI Behavior Frameworks Tutorial](https://devforum.roblox.com/t/using-ai-behavior-frameworks-for-npcs/3482097)
- [NPC System V2](https://devforum.roblox.com/t/npc-system-v2-your-comprehensive-npc-system-for-your-roblox-game/4003818)
- [Advanced Roblox AI Techniques 2025](https://toxigon.com/advanced-roblox-ai-techniques)

---

## Performance at Scale

For hundreds of animals (ecosystem simulation):

### Rendering
- **LOD** (Level of Detail) — simpler meshes at distance
- **Client-side interpolation** — server sends sparse updates, client smooths
- **Hybrid rendering** — detailed animals near camera, billboards far

### Animation
- **Animation culling** — don't animate off-screen animals
- **Shared AnimationTracks** — reuse across same species
- **Simplified far animations** — idle only at distance

### Behavior
- **Spatial partitioning** — only process nearby animals fully
- **Staggered updates** — not all AI every frame
- **Flocking algorithms** — emergent group behavior from simple rules

---

## Inspiration: Existing Roblox Wildlife Games

| Game | Notable Features |
|------|------------------|
| **Wild Savanna** | Realistic African animals, predator-prey interactions |
| **Yellowstone Unleashed** | Large map, diverse species, ecosystem feel |
| **Creatures of Sonaria** | 100+ creatures, evolution system |
| **Savannah Life** | Pride mechanics, herd behavior |
| **Endangered World** | 100+ animals, rescue/conservation theme |

---

## Recommended Approach for Verdant Basin

### Verdant Basin (dense, interconnected)
- **Fish**: Simple FSM, schooling/flocking
- **Birds**: Procedural flight paths, perching IK
- **Mammals**: Utility AI (hunger/thirst drives to water sources)
- **Insects**: Particle-like, minimal individual AI

### Driftplain (harsh, migratory)
- **Herd animals**: Flocking + migration paths
- **Predators**: Utility AI, stalking behavior
- **Scavengers**: Follow predators, opportunistic

### Pipeline

```
Blender                    Roblox
───────                    ──────
Model (low-poly)    →      MeshPart
Rig (armature)      →      Bones
Animate             →      AnimationController
Export FBX 0.01     →      AvatarImporter plugin

Luau Code
─────────
AnimalController.luau      -- base class
BehaviorTree.luau          -- decision making
Flocking.luau              -- group movement
AnimalAnimator.luau        -- play animations based on state
```

### File Structure
```
src/
  server/
    Animals/
      AnimalSpawner.luau
      AnimalController.luau
      Behaviors/
        Idle.luau
        Wander.luau
        Flee.luau
        Eat.luau
        Drink.luau
        Flock.luau
  shared/
    AnimalConfig.luau       -- species definitions
    BehaviorTree.luau
assets/
  animals/
    deer/
      deer.fbx
      deer_idle.fbx
      deer_walk.fbx
      deer_run.fbx
```

---

## Sources

- [Skinned MeshParts](https://devforum.roblox.com/t/skinned-meshparts-are-live/831011)
- [WrapDeformer Instance](https://devforum.roblox.com/t/introducing-the-new-wrapdeformer-instance/3294953)
- [IKControl Documentation](https://create.roblox.com/docs/animation/inverse-kinematics)
- [Pathfinding Improvements 2025](https://devforum.roblox.com/t/improving-pathfinding-quality-with-new-algorithm/3258657)
- [AI Behavior Frameworks](https://devforum.roblox.com/t/using-ai-behavior-frameworks-for-npcs/3482097)
- [NPC System V2](https://devforum.roblox.com/t/npc-system-v2-your-comprehensive-npc-system-for-your-roblox-game/4003818)
- [Adaptive Animation Beta](https://devforum.roblox.com/t/studio-beta-adaptive-animation-seamlessly-play-animations-across-various-rigs/4116008)
- [Mixamo Roblox Tutorial](https://devforum.roblox.com/t/using-mixamo-to-make-easy-animations-for-skinned-meshes-a-full-tutorial-be-prepared-bug-fix-included/2644018)
- [Mesh2Motion Alternative](https://gamefromscratch.com/mesh2motion-open-source-mixamo-alternative/)
- [Blender Rig Exporter Plugin](https://devforum.roblox.com/t/blender-rig-exporteranimation-importer/34729)
