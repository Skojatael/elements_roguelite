# Implementation Plan: Dungeon Depth & Difficulty Scaling

**Branch**: `010-depth-difficulty` | **Date**: 2026-02-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/010-depth-difficulty/spec.md`

---

## Summary

Extend the dungeon layout with per-room depth (grid Manhattan distance from start) and a derived difficulty multiplier (`1.0 + 0.12 × depth`). At generation time, rooms at depth-milestone slots (2, 4, …) are promoted to the existing EliteRoom01 type. The multiplier flows to `RoomSpawner` via a new `difficulty_mult` property, then to each spawned enemy via a new `apply_difficulty()` method on `Enemy.gd` — scaling max health only.

---

## Technical Context

**Language/Version**: GDScript, Godot 4.6
**Primary Dependencies**: `DungeonGenerator` (008) — `rooms_by_id`, `neighbours_by_id`; `RoomLoader` (009) — sets difficulty_mult on spawner; `RoomSpawner` (003) — spawns enemies; `Enemy.gd` — applies multiplier; `EliteRoom01` (scene + .tres already exist)
**Storage**: No changes to data files. `EliteRoom01.tres` already at `res://data/rooms/EliteRoom01.tres`.
**Testing**: Manual playtest via Godot Remote Inspector (see `quickstart.md`, 14 scenarios)
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Project Type**: Godot 4.6 mobile game
**Performance Goals**: O(1) depth computation per room; promotion loop O(N rooms) — negligible at 8 rooms
**Constraints**: Mobile renderer; Jolt physics; no raw `.tscn` editing; no hard-coded balance values in `.gd`

---

## Constitution Check

### Principle I — Single Responsibility ✅

- `DungeonGenerator._promote_elite_rooms()`: new private method, single purpose — elite slot assignment. Does not absorb spawning or loading logic.
- `DungeonGenerator._record_room()`: depth and difficulty_mult are pure data derived from `cell` — a natural part of the room record computation, not a mixed concern.
- `RoomSpawner`: new `difficulty_mult` field and one `apply_difficulty()` call in `_spawn_enemies()`. Spawner's responsibility (spawn enemies in a room with correct stats) is unchanged in scope.
- `Enemy.apply_difficulty()`: Enemy owns its own stats mutation. External code does not reach into `_stats` directly.
- No existing script absorbs a second responsibility.

### Principle II — Data-Driven Content ✅

- `ELITE_START = 2` and `ELITE_STEP = 2` are structural dungeon-generation constants, not game-balance values (they define the algorithm shape, not the difficulty curve). Acceptable as named GDScript constants per constitution precedent (`GRID_SIZE`, `SPACING_X`).
- `difficulty_mult = 1.0 + 0.12 × depth`: the formula coefficients (`1.0`, `0.12`) are balance values. Exception justified because the spec explicitly states the formula is fixed and non-configurable in this feature. If tuning is required in the future, the formula moves to `dungeon_config.json` at that time.
- No enemy stat values are hard-coded — `max_health` still comes from `enemies.json`; the multiplier is applied at runtime.

### Principle III — Mobile-First Performance ✅

- Depth = O(1) per room (two subtractions + abs). Zero allocations.
- `_promote_elite_rooms()` = O(N) over 8 rooms. Single pass, no sorting, no allocations beyond local Array.
- `apply_difficulty()` = two float multiplications per enemy. Negligible.
- No new nodes, scenes, or draw calls added.

### Principle IV — Editor-Centric Workflow ✅

- No `.tscn` files are modified. All changes are in `.gd` files.
- `EliteRoom01.tscn` and `EliteRoom01.tres` already exist — no editor work required.

### Principle V — Simplicity & YAGNI ✅

- No new autoloads, base classes, or utility scripts introduced.
- `_promote_elite_rooms()` is a private method, not an abstraction for reuse.
- `apply_difficulty()` is a single 2-line method — no over-engineering.
- Feature 011 (RunState) will track `max_depth_reached` using the same `depth` field added here — no structural change to RunState will be needed.

---

## Project Structure

### Documentation (this feature)

```text
specs/010-depth-difficulty/
├── plan.md              ← This file
├── research.md          ← Phase 0 (7 decisions)
├── data-model.md        ← Phase 1
├── quickstart.md        ← Phase 1 (14 scenarios)
├── contracts/
│   └── interfaces.md   ← Phase 1
└── tasks.md             ← Phase 2 (/speckit.tasks)
```

