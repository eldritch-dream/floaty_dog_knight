extends PlayerState
## Jump — launched upward, transitions to Float when falling.


func enter() -> void:
	player.velocity.y = config.jump_velocity
	player.coyote_timer = 0.0  # Used coyote time.
	player.jump_buffered = false


func physics_update(delta: float) -> void:
	var base_gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var gravity: float = base_gravity * config.gravity_scale
	player.velocity.y -= gravity * delta

	# Air control — camera-relative.
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() > 0.1:
		var cam_basis: Basis = player.camera_rig.global_transform.basis
		var forward: Vector3 = -cam_basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right: Vector3 = cam_basis.x
		right.y = 0.0
		right = right.normalized()
		var direction: Vector3 = (forward * -input_dir.y + right * input_dir.x).normalized()

		# High air control — directly blend toward desired direction.
		player.velocity.x = lerp(player.velocity.x, direction.x * config.move_speed, 0.15)
		player.velocity.z = lerp(player.velocity.z, direction.z * config.move_speed, 0.15)
	else:
		# Air friction when no input.
		player.velocity.x *= config.air_friction
		player.velocity.z *= config.air_friction

	# Air jump (double jump).
	if Input.is_action_just_pressed("jump") and player.air_jumps_remaining > 0:
		player.air_jumps_remaining -= 1
		player.velocity.y = config.jump_velocity
		# Stay in Jump state with fresh upward velocity.
		return

	# Dash in air.
	if Input.is_action_just_pressed("dash") and player.can_dash:
		player.state_machine.transition_to("dash")
		return

	# Transition to float when falling.
	if player.velocity.y < 0.0:
		player.state_machine.transition_to("float")
		return

	# Landed (edge case).
	if player.is_on_floor():
		_land()
		return

	player.move_and_slide()


func _land() -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() > 0.1:
		player.state_machine.transition_to("run")
	else:
		player.state_machine.transition_to("idle")
