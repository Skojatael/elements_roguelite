# Tasks: Mage Tower

**Input**: Design documents from `/specs/037-mage-tower/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Organization**: Tasks grouped by user story for independent implementation and testing. No tests — manual in-editor validation only.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story this task belongs to (US1–US4)

---

## Phase 1: Setup (Data Layer)

**Purpose**: Add the new MetaState field and config keys. All later phases depend on this.

- [x] T001 Add `var mage_tower_unlocked: bool = false` to `scripts/data_models/MetaState.gd`
- [x] T002 Add `mage_tower_unlocked` field to `scripts/managers/SaveManager.gd` (SaveManagerImpl): write `"mage_tower_unlocked": state.mage_tower_unlocked` in `save_meta_state()`; read `state.mage_tower_unlocked = bool(parsed.get("mage_tower_unlocked", false))` in `load_meta_state()`
- [x] T003 [P] Update `data/meta_config.json`: add keys `mage_tower_cost: 200`, `mage_tower_dungeon_expansion_cost: 200`, `mage_tower_relic_system_cost: 100`, `mage_tower_boss_challenge_cost: 200`; remove keys `adventuring_gear_cost`, `boss_run_cost`, `boss_run_kill_threshold`

---

## Phase 2: Foundational (MetaManager + Cleanup)

**Purpose**: Wire purchase logic into MetaManager layer and remove obsolete code. Blocks all user story work.

**⚠️ CRITICAL**: No user story scenes can work until this phase is complete.

- [x] T004 Update `scripts/managers/MetaManager.gd` (MetaManagerImpl): delete `try_activate_relic_offers()` and `unlock_adventurer_bag()` methods; add `purchase_mage_tower(cost: int, save_manager: Node) -> bool` (guard: already unlocked → false, can't afford → false; deduct, set `mage_tower_unlocked = true`, save); add `purchase_mage_tower_relic_system(cost: int, save_manager: Node) -> bool` (guard: `relic_offers_active` already true → false, can't afford → false; deduct, set `adventurer_bag_unlocked = true` and `relic_offers_active = true`, save)
- [x] T005 Update `autoload/MetaManager.gd`: remove `_impl.try_activate_relic_offers(SaveManager)` call from `_on_hub_entered()` (remove the method entirely if that was its sole purpose); remove `_impl.unlock_adventurer_bag(SaveManager)` call from elite detection branch in `_on_room_cleared()` (remove the elite branch entirely if that was its sole purpose); add `var is_mage_tower_unlocked: bool:` computed property returning `_impl.meta_state.mage_tower_unlocked`; add `purchase_mage_tower() -> bool` reading `mage_tower_cost` from config, delegating to `_impl.purchase_mage_tower()`, emitting `shards_changed` on success; add `purchase_mage_tower_relic_system() -> bool` reading `mage_tower_relic_system_cost` from config, delegating, emitting `shards_changed` on success
- [x] T006 [P] Delete orphaned scripts no longer attached to any scene: `scenes/hub/AdventuringGearShop.gd`, `scenes/hub/AdventuringGearShop.gd.uid`, `scenes/hub/BossRunShop.gd`, `scenes/hub/BossRunShop.gd.uid`

**Checkpoint**: MetaManager API is ready — `MetaManager.is_mage_tower_unlocked`, `purchase_mage_tower()`, `purchase_mage_tower_relic_system()` all callable. Old auto-unlock paths gone.

---

## Phase 3: User Story 1 — Player Restores the Mage Tower (Priority: P1) 🎯 MVP

**Goal**: A ruined Mage Tower zone appears in the hub. Tapping it opens a restoration overlay. Paying 200 shards switches the zone to its restored visual state permanently.

**Independent Test**: With 200+ shards, tap the ruined zone → overlay shows → purchase → visual changes to restored → restart game → still restored. With < 200 shards, restore button is disabled.

**Note**: US5 (cannot afford) is covered by T007 — the RestoreTowerOverlay disables its button when `not MetaManager.can_spend(cost)`.

### Implementation

- [x] T007 [P] [US1] Write `scenes/hub/RestoreTowerOverlay.gd`: `class_name RestoreTowerOverlay extends Control`; signals `restore_pressed`, `maybe_later_pressed`; exports `_restore_button: Button`, `_later_button: Button`; `_ready()` reads `mage_tower_cost` from `ResourceManager.get_meta_config()`, sets restore button text to `"Restore the Mage Tower ({c} shards)".format({"c": cost})`, disables restore button when `not MetaManager.can_spend(cost)`, connects `_restore_button.pressed → restore_pressed.emit()`, connects `_later_button.pressed → maybe_later_pressed.emit()`
- [x] T008 [P] [US1] Write `scenes/hub/MageTower.gd`: `class_name MageTower extends Control`; exports `_ruined_visual: ColorRect`, `_magic_visual: ColorRect`, `_label: Label`, `_button: Button`, `_restore_overlay_scene: PackedScene`, `_upgrade_screen_scene: PackedScene`; `var _overlay_layer: CanvasLayer = null`; `_ready()` connects `_button.pressed → _on_tower_pressed`, `MetaManager.shards_changed → func(_n) → _update_visuals()`, `GlobalSignals.hub_entered → func() → _update_visuals()`, then calls `_update_visuals()`; `_update_visuals()` sets ruined/magic visibility and label text based on `MetaManager.is_mage_tower_unlocked`; `_on_tower_pressed()` guards `_overlay_layer != null`; branches: unlocked → `_show_upgrade_screen()`, locked → `_show_restore_overlay()`; `_show_restore_overlay()` creates CanvasLayer, instantiates overlay, connects `restore_pressed → _on_restore_pressed`, `maybe_later_pressed → _close_overlay`; `_show_upgrade_screen()` creates CanvasLayer, instantiates screen, connects `close_pressed → _close_overlay`; `_close_overlay()` frees and nulls `_overlay_layer`; `_on_restore_pressed()` calls `MetaManager.purchase_mage_tower()`, returns early on failure, else calls `_close_overlay()` and `_update_visuals()`
- [ ] T009 [US1] Create `scenes/hub/RestoreTowerOverlay.tscn` in Godot Editor: Control root → attach `RestoreTowerOverlay.gd`; add child `RestoreButton` (Button) → assign to `_restore_button` export; add child `LaterButton` (Button) → assign to `_later_button` export
- [ ] T010 [US1] Create `scenes/hub/MageTower.tscn` in Godot Editor: Control root → attach `MageTower.gd`; add child `RuinedVisual` (ColorRect, black) → assign to `_ruined_visual`; add child `MageTowerVisual` (ColorRect, dark color) → assign to `_magic_visual`; add child `Label` → assign to `_label`; add child `Button` → assign to `_button`; assign `RestoreTowerOverlay.tscn` to `_restore_overlay_scene` export (leave `_upgrade_screen_scene` unset for now)
- [ ] T011 [US1] Update `scenes/hub/HubRoom.tscn` in Godot Editor: remove `AdventuringGearShop` node; remove `BossRunShop` node; add `MageTower.tscn` instance as child, position at approximately `(-400, 200)` in hub local space

**Checkpoint**: US1 fully functional — ruined/restored visual states work, shard deduction correct, persistence across restart confirmed. US5 confirmed: restore button disabled when balance < 200.

---

## Phase 4: User Stories 2–4 — System Upgrades Screen (Priority: P2–P4)

**Goal**: Tapping the restored Mage Tower opens a system upgrades screen with three purchasable unlocks: Relic System (100 shards), Dungeon Expansion (200 shards), Boss Challenge Mode (200 shards). Each entry shows "Unlock (X shards)" or "Unlocked" based on current state. A close button returns to the hub.

**Independent Test**: With the tower restored, tap it → upgrade screen opens. Purchase each unlock individually and confirm: shard deduction, entry switches to "Unlocked", and the corresponding game system activates in the next run. Confirm close button returns to hub with no orphaned nodes.

### Implementation

- [x] T012 [US2] Write `scenes/hub/MageTowerUpgradeScreen.gd`: `class_name MageTowerUpgradeScreen extends Control`; signal `close_pressed`; exports `_de_button: Button`, `_de_unlocked_label: Label`, `_rs_button: Button`, `_rs_unlocked_label: Label`, `_bc_button: Button`, `_bc_unlocked_label: Label`, `_close_button: Button`; `_ready()` reads three costs from `ResourceManager.get_meta_config()` into local vars; connects `_de_button.pressed → _on_de_buy`, `_rs_button.pressed → _on_rs_buy`, `_bc_button.pressed → _on_bc_buy`, `_close_button.pressed → func() → close_pressed.emit()`, `MetaManager.shards_changed → func(_n) → _update_entries()`; calls `_update_entries()`; `_update_entries()` for each system: if owned → hide button, show unlocked label; else → show button with cost text (`"Dungeon Expansion — {c} shards".format({"c": cost})`), disable button if `not MetaManager.can_spend(cost)`, hide unlocked label; ownership checks: DE = `MetaManager.is_adventuring_gear_owned`, RS = `MetaManager.is_relic_offers_active`, BC = `MetaManager.is_boss_run_unlocked`; `_on_de_buy()` calls `MetaManager.purchase_adventuring_gear()`, then `_update_entries()`; `_on_rs_buy()` calls `MetaManager.purchase_mage_tower_relic_system()`, then `_update_entries()`; `_on_bc_buy()` calls `MetaManager.purchase_boss_run()`, then `_update_entries()`
- [ ] T013 [US2] Create `scenes/hub/MageTowerUpgradeScreen.tscn` in Godot Editor: Control root → attach `MageTowerUpgradeScreen.gd`; add `DungeonExpansionButton` (Button) → assign to `_de_button`; add `RelicSystemButton` (Button) → assign to `_rs_button`; add `BossChallengeButton` (Button) → assign to `_bc_button`; add `CloseButton` (Button) → assign to `_close_button`
- [ ] T014 [US2] Assign `MageTowerUpgradeScreen.tscn` to MageTower's `_upgrade_screen_scene` export in Godot Editor: open `HubRoom.tscn`, select the `MageTower` node, set `_upgrade_screen_scene` in Inspector to `scenes/hub/MageTowerUpgradeScreen.tscn`

**Checkpoint**: All three system unlocks purchasable. US2 confirmed (relics appear after purchase). US3 confirmed (dungeon generates 13 rooms). US4 confirmed (BossRunButton visible after purchase).

---

## Phase 5: Polish & Cross-Cutting

**Purpose**: Final cleanup and full-flow validation.

- [ ] T015 Validate full tower flow: 0 shards → ruined zone visible → tap → overlay opens → restore button disabled; add 200 shards via DevPanel → restore button enables → purchase → visual changes → overlay closes → tap restored tower → upgrade screen opens → close button works → no orphaned CanvasLayer nodes
- [ ] T016 Validate each system unlock end-to-end: purchase Relic System (100 shards) → entry shows "Unlocked" → start run, clear combat room → relic offer appears; purchase Dungeon Expansion (200 shards) → entry shows "Unlocked" → start endless run → 13 rooms generated; purchase Boss Challenge (200 shards) → entry shows "Unlocked" → BossRunButton visible in hub; restart game → all purchased states persist

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 (T001 → T004, T001+T002 → T005)
- **Phase 3 (US1)**: Depends on Phase 2 completion
- **Phase 4 (US2–4)**: Depends on Phase 2 completion; Phase 3 must be partially complete (T010 must exist before T014)
- **Phase 5 (Polish)**: Depends on Phase 3 + Phase 4 completion

### Within-Phase Dependencies

```
T001 → T002
T001 → T004 → T005
T003 [P with T001/T002]
T006 [P with T004/T005]

