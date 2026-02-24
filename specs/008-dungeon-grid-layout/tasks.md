# Tasks: Dungeon Grid Layout

**Input**: Design documents from `specs/008-dungeon-grid-layout/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/signals.md ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Exact file paths are included in every task description

---

## Phase 1: Setup

**Purpose**: Update the data config before any script work begins. All downstream tasks depend on this.

- [x] T001 Rename `"room_sequence"` key to `"combat_room_pool"` and replace its value with `["CombatRoom01", "CombatRoom02"]` in `data/dungeon_config.json`

---

## Phase 2: Foundational (DungeonGenerator Scaffolding)

**Purpose**: Replace the old constant and add all helpers and output properties to `scenes/dungeon/DungeonGenerator.gd`. These are prerequisites for every user story phase.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T002 Replace the single `ROOM_SPACING: int = 2000` constant with five constants — `GRID_SIZE: int = 5`, `TARGET_ROOM_COUNT: int = 8`, `SPACING_X: int = 2000`, `SPACING_Y: int = 1200`, `CENTER: Vector2i = Vector2i(2, 2)` — in `scenes/dungeon/DungeonGenerator.gd`

- [x] T003 Declare three public output properties below the constants — `var rooms_by_id: Dictionary = {}`, `var neighbours_by_id: Dictionary = {}`, `var start_room_id: String = ""` — in `scenes/dungeon/DungeonGenerator.gd`

- [x] T004 Implement `_get_world_pos(cell: Vector2i) -> Vector2` returning `Vector2((cell.x - CENTER.x) * SPACING_X, (cell.y - CENTER.y) * SPACING_Y)` in `scenes/dungeon/DungeonGenerator.gd`

- [x] T005 Implement `_get_valid_neighbours(cell: Vector2i, occupied: Dictionary) -> Array[Vector2i]` returning the subset of the four cardinal neighbours `(cell + Vector2i(1,0), (-1,0), (0,1), (0,-1))` whose `x` and `y` both fall in `[0, GRID_SIZE)` and that are not already keys in `occupied` in `scenes/dungeon/DungeonGenerator.gd`

**Checkpoint**: Scaffolding complete — user story tasks can now proceed sequentially.

---

## Phase 3: User Story 1 — Dungeon Expands Organically from the Center (Priority: P1) 🎯 MVP

**Goal**: `_generate()` runs frontier expansion and populates `rooms_by_id` and `start_room_id`.

**Independent Test**: Start a run. Inspect `DungeonGenerator.rooms_by_id` in the remote inspector — expect exactly 8 keys, all with valid `grid_pos` (col/row 0–4), and key `"room_2_2"` always present. Inspect `start_room_id` — expect `"room_2_2"`. Start two more runs and confirm key sets differ.

- [x] T006 [US1] Implement `_record_room(cell: Vector2i, type_id: String, occupied: Dictionary, frontier: Array) -> void` — computes `room_id = "room_{cell.x}_{cell.y}"`, writes `{ "room_type_id": type_id, "grid_pos": cell, "world_pos": _get_world_pos(cell) }` into `rooms_by_id[room_id]`, sets `occupied[cell] = room_id`, then appends each cell from `_get_valid_neighbours(cell, occupied)` that is not already in `frontier` — in `scenes/dungeon/DungeonGenerator.gd`

- [x] T007 [US1] Rewrite `_generate()` — (1) clear `rooms_by_id`, `neighbours_by_id`, `start_room_id`; (2) declare `occupied: Dictionary = {}` and `frontier: Array = []`; (3) call `_record_room(CENTER, "", occupied, frontier)` (type_id placeholder, replaced in T008); (4) set `start_room_id = "room_2_2"`; (5) loop `while occupied.size() < TARGET_ROOM_COUNT and not frontier.is_empty()`: pick `idx = randi() % frontier.size()`, pop `cell = frontier[idx]; frontier.remove_at(idx)`, call `_record_room(cell, "", occupied, frontier)`; (6) if `occupied.size() < TARGET_ROOM_COUNT`: call `push_warning(...)` — in `scenes/dungeon/DungeonGenerator.gd`

**Checkpoint**: US1 independently testable — `rooms_by_id` populated with 8 entries, `"room_2_2"` always present, layouts vary across runs.

---

## Phase 4: User Story 2 — Random Combat Room Type per Cell (Priority: P1) 🎯 MVP

**Goal**: Wire `combat_room_pool` into `_generate()` so every `_record_room()` call receives a randomly selected `room_type_id`.

**Independent Test**: Start a run. Inspect every `room_type_id` value in `rooms_by_id` — all must be `"CombatRoom01"` or `"CombatRoom02"`. Run 5 times and confirm both types appear. Set pool to `[]`, confirm `push_error` fires and `rooms_by_id` is empty.

- [x] T008 [US2] In `_generate()`: add `var raw: Dictionary = ResourceManager.get_dungeon_config()`, `var pool: Array = raw.get("combat_room_pool", [])`, then `if pool.is_empty(): push_error("DungeonGenerator: combat_room_pool missing or empty in dungeon_config.json"); return`; also add `if TARGET_ROOM_COUNT > GRID_SIZE * GRID_SIZE: push_error("DungeonGenerator: TARGET_ROOM_COUNT exceeds grid capacity"); ` (execution continues, capped by frontier); replace all `_record_room(..., "", ...)` placeholder calls with `_record_room(..., pool.pick_random(), ...)` — in `scenes/dungeon/DungeonGenerator.gd`

**Checkpoint**: US2 independently testable — all rooms have CombatRoom* types, both types appear across runs, empty pool logs error and returns cleanly.

---

## Phase 5: User Story 3 — Player Placed at Center Room (Priority: P1) 🎯 MVP

**Goal**: Build `neighbours_by_id` from the occupied set, then place the player at `rooms_by_id[start_room_id].world_pos`.

**Independent Test**: Start a run. Inspect `DungeonGenerator.neighbours_by_id` — every key must map to a non-empty Array; adjacency must be bidirectional. Check Player `global_position` in remote inspector — must be `(0, 0)`.

- [x] T009 [US3] Implement `_build_neighbours(occupied: Dictionary) -> void` — for each `cell` in `occupied.keys()`: set `neighbours_by_id[occupied[cell]] = []`, then for each of the four cardinal offsets `(Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1))`: if `occupied.has(cell + offset)` append `occupied[cell + offset]` to `neighbours_by_id[occupied[cell]]` — in `scenes/dungeon/DungeonGenerator.gd`

- [x] T010 [US3] In `_generate()`: after the frontier loop, add `_build_neighbours(occupied)`; then replace the existing `_place_player(...)` call (or add one if removed) with `_place_player(rooms_by_id[start_room_id]["world_pos"])` — in `scenes/dungeon/DungeonGenerator.gd`

**Checkpoint**: All three user stories independently testable. `rooms_by_id` has 8 entries, `neighbours_by_id` is bidirectional, player spawns at `(0, 0)`.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Logging and final validation.

- [x] T011 Add a layout summary `print` after `_build_neighbours()` in `_generate()` that logs `"[DungeonGenerator] layout rooms={count} start={start_room_id} cells={keys}"` using `.format({"count": ..., "start": ..., "keys": rooms_by_id.keys()})` in `scenes/dungeon/DungeonGenerator.gd`

- [ ] T012 Run all 14 validation scenarios from `specs/008-dungeon-grid-layout/quickstart.md` — inspect `rooms_by_id`, `neighbours_by_id`, `start_room_id` in remote inspector, verify player position, confirm no scenes are spawned, test empty pool error path

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on T001 (config updated)
- **US1 (Phase 3)**: Depends on Phase 2 complete (T002–T005)
- **US2 (Phase 4)**: Depends on Phase 3 complete (T006–T007) — modifies `_generate()`
- **US3 (Phase 5)**: Depends on Phase 4 complete (T008) — adds to `_generate()`
- **Polish (Phase 6)**: Depends on Phase 5 complete

### User Story Dependencies

- **US1**: Requires foundational scaffolding only
- **US2**: Requires US1 (`_generate()` skeleton must exist to wire pool into)
- **US3**: Requires US2 (`rooms_by_id` fully populated before `_build_neighbours` is meaningful)

### Within Each Phase

- T002 → T003 → T004 → T005 (same file, sequential; logical order)
- T006 before T007 (`_record_room()` must exist before `_generate()` calls it)
- T009 before T010 (`_build_neighbours()` must exist before it is called)

### Parallel Opportunities

All phases in this feature modify the same file (`DungeonGenerator.gd`) sequentially. The only genuine parallel opportunity:

- T001 (config JSON) is independent of all DungeonGenerator.gd edits and can be applied at any point before the code is run.

---

## Parallel Example: Foundational Phase

```text
# T001 can be applied while T002–T005 are being written:
Task: "Update data/dungeon_config.json"         ← different file, any time
Task: "Add constants to DungeonGenerator.gd"    ← T002
Task: "Add output properties"                   ← T003 (after T002)
Task: "Add _get_world_pos()"                    ← T004 (after T003)
Task: "Add _get_valid_neighbours()"             ← T005 (after T004)
```

---

## Implementation Strategy

### MVP First (All three stories — delivered together)

All three user stories are P1 and delivered as a single algorithm. Complete them in order:

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational scaffolding (T002–T005)
3. Complete Phase 3: US1 — frontier expansion core (T006–T007)
4. Complete Phase 4: US2 — pool type wiring (T008)
5. Complete Phase 5: US3 — neighbours + player placement (T009–T010)
6. **STOP and VALIDATE**: Run quickstart scenarios 1–14
7. Complete Phase 6: Polish (T011–T012)

### Incremental Checkpoints

After T007: `rooms_by_id` is populated (type_ids are placeholders `""`) — layout shape is verifiable.
After T008: Type assignment works — all quickstart type-related scenarios pass.
After T010: Full feature complete — all 14 scenarios should pass.

---

## Notes

- All script edits are in `scenes/dungeon/DungeonGenerator.gd` — no new files, no new scenes
- Data change: `data/dungeon_config.json` (`room_sequence` → `combat_room_pool`)
- Generation is pure data — **no calls to `RunManager.spawn_room()`, `RoomFactory`, or `load()`** anywhere in the new `_generate()`
- `_ready()` and `_on_run_started()` are untouched
- `_place_player()` body is untouched — only its call site changes (pass `rooms_by_id[start_room_id]["world_pos"]`)
- Commit after each phase completes
