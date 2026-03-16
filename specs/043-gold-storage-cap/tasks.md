# Tasks: Gold Offline Storage Cap (043)

**Input**: Design documents from `specs/043-gold-storage-cap/`
**Prerequisites**: spec.md ✅, plan.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Tasks grouped by user story. Foundational tasks block all stories.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies)
- **[Story]**: User story this task belongs to

---

## Phase 1: Setup

No project initialization required — feature extends an existing Godot project with no new tooling.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared data layer changes all three user stories depend on. Must complete before any story work begins.

**⚠️ CRITICAL**: US1 (cap enforcement), US2 (upgrades), and US3 (display) all require `gold_storage_cap_level` in MetaState and its persistence, plus the updated `apply_offline_gold()` signature.

- [x] T001 [P] Add `gold_storage_cap` entry under `alchemy_lab.upgrades` in `data/meta_config.json` with fields `name`, `base_hours: 4`, `hours_per_level: 4`, `base_cost: 100`, `cost_scale: 1.5`, `max_levels: 2`
- [x] T002 [P] Add `var gold_storage_cap_level: int = 0` to `scripts/data_models/MetaState.gd` (after `gold_generator_owned`)
- [x] T003 Add `"gold_storage_cap_level": state.gold_storage_cap_level` to `save_meta_state()` and `state.gold_storage_cap_level = int(parsed.get("gold_storage_cap_level", 0))` to `load_meta_state()` in `scripts/managers/SaveManager.gd` (depends on T002)

**Checkpoint**: MetaState has the field, it saves and loads correctly, config has the new upgrade entry. All stories can now begin.

---

## Phase 3: User Story 1 — Offline Gold Capped at Storage Limit (Priority: P1) 🎯 MVP

**Goal**: When a player has been offline longer than the storage cap (base: 4 hours), only the capped amount of gold is credited on game open. The offline timer resets to current time on every game open.

**Independent Test**: Set `gold_last_saved_timestamp` to 6 hours ago. Open game. Gold credited must equal exactly 4 hours of generation (not 6). Set timestamp to 2 hours ago — full 2 hours credited. Timer reset: close immediately and reopen after 5 hours → only 4h credited (timer measured from last open).

### Tests for User Story 1

- [x] T004 [P] [US1] Add unit tests for cap enforcement and timestamp reset to `tests/unit/test_meta_manager_impl_gold.gd`:
  - Update all existing `apply_offline_gold` calls to include new `cap_seconds` argument (use `14400` for all, preserving existing behaviour)
  - `test_apply_offline_gold_over_cap_is_clamped()` — 6h elapsed, 4h cap → only 4h gold
  - `test_apply_offline_gold_under_cap_not_clamped()` — 2h elapsed, 4h cap → full 2h gold
  - `test_apply_offline_gold_exactly_at_cap()` — 4h elapsed, 4h cap → exactly 4h gold
  - `test_apply_offline_gold_updates_timestamp_to_now()` — after credit, `gold_last_saved_timestamp == now_unix`
  - `test_apply_offline_gold_first_boot_sets_timestamp()` — timestamp=0, after call: gold=0, timestamp==now_unix
  - `test_apply_offline_gold_clock_rollback_no_timestamp_update()` — negative elapsed: gold=0, timestamp unchanged

### Implementation for User Story 1

- [x] T005 [P] [US1] Update `apply_offline_gold()` in `scripts/managers/MetaManager.gd` (MetaManagerImpl):
  - New signature: `apply_offline_gold(now_unix: int, rate_per_hour: float, cap_seconds: int, save_manager: Node) -> void`
  - First-boot branch (`timestamp == 0`): set `meta_state.gold_last_saved_timestamp = now_unix`, call `_save()`, return (no gold credit)
  - After elapsed > 0 guard: `var capped_elapsed: int = mini(elapsed, cap_seconds)`
  - Use `capped_elapsed` in gold calculation (not `elapsed`)
  - Add `meta_state.gold_last_saved_timestamp = now_unix` before `_save()` (do NOT update on clock-rollback path)

- [x] T006 [US1] Update `autoload/MetaManager.gd` `_ready()` to pass `cap_seconds` to `apply_offline_gold()` (depends on T005):
  - Read cap config: `var cap_cfg: Dictionary = ResourceManager.get_meta_config().get("alchemy_lab", {}).get("upgrades", {}).get("gold_storage_cap", {})`
  - Compute cap_seconds via `_impl.get_gold_storage_cap_seconds(cap_cfg.get("base_hours", 4), cap_cfg.get("hours_per_level", 4))`
  - Pass cap_seconds as third argument: `_impl.apply_offline_gold(int(Time.get_unix_time_from_system()), rate, cap_seconds, SaveManager)`
  - Note: `get_gold_storage_cap_seconds()` is implemented in T007

