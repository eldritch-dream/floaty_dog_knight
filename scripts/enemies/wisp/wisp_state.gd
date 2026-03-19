class_name WispState
extends Node
## Base class for all Wisp enemy states.
## Subclass and override the virtual methods below.

## Reference to the WispEnemy CharacterBody3D. Set by WispStateMachine on _ready.
var wisp: CharacterBody3D
## Reference to the shared GameConfig resource.
var config: GameConfig
## Reference to the Wisp's EnemyStats resource.
var enemy_stats: EnemyStats


## Called when this state becomes active.
func enter() -> void:
	pass


## Called when this state is exited.
func exit() -> void:
	pass


## Called every physics frame while this state is active.
func physics_update(_delta: float) -> void:
	pass
