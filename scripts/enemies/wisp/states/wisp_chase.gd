extends WispState
## Chase — moves toward the player until in attack range or player escapes.
## Hysteresis: only returns to Patrol when distance > aggro_range * 1.5.


func enter() -> void:
	AudioManager.play_sfx("enemy_alert", wisp.global_position)


func physics_update(delta: float) -> void:
	if not wisp.player:
		wisp.state_machine.transition_to("patrol")
		return

	var dist: float = wisp.global_position.distance_to(wisp.player.global_position)

	# Player escaped — return to patrol (hysteresis prevents flickering).
	if dist > config.wisp_aggro_range * 1.5:
		wisp.state_machine.transition_to("patrol")
		return

	# Close enough to attack — begin wind-up.
	if dist <= config.wisp_attack_range:
		wisp.state_machine.transition_to("windup")
		return

	# Move toward player.
	var pos: Vector3 = wisp.global_position
	var dir: Vector3 = (wisp.player.global_position - pos)
	dir.y = 0.0
	dir = dir.normalized()
	wisp.velocity.x = dir.x * config.wisp_move_speed
	wisp.velocity.z = dir.z * config.wisp_move_speed

	_apply_float(delta)
	wisp.move_and_slide()


func _apply_float(delta: float) -> void:
	var target_y: float = wisp.spawn_y + config.wisp_float_height
	wisp.velocity.y = (target_y - wisp.global_position.y) * 8.0 * delta * 60.0
