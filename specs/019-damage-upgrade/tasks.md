# Tasks: Damage Multiplier Upgrade

**Input**: Design documents from `specs/019-damage-upgrade/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Data model and config extensions that ALL user stories depend on. Must be complete before any user story work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T001 [P] Add `damage_upgrade` config block to `data/meta_config.json` (base_cost: 50, cost_scale: 1.2, max_levels: 10, damage_per_level: 0.1)
- [X] T002 [P] Add `var damage_upgrade_level: int = 0` to `scripts/data_models/MetaState.gd`

**Checkpoint**: Config and data model ready — all user story phases can now begin.

---

## Phase 2: User Story 1 — Purchase a Damage Upgrade in the Hub (Priority: P1) 🎯 MVP

**Goal**: Player sees an upgrade button in the hub, can tap to buy levels with shards, button updates reactively, shows MAX state at level 10.

**Independent Test**: Enter hub with ≥50 shards. Tap button. Confirm balance drops by 50, button shows "Damage Multiplier — 60 shards". Purchase until level 10, confirm "Damage Multiplier — MAX" and button is disabled.

### Implementation

- [X] T003 [P] [US1] Add `get_upgrade_cost()`, `purchase_damage_upgrade()`, and `get_damage_multiplier()` methods to `scripts/managers/MetaManager.gd` (MetaManagerImpl) per contracts/interfaces.md
- [X] T004 [P] [US1] Add `damage_multiplier` computed property, `get_next_upgrade_cost()`, and `purchase_damage_upgrade()` to `autoload/MetaManager.gd` per contracts/interfaces.md
- [X] T005 [US1] Create `scenes/hub/UpgradeShop.gd` — `extends Control`, `@export var _button: Button`, implement `_ready()`, `_update_button()`, `_on_buy_pressed()` per contracts/interfaces.md (depends on T003, T004)
- [ ] T006 [US1] Add UpgradeShop to `scenes/hub/HubRoom.tscn` in Godot Editor: add `Control` child named `UpgradeShop`, attach `UpgradeShop.gd`, add `Button` child named `Button`, assign `_button` export in Inspector, set Mouse Filter = Pass on Control, position below ShardDisplay

**Checkpoint**: US1 complete — purchase flow fully testable in hub (shard deduction, button state, MAX state, reactive update on `shards_changed`).

---

## Phase 3: User Story 2 — Upgrade Persists Across Sessions (Priority: P2)

**Goal**: `damage_upgrade_level` is written to `user://meta_save.json` on purchase and read back on game launch. Progress survives restarts.

**Independent Test**: Purchase 2 levels. Quit game. Relaunch. Enter hub. Confirm button shows cost for level 3 (72 shards), not level 1 (50 shards).

### Implementation

- [X] T007 [US2] Update `save_meta_state()` and `load_meta_state()` in `scripts/managers/SaveManager.gd` to include `damage_upgrade_level` in the JSON dict; use `.get("damage_upgrade_level", 0)` for backward compatibility

**Checkpoint**: US2 complete — upgrade level persists across game restarts.

---

## Phase 4: User Story 3 — Upgrade Affects Player Damage in Runs (Priority: P3)

**Goal**: At run start, `CombatComponent.attack_damage` is set to `_base_attack_damage × MetaManager.damage_multiplier`. Multiplier is additive from base (level 3 = ×1.3, not compounding).

**Independent Test**: Purchase level 1. Start a run. Verify damage = base × 1.1. Purchase level 3 total. Start another run. Verify damage = base × 1.3 (not 1.1³ = 1.331).

### Implementation

- [X] T008 [US3] Add `_base_attack_damage: float`, cache it in `_ready()`, connect `RunManager.run_started` signal, and add `_apply_damage_multiplier()` to `scenes/player/components/CombatComponent.gd` per contracts/interfaces.md

**Checkpoint**: US3 complete — all three user stories fully functional.

---

## Phase 5: Polish & Validation

- [ ] T009 Run all 12 manual validation scenarios from `specs/019-damage-upgrade/quickstart.md` and confirm each passes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: No dependencies — start immediately. Both T001 and T002 are parallel.
- **US1 (Phase 2)**: Requires Phase 1 complete. T003 and T004 are parallel; T005 depends on T003+T004; T006 (editor) depends on T005.
- **US2 (Phase 3)**: Requires Phase 1 complete (MetaState field must exist). Independent of US1 code but purchase won't persist until T007 is done.
- **US3 (Phase 4)**: Requires Phase 1 complete (config needed for `damage_multiplier`). Independent of US1 and US2 code.
- **Polish (Phase 5)**: Requires all user stories complete.

### User Story Dependencies

- **US1 (P1)**: Foundational → T003 [P] + T004 [P] → T005 → T006 (editor)
- **US2 (P2)**: Foundational → T007
- **US3 (P3)**: Foundational → T008

### Parallel Opportunities

- T001 + T002 (foundational): parallel, different files
- T003 + T004 (impl + autoload): parallel, different files
- After Phase 1: US1, US2, and US3 can all start simultaneously (if capacity allows)

---

## Parallel Example: After Foundational Phase

```
# T003 and T004 can run together:
Task A: Implement MetaManagerImpl methods in scripts/managers/MetaManager.gd
Task B: Implement autoload wrappers in autoload/MetaManager.gd

# Separately and simultaneously with US1:
Task C (US2): Update SaveManager in scripts/managers/SaveManager.gd
Task D (US3): Update CombatComponent in scenes/player/components/CombatComponent.gd
```

---

## Implementation Strategy

### MVP (US1 Only)

1. Complete Phase 1 (Foundational)
2. Complete Phase 2 (US1 — purchase + hub UI)
3. **Validate**: Purchase flow works in hub (button, cost, MAX state)
4. Note: without T007 (US2), purchases won't persist across restarts — acceptable for MVP validation

### Full Delivery

1. Phase 1 → Phase 2 (US1) → Phase 3 (US2) → Phase 4 (US3) → Phase 5 (validation)
2. Each phase independently testable before moving on

---

## Notes

- T006 is a Godot Editor task (cannot be done via code) — open `scenes/hub/HubRoom.tscn`, add Control + Button child nodes, attach script, assign @export in Inspector.
- US2 (T007) should be completed before end-to-end testing of persistence scenarios (quickstart.md Scenario 6).
- `_base_attack_damage` in CombatComponent must always cache the Inspector-assigned value — never the post-multiplier value.
- `get_upgrade_cost(level, base, scale)` iterates `floori(float(prev) * scale)` starting from `base_cost`, `level` times (level 0 returns base_cost unchanged).
