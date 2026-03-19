class_name WeaponBase
extends Node3D
## Abstract base class for all player weapons.
## Subclass and override attack_light() / attack_heavy() for weapon-specific behaviour.
## Owns a HitBox child that ComboSystem activates/deactivates each swing.

## Reference to this weapon's hitbox — assign in _ready() of the subclass.
var hit_box: HitBox = null


## Activate the hitbox for a light attack swing.
func attack_light(damage: float, source: Node) -> void:
	if hit_box:
		hit_box.activate(damage, source)


## Activate the hitbox for a heavy attack swing.
func attack_heavy(damage: float, source: Node) -> void:
	if hit_box:
		hit_box.activate(damage, source)


## Deactivate the hitbox. Called by ComboSystem at end of active frames.
func deactivate_hitbox() -> void:
	if hit_box:
		hit_box.deactivate()
