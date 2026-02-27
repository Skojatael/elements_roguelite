# Data Model: Dungeon Depth & Difficulty Scaling

**Feature**: 010-depth-difficulty
**Date**: 2026-02-27

---

## Extended Room Record (rooms_by_id)

`rooms_by_id` maps `room_id → Dictionary`. This feature adds two fields to each entry:

| Field | Type | New? | Description |
|---|---|---|---|
| `room_type_id` | String | existing | Combat, Elite, or Start room type ID |
| `grid_pos` | Vector2i | existing | Grid coordinates (0–4, 0–4) |
| `world_pos` | Vector2 | existing | World-space centre position |
| `depth` | int | **NEW** | Manhattan distance from start cell; 0 = start room |
| `difficulty_mult` | float | **NEW** | `1.0 + 0.12 × depth`; equals 1.0 for depth 0 |

### Depth Distribution — Typical 8-Room Run

| Depth | Room count | difficulty_mult | Elite promotion? |
|---|---|---|---|
| 0 | 1 (start room) | 1.00 | No (start room) |
| 1 | 2–4 | 1.12 | No |
| 2 | 1–3 | 1.24 | Yes — 1 room promoted |
| 3 | 0–2 | 1.36 | No |
| 4 | 0–1 | 1.48 | Yes — 1 room promoted if present |

---

## Elite Promotion Constants (DungeonGenerator)

| Constant | Value | Description |
|---|---|---|
| `ELITE_START` | `2` | First depth eligible for elite promotion |
| `ELITE_STEP` | `2` | Interval between elite depth slots |

Elite depth slots evaluated in order: `2, 4, 6, 8, ...` up to `GRID_SIZE * 2`.

---

## RoomSpawner — New Field

| Field | Type | Default | Set by | Used by |
|---|---|---|---|---|
| `difficulty_mult` | `float` | `1.0` | `RoomLoader` (post spawn_room) | `_spawn_enemies()` |

---

## Enemy — New Method

```gdscript
func apply_difficulty(mult: float) -> void:
    _stats.max_health *= mult
    _stats.current_health = _stats.max_health
```

**Pre-condition**: Called after `add_child(enemy)` — enemy has been fully initialized via `_ready()` → `initialize()`.
**Effect**: Scales max_health by `mult` and resets current_health to the new maximum.
**No-op case**: `mult = 1.0` — no change (depth-0 rooms, or StartRoom01).

---

## State Transitions

### DungeonGenerator._generate() Sequence

```
1. rooms_by_id.clear()
2. _record_room(CENTER, pool.pick_random(), ...)     ← depth=0, mult=1.0
3. while frontier not empty:
       _record_room(cell, pool.pick_random(), ...)   ← depth computed per cell
4. _build_neighbours(occupied)
5. _promote_elite_rooms()                            ← overrides room_type_id for elite slots
6. dungeon_layout_ready.emit()
```

### _record_room() — Added Lines

```gdscript
var depth: int = abs(cell.x - CENTER.x) + abs(cell.y - CENTER.y)
var difficulty_mult: float = 1.0 + 0.12 * float(depth)
rooms_by_id[room_id] = {
    "room_type_id": type_id,
    "grid_pos":     cell,
    "world_pos":    _get_world_pos(cell),
    "depth":        depth,
    "difficulty_mult": difficulty_mult,
}
```

### _promote_elite_rooms() — Logic

```
for d in range(ELITE_START, GRID_SIZE * 2 + 1, ELITE_STEP):
    candidates = all room_ids where rooms_by_id[id]["depth"] == d
    if candidates is empty:
        continue  (silent skip — FR-009)
    chosen = candidates.pick_random()
    rooms_by_id[chosen]["room_type_id"] = "EliteRoom01"
```

### RoomLoader._load_room() — Added Lines

```gdscript
var spawner: RoomSpawner = RunManager.spawn_room(room_resource, room_id, context)
if spawner == null:
    _loading = false
    return
var room_mult: float = _dungeon_gen.rooms_by_id[room_id].get("difficulty_mult", 1.0)
spawner.difficulty_mult = room_mult
```

### RoomSpawner._spawn_enemies() — Modified Loop

```gdscript
for sp: SpawnPointData in _config.spawn_points:
    var enemy: Enemy = ENEMY_SCENE.instantiate()
    enemy.enemy_type_id = sp.enemy_id
    get_parent().add_child(enemy)          # _ready() → initialize() sets base stats
    enemy.apply_difficulty(difficulty_mult) # scale max_health by room multiplier
    # ... (position, signal connect — unchanged)
```
