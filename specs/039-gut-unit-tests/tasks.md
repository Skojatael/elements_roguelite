# Tasks: Unit Test Suite

**Input**: Design documents from `specs/039-gut-unit-tests/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Tasks grouped by user story. Two foundational source refactors unblock dungeon and boss-unlock stories; upgrade-cost and relic-deck stories have no blocking prerequisites.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Foundational (Source Refactors)

**Purpose**: Minimal source changes that make autoload-free testing possible. MUST be complete before US2/US3 and US5 test files are written.

**⚠️ CRITICAL**: US2, US3, and US5 test files depend on these refactors. US1 and US4 are unblocked and can start immediately.

- [x] T001 [P] Refactor `scripts/dungeon/DungeonGenerator.gd`: rename existing `_generate()` body to `_generate_with(config: Dictionary, gear_owned: bool) -> void`; update `_generate()` to a one-line shell: `_generate_with(ResourceManager.get_dungeon_config(), MetaManager.is_adventuring_gear_owned)`. Replace the two internal references — `var raw: Dictionary = ResourceManager.get_dungeon_config()` becomes the `config` parameter, and `MetaManager.is_adventuring_gear_owned` becomes the `gear_owned` parameter. No other logic changes.

- [x] T002 [P] Add static helper to `scenes/ui/hud/ExplorationHUD.gd`: `static func is_boss_available(cleared_count: int, required: int) -> bool: return cleared_count >= required`. Update `_on_room_cleared_for_boss()` to use it: replace `if RunManager.cleared_rooms.size() < threshold: return` with `if not ExplorationHUD.is_boss_available(RunManager.cleared_rooms.size(), threshold): return`. No other logic changes.

**Checkpoint**: T001 and T002 are independent ([P]) — run them together. After both complete, all five user stories can be implemented.

---

## Phase 2: User Story 1 — Upgrade Cost Formula (Priority: P1) 🎯 MVP

**Goal**: Verify `MetaManagerImpl.get_upgrade_cost` produces the full documented cost table for levels 0–9.

**Independent Test**: Load `scripts/managers/MetaManager.gd` without any autoloads, run GUT — all test functions in `test_upgrade_cost.gd` pass.

- [x] T003 [US1] Create `tests/unit/test_upgrade_cost.gd` with the following content:
  - `extends GutTest`
  - `const MetaManagerImpl = preload("res://scripts/managers/MetaManager.gd")`
  - `var _impl: MetaManagerImpl`
  - `func before_each(): _impl = MetaManagerImpl.new()`
  - `func test_cost_at_level_0_equals_base()`: assert `_impl.get_upgrade_cost(0, 50, 1.2) == 50`
  - `func test_cost_at_level_1()`: assert result is `60`
  - `func test_cost_at_level_2()`: assert result is `72`
  - `func test_cost_levels_3_through_9()`: loop over `[[3,86],[4,103],[5,123],[6,147],[7,176],[8,211],[9,253]]`, assert each pair
  - `func test_cost_at_level_0_any_base()`: assert `_impl.get_upgrade_cost(0, 100, 1.2) == 100`
  - `func test_cost_zero_base_always_zero()`: assert `_impl.get_upgrade_cost(5, 0, 1.2) == 0`

**Checkpoint**: Run GUT on this file alone. 7 test functions, 0 failures.

---

## Phase 3: User Stories 2 & 3 — Dungeon Generation (Priority: P1)

**Goal**: Verify every generated layout is fully connected and contains exactly the configured room count.

**Dependency**: Requires T001 (DungeonGenerator refactor).

**Independent Test**: Add `DungeonGenerator` as child node in GUT, call `_generate_with(STUB_CONFIG, false)`, inspect `rooms_by_id` and `neighbours_by_id` — all test functions pass.

- [x] T004 [US2] [US3] Create `tests/unit/test_dungeon_generation.gd` with the following content:
  - `extends GutTest`
  - `const DungeonGeneratorClass = preload("res://scripts/dungeon/DungeonGenerator.gd")`
  - Stub constant: `const STUB_CONFIG: Dictionary = { "combat_room_pool": ["CombatRoom01", "CombatRoom02"], "base_room_count": 9, "difficulty_scale": 0.12, "expansion_room_count": 4 }`
  - Private BFS helper `func _all_reachable(gen: DungeonGenerator) -> bool`: initialise `visited: Dictionary = {}` and `queue: Array = [gen.start_room_id]`; while queue not empty, pop, skip if visited, mark visited, push all entries from `gen.neighbours_by_id.get(id, [])`; return `visited.size() == gen.rooms_by_id.size()`
  - `func test_room_count_base()`: `add_child_autofree` a new `DungeonGeneratorClass`, call `_generate_with(STUB_CONFIG, false)`, assert `rooms_by_id.size() == 9`
  - `func test_start_room_always_in_rooms_by_id()`: same setup, assert `gen.rooms_by_id.has(gen.start_room_id)`
  - `func test_connectivity_run_1()` through `test_connectivity_run_5()`: five separate test functions (different seeds via `randomize()` before each), assert `_all_reachable(gen) == true`
  - `func test_neighbour_symmetry()`: for every `room_id` in `gen.neighbours_by_id`, for every neighbour `n` in the list, assert `gen.neighbours_by_id[n].has(room_id)`

**Checkpoint**: Run GUT on this file alone. 9 test functions, 0 failures.

---

## Phase 4: User Story 4 — Relic Deck (Priority: P2)

**Goal**: Verify no duplicate relics appear before a full deck pass, that `draw_offer()` never returns rare relics, and that `draw_boss_offer()` only returns rare relics.

**Independent Test**: Instantiate `RelicManagerImpl`, build pool with stub dicts, run all draw assertions — all test functions pass without any autoloads.

- [x] T005 [US4] Create `tests/unit/test_relic_deck.gd` with the following content:
  - `extends GutTest`
  - `const RelicManagerImpl = preload("res://scripts/managers/RelicManagerImpl.gd")`
  - Stub constants matching `data-model.md`:
    ```
    const STUB_RELICS: Dictionary = { "relics": { "common": { "relic_a": { "name": "A", "effect_stat": "attack_damage", "effect_mult": 1.10 }, "relic_b": { "name": "B", "effect_stat": "attack_speed", "effect_mult": 1.05 }, "relic_c": { "name": "C", "effect_stat": "move_speed", "effect_mult": 1.08 } }, "rare": { "relic_x": { "name": "X", "effect_stat": "attack_damage", "effect_mult": 1.25 }, "relic_y": { "name": "Y", "effect_stat": "max_health", "effect_mult": 1.30 } } } }
    const STUB_CFG: Dictionary = { "relic_tier_weights": { "common": 1.0 } }
    ```
  - `var _impl: RelicManagerImpl`
  - `func before_each(): _impl = RelicManagerImpl.new(); _impl.build_pool(STUB_RELICS, STUB_CFG)`
  - `func test_no_duplicates_single_pass()`: draw 3 relics via `_impl._draw_one()`, collect IDs into Array, assert `ids.size() == ids.filter(func(i): return ids.count(i) == 1).size()` (all unique)
  - `func test_reshuffle_restores_full_deck()`: draw 3 (exhausts deck), draw 3 more, collect second-pass IDs, assert all 3 unique in second pass
  - `func test_draw_offer_pair_distinct()`: loop 10 times, call `_impl.draw_offer()`, rebuild pool before each call, assert `offer[0].id != offer[1].id`
  - `func test_draw_offer_never_returns_rare()`: call `_impl.draw_offer()` 20 times (rebuilding pool between each), assert neither relic in any offer has `tier == "rare"`
  - `func test_boss_offer_only_rare()`: call `_impl.draw_boss_offer()`, assert result is not empty and every entry has `tier == "rare"`
  - `func test_boss_offer_excludes_held_relic()`: call `_impl.pick_relic("relic_x")`, call `draw_boss_offer()`, assert no entry in result has `id == "relic_x"`
  - `func test_boss_offer_empty_when_all_rares_held()`: pick both `relic_x` and `relic_y`, call `draw_boss_offer()`, assert result is empty

**Checkpoint**: Run GUT on this file alone. 7 test functions, 0 failures.

---

## Phase 5: User Story 5 — Boss Teleport Unlock Threshold (Priority: P2)

**Goal**: Verify the boss availability threshold condition is correct at and around the boundary.

**Dependency**: Requires T002 (ExplorationHUD static helper).

**Independent Test**: Preload `ExplorationHUD.gd` script, call `ExplorationHUD.is_boss_available()` — no scene, no autoload needed.

- [x] T006 [US5] Create `tests/unit/test_boss_unlock.gd` with the following content:
  - `extends GutTest`
  - `const ExplorationHUD = preload("res://scenes/ui/hud/ExplorationHUD.gd")`
  - `func test_unavailable_below_threshold()`: assert `ExplorationHUD.is_boss_available(5, 6) == false`
  - `func test_available_at_exact_threshold()`: assert `ExplorationHUD.is_boss_available(6, 6) == true`
  - `func test_available_above_threshold()`: assert `ExplorationHUD.is_boss_available(10, 6) == true`
  - `func test_unavailable_at_zero_cleared()`: assert `ExplorationHUD.is_boss_available(0, 6) == false`
  - `func test_available_when_threshold_is_zero()`: assert `ExplorationHUD.is_boss_available(0, 0) == true`

**Checkpoint**: Run GUT on this file alone. 5 test functions, 0 failures.

---

## Phase 6: Polish & Validation

**Purpose**: Full suite run and documentation.

- [ ] T007 Run all tests via GUT panel (manual — editor step) (Run All) and confirm: 0 failures, 0 errors across all 5 files including the existing `test_shard_conversion.gd`
- [ ] T008 [P] Update `specs/039-gut-unit-tests/quickstart.md` if actual test function names or output differ from the expected output section

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: No dependencies — start immediately. T001 and T002 are independent ([P]).
- **Phase 2 (US1)**: No dependency on Phase 1 — can start immediately in parallel with Phase 1.
- **Phase 3 (US2+US3)**: Depends on T001 only.
- **Phase 4 (US4)**: No dependency on Phase 1 — can start immediately in parallel with Phase 1.
- **Phase 5 (US5)**: Depends on T002 only.
- **Phase 6 (Polish)**: Depends on T003–T006 all complete.

### User Story Dependencies

- **US1** (T003): Independent — no source refactor needed. Start immediately.
- **US2+US3** (T004): Depends on T001 (DungeonGenerator refactor).
- **US4** (T005): Independent — no source refactor needed. Start immediately.
- **US5** (T006): Depends on T002 (ExplorationHUD static helper).

### Parallel Opportunities

- T001 + T002 + T003 + T005 can all run simultaneously on day one.
- T004 unblocks as soon as T001 is done.
- T006 unblocks as soon as T002 is done.

---

## Parallel Example: Day-One Batch

```
Simultaneous:
  T001 — DungeonGenerator refactor         (scripts/dungeon/DungeonGenerator.gd)
  T002 — ExplorationHUD static helper      (scenes/ui/hud/ExplorationHUD.gd)
  T003 — test_upgrade_cost.gd              (tests/unit/)
  T005 — test_relic_deck.gd                (tests/unit/)

After T001 completes:
  T004 — test_dungeon_generation.gd        (tests/unit/)

After T002 completes:
  T006 — test_boss_unlock.gd               (tests/unit/)

After T003–T006 all complete:
  T007 — Full suite run
  T008 — Update quickstart if needed
```

---

## Implementation Strategy

### MVP First (US1 only)

1. Write T003 (`test_upgrade_cost.gd`) — zero source changes needed
2. Run GUT, confirm 7 functions pass
3. **STOP and VALIDATE** — cost formula is verified

### Full Delivery

1. T001 + T002 + T003 + T005 in parallel
2. T004 (after T001), T006 (after T002)
3. T007 full suite run

---

## Notes

- [P] tasks touch different files — no conflicts when run in parallel
- Tests are the implementation for this feature — each task IS the deliverable
- Stub data is defined in `data-model.md` — copy from there verbatim
- `_draw_one()` is a private method on `RelicManagerImpl`; GDScript does not enforce private access, so tests may call it directly
- `DungeonGenerator` extends `Node` — use `add_child_autofree(gen)` in dungeon tests so GUT manages lifetime
