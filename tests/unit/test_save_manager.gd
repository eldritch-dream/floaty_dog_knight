extends GutTest
## Tests for SaveData serialisation and SaveManager desktop save/load path.
## JavaScriptBridge is not available in headless GUT — OS.has_feature("web")
## returns false, so the desktop (FileAccess) path is always exercised here.
## SaveManager.save_path is overridden per-test to a temp file that is cleaned
## up in after_each, keeping tests isolated from each other and from real saves.

const TEMP_SAVE: String = "user://test_save_tmp.json"

var _stats: PlayerStats
var _unlocks: AbilityUnlocks
var _save_manager: SaveManager


func before_each() -> void:
	_stats = PlayerStats.new()
	_stats.level = 3
	_stats.xp = 42
	_stats.max_health = 120.0
	_stats.health = 120.0
	_stats.max_stamina = 110.0
	_stats.stamina = 110.0
	_stats.stamina_regen_rate = 24.0

	_unlocks = AbilityUnlocks.new()
	_unlocks.double_jump_unlocked = true
	_unlocks.dash_unlocked = true

	_save_manager = SaveManager
	_save_manager.save_path = TEMP_SAVE
	_save_manager._session_active = false
	_save_manager._stats = null
	_save_manager._unlocks = null


func after_each() -> void:
	if FileAccess.file_exists(TEMP_SAVE):
		DirAccess.remove_absolute(TEMP_SAVE)
	_save_manager._session_active = false
	_save_manager._stats = null
	_save_manager._unlocks = null


# ── SaveData ──────────────────────────────────────────────────────────────────

func test_save_data_capture_stores_level() -> void:
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/hub.tscn")
	assert_eq(data.player_level, 3)


func test_save_data_capture_stores_xp() -> void:
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/hub.tscn")
	assert_eq(data.player_xp, 42)


func test_save_data_capture_stores_max_health() -> void:
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/hub.tscn")
	assert_eq(data.player_max_health, 120.0)


func test_save_data_capture_stores_ability_unlocks() -> void:
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/hub.tscn")
	assert_true(data.ability_unlocks.get("double_jump_unlocked", false))
	assert_true(data.ability_unlocks.get("dash_unlocked", false))
	assert_false(data.ability_unlocks.get("dodge_unlocked", true))


func test_save_data_capture_stores_last_scene() -> void:
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/zone_01.tscn")
	assert_eq(data.last_scene, "res://scenes/world/zone_01.tscn")


func test_save_data_to_dict_round_trips_via_from_dict() -> void:
	var original: SaveData = SaveData.new()
	original.capture(_stats, _unlocks, "res://scenes/world/hub.tscn")
	var d: Dictionary = original.to_dict()
	var restored: SaveData = SaveData.new()
	restored.from_dict(d)
	assert_eq(restored.player_level, original.player_level)
	assert_eq(restored.player_xp, original.player_xp)
	assert_eq(restored.player_max_health, original.player_max_health)
	assert_eq(restored.last_scene, original.last_scene)


func test_save_data_apply_to_restores_level() -> void:
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/hub.tscn")
	var target_stats: PlayerStats = PlayerStats.new()
	var target_unlocks: AbilityUnlocks = AbilityUnlocks.new()
	data.apply_to(target_stats, target_unlocks)
	assert_eq(target_stats.level, 3)


func test_save_data_apply_to_restores_health_to_max() -> void:
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/hub.tscn")
	var target_stats: PlayerStats = PlayerStats.new()
	var target_unlocks: AbilityUnlocks = AbilityUnlocks.new()
	data.apply_to(target_stats, target_unlocks)
	assert_eq(target_stats.health, target_stats.max_health)


func test_save_data_apply_to_restores_ability_unlocks() -> void:
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/hub.tscn")
	var target_stats: PlayerStats = PlayerStats.new()
	var target_unlocks: AbilityUnlocks = AbilityUnlocks.new()
	data.apply_to(target_stats, target_unlocks)
	assert_true(target_unlocks.double_jump_unlocked)
	assert_true(target_unlocks.dash_unlocked)
	assert_false(target_unlocks.dodge_unlocked)


# ── SaveManager ───────────────────────────────────────────────────────────────

func test_has_save_returns_false_when_no_save() -> void:
	assert_false(_save_manager.has_save())


