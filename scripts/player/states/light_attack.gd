extends PlayerState
## Light attack state. Spends stamina, triggers a short hitbox window, then returns.

var _combo_system: ComboSystem = null
var _finished: bool = false


func enter() -> void:
	_finished = false
	stats.spend_stamina(config.light_attack_stamina_cost, config.stamina_regen_delay)
	AudioManager.play_sfx("swing_light")

	_combo_system = player.get_node_or_null("ComboSystem") as ComboSystem
	if _combo_system:
		_combo_system.attack_ended.connect(_on_attack_ended, CONNECT_ONE_SHOT)
		_combo_system.start_attack(
			config.hitbox_active_frames_light,
			config.light_attack_damage,
			player,
			false
		)


func physics_update(delta: float) -> void:
	if _combo_system:
		_combo_system.tick(delta)

	# Allow slight movement during attack (half speed).
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() > 0.1 and player.is_on_floor():
		var dir: Vector3 = player.compute_camera_relative_direction(
			input_dir, player.camera_rig.global_transform.basis
		)
		player.velocity.x = dir.x * config.move_speed * 0.5
		player.velocity.z = dir.z * config.move_speed * 0.5
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, config.move_speed)
		player.velocity.z = move_toward(player.velocity.z, 0.0, config.move_speed)

	player.move_and_slide()

	if _finished:
		_transition_out()


func _on_attack_ended() -> void:
	_finished = true


func _transition_out() -> void:
	if player.is_on_floor():
		var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if input_dir.length() > 0.1:
			player.state_machine.transition_to("run")
		else:
			player.state_machine.transition_to("idle")
	else:
		player.state_machine.transition_to("float")
