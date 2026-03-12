# Tasks: Boss Challenge Gate

**Input**: Design documents from `/specs/038-boss-challenge-gate/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Organization**: Tasks grouped by user story for independent implementation and testing. No tests — manual in-editor validation only.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story this task belongs to (US1–US4)

---

## Phase 1: Setup (Data Layer)

**Purpose**: Extend `meta_config.json` with popup message and gate text. All later phases depend on this.

- [x] T001 Add `"first_boss_killed": { "popup_message": "You have defeated the boss. Boss Challenge Mode can now be purchased in the Mage Tower." }` under `mage_tower` in `data/meta_config.json`
- [x] T002 Add `"gate_text": "Major essence required"` to `mage_tower.upgrades.boss_challenge` in `data/meta_config.json`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: New script and gate logic that all user story phases depend on.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T003 Write `scenes/ui/boss_kill_popup/BossKillPopup.gd`: `class_name BossKillPopup extends Control`; signal `ok_pressed`; exports `_message_label: Label`, `_ok_button: Button`; `setup(message: String)` sets `_message_label.text = message`; `_ready()` connects `_ok_button.pressed → func() → ok_pressed.emit()`
- [x] T004 Update `_apply_entry(cfg: Dictionary)` in `scenes/hub/MageTowerUpgradeScreen.gd`: prepend gate guard — read `gate_prop: String = cfg.get("gate_prop", "")`; if `gate_prop != "" and not MetaManager.get(gate_prop)`: set `button.text = cfg.get("gate_text", "")`, `button.disabled = true`, `return`; all existing owned/cost logic unchanged after the guard
- [x] T005 Update `_entries` construction in `_ready()` in `scenes/hub/MageTowerUpgradeScreen.gd`: extend the `boss_challenge` entry merge with `"gate_prop": "is_first_boss_killed"` and `"gate_text": upgrades.get("boss_challenge", {}).get("gate_text", "")`

**Checkpoint**: `_apply_entry` gate logic is in place. `BossKillPopup.gd` script exists. Ready for user story work.

---

## Phase 3: User Story 1 — First Boss Kill Sets Flag (Priority: P1) 🎯 MVP

**Goal**: Confirm `first_boss_killed` flag is set and persisted on first endless boss kill. (Flag and persistence already implemented — this phase validates no regression and wires any needed connections.)

**Independent Test**: Kill the boss in an endless run for the first time. Restart the game. Confirm `first_boss_killed` is still true and Boss Challenge button in Mage Tower shows normal cost text.

- [x] T006 [US1] Verify `MetaManager._on_room_cleared()` in `autoload/MetaManager.gd` correctly calls `_impl.record_boss_kill(SaveManager)` when `room_id == "boss_room"` and `run_mode == "endless"` — read the file and confirm; no code change expected

**Checkpoint**: US1 confirmed — flag set on first kill, persists across restart.

---

## Phase 4: User Story 2 — Boss Kill Popup (No Relics) (Priority: P2)

**Goal**: After the first endless boss kill with relic system inactive, a popup appears before the victory overlay with the configured message and an OK button that resumes the flow.

**Independent Test**: Kill boss for first time with relic system not purchased. Confirm popup appears with correct message. Tap OK. Confirm victory overlay appears. Kill boss again — confirm no popup.

- [x] T007 [US2] Add fields to `scenes/core/Main.gd`: `var _boss_kill_popup_layer: CanvasLayer` (null), `var _first_boss_popup_pending: bool` (false); add preload `const _BOSS_KILL_POPUP_SCENE = preload("res://scenes/ui/boss_kill_popup/BossKillPopup.tscn")`
- [x] T008 [US2] Update `_on_boss_room_cleared(room_id: String)` in `scenes/core/Main.gd`: inside the `if RunManager.run_mode == "endless":` block, before the `RelicManager.trigger_boss_offer()` call, add `if MetaManager.endless_boss_kill_count == 1: _first_boss_popup_pending = true`
- [x] T009 [US2] Update `_show_boss_victory_overlay()` in `scenes/core/Main.gd`: add guard at top — `if _first_boss_popup_pending: _first_boss_popup_pending = false; _show_boss_kill_popup(); return`; existing overlay instantiation unchanged below
- [x] T010 [US2] Add `_show_boss_kill_popup()` to `scenes/core/Main.gd`: reads `ResourceManager.get_meta_config().get("mage_tower", {}).get("first_boss_killed", {}).get("popup_message", "")`; creates `_boss_kill_popup_layer = CanvasLayer.new()`; calls `add_child(_boss_kill_popup_layer)`; instantiates `_BOSS_KILL_POPUP_SCENE`, adds to layer, calls `popup.setup(message)`, connects `popup.ok_pressed → _on_boss_kill_popup_ok`
- [x] T011 [US2] Add `_on_boss_kill_popup_ok()` to `scenes/core/Main.gd`: `_boss_kill_popup_layer.queue_free(); _boss_kill_popup_layer = null; _show_boss_victory_overlay()`
- [x] T012 [US2] Guard `_boss_kill_popup_layer` cleanup in `_on_run_started()` and `_on_run_ended()` in `scenes/core/Main.gd`: add `if _boss_kill_popup_layer != null: _boss_kill_popup_layer.queue_free(); _boss_kill_popup_layer = null` alongside existing `_boss_victory_layer` cleanup
- [ ] T013 [US2] Create `scenes/ui/boss_kill_popup/BossKillPopup.tscn` in Godot Editor: Control root → attach `BossKillPopup.gd`; add `Label` child → assign to `_message_label` export; add `Button` child (text "OK") → assign to `_ok_button` export

**Checkpoint**: US2 fully functional — popup appears on first boss kill (no relics), OK resumes flow, no popup on second kill.

---

## Phase 5: User Story 3 — Popup After Relic Offer (Priority: P3)

**Goal**: When the relic system is active, the popup appears after relic selection, before the victory overlay.

**Independent Test**: Purchase Relic System in Mage Tower. Kill boss for first time. Confirm relic offer appears first. Pick a relic. Confirm popup appears next. Tap OK. Confirm victory overlay appears.

- [x] T014 [US3] Verify `_on_relic_picked()` in `scenes/core/Main.gd` calls `_show_boss_victory_overlay()` when `_boss_relic_pending` is true — read and confirm; no code change expected since `_show_boss_victory_overlay()` already has the popup guard from T009

**Checkpoint**: US3 confirmed — popup correctly sequenced after relic pick, before victory overlay.

---

## Phase 6: User Story 4 — Boss Challenge Button Gated (Priority: P4)

**Goal**: Boss Challenge entry in Mage Tower shows "Major essence required" and is non-interactive until first boss kill.

**Independent Test**: Open Mage Tower upgrade screen before any boss kill — Boss Challenge shows "Major essence required", disabled. Add shards via DevPanel — still disabled. Kill boss — return to hub, open screen — entry shows normal cost and affordability.

- [x] T015 [US4] Verify gate logic from T004 and T005 is working: open Mage Tower upgrade screen in-editor with `first_boss_killed = false` and confirm Boss Challenge button shows gate text and is disabled while Dungeon Expansion and Relic System entries are unaffected — no code change expected; validation task only

**Checkpoint**: US4 confirmed — gate displays correctly, all other entries unaffected.

---

## Phase 7: Polish & Validation

**Purpose**: Full end-to-end flow validation and edge case confirmation.

- [ ] T016 Validate full first-kill flow (no relics): start endless run → kill boss → popup appears with correct message → OK → victory overlay → cash out → hub → Mage Tower → Boss Challenge shows cost not gate text
- [ ] T017 Validate full first-kill flow (relics active): start endless run → kill boss → relic offer → pick relic → popup → OK → victory overlay
- [ ] T018 Validate no-rare-relic fallback: if no rare relics available (trigger_boss_offer returns false), popup still appears before victory overlay on first kill
- [ ] T019 Validate second boss kill: no popup on second kill in same session or subsequent sessions
- [ ] T020 Validate persistence: first_boss_killed flag survives app restart; Boss Challenge button shows normal cost after restart
- [ ] T021 Validate shard balance irrelevance: with first_boss_killed = false, Boss Challenge shows gate text regardless of shard balance (0 or 9999)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 (T001, T002 → T004, T005)
- **Phase 3 (US1)**: Depends on Phase 2 completion; T006 is a read/verify — can run in parallel with Phase 2
- **Phase 4 (US2)**: Depends on Phase 2 completion (T003 must exist before T013)
- **Phase 5 (US3)**: Depends on Phase 4 completion (T009 must exist)
- **Phase 6 (US4)**: Depends on Phase 2 completion (T004, T005 must exist)
- **Phase 7 (Polish)**: Depends on Phase 3 + 4 + 5 + 6 completion

### Within-Phase Dependencies

```
T001 → T002 (same file, sequential)
T003 [P with T004/T005]
T004 → T005 (same file)

