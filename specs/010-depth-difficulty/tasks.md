# Tasks: Dungeon Depth & Difficulty Scaling

**Input**: Design documents from `specs/010-depth-difficulty/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story. All three stories are P1 MVP. US1 is foundational — US2 and US3 both require its depth data. US2 and US3 are independent of each other.

**Files changed** (no new files, no scene files, no data files):
- `scenes/dungeon/DungeonGenerator.gd` — US1 + US3
- `scenes/combat/enemies/Enemy.gd` — US2
- `scenes/dungeon/RoomSpawner.gd` — US2
- `scenes/dungeon/RoomLoader.gd` — US2

---

## Phase 1: Setup

No project setup required — this feature adds to existing scripts only. No new files, no new dependencies, no data changes.

---

## Phase 2: Foundational (Blocking Prerequisites)

No shared infrastructure required beyond the individual user story phases below. US1 is the prerequisite for US2 and US3.

---

## Phase 3: User Story 1 — Every Room Has a Depth (Priority: P1) 🎯 MVP

**Goal**: Extend `rooms_by_id` entries with `depth` (grid Manhattan distance) and `difficulty_mult` (`1.0 + 0.12 × depth`) computed inline in `_record_room()`.

**Independent Test**: Start a run. Print `rooms_by_id`. Confirm `rooms_by_id["room_2_2"]["depth"] == 0` and `difficulty_mult == 1.0`. For every other room, verify `depth == abs(grid_pos.x - 2) + abs(grid_pos.y - 2)` and `difficulty_mult == 1.0 + 0.12 * depth`. No errors in Output panel.

### Implementation for User Story 1

- [x] T001 [US1] Extend `_record_room()` in `scenes/dungeon/DungeonGenerator.gd`: compute `var depth: int = abs(cell.x - CENTER.x) + abs(cell.y - CENTER.y)` and `var difficulty_mult: float = 1.0 + 0.12 * float(depth)`, add both to the `rooms_by_id[room_id]` Dictionary entry alongside the existing fields

**Checkpoint**: After T001 — start a run, print `rooms_by_id`, confirm depth=0 for start room and correct values for all rooms. US2 and US3 can now begin.

---

## Phase 4: User Story 2 — Deeper Rooms Have Tougher Enemies (Priority: P1) 🎯 MVP

**Goal**: Flow `difficulty_mult` from `rooms_by_id` through `RoomSpawner` to each spawned enemy's max health via `Enemy.apply_difficulty()`.

**Independent Test**: Start a run. Enter a room at depth 1 — check enemy max_health in Remote Inspector, confirm it equals `base_health × 1.12`. Enter a room at depth 2 — confirm `base_health × 1.24`. Start room loads without errors and spawns no enemies.

**⚠️ Depends on**: Phase 3 (T001 must be complete — `difficulty_mult` must exist in `rooms_by_id`)

### Implementation for User Story 2

- [x] T002 [P] [US2] Add `func apply_difficulty(mult: float) -> void` method to `scenes/combat/enemies/Enemy.gd` after `initialize()`: body sets `_stats.max_health *= mult` then `_stats.current_health = _stats.max_health`
- [x] T003 [P] [US2] Add `## Applied to each spawned enemy's max health. Set by RoomLoader after spawn_room(). \n@export var difficulty_mult: float = 1.0` to `scenes/dungeon/RoomSpawner.gd` (after the `auto_register` export), then add `enemy.apply_difficulty(difficulty_mult)` immediately after `get_parent().add_child(enemy)` in `_spawn_enemies()`
- [x] T004 [US2] In `_load_room()` in `scenes/dungeon/RoomLoader.gd`, after the `spawner == null` guard and before `_configure_doors()`, add: `var room_mult: float = _dungeon_gen.rooms_by_id[room_id].get("difficulty_mult", 1.0)` then `spawner.difficulty_mult = room_mult`

**Checkpoint**: After T002–T004 — enemy health scales by depth. Verify with Remote Inspector on depth-1 and depth-2 rooms.

---

## Phase 5: User Story 3 — Elite Rooms Appear at Depth Milestones (Priority: P1) 🎯 MVP

