# Tasks: Elite Room Depth Bands

**Input**: Design documents from `/specs/082-elite-depth-bands/`
**Prerequisites**: plan.md ✅, spec.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to
- Exact file paths in every description

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that must be complete before any band data is wired in.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 Update `data/dungeon_config.json` — remove `spawn_configs.EliteRoom01`; add `spawn_configs.ForestEliteRoom01` with `essence_mult: 1.8` and `enemy_count_mult: 1.5` (no spawn_points); add empty `elite_depth_bands: []` array at the top level alongside `depth_bands`
- [x] T002 Update `scripts/dungeon/DungeonGenerator.gd` — in `_promote_elite_rooms()` change the hard-coded string `"EliteRoom01"` to `"ForestEliteRoom01"`
- [x] T003 Update `scripts/dungeon/RoomSpawner.gd` — add `var _is_elite_band_room: bool = false` field; in `_load_config()` add a guard after the `combat_room_pool` check: if `room_type_id.contains("Elite")` set `_is_elite_band_room = true` and return `RoomSpawnConfig.new()`
- [x] T004 Add `_load_elite_depth_band_config(raw: Dictionary) -> RoomSpawnConfig` to `scripts/dungeon/RoomSpawner.gd` — iterates `raw.elite_depth_bands` to find the entry whose `min_depth`/`max_depth` range contains `depth`; performs weighted random variant selection from the matched entry's `variants` array (sum weights, pick by cumulative threshold); builds a `RoomSpawnConfig` with `wave_spawn_points[0]` populated from the selected variant's `wave` slots using `SpawnPointData.from_dict()`; reads `essence_mult` and `enemy_count_mult` from `raw.spawn_configs.get(room_type_id, {})`; sets `cfg.wave_config` to a minimal `WaveConfig` with `waves = [slot_count]`, `trigger_threshold = 0`, `alive_cap = MAX_ENEMIES`, `min_spawn_distance = 200.0`; validates each slot's pool with `_pool_has_unknown_id()` and returns `RoomSpawnConfig.new()` on any error; returns `RoomSpawnConfig.new()` if no band matches
- [x] T005 Update `_on_player_entered()` in `scripts/dungeon/RoomSpawner.gd` — in the spawn-deferred block, add a routing fork: call `_load_elite_depth_band_config(_raw_dungeon_config)` when `_is_elite_band_room`, otherwise call `_load_depth_band_config(_raw_dungeon_config)` when `_is_depth_band_room` (both assign to `_config`)
- [x] T006 Create `tests/unit/test_elite_depth_bands.gd` — test `_load_elite_depth_band_config()` core behavior using inline dict stubs (no autoloads): band matching by exact depth and boundary values (depth 2, 4, 6, 7, 8), no-match returns empty config, weighted variant selection returns a result within the valid set, `essence_mult` and `enemy_count_mult` propagate correctly from `spawn_configs`, pool validation rejects unknown enemy IDs

**Checkpoint**: Elite rooms now route through the new method. With `elite_depth_bands: []` the method returns an empty config (no enemies spawn). Ready to add band data.

---

## Phase 2: User Story 1 — Depth 1–2 Composition (Priority: P1) 🎯 MVP

**Goal**: Elite rooms at depth 2 spawn the correct 4-enemy composition with the 50/50 buffer/reflector slot.

**Independent Test**: Start a run, enter the depth-2 elite room, verify 4 enemies spawn: 2× forest_tank, 1× forest_disruptor, 1× forest_buffer or forest_reflector.

- [x] T007 [US1] Add Band 1 entry to `elite_depth_bands` in `data/dungeon_config.json` — `min_depth: 1`, `max_depth: 2`, one variant with `weight: 100` and 4 slots: `forest_tank` at `(-350, -200)` r40; `forest_tank` at `(350, -200)` r40; `forest_disruptor` at `(0, -200)` r40; pool `[{forest_buffer, 50}, {forest_reflector, 50}]` at `(0, 250)` r40
- [x] T008 [US1] Add Band 1 tests to `tests/unit/test_elite_depth_bands.gd` — verify depth 1 and depth 2 both select Band 1; verify the single variant is always selected; verify the 4th slot pool contains exactly `forest_buffer` and `forest_reflector` with equal weights; verify `wave_spawn_points[0].size() == 4`

**Checkpoint**: US1 fully functional. Depth-2 elite encounter works in-game.

---

## Phase 3: User Story 2 — Depth 3–4 Weighted Composition (Priority: P1)

**Goal**: Elite rooms at depth 4 draw from two weighted variants (70% with healer, 30% without).

**Independent Test**: Enter a depth-4 elite room, confirm the encounter is one of the two valid 5-enemy compositions; observe healer variant appears more frequently across multiple runs.

