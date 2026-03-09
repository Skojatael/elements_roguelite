# Tasks: Magic Forge

**Input**: Design documents from `specs/036-magic-forge/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (not applicable)

No project scaffolding needed — feature adds to existing Godot project.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data layer + meta-progression API. MUST be complete before any US work begins.

**⚠️ CRITICAL**: All user story phases depend on this foundation.

- [x] T001 [P] Add `"magic_forge_cost": 120` to `data/meta_config.json`
- [x] T002 [P] Add `var magic_forge_unlocked: bool = false` field to `scripts/data_models/MetaState.gd`
- [x] T003 [P] Add `purchase_magic_forge(cost, save_manager)` method to `scripts/managers/MetaManager.gd` (MetaManagerImpl) — guard on already-unlocked and can_spend; deduct shards, set flag, save
- [x] T004 Update `scripts/managers/SaveManager.gd` — add `magic_forge_unlocked` to `save_meta_state()` dict and `load_meta_state()` assignment (depends on T002)
- [x] T005 Add `is_magic_forge_unlocked: bool` computed property and `purchase_magic_forge() -> bool` delegate method to `autoload/MetaManager.gd` (depends on T003)

**Checkpoint**: Foundation ready — MetaManager.is_magic_forge_unlocked and MetaManager.purchase_magic_forge() are callable; state persists across sessions.

---

## Phase 3: User Story 1 — Player Unlocks the Magic Forge (Priority: P1) 🎯 MVP

**Goal**: Ruined Forge visible in hub; tapping opens restore overlay; 120-shard purchase unlocks the forge permanently, switching visuals to Magic Forge.

**Independent Test**: Open the hub, tap the Ruined Forge zone, confirm overlay appears. With ≥120 shards, tap "Restore the Forge" — confirm shards deducted, visual switches to grey "Magic Forge", state persists after leaving and re-entering hub.

### Implementation for User Story 1

- [x] T006 [P] [US1] Write `scenes/hub/RestoreForgeOverlay.gd` — `class_name RestoreForgeOverlay extends Control`; signals `restore_pressed`, `maybe_later_pressed`; `@export var _restore_button: Button` and `@export var _later_button: Button`; `_ready()` sets button text from `meta_config.magic_forge_cost`, disables restore button when `not MetaManager.can_spend(cost)`, connects both buttons to emit their signals
- [x] T007 [P] [US1] Write `scenes/hub/MagicForge.gd` — `class_name MagicForge extends Control`; exports `_ruined_visual: ColorRect`, `_magic_visual: ColorRect`, `_label: Label`, `_button: Button`, `_restore_overlay_scene: PackedScene`, `_upgrade_screen_scene: PackedScene`; `_overlay_layer: CanvasLayer = null` guard prevents double-spawn; `_ready()` connects `_button.pressed`, `MetaManager.shards_changed`, `GlobalSignals.hub_entered` all to refresh visuals; `_update_visuals()` toggles ColorRect visibility and label text based on `MetaManager.is_magic_forge_unlocked`; `_on_forge_pressed()` early-returns if overlay open, then branches on unlock state; `_show_restore_overlay()` creates CanvasLayer child, instantiates overlay, connects signals; `_close_overlay()` frees CanvasLayer, nulls ref; `_on_restore_pressed()` calls `MetaManager.purchase_magic_forge()`, early-returns on failure, then closes overlay and refreshes visuals
- [ ] T008 [US1] **EDITOR** — Create `scenes/hub/restoreforgeoverlay.tscn`: root is `RestoreForgeOverlay` (Control, full-screen anchors, mouse_filter=Stop, script=RestoreForgeOverlay.gd); add `Background` (ColorRect, full-screen, semi-transparent dark); add `Panel` (Control, centered ~300×160); inside Panel add `RestoreButton` (Button) and `LaterButton` (Button); assign Inspector exports `_restore_button → RestoreButton`, `_later_button → LaterButton`
- [ ] T009 [US1] **EDITOR** — Create `scenes/hub/magicforge.tscn`: root is `MagicForge` (Control, script=MagicForge.gd, size ~160×80); add `RuinedVisual` (ColorRect, black, fills parent); add `MagicVisual` (ColorRect, grey, fills parent); add `Label` (centered); add `Button` (fills parent, flat/transparent); assign Inspector exports: `_ruined_visual → RuinedVisual`, `_magic_visual → MagicVisual`, `_label → Label`, `_button → Button`, `_restore_overlay_scene → res://scenes/hub/restoreforgeoverlay.tscn`, `_upgrade_screen_scene → res://scenes/hub/forgeupgradescreen.tscn` (leave upgrade scene blank until T011 exists)

