# Implementation Plan: Dungeon Grid Layout

**Branch**: `008-dungeon-grid-layout` | **Date**: 2026-02-24 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/008-dungeon-grid-layout/spec.md`

---

## Summary

Replace the existing linear `room_sequence` dungeon generation in `DungeonGenerator.gd` with a frontier-expansion algorithm on a 5×5 virtual grid. Starting from the center cell (2,2), the generator randomly expands to unoccupied N/S/E/W neighbours until 8 cells are recorded. Room types are drawn uniformly at random from a `combat_room_pool` defined in `dungeon_config.json`. The output is three public properties: `rooms_by_id`, `neighbours_by_id`, and `start_room_id`. No scenes are instantiated during generation — scene loading is the responsibility of a separate system (room-at-a-time principle). The player is placed at the world position of `start_room_id` (always (0,0)). Generation is triggered by the existing `RunManager.run_started` signal.

---

## Technical Context

**Language/Version**: GDScript (Godot 4.6); static typing required
**Primary Dependencies**: Godot built-ins — `Vector2i`, `Vector2`, `Dictionary`, `Array`; `ResourceManager` autoload (config read); no scene-spawning calls
**Storage**: `data/dungeon_config.json` (config read only during generation)
**Testing**: Manual validation via Godot remote inspector (see [quickstart.md](quickstart.md))
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: 60 fps on Snapdragon 665-class; 8-room data generation is trivially fast (< 1 ms); no scene loading overhead
**Constraints**: Mobile renderer; Jolt physics; no new autoloads; no new data model scripts; no scene instantiation in generator
**Scale/Scope**: Single script rewrite + one JSON key rename

---

## Constitution Check

*GATE: All five principles must pass before implementation.*

| Principle | Status | Notes |
|---|---|---|
| I. Single Responsibility | ✅ PASS | `DungeonGenerator` owns only layout data generation. Scene loading, enemy spawning, run state remain in separate owners. |
| II. Data-Driven Content | ✅ PASS | Pool of room types in `dungeon_config.json`. Constants (GRID_SIZE, TARGET_ROOM_COUNT, SPACING_X/Y) are structural, not balance values. |
| III. Mobile-First Performance | ✅ PASS | Pure data generation over ≤25 cells, 8 iterations. No scene loading, no shaders, no physics. |
| IV. Editor-Centric Workflow | ✅ PASS | No `.tscn` files touched. `DungeonGenerator` node already exists in Main.tscn. |
| V. Simplicity & YAGNI | ✅ PASS | No new scripts. Output is three plain Dictionary/String properties on the existing generator node. |

**Gate result**: ✅ All five principles pass. Proceed to implementation.

---

## Project Structure

### Documentation (this feature)

```text
specs/008-dungeon-grid-layout/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   └── signals.md       ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code Changes

```text
scenes/dungeon/
└── DungeonGenerator.gd   ← REWRITE _generate() + add helpers + add output properties

data/
└── dungeon_config.json   ← rename room_sequence → combat_room_pool
```

No new files. No new scenes.

---

## Implementation Design

### `data/dungeon_config.json`

Replace `"room_sequence"` with `"combat_room_pool"`:

```json
{
  "combat_room_pool": ["CombatRoom01", "CombatRoom02"],
  "spawn_configs": { ... }
}
```

`EliteRoom01` is excluded from the pool per spec Assumptions.

---

### `scenes/dungeon/DungeonGenerator.gd`

#### Constants (replace `ROOM_SPACING`)

```gdscript
const GRID_SIZE:         int      = 5
const TARGET_ROOM_COUNT: int      = 8
const SPACING_X:         int      = 2000   # 1920 room width + 80 gap
const SPACING_Y:         int      = 1200   # 1080 room height + 120 gap
const CENTER:            Vector2i = Vector2i(2, 2)
```

#### Output properties (public, written by `_generate()`)

```gdscript
## Maps room_id → { "room_type_id": String, "grid_pos": Vector2i, "world_pos": Vector2 }
var rooms_by_id: Dictionary = {}

## Maps room_id → Array[String] of adjacent room_ids present in this layout
var neighbours_by_id: Dictionary = {}

## Always "room_2_2" after a successful generation
var start_room_id: String = ""
```

#### `_ready()` — unchanged

Connects to `RunManager.run_started`.

#### `_on_run_started(_mode: String)` — unchanged

