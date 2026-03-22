class_name GameConfig
extends Resource
## Master configuration resource for all tunable gameplay parameters.
## Attach to player via @export and tweak in the editor or .tres file.
## No magic numbers — every tunable value lives here.

# ── Movement ──────────────────────────────────────────────────────────
@export_group("Movement")
## Horizontal movement speed (m/s).
@export var move_speed: float = 10.0

# ── Jump & Gravity ───────────────────────────────────────────────────
@export_group("Jump & Gravity")
## Initial upward velocity when jumping.
@export var jump_velocity: float = 7.0
## Multiplier applied to project gravity. Higher = heavier feel.
@export var gravity_scale: float = 1.4
## Extra gravity multiplier when falling (velocity.y < 0).
@export var fall_multiplier: float = 2.3
## Per-frame velocity retention while airborne (0-1). 1 = no friction.
@export var air_friction: float = 0.98
## Drag applied during the float state to slow descent. Lower = floatier.
@export var float_drag: float = 0.93
## Number of extra air jumps allowed (1 = double jump, 2 = triple, etc.).
@export var max_air_jumps: int = 1
## Upward velocity for air jumps (weaker than ground jump, upgradeable).
@export var air_jump_velocity: float = 10.0

# ── Dash ─────────────────────────────────────────────────────────────
@export_group("Dash")
## Speed during a dash burst (m/s).
@export var dash_speed: float = 25.0
## How long the dash lasts (seconds).
@export var dash_duration: float = 0.2
## Cooldown before another dash is available (seconds).
@export var dash_cooldown: float = 0.8

# ── Input Buffers ────────────────────────────────────────────────────
@export_group("Input Buffers")
## Grace period after leaving a ledge where jump is still allowed (seconds).
@export var coyote_time: float = 0.15
## Window in which a jump press is remembered before landing (seconds).
@export var jump_buffer_time: float = 0.1

# ── Camera ───────────────────────────────────────────────────────────
@export_group("Camera")
## SpringArm3D length — distance behind the player (meters).
@export var camera_distance: float = 5.0
## Height offset of the camera above the player pivot (meters).
@export var camera_height: float = 2.0
## Mouse/stick sensitivity for camera rotation (radians per pixel).
@export var camera_sensitivity: float = 0.003
## Minimum pitch angle in degrees (looking up).
@export var camera_pitch_min: float = -60.0
## Maximum pitch angle in degrees (looking down).
@export var camera_pitch_max: float = 30.0
## Right-stick sensitivity multiplier for gamepad camera.
@export var gamepad_camera_sensitivity: float = 3.0

# ── Stamina ───────────────────────────────────────────────────────────
@export_group("Stamina")
## Base stamina regenerated per second (starting value for PlayerStats).
@export var stamina_regen_rate: float = 20.0
## Seconds after spending stamina before regen resumes (stamina tax).
@export var stamina_regen_delay: float = 1.2

# ── Dodge ─────────────────────────────────────────────────────────────
@export_group("Dodge")
## Duration of the invincibility window during a dodge roll (seconds).
@export var i_frame_duration: float = 0.4
## Stamina cost to execute a dodge roll.
@export var dodge_stamina_cost: float = 25.0
## Distance covered during a dodge roll (meters).
@export var dodge_distance: float = 4.0

# ── Combat ────────────────────────────────────────────────────────────
@export_group("Combat")
## Stamina cost for a light attack.
@export var light_attack_stamina_cost: float = 15.0
## Stamina cost for a heavy attack.
@export var heavy_attack_stamina_cost: float = 30.0
## Base damage dealt by a light attack.
@export var light_attack_damage: float = 10.0
## Base damage dealt by a heavy attack.
@export var heavy_attack_damage: float = 25.0
## Frames (at 60 fps) the light attack hitbox is active.
@export var hitbox_active_frames_light: int = 8
## Frames (at 60 fps) the heavy attack hitbox is active.
@export var hitbox_active_frames_heavy: int = 14

# ── Progression ───────────────────────────────────────────────────────
@export_group("Progression")
## Base XP required to level up (xp_required = xp_base * level ^ xp_exponent).
@export var xp_base: int = 100
## Exponent of the XP curve. Higher = steeper level-up costs.
@export var xp_exponent: float = 1.5

# ── Respawn ───────────────────────────────────────────────────────────────
@export_group("Respawn")
## Total seconds from death to scene transition (includes 0.3 s freeze).
## Set longer than the future death animation duration when animations are added.
@export var death_respawn_delay: float = 1.5
## Fraction of max health restored on respawn (1.0 = full, 0.5 = half).
@export var respawn_health_percent: float = 1.0

# ── Wisp Enemy ────────────────────────────────────────────────────────────
@export_group("Wisp Enemy")
## Maximum health of the Eldritch Wisp.
@export var wisp_max_health: float = 35.0
## Damage dealt per swipe attack.
@export var wisp_damage: float = 15.0
## Radius at which the Wisp detects the player and begins chasing.
@export var wisp_aggro_range: float = 8.0
## Radius at which the Wisp begins its attack wind-up.
@export var wisp_attack_range: float = 2.0
## Chase movement speed (m/s).
@export var wisp_move_speed: float = 4.0
## Patrol drift speed (m/s).
@export var wisp_patrol_speed: float = 2.0
## Radius around spawn point the Wisp patrols within.
@export var wisp_patrol_radius: float = 5.0
## Seconds the Wisp telegraphs its attack before the hitbox activates.
@export var wisp_windup_duration: float = 0.8
## Frames (at 60 fps) the attack hitbox is active.
@export var wisp_attack_active_frames: int = 12
## Seconds the Wisp is frozen after being hit.
@export var wisp_stagger_duration: float = 0.4
## Fixed height above spawn Y the Wisp floats at.
@export var wisp_float_height: float = 0.5
## XP awarded to the player when the Wisp dies.
@export var wisp_xp_reward: int = 20
