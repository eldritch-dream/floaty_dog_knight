extends GutTest
## Tests for DialogueBox — open/close, line advance, empty-guard, signal emission.
## DialogueBox is an autoload (CanvasLayer singleton) — tests call its API directly
## and restore state in after_each so subsequent tests start clean.

var _finished_npc_id: String = ""


func before_each() -> void:
	_finished_npc_id = ""
	# Ensure the box starts closed regardless of previous test state.
	if DialogueBox.is_open():
		DialogueBox.close()


func after_each() -> void:
	if DialogueBox.is_open():
		DialogueBox.close()
	if DialogueBox.dialogue_finished.is_connected(_on_finished):
		DialogueBox.dialogue_finished.disconnect(_on_finished)


func _on_finished(npc_id: String) -> void:
	_finished_npc_id = npc_id


# ── initial state ──────────────────────────────────────────────────────────

func test_is_open_false_initially() -> void:
	assert_false(DialogueBox.is_open(), "box must start closed")


# ── show_dialogue ──────────────────────────────────────────────────────────

func test_show_dialogue_opens_box() -> void:
	var lines: Array[String] = ["Hello."]
	DialogueBox.show_dialogue("owner", lines, null)
	assert_true(DialogueBox.is_open())


func test_show_dialogue_with_empty_lines_does_not_open() -> void:
	var lines: Array[String] = []
	DialogueBox.show_dialogue("owner", lines, null)
	assert_false(DialogueBox.is_open(), "empty lines must not open the box")


# ── advance_line ───────────────────────────────────────────────────────────

func test_advance_line_keeps_box_open_on_multiline() -> void:
	var lines: Array[String] = ["Line one.", "Line two."]
	DialogueBox.show_dialogue("owner", lines, null)
	DialogueBox.advance_line()
	assert_true(DialogueBox.is_open(), "box must stay open after first of two lines")


func test_advance_line_on_last_line_closes_box() -> void:
	var lines: Array[String] = ["Only line."]
	DialogueBox.show_dialogue("owner", lines, null)
	DialogueBox.advance_line()
	assert_false(DialogueBox.is_open(), "box must close after advancing past last line")


# ── signal ─────────────────────────────────────────────────────────────────

func test_close_emits_dialogue_finished_with_npc_id() -> void:
	DialogueBox.dialogue_finished.connect(_on_finished)
	var lines: Array[String] = ["Farewell."]
	DialogueBox.show_dialogue("owner", lines, null)
	DialogueBox.close()
	assert_eq(_finished_npc_id, "owner", "dialogue_finished must emit the npc_id")
