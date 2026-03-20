extends WispState
## Patrol — drifts between random points within wisp_patrol_radius of spawn.
## Transitions to Chase when the player enters aggro range.

var _target: Vector3 = Vector3.ZERO
var _wait_timer: float = 0.0


func enter() -> void:
	_pick_new_target()


func physics_update(delta: float) -> void:
	# Check aggro.
	if wisp.player and _player_in_range(config.wisp_aggro_range):
		wisp.state_machine.transition_to("chase")
		return

	# Wait at waypoint before picking a new one.
	if _wait_timer > 0.0:
		_wait_timer -= delta
		_apply_float(delta)
		wisp.move_and_slide()
		return

	# Move toward current target.
	var pos: Vector3 = wisp.global_position
	var flat_target: Vector3 = Vector3(_target.x, pos.y, _target.z)
	var flat_dist: float = pos.distance_to(flat_target)

	if flat_dist < 0.3:
		_wait_timer = randf_range(0.5, 1.5)
		_pick_new_target()
	else:
		var dir: Vector3 = (flat_target - pos).normalized()
		wisp.velocity.x = dir.x * config.wisp_patrol_speed
		wisp.velocity.z = dir.z * config.wisp_patrol_speed

	_apply_float(delta)
	wisp.move_and_slide()


func _pick_new_target() -> void:
	var angle: float = randf() * TAU
	var radius: float = randf() * config.wisp_patrol_radius
	_target = wisp.spawn_position + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


func _apply_float(delta: float) -> void:
	var target_y: float = wisp.spawn_y + config.wisp_float_height
	wisp.velocity.y = (target_y - wisp.global_position.y) * 8.0 * delta * 60.0


func _player_in_range(range: float) -> bool:
	return wisp.global_position.distance_to(wisp.player.global_position) <= range
