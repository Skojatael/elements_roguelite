# Tasks: Dungeon Expansion (Adventuring Gear)

**Input**: Design documents from `/specs/033-dungeon-expansion/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/interfaces.md ✅ quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks in the same phase)
- **[Story]**: Which user story this task belongs to
- Exact file paths are included in all descriptions

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Data files, MetaState fields, and persistence — MUST complete before any user story.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 [P] Add `"adventuring_gear_cost": 300` to `data/meta_config.json`
- [x] T002 [P] Add `"base_room_count": 9` and `"expansion_room_count": 4` to `data/dungeon_config.json`
- [x] T003 [P] Add `first_boss_killed: bool = false` and `adventuring_gear_owned: bool = false` fields to `scripts/data_models/MetaState.gd`
- [x] T004 Serialize and deserialize `first_boss_killed` and `adventuring_gear_owned` in `scripts/managers/SaveManagerImpl.gd` (depends on T003)

**Checkpoint**: Data layer complete — user story implementation can begin.

---

## Phase 2: User Story 1 — First Boss Kill Detection (Priority: P1) 🎯 MVP

**Goal**: Record a permanent flag on the player's first boss kill and expose it through MetaManager so the hub UI can react.

**Independent Test**: Start a boss run via DevPanel → kill boss → cash out → return to hub. Confirm `MetaManager.is_first_boss_killed` is `true` in output (or via print). Relaunch → confirm flag persists. On a fresh save → confirm flag is `false`.

- [x] T005 [US1] Add `record_boss_kill(save_manager: Node) -> bool` to `scripts/managers/MetaManagerImpl.gd` — returns `false` if already set, sets `first_boss_killed = true`, saves, returns `true`
- [x] T006 [US1] Add `is_first_boss_killed: bool` computed property and boss-kill branch to `_on_room_cleared()` in `autoload/MetaManager.gd` — early return after `record_boss_kill()` call (depends on T005)

**Checkpoint**: After T006, `MetaManager.is_first_boss_killed` returns correct value and persists across sessions. Adventuring Gear UI not yet visible.

---

## Phase 3: User Story 2 — Adventuring Gear Purchase (Priority: P2)

**Goal**: Show a hub button when the boss has been killed and gear is not yet owned. Allow purchase for 300 shards. Button does nothing if balance is insufficient.

**Independent Test**: With `first_boss_killed = true` and ≥ 300 shards → tap button → balance decreases by 300 → button disappears. With < 300 shards → tap button → nothing happens. Relaunch → button still absent after purchase.

- [x] T007 [US2] Add `purchase_adventuring_gear(cost: int, save_manager: Node) -> bool` to `scripts/managers/MetaManagerImpl.gd` — checks `can_spend(cost)`, deducts, sets `adventuring_gear_owned = true`, saves (depends on T004)
- [x] T008 [US2] Add `is_adventuring_gear_owned: bool` computed property and `purchase_adventuring_gear() -> bool` method to `autoload/MetaManager.gd` — reads cost from `ResourceManager.get_meta_config()`, delegates to `_impl`, emits `shards_changed` on success (depends on T007)
- [x] T009 [US2] Create `scenes/hub/AdventuringGearShop.gd` — `class_name AdventuringGearShop extends Control`; `@export var _button: Button`; connects button pressed + `MetaManager.shards_changed`; `_update_visibility()` sets `visible = is_first_boss_killed and not is_adventuring_gear_owned`; `_on_buy_pressed()` calls `MetaManager.purchase_adventuring_gear()` then `_update_visibility()` (depends on T008)
- [ ] T010 [US2] **EDITOR TASK** — Create `scenes/hub/AdventuringGearShop.tscn` in Godot Editor: `Control` root with script `AdventuringGearShop.gd`; `Button` child named `BuyButton` with text `"Adventuring Gear — 300 shards"` (never disabled); assign `BuyButton` to `_button` export in Inspector; add `AdventuringGearShop` as child of `HubRoom.tscn` (depends on T009)

**Checkpoint**: After T010, the full purchase flow is testable end-to-end (quickstart scenarios 1–5).

---

## Phase 4: User Story 3 — Expanded Dungeon in All Runs (Priority: P3)

**Goal**: When Adventuring Gear is owned, every run generates 13 rooms (9 base + 4 expansion). Grid enlarged to 11×11 to guarantee 4 rooms always fit. Expansion rooms are strictly deeper than Room A.

**Independent Test**: With gear owned, start a run → output log shows `rooms=13` and `expansion seed=room_X_Y max_depth=N rooms_added=4`. Without gear → log shows `rooms=9`.

- [x] T011 [US3] Update constants in `scripts/dungeon/DungeonGenerator.gd`: change `GRID_SIZE` from `5` to `13`, `CENTER` from `Vector2i(2, 2)` to `Vector2i(6, 6)`, remove `TARGET_ROOM_COUNT` const, read room count from `ResourceManager.get_dungeon_config().get("base_room_count", 9)` as a local var in `_generate()` (depends on T002)
- [x] T012 [US3] Add `_get_expansion_neighbours()` and `_expand_dungeon()` methods to `scripts/dungeon/DungeonGenerator.gd`; update `_generate()` to conditionally call `_expand_dungeon()` when `MetaManager.is_adventuring_gear_owned` and move `_promote_elite_rooms()` call to after expansion (covers all rooms); rebuild neighbours after expansion (depends on T011)

**Checkpoint**: After T012, full feature is complete. Quickstart scenarios 6–10 are testable.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T013 [P] Update `CLAUDE.md` — change DungeonGenerator section: `GRID_SIZE` 5→13, `CENTER` (2,2)→(6,6), start room `"room_6_6"`, depth formula `|col−6|+|row−6|`, `base_room_count` read from config; add Adventuring Gear entry to Meta Progression section; add dungeon expansion note to Dungeon generation section
- [ ] T014 Run all 10 scenarios in `specs/033-dungeon-expansion/quickstart.md` to validate the complete feature

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately; T001/T002/T003 are parallel, T004 depends on T003
- **US1 (Phase 2)**: Depends on Phase 1 (T005 needs MetaState fields from T003/T004; T006 depends on T005)
- **US2 (Phase 3)**: Depends on Phase 2 completion (T007–T010 sequential; T007 touches MetaManagerImpl.gd after T005 is done)
- **US3 (Phase 4)**: Depends on Phase 1 (T002) and Phase 2 (T006 exposes `is_adventuring_gear_owned`); T011→T012 sequential
- **Polish (Phase 5)**: Depends on all story phases; T013 [P] with T014 (different concerns)

### User Story Dependencies

- **US1**: Depends only on Foundational. No dependency on US2 or US3.
- **US2**: Depends on US1 (MetaManager.is_first_boss_killed used in AdventuringGearShop visibility). Cannot be tested without US1.
- **US3**: Depends on US1/US2 (reads `MetaManager.is_adventuring_gear_owned`). The grid change (T011) can be done independently of US1/US2.

### Parallel Opportunities

- Phase 1: T001, T002, T003 can run in parallel (separate files)
- Phase 5: T013 can run alongside T014 (separate concerns)
- T011 (grid constants) can be done immediately after T002, independent of US1/US2 logic

---

## Parallel Example: Phase 1

```gdscript
# Three files touched simultaneously:
# T001 → data/meta_config.json
# T002 → data/dungeon_config.json
# T003 → scripts/data_models/MetaState.gd

