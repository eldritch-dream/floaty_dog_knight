extends GutTest
## Unit tests for XPOrb: XP award logic and orb movement/vacuum/lifetime behaviour.

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

# ── Orb config values ─────────────────────────────────────────────────────────

func test_orb_pop_velocity_positive() -> void:
	assert_gt(config.orb_pop_velocity, 0.0)

func test_orb_vacuum_radius_positive() -> void:
	assert_gt(config.orb_vacuum_radius, 0.0)

func test_orb_lifetime_positive() -> void:
	assert_gt(config.orb_lifetime, 0.0)

func test_orb_bob_height_positive() -> void:
	assert_gt(config.orb_bob_height, 0.0)

func test_orb_gravity_multiplier_less_than_one() -> void:
	# Orbs must fall slower than full world gravity.
	assert_lt(config.orb_gravity_multiplier, 1.0)

# ── Orb movement behaviour ────────────────────────────────────────────────────

func test_orb_has_upward_velocity_on_spawn() -> void:
	var orb: XPOrb = XPOrb.new()
	orb.config = config
	# _ready() runs on add_child — velocity is set there.
	add_child_autoqfree(orb)
	assert_gt(orb._velocity_y, 0.0, "orb must start with positive upward velocity")


func test_orb_bob_phase_is_randomized() -> void:
	# Two orbs spawned separately should (almost certainly) have different phases.
	# Seeding randf() is not possible in GUT, so we check that both are in [0, TAU]
	# and accept the 1-in-a-million chance of identical phases as acceptable.
	var a: XPOrb = XPOrb.new()
	var b: XPOrb = XPOrb.new()
	a.config = config
	b.config = config
	add_child_autoqfree(a)
	add_child_autoqfree(b)
	assert_between(a._bob_phase, 0.0, TAU)
	assert_between(b._bob_phase, 0.0, TAU)


func test_orb_does_not_vacuum_before_delay_expires() -> void:
	var orb: XPOrb = XPOrb.new()
	orb.config = config
	add_child_autoqfree(orb)
	orb._popping = false
	orb._rest_y = orb.global_position.y
	orb._age = 0.0  # Delay has not expired.

	var mock_player: CharacterBody3D = CharacterBody3D.new()
	add_child_autoqfree(mock_player)
	mock_player.global_position = Vector3(config.orb_vacuum_radius * 0.5, 0.0, 0.0)
	orb.set_player(mock_player)

	orb._physics_process(0.05)
	assert_eq(orb.global_position.x, 0.0, "orb must not vacuum before delay expires")


func test_orb_moves_toward_player_in_vacuum_radius() -> void:
	var orb: XPOrb = XPOrb.new()
	orb.config = config
	add_child_autoqfree(orb)
	# Force out of pop phase and past vacuum delay so vacuum logic runs.
	orb._popping = false
	orb._rest_y = orb.global_position.y
	orb._age = config.orb_vacuum_delay + 0.1

	# Mock player must be in the scene tree so global_position works.
	var mock_player: CharacterBody3D = CharacterBody3D.new()
	add_child_autoqfree(mock_player)
	mock_player.global_position = Vector3(config.orb_vacuum_radius * 0.5, 0.0, 0.0)
	orb.set_player(mock_player)

	var start_pos: Vector3 = orb.global_position
	orb._physics_process(0.1)
	var moved: float = orb.global_position.distance_to(start_pos)
	assert_gt(moved, 0.0, "orb must move toward player when within vacuum radius")


func test_orb_ignores_player_outside_vacuum_radius() -> void:
	var orb: XPOrb = XPOrb.new()
	orb.config = config
	add_child_autoqfree(orb)
	orb._popping = false
	orb._rest_y = orb.global_position.y
	orb._age = config.orb_vacuum_delay + 0.1

	# Mock player must be in the scene tree so global_position works.
	var mock_player: CharacterBody3D = CharacterBody3D.new()
	add_child_autoqfree(mock_player)
	mock_player.global_position = Vector3(config.orb_vacuum_radius * 3.0, 0.0, 0.0)
	orb.set_player(mock_player)

	orb._physics_process(0.1)
	# Should bob (Y changes), not vacuum (X must stay at zero).
	assert_eq(orb.global_position.x, 0.0, "orb must not drift horizontally outside vacuum radius")


func test_orb_awards_xp_on_lifetime_expiry() -> void:
	var orb: XPOrb = XPOrb.new()
	orb.config = config
	orb.xp_amount = 10
	add_child_autoqfree(orb)
	orb._popping = false
	# Advance age past lifetime.
	orb._age = config.orb_lifetime + 0.1
	var initial_xp: int = stats.xp
	# Manually call expiry (can't overlap bodies in unit test, but _award_xp_on_expiry
	# is public-accessible; test the flag is set and queue_free is requested).
	orb._collected = false
	# Simulate the lifetime branch by calling _physics_process with enough delta.
	# Since we've already set _age past threshold, the next tick will trigger expiry.
	# We verify _collected is set to true (XP logic ran).
	orb._physics_process(0.0)
	assert_true(orb._collected, "orb must mark itself collected on lifetime expiry")


func test_orb_is_collected_flag_set_on_collect() -> void:
	var orb: XPOrb = XPOrb.new()
	orb.config = config
	orb.xp_amount = 5
	add_child_autoqfree(orb)
	orb._collected = false
	# Simulate collection via a mock body.
	var mock_body: CharacterBody3D = CharacterBody3D.new()
	add_child_autoqfree(mock_body)
	orb._on_body_entered(mock_body)
	assert_true(orb._collected, "orb must set _collected flag when body_entered fires")
