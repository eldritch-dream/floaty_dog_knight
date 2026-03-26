# Skill: Narrative System (Dialogue, Events, NPC State)

**Triggered when**: adding NPCs, writing dialogue, adding world events, working on DialogueManager, DialogueBox, or NpcBase.

---

## Architecture Overview

```
WorldEvents constants  →  fire_event(name)  →  DialogueManager
                                ↓
                       _evaluate_transitions()   (all cached NPCs)
                                ↓
                       _npc_states Dictionary    (in-memory + saved)
                                ↓
NpcBase (E pressed)  →  get_current_lines(npc_id)  →  DialogueBox.show_dialogue()
```

---

## DialogueManager (`scripts/systems/dialogue_manager.gd`) — autoload

**Key API:**
```gdscript
DialogueManager.fire_event(WorldEvents.SOME_EVENT)  # idempotent
DialogueManager.has_fired(WorldEvents.SOME_EVENT)   # → bool
DialogueManager.get_current_lines(npc_id)           # → Array[String]
DialogueManager.get_npc_state(npc_id)               # → String
DialogueManager._reset_for_test()                   # GUT only
```

**In-memory state** (`_npc_states`, `_fired_events`, `_one_shots_seen`) is:
- Loaded from `SaveData` in `_ready()`
- Persisted via `_save()` on every change
- `_save()` reads existing save → merges dialogue fields → writes via `SaveManager._write()`

**NPC data cache** (`_npc_cache`) is populated lazily on first `get_current_lines()` call. Events only trigger transitions for NPCs already in the cache. If an NPC hasn't been interacted with yet, events are saved to `_fired_events` but transitions are not evaluated until the NPC is first loaded.

**Conditional overlay states** are checked first in `get_current_lines()` — if the condition is met, those lines are returned regardless of the NPC's current state machine position. The state machine position is not changed.

---

## WorldEvents (`scripts/systems/world_events.gd`)

`class_name WorldEvents` — no `extends`, no autoload. String constants only.

```gdscript
WorldEvents.HUB_ENTERED          # fires every hub entry (idempotent after first)
WorldEvents.HUB_ENTERED_FIRST    # fires once on first hub entry
WorldEvents.ZONE_01_ENTERED
WorldEvents.ZONE_01_ENTERED_FIRST
WorldEvents.WISP_KILLED          # fires every wisp kill (idempotent after first)
WorldEvents.WISP_KILLED_FIRST    # fires once on first wisp kill
WorldEvents.RESTED_AT_BED        # fires when player uses any Dog Bed
```

> **Rule**: Always use `WorldEvents.CONSTANT` — never raw string literals in gameplay code. Add new constants to `world_events.gd` before firing them.

**Where events are fired:**
- `WorldManager._do_travel()` — fires `{scene_name}_entered` and `{scene_name}_entered_first`
- `DreamManager.enter_dream()` — fires `WorldEvents.RESTED_AT_BED`
- `WispDeath.enter()` — fires `WorldEvents.WISP_KILLED` and `WorldEvents.WISP_KILLED_FIRST`

---

## Dialogue JSON Format (`assets/dialogue/{npc_id}.json`)

```json
{
  "initial_state": "default",
  "states": {
    "default": {
      "lines": [
        "Plain string line.",
        { "text": "One-shot line — shown once, then hidden.", "one_shot": true }
      ],
      "transitions": [
        { "event": "rested_at_bed", "next_state": "after_rest" }
      ]
    },
    "after_rest": {
      "lines": ["Second state line."],
      "transitions": []
    },
    "conditional_overlay": {
      "condition": { "player_level_gte": 3 },
      "lines": ["Lines shown when player level >= 3, overrides normal state."]
    }
  }
}
```

**Rules:**
- One JSON file per NPC, named `{npc_id}.json`
- `initial_state` must match a key in `states`
- Transitions are evaluated only for the NPC's **current** state — not all states
- `fire_event()` is idempotent; each event can only trigger a transition once per save
- Conditional states are checked first (overlay pattern); they do not advance the state machine
- One-shot lines: once seen, they are permanently hidden for that save (keyed by `"{npc_id}_{state}_{index}"`)

