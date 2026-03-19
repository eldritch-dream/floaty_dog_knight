class_name HitBox
extends Area3D
## Damage-dealing area attached to weapons or attack states.
## Activate via activate() / deactivate(); collision with a HurtBox deals damage.

signal hit(hurt_box: HurtBox)

## Damage dealt when this hitbox overlaps a HurtBox.
var damage: float = 0.0

## Who owns this hitbox — used by HurtBox to avoid self-damage.
var source: Node = null


func _ready() -> void:
	monitoring = false
	monitorable = false
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


## Enable the hitbox for the current attack.
func activate(dmg: float, src: Node) -> void:
	damage = dmg
	source = src
	monitoring = true
	monitorable = true


## Disable the hitbox between attacks.
func deactivate() -> void:
	monitoring = false
	monitorable = false


func _on_area_entered(area: Area3D) -> void:
	if area is HurtBox:
		_try_deal_damage(area as HurtBox)


func _on_body_entered(_body: Node3D) -> void:
	pass  # HurtBox is an Area3D; body collision is unused


func _try_deal_damage(hurt_box: HurtBox) -> void:
	# Skip if hurt_box belongs to the same entity as the source.
	if source != null and hurt_box.owner_node == source:
		return
	hurt_box.receive_hit(damage, source)
	hit.emit(hurt_box)
