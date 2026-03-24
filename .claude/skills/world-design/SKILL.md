# Skill: World Design

**Triggered when**: placing enemies, collectibles, portals, dog beds, or designing scene layouts.

---

## XP Orb behaviour

- Orbs pop upward on spawn, fall under light gravity, then bob at rest height.
- Vacuum radius pulls orbs toward the player within `config.orb_vacuum_radius` (default 4m).
- **Orbs have a lifetime** (`config.orb_lifetime`, default 15s). After expiry they auto-collect (award XP silently and free themselves). The world will never accumulate orphaned orbs.
- Spawner (`wisp_death.gd`) passes a player reference to the orb via `set_player()` so vacuum works from the first frame.

## Dog Bed placement rules

- Node **name** in the scene must match `bed_id` — this name is used as the WorldManager spawn point.
- `bed_scene_path` auto-populates in `_ready()` via `get_tree().current_scene.scene_file_path`. Never use `scene_file_path` on the DogBed node itself (returns the DogBed subscene path, not the world scene).
- Naming convention: `{zone}_bed` (e.g. `hub_bed`, `zone_01_bed`).

## Portal placement rules

- Portal is an `Area3D` trigger → `WorldManager.travel_to(scene_path, spawn_point_name)`.
- The `spawn_point_name` must match a node name in the destination scene.
- Place a `Node3D` with the matching name at the landing position in the destination scene.
