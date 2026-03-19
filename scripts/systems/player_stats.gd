class_name PlayerStats
extends Resource
## Runtime stats for the player: health, stamina, XP, and leveling.
## Attach to the player node via @export. Initialise stamina_regen_rate
## from GameConfig in Player._ready() to keep this class config-agnostic.

signal health_changed(new_value: float, max_value: float)
signal stamina_changed(new_value: float, max_value: float)
signal died
signal leveled_up(new_level: int)

# ── Exported defaults ───────────────────────────────────────────────────
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0

# ── Public vars ─────────────────────────────────────────────────────────
var health: float = 100.0
## Effective regen rate. Set from GameConfig.stamina_regen_rate in Player._ready().
## Increases on level-up.
var stamina_regen_rate: float = 20.0
var stamina: float = 100.0
var level: int = 1
var xp: int = 0

# ── Private vars ─────────────────────────────────────────────────────────
var _regen_delay_remaining: float = 0.0

# ── Stamina API ─────────────────────────────────────────────────────────

## Attempt to spend stamina. Returns false without spending if insufficient.
func spend_stamina(cost: float, regen_delay: float) -> bool:
	if stamina < cost:
		return false
	stamina = clampf(stamina - cost, 0.0, max_stamina)
	stamina_changed.emit(stamina, max_stamina)
	_regen_delay_remaining = regen_delay
	return true

## Call every physics frame to tick the stamina regen timer.
func tick(delta: float) -> void:
	if _regen_delay_remaining > 0.0:
		_regen_delay_remaining -= delta
		return
	if stamina < max_stamina:
		stamina = minf(stamina + stamina_regen_rate * delta, max_stamina)
		stamina_changed.emit(stamina, max_stamina)

# ── Health API ──────────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	health = clampf(health - amount, 0.0, max_health)
	health_changed.emit(health, max_health)
	if health == 0.0:
		died.emit()

func heal(amount: float) -> void:
	health = clampf(health + amount, 0.0, max_health)
	health_changed.emit(health, max_health)

# ── Progression API ─────────────────────────────────────────────────────

## Award XP and level up if the threshold is crossed.
## base_xp and xp_exponent are passed in from GameConfig to avoid coupling.
func gain_xp(amount: int, base_xp: int, xp_exponent: float) -> void:
	xp += amount
	while xp >= _xp_required(base_xp, xp_exponent):
		xp -= _xp_required(base_xp, xp_exponent)
		level += 1
		_on_level_up()
		leveled_up.emit(level)

func _xp_required(base_xp: int, xp_exponent: float) -> int:
	return int(base_xp * pow(level, xp_exponent))

func _on_level_up() -> void:
	max_health += 10.0
	health = max_health
	max_stamina += 5.0
	stamina = max_stamina
	stamina_regen_rate += 2.0
