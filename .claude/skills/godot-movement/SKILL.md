# Skill: Godot Movement

**Triggered when**: asked to modify player movement, camera behaviour, or add new movement abilities.

---

## CharacterBody3D Movement Architecture

The player is a `CharacterBody3D` at `scenes/player/player.tscn`, scripted at `scripts/player/player.gd`.

All movement logic is **fully delegated to the StateMachine** — `player.gd` contains no per-frame movement math. The player script only:
- Ticks the stamina regen timer (`stats.tick(delta)`)
- Ticks the dash cooldown timer
- Resets `air_jumps_remaining` when `is_on_floor()` is true
- Counts down the jump buffer timer
- Routes mouse/gamepad input to `CameraRig`

Each state calls `player.move_and_slide()` itself at the end of its `physics_update`.

### Player state variables (used across states)

```gdscript
var can_dash: bool = true
var dash_cooldown_timer: float = 0.0
var coyote_timer: float = 0.0
var jump_buffered: bool = false
var jump_buffer_timer: float = 0.0
var air_jumps_remaining: int = 0   # reset to config.max_air_jumps on landing
var is_invincible: bool = false    # true during dodge roll i-frame window

# Resources
@export var config: GameConfig
@export var stats: PlayerStats
@export var ability_unlocks: AbilityUnlocks
```

### Camera-relative direction utility

`player.gd` exposes a `static` helper (usable from tests without instantiating a scene):

```gdscript
static func compute_camera_relative_direction(input: Vector2, camera_basis: Basis) -> Vector3
```

States compute movement direction inline using the same pattern:
```gdscript
var cam_basis: Basis = player.camera_rig.global_transform.basis
var forward := (-cam_basis.z).normalized()   # flatten Y
var right   := cam_basis.x.normalized()      # flatten Y
var direction := (forward * -input_dir.y + right * input_dir.x).normalized()
```

---

## GameConfig @export Parameters

All parameters live in `scripts/systems/game_config.gd`, resource at `resources/config/default_config.tres`.

### Movement
| Parameter | Current Value | Notes / Tuning Range |
|---|---|---|
| `move_speed` | `10.0` m/s | Ground and air target speed |

### Jump & Gravity
| Parameter | Current Value | Notes / Tuning Range |
|---|---|---|
| `jump_velocity` | `7.0` | Initial Y velocity on ground jump |
| `gravity_scale` | `1.4` | Multiplier on project gravity (9.8 m/s²) |
| `fall_multiplier` | `2.3` | Extra gravity when `velocity.y < 0` (Float state) |
| `air_friction` | `0.98` | Per-frame XZ velocity retention when no input, airborne |
| `float_drag` | `0.93` | Per-frame Y velocity retention in Float state (floaty feel) |
| `max_air_jumps` | `1` | Extra mid-air jumps (1 = double jump) |
| `air_jump_velocity` | `10.0` | Weaker than ground jump; upgradeable |

**Air jump gravity**: air jumps apply `gravity_scale * 1.5` (hardcoded multiplier in `jump.gd:22`) for a snappier arc.

**Double jump gate**: both `player.air_jumps_remaining > 0` **and** `ability_unlocks.double_jump_unlocked` must be true. Checking only `air_jumps_remaining` allows double-jumping regardless of the unlock flag.

**Jump buffer and double jump lock**: when `double_jump_unlocked == false`, pressing jump while airborne does **not** set `jump_buffered`. Only players who have the ability (but have exhausted their air jumps) get the landing buffer. This prevents the "rapid-tap creates a second ground jump" bug.

### Dash
| Parameter | Current Value | Notes / Tuning Range |
|---|---|---|
| `dash_speed` | `25.0` m/s | Burst speed during dash |
| `dash_duration` | `0.2` s | How long the dash lasts |
| `dash_cooldown` | `0.8` s | Cooldown before next dash |

Dash distance = `dash_speed × dash_duration` = **5.0 m**.
During dash: gravity is zeroed, `velocity.y = 0.0`.
On exit: momentum preserved as `_dash_direction * move_speed * 0.5`; if airborne, `velocity.y = -1.0`.

### Input Buffers
| Parameter | Current Value | Notes / Tuning Range |
|---|---|---|
| `coyote_time` | `0.15` s | Jump grace period after leaving a ledge |
| `jump_buffer_time` | `0.1` s | Jump press remembered before landing |

### Camera
| Parameter | Current Value | Notes / Tuning Range |
|---|---|---|
| `camera_distance` | `5.0` m | SpringArm3D spring length |
| `camera_height` | `2.0` m | SpringArm3D Y offset above player pivot |
| `camera_sensitivity` | `0.003` rad/px | Mouse look speed |
| `camera_pitch_min` | `-60.0°` | Looking up limit |
| `camera_pitch_max` | `30.0°` | Looking down limit |
| `gamepad_camera_sensitivity` | `3.0` | Right-stick speed multiplier |

### Stamina
| Parameter | Current Value | Notes |
|---|---|---|
| `stamina_regen_rate` | `20.0` /s | Base rate — copied to `PlayerStats.stamina_regen_rate` at startup; increases on level-up |
| `stamina_regen_delay` | `1.2` s | Pause before regen starts after spending stamina |

### Dodge
| Parameter | Current Value | Notes |
|---|---|---|
| `i_frame_duration` | `0.4` s | Invincibility window during dodge roll |
| `dodge_stamina_cost` | `25.0` | Stamina spent per dodge |
| `dodge_distance` | `4.0` m | Roll distance; speed derived as `distance / (distance / 12.0)` = 12 m/s |

