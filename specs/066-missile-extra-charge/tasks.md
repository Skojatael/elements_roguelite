# Tasks: Magic Forge — Missile Extra Charge Upgrade

**Input**: Design documents from `specs/066-missile-extra-charge/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

*No project initialization required — this feature extends an existing codebase.*

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data layer and persistence must exist before any user story can be implemented or tested.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 Extend `data/meta_config.json` — add `missile_charge_upgrade: {name: "Arcane Reservoir", cost: 150}` under `magic_forge.upgrades`
- [x] T002 Add `var missile_extra_charge_owned: bool = false` to `scripts/data_models/MetaState.gd`
- [x] T003 [P] Update `scripts/managers/SaveManagerImpl.gd` — add `"missile_extra_charge_owned"` key to `save_meta_state()` dict and `state.missile_extra_charge_owned = bool(data.get("missile_extra_charge_owned", false))` in `load_meta_state()`

**Checkpoint**: Foundation ready — MetaState has the field, JSON has the config, save/load is wired.

---

## Phase 3: User Story 1 — Purchase Extra Charge Upgrade (Priority: P1) 🎯 MVP

**Goal**: Player can open the Magic Forge screen, see the Arcane Reservoir upgrade, purchase it with shards, and see it marked as owned.

**Independent Test**: Open the Forge screen with ≥150 shards → tap the new button → shards deducted by 150, button shows "Purchased" and is disabled. Re-open screen → still shows Purchased.

### Tests for User Story 1

> **Write these tests FIRST — verify they FAIL before implementation of T005.**

- [x] T004 [P] [US1] Create `tests/unit/test_meta_manager_impl_missile_charge.gd` — GUT tests for `MetaManagerImpl.purchase_missile_extra_charge()` covering: success path deducts cost and sets flag; returns false when already owned; returns false when insufficient shards; save called on success; save NOT called on failure. Use inline `MetaState` and `StubSaveManager` (no autoloads). Pattern: see `tests/unit/test_meta_manager_impl_gold.gd`.

### Implementation for User Story 1

- [x] T005 [US1] Add `purchase_missile_extra_charge(cost: int, save_manager: Node) -> bool` to `scripts/managers/MetaManagerImpl.gd` — early-return guards: owned → false; can't afford → false; deduct cost, set flag, save, return true
- [x] T006 [US1] Add `var is_missile_extra_charge_owned: bool` computed property (delegates to `_impl.meta_state.missile_extra_charge_owned`) and `purchase_missile_extra_charge() -> bool` method (reads cost from `meta_config.json`, delegates to `_impl`, emits `shards_changed` on success) to `autoload/MetaManager.gd`
- [x] T007 [US1] Update `scenes/hub/ForgeUpgradeScreen.gd` — add `@export var _missile_charge_button: Button`; in `_ready()` connect `_missile_charge_button.pressed` to `_on_missile_charge_button_pressed()`; extend `_update_buttons()` with missile charge button logic (owned → "Purchased"/disabled; can afford → "{name} — {cost} shards"/enabled; can't afford → same label + " (insufficient)"/disabled); add `_on_missile_charge_button_pressed()` handler that calls `MetaManager.purchase_missile_extra_charge()` then `_update_buttons()`
- [ ] T008 [US1] **EDITOR TASK** — open `scenes/hub/ForgeUpgradeScreen.tscn` in Godot Editor; add a `Button` child node named `MissileChargeButton` below the existing damage upgrade button; in the Inspector for the `ForgeUpgradeScreen` root, assign `MissileChargeButton` to the `_missile_charge_button` export slot; save the scene

**Checkpoint**: US1 fully testable — purchase flow works end-to-end in the Forge screen.

---

## Phase 4: User Story 2 — Extra Charge Active During a Run (Priority: P1)

**Goal**: When the upgrade is owned, Magic Missile's `_max_charges` is base + 1 at run start; the HUD pip count reflects this; the extra charge fires and reloads normally.

**Independent Test**: Own the upgrade → start a run → Magic Missile HUD shows 4 pips (not 3) → fire all 4 → hit enemy with melee → charges refill to 4.

### Implementation for User Story 2

- [x] T009 [US2] Modify `scenes/player/components/SkillComponent.gd` — in `_load_skill_data()`, immediately after `_max_charges = int((entry as Dictionary).get("max_charges", 3))` and before `_current_charges = _max_charges`, add: `if MetaManager.is_missile_extra_charge_owned: _max_charges += 1`

**Checkpoint**: US2 fully testable — run with upgrade owned shows 4 pips; run without shows 3.

---

## Phase 5: User Story 3 — Upgrade Persists Across Sessions (Priority: P2)

**Goal**: The owned flag survives a full game quit-and-relaunch cycle.

**Independent Test**: Purchase upgrade → quit game → relaunch → open Forge screen → shows "Purchased"; start run → 4 pips.

*Note: Save/load wiring was completed in Phase 2 (T003). This phase has no new code tasks — persistence is already fully covered. Validation is the only remaining step.*

- [ ] T010 [US3] **VALIDATION** — purchase the upgrade in-game, force-quit the process, relaunch, open Forge screen: confirm it shows "Purchased". Start a run: confirm Magic Missile has 4 pips.

**Checkpoint**: All three user stories complete and independently verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T011 Run the GUT test suite (`tests/unit/test_meta_manager_impl_missile_charge.gd`) and confirm all cases pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately
- **US1 (Phase 3)**: Requires Phase 2 complete (T001, T002, T003)
- **US2 (Phase 4)**: Requires T002 (MetaState field) and T006 (MetaManager property); can start in parallel with T007/T008 once T006 is done
- **US3 (Phase 5)**: Requires Phase 2 complete + US1 complete (purchase flow working) + US2 complete (run effect working)
- **Polish (Phase 6)**: Requires T004 written and T005 implemented

### Within Phase 3 (US1)

- T004 (unit test skeleton) — write first, verify it fails
- T005 (MetaManagerImpl) — implement to make T004 pass
- T006 (MetaManager autoload) — depends on T005
- T007 (ForgeUpgradeScreen.gd) — depends on T006
- T008 (Editor scene) — depends on T007 being written

### Parallel Opportunities

- T003 (SaveManagerImpl) can be written in parallel with T002 (MetaState)
- T004 (unit test) can be written in parallel with T005 (implementation)

---

## Parallel Example: User Story 1

```
# Write simultaneously:
T004: tests/unit/test_meta_manager_impl_missile_charge.gd  (test skeleton)
T005: scripts/managers/MetaManagerImpl.gd                   (purchase method)

# Then sequentially:
T006: autoload/MetaManager.gd                               (delegates to impl)
T007: scenes/hub/ForgeUpgradeScreen.gd                      (UI logic)
T008: scenes/hub/ForgeUpgradeScreen.tscn  [EDITOR]          (button node)
```

---

## Implementation Strategy

### MVP First (User Stories 1 + 2 only)

1. Complete Phase 2: Foundational (T001–T003)
2. Complete Phase 3: US1 purchase flow (T004–T008)
3. Complete Phase 4: US2 in-run effect (T009)
4. **STOP and VALIDATE**: Fire Magic Missile 4 times in a run after purchasing upgrade
5. Phase 5/6 are confirmatory only

### Incremental Delivery

1. T001–T003 → data layer ready
2. T004–T008 → purchase flow complete and testable
3. T009 → in-run effect live
4. T010 → persistence confirmed
5. T011 → unit tests green

---

## Notes

- [P] tasks = different files, no mutual dependencies
- [Story] label maps each task to its user story for traceability
- All `.tscn` changes MUST be made in the Godot Editor (T008)
- Constitution II: all balance values (cost, name) live in `meta_config.json`, not in GDScript constants
- Constitution VI: `purchase_missile_extra_charge()` uses early-return guards, no deep nesting
