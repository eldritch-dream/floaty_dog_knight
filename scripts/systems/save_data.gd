class_name SaveData
extends RefCounted
## Snapshot of game state at save time. Never a live reference to PlayerStats.
##
## Flow:
##   SAVE: capture(stats, unlocks, scene) → to_dict() → JSON → storage
##   LOAD: storage → JSON → from_dict(dict) → apply_to(stats, unlocks)


var player_level: int = 1
var player_xp: int = 0
var player_max_health: float = 100.0
var player_max_stamina: float = 100.0
var stamina_regen_rate: float = 20.0
var ability_unlocks: Dictionary = {}
var last_scene: String = "res://scenes/world/hub.tscn"


## Populate this snapshot from live PlayerStats and AbilityUnlocks.
func capture(stats: PlayerStats, unlocks: AbilityUnlocks, scene: String) -> void:
	player_level = stats.level
	player_xp = stats.xp
	player_max_health = stats.max_health
	player_max_stamina = stats.max_stamina
	stamina_regen_rate = stats.stamina_regen_rate
	last_scene = scene
	ability_unlocks = {
		"double_jump_unlocked": unlocks.double_jump_unlocked,
		"dash_unlocked": unlocks.dash_unlocked,
		"dodge_unlocked": unlocks.dodge_unlocked,
		"light_attack_unlocked": unlocks.light_attack_unlocked,
		"heavy_attack_unlocked": unlocks.heavy_attack_unlocked,
	}


## Apply this snapshot to live PlayerStats and AbilityUnlocks.
## Health and stamina are restored to their saved maximums.
func apply_to(stats: PlayerStats, unlocks: AbilityUnlocks) -> void:
	stats.level = player_level
	stats.xp = player_xp
	stats.max_health = player_max_health
	stats.health = player_max_health
	stats.max_stamina = player_max_stamina
	stats.stamina = player_max_stamina
	stats.stamina_regen_rate = stamina_regen_rate
	unlocks.double_jump_unlocked = ability_unlocks.get("double_jump_unlocked", false)
	unlocks.dash_unlocked = ability_unlocks.get("dash_unlocked", false)
	unlocks.dodge_unlocked = ability_unlocks.get("dodge_unlocked", false)
	unlocks.light_attack_unlocked = ability_unlocks.get("light_attack_unlocked", false)
	unlocks.heavy_attack_unlocked = ability_unlocks.get("heavy_attack_unlocked", false)


func to_dict() -> Dictionary:
	return {
		"player_level": player_level,
		"player_xp": player_xp,
		"player_max_health": player_max_health,
		"player_max_stamina": player_max_stamina,
		"stamina_regen_rate": stamina_regen_rate,
		"ability_unlocks": ability_unlocks,
		"last_scene": last_scene,
	}


func from_dict(data: Dictionary) -> void:
	player_level = data.get("player_level", 1)
	player_xp = data.get("player_xp", 0)
	player_max_health = data.get("player_max_health", 100.0)
	player_max_stamina = data.get("player_max_stamina", 100.0)
	stamina_regen_rate = data.get("stamina_regen_rate", 20.0)
	ability_unlocks = data.get("ability_unlocks", {})
	last_scene = data.get("last_scene", "res://scenes/world/hub.tscn")