---

## DialogueBox (`scripts/ui/dialogue_box.gd`) — autoload via scenes/ui/dialogue_box.tscn

**API (stable seam — do not change):**
```gdscript
DialogueBox.show_dialogue(npc_id, lines, player)  # opens box, disables player input
DialogueBox.close()                               # restores player, emits dialogue_finished
DialogueBox.is_open()                             # → bool
DialogueBox.advance_line()                        # next line; closes on last
```

**Signal:** `dialogue_finished(npc_id: String)` — emitted on `close()`

**Player disable pattern** (same as DreamManager):
- `state_machine.set_physics_process(false)` — stops player movement
- `Input.set_mouse_mode(MOUSE_MODE_VISIBLE)` — releases cursor

**SEAM**: Replace the `Panel` contents with a portrait + styled text box in a future session. The `show_dialogue()` / `close()` interface must remain unchanged.

---

## NpcBase (`scripts/npc/npc_base.gd` + `scenes/world/npc_base.tscn`)

**Exports:**
```gdscript
@export var npc_id: String = ""          # matches assets/dialogue/{npc_id}.json
@export var interact_radius: float = 2.5
@export var interact_action: String = "ui_interact"
```

**Scene structure:**
```
NpcBase (Node3D, npc_base.gd)
  Visual          (MeshInstance3D — warm amber capsule placeholder)
  InteractZone    (Area3D, collision_mask=4 — player layer only)
    CollisionShape3D  (SphereShape3D, radius synced from interact_radius in _ready())
  InteractPrompt  (Label3D, billboard=1, visible=false, "[ E ] Talk")
  DialogueAnchor  (Node — SEAM for future portrait/voice system)
```

**Placing a new NPC:**
1. Instance `scenes/world/npc_base.tscn` in the world scene
2. Set `npc_id` in the Inspector
3. Create `assets/dialogue/{npc_id}.json`

---

## SaveData Dialogue Fields

Three fields added to `SaveData` (owned exclusively by `DialogueManager`):

| Field | Type | Default | Purpose |
|---|---|---|---|
| `npc_states` | `Dictionary` | `{}` | Current state per NPC (`{npc_id: state_name}`) |
| `fired_events` | `Array` | `[]` | All events ever fired this save |
| `one_shot_lines_seen` | `Array` | `[]` | Keys of one-shot lines that have been displayed |

`SaveManager.save_game()` preserves these fields by reading the existing save before overwriting — same pattern as `last_bed_id` / `last_bed_scene`.

---

## Owner NPC (`owner`)

Located at `(3, 0, -3)` in `hub.tscn`. `npc_id = "owner"`.

**State chain** (triggered by world events in order of expected occurrence):

| State | Trigger | Flavour |
|---|---|---|
| `default` | — | Searching for her dog. Leaves food by the door. |
| `dreamer` | `rested_at_bed` | Found Biscuit sleeping in that bed before he disappeared. |
| `wanderer` | `zone_01_entered_first` | Tried to go through the portal. Turned back. |
| `witness` | `wisp_killed_first` | Felt something quiet in the world. Connects the silence to Biscuit's old behaviour. |
| `returning_veteran` | `condition: player_level_gte: 3` | Overlay — notices the player has been changed by what they've seen. |

The owner knows the player character is her dog, but never says it directly.

---

## Testing

Test isolation: call `DialogueManager._reset_for_test()` in GUT `before_each()`. This clears all in-memory state without touching the save file.

Test NPC fixture: `assets/dialogue/test_npc.json` — used only by `test_dialogue_manager.gd`.

Test files:
- `tests/unit/test_dialogue_manager.gd` — 14 tests: events, transitions, one-shots, conditionals
- `tests/unit/test_npc_base.gd` — 5 tests: prompt visibility, collision radius, range state
- `tests/unit/test_dialogue_box.gd` — 6 tests: open/close, line advance, signal emission