Calls `_generate()`.

#### `_generate()` — complete rewrite

```
1. Clear rooms_by_id, neighbours_by_id, start_room_id.
2. Read raw config; get combat_room_pool array.
3. If pool empty → push_error, return.
4. occupied: Dictionary[Vector2i → String] = {}   # cell → room_id
5. frontier: Array[Vector2i] = []
6. _record_room(CENTER, pool.pick_random(), occupied, frontier)
7. start_room_id = "room_2_2"
8. Loop while occupied.size() < TARGET_ROOM_COUNT and frontier not empty:
   a. idx = randi() % frontier.size()
   b. cell = frontier[idx]; frontier.remove_at(idx)
   c. _record_room(cell, pool.pick_random(), occupied, frontier)
9. If occupied.size() < TARGET_ROOM_COUNT → push_warning
10. _build_neighbours(occupied)
11. _place_player(rooms_by_id[start_room_id].world_pos)
12. Print layout summary.
```

#### `_record_room(cell, type_id, occupied, frontier)` — new helper

```
1. room_id = "room_{cell.x}_{cell.y}"
2. world_pos = _get_world_pos(cell)
3. rooms_by_id[room_id] = { "room_type_id": type_id, "grid_pos": cell, "world_pos": world_pos }
4. occupied[cell] = room_id
5. For each n in _get_valid_neighbours(cell, occupied):
   if n not in frontier: frontier.append(n)
```

#### `_build_neighbours(occupied: Dictionary)` — new helper

```
For each cell in occupied:
    room_id = occupied[cell]
    neighbours_by_id[room_id] = []
    for n in [N, S, E, W]:
        if occupied.has(n):
            neighbours_by_id[room_id].append(occupied[n])
```

Runs once after all cells are recorded. Produces the bidirectional adjacency map.

#### `_get_world_pos(cell: Vector2i) -> Vector2` — new helper

```gdscript
return Vector2((cell.x - CENTER.x) * SPACING_X, (cell.y - CENTER.y) * SPACING_Y)
```

#### `_get_valid_neighbours(cell: Vector2i, occupied: Dictionary) -> Array[Vector2i]` — new helper

Returns the 4 cardinal neighbours of `cell` that are:
- Within `[0, GRID_SIZE)` on both axes
- Not in `occupied`

#### `_place_player(target_pos: Vector2)` — unchanged

---

## Key Algorithms

### Frontier Expansion (pseudo-code)

```text
occupied  = {}
frontier  = []

record_room(center, random_type)   # center always first
start_room_id = "room_2_2"

while occupied.size() < 8 and frontier not empty:
    cell = frontier.pop_random()
    record_room(cell, random_type)

build_neighbours(occupied)         # one pass after all rooms placed
place_player(rooms_by_id["room_2_2"].world_pos)
```

Guarantees:
- **Connected**: every placed cell was in the frontier of an already-occupied cell.
- **Center always occupied**: recorded unconditionally before the loop.
- **Count = TARGET_ROOM_COUNT**: loop terminates at exactly 8 (safe: 8 < 25).
- **No scene loading**: `record_room` writes to Dictionaries only.

### Room ID

```text
room_id = "room_{col}_{row}"   e.g. "room_2_2", "room_1_2", "room_3_4"
```

### World Position

```text
world_pos.x = (col - 2) * 2000
world_pos.y = (row - 2) * 1200
```

---

## Edge Case Handling

| Condition | Handler |
|---|---|
| `combat_room_pool` missing or empty | `push_error`, return early; all output properties stay empty |
| `TARGET_ROOM_COUNT` > 25 (impossible at default) | `push_error`, record as many as possible |
| Frontier exhausted before target | `push_warning`, stop early |
| Second run starts without game restart | `rooms_by_id`, `neighbours_by_id`, `start_room_id` are cleared and rebuilt each generation call |

---

## What Does NOT Change

| Component | Why untouched |
|---|---|
| `RoomSpawner.gd` | Not called by generator; scene loading is a separate concern |
| `RoomFactory.gd` | Not called by generator |
| `RunManager.gd` | Not called by generator; `spawn_room()` belongs to the scene-loading system |
| Room `.tscn` files | No scene changes |
| `RoomData.tres` assets | Not loaded during generation |

---

## Complexity Tracking

No constitution violations. No complexity entries required.
