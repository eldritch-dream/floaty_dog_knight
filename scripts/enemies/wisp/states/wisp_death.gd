extends WispState
## Death — spawns an XPOrb at the Wisp's position, waits briefly, then frees the node.
## Never calls queue_free directly in a physics frame — uses call_deferred.

const XP_ORB_SCENE: PackedScene = preload("res://scenes/collectibles/xp_orb.tscn")


func enter() -> void:
	# Freeze movement.
	wisp.velocity = Vector3.ZERO
	AudioManager.play_sfx("enemy_death", wisp.global_position)
	# Fire world events for quest tracking.
	DialogueManager.fire_event(WorldEvents.WISP_KILLED)
	if not DialogueManager.has_fired(WorldEvents.WISP_KILLED_FIRST):
		DialogueManager.fire_event(WorldEvents.WISP_KILLED_FIRST)

	# Disable HurtBox so the corpse can't be hit again.
	if wisp.hurt_box:
		wisp.hurt_box.monitoring = false
		wisp.hurt_box.monitorable = false

	# Hide visual.
	if wisp.visual:
		wisp.visual.visible = false

	_spawn_xp_orb()
	# Do NOT queue_free — wisp stays in the scene tree so reset() can revive it.
	_disable_wisp()


func physics_update(_delta: float) -> void:
	pass  # Dormant — disabled by _disable_wisp().


func _spawn_xp_orb() -> void:
	var orb: XPOrb = XP_ORB_SCENE.instantiate() as XPOrb
	orb.xp_amount = enemy_stats.xp_reward
	orb.config = config
	wisp.get_parent().add_child(orb)
	orb.global_position = wisp.global_position
	if wisp.player:
		orb.set_player(wisp.player as CharacterBody3D)


func _disable_wisp() -> void:
	# Disable physics and collision so the dormant wisp has no runtime cost.
	# CollisionShape3D must be deferred — cannot change shape during physics.
	wisp.set_physics_process(false)
	var col: CollisionShape3D = wisp.get_node_or_null(
			"CollisionShape3D") as CollisionShape3D
	if col:
		col.call_deferred("set_disabled", true)
