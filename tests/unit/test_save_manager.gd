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
