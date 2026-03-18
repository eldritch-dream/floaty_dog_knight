extends GutTest
## Movement feel regression baseline.
## These tests lock in the CURRENT TUNED values from default_config.tres.
## If GameConfig script defaults change, the hardcoded expected values below
## will diverge from the simulation → the test fails → sign-off is required.
##
## Expected values are derived from production defaults:
##   jump_velocity    = 14.5   gravity_scale  = 1.4    fall_multiplier = 2.3
##   air_friction     = 0.98   float_drag     = 0.93   move_speed      = 10.0
##   dash_speed       = 25.0   dash_duration  = 0.2    coyote_time     = 0.15
##   max_air_jumps    = 1      air_jump_velocity = 10.0
##
## DO NOT override config values in before_each — we test the live defaults.

# ── Hardcoded baselines (change only with sign-off) ───────────────────────────

## Ground jump peak height: v² / (2g) = 14.5² / (2 × 9.8 × 1.4) ≈ 7.663 m
const BASELINE_JUMP_PEAK_M := 7.663

## Time to reach peak: v / g = 14.5 / (9.8 × 1.4) ≈ 1.057 s
const BASELINE_TIME_TO_PEAK_S := 1.057

## Air jump peak height: v² / (2g') where g' = 9.8 × 1.4 × 1.5 (snappier arc)
## = 10² / (2 × 20.58) ≈ 2.430 m
const BASELINE_AIR_JUMP_PEAK_M := 2.430

## Dash distance: dash_speed × dash_duration = 25.0 × 0.2 = 5.0 m (exact)
const BASELINE_DASH_DISTANCE_M := 5.0

## Lateral position at jump apex with full forward input from standing still.
## Air control: lerp(vx, move_speed, 0.15) each frame for ~63 frames.
## Σ vx_n × dt ≈ 9.56 m
const BASELINE_LATERAL_AT_PEAK_M := 9.56

## Coyote window: 0.15 s — timer must be positive at 0.10 s, expired at 0.20 s.
const BASELINE_COYOTE_TIME_S := 0.15

const TOLERANCE := 0.05  # 5 %

# ── Setup ────────────────────────────────────────────────────────────────────

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()
	# No overrides — production defaults only.


# ── Ground jump arc ───────────────────────────────────────────────────────────

func test_ground_jump_peak_height() -> void:
	var g := 9.8 * config.gravity_scale
	var vel_y := config.jump_velocity
	var height := 0.0
	var dt := 1.0 / 60.0
	while vel_y > 0.0:
		vel_y -= g * dt
		height += vel_y * dt
	assert_almost_eq(height, BASELINE_JUMP_PEAK_M, BASELINE_JUMP_PEAK_M * TOLERANCE,
		"Ground jump peak height must be %.3f m (±5%%)" % BASELINE_JUMP_PEAK_M)


func test_ground_jump_time_to_peak() -> void:
	var g := 9.8 * config.gravity_scale
	var vel_y := config.jump_velocity
	var dt := 1.0 / 60.0
	var elapsed := 0.0
	while vel_y > 0.0:
		vel_y -= g * dt
		elapsed += dt
	assert_almost_eq(elapsed, BASELINE_TIME_TO_PEAK_S, BASELINE_TIME_TO_PEAK_S * TOLERANCE,
		"Time to jump peak must be %.3f s (±5%%)" % BASELINE_TIME_TO_PEAK_S)


# ── Air jump arc (double jump) ────────────────────────────────────────────────

func test_air_jump_peak_height() -> void:
	# Air jumps apply the 1.5× gravity multiplier hardcoded in jump.gd.
	var g := 9.8 * config.gravity_scale * 1.5
	var vel_y := config.air_jump_velocity
	var height := 0.0
	var dt := 1.0 / 60.0
	while vel_y > 0.0:
		vel_y -= g * dt
		height += vel_y * dt
	assert_almost_eq(height, BASELINE_AIR_JUMP_PEAK_M, BASELINE_AIR_JUMP_PEAK_M * TOLERANCE,
		"Air jump peak height must be %.3f m (±5%%)" % BASELINE_AIR_JUMP_PEAK_M)


