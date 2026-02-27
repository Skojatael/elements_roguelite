# Research Notes: Dungeon Depth & Difficulty Scaling

**Feature**: 010-depth-difficulty
**Date**: 2026-02-27
**Status**: Complete — all questions resolved

---

## Decision 1: Depth Computation Method

**Decision**: Grid Manhattan distance computed inline in `_record_room()`.
`depth = |cell.x - CENTER.x| + |cell.y - CENTER.y|`

**Rationale**:
- O(1) per room — no separate BFS pass required.
- `cell` is already available in `_record_room()` at the point the room is recorded — no additional loop.
- For an unweighted grid graph without shortcuts, BFS hop count equals grid Manhattan distance. Both methods are equivalent for this layout.
- Stores depth directly in the `rooms_by_id` entry alongside `grid_pos` — consistent with the existing data record pattern.

**Alternatives considered**:
- BFS hop count from start room: Same result, O(N) extra pass, more code. Rejected — no benefit over O(1) Manhattan.
- Euclidean (world-space) distance: Differs from grid hop count. Spec explicitly requires Manhattan. Rejected.

---

## Decision 2: Depth and difficulty_mult Storage

**Decision**: Extend the existing `rooms_by_id` entry to include `"depth": int` and `"difficulty_mult": float` fields.

**Rationale**:
- `rooms_by_id` already holds per-room data (`room_type_id`, `grid_pos`, `world_pos`). Adding depth and difficulty_mult is a natural extension of the same record.
- `RoomLoader` already reads from `rooms_by_id` for every room load; reading `difficulty_mult` requires no new data path.
- No separate dictionaries needed — keeps all room data in one lookup.

**Alternatives considered**:
- Separate `depth_by_id` and `mult_by_id` dictionaries: More fragmented, same data, extra lookups. Rejected.
- Compute depth on demand in `RoomLoader`: Requires RoomLoader to know `CENTER` and grid math; duplicates logic outside DungeonGenerator. Rejected.

---

## Decision 3: Elite Promotion Timing

**Decision**: New private method `_promote_elite_rooms()` called at the end of `_generate()`, after `_build_neighbours()`, immediately before `dungeon_layout_ready.emit()`.

**Rationale**:
- All rooms must be placed before promotion — we need to know which rooms exist at each depth.
- `dungeon_layout_ready` consumers (RoomLoader) must see promoted room types, so promotion must precede the signal.
- Separate method keeps `_generate()` readable and gives `_promote_elite_rooms()` a single, well-defined responsibility.

**Alternatives considered**:
- Promote during `_record_room()`: Cannot — not all rooms are placed yet; cannot evaluate the full depth distribution. Rejected.
- Promote in `RoomLoader`: Violates SRP — DungeonGenerator owns layout data, not RoomLoader. Rejected.

---

## Decision 4: difficulty_mult Flow to RoomSpawner

**Decision**: Add `@export var difficulty_mult: float = 1.0` to `RoomSpawner`. `RoomLoader` sets it from `rooms_by_id[room_id]["difficulty_mult"]` immediately after `RunManager.spawn_room()` returns.

**Rationale**:
- `_spawn_enemies()` is called deferred (on player entry), after `_ready()` — so the property can be set in the window between `spawn_room()` return and player entry. No race condition.
- `RoomLoader` already holds the spawner reference and has access to `rooms_by_id`. The assignment is one line.
- `@export` makes the field Inspector-editable, which is useful for manual testing with a specific multiplier.
- Follows the existing pattern: `RoomFactory` sets `auto_register=false` on the spawner before `add_child` for the same "configure before use" reason.

**Alternatives considered**:
- Pass `difficulty_mult` as a parameter to `RunManager.spawn_room()`: Requires changing RunManager's public interface. RunManager is an autoload — wider blast radius for a change that does not belong there. Rejected.
- RoomSpawner reads `difficulty_mult` directly from DungeonGenerator: Creates a direct dependency from RoomSpawner to DungeonGenerator. SRP violation. Rejected.

