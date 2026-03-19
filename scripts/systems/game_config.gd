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
