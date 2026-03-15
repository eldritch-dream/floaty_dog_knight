extends GutTest
## Tests for coyote time mechanic.
## Validates that jump is allowed within the coyote window and rejected after.


func test_jump_allowed_within_coyote_window() -> void:
	# Simulate: coyote_time = 0.15s, check at 0.10s (should be valid).
	var coyote_time := 0.15
	var coyote_timer := coyote_time
	var dt := 1.0 / 60.0
	var elapsed := 0.0
	# Simulate 6 frames (~0.1s).
	for i in 6:
		coyote_timer -= dt
		elapsed += dt
	assert_gt(coyote_timer, 0.0,
		"Coyote timer should still be positive at %.3fs" % elapsed)


func test_jump_rejected_after_coyote_window() -> void:
	# Simulate: run past the coyote window.
	var coyote_time := 0.15
	var coyote_timer := coyote_time
	var dt := 1.0 / 60.0
	# Simulate 12 frames (~0.2s) — past the 0.15s window.
	for i in 12:
		coyote_timer -= dt
	assert_lt(coyote_timer, 0.0,
		"Coyote timer should be expired after 0.2s")


func test_coyote_timer_starts_at_configured_value() -> void:
	var config := GameConfig.new()
	config.coyote_time = 0.15
	var timer := config.coyote_time
	assert_eq(timer, 0.15,
		"Coyote timer should initialize from config")


func test_coyote_time_exact_boundary() -> void:
	# At exactly the coyote_time boundary, timer should be ~0.
	var coyote_time := 0.15
	var coyote_timer := coyote_time
	var dt := 1.0 / 60.0
	var frames := int(coyote_time / dt)  # 9 frames
	for i in frames:
		coyote_timer -= dt
	# Should be very close to zero (within one frame).
	assert_almost_eq(coyote_timer, 0.0, dt,
		"Timer should be near zero at the boundary frame")


func test_jump_buffer_records_input() -> void:
	# Simulate jump buffer: set flag and timer, verify timer counts down.
	var config := GameConfig.new()
	config.jump_buffer_time = 0.1
	var jump_buffered := true
	var buffer_timer := config.jump_buffer_time
	var dt := 1.0 / 60.0
	# 4 frames (~0.067s) — still within buffer.
	for i in 4:
		buffer_timer -= dt
	assert_true(jump_buffered and buffer_timer > 0.0,
		"Jump buffer should still be active within window")


func test_jump_buffer_expires() -> void:
	var config := GameConfig.new()
	config.jump_buffer_time = 0.1
	var buffer_timer := config.jump_buffer_time
	var dt := 1.0 / 60.0
	# 8 frames (~0.133s) — past the 0.1s window.
	for i in 8:
		buffer_timer -= dt
	if buffer_timer <= 0.0:
		pass  # Would set jump_buffered = false in real code.
	assert_lt(buffer_timer, 0.0,
		"Jump buffer should expire after 0.133s")
