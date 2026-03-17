# Tasks: Gold-Purchased Essence Gain Upgrade

**Input**: Design documents from `/specs/044-gold-essence-upgrade/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Config update that all subsequent tasks depend on.

- [X] T001 Update `data/meta_config.json` — in `alchemy_lab.upgrades.essence_gain`: replace `"base_cost": 0, "max_levels": 1` with `"costs": [50, 100, 150, 200, 250], "max_levels": 5`; keep `"essence_per_level": 0.05` unchanged

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Impl and autoload changes that US1, US2, and US3 all depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 [P] Write GUT unit tests for `MetaManagerImpl` additions in `tests/unit/test_meta_manager_impl.gd` — cover: `can_spend_gold()` (true when balance ≥ cost; false when below; false for negative cost), `spend_gold()` (deducts on success; rejects insufficient balance; rejects negative cost), `purchase_essence_gain()` (increments level on success; returns false at max level 5; returns false when gold insufficient; total_gold correctly reduced), `get_essence_gain_multiplier()` (returns 1.0 at level 0; returns exactly pow(1.05, 1) at level 1; returns exactly pow(1.05, 5) at level 5) — use inline MetaState dict stubs, no autoloads
- [X] T003 Fix `get_essence_gain_multiplier(essence_per_level)` in `scripts/managers/MetaManagerImpl.gd` — change body from `return 1.0 + meta_state.essence_gain_level * essence_per_level` to `return pow(1.0 + essence_per_level, meta_state.essence_gain_level)`; then add `can_spend_gold(cost: float) -> bool`, `spend_gold(cost: float, save_manager: Node) -> bool`, and `purchase_essence_gain(costs: Array, max_levels: int, save_manager: Node) -> bool` per data-model.md — all new methods use early-return guard clauses
- [X] T004 Expose new wrappers in `autoload/MetaManager.gd` — add `can_spend_gold(cost: float) -> bool` (delegates to `_impl`), `spend_gold(cost: float) -> bool` (delegates, emits `gold_changed` on success), `get_next_essence_gain_cost() -> int` (reads `alchemy_lab.upgrades.essence_gain.costs[essence_gain_level]` from config; returns 0 if maxed), `purchase_essence_gain() -> bool` (reads costs+max_levels from config, delegates to `_impl`, emits `gold_changed` on success)

**Checkpoint**: Foundation ready — GUT tests should pass, MetaManager exposes all new methods.

---

## Phase 3: User Story 1 — Purchase Essence Gain Upgrade with Gold (Priority: P1) 🎯 MVP

**Goal**: The Alchemy Lab upgrade screen's Essence Gain button is enabled when the player can afford the current level cost in gold, shows the correct gold cost, and purchasing deducts gold and increments the level.

**Independent Test**: Open Alchemy Lab with ≥ 50 gold → button enabled and shows "50 gold" cost → purchase → gold deducted, level becomes 1, button now shows "100 gold". With < 50 gold → button disabled.

- [X] T005 [US1] Update `_update_essence_button()` in `scenes/hub/LabUpgradeScreen.gd` — read `costs` array from config (`alchemy_lab.upgrades.essence_gain.costs`); at max level show "Essence Gain — MAX" and disable; otherwise read `cost = costs[level]`, compute `pct = roundi(pow(1.0 + essence_per_level, level + 1) * 100.0) - 100`, set button text to `"Essence Gain +{pct}% (Lv{lv}) — {cost} gold"`, disable if `not MetaManager.can_spend_gold(float(cost))`
- [X] T006 [US1] Connect `MetaManager.gold_changed` signal in `scenes/hub/LabUpgradeScreen.gd` `_ready()` — add `MetaManager.gold_changed.connect(func(_n: int) -> void: _update_buttons())` so the button re-evaluates affordability when gold ticks
- [X] T007 [US1] Wire `_essence_button.pressed` to `MetaManager.purchase_essence_gain()` in `scenes/hub/LabUpgradeScreen.gd` — replace any existing no-op handler with `func _on_essence_pressed() -> void: MetaManager.purchase_essence_gain(); _update_buttons()`; ensure the button's pressed signal is connected to this method (not a previously disabled stub)

**Checkpoint**: User Story 1 fully functional. Buying cycles through all 5 levels, gold deducts correctly, button disables at MAX.

---

## Phase 4: User Story 2 — Essence Gain Multiplier Applied During Runs (Priority: P2)

**Goal**: Confirm that the compounding multiplier (fixed in T003) propagates correctly to in-run essence rewards.

**Independent Test**: Set `essence_gain_level = 3` in DevPanel / save file, start a run, kill a slime at depth 1 → essence = `floor(10 × 1.0 × pow(1.05, 3))` = `floor(11.576)` = 11.

- [ ] T008 [US2] Validate essence rewards in-game at each upgrade level — using DevPanel or save-file edit, test levels 0, 1, 3, and 5; for each level kill a known enemy at a known depth and confirm essence awarded matches `floor(base × depth_mult × pow(1.05, level))` within ±1 rounding; no code changes expected — this is a validation-only task to confirm T003's formula fix is end-to-end correct

**Checkpoint**: User Story 2 confirmed. Compounding formula verified live.

---

## Phase 5: User Story 3 — Persistent Upgrade Level Across Sessions (Priority: P3)

**Goal**: Confirm the upgrade level and reduced gold balance survive a game restart.

**Independent Test**: Purchase level 2 (costs 50 + 100 = 150 gold total), close the game process, reopen → Alchemy Lab shows level 2, next cost = 150 gold, gold balance reflects both deductions.

- [ ] T009 [US3] Validate persistence across restart — purchase one or more levels, note the resulting gold balance and upgrade level, fully close and reopen the game, open the Alchemy Lab upgrade screen and confirm displayed level and gold match pre-close values; no code changes expected — the existing save system already handles this; task confirms no regression

**Checkpoint**: All three user stories validated.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T010 Run all quickstart.md validation scenarios end-to-end — follow each step in `specs/044-gold-essence-upgrade/quickstart.md` in order; confirm all 6 bullet-point scenarios pass; verify GUT test suite still passes after all changes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on T001 (config must exist before impl reads it) — blocks all user stories
- **Phase 3 (US1)**: Depends on Phase 2 complete (needs `purchase_essence_gain` on MetaManager)
- **Phase 4 (US2)**: Depends on T003 (formula fix) — can validate once T003 is done
- **Phase 5 (US3)**: Depends on Phase 3 (needs a purchasable upgrade to test persistence)
- **Phase 6 (Polish)**: Depends on all prior phases complete

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 — no dependency on US2 or US3
- **US2 (P2)**: Depends on T003 only (formula fix in Phase 2)
- **US3 (P3)**: Depends on US1 being functional (needs a real purchase to persist)

### Within Phase 2

- T002 [P] and T001 can run in parallel (different files)
- T003 depends on T001 (reads config structure for constants reference)
- T004 depends on T003 (wraps the new impl methods)

---

## Parallel Opportunities

```text
# Phase 2 parallel start:
T001 (config)    ─┐
T002 (tests)     ─┘ → T003 (impl) → T004 (autoload) → Phase 3

# Phase 3 sequential (same file, LabUpgradeScreen.gd):
T005 → T006 → T007
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. T001 — Config
2. T002, T003, T004 — Foundational (Phase 2)
3. T005, T006, T007 — US1 UI wiring
4. **STOP and VALIDATE**: Purchase flow works end-to-end with gold deduction

### Incremental Delivery

1. Phase 1 + 2 → Backend ready (purchase API exists, multiplier fixed)
2. Phase 3 → US1 purchasable in UI → playable MVP
3. Phase 4 → US2 confirmed (formula already live, just validation)
4. Phase 5 → US3 confirmed (persistence already live, just validation)

---

## Notes

- Total tasks: **10**
- Tasks per user story: US1=3, US2=1, US3=1
- Parallel opportunities: T001 ∥ T002 (Phase 2 start)
- No new files — all tasks modify existing files
- MVP scope: T001 → T002 → T003 → T004 → T005 → T006 → T007 (7 tasks for a fully purchasable upgrade)
- GUT test task (T002) is MANDATORY per constitution rules — `MetaManagerImpl.gd` is a `scripts/managers/` file with new testable logic
