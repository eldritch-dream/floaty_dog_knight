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
│   ├── audio/                  ← empty, .gdkeep placeholder
│   ├── models/                 ← empty, .gdkeep placeholder
│   └── textures/               ← empty, .gdkeep placeholder
├── resources/
│   └── config/
│       └── default_config.tres ← GameConfig resource (the canonical tuning file)
├── run_tests.ps1               ← Windows test runner
├── scenes/
│   ├── player/
│   │   └── player.tscn         ← CharacterBody3D player scene
│   ├── ui/                     ← empty, .gdkeep placeholder
│   └── world/
│       └── test_room.tscn      ← main scene / dev sandbox
├── scripts/
│   ├── new_test.sh             ← scaffold helper for new test files
│   ├── autoloads/              ← empty, .gdkeep — no autoloads yet
│   ├── player/
│   │   ├── camera_rig.gd
│   │   ├── player.gd
│   │   ├── player_state.gd
│   │   ├── state_machine.gd
│   │   └── states/
│   │       ├── dash.gd
│   │       ├── float.gd
│   │       ├── idle.gd
│   │       ├── jump.gd
│   │       └── run.gd
│   └── systems/
│       └── game_config.gd
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

**None currently registered.** The `scripts/autoloads/` directory exists but is empty.

Config is distributed explicitly: `player.gd` holds `@export var config: GameConfig` and passes it to `StateMachine` and `CameraRig` in `_ready()`.

When adding an autoload:
1. Register it in `project.godot` under `[autoload]`
2. Document it here with its responsibilities

---

## GameConfig Resource Pattern

- Class defined at `scripts/systems/game_config.gd` (`class_name GameConfig`, `extends Resource`)
- Canonical instance: `resources/config/default_config.tres`
- Assigned to Player node via `@export var config: GameConfig` in the Inspector
- Distributed to all systems in `player._ready()`:
  ```gdscript
  state_machine.set_config(config)
  camera_rig.setup(config, $CameraRig/SpringArm3D)
  ```
- **All tunable values go here. No magic numbers anywhere in scripts.**

---

## Node Naming Inside Scenes

### `scenes/player/player.tscn`

```
Player              (CharacterBody3D, script=player.gd)
├── CollisionShape3D    (CapsuleShape3D r=0.35 h=0.9, offset y=0.45)
├── MeshInstance3D      (CapsuleMesh, tan/corgi colour #D9A566, offset y=0.45)
├── CameraRig           (Node3D, script=camera_rig.gd)
│   └── SpringArm3D     (spring_length=5.0, position.y=2.0)
│       └── Camera3D
└── StateMachine        (Node, script=state_machine.gd, initial_state=NodePath("Idle"))
    ├── Idle            (Node, script=states/idle.gd)
    ├── Run             (Node, script=states/run.gd)
    ├── Jump            (Node, script=states/jump.gd)
    ├── Float           (Node, script=states/float.gd)
    └── Dash            (Node, script=states/dash.gd)
```

Player `config` is **not assigned in the scene file** — it must be set in the Inspector or via a parent scene/world that instantiates the player. Currently assigned via `test_room.tscn`.

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
| `attack` | Left mouse | Button 2 (X/Square) |
| `camera_look_right` | — | Right stick right (axis 2) |
| `camera_look_left` | — | Right stick left (axis 2) |
| `camera_look_up` | — | Right stick up (axis 3) |
| `camera_look_down` | — | Right stick down (axis 3) |
