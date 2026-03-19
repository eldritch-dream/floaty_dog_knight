class_name NpcBase
extends Node3D
## Base class for all NPCs. Subclass and override interact() for dialogue/shop logic.

## Display name shown in interaction prompts.
@export var npc_name: String = "NPC"


## Called when the player initiates interaction (e.g., presses interact key near this NPC).
func interact(_player: Node) -> void:
	pass