func test_load_game_returns_null_when_no_save() -> void:
	assert_null(_save_manager.load_game())


func test_save_creates_file() -> void:
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	assert_true(FileAccess.file_exists(TEMP_SAVE))


func test_has_save_returns_true_after_save() -> void:
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	assert_true(_save_manager.has_save())


func test_load_restores_level_correctly() -> void:
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	var data: SaveData = _save_manager.load_game()
	assert_not_null(data)
	assert_eq(data.player_level, 3)


func test_load_restores_xp_correctly() -> void:
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	var data: SaveData = _save_manager.load_game()
	assert_eq(data.player_xp, 42)


func test_load_restores_ability_unlocks() -> void:
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	var data: SaveData = _save_manager.load_game()
	assert_true(data.ability_unlocks.get("double_jump_unlocked", false))
	assert_false(data.ability_unlocks.get("dodge_unlocked", true))


func test_save_overwrites_previous_save() -> void:
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	_stats.level = 7
	_save_manager.save_game("res://scenes/world/hub.tscn")
	var data: SaveData = _save_manager.load_game()
	assert_eq(data.player_level, 7)


func test_delete_save_removes_file() -> void:
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	_save_manager.delete_save()
	assert_false(FileAccess.file_exists(TEMP_SAVE))


func test_has_save_returns_false_after_delete() -> void:
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	_save_manager.delete_save()
	assert_false(_save_manager.has_save())


func test_apply_save_if_exists_is_noop_when_no_save() -> void:
	var target_stats: PlayerStats = PlayerStats.new()
	var target_unlocks: AbilityUnlocks = AbilityUnlocks.new()
	_save_manager.apply_save_if_exists(target_stats, target_unlocks)
	assert_eq(target_stats.level, 1)  # unchanged default


func test_apply_save_if_exists_restores_when_save_exists() -> void:
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	var target_stats: PlayerStats = PlayerStats.new()
	var target_unlocks: AbilityUnlocks = AbilityUnlocks.new()
	_save_manager.apply_save_if_exists(target_stats, target_unlocks)
	assert_eq(target_stats.level, 3)


func test_web_and_desktop_paths_produce_same_dict_shape() -> void:
	# Both paths serialise to JSON using SaveData.to_dict() — verify the keys.
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/hub.tscn")
	var d: Dictionary = data.to_dict()
	assert_true(d.has("player_level"))
	assert_true(d.has("player_xp"))
	assert_true(d.has("player_max_health"))
	assert_true(d.has("player_max_stamina"))
	assert_true(d.has("stamina_regen_rate"))
	assert_true(d.has("ability_unlocks"))
	assert_true(d.has("last_scene"))
	assert_true(d.has("last_bed_id"))
	assert_true(d.has("last_bed_scene"))
	assert_true(d.has("unspent_stat_points"))


# ── Bed fields ────────────────────────────────────────────────────────────────

func test_last_bed_id_persists() -> void:
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/zone_01.tscn")
	data.last_bed_id = "zone_01_bed"
	var d: Dictionary = data.to_dict()
	var restored: SaveData = SaveData.new()
	restored.from_dict(d)
	assert_eq(restored.last_bed_id, "zone_01_bed")


func test_last_bed_scene_persists() -> void:
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, "res://scenes/world/zone_01.tscn")
	data.last_bed_scene = "res://scenes/world/zone_01.tscn"
	var d: Dictionary = data.to_dict()
	var restored: SaveData = SaveData.new()
	restored.from_dict(d)
	assert_eq(restored.last_bed_scene, "res://scenes/world/zone_01.tscn")


func test_save_game_preserves_bed_fields_across_subsequent_saves() -> void:
	# Simulate the DreamManager flow: _update_respawn_point writes bed fields via _write(),
	# then exit_dream calls save_game(). save_game() must NOT wipe those fields.
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	# Step 1 — write bed fields directly (as _update_respawn_point does).
	var bed_data: SaveData = SaveData.new()
	bed_data.last_bed_id = "zone_01_bed"
	bed_data.last_bed_scene = "res://scenes/world/zone_01.tscn"
	_save_manager._write(JSON.stringify(bed_data.to_dict()))
	# Step 2 — a subsequent save_game() call (as exit_dream does) must preserve them.
	_save_manager.save_game("res://scenes/world/zone_01.tscn")
	var result: SaveData = _save_manager.load_game()
	assert_not_null(result)
	assert_eq(result.last_bed_id, "zone_01_bed")
	assert_eq(result.last_bed_scene, "res://scenes/world/zone_01.tscn")


