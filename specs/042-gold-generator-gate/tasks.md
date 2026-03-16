# Tasks: Gold Generator Gate (Transmuter)

**Input**: Design documents from `specs/042-gold-generator-gate/`
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

**Purpose**: Shared data layer changes that all three user stories depend on. Must complete before any story work begins.

**⚠️ CRITICAL**: US1 (purchase flow), US2 (gate suppression), and US3 (persistence) all require the `gold_generator_owned` field to exist in MetaState and be persisted correctly.

- [x] T001 [P] Add `gold_generator` upgrade entry under `alchemy_lab.upgrades` in `data/meta_config.json` with fields `name: "Transmuter"` and `cost: 50`
- [x] T002 [P] Add `var gold_generator_owned: bool = false` field to `scripts/data_models/MetaState.gd` (after `essence_gain_level`)
- [x] T003 Add `"gold_generator_owned": state.gold_generator_owned` to `save_meta_state()` and `state.gold_generator_owned = bool(parsed.get("gold_generator_owned", false))` to `load_meta_state()` in `scripts/managers/SaveManager.gd` (depends on T002)

**Checkpoint**: MetaState has the flag, it saves and loads correctly, config has the upgrade entry. All stories can now begin.

---

## Phase 3: User Story 1 — Unlock Gold Generation via Transmuter (Priority: P1) 🎯 MVP

**Goal**: Player can open the Alchemy Lab upgrade screen, see the Transmuter entry, spend 50 shards to unlock it, and immediately see gold begin accumulating.

**Independent Test**: With ≥ 50 shards and Transmuter not yet purchased — open Alchemy Lab, press Transmuter button, verify shards decrease by 50, button shows "Transmuter — ACTIVE" (disabled), and gold begins incrementing within 36 s.

### Tests for User Story 1

- [x] T004 [P] [US1] Add unit tests for `purchase_gold_generator()` to `tests/unit/test_meta_manager_impl_gold.gd`: success path (sufficient shards, flag set, shards deducted), failure paths (insufficient shards returns false with no mutation, already-owned returns false with no double-deduct), and idempotency (second call returns false with no additional deduction)

### Implementation for User Story 1

- [x] T005 [P] [US1] Add `purchase_gold_generator(cost: int, save_manager: Node) -> bool` to `scripts/managers/MetaManager.gd` (MetaManagerImpl): early-return if `meta_state.gold_generator_owned`; early-return if `not can_spend(cost)`; deduct shards, set flag, call `_save(save_manager)`, return true
- [x] T006 [US1] Add `var is_gold_generator_owned: bool` computed property (delegates to `_impl.meta_state.gold_generator_owned`) and `func purchase_gold_generator() -> bool` (reads cost from `ResourceManager.get_meta_config()` path `alchemy_lab.upgrades.gold_generator.cost`, delegates to `_impl`, emits `shards_changed` on success) to `autoload/MetaManager.gd` (depends on T005)
- [x] T007 [US1] Refactor `scenes/hub/LabUpgradeScreen.gd`: add `@export var _transmuter_button: Button`; in `_ready()` add `_transmuter_button.pressed.connect(_on_transmuter_pressed)`; extract existing `_update_buttons()` body into `_update_essence_button()`; make `_update_buttons()` a coordinator calling `_update_essence_button()` and `_update_transmuter_button()`; implement `_update_transmuter_button()` (shows "Transmuter — ACTIVE" disabled when owned, else "Transmuter (N shards)" enabled/disabled by affordability); implement `_on_transmuter_pressed()` calling `MetaManager.purchase_gold_generator()` (depends on T006)
- [ ] T008 [US1] **[EDITOR]** Open `scenes/hub/LabUpgradeScreen.tscn` in Godot Editor: add a `Button` node named `TransmuterButton` as a sibling of `EssenceButton`; assign it to the `_transmuter_button` export on `LabUpgradeScreen` via the Inspector (depends on T007)

**Checkpoint**: Open Alchemy Lab with ≥ 50 shards → Transmuter button is enabled → press it → shards decrease by 50 → button shows "ACTIVE" → gold starts ticking. US1 fully functional.

---

## Phase 4: User Story 2 — Gold Remains Zero Before Purchase (Priority: P2)

**Goal**: Gold accumulation (in-session ticking and offline credit) is completely suppressed when `gold_generator_owned` is false. The display stays at 0 regardless of time elapsed.

**Independent Test**: Launch with Transmuter not purchased, wait 60 s in hub — gold must remain 0. Close the game, wait 1 min, reopen — gold must still be 0.

### Tests for User Story 2