- [x] T007 [P] [US1] Add `get_gold_storage_cap_seconds(base_hours: int, hours_per_level: int) -> int` to `scripts/managers/MetaManager.gd` (MetaManagerImpl):
  - Returns `(base_hours + hours_per_level * meta_state.gold_storage_cap_level) * 3600`
  - Pure computation, no side effects

**Checkpoint**: Offline gold is now capped at 4h (base level). Timer resets on every game open. US1 fully functional.

---

## Phase 4: User Story 2 — Player Can Upgrade the Storage Cap (Priority: P2)

**Goal**: Player opens Alchemy Lab, sees a `Gold Storage` upgrade button, spends shards to increase the offline storage cap from 4h to 8h, then to 12h (max). At max level the button shows "MAX" and is disabled.

**Independent Test**: With ≥ 100 shards and Transmuter purchased — open Alchemy Lab, press Gold Storage button. Verify shards decrease by 100, button updates to show 8h → 12h (150 shards). Press again. Verify button shows "MAX" (disabled). Simulate 10h offline → 8h gold credited after first upgrade.

### Tests for User Story 2

- [x] T008 [P] [US2] Add unit tests for the new methods to `tests/unit/test_meta_manager_impl_gold.gd`:
  - `test_get_gold_storage_cap_seconds_level_0()` — base=4, per_level=4, level=0 → 14400
  - `test_get_gold_storage_cap_seconds_level_1()` — base=4, per_level=4, level=1 → 28800
  - `test_purchase_gold_storage_cap_success()` — sufficient shards: returns true, level incremented, shards deducted, save called
  - `test_purchase_gold_storage_cap_insufficient_shards()` — returns false, level unchanged, save NOT called
  - `test_purchase_gold_storage_cap_at_max_returns_false()` — at max_levels: returns false, save NOT called
  - `test_purchase_gold_storage_cap_idempotent_at_max()` — two calls with max_levels=1 → second returns false, only one deduction

### Implementation for User Story 2

- [x] T009 [P] [US2] Add `purchase_gold_storage_cap(cost: int, max_levels: int, save_manager: Node) -> bool` to `scripts/managers/MetaManager.gd` (MetaManagerImpl):
  - Pattern identical to `purchase_damage_upgrade()`: early-return if `meta_state.gold_storage_cap_level >= max_levels`; early-return if `not can_spend(cost)`; deduct shards, increment level, `_save()`, return true

- [x] T010 [US2] Add `purchase_gold_storage_cap() -> bool` delegation to `autoload/MetaManager.gd` (depends on T009):
  - Read cap config from `ResourceManager.get_meta_config()` path `alchemy_lab.upgrades.gold_storage_cap`
  - Compute cost via `_impl.get_upgrade_cost(meta_state.gold_storage_cap_level, cfg.base_cost, cfg.cost_scale)`
  - Delegate to `_impl.purchase_gold_storage_cap(cost, max_levels, SaveManager)`
  - Emit `shards_changed` on success

- [x] T011 [US2] Refactor `scenes/hub/LabUpgradeScreen.gd` to add the storage cap upgrade button: to add the storage cap upgrade button:
  - Add `@export var _storage_cap_button: Button`
  - In `_ready()`: `_storage_cap_button.pressed.connect(_on_storage_cap_pressed)`
  - Add `_update_storage_cap_button()` call inside `_update_buttons()` coordinator
  - Implement `_update_storage_cap_button()`: reads config name, base_hours, hours_per_level, base_cost, cost_scale, max_levels; if at max level → `"[name] — MAX"` (disabled); else → `"{name} {cur_h}h → {next_h}h ({cost} shards)"` (enabled/disabled by affordability via `MetaManager.can_spend(cost)`)
  - Implement `_on_storage_cap_pressed()` calling `MetaManager.purchase_gold_storage_cap()`

- [ ] T012 [US2] **[EDITOR]** Open `scenes/hub/LabUpgradeScreen.tscn` in Godot Editor: add a `Button` node named `StorageCapButton` as sibling of `TransmuterButton`; assign it to the `_storage_cap_button` export on `LabUpgradeScreen` via the Inspector (depends on T011)

**Checkpoint**: Open Alchemy Lab with ≥ 100 shards → Gold Storage button enabled → press it → shards decrease by 100 → button shows 8h → 12h → press again → button shows MAX. US2 fully functional.

---

## Phase 5: User Story 3 — Storage Cap Shown in Gold Display (Priority: P3)

**Goal**: The hub GoldDisplay shows the current storage cap hours when the Transmuter is owned, so players know the ceiling. The cap label updates immediately when an upgrade is purchased during the session.

**Independent Test**: Open hub with Transmuter owned — GoldDisplay shows "Cap: 4h". Purchase a storage upgrade — cap label changes to "Cap: 8h" without restarting. On a save without Transmuter — no cap label shown.

### Implementation for User Story 3

