extends PlayerState
## Death — terminal state entered when the player's health reaches zero.
## Disables all input processing. RespawnManager drives the respawn sequence
## externally via handle_death(); this state never self-exits.
##
## Animation hook: when a death animation is implemented, call it at the
## start of enter() and emit player.player_died AFTER it completes.
## RespawnManager's freeze/delay already accounts for this — replace the
## 0.3 s freeze with an await on an animation_finished signal instead.


func enter() -> void:
	# Halt all momentum immediately.
	player.velocity = Vector3.ZERO
	AudioManager.play_sfx("player_death")
	# Notify UI and future animation system. RespawnManager listens here too.
	# TODO: trigger death animation before emitting when animations are implemented.
	player.player_died.emit()


func exit() -> void:
	pass


func physics_update(delta: float) -> void:
	# Keep applying gravity so the corpse falls if airborne — no input accepted.
	if not player.is_on_floor():
		var base_gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
		player.velocity.y -= base_gravity * config.gravity_scale * delta
		player.move_and_slide()
