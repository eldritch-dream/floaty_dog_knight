extends GutTest
## Tests for jump arc physics calculations.
## Validates peak height, time-to-peak, and fall multiplier effect.

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()
	config.jump_velocity = 12.0
	config.gravity_scale = 1.5
	config.fall_multiplier = 2.5


func test_peak_height_matches_formula() -> void:
	# Peak height = v^2 / (2 * g)
	# g = default_gravity * gravity_scale
	var g := 9.8 * config.gravity_scale  # 14.7
	var expected_peak := (config.jump_velocity ** 2) / (2.0 * g)
	# Simulate: step through physics until velocity crosses zero.
	var vel_y := config.jump_velocity
	var height := 0.0
	var dt := 1.0 / 60.0  # 60 FPS
	while vel_y > 0.0:
		vel_y -= g * dt
		height += vel_y * dt
	# Allow 5% tolerance for discrete stepping.
	assert_almost_eq(height, expected_peak, expected_peak * 0.05,
		"Peak height should match v²/(2g) within 5%%")


func test_time_to_peak() -> void:
	# Time to peak = v / g
	var g := 9.8 * config.gravity_scale
	var expected_time := config.jump_velocity / g
	var vel_y := config.jump_velocity
	var dt := 1.0 / 60.0
	var time := 0.0
	while vel_y > 0.0:
		vel_y -= g * dt
		time += dt
	assert_almost_eq(time, expected_time, dt * 2.0,
		"Time to peak should match v/g within 2 frames")


func test_fall_multiplier_increases_descent_speed() -> void:
	# After reaching peak, falling with fall_multiplier should be faster
	# than falling without it.
	var g := 9.8 * config.gravity_scale
	var g_fall := g * config.fall_multiplier
	var dt := 1.0 / 60.0
	var vel_normal := 0.0
	var vel_fast := 0.0
	# Simulate 30 frames of falling.
	for i in 30:
		vel_normal -= g * dt
		vel_fast -= g_fall * dt
	assert_gt(abs(vel_fast), abs(vel_normal),
		"Fall velocity with multiplier should be greater than without")


func test_fall_multiplier_ratio() -> void:
	# After the same number of frames, the fall speed ratio should match
	# the fall_multiplier.
	var g := 9.8 * config.gravity_scale
	var dt := 1.0 / 60.0
	var vel_normal := 0.0
	var vel_fast := 0.0
	for i in 10:
		vel_normal -= g * dt
		vel_fast -= g * config.fall_multiplier * dt
	var ratio := vel_fast / vel_normal
	assert_almost_eq(ratio, config.fall_multiplier, 0.01,
		"Fall speed ratio should equal fall_multiplier")