- [x] T009 [P] [US2] Add unit tests for gate behaviour to `tests/unit/test_meta_manager_impl_gold.gd`: `tick_gold()` with `gold_generator_owned = false` returns current floor without mutating `total_gold`; `apply_offline_gold()` with `gold_generator_owned = false` and a valid non-zero timestamp awards 0 gold and does not call save; after `gold_generator_owned` is set to true, `tick_gold()` resumes accumulation normally

### Implementation for User Story 2

- [x] T010 [P] [US2] Guard `tick_gold()` in `scripts/managers/MetaManager.gd` (MetaManagerImpl): prepend `if not meta_state.gold_generator_owned: return floori(meta_state.total_gold)` as the first line
- [x] T011 [P] [US2] Guard `apply_offline_gold()` in `scripts/managers/MetaManager.gd` (MetaManagerImpl): prepend `if not meta_state.gold_generator_owned: return` as the first line (before the timestamp == 0 check)

**Checkpoint**: Without purchasing Transmuter, gold display stays at 0 in hub for any duration and after any app restart. US2 fully functional independently of US1 purchase flow.

---

## Phase 5: User Story 3 — Transmuter State Persists Across Sessions (Priority: P3)

**Goal**: After purchasing the Transmuter, the purchased state and gold balance survive a full app restart — no re-purchase required, offline gold credited correctly.

**Independent Test**: Purchase Transmuter, record gold + timestamp, close game, wait 1 min, reopen — Transmuter shows ACTIVE, gold increased by ~1.67 (floor = 1).

No additional code tasks required — US3 is fully covered by the foundational tasks (T002, T003) which persist `gold_generator_owned`, and the guards from US2 (T010, T011) which ensure offline credit fires correctly post-purchase.

**Checkpoint**: After purchase + restart, `is_gold_generator_owned` is true, offline gold is credited, Transmuter button shows ACTIVE. US3 complete.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T012 Run manual verification steps from `specs/042-gold-generator-gate/quickstart.md` in full: pre-purchase suppression, purchase flow, post-purchase offline credit, affordability guard, and data-driven config check (change cost to 999, verify UI reflects it, revert)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately; T001 and T002 are parallel
- **US1 (Phase 3)**: Depends on T001, T002, T003
- **US2 (Phase 4)**: Depends on T002 only (MetaState field must exist); T010 and T011 are parallel; can run alongside US1 implementation
- **US3 (Phase 5)**: No new tasks — covered by Phase 2 + Phase 4
- **Polish (Phase 6)**: Depends on all phases complete

### User Story Dependencies

- **US1**: Requires T001 (config), T002 (MetaState), T003 (SaveManager)
- **US2**: Requires T002 (MetaState field); T010/T011 can be written independently of US1
- **US3**: No new tasks

### Parallel Opportunities

- T001 + T002: parallel (different files)
- T004 + T005: parallel (test file vs impl file)
- T010 + T011: parallel (different methods, same file — write sequentially if editing same file in one pass; otherwise parallel via separate edits)
- T009 can be written before or alongside T010/T011 (test first)

---

## Parallel Example: User Story 1

```text
After T003 completes:

Parallel batch A:
  T004 — Write unit tests for purchase_gold_generator()
  T005 — Implement purchase_gold_generator() in MetaManagerImpl

Then sequentially:
  T006 — Add autoload property + delegation (depends on T005)
  T007 — Update LabUpgradeScreen.gd (depends on T006)
  T008 — Editor task: add TransmuterButton node (depends on T007)
```

## Parallel Example: User Story 2

```text
After T002 completes (can overlap with US1 work):

Parallel batch:
  T009 — Write gate unit tests
  T010 — Guard tick_gold()
  T011 — Guard apply_offline_gold()
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 2: T001, T002, T003
2. Complete Phase 3: T004 → T005 → T006 → T007 → T008
3. **STOP and VALIDATE**: Purchase flow works end-to-end
4. Gold now generates for players who purchase — feature is shippable at this point

### Incremental Delivery

1. Phase 2 (Foundational) → data layer ready
2. Phase 3 (US1) → purchase flow live
3. Phase 4 (US2) → gate enforcement live (gold cannot be earned without purchase)
4. Phase 5 (US3) → persistence verified (no new code, just validation)
5. Phase 6 → manual QA pass

### Note on Ordering US1 vs US2

US2 (gate suppression) must be implemented before or together with US1 if the feature is to be correct at each step. Without T010/T011, a player could earn gold simply by waiting — even before purchasing the Transmuter. Implement US2 guards as soon as MetaState field exists (after T002).

---

## Notes

- T008 is an Editor task — cannot be automated; requires Godot Editor open
- `test_meta_manager_impl_gold.gd` already exists as an untracked file (from feature 041); extend it rather than creating a new file
- All config values (cost, name) must be read from `ResourceManager.get_meta_config()` — never hard-coded in scripts
- `MetaManager._process()` and `_ready()` require no changes — gates live entirely in MetaManagerImpl
