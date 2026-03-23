class_name PlayerStats
extends Resource
## Runtime stats for the player: health, stamina, XP, and leveling.
## Attach to the player node via @export. Initialise stamina_regen_rate
## from GameConfig in Player._ready() to keep this class config-agnostic.

signal health_changed(new_value: float, max_value: float)
signal stamina_changed(new_value: float, max_value: float)
signal died
signal leveled_up(new_level: int)
signal xp_changed(new_xp: int)
signal stat_points_pending(amount: int)
signal stat_invested(stat_name: String, new_value: float)

# ── Exported defaults ───────────────────────────────────────────────────
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0

# ── Public vars ─────────────────────────────────────────────────────────
var health: float = 100.0
## Effective regen rate. Set from GameConfig.stamina_regen_rate in Player._ready().
## Does NOT change on level-up — regen is an item/unlock reward, not a stat.
var stamina_regen_rate: float = 20.0
var stamina: float = 100.0
var level: int = 1
var xp: int = 0
## Stat points accumulated from level-ups, waiting to be spent at a Dog Bed.
var unspent_stat_points: int = 0
## Per-point gains — set from GameConfig in Player._ready(). Not saved;
## always re-applied from config on load.
var constitution_health_per_point: float = 15.0
var endurance_stamina_per_point: float = 8.0

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
## base_xp, xp_exponent, and stat_points_per_level are passed from GameConfig
## to avoid coupling this resource to the config resource.
func gain_xp(amount: int, base_xp: int, xp_exponent: float,
		stat_points_per_level: int = 1) -> void:
	xp += amount
	while xp >= _xp_required(base_xp, xp_exponent):
		xp -= _xp_required(base_xp, xp_exponent)
		level += 1
		_on_level_up(stat_points_per_level)
		leveled_up.emit(level)
	xp_changed.emit(xp)

func _xp_required(base_xp: int, xp_exponent: float) -> int:
	return int(base_xp * pow(level, xp_exponent))

func _on_level_up(stat_points_per_level: int) -> void:
	## No auto-allocation. Stats are invested manually at Dog Beds.
	unspent_stat_points += stat_points_per_level
	stat_points_pending.emit(unspent_stat_points)

# ── Stat Investment API ──────────────────────────────────────────────────

## Spend one stat point on the named stat. Returns false if no points remain
## or the stat name is not recognised.
func invest_in_stat(stat_name: String) -> bool:
	if unspent_stat_points <= 0:
		return false
	match stat_name:
		"constitution":
			max_health += constitution_health_per_point
			health = max_health
			health_changed.emit(health, max_health)
			unspent_stat_points -= 1
			stat_invested.emit("constitution", max_health)
			return true
		"endurance":
			max_stamina += endurance_stamina_per_point
			stamina = max_stamina
			stamina_changed.emit(stamina, max_stamina)
			unspent_stat_points -= 1
			stat_invested.emit("endurance", max_stamina)
			return true
	return false

## Returns a dictionary describing each investable stat for the UI.
## Shape: { stat_name: { label, description, current, gain } }
func get_investable_stats() -> Dictionary:
	return {
		"constitution": {
			"label": "Constitution",
			"description": "Increases max health",
			"current": max_health,
			"gain": constitution_health_per_point,
		},
		"endurance": {
			"label": "Endurance",
			"description": "Increases max stamina",
			"current": max_stamina,
			"gain": endurance_stamina_per_point,
		},
	}