- [x] T013 [P] [US3] Update `scenes/hub/GoldDisplay.gd`
  - Add `@export var _cap_label: Label`
  - In `_ready()`: call `_update_cap_label()` immediately; connect `MetaManager.shards_changed` → `func(_n: int) -> void: _update_cap_label()`
  - Implement `_update_cap_label()`: if `MetaManager.is_gold_generator_owned` → `_cap_label.text = "Cap: {n}h".format({"n": MetaManager.gold_storage_cap_hours})`; else `_cap_label.text = ""`
  - Add `var gold_storage_cap_hours: int` computed property to `autoload/MetaManager.gd` if not yet present (delegates to `_impl.get_gold_storage_cap_seconds()` ÷ 3600, using config values)

- [ ] T014 [US3] **[EDITOR]** Open `scenes/hub/GoldDisplay.tscn` in Godot Editor: add a `Label` node named `CapLabel` as child of GoldDisplay root; assign it to the `_cap_label` export on `GoldDisplay` via the Inspector (depends on T013)

**Checkpoint**: Hub GoldDisplay shows "Cap: 4h" with base cap; updates to "Cap: 8h" after purchasing the first storage upgrade. US3 complete.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T015 Run manual verification steps from `specs/043-gold-storage-cap/quickstart.md` in full: base cap enforcement (6h, 2h, 4h cases), timer reset, upgrade purchase flow, max level display, affordability gate, display update, and data-driven config check (change `base_hours` to 8, verify UI and cap, revert)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: T001 and T002 are parallel; T003 depends on T002
- **US1 (Phase 3)**: Depends on T001, T002, T003; T004, T005, T007 are parallel; T006 depends on T005 and T007
- **US2 (Phase 4)**: Depends on T001, T002, T003; T008 and T009 are parallel; T010 depends on T009; T011 depends on T010; T012 is Editor task depending on T011
- **US3 (Phase 5)**: Depends on T007 (for `get_gold_storage_cap_seconds`) and T010 (for `gold_storage_cap_hours` property); T013 and T014 are sequential; T014 is Editor task
- **Polish (Phase 6)**: Depends on all phases complete

### User Story Dependencies

- **US1**: Requires T001, T002, T003 (foundational) + T005, T007 (impl) + T006 (autoload wiring)
- **US2**: Requires T001, T002, T003 + T007 (for cap seconds in upgrade context) + T009, T010, T011
- **US3**: Requires T007 (cap seconds computation) + T010 (autoload property); T013 can be written once T007+T010 exist

### Parallel Opportunities

- T001 + T002: parallel (different files)
- T004 + T005 + T007: parallel (tests vs impl methods — different concerns, same file can be done sequentially or split)
- T008 + T009: parallel (tests vs impl — write tests before impl for TDD)
- T013 can begin once T007 and T010 are done (parallel with T011/T012)

---

## Parallel Example: User Story 1

```text
After T003 completes:

Parallel batch:
  T004 — Write unit tests for cap enforcement + timestamp reset
  T005 — Update apply_offline_gold() with cap + timestamp
  T007 — Add get_gold_storage_cap_seconds()

Then sequentially:
  T006 — Update autoload _ready() to pass cap_seconds (depends on T005 + T007)
```

## Parallel Example: User Story 2

```text
After T003 completes (can overlap with US1 work):

Parallel batch:
  T008 — Write unit tests for get_gold_storage_cap_seconds + purchase_gold_storage_cap
  T009 — Implement purchase_gold_storage_cap() in MetaManagerImpl

Then sequentially:
  T010 — Add autoload delegation (depends on T009)
  T011 — Refactor LabUpgradeScreen.gd (depends on T010)
  T012 — [EDITOR] Add StorageCapButton to LabUpgradeScreen.tscn (depends on T011)
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 2: T001, T002, T003
2. Complete Phase 3: T004 → T005 + T007 → T006
3. **STOP and VALIDATE**: Gold correctly capped at 4h offline; timer resets on game open
4. Feature is correct and shippable at this point — upgrades and display are polish

### Incremental Delivery

1. Phase 2 (Foundational) → data layer ready
2. Phase 3 (US1) → cap enforcement live
3. Phase 4 (US2) → upgrades live (players can extend to 8h or 12h)
4. Phase 5 (US3) → cap visible in hub display
5. Phase 6 → manual QA pass

---

## Notes

- T012 and T014 are Editor tasks — cannot be automated; require Godot Editor open
- `apply_offline_gold()` signature change breaks all callers — T004 (tests) and T006 (autoload) must update their call sites to pass `cap_seconds`
- `tick_gold()` is intentionally untouched — in-session accumulation has no cap (FR-009)
- All config reads use `.get("key", fallback)` — missing config must not crash (edge case from quickstart.md)
- `get_upgrade_cost()` in MetaManagerImpl is already used by `purchase_damage_upgrade()`; `purchase_gold_storage_cap()` is the second call site (Constitution V ✅)
