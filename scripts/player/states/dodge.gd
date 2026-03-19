extends PlayerState
## Dodge roll — short directional dash with an i-frame invincibility window.
## Requires ability_unlocks.dodge_unlocked and sufficient stamina.

var _dodge_timer: float = 0.0
var _i_frame_timer: float = 0.0
var _dodge_direction: Vector3 = Vector3.ZERO


func enter() -> void:
	_dodge_timer = _dodge_duration()
	_i_frame_timer = config.i_frame_duration

	player.is_invincible = true

	# Spend stamina (already checked before transitioning here).
	stats.spend_stamina(config.dodge_stamina_cost, config.stamina_regen_delay)

	# Dodge in input direction, or backward if no input.
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() > 0.1:
		var cam_basis: Basis = player.camera_rig.global_transform.basis
		_dodge_direction = player.compute_camera_relative_direction(input_dir, cam_basis)
	else:
		_dodge_direction = player.global_transform.basis.z  # Dodge backward.
		_dodge_direction.y = 0.0
		_dodge_direction = _dodge_direction.normalized()


func physics_update(delta: float) -> void:
	# Tick i-frame window.
	if _i_frame_timer > 0.0:
		_i_frame_timer -= delta
		if _i_frame_timer <= 0.0:
			player.is_invincible = false

	_dodge_timer -= delta
	if _dodge_timer <= 0.0:
		_finish()
		return

	# Move at dodge speed along the roll direction.
	var speed: float = config.dodge_distance / _dodge_duration()
	player.velocity = _dodge_direction * speed
	player.velocity.y = 0.0
	player.move_and_slide()


func exit() -> void:
	player.is_invincible = false


func _dodge_duration() -> float:
	# Derive duration from distance and a fixed roll speed of 12 m/s.
	return config.dodge_distance / 12.0


func _finish() -> void:
	if player.is_on_floor():
		var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir.length() > 0.1:
			player.state_machine.transition_to("run")
		else:
			player.state_machine.transition_to("idle")
	else:
		player.state_machine.transition_to("float")
