class_name Portal
extends Area3D
## Scene transition trigger. When the player enters, calls WorldManager.travel_to().

## Path of the scene to load (e.g. "res://scenes/world/zone_01.tscn").
@export var destination_scene: String = ""
## Name of the spawn point marker in the destination scene.
@export var destination_spawn_point: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	if destination_scene.is_empty():
		push_warning("Portal: destination_scene is not set.")
		return
	WorldManager.travel_to(destination_scene, destination_spawn_point)