**Checkpoint**: Ruined Forge zone in hub fully functional — overlay appears, purchase works, visual switches, state persists. US1 complete and testable independently.

---

## Phase 4: User Story 2 — Player Purchases Run Upgrades at the Forge (Priority: P2)

**Goal**: Tapping the Magic Forge (unlocked) opens a full upgrade screen showing the damage % upgrade with current level, cost, and a purchase button.

**Independent Test**: With forge unlocked, tap the Magic Forge — upgrade screen opens. Tap the damage upgrade button with sufficient shards — shards deducted, level increments, cost label updates. At max level, button shows "MAX" and is disabled. Close button returns to hub cleanly.

### Implementation for User Story 2

- [x] T010 [P] [US2] Write `scenes/hub/ForgeUpgradeScreen.gd` — `class_name ForgeUpgradeScreen extends Control`; signal `close_pressed`; `@export var _damage_button: Button`, `@export var _close_button: Button`; `_ready()` connects close button to emit `close_pressed`, damage button to `_on_damage_buy()`, and `MetaManager.shards_changed` to `_update_buttons()`; `_update_buttons()` reads `damage_upgrade` config, detects max level (sets text "Damage Multiplier — MAX", disables), otherwise formats button text with current level cost and disables when `not MetaManager.can_spend(cost)`; `_on_damage_buy()` calls `MetaManager.purchase_damage_upgrade()` then `_update_buttons()`
- [ ] T011 [US2] **EDITOR** — Create `scenes/hub/forgeupgradescreen.tscn`: root is `ForgeUpgradeScreen` (Control, full-screen anchors, mouse_filter=Stop, script=ForgeUpgradeScreen.gd); add `Background` (ColorRect, full-screen, semi-transparent dark); add `Panel` (Control, centered ~420×220); inside Panel add `TitleLabel` (Label, text="Magic Forge"), `DamageButton` (Button), `CloseButton` (Button, text="Close"); assign exports `_damage_button → DamageButton`, `_close_button → CloseButton`; then go to `magicforge.tscn` and assign `_upgrade_screen_scene → res://scenes/hub/forgeupgradescreen.tscn`

**Checkpoint**: Magic Forge upgrade screen fully functional — damage upgrade purchasable, max detection works, close returns to hub. US2 complete.

---

## Phase 5: User Story 3 — Player Cannot Afford Restoration (Priority: P3)

**Goal**: When the player has fewer than 120 shards, the "Restore the Forge" button in the overlay is disabled/non-functional.

**Independent Test**: Start with < 120 shards, tap Ruined Forge — overlay opens, "Restore the Forge" button is visually disabled and pressing it has no effect.

### Implementation for User Story 3

US3 is fully covered by the `_restore_button.disabled = not MetaManager.can_spend(cost)` line in T006 (RestoreForgeOverlay.gd). No new implementation tasks required.

- [ ] T012 [US3] Verify affordability guard — manually test with < 120 shards that restore button is disabled; verify `MetaManager.purchase_magic_forge()` also returns false as a server-side guard (belt-and-suspenders)

**Checkpoint**: All affordability states correct. US3 validated.

