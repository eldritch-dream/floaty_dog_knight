extends WispState
## Attack — activates the HitBox for wisp_attack_active_frames then returns to Chase.

var _frames_remaining: int = 0


func enter() -> void:
	_frames_remaining = config.wisp_attack_active_frames
	if wisp.hit_box:
		wisp.hit_box.activate(enemy_stats.damage, wisp)
	_set_emission(Color(1.0, 0.1, 0.05))
	AudioManager.play_sfx("enemy_attack", wisp.global_position)


func exit() -> void:
	if wisp.hit_box:
		wisp.hit_box.deactivate()
	_set_emission(Color(0.45, 0.1, 0.8))


func _set_emission(color: Color) -> void:
	if not wisp.visual:
		return
	var mat := wisp.visual.material as StandardMaterial3D
	if mat:
		mat.emission = color


func physics_update(delta: float) -> void:
	_frames_remaining -= 1

	_apply_float(delta)
	wisp.move_and_slide()

	if _frames_remaining <= 0:
		wisp.state_machine.transition_to("chase")


func _apply_float(delta: float) -> void:
	var target_y: float = wisp.spawn_y + config.wisp_float_height
	wisp.velocity.y = (target_y - wisp.global_position.y) * 8.0 * delta * 60.0
