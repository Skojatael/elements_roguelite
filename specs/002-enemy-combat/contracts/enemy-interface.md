# Contract: Enemy Interface

**Feature**: `002-enemy-combat`
**File**: `scenes/combat/enemies/Enemy.gd`

---

## Class Declaration

```gdscript
class_name Enemy
extends CharacterBody2D
```

---

## Exports & Public Properties

```gdscript
## Read-only from outside — remaining health of this enemy instance.
var current_health: float
```

---

## Public API

### `initialize(data: EnemyData) -> void`

Copies all stats from `data` into the enemy instance. MUST be called immediately after the enemy node enters the scene tree (e.g., from the room scene's `_ready()`). Calling any other method before `initialize()` is a programming error.

**Preconditions**: `data` is a valid, fully populated `EnemyData` (all fields pass validation).
**Postconditions**: `current_health == data.max_health`; internal state is `IDLE`.

---

### `take_damage(amount: float) -> void`

Reduces `current_health` by `amount`. If `current_health` drops to 0 or below, emits `defeated` and calls `queue_free()`.

**Preconditions**: `amount >= 0`. `initialize()` has been called.
**Postconditions**:
- `current_health` reduced by `amount`, clamped to minimum 0.
- If `current_health <= 0`: `defeated` emitted; node is freed.

---

## Signals

```gdscript
signal defeated
```

Emitted once, immediately before `queue_free()`. Consumers (e.g., a future room kill counter) connect to this signal.

---

## Internal Nodes (set up in Editor)

| Node | Type | Purpose |
|---|---|---|
| `CollisionShape2D` | `CollisionShape2D` | Physical body collision |
| `DetectionArea` | `Area2D` + `CollisionShape2D` | Large circle; triggers pursuit state |
| `ContactArea` | `Area2D` + `CollisionShape2D` | Small circle; triggers contact damage |

---

## Behaviour Guarantees

| Condition | Guaranteed Behaviour |
|---|---|
| Player enters `DetectionArea` | Enemy state → `PURSUING`; enemy moves toward player each `_physics_process` |
| Player exits `DetectionArea` | Enemy state → `IDLE`; movement stops |
| Player enters `ContactArea` | Contact damage timer starts; `StatsComponent.take_damage(damage)` called every `damage_cooldown` seconds |
| Player exits `ContactArea` | Contact damage timer stops |
| `current_health <= 0` after `take_damage()` | `defeated` emitted; `queue_free()` called; enemy no longer collidable |
| `initialize()` not called | `_ready()` assertion fails with descriptive error |
