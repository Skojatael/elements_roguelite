# Tasks: Depth-Banded Enemy Pools

**Input**: Design documents from `/specs/074-depth-banded-enemy-pools/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

**Purpose**: Rename the combat room asset and update the pool — blocks all user stories.

- [ ] T001 Rename `CombatRoom01.tscn` and `CombatRoom01.tres` to `ForestRoom01.tscn` / `ForestRoom01.tres` in the Godot Editor; update the `room_type_id` field on the RoomSpawner node inside the scene and the `room_type_id` export on the RoomData resource to `"ForestRoom01"` *(editor task — user confirmed they will do this)*
- [x] T002 Update `combat_room_pool` in `data/dungeon_config.json` from `["CombatRoom01", "CombatRoom02"]` to `["ForestRoom01"]`

**Checkpoint**: Room pool references ForestRoom01 only. No CombatRoom entries remain in pool.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data model extensions and spawner logic — MUST be complete before any user story band data is added.

- [x] T003 Add `enemy_pool: Array` field to `SpawnPointData` and update `from_dict()` to support both legacy `"enemy_id"` key (wraps as single 100%-weight pool entry) and new `"pool"` key (array of `{enemy_id, weight}` dicts); retain `enemy_id: String` field as the resolved value populated at spawn time in `scripts/data_models/SpawnPointData.gd`
- [x] T004 Add `pick_enemy_id() -> String` method to `SpawnPointData`: iterates `enemy_pool` summing weights, draws `randf() * total_weight`, returns the matching `enemy_id`; returns first entry for single-entry pool (fast path); logs a warning and returns `""` for empty pool in `scripts/data_models/SpawnPointData.gd`
- [x] T005 [P] Write GUT unit tests for `SpawnPointData.pick_enemy_id()` in `tests/unit/test_spawn_point_data.gd`: (a) single-entry 100% pool always returns that enemy_id; (b) empty pool returns `""`; (c) 50/50 pool over 200 samples — both entries appear; (d) single-entry pool with weight 50 (not 100) still returns that entry always; (e) 70/10/10/10 pool over 200 samples — first entry wins majority; use inline dict stubs, no autoloads
- [x] T006 [P] Add `wave_spawn_points: Array` field (empty by default, array of `Array[SpawnPointData]` indexed by wave) to `RoomSpawnConfig` in `scripts/data_models/RoomSpawnConfig.gd`
- [x] T007 Add `_load_depth_band_config() -> RoomSpawnConfig` private method to `RoomSpawner`: reads `depth_bands` array from `ResourceManager.get_dungeon_config()`; finds the matching band for `self.depth` (deepest band whose `min_depth <= depth` and `max_depth == -1` or `max_depth >= depth`); for each wave in the band, creates an `Array[SpawnPointData]` from each slot's `pool` + `position` + `radius` via `SpawnPointData.from_dict()`; validates all `enemy_id` values in all pools via `ResourceManager.enemy_id_exists()`; populates `cfg.wave_spawn_points`; returns the populated `RoomSpawnConfig`; returns empty config with a warning if no band matches in `scripts/dungeon/RoomSpawner.gd`
- [x] T008 Update `_load_config()` in `RoomSpawner`: read `combat_room_pool` from config; if `room_type_id` is in that pool, call `_load_depth_band_config()` instead of the `spawn_configs` lookup; keep existing `spawn_configs` path for all other room types (Elite, Boss, Start) in `scripts/dungeon/RoomSpawner.gd`
- [x] T009 Update `_resolve_wave_config()` in `RoomSpawner`: when `_config.wave_spawn_points` is non-empty, derive `waves` array as `[_config.wave_spawn_points[i].size() for i in range]` instead of using `tier.waves`; still read `trigger_threshold`, `alive_cap`, `min_spawn_distance` from the matching `DepthTierConfig` in `scripts/dungeon/RoomSpawner.gd`
- [x] T010 Update `_spawn_wave()` in `RoomSpawner`: when `_config.wave_spawn_points` is non-empty and `wave_idx < _config.wave_spawn_points.size()`, iterate `_config.wave_spawn_points[wave_idx]` directly (no cycling, no distance sort); for each slot call `sp.pick_enemy_id()` to resolve `enemy_type_id` before instantiating the enemy; fall through to existing legacy sorted flat-list path when `wave_spawn_points` is empty in `scripts/dungeon/RoomSpawner.gd`

**Checkpoint**: `SpawnPointData` supports weighted pools; `RoomSpawner` routes combat rooms through the band loader and resolves pools at spawn time. No band data in JSON yet — combat rooms will produce empty configs until US phases add bands.

---

## Phase 3: User Story 1 — Shallow Rooms (Priority: P1) 🎯 MVP

**Goal**: Depth-1 and depth-2 rooms spawn the correct enemy compositions as defined by bands 1 and 2.

**Independent Test**: Start a run; enter depth-1 rooms across multiple attempts — slots 1 and 2 always spawn `forest_tank`, slot 3 spawns `forest_disruptor` roughly 1-in-10 times. Enter depth-2 rooms — slot 4 is always `forest_disruptor`, slot 3 is roughly 50/50 between `forest_tank` and `forest_healer`.

- [x] T011 [US1] Add depth-band entries for depth 1 and depth 2 to the `depth_bands` array in `data/dungeon_config.json`:
  - Band 1: `min_depth: 1, max_depth: 1`, 1 wave with 3 slots — slot 1: `forest_tank 100%` at `(-350,-250)` r=40; slot 2: `forest_tank 100%` at `(350,-250)` r=40; slot 3: `forest_tank 90% / forest_disruptor 10%` at `(0,250)` r=40
  - Band 2: `min_depth: 2, max_depth: 2`, 1 wave with 4 slots — slot 1: `forest_tank 100%` at `(-350,-250)` r=40; slot 2: `forest_tank 100%` at `(350,-250)` r=40; slot 3: `forest_tank 50% / forest_healer 50%` at `(-150,250)` r=40; slot 4: `forest_disruptor 100%` at `(150,250)` r=40

**Checkpoint**: Depth-1 rooms spawn 3 enemies matching the 90/10 pool; depth-2 rooms spawn 4 enemies with correct slot compositions.

---

## Phase 4: User Story 2 — Mid-Depth Rooms (Priority: P2)

**Goal**: Depth 3–4 rooms spawn a two-wave encounter with correct fixed and pooled slots.

**Independent Test**: Enter depth-3 or depth-4 rooms. Wave 0 always produces exactly `forest_tank, forest_tank, forest_healer, forest_disruptor`. Wave 1 always has `forest_tank` in slot 1; over many runs slot 2 is `forest_tank` roughly 70% of the time with healer/poisoner/disruptor splitting the remaining 30%.

- [x] T012 [US2] Add depth-band entry for depths 3–4 to `depth_bands` in `data/dungeon_config.json`:
  - Band 3: `min_depth: 3, max_depth: 4`, 2 waves:
    - Wave 0 (4 slots): `forest_tank 100%` at `(-350,-250)` r=40; `forest_tank 100%` at `(350,-250)` r=40; `forest_healer 100%` at `(-150,250)` r=40; `forest_disruptor 100%` at `(150,250)` r=40
    - Wave 1 (2 slots): `forest_tank 100%` at `(-200,0)` r=40; pool `forest_tank 70% / forest_healer 10% / forest_poisoner 10% / forest_disruptor 10%` at `(200,0)` r=40

**Checkpoint**: Depth 3–4 rooms produce exactly 4 enemies in wave 0 and exactly 2 in wave 1; wave 1 slot 2 pool resolves correctly.

---

## Phase 5: User Story 3 — Deep Rooms (Priority: P3)

**Goal**: Depth 5+ rooms spawn a three-wave encounter; wave 2 is a single pooled slot.

**Independent Test**: Enter depth-5+ rooms. Wave 0: `forest_tank, forest_poisoner, forest_healer, forest_disruptor` always. Wave 1: matches depth 3–4 wave 1 exactly. Wave 2: exactly one enemy — `forest_tank` or `forest_poisoner` roughly 50/50.

- [x] T013 [US3] Add depth-band entry for depth 5+ to `depth_bands` in `data/dungeon_config.json`:
  - Band 4: `min_depth: 5, max_depth: -1`, 3 waves:
    - Wave 0 (4 slots): `forest_tank 100%` at `(-350,-250)` r=40; `forest_poisoner 100%` at `(350,-250)` r=40; `forest_healer 100%` at `(-150,250)` r=40; `forest_disruptor 100%` at `(150,250)` r=40
    - Wave 1 (2 slots): `forest_tank 100%` at `(-200,0)` r=40; pool `forest_tank 70% / forest_healer 10% / forest_poisoner 10% / forest_disruptor 10%` at `(200,0)` r=40
    - Wave 2 (1 slot): pool `forest_tank 50% / forest_poisoner 50%` at `(0,0)` r=40

**Checkpoint**: Depth 5+ rooms produce exactly 4 + 2 + 1 enemies across three waves; wave 2 always spawns exactly one enemy from the 50/50 pool.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T014 [P] Remove `ForestRoom01` (former CombatRoom01) entry from `spawn_configs` in `data/dungeon_config.json` if it still exists — combat rooms now use depth bands exclusively; keep `EliteRoom01`, `BossRoom01`, and `StartRoom01` entries unchanged
- [x] T015 [P] Update `repo_map.md` entries for `SpawnPointData` (new `enemy_pool` field, `pick_enemy_id()` method), `RoomSpawnConfig` (new `wave_spawn_points` field), and `RoomSpawner` (new `_load_depth_band_config()` method, updated `_load_config()` / `_resolve_wave_config()` / `_spawn_wave()`)

---

## Dependencies

```
T001 → T002                            (rename scene before updating pool string)

