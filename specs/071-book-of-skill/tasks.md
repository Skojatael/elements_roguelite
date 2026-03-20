# Tasks: Book of Skill

**Input**: Design documents from `/specs/071-book-of-skill/`
**Prerequisites**: spec.md ✅, plan.md ✅

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)

---

## Phase 1: Setup (Shared Data Infrastructure)

**Purpose**: Data and schema changes required by every user story.

- [x] T001 Add `"book_of_skill": {"cost": 250, "popup_message": "..."}` section to `data/meta_config.json`
- [x] T002 [P] Add `book_of_skill_gate_reached: bool = false` and `book_of_skill_owned: bool = false` to `scripts/data_models/MetaState.gd`
- [x] T003 [P] Add `"book_of_skill_gate_reached"` and `"book_of_skill_owned"` keys to `save_meta_state()` dict and `load_meta_state()` dict (with `false` defaults) in `scripts/managers/SaveManager.gd`

---

## Phase 2: Foundational (Manager Logic + Autoload)

**Purpose**: Business logic and autoload delegation that all scenes depend on.

**⚠️ CRITICAL**: Complete before any scene or Main.gd work.

- [x] T004 Add `record_book_of_skill_gate(save_manager: Node) -> bool` (sets `book_of_skill_gate_reached = true` if not already set, saves, returns true if changed) and `purchase_book_of_skill(cost: int, save_manager: Node) -> bool` (standard idempotent purchase guard: owned check, can_spend check, deduct, set `book_of_skill_owned = true`, save) to `scripts/managers/MetaManager.gd`
- [x] T005 [P] Add computed properties `is_book_of_skill_gate_reached: bool` and `is_book_of_skill_owned: bool` (both read-through to `_impl.meta_state`) and delegating methods `record_book_of_skill_gate() -> bool` and `purchase_book_of_skill() -> bool` (reads `meta_config.get("book_of_skill", {}).get("cost", 250)`, delegates to impl, emits `shards_changed` on purchase success) to `autoload/MetaManager.gd`
- [x] T006 Create `tests/unit/test_meta_manager_impl_book_of_skill.gd` following the pattern in `tests/unit/test_meta_manager_impl_missile_charge.gd`; cover: `record_book_of_skill_gate` returns true on first call and false on second; `purchase_book_of_skill` deducts cost and sets flag on success; `purchase_book_of_skill` returns false when already owned; `purchase_book_of_skill` returns false when insufficient shards; use inline `StubSaveManager` (no autoloads)

**Checkpoint**: Unit tests pass. Autoload exposes correct properties.

---

## Phase 3: User Story 1 — Gate Unlock Popup (Priority: P1) 🎯 MVP

**Goal**: On the run where the 3rd boss is killed, a one-time popup fires before the boss victory overlay.

**Independent Test**: Kill 3 bosses (or set `endless_boss_kill_count = 2` in save then kill one more). Popup with Book of Skill message appears. Kill a 4th boss — popup does NOT fire again.

- [x] T007 [US1] Update `scenes/core/Main.gd`: add `var _book_of_skill_popup_pending: bool = false`; in `_on_boss_room_cleared()`, after the existing `count == 1` block, add check `if MetaManager.endless_boss_kill_count == 3 and not MetaManager.is_book_of_skill_gate_reached: MetaManager.record_book_of_skill_gate(); _book_of_skill_popup_pending = true`; in `_show_boss_victory_overlay()`, add guard for `_book_of_skill_popup_pending` immediately after the `_first_boss_popup_pending` guard (clear flag, call `_show_book_of_skill_popup()`, return); add `_show_book_of_skill_popup()` reading message from `ResourceManager.get_meta_config().get("book_of_skill", {}).get("popup_message", "")` and showing `BossKillPopup` inside `_boss_kill_popup_layer`; add `_on_book_of_skill_popup_ok()` that frees `_boss_kill_popup_layer` and calls `_show_boss_victory_overlay()`; reset `_book_of_skill_popup_pending = false` in `_on_run_started()`

**Checkpoint**: Popup fires exactly once at 3rd boss kill. Subsequent kills skip it.

---

