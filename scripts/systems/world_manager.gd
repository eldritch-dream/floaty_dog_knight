extends Node
## Autoload singleton. Handles scene transitions and spawn point lookup.
## Registered as "WorldManager" in Project Settings → Autoload.
## Register in Project Settings → Autoload as "WorldManager".

## Emitted just before the scene swap begins.
signal travel_started(destination: String)
## Emitted after the new scene is fully loaded and ready.
signal travel_completed(destination: String)

## The spawn point name the player should use on the next scene load.
var _pending_spawn_point: String = ""
## Whether a travel is currently in progress (guard against double calls).
var _travelling: bool = false


## Transition to a new scene, landing at the named spawn point.
## The call is deferred so the current physics frame finishes cleanly.
func travel_to(scene_path: String, spawn_point: String = "") -> void:
	if _travelling:
		return
	_travelling = true
	_pending_spawn_point = spawn_point
	travel_started.emit(scene_path)
	# Save before the scene swaps so stats are captured at the transition point.
	SaveManager.save_game(scene_path)
	# Defer the actual swap so physics/signal handlers in the current frame finish.
	call_deferred("_do_travel", scene_path)


func _do_travel(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
	# Mark as done. The new scene's _ready() calls on_scene_ready() if needed.
	_travelling = false
	travel_completed.emit(scene_path)


## Called by new scene's player after _ready() to retrieve the spawn point name.
func consume_spawn_point() -> String:
	var point := _pending_spawn_point
	_pending_spawn_point = ""
	return point
