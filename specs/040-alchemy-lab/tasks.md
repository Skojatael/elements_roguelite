# Tasks: Alchemy Lab

**Input**: Design documents from `/specs/040-alchemy-lab/`
**Prerequisites**: spec.md ✅, plan.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the data config block that all scripts read at runtime. Must be done first — scripts fall back to hardcoded defaults without it, which is unacceptable under Constitution II.

- [X] T001 Add `alchemy_lab` block to `data/meta_config.json` (cost: 500, essence_gain: base_cost 0, max_levels 1, essence_per_level 0.05)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data model, persistence, and MetaManager wiring that every other task depends on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T002 Add `alchemy_lab_unlocked: bool = false` and `essence_gain_level: int = 0` to `scripts/data_models/MetaState.gd`
- [X] T003 [P] Add save and load of `alchemy_lab_unlocked` and `essence_gain_level` in `scripts/managers/SaveManager.gd` (`save_meta_state()` dict and `load_meta_state()` parse block)
- [X] T004 [P] Add `purchase_alchemy_lab(cost: int, save_manager: Node) -> bool` to `scripts/managers/MetaManager.gd` (MetaManagerImpl) — guard: already unlocked returns false; deducts cost, sets flag, saves
- [X] T005 Add `is_alchemy_lab_unlocked: bool` computed property, `essence_gain_multiplier: float` computed property, and `purchase_alchemy_lab() -> bool` delegating method to `autoload/MetaManager.gd`
- [X] T006 Add unit tests for `purchase_alchemy_lab()` in `tests/unit/test_alchemy_lab_purchase.gd` covering: success path deducts shards and sets flag; insufficient shards returns false; already-unlocked guard returns false; idempotent (second call returns false)

**Checkpoint**: Foundation ready — all downstream scripts can now call `MetaManager.is_alchemy_lab_unlocked`, `MetaManager.purchase_alchemy_lab()`, and `MetaManager.essence_gain_multiplier`.

---

## Phase 3: User Story 1 — Restore the Alchemy Lab (Priority: P1) 🎯 MVP

**Goal**: Player can tap the Alchemy Lab in the hub, see the restore overlay with cost, confirm restoration, and observe the visual change persisted across sessions.

**Independent Test**: Grant 600 shards via DevPanel → tap building → confirm → verify shard balance drops by 500, visual switches to restored, and state survives a scene reload.

### Implementation for User Story 1

- [X] T007 [US1] Write `scenes/hub/AlchemyLab.gd` (`class_name AlchemyLab extends Control`) with exports `_ruined_visual: ColorRect`, `_magic_visual: ColorRect`, `_label: Label`, `_button: Button`, `_restore_overlay_scene: PackedScene`, `_upgrade_screen_scene: PackedScene`; implement `_ready()`, `_update_visuals()`, `_on_lab_pressed()`, `_show_restore_overlay()`, `_show_upgrade_screen()`, `_close_overlay()`, `_on_restore_pressed()` — see plan.md for full implementation
- [X] T008 [US1] Write `scenes/hub/RestoreLabOverlay.gd` (`class_name RestoreLabOverlay extends Control`) with signals `restore_pressed`, `maybe_later_pressed`; exports `_restore_button: Button`, `_later_button: Button`; `_ready()` reads cost from `ResourceManager.get_meta_config().get("alchemy_lab", {}).get("cost", 500)`, sets button text and disabled state
- [ ] T009 [US1] **[Editor]** Create `scenes/hub/AlchemyLab.tscn`: Control root → attach `AlchemyLab.gd`; add two `ColorRect` children (ruined/restored visuals), one `Label`, one `Button`; assign all `@export var` refs via Inspector
- [ ] T010 [US1] **[Editor]** Create `scenes/hub/RestoreLabOverlay.tscn`: Control root → attach `RestoreLabOverlay.gd`; add two `Button` children; assign `_restore_button` and `_later_button` via Inspector
- [ ] T011 [US1] **[Editor]** Set `_restore_overlay_scene` export on the `AlchemyLab` node (in Inspector) to point at `RestoreLabOverlay.tscn`
- [ ] T012 [US1] **[Editor]** Open `scenes/hub/HubRoom.tscn` in the Godot Editor; add an `AlchemyLab` node (instantiate `AlchemyLab.tscn`) and position it in the hub layout

**Checkpoint**: User Story 1 fully functional — restoration flow works end-to-end, state persists.

---

## Phase 4: User Story 2 — View Essence Gain Upgrade (Priority: P2)

**Goal**: Player with a restored Alchemy Lab opens the upgrade screen and sees the Essence Gain upgrade entry with correct name, +5% bonus, and a disabled purchase button. Changing `essence_per_level` in config changes the displayed value without code edits.

**Independent Test**: Open the upgrade screen on a restored lab → confirm entry shows "Essence Gain +5% (Lv1)" with button disabled. Edit `data/meta_config.json` `essence_per_level` to `0.10` → confirm display updates to "+10%".

