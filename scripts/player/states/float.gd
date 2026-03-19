extends PlayerState
## Float — airborne falling state. Floaty descent with high air control.


func enter() -> void:
	# If we didn't come from Jump (i.e. walked off ledge), coyote timer was set in Run.
	pass


func physics_update(delta: float) -> void:
	# Enhanced gravity when falling (fall_multiplier).
	var base_gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
	var gravity: float = base_gravity * config.gravity_scale * config.fall_multiplier
	player.velocity.y -= gravity * delta

	# Float drag slows the descent for that floaty feel.
	player.velocity.y *= config.float_drag

	# Coyote time — still allow jump shortly after leaving ground.
	if player.coyote_timer > 0.0:
		player.coyote_timer -= delta
		if Input.is_action_just_pressed("jump") or player.jump_buffered:
			player.jump_buffered = false
			player.state_machine.transition_to("jump")
			return

	# Buffer jump press for when we land.
	if Input.is_action_just_pressed("jump") and player.coyote_timer <= 0.0:
		# Air jump if available.
		if player.air_jumps_remaining > 0 and ability_unlocks.double_jump_unlocked:
			player.air_jumps_remaining -= 1
			player.jump_buffered = false
			player.state_machine.transition_to("jump")
			return
		# Buffer for landing only when double jump is unlocked but out of uses.
		# When locked entirely the press was a failed double-jump attempt — don't buffer,
		# or it fires again on landing and mimics a double jump.
		if ability_unlocks.double_jump_unlocked:
			player.jump_buffered = true
			player.jump_buffer_timer = config.jump_buffer_time

	# Air control — camera-relative, high responsiveness.
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
		player.velocity.x = lerp(player.velocity.x, direction.x * config.move_speed, 0.15)
		player.velocity.z = lerp(player.velocity.z, direction.z * config.move_speed, 0.15)
	else:
		player.velocity.x *= config.air_friction
		player.velocity.z *= config.air_friction

	# Dash in air.
	if Input.is_action_just_pressed("dash") and player.can_dash and ability_unlocks.dash_unlocked:
		player.state_machine.transition_to("dash")
		return

	if _handle_combat_input():
		return

	# Landed.
	player.move_and_slide()
	if player.is_on_floor():
		# Check for buffered jump.
		if player.jump_buffered and player.jump_buffer_timer > 0.0:
			player.jump_buffered = false
			player.state_machine.transition_to("jump")
		elif input_dir.length() > 0.1:
			player.state_machine.transition_to("run")
		else:
			player.state_machine.transition_to("idle")
