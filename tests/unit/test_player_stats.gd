extends GutTest
## Unit tests for PlayerStats: health, stamina, regen, XP/leveling.

var stats: PlayerStats

func before_each() -> void:
	stats = PlayerStats.new()
	stats.max_health = 100.0
	stats.health = 100.0
	stats.max_stamina = 100.0
	stats.stamina = 100.0
	stats.stamina_regen_rate = 20.0
	stats.level = 1
	stats.xp = 0

# ── Health ───────────────────────────────────────────────────────────────────

func test_take_damage_reduces_health() -> void:
	stats.take_damage(30.0)
	assert_eq(stats.health, 70.0)

func test_health_clamped_below_zero() -> void:
	stats.take_damage(999.0)
	assert_eq(stats.health, 0.0)

func test_heal_restores_health() -> void:
	stats.health = 50.0
	stats.heal(20.0)
	assert_eq(stats.health, 70.0)

func test_heal_clamped_at_max() -> void:
	stats.heal(999.0)
	assert_eq(stats.health, stats.max_health)

func test_died_signal_emitted_at_zero() -> void:
	watch_signals(stats)
	stats.take_damage(100.0)
	assert_signal_emitted(stats, "died")

func test_health_changed_signal_emitted() -> void:
	watch_signals(stats)
	stats.take_damage(10.0)
	assert_signal_emitted(stats, "health_changed")

# ── Stamina ──────────────────────────────────────────────────────────────────

func test_spend_stamina_succeeds_when_sufficient() -> void:
	var result := stats.spend_stamina(25.0, 1.2)
	assert_true(result)
	assert_eq(stats.stamina, 75.0)

func test_spend_stamina_fails_when_insufficient() -> void:
	stats.stamina = 10.0
	var result := stats.spend_stamina(25.0, 1.2)
	assert_false(result)
	assert_eq(stats.stamina, 10.0)

func test_stamina_does_not_regen_during_delay() -> void:
	stats.stamina = 50.0
	stats.spend_stamina(0.0, 1.2)  # set delay without spending more
	stats._regen_delay_remaining = 1.2
	stats.tick(0.5)
	assert_eq(stats.stamina, 50.0)

func test_stamina_regens_after_delay_expires() -> void:
	stats.stamina = 50.0
	stats._regen_delay_remaining = 0.0
	stats.tick(1.0)
	assert_almost_eq(stats.stamina, 70.0, 0.01)

func test_stamina_clamped_at_max_during_regen() -> void:
	stats.stamina = 99.0
	stats._regen_delay_remaining = 0.0
	stats.tick(10.0)
	assert_eq(stats.stamina, stats.max_stamina)

func test_stamina_changed_signal_on_spend() -> void:
	watch_signals(stats)
	stats.spend_stamina(10.0, 1.2)
	assert_signal_emitted(stats, "stamina_changed")

# ── XP / Leveling ────────────────────────────────────────────────────────────

func test_gain_xp_increases_xp() -> void:
	stats.gain_xp(50, 100, 1.5)
	assert_eq(stats.xp, 50)

func test_gain_xp_triggers_levelup() -> void:
	# xp_required at level 1 = int(100 * 1^1.5) = 100
	stats.gain_xp(100, 100, 1.5)
	assert_eq(stats.level, 2)

func test_xp_wraps_after_levelup() -> void:
	# Award exactly threshold + 10 extra
	stats.gain_xp(110, 100, 1.5)
	assert_eq(stats.xp, 10)

func test_leveled_up_signal_emitted() -> void:
	watch_signals(stats)
	stats.gain_xp(100, 100, 1.5)
	assert_signal_emitted(stats, "leveled_up")

func test_level_up_grants_unspent_stat_points() -> void:
	# Stat allocation is manual (at Dog Beds) — level-up no longer auto-allocates.
	stats.gain_xp(100, 100, 1.5, 1)
	assert_eq(stats.unspent_stat_points, 1)

func test_level_up_does_not_auto_increase_max_health() -> void:
	var old_max: float = stats.max_health
	stats.gain_xp(100, 100, 1.5, 1)
	assert_eq(stats.max_health, old_max)

func test_xp_required_grows_with_level() -> void:
	# Level 1 needs 100, level 2 needs int(100 * 2^1.5) = 282
	stats.gain_xp(100, 100, 1.5)  # now level 2
	assert_eq(stats.level, 2)
	# Should NOT level up on just 100 more XP at level 2
	stats.gain_xp(100, 100, 1.5)
	assert_eq(stats.level, 2)

# ── Stat Investment ───────────────────────────────────────────────────────────

func test_stat_points_pending_signal_emitted() -> void:
	watch_signals(stats)
	stats.gain_xp(100, 100, 1.5, 1)
	assert_signal_emitted(stats, "stat_points_pending")

func test_invest_constitution_increases_max_health() -> void:
	stats.unspent_stat_points = 1
	stats.constitution_health_per_point = 15.0
	var old_max: float = stats.max_health
	stats.invest_in_stat("constitution")
	assert_eq(stats.max_health, old_max + 15.0)

func test_invest_endurance_increases_max_stamina() -> void:
	stats.unspent_stat_points = 1
	stats.endurance_stamina_per_point = 8.0
	var old_max: float = stats.max_stamina
	stats.invest_in_stat("endurance")
	assert_eq(stats.max_stamina, old_max + 8.0)

func test_invest_returns_false_with_no_points() -> void:
	stats.unspent_stat_points = 0
	var result: bool = stats.invest_in_stat("constitution")
	assert_false(result)

func test_invest_decrements_unspent_points() -> void:
	stats.unspent_stat_points = 2
	stats.invest_in_stat("constitution")
	assert_eq(stats.unspent_stat_points, 1)

func test_invest_unknown_stat_returns_false() -> void:
	stats.unspent_stat_points = 1
	var result: bool = stats.invest_in_stat("strength")
	assert_false(result)

func test_invest_unknown_stat_does_not_consume_point() -> void:
	stats.unspent_stat_points = 1
	stats.invest_in_stat("strength")
	assert_eq(stats.unspent_stat_points, 1)

func test_get_investable_stats_returns_constitution() -> void:
	var inv: Dictionary = stats.get_investable_stats()
	assert_true(inv.has("constitution"))

func test_get_investable_stats_returns_endurance() -> void:
	var inv: Dictionary = stats.get_investable_stats()
	assert_true(inv.has("endurance"))

func test_get_investable_stats_shape() -> void:
	var inv: Dictionary = stats.get_investable_stats()
	var entry: Dictionary = inv.get("constitution", {})
	assert_true(entry.has("label"))
	assert_true(entry.has("description"))
	assert_true(entry.has("current"))
	assert_true(entry.has("gain"))
