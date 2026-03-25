extends CanvasLayer
## Autoload singleton. Displays NPC dialogue lines one at a time.
## Register as "DialogueBox" via scenes/ui/dialogue_box.tscn in Project Settings → Autoload.
##
## Interface (must not change — this is the seam for future visual upgrades):
##   show_dialogue(npc_id, lines, player) → opens box, disables player, shows first line
##   close()                              → restores player, hides box, emits signal
##   is_open() → bool
##   advance_line()                       → advance to next line (also called internally on input)
##
## SEAM: replace the Panel contents in a future session with a portrait + styled text box.
## The show_dialogue() / close() interface must remain unchanged.

signal dialogue_finished(npc_id: String)

var _npc_id: String = ""
var _lines: Array[String] = []
var _current_index: int = 0
var _is_open: bool = false
var _player: Node = null

@onready var _speaker_label: Label = $Panel/SpeakerLabel
@onready var _line_label: Label = $Panel/LineLabel
@onready var _prompt_label: Label = $Panel/PromptLabel


func _process(_delta: float) -> void:
	if not _is_open:
		return
	if Input.is_action_just_pressed("ui_interact"):
		advance_line()


# ── Public API ────────────────────────────────────────────────────────────────

func show_dialogue(npc_id: String, lines: Array[String], player: Node) -> void:
	if lines.is_empty():
		return
	_npc_id = npc_id
	_lines = lines
	_current_index = 0
	_player = player
	_is_open = true
	_disable_player()
	visible = true
	AudioManager.play_sfx("dialogue_open")
	_show_current_line()


func close() -> void:
	_is_open = false
	visible = false
	AudioManager.play_sfx("dialogue_close")
	_restore_player()
	_player = null
	dialogue_finished.emit(_npc_id)


func is_open() -> bool:
	return _is_open


## Advance to the next line. Closes on last line. Safe to call from tests.
func advance_line() -> void:
	AudioManager.play_sfx("dialogue_advance")
	_current_index += 1
	if _current_index >= _lines.size():
		close()
	else:
		_show_current_line()


# ── Private ───────────────────────────────────────────────────────────────────

func _show_current_line() -> void:
	_line_label.text = _lines[_current_index]
	var is_last: bool = _current_index >= _lines.size() - 1
	_prompt_label.text = "[ E ] Close" if is_last else "[ E ] Continue"


func _disable_player() -> void:
	if not _player:
		return
	var sm: Node = _player.get("state_machine") as Node
	if sm:
		sm.set_physics_process(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _restore_player() -> void:
	if not _player:
		return
	var sm: Node = _player.get("state_machine") as Node
	if sm:
		sm.set_physics_process(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
