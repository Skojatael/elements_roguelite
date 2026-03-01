# Tasks: Essence Currency

**Input**: Design documents from `/specs/014-essence-currency/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Tasks grouped by user story. US1 (earn essence per kill) and US2 (cash out on run end) are both P1 MVP. US1 has more foundational prerequisites; US2 is a single task that can be done independently once RunManager is touched.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

No project initialization required. No new dependencies. Pure modifications to existing files.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data layer and infrastructure required before either user story can work.

**⚠️ CRITICAL**: T003, T004, T005 cannot proceed until T001 and T002 exist.

- [x] T001 [P] Add `base_essence` to `data/enemies.json` — add `"base_essence": 2` to the slime entry and `"base_essence": 3` to the skeleton entry
- [x] T002 [P] Add `base_essence` field to `scripts/data_models/EnemyData.gd` — add `var base_essence: float` field; in `from_dict()` add `d.base_essence = float(data.get("base_essence", 0.0))` after the existing assignments (use `.get()` with default `0.0`, NOT `assert`)
- [x] T003 Extend `autoload/ResourceManager.gd` — add `var _enemy_essence_cache: Dictionary = {}`; rename `_load_enemy_ids()` to `_load_enemy_data()` and update the single internal call to it; inside `_load_enemy_data()` add `_enemy_essence_cache[entry["id"]] = float(entry.get("base_essence", 0.0))` alongside the existing ID append; add `func get_enemy_base_essence(id: String) -> float` that calls `_load_enemy_data()` if not loaded and returns `_enemy_essence_cache.get(id, 0.0)`
- [x] T004 Modify `scripts/dungeon/RoomSpawner.gd` — (a) add `@export var depth: int = 0` alongside `difficulty_mult`; (b) add signal `enemy_defeated(enemy_type_id: String)`; (c) in `_spawn_enemies()` change `enemy.defeated.connect(_on_enemy_defeated)` to `enemy.defeated.connect(_on_enemy_defeated.bind(sp.enemy_id))`; (d) update `_on_enemy_defeated` signature to `_on_enemy_defeated(enemy_type_id: String)` and add `enemy_defeated.emit(enemy_type_id)` as the first line of the method body
- [x] T005 Modify `scripts/dungeon/RoomLoader.gd` — add `spawner.depth = _dungeon_gen.rooms_by_id[room_id].get("depth", 0)` immediately after the existing `spawner.difficulty_mult = room_mult` line in `_load_room()`

**Checkpoint**: Data layer complete. ResourceManager can return `base_essence`. RoomSpawner emits `enemy_defeated(enemy_type_id)` with correct depth field set by RoomLoader. Ready for US1 wiring.

---

## Phase 3: User Story 1 — Earning Essence by Killing Enemies (Priority: P1) 🎯 MVP

**Goal**: Every enemy kill during an active run awards `floori(base_essence × (1 + 0.10 × depth))` essence to the run total.

**Independent Test**: Start a run. Enter a combat room. Kill an enemy. Confirm `[RunManager] currency +N` appears in Output with the correct amount. Kill multiple enemies; confirm each adds individually. Confirm `run_currency` total matches the sum.

- [x] T006 [US1] Modify `scripts/managers/RunManager.gd` — add session field `var current_room_depth: int = 0` alongside the other session fields; add `current_room_depth = 0` to the reset block in `start_run()`; in `_on_room_entered()` add `current_room_depth = (spawner as RoomSpawner).depth` after the existing lines
- [x] T007 [US1] Modify `scripts/managers/RunManager.gd` — add `func _on_enemy_defeated(enemy_type_id: String) -> void` that calculates `var base_essence: float = ResourceManager.get_enemy_base_essence(enemy_type_id)`, then `var essence: int = floori(base_essence * (1.0 + 0.10 * float(current_room_depth)))`, then `if essence > 0: add_currency(float(essence))`; in `register_room()` add `spawner.enemy_defeated.connect(_on_enemy_defeated)` alongside the existing two signal connections

**Checkpoint**: US1 complete. Killing a slime at depth 1 logs `[RunManager] currency +2 — total=2`. Killing a skeleton at depth 2 logs `+3`. Multiple kills accumulate correctly.

---

## Phase 4: User Story 2 — Cashing Out Essence at Run End (Priority: P1) 🎯 MVP

**Goal**: When the run ends, the accumulated essence is printed. Full amount on CASH_OUT; 85% (floored) on DIED.

**Independent Test**: Accumulate some essence, end run via CASH_OUT — confirm `[Essence] X essence cashed out` with full amount. Start fresh run, accumulate essence, die — confirm 85% (floored) printed.

- [x] T008 [US2] Modify `scripts/managers/RunManager.gd` — in `end_run()` insert after `is_run_active = false` and before `run_ended.emit(reason)`: declare `var cashed_out: int`; if `reason == EndReason.DIED` set `cashed_out = floori(run_currency * 0.85)` else set `cashed_out = floori(run_currency)`; print `"[Essence] {amount} essence cashed out".format({"amount": cashed_out})`

**Checkpoint**: US2 complete. Full flow works: kill enemies → accumulate essence → end run → correct amount printed. Both end reasons handled correctly.

---

## Phase 5: Polish & Validation

- [ ] T009 Run all 12 manual validation scenarios from `specs/014-essence-currency/quickstart.md` — pay special attention to Scenario 7 (DIED = 85%), Scenario 9 (fractional floor), and Scenario 10 (essence resets between runs)

---

## Dependencies & Execution Order

### Task Dependencies

| Task | Depends On | Reason |
|---|---|---|
| T001 | — | No dependencies |
| T002 | — | No dependencies |
| T003 | T001 | Caches base_essence from enemies.json |
| T004 | — | No dependencies (signal and depth field are independent) |
| T005 | T004 | Needs `depth` field to exist on RoomSpawner |
| T006 | T004 | Casts to RoomSpawner to read `.depth` |
| T007 | T003, T004, T006 | Needs ResourceManager lookup, enemy_defeated signal, current_room_depth |
| T008 | — | end_run() cash-out is independent of US1 kill logic |
| T009 | T001–T008 | All implementation complete |

### Parallel Opportunities

- T001 and T002 are independent — run in parallel
- T004 is independent — can run alongside T001/T002
- T006 and T008 are independent of each other — can run in parallel once T004 is done
- T007 must wait for T003, T004, T006

---

## Implementation Strategy

### MVP (all 8 code tasks required — US1 and US2 are both P1)

1. T001 + T002 (parallel) → Data layer ready
2. T003 → ResourceManager extended
3. T004 → RoomSpawner updated (can run in parallel with T003)
4. T005 → RoomLoader sets depth (after T004)
5. T006 → RunManager depth caching (after T004)
6. T007 → RunManager kill handler wired (after T003, T004, T006)
7. T008 → Cash-out added (independent, can run alongside T006–T007)
8. T009 → Validate 12 scenarios

### Incremental Checkpoints

- After T005: RoomSpawner emits `enemy_defeated` with correct depth set — US1 wiring can begin
- After T007: Kill enemies → essence awarded — US1 testable independently
- After T008: End run → cash-out message — US2 testable independently

---

## Notes

- T001 and T002 are [P] — different files, write in parallel
- T004 modifies RoomSpawner in 4 specific places; complete all 4 in one pass to avoid partial states
- T007 modifies RunManager in 2 places (new method + register_room addition); complete both together
- `(spawner as RoomSpawner).depth` in T006 requires that `RoomSpawner` class_name is resolvable — it is, since `class_name RoomSpawner` is declared in the file
- `_load_enemy_ids()` internal call in ResourceManager must be updated to `_load_enemy_data()` in T003 — there is exactly one internal call site (`enemy_id_exists()` checks `_enemy_ids_loaded` then calls the loader)
- Cash-out message format: `"[Essence] {amount} essence cashed out"` — match exactly for quickstart validation
