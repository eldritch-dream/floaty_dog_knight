extends Node
## Autoload singleton. Owns all dialogue state and event tracking.
## Register as "DialogueManager" in Project Settings → Autoload.
##
## NPC dialogue data lives in assets/dialogue/{npc_id}.json — one file per NPC.
## This singleton loads and caches those files, tracks NPC state transitions,
## and persists everything through SaveManager.
##
## Consumers:
##   NpcBase calls get_current_lines(npc_id) → shows lines in DialogueBox
##   Game code calls fire_event(WorldEvents.SOME_EVENT) → advances NPC states
##   DialogueBox calls nothing here — it operates on the lines array it received

signal event_fired(event_name: String)

## In-memory mirrors of the three SaveData dialogue fields.
## Loaded from save in _ready(), persisted via _save() on every change.
var _npc_states: Dictionary = {}
var _fired_events: Array = []
var _one_shots_seen: Array = []

## Parsed JSON data per NPC, cached for the session lifetime.
var _npc_cache: Dictionary = {}


func _ready() -> void:
	_load_from_save()


## Restore in-memory state from the current save file.
## Also callable from tests after _reset_for_test() to simulate a session reload.
func _load_from_save() -> void:
	var data: SaveData = SaveManager.load_game()
	if data:
		_npc_states = data.npc_states.duplicate()
		_fired_events = data.fired_events.duplicate()
		_one_shots_seen = data.one_shot_lines_seen.duplicate()


# ── Public API ────────────────────────────────────────────────────────────────

## Fire a world event. Records it, evaluates all cached NPC transitions,
## saves if anything changed, and emits event_fired.
## Idempotent — firing the same event twice has no additional effect.
func fire_event(event_name: String) -> void:
	if _fired_events.has(event_name):
		return
	_fired_events.append(event_name)
	var state_changed: bool = false
	for npc_id in _npc_cache:
		if _evaluate_transitions(npc_id, event_name):
			state_changed = true
	# Always save so fired_events is persisted, regardless of state changes.
	_save()
	if state_changed:
		pass  # _save() already called above
	event_fired.emit(event_name)


## Returns the display lines for an NPC's current state, filtered of seen one-shots.
## Calling this marks any newly-seen one-shot lines and saves.
## Returns an empty array if the NPC data file cannot be found.
func get_current_lines(npc_id: String) -> Array[String]:
	_load_npc_data(npc_id)
	if not _npc_cache.has(npc_id):
		return []
	var npc_data: Dictionary = _npc_cache[npc_id]
	var states: Dictionary = npc_data.get("states", {})
	# Conditional overlay states take priority — checked fresh each call.
	for state_name in states:
		var state_data: Dictionary = states[state_name]
		if state_data.has("condition"):
			if _check_condition(state_data["condition"]):
				return _filter_lines(npc_id, state_name, state_data.get("lines", []))
	# Fall back to the NPC's current state machine position.
	var initial: String = npc_data.get("initial_state", "default")
	var current: String = _npc_states.get(npc_id, initial)
	if not states.has(current):
		return []
	return _filter_lines(npc_id, current, states[current].get("lines", []))


## Returns true if the named event has ever been fired this save.
func has_fired(event_name: String) -> bool:
	return _fired_events.has(event_name)


## Returns the current state name for an NPC (falls back to initial_state).
func get_npc_state(npc_id: String) -> String:
	_load_npc_data(npc_id)
	if not _npc_cache.has(npc_id):
		return ""
	var initial: String = _npc_cache[npc_id].get("initial_state", "default")
	return _npc_states.get(npc_id, initial)


# ── Internal ──────────────────────────────────────────────────────────────────

## Load and cache NPC JSON data. No-op if already cached or if file is missing.
func _load_npc_data(npc_id: String) -> void:
	if _npc_cache.has(npc_id):
		return
	var path: String = "res://assets/dialogue/%s.json" % npc_id
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not f:
		print("DialogueManager: no dialogue file for '%s'" % npc_id)
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not parsed is Dictionary:
		print("DialogueManager: invalid JSON in '%s'" % path)
		return
	_npc_cache[npc_id] = parsed as Dictionary


## Check if the current state has a transition matching event_name and advance if so.
## Returns true if the state changed.
func _evaluate_transitions(npc_id: String, event_name: String) -> bool:
	if not _npc_cache.has(npc_id):
		return false
	var npc_data: Dictionary = _npc_cache[npc_id]
	var initial: String = npc_data.get("initial_state", "default")
	var current: String = _npc_states.get(npc_id, initial)
	var states: Dictionary = npc_data.get("states", {})
	if not states.has(current):
		return false
	var transitions: Array = states[current].get("transitions", [])
	for t in transitions:
		if t.get("event", "") != event_name:
			continue
		var next_state: String = t.get("next_state", "")
		if next_state.is_empty() or not states.has(next_state):
			continue
		_npc_states[npc_id] = next_state
		return true
	return false


## Evaluate a condition dictionary against live player stats.
## Supported keys: player_level_gte (int).
func _check_condition(condition: Dictionary) -> bool:
	if condition.has("player_level_gte"):
		var required: int = condition["player_level_gte"]
		var stats: PlayerStats = SaveManager._stats
		if stats:
			return stats.level >= required
		return false
	return false


## Return filtered display strings from a raw lines array.
## Strips seen one-shot lines; marks newly-encountered one-shots as seen.
func _filter_lines(npc_id: String, state_name: String,
		raw_lines: Array) -> Array[String]:
	var result: Array[String] = []
	var new_one_shots: Array = []
	for i in raw_lines.size():
		var entry = raw_lines[i]
		var text: String
		var is_one_shot: bool = false
		if entry is Dictionary:
			text = entry.get("text", "")
			is_one_shot = entry.get("one_shot", false)
		else:
			text = str(entry)
		var key: String = "%s_%s_%d" % [npc_id, state_name, i]
		if is_one_shot and _one_shots_seen.has(key):
			continue
		result.append(text)
		if is_one_shot:
			new_one_shots.append(key)
	if not new_one_shots.is_empty():
		_one_shots_seen.append_array(new_one_shots)
		_save()
	return result


## Merge in-memory dialogue state into the existing save and write.
## Reads current save first so stats/bed fields are preserved.
func _save() -> void:
	var data: SaveData = SaveManager.load_game()
	if data == null:
		data = SaveData.new()
	data.npc_states = _npc_states.duplicate()
	data.fired_events = _fired_events.duplicate()
	data.one_shot_lines_seen = _one_shots_seen.duplicate()
	SaveManager._write(JSON.stringify(data.to_dict()))


## Test helper — resets all in-memory state without touching the save file.
## Call in GUT before_each() to isolate tests.
func _reset_for_test() -> void:
	_npc_states = {}
	_fired_events = []
	_one_shots_seen = []
	_npc_cache = {}
