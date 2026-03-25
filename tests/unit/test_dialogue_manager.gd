extends GutTest
## Tests for DialogueManager — event tracking, state transitions, one-shots,
## conditional overlay states, and save persistence.
## Each test calls _reset_for_test() to clear in-memory state.
## The test NPC lives at assets/dialogue/test_npc.json.

const TEST_NPC: String = "test_npc"
const TEMP_SAVE: String = "user://test_dm_tmp.json"

var _stats: PlayerStats


func before_each() -> void:
	DialogueManager._reset_for_test()
	_stats = PlayerStats.new()
	_stats.level = 1
	SaveManager._stats = _stats
	SaveManager.save_path = TEMP_SAVE


func after_each() -> void:
	DialogueManager._reset_for_test()
	SaveManager._stats = null
	SaveManager.save_path = "user://save.json"
	if FileAccess.file_exists(TEMP_SAVE):
		DirAccess.remove_absolute(TEMP_SAVE)


# ── has_fired / fire_event ─────────────────────────────────────────────────

func test_fire_event_records_event() -> void:
	DialogueManager.fire_event("test_event")
	assert_true(DialogueManager.has_fired("test_event"))


func test_has_fired_returns_false_for_unfired_event() -> void:
	assert_false(DialogueManager.has_fired("never_fired"))


func test_fire_event_is_idempotent() -> void:
	DialogueManager.fire_event("test_event")
	DialogueManager.fire_event("test_event")
	assert_true(DialogueManager.has_fired("test_event"))


# ── get_current_lines ─────────────────────────────────────────────────────

func test_get_current_lines_returns_initial_state_lines() -> void:
	var lines: Array[String] = DialogueManager.get_current_lines(TEST_NPC)
	assert_false(lines.is_empty(), "initial state should have lines")
	assert_eq(lines[0], "Hello.")


func test_get_current_lines_returns_empty_for_unknown_npc() -> void:
	var lines: Array[String] = DialogueManager.get_current_lines("no_such_npc")
	assert_true(lines.is_empty())


# ── state transitions ─────────────────────────────────────────────────────

func test_state_transitions_on_event() -> void:
	DialogueManager.get_current_lines(TEST_NPC)  # prime the cache
	DialogueManager.fire_event("test_event")
	var lines: Array[String] = DialogueManager.get_current_lines(TEST_NPC)
	assert_eq(lines[0], "Goodbye.")


func test_state_does_not_transition_on_wrong_event() -> void:
	DialogueManager.get_current_lines(TEST_NPC)  # prime the cache
	DialogueManager.fire_event("unrelated_event")
	var lines: Array[String] = DialogueManager.get_current_lines(TEST_NPC)
	assert_eq(lines[0], "Hello.", "wrong event must not advance state")


func test_get_npc_state_returns_initial_before_any_event() -> void:
	var state: String = DialogueManager.get_npc_state(TEST_NPC)
	assert_eq(state, "start")


func test_get_npc_state_returns_new_state_after_transition() -> void:
	DialogueManager.get_current_lines(TEST_NPC)  # prime the cache
	DialogueManager.fire_event("test_event")
	assert_eq(DialogueManager.get_npc_state(TEST_NPC), "after")


# ── one-shot lines ────────────────────────────────────────────────────────

func test_one_shot_line_shown_on_first_view() -> void:
	var lines: Array[String] = DialogueManager.get_current_lines(TEST_NPC)
	assert_true(lines.has("Welcome!"), "one-shot must appear on first view")


func test_one_shot_line_hidden_after_first_view() -> void:
	DialogueManager.get_current_lines(TEST_NPC)  # first view marks it seen
	var lines: Array[String] = DialogueManager.get_current_lines(TEST_NPC)
	assert_false(lines.has("Welcome!"), "one-shot must not appear on second view")


func test_non_one_shot_line_still_shown_after_one_shot_consumed() -> void:
	DialogueManager.get_current_lines(TEST_NPC)  # consume one-shot
	var lines: Array[String] = DialogueManager.get_current_lines(TEST_NPC)
	assert_true(lines.has("Hello."), "normal line must still appear after one-shot consumed")


# ── conditional overlay ───────────────────────────────────────────────────

func test_conditional_state_not_shown_below_level_threshold() -> void:
	_stats.level = 1  # below player_level_gte: 5
	var lines: Array[String] = DialogueManager.get_current_lines(TEST_NPC)
	assert_false(lines.has("Veteran line."), "conditional state must not show below threshold")


func test_conditional_state_shown_at_or_above_level_threshold() -> void:
	_stats.level = 5  # meets player_level_gte: 5
	var lines: Array[String] = DialogueManager.get_current_lines(TEST_NPC)
	assert_true(lines.has("Veteran line."), "conditional state must show at threshold")


# ── talked-state event ───────────────────────────────────────────────────

func test_finishing_dialogue_fires_talked_state_event() -> void:
	SaveManager._unlocks = AbilityUnlocks.new()
	SaveManager.save_game("")
	DialogueManager.get_current_lines(TEST_NPC)  # prime cache; state = "start"
	var lines: Array[String] = ["Hello."]
	DialogueBox.show_dialogue(TEST_NPC, lines, null)
	DialogueBox.close()
	assert_true(DialogueManager.has_fired("test_npc_talked_start"),
		"closing dialogue must fire {npc_id}_talked_{state} event")


func test_talked_event_reflects_current_state() -> void:
	SaveManager._unlocks = AbilityUnlocks.new()
	SaveManager.save_game("")
	DialogueManager.get_current_lines(TEST_NPC)  # prime cache
	DialogueManager.fire_event("test_event")      # transitions to "after"
	var lines: Array[String] = ["Goodbye."]
	DialogueBox.show_dialogue(TEST_NPC, lines, null)
	DialogueBox.close()
	assert_true(DialogueManager.has_fired("test_npc_talked_after"),
		"talked event must use the state at time of closing, not the initial state")


# ── save persistence round-trip ───────────────────────────────────────────

func test_fired_event_survives_session_reload() -> void:
	SaveManager._unlocks = AbilityUnlocks.new()
	SaveManager.save_game("")  # create a base save
	DialogueManager.fire_event("test_event")  # _save() writes to temp file
	DialogueManager._reset_for_test()
	DialogueManager._load_from_save()
	assert_true(DialogueManager.has_fired("test_event"),
		"fired event must still be recorded after reset + reload")


func test_npc_state_survives_session_reload() -> void:
	SaveManager._unlocks = AbilityUnlocks.new()
	SaveManager.save_game("")
	DialogueManager.get_current_lines(TEST_NPC)  # prime cache
	DialogueManager.fire_event("test_event")     # transitions to "after"
	assert_eq(DialogueManager.get_npc_state(TEST_NPC), "after")
	DialogueManager._reset_for_test()
	DialogueManager._load_from_save()
	assert_eq(DialogueManager.get_npc_state(TEST_NPC), "after",
		"npc state must be restored to 'after' after reset + reload")


func test_one_shot_seen_survives_session_reload() -> void:
	SaveManager._unlocks = AbilityUnlocks.new()
	SaveManager.save_game("")
	DialogueManager.get_current_lines(TEST_NPC)  # marks one-shot as seen, calls _save()
	DialogueManager._reset_for_test()
	DialogueManager._load_from_save()
	var lines: Array[String] = DialogueManager.get_current_lines(TEST_NPC)
	assert_false(lines.has("Welcome!"),
		"one-shot must remain consumed after reset + reload")
