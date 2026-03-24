# Skill: Godot Conventions

**Triggered when**: creating a new scene, script, or node structure.

---

## Project Folder Structure (as it exists)

```
floaty_dog_knight/
├── .claude/
│   └── skills/
│       ├── godot-movement/SKILL.md
│       ├── gut-testing/SKILL.md
│       ├── git-workflow/SKILL.md
│       └── godot-conventions/SKILL.md
├── .gutconfig.json
├── addons/
│   └── gut/                    ← GUT test framework (do not edit)
├── assets/
│   ├── audio/
│   │   ├── sfx/                ← placeholder .wav files (one per SOUNDS dict entry)
│   │   └── music/              ← music tracks (empty until music added)
│   ├── models/                 ← empty, .gdkeep placeholder
│   └── textures/               ← empty, .gdkeep placeholder
├── tools/
│   └── generate_placeholder_audio.gd  ← @tool EditorScript, run once to regenerate placeholders
├── resources/
│   ├── config/
│   │   └── default_config.tres ← GameConfig resource (the canonical tuning file)
│   ├── stats/
│   │   └── default_stats.tres  ← PlayerStats defaults
│   └── unlocks/
│       └── default_unlocks.tres ← AbilityUnlocks defaults (all locked)
├── run_tests.ps1               ← Windows test runner
├── scenes/
│   ├── combat/                 ← HitBox.tscn / HurtBox.tscn prefabs go here
│   ├── collectibles/           ← XPOrb.tscn goes here
│   ├── player/
│   │   └── player.tscn         ← CharacterBody3D player scene
│   ├── ui/                     ← empty, .gdkeep placeholder
│   └── world/
│       ├── hub.tscn            ← home base / owner NPC / portal to zone_01
│       ├── zone_01.tscn        ← first zone (placeholder)
│       └── test_room.tscn      ← movement sandbox (main scene during dev)
├── scripts/
│   ├── new_test.sh             ← scaffold helper for new test files
│   ├── collectibles/
│   │   └── xp_orb.gd
│   ├── combat/
│   │   ├── hit_box.gd          ← Area3D; activate()/deactivate() per swing
│   │   ├── hurt_box.gd         ← Area3D; receive_hit() → stats.take_damage()
│   │   ├── sword.gd            ← extends WeaponBase; HitBox child = "HitBox"
│   │   └── weapon_base.gd      ← abstract base; attack_light/heavy/deactivate_hitbox
│   ├── npc/
│   │   └── npc_base.gd         ← base NPC class; interact() virtual
│   ├── player/
│   │   ├── camera_rig.gd
│   │   ├── player.gd
│   │   ├── player_state.gd
│   │   ├── state_machine.gd
│   │   └── states/
│   │       ├── dash.gd
│   │       ├── death.gd        ← terminal state; emits player_died signal
│   │       ├── dodge.gd        ← combat dodge roll with i-frames
│   │       ├── float.gd
│   │       ├── heavy_attack.gd
│   │       ├── idle.gd
│   │       ├── jump.gd
│   │       ├── light_attack.gd
│   │       └── run.gd
│   ├── systems/
│   │   ├── ability_unlocks.gd  ← @export bools for each ability
│   │   ├── combo_system.gd     ← manages hitbox active-frame windows
│   │   ├── game_config.gd
│   │   ├── player_stats.gd     ← health, stamina, XP/leveling + signals
│   │   ├── respawn_manager.gd  ← autoload: freeze→wait→heal→travel on death
│   │   ├── save_data.gd        ← RefCounted snapshot: capture/apply/to_dict/from_dict
│   │   ├── save_manager.gd     ← autoload: save/load/delete; web + desktop storage
│   │   └── world_manager.gd    ← autoload: travel_to(scene, spawn_point)
│   └── world/
│       └── portal.gd           ← Area3D trigger → WorldManager.travel_to()
├── SKILLS.md
└── tests/
    ├── unit/
    │   ├── test_camera_movement.gd
    │   ├── test_coyote_time.gd
    │   ├── test_dash_cooldown.gd
    │   ├── test_jump_arc.gd
    │   └── test_state_transitions.gd
    └── integration/            ← empty, .gdkeep placeholder
```

