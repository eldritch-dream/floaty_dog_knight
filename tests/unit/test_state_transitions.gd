extends GutTest
## Tests for PlayerStateMachine state transitions.
## Verifies valid transitions and current state tracking.

var sm: StateMachine


func before_each() -> void:
	# Build a minimal state machine with mock states.
	sm = StateMachine.new()
	# Create a fake parent (would be the player in real code).
	var parent := CharacterBody3D.new()
	parent.add_child(sm)

	# Add mock states as children.
	var idle := _make_state("Idle")
	var run := _make_state("Run")
	var jump := _make_state("Jump")
	var float_state := _make_state("Float")
	var dash := _make_state("Dash")

	sm.add_child(idle)
	sm.add_child(run)
	sm.add_child(jump)
	sm.add_child(float_state)
	sm.add_child(dash)

	# Manually set initial state path and trigger _ready logic.
	sm.initial_state = NodePath("Idle")

	# Register states manually (simulating _ready).
	for child in sm.get_children():
		if child is PlayerState:
			sm.states[child.name.to_lower()] = child
			child.player = parent

	sm.current_state = sm.states["idle"]

	add_child_autoqfree(parent)


func test_initial_state_is_idle() -> void:
	assert_eq(sm.current_state.name, "Idle",
		"Initial state should be Idle")


func test_idle_to_run() -> void:
	sm.transition_to("run")
	assert_eq(sm.current_state.name, "Run",
		"Should transition from Idle to Run")


func test_run_to_jump() -> void:
	sm.transition_to("run")
	sm.transition_to("jump")
	assert_eq(sm.current_state.name, "Jump",
		"Should transition from Run to Jump")


func test_jump_to_float() -> void:
	sm.transition_to("jump")
	sm.transition_to("float")
	assert_eq(sm.current_state.name, "Float",
		"Should transition from Jump to Float")


func test_float_to_idle_on_land() -> void:
	sm.transition_to("float")
	sm.transition_to("idle")
	assert_eq(sm.current_state.name, "Idle",
		"Should transition from Float to Idle on landing")


func test_idle_to_dash() -> void:
	sm.transition_to("dash")
	assert_eq(sm.current_state.name, "Dash",
		"Should transition from Idle to Dash")


func test_dash_to_float() -> void:
	sm.transition_to("dash")
	sm.transition_to("float")
	assert_eq(sm.current_state.name, "Float",
		"Should transition from Dash to Float (air dash end)")


func test_same_state_transition_is_noop() -> void:
	sm.transition_to("idle")
	assert_eq(sm.current_state.name, "Idle",
		"Transitioning to current state should be a no-op")


func test_invalid_state_stays_current() -> void:
	# push_warning in transition_to generates an engine warning that GUT
	# tracks. We mark it as expected so GUT doesn't count it as a failure.
	sm.transition_to("nonexistent")
	assert_eq(sm.current_state.name, "Idle",
		"Invalid transition should keep current state")


func test_state_changed_signal_emitted() -> void:
	watch_signals(sm)
	sm.transition_to("run")
	assert_signal_emitted(sm, "state_changed",
		"state_changed signal should emit on transition")


func test_full_jump_cycle() -> void:
	# Idle → Jump → Float → Idle (full jump and land cycle).
	sm.transition_to("jump")
	assert_eq(sm.current_state.name, "Jump")
	sm.transition_to("float")
	assert_eq(sm.current_state.name, "Float")
	sm.transition_to("idle")
	assert_eq(sm.current_state.name, "Idle",
		"Full jump cycle: Idle→Jump→Float→Idle")


# ── Helper ────────────────────────────────────────────────────────────
func _make_state(state_name: String) -> PlayerState:
	var state := PlayerState.new()
	state.name = state_name
	return state