---

## Phase 6: Hub Integration (Editor)

**Purpose**: Wire MagicForge into HubRoom, remove the old UpgradeShop.

- [ ] T013 **EDITOR** — Open `scenes/hub/HubRoom.tscn` in Godot Editor; delete the inline `UpgradeShop` node (and all its children: ColorRect, Button). This removes the ungated damage upgrade button.
- [ ] T014 **EDITOR** — Still in `HubRoom.tscn`: instance `scenes/hub/magicforge.tscn` as a new child of HubRoom; set its local position to `(0, -350)` (top-center of hub); confirm the MagicForge Inspector exports are all assigned (from T009)
- [x] T015 Delete orphaned file `scenes/hub/UpgradeShop.gd` — no longer referenced by any scene after T013

**Checkpoint**: HubRoom.tscn contains MagicForge at top-center; old UpgradeShop removed; HubRoom.gd unchanged.

---

## Phase 7: Polish & Validation

- [ ] T016 [P] Manual validation — full unlock flow: start with ≥120 shards → tap Ruined Forge → overlay appears → tap "Restore" → shards deducted, visual switches to grey "Magic Forge" → leave hub → return to hub → still shows Magic Forge (persistence confirmed)
- [ ] T017 [P] Manual validation — upgrade flow: with forge unlocked → tap Magic Forge → upgrade screen opens directly (no overlay) → purchase damage upgrade → level increments → cost updates → at max level "MAX" shown → Close returns to hub
- [ ] T018 [P] Manual validation — "Maybe Later" closes overlay with no side effects; forge remains Ruined
- [ ] T019 [P] Manual validation — with < 120 shards, "Restore the Forge" button is disabled in overlay

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 2 (Foundational)**: No dependencies — start immediately; T001, T002, T003 can run in parallel; T004 depends on T002; T005 depends on T003
- **Phase 3 (US1)**: Depends on Phase 2 complete; T006 and T007 [P]; T008 depends on T006; T009 depends on T007 and T008
- **Phase 4 (US2)**: Depends on Phase 2; T010 [P] alongside Phase 3; T011 depends on T010 and T009
- **Phase 5 (US3)**: Covered by T006; only validation remains (T012)
- **Phase 6 (Hub Integration)**: Depends on T009 and T011; T013 before T014; T015 after T013
- **Phase 7 (Validation)**: Depends on Phase 6 complete

### Parallel Opportunities

```
# Phase 2 parallel start:
T001 (meta_config.json)
T002 (MetaState.gd)         → T004 (SaveManager.gd)
T003 (MetaManagerImpl.gd)   → T005 (MetaManager autoload)

# Phase 3+4 parallel (once Phase 2 done):
T006 (RestoreForgeOverlay.gd)  → T008 (restoreforgeoverlay.tscn)  → T009 (magicforge.tscn)
T007 (MagicForge.gd)           ↗                                                    ↓
T010 (ForgeUpgradeScreen.gd) → T011 (forgeupgradescreen.tscn + assign in magicforge.tscn)

# Phase 7 all parallel:
T016, T017, T018, T019
```

---

## Implementation Strategy

### MVP (User Story 1 + Foundation only)

1. Complete Phase 2 (Foundational) — T001–T005
2. Complete Phase 3 (US1 scripts) — T006–T007
3. Complete Phase 3 (US1 editor tasks) — T008–T009
4. Complete Phase 6 (Hub Integration) — T013–T015
5. **STOP and VALIDATE**: Ruined Forge in hub, overlay works, unlock works
6. Then add Phase 4 (US2) for upgrade screen

### Notes

- T008, T009, T011, T013, T014 are Godot Editor tasks — must be done in Godot, not via code edits
- T015 is a file deletion — confirm T013 is done first so no scene references UpgradeShop.gd
- `HubRoom.gd` requires no code changes — MagicForge is fully self-contained
