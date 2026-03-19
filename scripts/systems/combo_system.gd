class_name ComboSystem
extends Node
## Manages attack active-frame windows and hitbox lifetime.
## Tick via update(delta) from the active attack state.
## Call start_attack() at the beginning of each swing.

signal attack_ended

## Seconds-per-frame at 60 fps.
const FRAME_TIME: float = 1.0 / 60.0

## Currently equipped weapon. Assign from Player._ready().
var weapon: WeaponBase = null

var _active: bool = false
var _active_time_remaining: float = 0.0
var _damage: float = 0.0
var _source: Node = null


## Begin a swing. active_frames is the number of 60-fps frames the hitbox stays open.
func start_attack(active_frames: int, damage: float, source: Node, heavy: bool = false) -> void:
	_damage = damage
	_source = source
	_active = true
	_active_time_remaining = active_frames * FRAME_TIME

	if weapon:
		if heavy:
			weapon.attack_heavy(damage, source)
		else:
			weapon.attack_light(damage, source)


## Call every frame from the attack state's update().
func tick(delta: float) -> void:
	if not _active:
		return
	_active_time_remaining -= delta
	if _active_time_remaining <= 0.0:
		_end_attack()


func _end_attack() -> void:
	_active = false
	if weapon:
		weapon.deactivate_hitbox()
	attack_ended.emit()


func is_attacking() -> bool:
	return _active