### Implementation for User Story 2

- [X] T013 [US2] Write `scenes/hub/LabUpgradeScreen.gd` (`class_name LabUpgradeScreen extends Control`) with signal `close_pressed`; exports `_essence_button: Button`, `_close_button: Button`; `_ready()` subscribes to `MetaManager.shards_changed`; `_update_buttons()` reads config at `alchemy_lab.upgrades.essence_gain`, shows name + pct + level, disables button when `base_cost == 0` — see plan.md for full implementation
- [ ] T014 [US2] **[Editor]** Create `scenes/hub/LabUpgradeScreen.tscn`: Control root → attach `LabUpgradeScreen.gd`; add `_essence_button: Button` and `_close_button: Button`; assign exports via Inspector
- [ ] T015 [US2] **[Editor]** Set `_upgrade_screen_scene` export on the `AlchemyLab` node (in Inspector) to point at `LabUpgradeScreen.tscn`
- [X] T016 [US2] Apply `MetaManager.essence_gain_multiplier` in `scripts/managers/RunManager.gd` `_on_enemy_defeated()`: multiply it as the final factor in the essence formula after `room_essence_mult`

**Checkpoint**: User Stories 1 and 2 both independently functional — building restores, upgrade screen displays correct data-driven values, essence formula applies multiplier (×1.0 at level 0, no behaviour change this iteration).

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Validation against quickstart.md and config-driven smoke test.

- [ ] T017 Run the smoke test from `specs/040-alchemy-lab/quickstart.md`: grant 600 shards, restore lab, open upgrade screen, verify display, restart and confirm persistence
- [ ] T018 Config-driven validation: edit `data/meta_config.json` `alchemy_lab.cost` to `100` → confirm overlay shows "100 shards"; edit `essence_per_level` to `0.10` → confirm upgrade screen shows "+10%"; revert both values

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on T001 (config must exist for defaults to be irrelevant); T002 must complete before T003/T004 (MetaState fields exist before Save/Impl use them); T004 before T005 (impl before autoload wrapper)
- **User Story 1 (Phase 3)**: Depends on all of Phase 2 — T007/T008 can be written in parallel once Phase 2 is complete; T009/T010 require scripts; T011 requires T009+T010; T012 requires T009
- **User Story 2 (Phase 4)**: T013 requires Phase 2; T014 requires T013; T015 requires T014; T016 requires Phase 2 (MetaManager.essence_gain_multiplier available)
- **Polish (Phase 5)**: Depends on all preceding phases

### User Story Dependencies

- **User Story 1 (P1)**: Depends only on Phase 2 completion. No dependency on US2.
- **User Story 2 (P2)**: Depends only on Phase 2 completion. T015 requires AlchemyLab.tscn from US1 (T009), so in practice US1 editor tasks should be done first, but the scripts (T013, T016) can be written in parallel with US1.

### Within Each User Story

- Scripts before Editor tasks (T007/T008 before T009/T010)
- Scenes before Inspector wiring (T009/T010 before T011)
- All before HubRoom placement (T009 before T012)

### Parallel Opportunities

- T003 and T004 can run in parallel (different files, both depend only on T002)
- T007 and T008 can run in parallel (different files)
- T013 and T016 can run in parallel (different files, both depend only on Phase 2)

---

## Parallel Example: Phase 2 Foundational

```
# After T002 (MetaState fields added):
Task A: T003 — SaveManager.gd save/load
Task B: T004 — MetaManagerImpl purchase_alchemy_lab()
# T005 waits for T004; T006 waits for T004
```

## Parallel Example: User Story 1 Scripts

```
# After Phase 2 complete:
Task A: T007 — AlchemyLab.gd
Task B: T008 — RestoreLabOverlay.gd
# T009 waits for T007; T010 waits for T008
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: T001 (config)
2. Complete Phase 2: T002 → T003+T004 (parallel) → T005 → T006
3. Complete Phase 3: T007+T008 (parallel) → T009+T010 → T011 → T012
4. **STOP and VALIDATE**: Restoration flow works, persists, visuals correct
5. Proceed to Phase 4 once MVP is confirmed

### Incremental Delivery

1. Phase 1 + 2 → meta-layer ready
2. Phase 3 → building visible in hub, restoration purchasable ✅ MVP
3. Phase 4 → upgrade screen shows essence gain entry ✅ Full feature
4. Phase 5 → validated against quickstart ✅ Done

---

## Notes

- [P] tasks = different files, no shared dependencies
- [US1]/[US2] labels map to spec.md user stories
- **Editor tasks** must be done in the Godot Editor — they cannot be scripted
- `essence_gain_level` will be 0 throughout this iteration; T016 is a wire-up with no gameplay effect yet — the multiplier returns 1.0 at level 0
- Commit after each logical group (config, data model, autoload, each scene)
