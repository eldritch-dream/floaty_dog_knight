extends GutTest
## Tests for EnemyStats resource behaviour.


func test_take_damage_reduces_health() -> void:
	var stats := EnemyStats.new()
	stats.max_health = 35.0
	stats.current_health = 35.0
	stats.take_damage(10.0)
	assert_eq(stats.current_health, 25.0,
		"Taking 10 damage from 35 hp should leave 25 hp")


func test_health_floor_at_zero() -> void:
	var stats := EnemyStats.new()
	stats.max_health = 35.0
	stats.current_health = 35.0
	stats.take_damage(999.0)
	assert_eq(stats.current_health, 0.0,
		"Health should not go below zero")


func test_died_signal_emitted_at_zero() -> void:
	var stats := EnemyStats.new()
	stats.max_health = 35.0
	stats.current_health = 10.0
	watch_signals(stats)
	stats.take_damage(10.0)
	assert_signal_emitted(stats, "died",
		"died signal should fire when health reaches zero")


func test_died_signal_not_emitted_when_alive() -> void:
	var stats := EnemyStats.new()
	stats.max_health = 35.0
	stats.current_health = 35.0
	watch_signals(stats)
	stats.take_damage(10.0)
	assert_signal_not_emitted(stats, "died",
		"died signal should not fire when health remains above zero")


func test_is_dead_returns_true_at_zero() -> void:
	var stats := EnemyStats.new()
	stats.max_health = 35.0
	stats.current_health = 0.0
	assert_true(stats.is_dead(), "is_dead() should return true at zero health")


func test_is_dead_returns_false_when_alive() -> void:
	var stats := EnemyStats.new()
	stats.max_health = 35.0
	stats.current_health = 1.0
	assert_false(stats.is_dead(), "is_dead() should return false when health > 0")


func test_xp_reward_value_accessible() -> void:
	var stats := EnemyStats.new()
	stats.xp_reward = 20
	assert_eq(stats.xp_reward, 20,
		"xp_reward should be readable from EnemyStats")


func test_take_damage_no_op_when_already_dead() -> void:
	var stats := EnemyStats.new()
	stats.max_health = 35.0
	stats.current_health = 0.0
	watch_signals(stats)
	stats.take_damage(10.0)
	assert_signal_not_emitted(stats, "died",
		"take_damage on a dead enemy should not re-emit died")


func test_health_changed_signal_emitted_on_damage() -> void:
	var stats := EnemyStats.new()
	stats.max_health = 35.0
	stats.current_health = 35.0
	watch_signals(stats)
	stats.take_damage(5.0)
	assert_signal_emitted(stats, "health_changed",
		"health_changed signal should fire on damage")


func test_wisp_dies_in_four_light_attacks() -> void:
	var config := GameConfig.new()
	var stats := EnemyStats.new()
	stats.max_health = config.wisp_max_health
	stats.current_health = config.wisp_max_health
	for i in 4:
		stats.take_damage(config.light_attack_damage)
	assert_true(stats.is_dead(),
		"Wisp should die in 4 light attacks at default config values")


func test_wisp_dies_in_two_heavy_attacks() -> void:
	var config := GameConfig.new()
	var stats := EnemyStats.new()
	stats.max_health = config.wisp_max_health
	stats.current_health = config.wisp_max_health
	for i in 2:
		stats.take_damage(config.heavy_attack_damage)
	assert_true(stats.is_dead(),
		"Wisp should die in 2 heavy attacks at default config values")