---

## Naming Conventions (confirmed from codebase)

| Thing | Convention | Example |
|---|---|---|
| Scene files | snake_case | `player.tscn`, `test_room.tscn` |
| Script files | snake_case | `player.gd`, `camera_rig.gd`, `game_config.gd` |
| Node names in scenes | PascalCase | `StateMachine`, `CameraRig`, `SpringArm3D`, `Camera3D` |
| State node names | PascalCase | `Idle`, `Run`, `Jump`, `Float`, `Dash` |
| GDScript classes | PascalCase (`class_name`) | `GameConfig`, `StateMachine`, `CameraRig`, `PlayerState` |
| Variables / functions | snake_case | `move_speed`, `physics_update`, `can_dash` |
| Constants | SCREAMING_SNAKE | (none yet, but follow this when adding) |
| Test files | `test_` prefix + snake_case | `test_jump_arc.gd` |

---

## Autoloads

| Autoload name | Script | Responsibility |
|---|---|---|
| `WorldManager` | `scripts/systems/world_manager.gd` | Scene transitions via `travel_to(scene_path, spawn_point)` |
| `RespawnManager` | `scripts/systems/respawn_manager.gd` | Death sequence: freeze → wait → heal → travel to hub |
| `SaveManager` | `scripts/systems/save_manager.gd` | Persist/restore player state; web (localStorage) + desktop (FileAccess) |
| `DreamManager` | `scripts/systems/dream_manager.gd` | Dog Bed enter/exit dream flow; sole entry point for dream state |
| `AudioManager` | `scripts/systems/audio_manager.gd` | All audio playback; sole owner of audio file paths (see audio skill doc) |

Config, stats, and unlocks are **not** autoloaded — they are distributed explicitly via `@export` on the Player node.

> **Rule**: Autoloads must NOT have `class_name` — the autoload name itself IS the global identifier. Adding `class_name` creates a naming conflict in tests.

---

## Web Export Type Inference

The Godot web export (WASM) is stricter than the desktop runtime about `:=` type inference.

> **Rule**: Never use `:=` on compound boolean expressions. Always use an explicit `: bool =` annotation.

```gdscript
# BAD — fails to parse in web export
var can_air_jump := player.air_jumps_remaining > 0 and ability_unlocks.double_jump_unlocked

# GOOD
var can_air_jump: bool = player.air_jumps_remaining > 0 and ability_unlocks.double_jump_unlocked
```

This applies to any expression mixing comparison operators (`>`, `<`, `==`) with `and`/`or`. Simple single-operator booleans (e.g. `var x := foo > 0`) may work but explicit typing is safer throughout.

---

## Resource Pattern

### GameConfig
- Class: `scripts/systems/game_config.gd` (`class_name GameConfig`, `extends Resource`)
- Canonical instance: `resources/config/default_config.tres`
- Assigned to Player via `@export var config: GameConfig` in Inspector
- Distributed in `player._ready()`: `state_machine.set_config(config)`, `camera_rig.setup(...)`
- **All tunable values go here. No magic numbers anywhere in scripts.**

### PlayerStats
- Class: `scripts/systems/player_stats.gd` (`class_name PlayerStats`, `extends Resource`)
- Canonical instance: `resources/stats/default_stats.tres`
- Assigned via `@export var stats: PlayerStats`; `stamina_regen_rate` initialised from `config` in `player._ready()`
- Provides: `spend_stamina()`, `tick(delta)`, `take_damage()`, `heal()`, `gain_xp()`; emits `health_changed`, `stamina_changed`, `died`, `leveled_up`

