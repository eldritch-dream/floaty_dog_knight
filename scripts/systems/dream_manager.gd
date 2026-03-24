extends Node
## Autoload singleton. Owns the full enter/exit Dream flow.
## Register as "DreamManager" in Project Settings → Autoload.
##
## This is the SESSION B SEAM. The placeholder CanvasLayer overlay below is
## replaced in Session B by a full scene transition to dream_space.tscn.
## Everything outside this file (DogBed, PlayerStats, SaveManager) is unchanged.
##
## Entry point: DreamManager.enter_dream(bed)
## Exit point:  DreamManager.exit_dream()
## These are the ONLY two ways to open or close the Dream UI.

var _player: CharacterBody3D = null
var _dream_overlay: CanvasLayer = null
var _stat_screen = null  # StatAllocationScreen — typed after class_name is available


## Called from Player._ready() each scene load. DreamManager needs a direct
## player reference to toggle is_in_dream and disable input.
func register_player(player: CharacterBody3D) -> void:
	_player = player


## Enter the Dream at the given bed. Disables player input, heals to full,
## updates the respawn point, respawns enemies, saves, then shows the overlay.
func enter_dream(bed: DogBed) -> void:
	if not _player:
		push_warning("DreamManager: enter_dream called before register_player.")
		return

	# Disable all player input and physics.
	_player.is_in_dream = true
	_player.state_machine.set_physics_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Update respawn point so future deaths land at this bed.
	_update_respawn_point(bed)

	# Heal player to full and restore stamina.
	_player.stats.health = _player.stats.max_health
	_player.stats.health_changed.emit(_player.stats.health, _player.stats.max_health)
	_player.stats.stamina = _player.stats.max_stamina
	_player.stats.stamina_changed.emit(_player.stats.stamina, _player.stats.max_stamina)

	# Respawn enemies in the current scene (gated by config flag).
	# Reset first, then freeze — reset() re-enables physics internally, so the
	# freeze must come after to keep enemies paused while the dream is open.
	if _player.config and _player.config.enemy_respawn_on_rest:
		get_tree().call_group("enemies", "reset")
	get_tree().call_group("enemies", "set_physics_process", false)

	AudioManager.play_sfx("dream_enter")

	# Show the placeholder overlay.
	# PLACEHOLDER: Session B replaces _show_overlay() with a call to
	# WorldManager.travel_to("res://scenes/world/dream_space.tscn").
	# Do not move stat allocation logic here — it lives in StatAllocationScreen.
	_show_overlay()


## Hide the overlay and restore player input.
## Save happens here, after stat investments, not on entry.
func exit_dream() -> void:
	_hide_overlay()
	AudioManager.play_sfx("dream_wake")
	if _player:
		# Save after investments are applied — entry save only wrote the respawn point.
		var scene: Node = get_tree().current_scene
		var scene_path: String = scene.scene_file_path if scene else ""
		SaveManager.save_game(scene_path)
		_player.is_in_dream = false
		_player.state_machine.set_physics_process(true)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Unfreeze enemies that were paused on entry.
	get_tree().call_group("enemies", "set_physics_process", true)


# ── Private ───────────────────────────────────────────────────────────────────

func _update_respawn_point(bed: DogBed) -> void:
	# Write last_bed_id and last_bed_scene directly into the current save data,
	# then re-save so the respawn point survives a crash between rests.
	var data: SaveData = SaveManager.load_game()
	if data == null:
		data = SaveData.new()
	data.last_bed_id = bed.bed_id
	data.last_bed_scene = bed.bed_scene_path
	SaveManager._write(JSON.stringify(data.to_dict()))


func _show_overlay() -> void:
	if _dream_overlay:
		return  # Already open.
	_dream_overlay = CanvasLayer.new()
	_dream_overlay.layer = 10
	add_child(_dream_overlay)

	var panel: Panel = Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.05, 0.85)
	panel.add_theme_stylebox_override("panel", style)
	_dream_overlay.add_child(panel)

	# Load and attach the stat allocation screen.
	var screen_scene: PackedScene = load(
			"res://scenes/ui/stat_allocation_screen.tscn") as PackedScene
	if screen_scene:
		_stat_screen = screen_scene.instantiate()
		_stat_screen.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		if _player:
			_stat_screen.setup(_player.stats)
		_dream_overlay.add_child(_stat_screen)


func _hide_overlay() -> void:
	if _dream_overlay:
		_dream_overlay.queue_free()
		_dream_overlay = null
		_stat_screen = null