- [x] T009 [US2] Add Band 2 entry to `elite_depth_bands` in `data/dungeon_config.json` — `min_depth: 3`, `max_depth: 4`; variant A `weight: 70`: forest_tank at (-350,-200) r40, forest_tank at (350,-200) r40, forest_disruptor at (0,-200) r40, forest_healer at (-150,250) r40, pool [forest_buffer 50/forest_reflector 50] at (150,250) r40; variant B `weight: 30`: forest_tank at (-350,-200) r40, forest_tank at (350,-200) r40, forest_tank at (0,-200) r40, forest_disruptor at (-150,250) r40, pool [forest_buffer 50/forest_reflector 50] at (150,250) r40
- [x] T010 [US2] Add Band 2 tests to `tests/unit/test_elite_depth_bands.gd` — verify depth 3 and depth 4 both select Band 2; across 1000 draws verify variant A appears between 650–750 times (70% ± 5%); verify variant A has 5 slots including forest_healer; verify variant B has 5 slots with 3× forest_tank

**Checkpoint**: US2 functional. Weighted selection verified in tests.

---

## Phase 4: User Story 3 — Depth 5–6 Complex Composition (Priority: P2)

**Goal**: Elite rooms at depth 6 draw from three variants (60%/30%/10%); the 10% variant has both forest_buffer and forest_reflector simultaneously.

**Independent Test**: Enter a depth-5 or depth-6 elite room and confirm the encounter matches one of the three valid compositions; verify the 10% variant (dual special) is structurally correct when it appears.

- [x] T011 [US3] Add Band 3 entry to `elite_depth_bands` in `data/dungeon_config.json` — `min_depth: 5`, `max_depth: 6`; variant A `weight: 60`: forest_tank (-350,-200) r40, forest_disruptor (350,-200) r40, forest_healer (-150,200) r40, forest_poisoner (150,200) r40, pool [forest_buffer 50/forest_reflector 50] (0,280) r40; variant B `weight: 30`: forest_tank (-350,-200) r40, forest_tank (350,-200) r40, forest_disruptor (-150,200) r40, forest_poisoner (150,200) r40, pool [forest_buffer 50/forest_reflector 50] (0,280) r40; variant C `weight: 10`: forest_tank (-350,-200) r40, forest_tank (350,-200) r40, forest_disruptor (0,-200) r40, forest_healer (-150,280) r40, forest_buffer (150,280) r40, forest_reflector (0,280) r40
- [x] T012 [US3] Add Band 3 tests to `tests/unit/test_elite_depth_bands.gd` — verify depth 5 and depth 6 select Band 3; across 1000 draws verify variant A 550–650, variant B 250–350, variant C 50–150; verify variant A contains forest_healer and forest_poisoner; verify variant B contains 2× forest_tank and forest_poisoner; verify variant C contains both forest_buffer and forest_reflector as fixed (non-pool) slots

**Checkpoint**: US3 functional. Three-variant distribution tested.

---

## Phase 5: User Story 4 — Depth 7+ Composition (Priority: P2)

**Goal**: Elite rooms at depth 7 and beyond use the same composition as Band 3.

**Independent Test**: With Adventuring Gear active, enter a depth-8 elite room and confirm the composition matches a Band 3 variant.

- [x] T013 [US4] Add Band 4 entry to `elite_depth_bands` in `data/dungeon_config.json` — `min_depth: 7`, `max_depth: -1`; identical variants and weights to Band 3 (copy the three variant definitions)
- [x] T014 [US4] Add Band 4 tests to `tests/unit/test_elite_depth_bands.gd` — verify depth 7 and depth 8 select Band 4 (not Band 3); verify Band 4's variant structure is identical to Band 3 (same slot counts, same enemy IDs, same weights)

**Checkpoint**: All four bands implemented and unit-tested. Full feature complete.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately
- **US1 (Phase 2)**: Requires Phase 1 complete
- **US2 (Phase 3)**: Requires Phase 1 complete; independent of US1
- **US3 (Phase 4)**: Requires Phase 1 complete; independent of US1/US2
- **US4 (Phase 5)**: Requires Phase 1 complete; independent of all other US phases

### Within Phase 1

- T001–T002 [P]: Edit different files, can run in parallel
- T003–T005: All edit `RoomSpawner.gd` — sequential
- T006: Requires T003–T005 complete (tests the new method)

### Parallel Opportunities

- T001 and T002 can run in parallel (different files)
- T007 and T008 are sequential (data then test)
- Once Phase 1 is complete, US1–US4 phases can proceed independently (each edits different JSON array entries and adds to the same test file sequentially)

---

## Implementation Strategy

### MVP (Phase 1 + US1 only)

1. Complete Phase 1 (T001–T006) — routing infrastructure in place
2. Complete Phase 2 (T007–T008) — Band 1 data and tests
3. **STOP and VALIDATE**: Enter depth-2 elite in-game, verify 4-enemy encounter
4. Confirms the entire mechanism works end-to-end before adding remaining bands

### Incremental Delivery

1. Phase 1 → infrastructure ready, elite rooms spawn 0 enemies (safe default)
2. Phase 2 → depth 1–2 band live
3. Phase 3 → depth 3–4 band live
4. Phase 4 → depth 5–6 band live
5. Phase 5 → depth 7+ band live (Adventuring Gear runs)
