# Tasks: Depth Scaling Gate

**Input**: Design documents from `/specs/085-depth-scaling-gate/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Foundational phase gates both user stories. US1 and US2 share the same implementation — the "off-state" (US2) is an inherent result of the gating logic introduced in US1 and is covered by the same unit tests.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: Schema changes and MetaManagerImpl purchase logic that must land before any runtime behavior is wired.

**⚠️ CRITICAL**: No US1/US2 work can begin until this phase is complete.

- [x] T001 [P] Add `depth_scaling` entry to `data/meta_config.json` — inside `mage_tower.upgrades`, add `"depth_scaling": { "name": "Depth Scaling", "cost": 300 }` after the `boss_challenge` entry
- [x] T002 [P] Add `var depth_scaling_unlocked: bool = false` as the last field in `scripts/data_models/MetaState.gd`
- [x] T003 Update `scripts/managers/SaveManager.gd` — add `"depth_scaling_unlocked": state.depth_scaling_unlocked` to the save dict and `state.depth_scaling_unlocked = bool(parsed.get("depth_scaling_unlocked", false))` to the load block (depends on T002)
- [x] T004 Add `purchase_depth_scaling(cost: int, save_manager: Node) -> bool` to `scripts/managers/MetaManager.gd` (MetaManagerImpl) — same guard-clause pattern as existing boolean-flag purchase methods: return false if `meta_state.depth_scaling_unlocked` is already true or `can_spend(cost)` fails; otherwise deduct shards, set flag true, save (depends on T002)

**Checkpoint**: MetaState carries the new field, save/load round-trips it, and the purchase logic is testable without autoloads.

---

## Phase 2: User Story 1 — Unlock Scaling in Mage Tower (Priority: P1) 🎯 MVP

**Goal**: Player can purchase the Depth Scaling upgrade from the Mage Tower screen; once purchased, dungeon difficulty and essence rewards scale with depth per the pre-existing formulas.

**Independent Test**: Grant 300 shards via DevPanel, open Mage Tower, purchase Depth Scaling, run a dungeon to depth 4, confirm enemies are stronger and essence per kill is higher than at depth 1. Without shards or before purchase, everything stays flat.

### Unit Tests

- [x] T005 [P] [US1] Write `tests/unit/test_depth_scaling_gate.gd` — preload `MetaManagerImpl`; create an instance with a stub `MetaState`; cover: (a) `purchase_depth_scaling()` succeeds and sets flag when shards sufficient; (b) `purchase_depth_scaling()` returns false when already owned; (c) `purchase_depth_scaling()` returns false when shards insufficient; (d) flag defaults to false on a fresh MetaState (depends on T004)

### Implementation

- [x] T006 [US1] Add `var is_depth_scaling_unlocked: bool` computed property (getter: `_impl.meta_state.depth_scaling_unlocked`) and delegating `purchase_depth_scaling() -> bool` method (reads cost from `meta_config.json` at `mage_tower.upgrades.depth_scaling.cost` with default 300, calls `_impl.purchase_depth_scaling(cost, SaveManager)`, emits `shards_changed` on success) to `autoload/MetaManager.gd` (depends on T004)
- [x] T007 [P] [US1] Gate `difficulty_mult` in `scripts/dungeon/DungeonGenerator.gd` `_record_room()` — replace the single `difficulty_mult` assignment with: `1.0 + difficulty_scale * float(depth)` when `MetaManager.is_depth_scaling_unlocked` is true, otherwise `1.0` (depends on T006)
- [x] T008 [P] [US1] Gate essence depth factor in `scripts/managers/RunManager.gd` `_on_enemy_defeated()` — introduce `var effective_depth: int = current_room_depth if MetaManager.is_depth_scaling_unlocked else 1` before the essence formula; substitute `effective_depth` for `current_room_depth` in the existing formula (depends on T006)
- [x] T009 [US1] Add `@export var _ds_button: Button` and append a fourth entry to the `_entries` array in `scenes/hub/MageTowerUpgradeScreen.gd` — entry: `upgrades.get("depth_scaling", {}).merged({"button": _ds_button, "owned_prop": "is_depth_scaling_unlocked", "purchase": MetaManager.purchase_depth_scaling})` (depends on T001, T006)
- [ ] T010 [US1] Add `DepthScalingButton` Button node as a child of the upgrade list container in `scenes/hub/MageTowerUpgradeScreen.tscn` via the Godot Editor; assign it to the `_ds_button` export on `MageTowerUpgradeScreen` in the Inspector (depends on T009)

**Checkpoint**: Mage Tower upgrade screen shows the Depth Scaling entry; purchase deducts shards and persists; rooms at depth 4+ have difficulty_mult > 1.0 and award scaled essence after purchase; all rooms have difficulty_mult = 1.0 and flat essence before purchase.

---

## Phase 3: User Story 2 — Flat Rewards for New Players (Priority: P2)

**Goal**: Verify the ungated state is correct — no depth scaling when the upgrade has not been purchased.

**Independent Test**: Start a fresh save (or set `depth_scaling_unlocked = false`), run to depth 4, confirm essence per kill equals base essence and enemy HP equals base HP.

This story has no additional implementation tasks — the off-state is an inherent consequence of the guards added in Phase 2. It is validated by the unit tests in T005 (flag defaults false) and by gameplay verification outlined above.

**Checkpoint**: T005 tests pass with flag off; gameplay confirms flat difficulty and flat essence before upgrade.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 1)**: T001 and T002 can run in parallel; T003 and T004 both depend on T002.
- **US1 (Phase 2)**: All tasks depend on Phase 1 completion. T005 depends on T004. T006 depends on T004. T007 and T008 depend on T006 and can run in parallel. T009 depends on T001 and T006. T010 depends on T009.
- **US2 (Phase 3)**: No additional implementation; covered by T005 and gameplay verification.

### Parallel Opportunities

- T001 and T002 can be done simultaneously (different files).
- T003 and T004 can be done simultaneously (different files), both depending on T002.
- T005 (unit test) and T006 (autoload) can start simultaneously once T004 is done.
- T007 (DungeonGenerator gate) and T008 (RunManager gate) can be done simultaneously once T006 is done.

---

## Implementation Strategy

### MVP (All in one pass — feature is small)

1. Complete Phase 1 (T001–T004): schema + persistence + impl purchase
2. Complete Phase 2 (T005–T010): autoload + runtime gates + UI + editor
3. Run T005 unit tests; verify they pass
4. Manual gameplay test: flat before purchase, scaled after purchase

---

## Notes

- [P] tasks = different files, no dependencies between them
- T010 is an Editor task — open `MageTowerUpgradeScreen.tscn` in Godot, add the Button, save via Editor
- The Boss room HP scaling (rooms-cleared formula) is intentionally **not** gated by this upgrade; no changes to `Main._on_boss_teleport_pressed()`
- Mid-run purchase is architecturally impossible (upgrades require the hub); dungeon difficulty is baked at run start, so the "next room" edge case does not require special handling
