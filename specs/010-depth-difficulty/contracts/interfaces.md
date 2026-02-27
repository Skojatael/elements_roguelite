# Interface Contracts: Dungeon Depth & Difficulty Scaling

**Feature**: 010-depth-difficulty
**Date**: 2026-02-27

---

## 1. rooms_by_id Extended Record

**Owner**: `DungeonGenerator`
**Consumed by**: `RoomLoader`
**Changed**: Two new fields added per room entry.

### Contract

Every entry in `rooms_by_id` after `dungeon_layout_ready` MUST contain:

| Key | Type | Guarantee |
|---|---|---|
| `"room_type_id"` | String | Non-empty; may be overridden to `"EliteRoom01"` at promotion time |
| `"grid_pos"` | Vector2i | Grid coordinates within 5×5 bounds |
| `"world_pos"` | Vector2 | World-space centre; `(col-2)*2000, (row-2)*1200` |
| `"depth"` | int | `>= 0`; start room is exactly `0` |
| `"difficulty_mult"` | float | `>= 1.0`; equals `1.0 + 0.12 * depth` |

### Invariants

- `rooms_by_id["room_2_2"]["depth"] == 0` — always.
- `rooms_by_id[id]["difficulty_mult"] == 1.0 + 0.12 * rooms_by_id[id]["depth"]` — always.
- If a room is elite-promoted, `rooms_by_id[id]["room_type_id"] == "EliteRoom01"` and `rooms_by_id[id]["depth"]` is 2 or 4 (in a standard 8-room run).
- At most one room per elite depth slot has `room_type_id == "EliteRoom01"`.

---

## 2. RoomSpawner.difficulty_mult Property

**Owner**: `RoomSpawner` (declares and uses it)
**Set by**: `RoomLoader` (immediately after `RunManager.spawn_room()` returns)
**Used in**: `RoomSpawner._spawn_enemies()`

### Contract

```gdscript
@export var difficulty_mult: float = 1.0
```

- Default `1.0` — no scaling. Safe to leave unset (start room, or any room before first population).
- MUST be set by `RoomLoader` before the player enters the room.
- MUST be `>= 1.0`. Values < 1.0 are not valid inputs for this feature.

### Usage in _spawn_enemies()

After `get_parent().add_child(enemy)`, the spawner calls:
```gdscript
enemy.apply_difficulty(difficulty_mult)
```

---

## 3. Enemy.apply_difficulty() Method

**Owner**: `Enemy`
**Called by**: `RoomSpawner._spawn_enemies()`

### Contract

```gdscript
func apply_difficulty(mult: float) -> void
```

**Pre-condition**: Enemy has been added to the scene tree via `add_child()` — `_ready()` has fired and `initialize()` has set `_stats.max_health` and `_stats.current_health` from JSON data.

**Post-condition**:
- `_stats.max_health == original_max_health * mult`
- `_stats.current_health == _stats.max_health` (reset to new max)

**Idempotency**: NOT idempotent — calling twice with `mult = 1.24` would apply `1.24 × 1.24`. Callers MUST call it exactly once per enemy instance.

**Safe default**: `apply_difficulty(1.0)` is a no-op in effect (multiplies by 1.0).

---

## 4. DungeonGenerator._promote_elite_rooms() (Internal)

**Owner**: `DungeonGenerator` (private — not consumed externally)

### Contract

MUST be called after `_build_neighbours()` and before `dungeon_layout_ready.emit()`.

**Post-condition**:
- For every depth slot `d` in `{ELITE_START, ELITE_START + ELITE_STEP, ...}` up to `GRID_SIZE * 2`:
  - If one or more rooms have `depth == d`: exactly one is promoted to `"EliteRoom01"`.
  - If no rooms have `depth == d`: slot silently skipped, no error emitted.
- No room is ever promoted more than once (depth slots are disjoint integers).
