# Skill: Game State (Death, Save/Load)

**Triggered when**: working on player death, respawn, save/load, or game persistence.

---

## Death Flow

### Signal chain

```
stats.take_damage()
  → stats.died.emit()               (PlayerStats)
  → player._on_player_died()        (Player)
      sets is_dead = true
      sets is_invincible = true
      state_machine.transition_to("death")
      RespawnManager.handle_death(stats, config)
```

### Death state (`scripts/player/states/death.gd`)

- Terminal state — never self-exits; entered once and stays until scene reload
- `enter()`: zeros velocity, emits `player.player_died` (animation hook for future use)
- `physics_update()`: applies gravity so the player ragdolls naturally while the respawn sequence runs

### RespawnManager (`scripts/systems/respawn_manager.gd`)

Sequence on `handle_death(stats, config)`:
1. `Engine.time_scale = 0.0` — freeze world (0.3 s hit-stop feel)
2. `await create_timer(0.3, true, false, true)` — **must pass `ignore_time_scale=true`** (4th arg) or the timer never ticks at time_scale=0 and the game hangs permanently
3. `Engine.time_scale = 1.0`
4. Wait remaining `config.death_respawn_delay - 0.3` seconds
5. Restore health: `stats.health = stats.max_health * config.respawn_health_percent`
6. `WorldManager.travel_to("res://scenes/world/hub.tscn", "SpawnPoint")`

> **Health must be restored immediately before `travel_to()`**, not between the two wait periods. `is_invincible = true` prevents the wisp from dealing further damage during the delay.

### GameConfig parameters (Respawn group)

| Param | Default | Meaning |
|---|---|---|
| `death_respawn_delay` | `1.5` | Total seconds from death to scene change |
| `respawn_health_percent` | `1.0` | Fraction of max_health restored on respawn |

### `is_dead` / `is_invincible` flags on Player

- `is_dead`: set to `true` in `_on_player_died()`. Gates `camera_rig.handle_mouse_input()` and `camera_rig.handle_gamepad_look()` — without this gate the camera continues to spin during the death sequence.
- `is_invincible`: checked in `HurtBox.receive_hit()` — skips damage when true. Set on death; cleared automatically on scene reload since `Player._ready()` runs fresh.

### Future death animation hook

`player_died` signal on the Player node is the intended hook point. When animations exist:
- Death state listens for `animation_finished` before returning
- Or: replace the 0.3 s freeze with `await player.death_animation_finished`
- RespawnManager drives timing independently — no structural change needed

---

## Save System

### Architecture

```
PlayerStats / AbilityUnlocks   (live, in-memory Resources)
       ↕  capture / apply_to
SaveData                        (RefCounted snapshot — never a live reference)
       ↕  to_dict / from_dict
JSON string
       ↕  _write / _read
Storage:
  Web  → localStorage["doggo_knight_save"]  via JavaScriptBridge
  Desktop → user://save.json  via FileAccess
```

### SaveData (`scripts/systems/save_data.gd`)

Fields captured:
- `player_level`, `player_xp`, `player_max_health`, `player_max_stamina`, `stamina_regen_rate`
- `ability_unlocks: Dictionary` — keys match `AbilityUnlocks` bool property names
- `last_scene: String`

`apply_to(stats, unlocks)`: restores all fields; always sets `health = max_health` (full heal on load).

`to_dict()` / `from_dict()`: plain Dictionary; all keys use `.get(key, default)` for forward-compatible loading.

### SaveManager (`scripts/systems/save_manager.gd`) — autoload

**Cold start vs scene transition**: `_session_active: bool` flag prevents re-applying save data on scene transitions (which would overwrite in-memory stats that are already correct).

```gdscript
# Player._ready() — must be called every scene load:
SaveManager.register_player(stats, ability_unlocks)
```

First call: `_session_active = false` → applies save if one exists.
Subsequent calls (scene transitions): `_session_active = true` → skip apply.

**Save triggers**:
| Trigger | How |
|---|---|
| Level up | `stats.leveled_up` signal → `_on_level_up` |
| XP gain | `stats.xp_changed` signal → `_on_xp_changed` |
| Scene transition | `WorldManager.travel_to()` calls `save_game()` before deferred travel |
| Respawn | Covered by the scene transition in `RespawnManager` |

**Web storage**: `localStorage.setItem(key, JSON.stringify(json_str))` — the inner `JSON.stringify` wraps the string in quotes and escapes it for safe JS embedding. Avoid double-serializing.

**Test isolation**: `save_path` is a `var` (not `const`) — tests override it to `"user://test_save_tmp.json"` and clean up in `after_each()`.

### PlayerStats signals relevant to saving

```gdscript
signal leveled_up(new_level: int)
signal xp_changed(new_xp: int)    # emitted at end of gain_xp()
```

Both are connected in `SaveManager.register_player()`.

---

## Spawn Point System

`WorldManager.travel_to(scene_path, spawn_point_name)` stores the spawn point name.

In `Player._ready()`:
```gdscript
var sp_name: String = WorldManager.consume_spawn_point()
if not sp_name.is_empty():
    var sp: Node3D = get_parent().get_node_or_null(sp_name)
    if sp:
        global_position = sp.global_position
```

`consume_spawn_point()` clears the stored name after reading (one-shot).