---

## Decision 5: How Enemy Applies difficulty_mult

**Decision**: Add `func apply_difficulty(mult: float) -> void` method to `Enemy.gd`. `RoomSpawner` calls it immediately after `get_parent().add_child(enemy)` in `_spawn_enemies()`.

**Rationale**:
- `enemy._ready()` fires on `add_child()` → `initialize()` runs → `max_health` and `current_health` are set from JSON data.
- After `add_child()` returns, the enemy is fully initialized. Calling `apply_difficulty(mult)` at that point multiplies `max_health` and resets `current_health` to match.
- Enemy remains responsible for its own stats mutation; external code does not reach into the private `_stats` node.
- `apply_difficulty(1.0)` is a no-op, making it safe to call for depth-0 rooms.

**Alternatives considered**:
- Set `enemy.difficulty_mult` before `add_child()` and apply in `initialize()`: Would require adding difficulty_mult as an Enemy `@export`. Enemy would need to know about dungeon scaling — crosses responsibility boundaries. Rejected.
- RoomSpawner directly sets `enemy._stats.max_health`: Violates encapsulation — `_stats` is a private `@onready` var. Rejected.
- Create a modified `EnemyData` copy with scaled `max_health`: Requires `EnemyData` to be mutable/clonable; adds complexity for a one-line multiplication. Rejected.

---

## Decision 6: Elite Room Type

**Decision**: Use the existing `"EliteRoom01"` room type. `_promote_elite_rooms()` overrides `rooms_by_id[room_id]["room_type_id"] = "EliteRoom01"` for promoted rooms.

**Rationale**:
- `EliteRoom01` scene, `.tres` resource, and `spawn_configs` entry already exist. No new assets needed.
- Overriding `room_type_id` in `rooms_by_id` at generation time means `RoomLoader` picks up the correct type automatically — zero changes to RoomLoader.
- `EliteRoom01`'s spawn config (slime + skeleton) provides a meaningfully harder encounter.
- Promoted rooms are removed from the random pool implicitly — they already were never in `combat_room_pool`.

**Alternatives considered**:
- Create a new dedicated elite scene: Spec says use existing `EliteRoom01`. Rejected.
- Add `EliteRoom01` to `combat_room_pool`: Would allow it to appear at random depths, not just milestones. Contradicts the design intent. Rejected.

---

## Decision 7: Elite Depth Slots as Named Constants

**Decision**: Two named constants in `DungeonGenerator`: `ELITE_START: int = 2`, `ELITE_STEP: int = 2`. `_promote_elite_rooms()` iterates `d = ELITE_START, ELITE_START + ELITE_STEP, ...` up to `GRID_SIZE * 2` (safe upper bound for max depth in a 5×5 grid).

**Rationale**:
- Spec states T=2, step=2 are fixed in this feature (not data-driven).
- Named constants follow YAGNI — no config file entry needed for two fixed integers.
- `GRID_SIZE * 2 = 10` is a safe iteration ceiling (actual max depth in a 5×5 grid from center is 4).

**Alternatives considered**:
- Store in `dungeon_config.json`: Over-engineering for two fixed, non-balance constants in this feature. Rejected per YAGNI.
- Hardcode literals `2` and `4` directly: Less readable; brittle if GRID_SIZE changes later. Rejected.

---

## Integration Summary

| Component | Change |
|---|---|
| `DungeonGenerator.gd` | Extend `rooms_by_id` entry with `depth` + `difficulty_mult`; add `_promote_elite_rooms()` |
| `RoomLoader.gd` | Set `spawner.difficulty_mult` after `RunManager.spawn_room()` returns |
| `RoomSpawner.gd` | Add `@export var difficulty_mult: float = 1.0`; call `enemy.apply_difficulty(difficulty_mult)` in `_spawn_enemies()` |
| `Enemy.gd` | Add `func apply_difficulty(mult: float) -> void` |
| `dungeon_config.json` | No change |
| New files | None |
