extends PlayerState
## Dash — high-speed burst in facing direction. Works on ground and in air.

var _dash_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
## Track whether we were airborne when dash started.
var _was_airborne: bool = false


func enter() -> void:
	_dash_timer = config.dash_duration
	_was_airborne = not player.is_on_floor()
	player.can_dash = false
	player.dash_cooldown_timer = config.dash_cooldown

	# Dash in the direction the player is facing, or input direction if available.
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() > 0.1:
		var cam_basis: Basis = player.camera_rig.global_transform.basis
		var forward: Vector3 = -cam_basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right: Vector3 = cam_basis.x
		right.y = 0.0
		right = right.normalized()
		_dash_direction = (forward * -input_dir.y + right * input_dir.x).normalized()
	else:
		# Dash forward based on player's current facing.
		_dash_direction = -player.global_transform.basis.z
		_dash_direction.y = 0.0
		_dash_direction = _dash_direction.normalized()


func physics_update(delta: float) -> void:
	_dash_timer -= delta

	if _dash_timer <= 0.0:
		# Dash finished — choose next state.
		if player.is_on_floor():
			var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
			if input_dir.length() > 0.1:
				player.state_machine.transition_to("run")
			else:
				player.state_machine.transition_to("idle")
		else:
			player.state_machine.transition_to("float")
		return

	# During dash: override velocity, ignore gravity.
	player.velocity = _dash_direction * config.dash_speed
	# Zero vertical velocity during dash for clean horizontal movement.
	player.velocity.y = 0.0
	player.move_and_slide()


func exit() -> void:
	# Preserve some momentum after dash for smooth feel.
	player.velocity = _dash_direction * config.move_speed * 0.5
	if _was_airborne:
		player.velocity.y = -1.0  # Slight downward to not float weirdly.
