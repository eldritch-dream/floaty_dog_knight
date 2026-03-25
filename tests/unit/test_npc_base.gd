extends GutTest
## Tests for NpcBase — prompt visibility, collision radius sync, range detection.
## Instantiates npc_base.tscn and adds it to the scene tree so @onready vars resolve.

const NPC_SCENE: PackedScene = preload("res://scenes/world/npc_base.tscn")

var _npc: NpcBase


func before_each() -> void:
	_npc = NPC_SCENE.instantiate() as NpcBase
	_npc.npc_id = "test_npc"
	add_child(_npc)


func after_each() -> void:
	_npc.queue_free()
	_npc = null


# ── prompt visibility ──────────────────────────────────────────────────────

func test_interact_prompt_hidden_on_ready() -> void:
	var prompt: Label3D = _npc.get_node("InteractPrompt") as Label3D
	assert_false(prompt.visible, "prompt must start hidden")


func test_interact_prompt_shown_when_body_enters() -> void:
	var stub_body: CharacterBody3D = CharacterBody3D.new()
	add_child(stub_body)
	_npc._on_body_entered(stub_body)
	var prompt: Label3D = _npc.get_node("InteractPrompt") as Label3D
	assert_true(prompt.visible, "prompt must show when CharacterBody3D enters zone")
	stub_body.queue_free()


func test_interact_prompt_hidden_when_body_exits() -> void:
	var stub_body: CharacterBody3D = CharacterBody3D.new()
	add_child(stub_body)
	_npc._on_body_entered(stub_body)
	_npc._on_body_exited(stub_body)
	var prompt: Label3D = _npc.get_node("InteractPrompt") as Label3D
	assert_false(prompt.visible, "prompt must hide when the same body exits")
	stub_body.queue_free()


# ── collision shape ────────────────────────────────────────────────────────

func test_collision_shape_radius_matches_interact_radius_export() -> void:
	# interact_radius default is 2.5; _ready() creates the shape from this value.
	var col: CollisionShape3D = _npc.get_node("InteractZone/CollisionShape3D")
	var sphere: SphereShape3D = col.shape as SphereShape3D
	assert_eq(sphere.radius, _npc.interact_radius,
		"collision sphere radius must match interact_radius export at ready")


# ── range state ────────────────────────────────────────────────────────────

func test_not_in_range_by_default() -> void:
	assert_false(_npc._in_range, "_in_range must be false before any body enters")
