extends PlayerState
## Heavy attack state. Higher damage, longer active frames, higher stamina cost.

var _combo_system: ComboSystem = null
var _finished: bool = false


func enter() -> void:
	_finished = false
	stats.spend_stamina(config.heavy_attack_stamina_cost, config.stamina_regen_delay)

	_combo_system = player.get_node_or_null("ComboSystem") as ComboSystem
	if _combo_system:
		_combo_system.attack_ended.connect(_on_attack_ended, CONNECT_ONE_SHOT)
		_combo_system.start_attack(
			config.hitbox_active_frames_heavy,
			config.heavy_attack_damage,
			player,
			true
		)


func physics_update(delta: float) -> void:
	if _combo_system:
		_combo_system.tick(delta)

	# Player is rooted during heavy attacks.
	player.velocity.x = move_toward(player.velocity.x, 0.0, config.move_speed)
	player.velocity.z = move_toward(player.velocity.z, 0.0, config.move_speed)
	player.move_and_slide()

	if _finished:
		_transition_out()


func _on_attack_ended() -> void:
	_finished = true


func _transition_out() -> void:
	if player.is_on_floor():
		player.state_machine.transition_to("idle")
	else:
		player.state_machine.transition_to("float")
