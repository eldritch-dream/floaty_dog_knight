class_name DogBed
extends StaticBody3D
## Interactable rest point. Player presses ui_interact when in range to enter
## the Dream and allocate stat points.
##
## Placement rules:
##   - The scene node NAME must match bed_id (e.g. node "hub_bed", bed_id = "hub_bed").
##     This doubles as the spawn point name for WorldManager.travel_to().
##   - bed_scene_path auto-populates in _ready() from scene_file_path — never
##     hardcode it in the Inspector.
##   - bed_id naming convention: {zone_name}_bed  (hub_bed, zone_01_bed, ...)

@export var config: GameConfig
## Unique identifier. Must match this node's name in the scene tree.
@export var bed_id: String = "bed_default"
## Scene path this bed lives in. Auto-populated from scene_file_path in _ready().
@export var bed_scene_path: String = ""

var _player_in_range: bool = false
var _interact_prompt: Label3D
var _interact_zone: Area3D


func _ready() -> void:
	if bed_scene_path.is_empty():
		bed_scene_path = get_tree().current_scene.scene_file_path

	_interact_prompt = get_node_or_null("InteractPrompt") as Label3D
	_interact_zone = get_node_or_null("InteractZone") as Area3D

	if _interact_prompt:
		_interact_prompt.visible = false

	if _interact_zone:
		_interact_zone.body_entered.connect(_on_body_entered)
		_interact_zone.body_exited.connect(_on_body_exited)

	# Set interact radius from config.
	if config and _interact_zone:
		var shape_node: CollisionShape3D = _interact_zone.get_node_or_null(
				"CollisionShape3D") as CollisionShape3D
		if shape_node and shape_node.shape is SphereShape3D:
			(shape_node.shape as SphereShape3D).radius = config.dog_bed_interact_radius


func _unhandled_input(event: InputEvent) -> void:
	if not _player_in_range:
		return
	if event.is_action_pressed(config.dream_enter_key if config else "ui_interact"):
		DreamManager.enter_dream(self)


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.get("is_in_dream") != null:
		_player_in_range = true
		if _interact_prompt:
			_interact_prompt.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D and body.get("is_in_dream") != null:
		_player_in_range = false
		if _interact_prompt:
			_interact_prompt.visible = false