func test_unspent_stat_points_persists() -> void:
	_stats.unspent_stat_points = 3
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	var data: SaveData = _save_manager.load_game()
	assert_eq(data.unspent_stat_points, 3)


func test_backward_compat_load_without_bed_fields() -> void:
	# Simulate a save written before bed fields existed (no keys present).
	var old_dict: Dictionary = {
		"player_level": 2,
		"player_xp": 50,
		"player_max_health": 110.0,
		"player_max_stamina": 105.0,
		"stamina_regen_rate": 20.0,
		"ability_unlocks": {},
		"last_scene": "res://scenes/world/hub.tscn",
	}
	var data: SaveData = SaveData.new()
	data.from_dict(old_dict)
	assert_eq(data.last_bed_id, "")
	assert_eq(data.last_bed_scene, "")
	assert_eq(data.unspent_stat_points, 0)


func test_save_game_preserves_dialogue_fields_across_subsequent_saves() -> void:
	# Simulate the DialogueManager flow: _save() writes dialogue fields via _write(),
	# then save_game() runs. save_game() must NOT wipe those fields.
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	# Step 1 — write dialogue fields directly (as DialogueManager._save() does).
	var dm_data: SaveData = SaveData.new()
	dm_data.fired_events = ["hub_entered_first", "rested_at_bed"]
	dm_data.npc_states = {"owner": "dreamer"}
	dm_data.one_shot_lines_seen = ["owner_dreamer_2"]
	_save_manager._write(JSON.stringify(dm_data.to_dict()))
	# Step 2 — a subsequent save_game() call must preserve those fields.
	_save_manager.save_game("res://scenes/world/hub.tscn")
	var result: SaveData = _save_manager.load_game()
	assert_not_null(result)
	assert_true(result.fired_events.has("rested_at_bed"))
	assert_eq(result.npc_states.get("owner", ""), "dreamer")
	assert_true(result.one_shot_lines_seen.has("owner_dreamer_2"))


func test_dialogue_fields_default_to_empty_on_new_save() -> void:
	_save_manager._stats = _stats
	_save_manager._unlocks = _unlocks
	_save_manager.save_game("res://scenes/world/hub.tscn")
	var result: SaveData = _save_manager.load_game()
	assert_eq(result.fired_events, [])
	assert_eq(result.npc_states, {})
	assert_eq(result.one_shot_lines_seen, [])


func test_backward_compat_load_without_dialogue_fields() -> void:
	# Simulate a save written before dialogue fields existed.
	var old_dict: Dictionary = {
		"player_level": 2,
		"player_xp": 50,
		"player_max_health": 110.0,
		"player_max_stamina": 105.0,
		"stamina_regen_rate": 20.0,
		"ability_unlocks": {},
		"last_scene": "res://scenes/world/hub.tscn",
	}
	var data: SaveData = SaveData.new()
	data.from_dict(old_dict)
	assert_eq(data.fired_events, [])
	assert_eq(data.npc_states, {})
	assert_eq(data.one_shot_lines_seen, [])


func test_bad_bed_scene_path_is_cleared_on_load() -> void:
	# Simulate a save written by the old bug where bed_scene_path stored the
	# DogBed subscene path instead of the world scene path.
	var bad_dict: Dictionary = {
		"player_level": 1,
		"player_xp": 0,
		"player_max_health": 100.0,
		"player_max_stamina": 100.0,
		"stamina_regen_rate": 20.0,
		"ability_unlocks": {},
		"last_scene": "res://scenes/world/hub.tscn",
		"last_bed_id": "hub_bed",
		"last_bed_scene": "res://scenes/world/dog_bed.tscn",
		"unspent_stat_points": 0,
	}
	var data: SaveData = SaveData.new()
	data.from_dict(bad_dict)
	# Bad path must be cleared so cold-start falls back to hub rather than loading
	# a sceneless file with no Player node.
	assert_eq(data.last_bed_scene, "")
