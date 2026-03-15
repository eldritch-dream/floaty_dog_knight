class_name PlayerState
extends Node
## Base class for all player states. Subclass and override virtual methods.

## Reference to the player CharacterBody3D. Set by StateMachine on _ready.
var player: CharacterBody3D
## Reference to the GameConfig resource. Set by StateMachine on _ready.
var config: GameConfig


## Called when this state becomes active.
func enter() -> void:
	pass


## Called when this state is exited.
func exit() -> void:
	pass


## Called every frame while this state is active (maps to _process).
func update(_delta: float) -> void:
	pass


## Called every physics frame while this state is active (maps to _physics_process).
func physics_update(_delta: float) -> void:
	pass