T007 → T009 → T011
T008 → T010 → T011

T012 → T013 → T014
```

### Parallel Opportunities

- T003 (config JSON) runs in parallel with T001+T002
- T006 (delete files) runs in parallel with T004+T005
- T007 (RestoreTowerOverlay.gd) and T008 (MageTower.gd) run in parallel
- T009 (RestoreTowerOverlay.tscn) and T010 (MageTower.tscn Editor tasks) run in parallel after their scripts exist
- T012 (upgrade screen script) can begin as soon as Phase 2 is done, in parallel with Phase 3 Editor work

---

## Implementation Strategy

### MVP (US1 only — tower restoration)

1. Complete Phase 1 (T001–T003)
2. Complete Phase 2 (T004–T006)
3. Complete Phase 3 (T007–T011)
4. **STOP and VALIDATE** — ruined/restored zone works; 200-shard purchase flow confirmed; persistence confirmed

### Full Delivery

5. Complete Phase 4 (T012–T014) — all three system unlocks purchasable
6. Complete Phase 5 (T015–T016) — full end-to-end validation

---

## Notes

- All Godot Editor tasks (T009–T011, T013–T014) require the Godot Editor to be open with `project.godot`
- Script files must exist before their scene can attach them — always write the `.gd` before the Editor task
- T006 (delete files) should be done via the Godot Editor's FileSystem panel or OS file system — delete `.gd` and `.gd.uid` together
- After T006, if Godot shows missing-script errors on HubRoom.tscn, complete T011 immediately to remove the stale nodes
- `ResourceManager.get_meta_config()` is the correct call for reading `meta_config.json` — do not parse JSON directly in scene scripts
