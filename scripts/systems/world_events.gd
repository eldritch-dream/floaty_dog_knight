class_name WorldEvents
## Canonical string constants for all world events fired into DialogueManager.
## Use these everywhere gameplay code calls DialogueManager.fire_event().
## Never use raw string literals in gameplay scripts — reference these constants.
## Adding a new event = add a constant here, reference it in JSON and in code.
##
## Naming convention:
##   {scene_name}_entered        — fires every visit
##   {scene_name}_entered_first  — fires on first visit only
##   {enemy_type}_killed         — fires on every kill
##   {enemy_type}_killed_first   — fires on first kill of that type
##   {item_id}_found             — fires when item is collected
##   {boss_id}_defeated          — fires when a boss dies
##
## WorldManager constructs _entered/_entered_first dynamically from scene filename.
## All other callers must use the constants below.

# ── Scenes ────────────────────────────────────────────────────────────────────
const HUB_ENTERED: String = "hub_entered"
const HUB_ENTERED_FIRST: String = "hub_entered_first"
const ZONE_01_ENTERED: String = "zone_01_entered"
const ZONE_01_ENTERED_FIRST: String = "zone_01_entered_first"

# ── Enemies ───────────────────────────────────────────────────────────────────
const WISP_KILLED: String = "wisp_killed"
const WISP_KILLED_FIRST: String = "wisp_killed_first"

# ── World interactions ────────────────────────────────────────────────────────
const RESTED_AT_BED: String = "rested_at_bed"
