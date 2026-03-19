class_name Sword
extends WeaponBase
## Sword weapon. HitBox child must be named "HitBox" in the scene.

func _ready() -> void:
	hit_box = get_node_or_null("HitBox") as HitBox
