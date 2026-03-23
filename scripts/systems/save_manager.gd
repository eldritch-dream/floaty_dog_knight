extends Node
## Autoload singleton. Saves and loads game state.
## Register as "SaveManager" in Project Settings → Autoload.
##
## Web (primary):  JavaScriptBridge → localStorage key "doggo_knight_save"
## Desktop (fallback): FileAccess → save_path ("user://save.json")
##
## Call register_player() from Player._ready(). On the first call of a session
## (cold start) save data is automatically applied. Subsequent calls (scene
## transitions) skip the apply so in-memory stats are not overwritten.

const SAVE_KEY: String = "doggo_knight_save"

## Overridable in tests — point at a temp path to avoid polluting real saves.
var save_path: String = "user://save.json"

var _stats: PlayerStats = null
var _unlocks: AbilityUnlocks = null
var _session_active: bool = false


## Called from Player._ready() each scene load. Wires level-up autosave and,
## on cold start only, applies any existing save data to stats and unlocks.
func register_player(stats: PlayerStats, unlocks: AbilityUnlocks) -> void:
	_stats = stats
	_unlocks = unlocks
	if _stats and not _stats.leveled_up.is_connected(_on_level_up):
		_stats.leveled_up.connect(_on_level_up)
	if _stats and not _stats.xp_changed.is_connected(_on_xp_changed):
		_stats.xp_changed.connect(_on_xp_changed)
	if not _session_active:
		_session_active = true
		apply_save_if_exists(stats, unlocks)


## Write a save snapshot. Call on scene transition, respawn, and level-up.
func save_game(scene_path: String) -> void:
	if not _stats or not _unlocks:
		return
	var data: SaveData = SaveData.new()
	data.capture(_stats, _unlocks, scene_path)
	# Preserve respawn point — bed fields are written only by DreamManager._update_respawn_point()
	# and must survive every subsequent save_game() call.
	var existing: SaveData = load_game()
	if existing:
		data.last_bed_id = existing.last_bed_id
		data.last_bed_scene = existing.last_bed_scene
	_write(JSON.stringify(data.to_dict()))


## Load save data from storage. Returns null if no save exists.
func load_game() -> SaveData:
	var raw: String = _read()
	if raw.is_empty():
		return null
	var parsed: Variant = JSON.parse_string(raw)
	if not parsed is Dictionary:
		return null
	var data: SaveData = SaveData.new()
	data.from_dict(parsed as Dictionary)
	return data


## Apply save data to stats and unlocks if a save exists. No-op if no save.
func apply_save_if_exists(stats: PlayerStats, unlocks: AbilityUnlocks) -> void:
	var data: SaveData = load_game()
	if data:
		data.apply_to(stats, unlocks)


func has_save() -> bool:
	return not _read().is_empty()


func delete_save() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("localStorage.removeItem('%s')" % SAVE_KEY)
	else:
		if FileAccess.file_exists(save_path):
			DirAccess.remove_absolute(save_path)


# ── Storage layer ─────────────────────────────────────────────────────────────

func _write(json_str: String) -> void:
	if OS.has_feature("web"):
		# JSON.stringify wraps the string in quotes and escapes it safely for JS.
		JavaScriptBridge.eval(
			"localStorage.setItem('%s', %s)" % [SAVE_KEY, JSON.stringify(json_str)]
		)
	else:
		var f: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
		if f:
			f.store_string(json_str)


func _read() -> String:
	if OS.has_feature("web"):
		var result: Variant = JavaScriptBridge.eval(
			"localStorage.getItem('%s')" % SAVE_KEY
		)
		if result == null:
			return ""
		return str(result)
	if not FileAccess.file_exists(save_path):
		return ""
	var f: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if not f:
		return ""
	return f.get_as_text()


# ── Signal handlers ───────────────────────────────────────────────────────────

func _on_level_up(_new_level: int) -> void:
	var scene: Node = get_tree().current_scene
	var path: String = scene.scene_file_path if scene else ""
	save_game(path)


func _on_xp_changed(_new_xp: int) -> void:
	var scene: Node = get_tree().current_scene
	var path: String = scene.scene_file_path if scene else ""
	save_game(path)