T003 → T004 → T005                     (SpawnPointData: field → method → tests)
T006                                   (RoomSpawnConfig: independent)

T003, T004, T006 → T007               (band loader needs both data models complete)
T007 → T008 → T009 → T010             (sequential in RoomSpawner.gd)

T010 → T011                           (spawner must use bands before band 1+2 data added)
T011 → T012                           (US1 bands must exist; band 3 is additive)
T012 → T013                           (US2 bands must exist; band 4 is additive)

T013 → T014, T015                     (polish after all bands added)
```

## Parallel Opportunities

**Phase 2:**
- T003 + T006 can run in parallel (different files)
- T005 can run in parallel with T006 (tests file vs data model file)

**Phase 6:**
- T014 + T015 can run in parallel (JSON vs markdown)

## Implementation Strategy

### MVP (Phase 1 + Phase 2 + Phase 3)

1. Editor rename (T001) + pool update (T002)
2. Data model extensions (T003–T006) + spawner changes (T007–T010)
3. Add depth 1 and 2 bands (T011)
4. **Validate**: depth-1 rooms show 3 enemies from correct pools; depth-2 shows 4 enemies.

### Full delivery (+ Phase 4 + Phase 5)

- T012 adds depth 3–4 two-wave encounter
- T013 adds depth 5+ three-wave encounter
- Each is independently observable by reaching the relevant depth

**Total tasks**: 15
- Phase 1 (Setup): 2 tasks
- Phase 2 (Foundational): 8 tasks
- Phase 3 (US1): 1 task
- Phase 4 (US2): 1 task
- Phase 5 (US3): 1 task
- Phase 6 (Polish): 2 tasks

**Parallel opportunities**: 4 tasks marked [P]
