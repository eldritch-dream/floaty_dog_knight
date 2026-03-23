extends Node
## Autoload singleton. Drives the death-to-respawn sequence.
## Registered as "RespawnManager" in Project Settings → Autoload.
##
## Sequence (called by Player._on_player_died via handle_death):
##   1. Engine freeze (0.3 s) — placeholder for future death animation duration.
##      TODO: when a death animation exists, replace the freeze with
##            await player.death_animation_finished instead.
##   2. Restore health on the PlayerStats resource.
##   3. Remaining config.death_respawn_delay elapses.
##   4. WorldManager.travel_to(hub) — scene change handles everything else.


## Starts the respawn sequence. Called directly from Player._on_player_died().
## Refs are passed in so the autoload never holds stale scene-specific pointers.
func handle_death(stats: PlayerStats, config: GameConfig) -> void:
	_run_sequence(stats, config)


func _run_sequence(stats: PlayerStats, config: GameConfig) -> void:
	# Step 1 — brief freeze. Placeholder for death animation duration.
	# All timers use process_always=true so they tick despite time_scale = 0.
	Engine.time_scale = 0.0
	# ignore_time_scale=true (4th arg) is required — without it, the timer
	# never ticks when time_scale=0 and the coroutine hangs permanently.
	await get_tree().create_timer(0.3, true, false, true).timeout
	Engine.time_scale = 1.0

	# Step 2 — wait the remaining configured delay (total = respawn_delay).
	# Health is NOT restored yet — player stays visually dead at 0 HP.
	# is_invincible=true (set in Player._on_player_died) blocks any damage during this wait.
	var remaining: float = maxf(0.0, config.death_respawn_delay - 0.3)
	if remaining > 0.0:
		await get_tree().create_timer(remaining, true, false, true).timeout

	# Step 3 — restore health immediately before the scene swap so the shared
	# PlayerStats resource carries the correct value into the new scene.
	stats.health = stats.max_health * config.respawn_health_percent
	stats.health_changed.emit(stats.health, stats.max_health)

	# Step 4 — travel to last-used Dog Bed, falling back to hub if none recorded.
	# WorldManager.travel_to() also triggers a save automatically.
	var data: SaveData = SaveManager.load_game()
	var bed_scene: String = data.last_bed_scene if data else ""
	var bed_id: String = data.last_bed_id if data else ""
	if bed_scene.is_empty():
		# No bed used yet — fall back to hub SpawnPoint (same as pre-PR behaviour).
		bed_scene = "res://scenes/world/hub.tscn"
		bed_id = "SpawnPoint"
	WorldManager.travel_to(bed_scene, bed_id)