T007 → T008 → T009 → T010 → T011 → T012 (same file, sequential)
T013 depends on T003 (scene needs script to exist)

T014 depends on T009
T015 depends on T004, T005
```

### Parallel Opportunities

- T001/T002 sequential (same file); T003 parallel with T004/T005
- T006 (read/verify) can run any time after Phase 1
- T007–T012 are all Main.gd edits — sequential
- T013 (Editor task) can be done any time after T003 exists
- T015 (verify) can run any time after T004/T005

---

## Implementation Strategy

### MVP (US1 + US2 — flag confirmed + popup working)

1. Complete Phase 1 (T001–T002)
2. Complete Phase 2 (T003–T005)
3. Complete Phase 3 (T006) — verify flag, no code change
4. Complete Phase 4 (T007–T013) — popup wired and working
5. **STOP and VALIDATE** — first-kill popup fires correctly, no popup on second kill

### Full Delivery

6. Complete Phase 5 (T014) — confirm relic-path ordering (likely already working)
7. Complete Phase 6 (T015) — confirm gate display
8. Complete Phase 7 (T016–T021) — full validation

---

## Notes

- T006 and T014 and T015 are read/verify tasks — they confirm existing behaviour is correct. If a discrepancy is found, a fix task should be added before continuing.
- T013 (BossKillPopup.tscn) requires Godot Editor to be open with `project.godot`
- Script T003 must exist on disk before T013 can attach it in the Editor
- The gate in `_apply_entry` is opt-in — only boss_challenge carries `gate_prop`; all other entries are structurally unaffected
