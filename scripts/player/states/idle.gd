extends PlayerState
## Idle — standing still on the ground.


func physics_update(delta: float) -> void:
	# Apply gravity.
	if not player.is_on_floor():
		player.velocity.y -= _get_gravity() * delta
		# Fell off ledge → Float (coyote time is tracked there).
		player.state_machine.transition_to("float")
		return

	# Jump buffer / input.
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

	# Movement → Run.
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() > 0.1:
		player.state_machine.transition_to("run")
		return

	# Decelerate to stop.
	player.velocity.x = move_toward(player.velocity.x, 0.0, config.move_speed * delta * 10.0)
	player.velocity.z = move_toward(player.velocity.z, 0.0, config.move_speed * delta * 10.0)
	player.move_and_slide()


func _get_gravity() -> float:
	var base_gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	return base_gravity * config.gravity_scale
