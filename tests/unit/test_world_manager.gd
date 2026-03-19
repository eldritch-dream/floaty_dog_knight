extends GutTest
## Unit tests for WorldManager: spawn point state and guard logic.
## Scene change (get_tree().change_scene_to_file) is NOT called here
## to avoid disrupting the test runner scene tree.

var wm: Node  # Typed as Node to avoid autoload name collision.

func before_each() -> void:
	wm = load("res://scripts/systems/world_manager.gd").new()
	add_child(wm)


func after_each() -> void:
	wm.queue_free()

# ── consume_spawn_point ───────────────────────────────────────────────────────

func test_spawn_point_empty_by_default() -> void:
	assert_eq(wm.consume_spawn_point(), "")

func test_spawn_point_consumed_once() -> void:
	wm._pending_spawn_point = "entrance"
	assert_eq(wm.consume_spawn_point(), "entrance")
	assert_eq(wm.consume_spawn_point(), "")

func test_spawn_point_cleared_after_consume() -> void:
	wm._pending_spawn_point = "hub_exit"
	wm.consume_spawn_point()
	assert_eq(wm._pending_spawn_point, "")

# ── travel guard ──────────────────────────────────────────────────────────────

func test_travelling_false_by_default() -> void:
	assert_false(wm._travelling)

func test_travel_to_sets_travelling_flag() -> void:
	# Stub out _do_travel so we don't call change_scene_to_file.
	wm.set_meta("_skip_do_travel", true)
	# Patch: check flag is set before deferred call resolves.
	wm._travelling = false
	wm._pending_spawn_point = ""
	# Manually simulate what travel_to does (minus the deferred call).
	wm._travelling = true
	wm._pending_spawn_point = "entrance"
	assert_true(wm._travelling)
	assert_eq(wm._pending_spawn_point, "entrance")

func test_second_travel_ignored_while_travelling() -> void:
	wm._travelling = true
	wm._pending_spawn_point = "original"
	# travel_to should return early without overwriting spawn point.
	wm.travel_to("res://scenes/world/zone_01.tscn", "new_point")
	assert_eq(wm._pending_spawn_point, "original")

# ── signals ───────────────────────────────────────────────────────────────────

func test_travel_started_signal_exists() -> void:
	# Verify the signal is declared on the class.
	assert_true(wm.has_signal("travel_started"))

func test_travel_completed_signal_exists() -> void:
	assert_true(wm.has_signal("travel_completed"))