**Goal**: At dungeon generation time, promote one random room per elite depth slot (2, 4, …) to `"EliteRoom01"` type by overriding `rooms_by_id[id]["room_type_id"]`.

**Independent Test**: Start 5 runs. In each, confirm 1–2 rooms have `room_type_id == "EliteRoom01"`. Confirm all elite rooms have depth 2 or 4. Confirm at most one elite room per depth slot. No errors in Output panel.

**⚠️ Depends on**: Phase 3 (T001 must be complete — `depth` must exist in `rooms_by_id`)
**Independent of**: Phase 4 (US2) — can be done in parallel

### Implementation for User Story 3

- [x] T005 [US3] In `scenes/dungeon/DungeonGenerator.gd`: (1) add constants `const ELITE_START: int = 2` and `const ELITE_STEP: int = 2` after the existing constants block; (2) add private method `_promote_elite_rooms()` that iterates depth slots `d = ELITE_START, ELITE_START + ELITE_STEP, ...` up to `GRID_SIZE * 2`, collects candidate room IDs where `rooms_by_id[id]["depth"] == d`, skips silently if empty, otherwise calls `candidates.pick_random()` and sets `rooms_by_id[chosen]["room_type_id"] = "EliteRoom01"` with a print log; (3) call `_promote_elite_rooms()` in `_generate()` between `_build_neighbours(occupied)` and `dungeon_layout_ready.emit()`

**Checkpoint**: After T005 — inspect rooms_by_id after run start. Confirm elite rooms at depth 2 and optionally 4. Confirm no errors.

---

## Phase 6: Polish & Validation

- [ ] T006 Run all 14 manual validation scenarios from `specs/010-depth-difficulty/quickstart.md` and confirm every scenario passes with no errors or warnings in the Output panel

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 3 (US1)** → No dependencies — start immediately
- **Phase 4 (US2)** → Depends on Phase 3 (T001) — depth+mult data must exist in rooms_by_id
- **Phase 5 (US3)** → Depends on Phase 3 (T001) — depth data must exist in rooms_by_id
- **Phase 4 and Phase 5** → Independent of each other — can proceed in parallel once Phase 3 is done
- **Phase 6 (Validation)** → Depends on Phases 3, 4, and 5 all complete

### Task Dependencies

- **T001**: No dependencies — start here
- **T002** [P]: Depends on T001 (needs depth data concept confirmed); independent of T003
- **T003** [P]: Depends on T001; independent of T002 (different file); T004 depends on this
- **T004**: Depends on T003 (references `spawner.difficulty_mult` which T003 defines)
- **T005**: Depends on T001; independent of T002/T003/T004 (DungeonGenerator file)
- **T006**: Depends on T001–T005 all complete

### Parallel Opportunities

- T002 and T003 can run in parallel (different files: Enemy.gd vs RoomSpawner.gd)
- T005 can run in parallel with T002–T004 (different concern, different methods in DungeonGenerator.gd)

---

## Parallel Example: US2 + US3

```
After T001 is complete:

Track A (US2):
  Parallel: T002 (Enemy.gd) + T003 (RoomSpawner.gd)
  Then sequential: T004 (RoomLoader.gd) — depends on T003

Track B (US3):
  T005 (DungeonGenerator.gd) — independent of Track A
```

---

## Implementation Strategy

### MVP (All Three Stories — ~1 hour of coding)

1. T001 — Extend `_record_room()` in DungeonGenerator.gd
2. T002 + T003 — (parallel) Enemy.apply_difficulty() + RoomSpawner.difficulty_mult
3. T004 — RoomLoader sets difficulty_mult on spawner
4. T005 — _promote_elite_rooms() in DungeonGenerator.gd
5. T006 — Validate 14 scenarios

All three stories are P1 and tightly coupled (depth → scaling + elites). Implement in one pass rather than stopping between stories.

---

## Notes

- All 5 code tasks modify existing `.gd` files. No new files, no editor work, no data changes.
- T002 and T003 are marked [P] — different files, no conflict.
- T005 modifies DungeonGenerator.gd (same file as T001), so it must run after T001.
- `apply_difficulty(1.0)` is safe to call for StartRoom01 (no-op) — no special case needed.
- `difficulty_mult` defaults to `1.0` in RoomSpawner — safe if RoomLoader ever fails to set it.
