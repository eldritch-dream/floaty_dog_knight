extends GutTest
## Unit tests for AbilityUnlocks: default state and toggling.

var unlocks: AbilityUnlocks

func before_each() -> void:
	unlocks = AbilityUnlocks.new()

# ── Defaults ─────────────────────────────────────────────────────────────────

func test_double_jump_locked_by_default() -> void:
	assert_false(unlocks.double_jump_unlocked)

func test_dash_locked_by_default() -> void:
	assert_false(unlocks.dash_unlocked)

func test_dodge_locked_by_default() -> void:
	assert_false(unlocks.dodge_unlocked)

func test_light_attack_locked_by_default() -> void:
	assert_false(unlocks.light_attack_unlocked)

func test_heavy_attack_locked_by_default() -> void:
	assert_false(unlocks.heavy_attack_unlocked)

# ── Toggling ─────────────────────────────────────────────────────────────────

func test_unlock_double_jump() -> void:
	unlocks.double_jump_unlocked = true
	assert_true(unlocks.double_jump_unlocked)

func test_unlock_dash() -> void:
	unlocks.dash_unlocked = true
	assert_true(unlocks.dash_unlocked)

func test_unlock_dodge() -> void:
	unlocks.dodge_unlocked = true
	assert_true(unlocks.dodge_unlocked)

func test_unlock_light_attack() -> void:
	unlocks.light_attack_unlocked = true
	assert_true(unlocks.light_attack_unlocked)

func test_unlock_heavy_attack() -> void:
	unlocks.heavy_attack_unlocked = true
	assert_true(unlocks.heavy_attack_unlocked)

func test_unlocks_are_independent() -> void:
	unlocks.double_jump_unlocked = true
	assert_false(unlocks.dash_unlocked)
	assert_false(unlocks.dodge_unlocked)