### Combat
| Parameter | Current Value | Notes |
|---|---|---|
| `light_attack_stamina_cost` | `15.0` | Stamina per light swing |
| `heavy_attack_stamina_cost` | `30.0` | Stamina per heavy swing |
| `light_attack_damage` | `10.0` | Base light damage |
| `heavy_attack_damage` | `25.0` | Base heavy damage |
| `hitbox_active_frames_light` | `8` | 60-fps frames the light hitbox stays open |
| `hitbox_active_frames_heavy` | `14` | 60-fps frames the heavy hitbox stays open |

### Progression
| Parameter | Current Value | Notes |
|---|---|---|
| `xp_base` | `100` | XP required at level 1 |
| `xp_exponent` | `1.5` | `xp_required = int(xp_base * pow(level, xp_exponent))` |

---

## SpringArm3D Camera Rig

File: `scripts/player/camera_rig.gd`, class `CameraRig`.

```
Player (CharacterBody3D)
└── CameraRig (Node3D)          ← top_level = true (set in setup(), NOT in scene)
    └── SpringArm3D             ← spring_length = config.camera_distance (5.0)
                                   position.y   = config.camera_height   (2.0)
        └── Camera3D
```

`top_level = true` is set programmatically in `setup()` so the rig does **not** inherit the player's Y rotation. It manually follows the player's `global_position` each `_physics_process` tick.

**Mouse**: `handle_mouse_input(event)` — yaw rotates the whole CameraRig, pitch stored in `_pitch` and applied to `SpringArm3D.rotation.x`, clamped to `[camera_pitch_min, camera_pitch_max]`.

**Gamepad**: `handle_gamepad_look(delta)` called from `player._physics_process`, reads axes `camera_look_left/right/up/down` with 0.1 deadzone.

---

## PlayerStateMachine States and Transitions

### States

| State node | Script | Entry condition |
|---|---|---|
| `Idle` | `states/idle.gd` | Default / landing with no input |
| `Run` | `states/run.gd` | Stick/WASD input while grounded |
| `Jump` | `states/jump.gd` | Jump pressed (ground or coyote or air) |
| `Float` | `states/float.gd` | Fell off ledge, or descending after jump peak |
| `Dash` | `states/dash.gd` | Dash pressed + `can_dash == true` |
| `Dodge` | `states/dodge.gd` | Dodge pressed + `ability_unlocks.dodge_unlocked` + stamina ≥ cost |
| `LightAttack` | `states/light_attack.gd` | Attack pressed + `ability_unlocks.light_attack_unlocked` + stamina ≥ cost |
| `HeavyAttack` | `states/heavy_attack.gd` | Heavy attack pressed + `ability_unlocks.heavy_attack_unlocked` + stamina ≥ cost |

### Valid transitions (as coded)

```
Idle  → Run   (input detected)
Idle  → Jump  (jump pressed or jump_buffered)
Idle  → Dash  (dash pressed + can_dash)
Idle  → Float (not on floor — fell off)

Run   → Idle  (no input)
Run   → Jump  (jump pressed or jump_buffered)
Run   → Dash  (dash pressed + can_dash)
Run   → Float (left ground without jumping — sets coyote_timer)

Jump  → Float (velocity.y < 0)
Jump  → Dash  (dash pressed + can_dash)
Jump  → Run   (landed with input)
Jump  → Idle  (landed with no input)
Jump  → Jump  (air jump: decrements air_jumps_remaining, re-enters Jump state)

Float → Jump  (coyote window + jump pressed, OR air_jumps_remaining > 0)
Float → Dash  (dash pressed + can_dash)
Float → Run   (landed with input, no buffered jump)
Float → Idle  (landed with no input, no buffered jump)
Float → Jump  (landed with buffered jump)

Dash  → Run   (timer expired + on floor + input)
Dash  → Idle  (timer expired + on floor + no input)
Dash  → Float (timer expired + not on floor)

Dodge      → Run / Idle / Float  (roll timer expired, same floor check as Dash)
LightAttack → Run / Idle / Float  (ComboSystem emits attack_ended)
HeavyAttack → Run / Idle / Float  (ComboSystem emits attack_ended)
```

Dodge, LightAttack, and HeavyAttack are reachable from **Idle, Run, Jump, and Float** — any state that processes input. The gate is always checked in the *calling* state, not in the target state's `enter()`.

**Invalid transitions**: `StateMachine.transition_to()` silently prints a warning and keeps the current state if the target name does not exist in the `states` dictionary.

**State name lowercasing**: the StateMachine registers nodes as `child.name.to_lower()`. Use `"lightattack"` and `"heavyattack"` (no underscore) when calling `transition_to()`.

**Stale `is_on_floor()` guard**: `Run` returns before calling `move_and_slide()` when jumping, leaving `is_on_floor()` stale-true on Jump's first frame. Jump's landed check uses `player.is_on_floor() and player.velocity.y <= 0.0` to prevent a false landing detection that would otherwise chain back through Run's coyote timer for an unchecked second jump.

---

## Rule

> **Never change movement feel without updating regression tests and getting a sign-off comment in the PR.**

Any change to GameConfig defaults, gravity arithmetic, jump velocity, dash distance, or air control lerp factor must be accompanied by updated baseline values in `tests/unit/test_movement_regression.gd` **and** in the `@export` default in `game_config.gd` (the test uses `GameConfig.new()`, which reads script defaults, not the `.tres` file).

Three places must stay in sync: `game_config.gd` default → `default_config.tres` value → `test_movement_regression.gd` baseline constant.