### Source Code

**Modified GDScript files**:

```text
scenes/dungeon/DungeonGenerator.gd    ← add ELITE_START/STEP constants; extend _record_room() with depth+mult; add _promote_elite_rooms()
scenes/dungeon/RoomLoader.gd          ← set spawner.difficulty_mult after spawn_room() returns
scenes/dungeon/RoomSpawner.gd         ← add @export difficulty_mult: float = 1.0; call apply_difficulty() in _spawn_enemies()
scenes/combat/enemies/Enemy.gd        ← add func apply_difficulty(mult: float) -> void
```

**No new files** — all changes are additions to existing scripts.
**No scene file changes** — editor work not required for this feature.
**No data file changes** — `EliteRoom01` assets already exist.

---

## Implementation Phases

### Phase 1 — DungeonGenerator: depth + difficulty_mult in _record_room()

Edit `scenes/dungeon/DungeonGenerator.gd`:

1. Add two constants after existing constants:
   ```gdscript
   const ELITE_START: int = 2
   const ELITE_STEP: int = 2
   ```

2. In `_record_room()`, compute depth and difficulty_mult from `cell`, then add both to the `rooms_by_id` entry:
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

### Phase 2 — DungeonGenerator: _promote_elite_rooms()

Add a new private method to `DungeonGenerator.gd`. Call it from `_generate()` after `_build_neighbours()` and before `dungeon_layout_ready.emit()`:

```gdscript
func _promote_elite_rooms() -> void:
    var d: int = ELITE_START
    while d <= GRID_SIZE * 2:
        var candidates: Array[String] = []
        for room_id: String in rooms_by_id:
            if rooms_by_id[room_id]["depth"] == d:
                candidates.append(room_id)
        if not candidates.is_empty():
            var chosen: String = candidates.pick_random()
            rooms_by_id[chosen]["room_type_id"] = "EliteRoom01"
            print("[DungeonGenerator] elite promoted room_id={id} at depth={d}".format({"id": chosen, "d": d}))
        d += ELITE_STEP
```

In `_generate()`, insert between `_build_neighbours(occupied)` and `dungeon_layout_ready.emit()`:
```gdscript
_promote_elite_rooms()
```

### Phase 3 — Enemy: apply_difficulty()

Edit `scenes/combat/enemies/Enemy.gd`. Add method after `initialize()`:

```gdscript
func apply_difficulty(mult: float) -> void:
    _stats.max_health *= mult
    _stats.current_health = _stats.max_health
```

### Phase 4 — RoomSpawner: difficulty_mult property + apply call

Edit `scenes/dungeon/RoomSpawner.gd`:

1. Add export field (after `@export var auto_register`):
   ```gdscript
   ## Applied to each spawned enemy's maximum health. Set by RoomLoader after spawn_room().
   @export var difficulty_mult: float = 1.0
   ```

2. In `_spawn_enemies()`, after `get_parent().add_child(enemy)`:
   ```gdscript
   enemy.apply_difficulty(difficulty_mult)
   ```

### Phase 5 — RoomLoader: set difficulty_mult on spawner

Edit `scenes/dungeon/RoomLoader.gd`. In `_load_room()`, after the `spawner == null` guard:

```gdscript
var room_mult: float = _dungeon_gen.rooms_by_id[room_id].get("difficulty_mult", 1.0)
spawner.difficulty_mult = room_mult
```

### Phase 6 — Validate

Run all 14 scenarios from `specs/010-depth-difficulty/quickstart.md`.

---

## Key Design Decisions

| Decision | Summary |
|---|---|
| Depth method | Grid Manhattan distance — O(1), computed in `_record_room()` alongside grid_pos |
| Storage | Extend existing `rooms_by_id` entry — no new dictionaries |
| Elite timing | `_promote_elite_rooms()` after `_build_neighbours()`, before `dungeon_layout_ready.emit()` |
| Multiplier delivery | `RoomSpawner.difficulty_mult` set by RoomLoader after `spawn_room()` returns |
| Enemy application | `enemy.apply_difficulty(mult)` called after `add_child()` — enemy is initialized, player hasn't entered yet |
| Elite type | `"EliteRoom01"` — existing scene, .tres resource, spawn config; override at generation time |
| Constants | `ELITE_START=2`, `ELITE_STEP=2` as named GDScript constants (not data-driven in this feature) |

*(See `research.md` for full rationale on each decision.)*
