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
@export var jump_velocity: float = 14.5
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