### AbilityUnlocks
- Class: `scripts/systems/ability_unlocks.gd` (`class_name AbilityUnlocks`, `extends Resource`)
- Canonical instance: `resources/unlocks/default_unlocks.tres` (all `false` by default)
- Assigned via `@export var ability_unlocks: AbilityUnlocks`
- Contains bool flags: `double_jump_unlocked`, `dash_unlocked`, `dodge_unlocked`, `light_attack_unlocked`, `heavy_attack_unlocked`
- States read unlocks directly: `ability_unlocks.dodge_unlocked` — no signals

### Decoupling rule
> **PlayerStats never references GameConfig.** Base values are copied once in `player._ready()`. States pass primitive arguments (`base_xp: int`, `xp_exponent: float`) from config rather than the resource object.

---

## Node Naming Inside Scenes

### `scenes/player/player.tscn`

```
Player              (CharacterBody3D, collision_layer=4, collision_mask=1)
├── CollisionShape3D    (CapsuleShape3D r=0.35 h=0.9, offset y=0.45)
├── MeshInstance3D      (CapsuleMesh, tan/corgi colour #D9A566, offset y=0.45)
├── CameraRig           (Node3D, script=camera_rig.gd)
│   └── SpringArm3D     (spring_length=5.0, position.y=2.0, collision_mask=1)
│       └── Camera3D
├── ComboSystem         (Node, script=combo_system.gd)
├── PawWeapon           (Node3D, script=weapon_base.gd, offset y=0.45)
│   └── HitBox          (Area3D, script=hit_box.gd)
│       ├── CollisionShape3D  (SphereShape3D r=1.0)
│       └── DebugMesh   (MeshInstance3D, visible=false — shown during attack window)
├── HurtBox             (Area3D, script=hurt_box.gd, offset y=0.45)
│   └── CollisionShape3D  (CapsuleShape3D r=0.35 h=0.9)
└── StateMachine        (Node, script=state_machine.gd, initial_state=NodePath("Idle"))
    ├── Idle / Run / Jump / Float / Dash
    ├── Death           (Node, script=states/death.gd)
    ├── Dodge           (Node, script=states/dodge.gd)
    ├── LightAttack     (Node, script=states/light_attack.gd)
    └── HeavyAttack     (Node, script=states/heavy_attack.gd)
```

`player._ready()` wires: `combo_system.weapon = PawWeapon`, `weapon.hit_box = PawWeapon/HitBox`, `hurt_box.owner_node = self`, `hurt_box.stats = stats`.

Player `config`, `stats`, and `ability_unlocks` must all be assigned in the Inspector or via a parent scene. Currently assigned via `hub.tscn` and `zone_01.tscn`.

---

## Animation Rule

> **Use `Tween` for simple one-shot procedural animations (scale pulses, flashes, position pops). Do not use `AnimationPlayer` until a full animation system is added.**

`AnimationPlayer` requires named animations, clip management, and a node reference — overkill for a single-use effect. `create_tween()` is fire-and-forget and self-cleans.

---

## World Geometry Rule

> **CSG primitives are fine for world geometry during development.**
> Mark all CSG nodes with a `# TODO: art pass` comment in the scene or a descriptive node name like `CSGBox_Floor_TODO`.

This convention avoids blocking gameplay development on art assets.

---

## Input Actions (registered in project.godot)

| Action | Keyboard | Gamepad |
|---|---|---|
| `move_forward` | W | Left stick up |
| `move_back` | S | Left stick down |
| `move_left` | A | Left stick left |
| `move_right` | D | Left stick right |
| `jump` | Space | Button 0 (A/Cross) |
| `dash` | Shift | Button 1 (B/Circle) |
| `attack` | Left mouse | Button 10 (R1/RB) |
| `dodge` | Q | Button 9 (LB/L1) |
| `heavy_attack` | Right mouse | Axis 5 (R2/RT) |
| `camera_look_right` | — | Right stick right (axis 2) |
| `camera_look_left` | — | Right stick left (axis 2) |
| `camera_look_up` | — | Right stick up (axis 3) |
| `camera_look_down` | — | Right stick down (axis 3) |
