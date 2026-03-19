class_name HurtBox
extends Area3D
## Damage-receiving area attached to characters.
## Pair with a PlayerStats resource; calls stats.take_damage() on hit.

signal damaged(amount: float, source: Node)

## The character that owns this HurtBox — used to prevent self-damage.
var owner_node: Node = null

## Stats resource to apply damage to. Assign from the owning character's _ready().
var stats: PlayerStats = null


func receive_hit(amount: float, source: Node) -> void:
	# Skip if the owner is invincible (i-frame dodge window).
	if owner_node and owner_node.get("is_invincible"):
		return
	if stats:
		stats.take_damage(amount)
	damaged.emit(amount, source)
