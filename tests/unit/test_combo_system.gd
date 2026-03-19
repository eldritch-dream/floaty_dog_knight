extends GutTest
## Unit tests for ComboSystem: attack timing, signal, hitbox lifecycle.

var combo: ComboSystem
var config: GameConfig

func before_each() -> void:
	config = GameConfig.new()
	combo = ComboSystem.new()
	add_child(combo)


func after_each() -> void:
	combo.queue_free()

# ── Initial state ─────────────────────────────────────────────────────────────

func test_not_attacking_by_default() -> void:
	assert_false(combo.is_attacking())

# ── start_attack ──────────────────────────────────────────────────────────────

func test_start_attack_sets_attacking_true() -> void:
	combo.start_attack(8, 10.0, null, false)
	assert_true(combo.is_attacking())

func test_start_attack_stores_damage() -> void:
	combo.start_attack(8, 25.0, null, false)
	assert_eq(combo._damage, 25.0)

func test_attack_ends_after_active_frames_elapse() -> void:
	combo.start_attack(6, 10.0, null, false)
	# 6 frames at 60 fps = 0.1 s
	combo.tick(0.1 + 0.001)
	assert_false(combo.is_attacking())

func test_attack_still_active_before_frames_elapse() -> void:
	combo.start_attack(60, 10.0, null, false)
	combo.tick(0.5)  # Only half a second — 60 frames = 1 s
	assert_true(combo.is_attacking())

func test_attack_ended_signal_emitted() -> void:
	watch_signals(combo)
	combo.start_attack(1, 10.0, null, false)
	combo.tick(1.0)
	assert_signal_emitted(combo, "attack_ended")

func test_tick_no_op_when_not_attacking() -> void:
	combo.tick(1.0)
	assert_false(combo.is_attacking())

# ── Config values ─────────────────────────────────────────────────────────────

func test_light_attack_frames_positive() -> void:
	assert_gt(config.hitbox_active_frames_light, 0)

func test_heavy_attack_frames_greater_than_light() -> void:
	assert_gt(config.hitbox_active_frames_heavy, config.hitbox_active_frames_light)

func test_light_damage_positive() -> void:
	assert_gt(config.light_attack_damage, 0.0)

func test_heavy_damage_greater_than_light() -> void:
	assert_gt(config.heavy_attack_damage, config.light_attack_damage)

func test_light_stamina_cost_positive() -> void:
	assert_gt(config.light_attack_stamina_cost, 0.0)

func test_heavy_stamina_cost_greater_than_light() -> void:
	assert_gt(config.heavy_attack_stamina_cost, config.light_attack_stamina_cost)
