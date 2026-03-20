class_name WispStateMachine
extends Node
## Lightweight state machine for the Eldritch Wisp.
## Mirrors the player StateMachine pattern.

signal state_changed(new_state_name: String)

## Currently active state.
var current_state: WispState

## All registered states keyed by lowercase name.
var states: Dictionary = {}


## Called explicitly by WispEnemy._ready() after enemy_stats is created.
## Avoids Godot's bottom-up _ready() order leaving enemy_stats null.
func setup(p_wisp: CharacterBody3D, p_config: GameConfig, p_enemy_stats: EnemyStats) -> void:
	for child in get_children():
		if child is WispState:
			states[child.name.to_lower()] = child
			child.wisp = p_wisp
			child.config = p_config
			child.enemy_stats = p_enemy_stats

	if states.size() > 0:
		current_state = states.values()[0]
		current_state.enter()


func transition_to(state_name: String) -> void:
	if not states.has(state_name):
		push_warning("WispStateMachine: no state named '%s'" % state_name)
		return
	if current_state:
		current_state.exit()
	current_state = states[state_name]
	current_state.enter()
	state_changed.emit(state_name)


func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
