extends PlayerState
## Run — moving on the ground at full speed.


func physics_update(delta: float) -> void:
	# Apply gravity.
	if not player.is_on_floor():
		player.velocity.y -= _get_gravity() * delta
		# Left the ground without jumping → Float (coyote time starts).
		player.coyote_timer = config.coyote_time
		player.state_machine.transition_to("float")
		return

	# Jump.
	if player.jump_buffered or Input.is_action_just_pressed("jump"):
		player.jump_buffered = false
		player.state_machine.transition_to("jump")
		return

	# Dash.
	if Input.is_action_just_pressed("dash") and player.can_dash:
		player.state_machine.transition_to("dash")
		return

	if _handle_combat_input():
		return

	# Get camera-relative input.
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if input_dir.length() < 0.1:
		player.state_machine.transition_to("idle")
		return

	# Camera-relative direction.
	var cam_basis: Basis = player.camera_rig.global_transform.basis
	var forward: Vector3 = -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var direction: Vector3 = (forward * -input_dir.y + right * input_dir.x).normalized()
	player.velocity.x = direction.x * config.move_speed
	player.velocity.z = direction.z * config.move_speed

	# Rotate player to face movement direction.
	if direction.length() > 0.01:
		var target_angle: float = atan2(direction.x, direction.z)
		player.rotation.y = lerp_angle(player.rotation.y, target_angle, 0.2)

	player.move_and_slide()


func _get_gravity() -> float:
	var base_gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	return base_gravity * config.gravity_scale
