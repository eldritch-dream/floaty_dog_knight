class_name StateMachine
extends Node
## Generic state machine. Add PlayerState children to define available states.
## Call transition_to(state_name) to switch states.

## Emitted when the state changes. Useful for animation/debug.
signal state_changed(old_state_name: String, new_state_name: String)

## The currently active state node.
var current_state: PlayerState
## Dictionary mapping state names (lowercase) to state nodes.
var states: Dictionary = {}

@export var initial_state: NodePath


func _ready() -> void:
	# Register all PlayerState children.
	for child in get_children():
		if child is PlayerState:
			states[child.name.to_lower()] = child
			child.player = get_parent()
			# Config is set from the player script after _ready.

	# Activate the initial state.
	if initial_state:
		var node = get_node(initial_state)
		if node and node is PlayerState:
			current_state = node
			current_state.enter()


func set_config(config: GameConfig) -> void:
	for state_node: PlayerState in states.values():
		state_node.config = config


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


## Transition from the current state to the named state.
func transition_to(target_state_name: String) -> void:
	var key := target_state_name.to_lower()
	if not states.has(key):
		print("StateMachine: no state named '%s'" % target_state_name)
		return
	var new_state: PlayerState = states[key]
	if new_state == current_state:
		return

	var old_name: String = current_state.name if current_state else ""
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()
	state_changed.emit(old_name, current_state.name)
