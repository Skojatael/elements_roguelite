# Data Model: Enemy Combat System

**Feature**: `002-enemy-combat`
**Date**: 2026-02-19

---

## Entities

### EnemyData *(data model, `scripts/data_models/EnemyData.gd`)*

Typed GDScript wrapper over a single record from `data/enemies.json`. Immutable after construction — runtime enemy instances copy values from this data object.

| Field | Type | Description |
|---|---|---|
| `id` | `String` | Machine-readable identifier, e.g. `"slime"` |
| `display_name` | `String` | Human-readable name for future UI |
| `max_health` | `float` | Starting and maximum health of this enemy type |
| `damage` | `float` | Contact damage dealt per cooldown interval |
| `move_speed` | `float` | Pursuit movement speed in pixels/second |
| `detection_range` | `float` | Radius (pixels) at which enemy detects the player |
| `damage_cooldown` | `float` | Minimum seconds between consecutive contact damage hits |

**Validation rules**:
- `max_health > 0`
- `damage >= 0`
- `move_speed >= 0`
- `detection_range > 0`
- `damage_cooldown > 0`

**Construction**: `EnemyData.from_dict(dict: Dictionary) -> EnemyData` — parses one JSON object; asserts all required keys present.

---

### Enemy *(runtime entity, `scenes/combat/enemies/Enemy.gd`)*

A single enemy instance in the dungeon. Initialized from an `EnemyData` record. Responsible for its own health, state machine, movement, and contact-damage delivery.

| Field | Type | Description |
|---|---|---|
| `current_health` | `float` | Remaining health; initialized to `EnemyData.max_health` |
| `_data` | `EnemyData` | The type definition this instance was built from |
| `_state` | `EnemyState` | Current FSM state: `IDLE` or `PURSUING` |
| `_player_ref` | `CharacterBody2D` | Reference to the player node; set when detection fires |
| `_damage_timer` | `float` | Countdown to next allowed contact-damage hit |

**State machine**:
```
IDLE ──[player enters DetectionArea]──► PURSUING
PURSUING ──[player exits DetectionArea]──► IDLE
PURSUING ──[current_health <= 0]──► (removed from scene tree)
```

**Methods**:
- `initialize(data: EnemyData) -> void` — copies stats from data; must be called immediately after instantiation.
- `take_damage(amount: float) -> void` — reduces `current_health`; calls `queue_free()` when health ≤ 0.

**Signals**:
- `defeated` — emitted just before `queue_free()`; allows room manager to track kill counts in a future feature.

---

### StatsComponent *(player component, `scenes/player/components/StatsComponent.gd`)*

Owns the player's health domain. Child node of `Player.tscn`.

| Field | Type | Description |
|---|---|---|
| `max_health` | `float` | Exported; default `10.0` |
| `current_health` | `float` | Remaining player health |

**Methods**:
- `take_damage(amount: float) -> void` — reduces `current_health`; clamps to 0; emits `died` if health reaches 0.
- `heal(amount: float) -> void` — increases `current_health`; clamps to `max_health`.

**Signals**:
- `health_changed(new_health: float, max_health: float)` — emitted on every change; consumed by HUD in a future feature.
- `died` — emitted once when `current_health` first reaches 0; `Main.gd` connects this to emit `GlobalSignals.gameplay_ended`.

---

### CombatComponent *(player component, `scenes/player/components/CombatComponent.gd`)*

Delivers outgoing damage from the player to enemies. Child node of `Player.tscn`. Uses an `Area2D` child to detect overlapping enemies.

| Field | Type | Description |
|---|---|---|
| `attack_damage` | `float` | Exported; damage per hit; default `1.0` |
| `attack_interval` | `float` | Exported; seconds between hits; default `0.5` |
| `_attack_timer` | `float` | Countdown to next attack |
| `_overlapping_enemies` | `Array` | Current set of enemies in attack range |

**Behaviour**: Every `attack_interval` seconds, if `_overlapping_enemies` is non-empty, calls `take_damage(attack_damage)` on one enemy (nearest, or first in list for MVP).

---

## JSON Schema (`data/enemies.json`)

```json
{
  "enemies": [
    {
      "id": "slime",
      "display_name": "Slime",
      "max_health": 3.0,
      "damage": 1.0,
      "move_speed": 60.0,
      "detection_range": 200.0,
      "damage_cooldown": 0.5
    }
  ]
}
```

---

## Entity Relationships

```
data/enemies.json
      │  (loaded at startup by ResourceManager or Main.gd)
      ▼
EnemyData  ──initialize()──►  Enemy (runtime instance, 0..N per room)
                                 │
                                 │ take_damage()
                                 ◄─────────────── CombatComponent (player child)
                                 │
                                 │ contact damage ─► StatsComponent.take_damage()
                                                          │
                                                          │ died signal
                                                          ▼
                                                     Main.gd ──► GlobalSignals.gameplay_ended
```

---

## Data Flow Summary

1. At scene load, `enemies.json` is parsed into an array of `EnemyData` objects.
2. Each pre-placed `Enemy` node in the room calls `initialize(data)` in `_ready()`.
3. During play, `Enemy._physics_process()` moves the enemy toward the player when `_state == PURSUING`.
4. `Enemy.ContactArea` fires `body_entered` → starts damage timer → calls `StatsComponent.take_damage()` at each cooldown expiry.
5. `Player.CombatComponent` fires `take_damage()` on overlapping enemies via its own `Area2D`.
6. When `Enemy.current_health <= 0`, `take_damage()` emits `defeated` and calls `queue_free()`.
7. When `StatsComponent.current_health <= 0`, `died` fires → `Main.gd` emits `GlobalSignals.gameplay_ended`.
