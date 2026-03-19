class_name AbilityUnlocks
extends Resource
## Tracks which player abilities have been unlocked via upgrades/progression.
## Read directly (e.g. player.ability_unlocks.double_jump_unlocked).
## Never coupled to PlayerStats — unlocks are gated by story/items, not level.

# ── Movement ────────────────────────────────────────────────────────────
## Allows the player to jump once more while airborne.
@export var double_jump_unlocked: bool = false
## Enables the dash burst in any direction.
@export var dash_unlocked: bool = false
## Enables the combat dodge roll with i-frames.
@export var dodge_unlocked: bool = false

# ── Combat ───────────────────────────────────────────────────────────────
## Unlocks the light attack action.
@export var light_attack_unlocked: bool = false
## Unlocks the heavy attack action.
@export var heavy_attack_unlocked: bool = false
