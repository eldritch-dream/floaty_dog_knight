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
## The node name (and bed_id) of the last Dog Bed the player rested at.
## Empty string = no bed used yet; RespawnManager falls back to hub/SpawnPoint.
var last_bed_id: String = ""
## The scene path that contains last_bed_id.
var last_bed_scene: String = ""
## Stat points earned from leveling up but not yet spent at a Dog Bed.
var unspent_stat_points: int = 0


## Populate this snapshot from live PlayerStats and AbilityUnlocks.
## last_bed_id and last_bed_scene are NOT set here — they are written by
## DreamManager.enter_dream() when the player explicitly rests at a bed.
func capture(stats: PlayerStats, unlocks: AbilityUnlocks, scene: String) -> void:
	player_level = stats.level
	player_xp = stats.xp
	player_max_health = stats.max_health
	player_max_stamina = stats.max_stamina
	stamina_regen_rate = stats.stamina_regen_rate
	unspent_stat_points = stats.unspent_stat_points
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
	stats.unspent_stat_points = unspent_stat_points
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
		"unspent_stat_points": unspent_stat_points,
		"ability_unlocks": ability_unlocks,
		"last_scene": last_scene,
		"last_bed_id": last_bed_id,
		"last_bed_scene": last_bed_scene,
	}


func from_dict(data: Dictionary) -> void:
	player_level = data.get("player_level", 1)
	player_xp = data.get("player_xp", 0)
	player_max_health = data.get("player_max_health", 100.0)
	player_max_stamina = data.get("player_max_stamina", 100.0)
	stamina_regen_rate = data.get("stamina_regen_rate", 20.0)
	unspent_stat_points = data.get("unspent_stat_points", 0)
	ability_unlocks = data.get("ability_unlocks", {})
	last_scene = data.get("last_scene", "res://scenes/world/hub.tscn")
	last_bed_id = data.get("last_bed_id", "")
	var raw_bed_scene: String = data.get("last_bed_scene", "")
	# Guard: an earlier bug stored the dog_bed subscene path instead of the world scene.
	# Treat that as unset so cold-start falls back to hub rather than loading a sceneless file.
	last_bed_scene = "" if raw_bed_scene.ends_with("dog_bed.tscn") else raw_bed_scene
