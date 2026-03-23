class_name XPOrb
extends Area3D
## Collectible XP orb. Overlapping the player awards XP and frees the orb.
## Spawn via WorldManager.spawn_xp_orb() or place directly in the scene.

## Amount of XP this orb awards when collected.
@export var xp_amount: int = 10

## GameConfig reference — passed in by the spawner or set in the inspector.
@export var config: GameConfig


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	var player_stats: PlayerStats = body.get("stats") as PlayerStats
	if player_stats and config:
		player_stats.gain_xp(xp_amount, config.xp_base, config.xp_exponent,
				config.stat_points_per_level)
	queue_free()
