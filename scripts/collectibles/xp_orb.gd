class_name XPOrb
extends Area3D
## Collectible XP orb. Pops upward on spawn, bobs at rest height, and
## accelerates toward the player within vacuum_radius. Awards XP on contact
## or silently on lifetime expiry so orbs never litter the world permanently.

## Amount of XP this orb awards when collected.
@export var xp_amount: int = 10

## GameConfig reference — passed in by the spawner or set in the inspector.
@export var config: GameConfig

var _velocity_y: float = 0.0
var _spawn_y: float = 0.0         # Y position at spawn — rest height derived from this
var _rest_y: float = 0.0
var _popping: bool = true         # Phase A: upward pop + fall still in progress
var _bob_phase: float = 0.0       # random per-orb offset so groups don't bob in sync
var _age: float = 0.0
var _player: CharacterBody3D = null
var _collected: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_velocity_y = config.orb_pop_velocity if config else 4.0
	_spawn_y = global_position.y
	_bob_phase = randf() * TAU
	_spawn_tween()


func _physics_process(delta: float) -> void:
	if _collected or not config:
		return

	_age += delta

	# Lifetime expiry — award XP silently then free.
	if _age >= config.orb_lifetime:
		_award_xp_on_expiry()
		queue_free()
		return

	# Vacuum check — delayed so the pop and bob play before pull activates.
	if _age >= config.orb_vacuum_delay and _player and is_instance_valid(_player):
		var dist: float = global_position.distance_to(_player.global_position)
		if dist <= config.orb_vacuum_radius:
			global_position = global_position.move_toward(
					_player.global_position, config.orb_vacuum_speed * delta)
			return

	# Phase A — pop: upward velocity, then fall back to rest height.
	if _popping:
		var base_gravity: float = ProjectSettings.get_setting(
				"physics/3d/default_gravity", 9.8)
		_velocity_y -= base_gravity * config.orb_gravity_multiplier * delta
		global_position.y += _velocity_y * delta
		# Settle at spawn_y + 2*bob_height so the sine trough (_rest_y - bob_height)
		# lands at spawn_y + bob_height — clearly above ground, no clipping.
		if _velocity_y < 0.0 and global_position.y <= _spawn_y + config.orb_bob_height * 2.0:
			_rest_y = _spawn_y + config.orb_bob_height * 2.0
			global_position.y = _rest_y
			_popping = false
		return

	# Phase B — bob: sine wave around rest height, phase-offset per orb.
	var t: float = Time.get_ticks_msec() * 0.001
	global_position.y = _rest_y + sin(t * config.orb_bob_speed + _bob_phase) \
			* config.orb_bob_height


## Called by the spawner to give the orb a player reference so vacuum
## works from the first frame without waiting for a body_entered event.
func set_player(p: CharacterBody3D) -> void:
	_player = p


func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	if not body is CharacterBody3D:
		return
	_collect(body as CharacterBody3D)


func _collect(body: CharacterBody3D) -> void:
	_collected = true
	AudioManager.play_sfx("orb_collect")
	var player_stats: PlayerStats = body.get("stats") as PlayerStats
	if player_stats and config:
		player_stats.gain_xp(xp_amount, config.xp_base, config.xp_exponent,
				config.stat_points_per_level)
	queue_free()


func _award_xp_on_expiry() -> void:
	# Lifetime expired — always award XP to the registered player so orbs
	# never silently delete earned XP.
	_collected = true
	if _player and is_instance_valid(_player) and config:
		var ps: PlayerStats = _player.get("stats") as PlayerStats
		if ps:
			ps.gain_xp(xp_amount, config.xp_base, config.xp_exponent,
					config.stat_points_per_level)


func _spawn_tween() -> void:
	scale = Vector3.ZERO
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector3(1.2, 1.2, 1.2), 0.12)
	tw.tween_property(self, "scale", Vector3.ONE, 0.08)
