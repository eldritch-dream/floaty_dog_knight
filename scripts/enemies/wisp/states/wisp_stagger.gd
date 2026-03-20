extends WispState
## Stagger — Wisp is frozen briefly after being hit.
## Returns to Chase after wisp_stagger_duration.

var _timer: float = 0.0


func enter() -> void:
	_timer = config.wisp_stagger_duration
	# Snap scale back to normal in case WindUp left it enlarged.
	if wisp.visual:
		wisp.visual.scale = Vector3.ONE
	_set_emission(Color(1.0, 1.0, 1.0))  # White = stunned


func exit() -> void:
	_set_emission(Color(0.45, 0.1, 0.8))  # Restore purple


func _set_emission(color: Color) -> void:
	if not wisp.visual:
		return
	var mat := wisp.visual.material as StandardMaterial3D
	if mat:
		mat.emission = color


func physics_update(delta: float) -> void:
	_timer -= delta

	# Hold position.
	wisp.velocity.x = 0.0
	wisp.velocity.z = 0.0
	_apply_float(delta)
	wisp.move_and_slide()

	if _timer <= 0.0:
		wisp.state_machine.transition_to("chase")


func _apply_float(delta: float) -> void:
	var target_y: float = wisp.spawn_y + config.wisp_float_height
	wisp.velocity.y = (target_y - wisp.global_position.y) * 8.0 * delta * 60.0
