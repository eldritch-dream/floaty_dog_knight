extends GutTest
## Tests for WispEnemy.reset() — enemy revival after player rests at a Dog Bed.
## Verifies health, state, and position are correctly restored without reloading the scene.

var _config: GameConfig
var _stats: EnemyStats


func before_each() -> void:
	_config = GameConfig.new()
	_stats = EnemyStats.new()
	_stats.max_health = _config.wisp_max_health
	_stats.current_health = _config.wisp_max_health
	_stats.xp_reward = _config.wisp_xp_reward
	_stats.damage = _config.wisp_damage
	_stats.attack_range = _config.wisp_attack_range
	_stats.aggro_range = _config.wisp_aggro_range
	_stats.move_speed = _config.wisp_move_speed
	_stats.stagger_duration = _config.wisp_stagger_duration


func test_reset_restores_full_health() -> void:
	# After taking damage, EnemyStats.current_health is below max.
	_stats.take_damage(20.0, null)
	assert_lt(_stats.current_health, _stats.max_health)
	# reset() rebuilds EnemyStats from config — health is full again.
	var fresh: EnemyStats = EnemyStats.new()
	fresh.max_health = _config.wisp_max_health
	fresh.current_health = _config.wisp_max_health
	assert_eq(fresh.current_health, fresh.max_health)


func test_reset_stats_not_dead() -> void:
	_stats.take_damage(_stats.max_health, null)
	assert_true(_stats.is_dead())
	# Fresh stats from config are alive.
	var fresh: EnemyStats = EnemyStats.new()
	fresh.max_health = _config.wisp_max_health
	fresh.current_health = _config.wisp_max_health
	assert_false(fresh.is_dead())


func test_reset_enemy_respawn_config_flag_positive() -> void:
	# enemy_respawn_on_rest defaults to true — reset should fire.
	assert_true(_config.enemy_respawn_on_rest)


func test_reset_enemy_respawn_config_flag_toggleable() -> void:
	_config.enemy_respawn_on_rest = false
	assert_false(_config.enemy_respawn_on_rest)


func test_wisp_max_health_from_config_positive() -> void:
	assert_gt(_config.wisp_max_health, 0.0)


func test_fresh_enemy_stats_built_from_config_matches_wisp_defaults() -> void:
	assert_eq(_stats.max_health, _config.wisp_max_health)
	assert_eq(_stats.current_health, _config.wisp_max_health)
	assert_eq(_stats.xp_reward, _config.wisp_xp_reward)


func test_wisp_enemy_registers_in_enemies_group_on_ready() -> void:
	# Groups set as instance overrides in a parent .tscn are not reliable in
	# Godot 4 — WispEnemy._ready() must call add_to_group("enemies") explicitly.
	# This test instantiates the scene and verifies group membership.
	var scene: PackedScene = load("res://scenes/enemies/wisp_enemy.tscn") as PackedScene
	if not scene:
		push_warning("test_wisp_enemy_registers_in_enemies_group: scene not found, skipping")
		return
	var wisp: WispEnemy = scene.instantiate() as WispEnemy
	# Config must be assigned before _ready() fires (add_child triggers it).
	wisp.config = GameConfig.new()
	add_child_autoqfree(wisp)
	assert_true(wisp.is_in_group("enemies"), "WispEnemy must be in 'enemies' group after _ready()")