# Then:
# T004 → scripts/managers/SaveManagerImpl.gd  (needs T003 done first)
```

---

## Implementation Strategy

### MVP: User Story 1 Only

1. Complete Phase 1 (Foundational) — data + MetaState + persistence
2. Complete Phase 2 (US1) — boss kill flag + MetaManager property
3. **STOP and VALIDATE**: `is_first_boss_killed` persists across sessions. Hub logic can react to it.

### Incremental Delivery

1. Phase 1 + Phase 2 (US1) → Boss kill flag works. Hub can read it.
2. Phase 3 (US2) → Purchase flow works end-to-end. Button appears, deducts shards, disappears.
3. Phase 4 (US3) → Dungeon expansion works. 13-room runs when gear owned.
4. Each phase is testable independently before moving on.

---

## Notes

- T010 is an **editor task** — must be done in Godot Editor, not via script edits.
- T011 and T012 both modify `DungeonGenerator.gd` — run sequentially.
- `_promote_elite_rooms()` is moved (not duplicated) — it runs exactly once, after expansion.
- Base room count change: `TARGET_ROOM_COUNT` const removed in T011; `base_room_count: 9` read from `dungeon_config.json`.
- Grid proof: with 9 base rooms (8 steps from center), max reachable depth = 8. Expansion cells are at depth ≥ 9. The 13×13 grid guarantees ≥ 4 valid cells (via chaining) at all reachable depth-8 positions. 11×11 is insufficient — worst-case Room A at (0,2) in 11×11 yields only 3 reachable expansion cells (see research.md).