## Phase 4: User Story 2 — Building Appears in Hub (Priority: P2)

**Goal**: After the gate triggers, the Book of Skill node is visible in the hub on every subsequent visit, hidden before.

**Independent Test**: With gate NOT triggered — verify building invisible. Trigger gate — return to hub — building visible in "not created" state.

- [x] T008 [US2] Implement `scenes/hub/BookOfSkill.gd` (`class_name BookOfSkill extends Control`): exports `_not_created_visual: ColorRect`, `_created_visual: ColorRect`, `_label: Label`, `_button: Button`, `_buy_overlay_scene: PackedScene`, `_interior_scene: PackedScene`; in `_ready()` connect `MetaManager.shards_changed` (lambda discard arg) and `GlobalSignals.hub_entered` (lambda) to `_update_visuals()`; `_update_visuals()` sets `visible = MetaManager.is_book_of_skill_gate_reached`, `_not_created_visual.visible = not MetaManager.is_book_of_skill_owned`, `_created_visual.visible = MetaManager.is_book_of_skill_owned`; `_on_button_pressed()` calls `_show_buy_overlay()` when not owned, `_show_interior()` when owned; manages `_overlay_layer: CanvasLayer` for both overlay and interior; follows `MageTower.gd` structure
- [ ] T009 [US2] **[EDITOR]** Create `scenes/hub/BookOfSkill.tscn` in Godot Editor: `Control` root with `BookOfSkill.gd` attached; children: `NotCreatedVisual` (ColorRect), `CreatedVisual` (ColorRect), `Label`, `Button`; assign all `@export` vars in Inspector
- [ ] T010 [US2] **[EDITOR]** Open `scenes/hub/HubRoom.tscn` in Godot Editor; add `BookOfSkill.tscn` as a child node and position it in the hub layout; assign `_buy_overlay_scene` → `BookOfSkillBuyOverlay.tscn` and `_interior_scene` → `BookOfSkillInterior.tscn` in the Inspector (these scenes are created in later tasks — assign after T012 and T014 are done)

**Checkpoint**: Visibility toggles correctly with gate state. Visual states show correct ColorRect.

---

## Phase 5: User Story 3 — Purchase to Create (Priority: P3)

**Goal**: Tapping "not created" building shows a purchase overlay; confirming with sufficient shards transitions to "created" permanently.

**Independent Test**: With gate reached and building not owned, tap → overlay appears with cost; with insufficient shards buy button is disabled; with sufficient shards confirm → building switches to created state; re-enter hub → still created.

- [x] T011 [US3] Implement `scenes/hub/BookOfSkillBuyOverlay.gd` (`class_name BookOfSkillBuyOverlay extends Control`): exports `_buy_button: Button`, `_cancel_button: Button`, `_cost_label: Label`; signals `buy_pressed`, `cancel_pressed`; in `_ready()` reads cost via `ResourceManager.get_meta_config().get("book_of_skill", {}).get("cost", 250)`, sets label text, calls `_update_button()`; `_update_button()` sets `_buy_button.disabled = not MetaManager.can_spend(cost)`; connects `MetaManager.shards_changed` (lambda) to `_update_button()`; buy button pressed emits `buy_pressed`; cancel button pressed emits `cancel_pressed`; follows `RestoreTowerOverlay.gd` structure
- [ ] T012 [US3] **[EDITOR]** Create `scenes/hub/BookOfSkillBuyOverlay.tscn`: `Control` root with `BookOfSkillBuyOverlay.gd` attached; children: `CostLabel` (Label), `BuyButton` (Button), `CancelButton` (Button); assign `@export` vars
- [x] T013 [US3] Complete purchase wiring in `scenes/hub/BookOfSkill.gd`: implement `_show_buy_overlay()` method — instantiates `_buy_overlay_scene` into `_overlay_layer: CanvasLayer`, connects overlay's `buy_pressed` to `_on_buy_pressed()` and `cancel_pressed` to `_close_overlay()`; implement `_on_buy_pressed()` — calls `MetaManager.purchase_book_of_skill()`, calls `_close_overlay()`, calls `_update_visuals()`; implement `_close_overlay()` — frees `_overlay_layer` and nulls it

