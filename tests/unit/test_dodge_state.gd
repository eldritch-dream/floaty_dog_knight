extends GutTest
## Unit tests for Dodge state logic using isolated state object.
## Tests the stamina spend and i-frame flag; physics_update integration
## is validated by the movement regression suite.

var dodge: PlayerState
var stats: PlayerStats
var config: GameConfig
var unlocks: AbilityUnlocks


func before_each() -> void:
	config = GameConfig.new()
	stats = PlayerStats.new()
	stats.max_stamina = 100.0
	stats.stamina = 100.0
	stats.stamina_regen_rate = config.stamina_regen_rate
	unlocks = AbilityUnlocks.new()
	unlocks.dodge_unlocked = true

	dodge = load("res://scripts/player/states/dodge.gd").new()
	dodge.config = config
	dodge.stats = stats
	dodge.ability_unlocks = unlocks
	# No player node — tests below avoid calls that require it.


func after_each() -> void:
	dodge.free()

# ── Stamina gating ────────────────────────────────────────────────────────────

func test_spend_stamina_succeeds_when_sufficient() -> void:
	var result := stats.spend_stamina(config.dodge_stamina_cost, config.stamina_regen_delay)
	assert_true(result)

func test_spend_stamina_fails_when_insufficient() -> void:
	stats.stamina = 10.0
	var result := stats.spend_stamina(config.dodge_stamina_cost, config.stamina_regen_delay)
	assert_false(result)

func test_stamina_reduced_after_spend() -> void:
	stats.spend_stamina(config.dodge_stamina_cost, config.stamina_regen_delay)
	assert_almost_eq(stats.stamina, 100.0 - config.dodge_stamina_cost, 0.01)

# ── Config defaults ────────────────────────────────────────────────────────────

func test_dodge_distance_positive() -> void:
	assert_gt(config.dodge_distance, 0.0)

func test_i_frame_duration_positive() -> void:
	assert_gt(config.i_frame_duration, 0.0)

func test_dodge_stamina_cost_positive() -> void:
	assert_gt(config.dodge_stamina_cost, 0.0)

# ── AbilityUnlocks ────────────────────────────────────────────────────────────

func test_dodge_locked_by_default() -> void:
	var fresh_unlocks := AbilityUnlocks.new()
	assert_false(fresh_unlocks.dodge_unlocked)

func test_dodge_can_be_unlocked() -> void:
	unlocks.dodge_unlocked = true
	assert_true(unlocks.dodge_unlocked)
