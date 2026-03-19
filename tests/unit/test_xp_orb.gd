extends GutTest
## Unit tests for XPOrb: XP award logic via PlayerStats.

var stats: PlayerStats
var config: GameConfig

func before_each() -> void:
	config = GameConfig.new()
	stats = PlayerStats.new()
	stats.level = 1
	stats.xp = 0

# ── XP award ─────────────────────────────────────────────────────────────────

func test_gain_xp_increases_xp() -> void:
	stats.gain_xp(10, config.xp_base, config.xp_exponent)
	assert_eq(stats.xp, 10)

func test_gain_xp_does_not_level_up_on_small_award() -> void:
	stats.gain_xp(10, config.xp_base, config.xp_exponent)
	assert_eq(stats.level, 1)

func test_gain_xp_levels_up_at_threshold() -> void:
	# xp_required at level 1 = int(100 * 1^1.5) = 100
	stats.gain_xp(100, config.xp_base, config.xp_exponent)
	assert_eq(stats.level, 2)

func test_gain_xp_wraps_remainder_after_levelup() -> void:
	stats.gain_xp(110, config.xp_base, config.xp_exponent)
	assert_eq(stats.xp, 10)

# ── Config defaults ────────────────────────────────────────────────────────────

func test_xp_base_positive() -> void:
	assert_gt(config.xp_base, 0)

func test_xp_exponent_above_one() -> void:
	assert_gt(config.xp_exponent, 1.0)

func test_xp_required_grows_with_level() -> void:
	# Level 1 needs 100; level 2 needs int(100 * 2^1.5) = 282
	var req_lv1: int = int(config.xp_base * pow(1, config.xp_exponent))
	var req_lv2: int = int(config.xp_base * pow(2, config.xp_exponent))
	assert_gt(req_lv2, req_lv1)
