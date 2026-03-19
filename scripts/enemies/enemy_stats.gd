class_name EnemyStats
extends Resource
## Health and combat stats for an enemy. Separate from PlayerStats —
## enemies have no stamina or XP tracking.

signal died(enemy: Node)
signal health_changed(new_val: float, max_val: float)

@export var max_health: float = 35.0
@export var current_health: float = 35.0
@export var xp_reward: int = 20
@export var damage: float = 15.0
@export var attack_range: float = 2.0
@export var aggro_range: float = 8.0
@export var move_speed: float = 4.0
@export var stagger_duration: float = 0.4


func take_damage(amount: float, enemy: Node = null) -> void:
	if current_health <= 0.0:
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		died.emit(enemy)


func is_dead() -> bool:
	return current_health <= 0.0
