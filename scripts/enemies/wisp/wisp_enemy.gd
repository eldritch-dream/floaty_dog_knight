class_name WispEnemy
extends CharacterBody3D
## Eldritch Wisp — the weakest enemy in the game.
## Floats at a fixed height, patrols, detects the player, and performs a
## single melee swipe attack. Dies in 3-4 light hits or 2 heavy hits.

## GameConfig resource — assign in the inspector (same resource as player).
@export var config: GameConfig

## Player reference — assign in the scene to the Player node.
@export var player: CharacterBody3D

## Whether the Wisp is currently invincible (unused for now — kept for
## HurtBox compatibility with the is_invincible duck-type check).
var is_invincible: bool = false

## EnemyStats instance — created from config values in _ready().
var enemy_stats: EnemyStats

## World-space Y of the spawn position. Float height is relative to this.
var spawn_y: float = 0.0

## World-space XZ spawn position. Patrol radius is relative to this.
var spawn_position: Vector3 = Vector3.ZERO

## The Wisp's own state machine node.
var state_machine: WispStateMachine

## HitBox node — activated only during the Attack state.
var hit_box: HitBox

## HurtBox node — receives player attack hits.
var hurt_box: HurtBox

## Visual mesh node — used for scale pulses during wind-up.
var visual: CSGSphere3D


func _ready() -> void:
	spawn_position = global_position
	spawn_y = global_position.y

	# Build EnemyStats from config values.
	enemy_stats = EnemyStats.new()
	enemy_stats.max_health = config.wisp_max_health
	enemy_stats.current_health = config.wisp_max_health
	enemy_stats.xp_reward = config.wisp_xp_reward
	enemy_stats.damage = config.wisp_damage
	enemy_stats.attack_range = config.wisp_attack_range
	enemy_stats.aggro_range = config.wisp_aggro_range
	enemy_stats.move_speed = config.wisp_move_speed
	enemy_stats.stagger_duration = config.wisp_stagger_duration

	state_machine = get_node("WispStateMachine") as WispStateMachine
	hit_box = get_node("HitBox") as HitBox
	hurt_box = get_node("HurtBox") as HurtBox
	visual = get_node("CSGSphere3D") as CSGSphere3D

	# Fallback: typed export NodePath may not resolve for instanced sub-scenes.
	if not is_instance_valid(player):
		player = get_parent().get_node_or_null("Player") as CharacterBody3D

	# Prevent self-damage: owner_node on HurtBox, source set by Attack state.
	hurt_box.owner_node = self
	# Stats intentionally left null on HurtBox — damage is handled via signal.
	hurt_box.damaged.connect(_on_damaged)

	enemy_stats.died.connect(_on_died)

	# Init state machine after enemy_stats exists (avoids bottom-up _ready order).
	state_machine.setup(self, config, enemy_stats)


func _physics_process(delta: float) -> void:
	state_machine.physics_update(delta)


## Called when the HurtBox receives a hit. Routes damage to EnemyStats
## and notifies the active state so it can react (e.g. WindUp → Stagger).
func take_damage(amount: float) -> void:
	if enemy_stats.is_dead():
		return
	enemy_stats.take_damage(amount, self)
	_flash_hit()
	# Notify current state — WindUp uses this to interrupt into Stagger.
	var current: WispState = state_machine.current_state
	if current and current.has_method("on_damaged"):
		current.on_damaged()


func _flash_hit() -> void:
	if not is_instance_valid(visual):
		return
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector3(0.6, 0.6, 0.6), 0.05)
	tween.tween_property(visual, "scale", Vector3.ONE, 0.1)


func _on_damaged(amount: float, _source: Node) -> void:
	take_damage(amount)


func _on_died(_enemy: Node) -> void:
	state_machine.transition_to("death")
