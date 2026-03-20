extends WispState
## Death — spawns an XPOrb at the Wisp's position, waits briefly, then frees the node.
## Never calls queue_free directly in a physics frame — uses call_deferred.

const XP_ORB_SCENE: PackedScene = preload("res://scenes/collectibles/xp_orb.tscn")


func enter() -> void:
	# Freeze movement.
	wisp.velocity = Vector3.ZERO

	# Disable HurtBox so the corpse can't be hit again.
	if wisp.hurt_box:
		wisp.hurt_box.monitoring = false
		wisp.hurt_box.monitorable = false

	# Hide visual.
	if wisp.visual:
		wisp.visual.visible = false

	_spawn_xp_orb()
	_defer_free()


func physics_update(_delta: float) -> void:
	pass  # Nothing to do while waiting for the deferred free.


func _spawn_xp_orb() -> void:
	var orb: XPOrb = XP_ORB_SCENE.instantiate() as XPOrb
	orb.xp_amount = enemy_stats.xp_reward
	orb.config = config
	wisp.get_parent().add_child(orb)
	orb.global_position = wisp.global_position


func _defer_free() -> void:
	await wisp.get_tree().create_timer(0.3).timeout
	wisp.call_deferred("queue_free")
