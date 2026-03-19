class_name PlayerState
extends Node
## Base class for all player states. Subclass and override virtual methods.

## Reference to the player CharacterBody3D. Set by StateMachine on _ready.
var player: CharacterBody3D
## Reference to the GameConfig resource. Set by StateMachine on _ready.
var config: GameConfig
## Reference to the PlayerStats resource. Set by StateMachine on _ready.
var stats: PlayerStats
## Reference to the AbilityUnlocks resource. Set by StateMachine on _ready.
var ability_unlocks: AbilityUnlocks


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


## Checks dodge, light attack, and heavy attack inputs in priority order.
## Transitions and returns true if one fires so the caller can early-return.
func _handle_combat_input() -> bool:
	if Input.is_action_just_pressed("dodge"):
		if ability_unlocks.dodge_unlocked and stats.stamina >= config.dodge_stamina_cost:
			player.state_machine.transition_to("dodge")
			return true
	if Input.is_action_just_pressed("attack"):
		if ability_unlocks.light_attack_unlocked and stats.stamina >= config.light_attack_stamina_cost:
			player.state_machine.transition_to("lightattack")
			return true
	if Input.is_action_just_pressed("heavy_attack"):
		if ability_unlocks.heavy_attack_unlocked and stats.stamina >= config.heavy_attack_stamina_cost:
			player.state_machine.transition_to("heavyattack")
			return true
	return false
