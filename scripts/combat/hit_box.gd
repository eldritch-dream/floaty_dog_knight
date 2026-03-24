class_name HitBox
extends Area3D
## Damage-dealing area attached to weapons or attack states.
## Activate via activate() / deactivate(); collision with a HurtBox deals damage.
## Polls overlapping areas each physics frame so i-frame dodges register correctly
## (area_entered fires once at overlap start and never rechecks invincibility).

signal hit(hurt_box: HurtBox)

## Damage dealt when this hitbox overlaps a HurtBox.
var damage: float = 0.0

## Who owns this hitbox — used by HurtBox to avoid self-damage.
var source: Node = null

## HurtBoxes already damaged this activation — prevents multi-hit per swing.
var _hit_this_attack: Array[HurtBox] = []


func _ready() -> void:
	monitoring = false
	monitorable = false


## Enable the hitbox for the current attack.
func activate(dmg: float, src: Node) -> void:
	damage = dmg
	source = src
	_hit_this_attack.clear()
	monitoring = true
	monitorable = true
	_set_debug_visible(true)


## Disable the hitbox between attacks.
func deactivate() -> void:
	monitoring = false
	monitorable = false
	_hit_this_attack.clear()
	_set_debug_visible(false)


func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	for area in get_overlapping_areas():
		if area is HurtBox and area not in _hit_this_attack:
			_try_deal_damage(area as HurtBox)


func _set_debug_visible(v: bool) -> void:
	var mesh := get_node_or_null("DebugMesh") as MeshInstance3D
	if mesh:
		mesh.visible = v


func _try_deal_damage(hurt_box: HurtBox) -> void:
	if source != null and hurt_box.owner_node == source:
		return
	# Don't add to hit list while invincible — recheck next frame so
	# i-frames actually block damage rather than just delaying it.
	if hurt_box.owner_node and hurt_box.owner_node.get("is_invincible"):
		return
	_hit_this_attack.append(hurt_box)
	hurt_box.receive_hit(damage, source)
	hit.emit(hurt_box)
	AudioManager.play_sfx("hit_impact", hurt_box.global_position)