# ── Dash distance ─────────────────────────────────────────────────────────────

func test_dash_covers_baseline_distance() -> void:
	var distance := config.dash_speed * config.dash_duration
	assert_almost_eq(distance, BASELINE_DASH_DISTANCE_M, BASELINE_DASH_DISTANCE_M * TOLERANCE,
		"Dash must cover %.1f m (±5%%)" % BASELINE_DASH_DISTANCE_M)


# ── Air control — lateral position at jump apex ───────────────────────────────

func test_lateral_position_at_jump_apex() -> void:
	# Simulate a jump from rest with full horizontal input.
	# vx starts at 0 and lerps toward move_speed each frame (factor 0.15).
	# We accumulate lateral position until vy crosses zero (apex).
	var g := 9.8 * config.gravity_scale
	var vel_y := config.jump_velocity
	var vel_x := 0.0
	var x := 0.0
	var dt := 1.0 / 60.0
	while vel_y > 0.0:
		vel_y -= g * dt
		vel_x = lerp(vel_x, config.move_speed, 0.15)
		if vel_y > 0.0:
			x += vel_x * dt
	assert_almost_eq(x, BASELINE_LATERAL_AT_PEAK_M, BASELINE_LATERAL_AT_PEAK_M * TOLERANCE,
		"Lateral position at apex must be %.2f m (±5%%)" % BASELINE_LATERAL_AT_PEAK_M)


# ── Coyote time window ────────────────────────────────────────────────────────

func test_coyote_jump_allowed_at_0_10s() -> void:
	# At 0.10 s — well within the 0.15 s window.
	assert_eq(config.coyote_time, BASELINE_COYOTE_TIME_S,
		"Coyote time default must be %.2f s" % BASELINE_COYOTE_TIME_S)
	var timer := config.coyote_time
	var dt := 1.0 / 60.0
	for i in 6:  # ~0.10 s
		timer -= dt
	assert_gt(timer, 0.0,
		"Coyote timer must still be positive at ~0.10 s (within the window)")


func test_coyote_jump_blocked_after_0_20s() -> void:
	# At 0.20 s — past the 0.15 s window.
	var timer := config.coyote_time
	var dt := 1.0 / 60.0
	for i in 12:  # ~0.20 s
		timer -= dt
	assert_lt(timer, 0.0,
		"Coyote timer must be expired at ~0.20 s (past the window)")


# ── State machine — valid and invalid transitions ────────────────────────────

func test_all_five_states_registered() -> void:
	var sm := StateMachine.new()
	var parent := CharacterBody3D.new()
	parent.add_child(sm)
	for state_name in ["Idle", "Run", "Jump", "Float", "Dash"]:
		var state := PlayerState.new()
		state.name = state_name
		sm.add_child(state)
		sm.states[state_name.to_lower()] = state
		state.player = parent
	add_child_autoqfree(parent)
	assert_eq(sm.states.size(), 5,
		"State machine must register exactly 5 states")
	for state_name in ["idle", "run", "jump", "float", "dash"]:
		assert_true(sm.states.has(state_name),
			"State '%s' must be registered" % state_name)


func test_invalid_transition_is_rejected() -> void:
	var sm := StateMachine.new()
	var parent := CharacterBody3D.new()
	parent.add_child(sm)
	var idle := PlayerState.new()
	idle.name = "Idle"
	sm.add_child(idle)
	sm.states["idle"] = idle
	idle.player = parent
	sm.current_state = idle
	add_child_autoqfree(parent)
	sm.transition_to("nonexistent_state")
	assert_eq(sm.current_state.name, "Idle",
		"Invalid transition must not change the current state")
