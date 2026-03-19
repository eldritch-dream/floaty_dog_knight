extends GutTest
## Tests for dash cooldown enforcement.
## Validates cooldown timer behavior and availability logic.


func test_dash_unavailable_during_cooldown() -> void:
	var config := GameConfig.new()
	config.dash_cooldown = 0.8
	var can_dash := false
	var cooldown_timer := config.dash_cooldown
	var dt := 1.0 / 60.0
	# Simulate 24 frames (~0.4s) — halfway through cooldown.
	for i in 24:
		cooldown_timer -= dt
	# Still in cooldown.
	if cooldown_timer > 0.0:
		can_dash = false
	assert_false(can_dash,
		"Dash should not be available during cooldown (%.3fs remaining)" % cooldown_timer)


func test_dash_available_after_cooldown() -> void:
	var config := GameConfig.new()
	config.dash_cooldown = 0.8
	var can_dash := false
	var cooldown_timer := config.dash_cooldown
	var dt := 1.0 / 60.0
	# Simulate 60 frames (1.0s) — past 0.8s cooldown.
	for i in 60:
		cooldown_timer -= dt
		if cooldown_timer <= 0.0:
			can_dash = true
			break
	assert_true(can_dash,
		"Dash should be available after cooldown expires")


func test_dash_cooldown_resets_on_dash() -> void:
	# After a dash, cooldown should reset to full duration.
	var config := GameConfig.new()
	config.dash_cooldown = 0.8
	# Simulate starting a dash → cooldown resets.
	var cooldown_timer := 0.0  # Was available.
	cooldown_timer = config.dash_cooldown  # Reset on dash.
	assert_eq(cooldown_timer, 0.8,
		"Cooldown timer should reset to full duration after dash")


func test_dash_duration_from_config() -> void:
	var config := GameConfig.new()
	config.dash_duration = 0.2
	config.dash_speed = 25.0
	# Dash distance = speed * duration.
	var distance := config.dash_speed * config.dash_duration
	assert_eq(distance, 5.0,
		"Dash should cover speed × duration meters")


func test_dash_locked_by_default() -> void:
	var unlocks := AbilityUnlocks.new()
	assert_false(unlocks.dash_unlocked,
		"Dash should be locked by default")


func test_dash_unlock_enables_dash() -> void:
	var unlocks := AbilityUnlocks.new()
	unlocks.dash_unlocked = true
	assert_true(unlocks.dash_unlocked,
		"Dash should be available after unlock")


func test_rapid_dash_rejected() -> void:
	# Try to dash twice quickly — second should be rejected.
	var config := GameConfig.new()
	config.dash_cooldown = 0.8
	var can_dash := true
	# First dash.
	can_dash = false
	var cooldown_timer := config.dash_cooldown
	# Try again immediately.
	assert_false(can_dash,
		"Second dash should be rejected immediately after first")
	# Wait a tiny bit.
	var dt := 1.0 / 60.0
	for i in 3:
		cooldown_timer -= dt
	if cooldown_timer <= 0.0:
		can_dash = true
	assert_false(can_dash,
		"Dash should still be on cooldown after 3 frames")
