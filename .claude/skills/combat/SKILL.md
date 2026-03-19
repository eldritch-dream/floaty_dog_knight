# Skill: Combat

**Triggered when**: asked to modify combat, damage, hitboxes, dodge, stamina, or progression systems.

---

## Architecture Overview

```
Player
├── stats: PlayerStats          @export resource — health, stamina, XP, level
├── ability_unlocks: AbilityUnlocks  @export resource — bool flags per ability
├── is_invincible: bool         true during dodge i-frame window
├── ComboSystem (Node)          manages hitbox active-frame lifetime
├── StateMachine
│   ├── Dodge                   dodge roll with i-frames (ability_unlocks.dodge_unlocked)
│   ├── LightAttack             short hitbox window (ability_unlocks.light_attack_unlocked)
│   └── HeavyAttack             long hitbox window, roots player (ability_unlocks.heavy_attack_unlocked)
└── [Weapon scene] (e.g. Sword)
    ├── WeaponBase script       attack_light/heavy/deactivate_hitbox
    └── HitBox (Area3D)         activate(damage, source) / deactivate()
```

Enemies/NPCs that can receive damage get a **HurtBox** (Area3D) child with `stats` and `owner_node` assigned.

---

## Stamina System

Stamina is managed by `PlayerStats` and ticked each frame from `player._physics_process`:

```gdscript
stats.tick(delta)  # counts down regen delay, then regens
```

### Spending stamina

```gdscript
if stats.spend_stamina(cost, config.stamina_regen_delay):
    # proceed
else:
    return  # blocked — not enough stamina
```

`spend_stamina()` returns `false` without side-effects if `stamina < cost`.

### Stamina regen
- `stamina_regen_delay` (default 1.2 s): after spending stamina, regen pauses
- `stamina_regen_rate` (default 20/s): base rate set from `config` in `player._ready()`; increases by 2.0 per level-up

---

## HitBox / HurtBox Pattern

### HitBox (`scripts/combat/hit_box.gd`)
- `extends Area3D`, `class_name HitBox`
- Starts disabled: `monitoring = false`, `monitorable = false`
- `activate(damage, source)` — enable for a swing
- `deactivate()` — close after active frames expire
- On area overlap: calls `hurt_box.receive_hit(damage, source)` if the overlapping Area3D is a HurtBox
- Skips self-hits: `hurt_box.owner_node == source` → ignored

### HurtBox (`scripts/combat/hurt_box.gd`)
- `extends Area3D`, `class_name HurtBox`
- `owner_node`: the character this belongs to (set in owning character's `_ready`)
- `stats`: PlayerStats to call `take_damage()` on
- `receive_hit(amount, source)` — checks `owner_node.is_invincible`; if true, skips damage

### Invincibility (i-frames)
- `player.is_invincible = true` set in `Dodge.enter()`
- Cleared in `Dodge.exit()` and when `_i_frame_timer` expires
- HurtBox reads this via `owner_node.get("is_invincible")` — works for any node with that property

---

## ComboSystem (`scripts/systems/combo_system.gd`)

Manages hitbox active-frame windows for attack states:

```gdscript
combo.start_attack(active_frames, damage, source, heavy)  # call in enter()
combo.tick(delta)  # call in physics_update()
combo.is_attacking() -> bool
# signal: attack_ended
```

- Active frames are in 60-fps units: `active_frames * (1/60)` seconds
- Attack states connect `attack_ended` with `CONNECT_ONE_SHOT`, then `_finished = true`
- `weapon.attack_light/heavy()` is called inside `start_attack()`; `deactivate_hitbox()` on end

---

## WeaponBase / Sword

- `WeaponBase` (`class_name WeaponBase`, `extends Node3D`) — abstract: `attack_light()`, `attack_heavy()`, `deactivate_hitbox()`
- `Sword` (`class_name Sword`, `extends WeaponBase`) — `_ready()` looks up `HitBox` child by name
- Assign weapon reference to `ComboSystem.weapon` in `player._ready()` after adding weapon as a child

---

## XPOrb (`scripts/collectibles/xp_orb.gd`)

- `extends Area3D`, `class_name XPOrb`
- `@export var xp_amount: int = 10`
- `@export var config: GameConfig` — must be assigned (spawner or inspector)
- On `body_entered`: if body has a `stats` property (PlayerStats), calls `stats.gain_xp(xp_amount, config.xp_base, config.xp_exponent)`, then `queue_free()`

### XP / Level curve

```gdscript
xp_required = int(xp_base * pow(level, xp_exponent))
# Level 1 → 100 XP, Level 2 → 282 XP, Level 3 → 520 XP
```

Level-up effects (in `PlayerStats._on_level_up()`):
- `max_health += 10.0`, restored to full
- `max_stamina += 5.0`, restored to full
- `stamina_regen_rate += 2.0`

---

## WorldManager (autoload)

```gdscript
WorldManager.travel_to("res://scenes/world/zone_01.tscn", "entrance")
WorldManager.consume_spawn_point()  # called from new scene's player _ready()
```

- Call is deferred (`call_deferred("_do_travel", ...)`) so physics finishes cleanly
- Guard: second call while `_travelling == true` is silently ignored
- Signals: `travel_started(destination)`, `travel_completed(destination)`

### Portal (`scripts/world/portal.gd`)
- `extends Area3D`, placed in world scenes
- `@export var destination_scene: String`
- `@export var destination_spawn_point: String`
- On `body_entered` by CharacterBody3D: calls `WorldManager.travel_to(...)`

---

## Rule

> **Ability gating always happens in the calling state before transition, never inside the state's `enter()`.** Check `ability_unlocks.X_unlocked` and `stats.stamina >= cost` before calling `state_machine.transition_to("dodge")`.

> **PlayerStats never references GameConfig.** Pass primitive values (`base_xp: int`, `xp_exponent: float`) from config as arguments.