**Checkpoint**: Purchase deducts shards, building shows created visual, state survives hub re-entry.

---

## Phase 6: User Story 4 — Interior Screen (Priority: P4)

**Goal**: Tapping a "created" building opens the interior screen; Close button dismisses it.

**Independent Test**: With building owned, tap → interior opens; tap Close → interior dismissed, hub interactive.

- [x] T014 [US4] Implement `scenes/hub/BookOfSkillInterior.gd` (`class_name BookOfSkillInterior extends Control`): single export `_close_button: Button`; signal `close_pressed`; in `_ready()` connects `_close_button.pressed` to emit `close_pressed`
- [ ] T015 [US4] **[EDITOR]** Create `scenes/hub/BookOfSkillInterior.tscn`: `Control` root with `BookOfSkillInterior.gd` attached; child `CloseButton` (Button); assign `_close_button` export
- [x] T016 [US4] Complete interior wiring in `scenes/hub/BookOfSkill.gd`: implement `_show_interior()` method — instantiates `_interior_scene` into `_overlay_layer: CanvasLayer`, connects interior's `close_pressed` to `_close_overlay()`

**Checkpoint**: Interior opens on tap, Close dismisses cleanly, no orphaned nodes.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T017 [P] Run GUT unit test suite to confirm no regressions (`tests/unit/test_meta_manager_impl_book_of_skill.gd` passes; existing tests unaffected by MetaState/SaveManagerImpl changes)
- [ ] T018 Assign `_interior_scene` export on `BookOfSkill` node in `HubRoom.tscn` after T015 is complete (if deferred from T010)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1** (T001–T003): No dependencies — start immediately; T002 and T003 are parallel
- **Phase 2** (T004–T006): Depends on Phase 1 (MetaState fields must exist) — BLOCKS all scene work
- **Phase 3** (T007): Depends on Phase 2 (needs `MetaManager.is_book_of_skill_gate_reached` and `record_book_of_skill_gate()`)
- **Phase 4** (T008–T010): Depends on Phase 2; T009/T010 are editor tasks after T008
- **Phase 5** (T011–T013): Depends on Phase 2; T013 depends on T008 (extends BookOfSkill.gd)
- **Phase 6** (T014–T016): Depends on T008; T016 depends on T014
- **Phase 7** (T017–T018): Depends on all prior phases

### Parallel Opportunities Within Phases

- T002 ‖ T003 (different files, both Phase 1)
- T004 ‖ T005 (different files, both Phase 2) — but T005 depends on T004 completing first (needs new impl methods to delegate to)
- T008 ‖ T011 ‖ T014 (three different new scripts, once Phase 2 is done)
- T009, T012, T015 (editor tasks, all independent once their script is done)

---

## Implementation Strategy

### MVP First (US1 — Gate Popup only)

1. Complete Phase 1 (data)
2. Complete Phase 2 (manager logic)
3. Complete Phase 3 (T007 — Main.gd popup)
4. **STOP and VALIDATE**: kill 3 bosses, verify popup fires once

### Incremental Delivery

1. Phase 1 + 2 → data and logic foundation
2. Phase 3 → popup fires (US1 verified)
3. Phase 4 → building visible in hub (US2 verified)
4. Phase 5 → purchase works (US3 verified)
5. Phase 6 → interior opens/closes (US4 verified)
6. Phase 7 → regression safety net

---

## Notes

- Editor tasks (T009, T010, T012, T015) cannot be scripted — must be done in Godot Editor
- T010 assigns `_interior_scene` export; this requires T015 to exist first. Assign it after T015 if doing tasks sequentially
- Popup message text in `meta_config.json` (T001) is placeholder — update to final copy before shipping
- `record_book_of_skill_gate()` must be idempotent — safe to call even if gate already reached (returns false, no save)
- Pattern reference: `BookOfSkill.gd` ≈ `MageTower.gd`; `BookOfSkillBuyOverlay.gd` ≈ `RestoreTowerOverlay.gd`; `BookOfSkillInterior.gd` ≈ minimal `MageTowerUpgradeScreen.gd`
