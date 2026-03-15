extends CharacterBody3D
## Player controller — the dog knight. All logic delegated to StateMachine.
## Exports GameConfig resource for inspector tuning.

@export var config: GameConfig

## Node references — set in _ready.
var state_machine: StateMachine
var camera_rig: CameraRig

# ── Dash state ───────────────────────────────────────────────────────
## Whether the player can currently dash (cooldown expired).
var can_dash: bool = true
## Time remaining on dash cooldown.
var dash_cooldown_timer: float = 0.0

# ── Jump helpers ─────────────────────────────────────────────────────
## Remaining coyote-time window (set when running off a ledge).
var coyote_timer: float = 0.0
## Whether a jump has been buffered (pressed slightly before landing).
var jump_buffered: bool = false
## Time remaining for the jump buffer to stay valid.
var jump_buffer_timer: float = 0.0


func _ready() -> void:
	# Capture mouse for FPS-style camera.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Grab node references.
	state_machine = $StateMachine as StateMachine
	camera_rig = $CameraRig as CameraRig

	# Pass config to systems.
	if config:
		state_machine.set_config(config)
		camera_rig.setup(config, $CameraRig/SpringArm3D as SpringArm3D)
	else:
		push_warning("Player: No GameConfig assigned!")


func _unhandled_input(event: InputEvent) -> void:
	# Mouse look.
	if event is InputEventMouseMotion:
		camera_rig.handle_mouse_input(event as InputEventMouseMotion)

	# Toggle mouse capture with Escape.
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	# Gamepad camera look.
	camera_rig.handle_gamepad_look(delta)

	# Dash cooldown.
	if not can_dash:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0.0:
			can_dash = true
			dash_cooldown_timer = 0.0

	# Jump buffer countdown.
	if jump_buffered:
		jump_buffer_timer -= delta
		if jump_buffer_timer <= 0.0:
			jump_buffered = false

	# State machine handles the rest (movement, gravity, state transitions).
	# It calls physics_update on the current state automatically.


## Helper: compute camera-relative movement direction from input.
## Exposed as a static-like utility for tests.
static func compute_camera_relative_direction(input: Vector2, camera_basis: Basis) -> Vector3:
	if input.length() < 0.01:
		return Vector3.ZERO
	var forward := -camera_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera_basis.x
	right.y = 0.0
	right = right.normalized()
	return (forward * -input.y + right * input.x).normalized()
