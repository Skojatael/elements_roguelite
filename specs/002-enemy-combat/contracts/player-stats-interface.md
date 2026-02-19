# Contract: Player Stats Interface

**Feature**: `002-enemy-combat`
**File**: `scenes/player/components/StatsComponent.gd`

---

## Class Declaration

```gdscript
class_name StatsComponent
extends Node
```

---

## Exports & Public Properties

```gdscript
## Maximum and starting health of the player.
@export var max_health: float = 10.0

## Current remaining health. Read-only from outside; modified only via take_damage() / heal().
var current_health: float
```

---

## Public API

### `take_damage(amount: float) -> void`

Reduces `current_health` by `amount`. Clamps result to 0. Emits `health_changed`. If `current_health` reaches 0, emits `died` (exactly once per life).

**Preconditions**: `amount >= 0`.
**Postconditions**:
- `current_health` reduced by `amount`, minimum 0.
- `health_changed` emitted with updated values.
- If `current_health == 0` and health was positive before: `died` emitted once.

---

### `heal(amount: float) -> void`

Increases `current_health` by `amount`. Clamps result to `max_health`. Emits `health_changed`.

**Preconditions**: `amount >= 0`.
**Postconditions**:
- `current_health` increased by `amount`, maximum `max_health`.
- `health_changed` emitted.

---

## Signals

```gdscript
## Emitted whenever current_health changes (damage or heal).
signal health_changed(new_health: float, max_health: float)

## Emitted once when current_health first reaches 0. Main.gd connects this
## to GlobalSignals.gameplay_ended.emit().
signal died
```

---

## Behaviour Guarantees

| Condition | Guaranteed Behaviour |
|---|---|
| `take_damage(0)` called | `current_health` unchanged; `health_changed` still emitted |
| `take_damage(amount)` where `amount > current_health` | `current_health` set to 0; `died` emitted; no negative health |
| `died` after already dead | Not emitted again (guarded by `current_health == 0` check) |
| `heal()` called after death | `current_health` remains 0 (healing a dead player is a no-op for this feature) |
| `max_health <= 0` | `_ready()` assertion fails with descriptive error |
