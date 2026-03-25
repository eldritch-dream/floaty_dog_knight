class_name NpcBase
extends Node3D
## Base class for all interactive NPCs.
## Place npc_base.tscn in any scene, set npc_id to match assets/dialogue/{npc_id}.json.
## Dialogue content lives entirely in the JSON file — this script never knows the lines.

## Matches the filename in assets/dialogue/ (without extension).
@export var npc_id: String = ""
## Radius at which the interaction prompt appears and E-to-talk becomes available.
@export var interact_radius: float = 2.5
## Input action to trigger interaction. Matches the project's registered action name.
@export var interact_action: String = "ui_interact"

var _in_range: bool = false
var _player: CharacterBody3D = null


func _ready() -> void:
	var zone: Area3D = $InteractZone
	zone.body_entered.connect(_on_body_entered)
	zone.body_exited.connect(_on_body_exited)
	# Sync the collision sphere radius to the export value.
	var col: CollisionShape3D = $InteractZone/CollisionShape3D
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = interact_radius
	col.shape = sphere


func _process(_delta: float) -> void:
	if not _in_range:
		return
	if not Input.is_action_just_pressed(interact_action):
		return
	if DialogueBox.is_open():
		return
	var lines: Array[String] = DialogueManager.get_current_lines(npc_id)
	if lines.is_empty():
		return
	DialogueBox.show_dialogue(npc_id, lines, _player)


func _on_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	_in_range = true
	_player = body as CharacterBody3D
	$InteractPrompt.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body != _player:
		return
	_in_range = false
	_player = null
	$InteractPrompt.visible = false
