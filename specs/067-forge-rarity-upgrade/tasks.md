# Tasks: Forge Rarity Upgrade

**Input**: Design documents from `/specs/067-forge-rarity-upgrade/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Data config and persistence layer — required before any runtime or UI work.

- [x] T001 Add `rarity_luck_upgrade` entry to `data/meta_config.json` under `magic_forge.upgrades` with fields `name: "Rarity Luck"`, `cost: 350`, `promotion_chance: 0.1`
- [x] T002 Add `var rarity_luck_owned: bool = false` field to `scripts/data_models/MetaState.gd` (after `missile_extra_charge_owned`)
- [x] T003 [P] Add `"rarity_luck_owned": state.rarity_luck_owned` to `save_meta_state()` dict in `scripts/managers/SaveManager.gd`
- [x] T004 [P] Add `state.rarity_luck_owned = bool((parsed as Dictionary).get("rarity_luck_owned", false))` to `load_meta_state()` in `scripts/managers/SaveManager.gd`

**Checkpoint**: MetaState and save/load now support `rarity_luck_owned`. Run the game, trigger a save, confirm the new key appears in `user://meta_save.json`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Purchase API must exist before the UI and draw logic can reference it.

⚠️ **CRITICAL**: Phase 3 (draw logic) and Phase 4 (UI) cannot be tested end-to-end until this phase is complete.

- [x] T005 Add `purchase_rarity_luck(cost: int, save_manager: Node) -> bool` to `scripts/managers/MetaManagerImpl.gd` — guard on `meta_state.rarity_luck_owned`; deduct cost; set flag; save; return success (follow `purchase_missile_extra_charge` pattern exactly)
- [x] T006 Add `var is_rarity_luck_owned: bool` computed property to `autoload/MetaManager.gd` (getter: `return _impl.meta_state.rarity_luck_owned`) after `is_missile_extra_charge_owned`
- [x] T007 Add `purchase_rarity_luck() -> bool` delegating method to `autoload/MetaManager.gd` — reads cost from `meta_config` path `magic_forge.upgrades.rarity_luck_upgrade.cost` (default 350), delegates to `_impl`, emits `shards_changed` on success (follow `purchase_missile_extra_charge` pattern)

**Checkpoint**: In DevPanel or via code, call `MetaManager.purchase_rarity_luck()` with sufficient shards. Confirm `MetaManager.is_rarity_luck_owned` is `true` and save file contains `"rarity_luck_owned": true`.

---

## Phase 3: User Story 1 + 2 — Draw Promotion Logic (Priority: P1)

**Goal**: When `rarity_luck_owned` is true, each relic draw in standard and elite rooms has a 10% chance to draw from the next rarity tier. Both stories share the same draw-logic changes.

**Independent Test**: Use the GUT unit test (T008–T013). Set `promotion_chance = 1.0` to force promotions; verify tier of returned relics. Set `promotion_chance = 0.0`; verify no promotion occurs.

### Unit Tests for Draw Logic

- [x] T008 Create `tests/unit/test_relic_rarity_upgrade.gd` with GUT `class_name TestRelicRarityUpgrade extends GutTest`. Build a minimal `RelicManagerImpl` instance and call `build_pool()` with inline dict stubs (2–3 relics per tier) — **no autoloads**
- [x] T009 [P] In `test_relic_rarity_upgrade.gd`: add test `test_next_tier_common` — assert `_impl._next_tier("common") == "uncommon"`
- [x] T010 [P] In `test_relic_rarity_upgrade.gd`: add test `test_next_tier_uncommon` — assert `_impl._next_tier("uncommon") == "rare"`
- [x] T011 [P] In `test_relic_rarity_upgrade.gd`: add test `test_next_tier_rare` — assert `_impl._next_tier("rare") == ""`
- [x] T012 [P] In `test_relic_rarity_upgrade.gd`: add test `test_no_promotion_when_chance_zero` — call `draw_offer("common", 0.0)` 20 times; assert all returned relics have `tier == "common"`
- [x] T013 [P] In `test_relic_rarity_upgrade.gd`: add test `test_promotion_when_chance_one` — call `draw_offer("common", 1.0)` 10 times; assert all returned relics have `tier == "uncommon"`
- [x] T014 [P] In `test_relic_rarity_upgrade.gd`: add test `test_promotion_fallback_when_next_tier_empty` — build pool with only `common` relics (no `uncommon`); call `draw_offer("common", 1.0)` 10 times; assert all relics have `tier == "common"` (no crash, no empty result)
- [x] T015 [P] In `test_relic_rarity_upgrade.gd`: add test `test_offer_cards_are_distinct` — call `draw_offer("common", 1.0)` 20 times; assert each 2-card result has `result[0].id != result[1].id`
- [x] T016 [P] In `test_relic_rarity_upgrade.gd`: add test `test_elite_promotion_uncommon_to_rare` — call `draw_offer("uncommon", 1.0)` 10 times; assert all returned relics have `tier == "rare"`

### Implementation for Draw Logic

- [x] T017 Add private `_next_tier(tier: String) -> String` method to `scripts/managers/RelicManagerImpl.gd` — `match` on `"common"` → `"uncommon"`, `"uncommon"` → `"rare"`, default → `""`
- [x] T018 Add private `_draw_one_with_promotion(base_tier: String, promotion_chance: float) -> RelicData` method to `scripts/managers/RelicManagerImpl.gd` — guard: if `promotion_chance > 0.0`, get `next = _next_tier(base_tier)`, check non-empty and `randf() < promotion_chance`, attempt `_draw_one_from_tier(next)`, return if non-null; fall through to `_draw_one_from_tier(base_tier)`
- [x] T019 Update `draw_offer(tier: String) -> Array[RelicData]` in `scripts/managers/RelicManagerImpl.gd` to `draw_offer(tier: String, promotion_chance: float = 0.0) -> Array[RelicData]`; replace the two `_draw_one_from_tier(tier)` calls with `_draw_one_with_promotion(tier, promotion_chance)`; change the de-dup strip to use `left.tier` instead of `tier` so copies are stripped from the deck that `left` was actually drawn from
- [x] T020 Update `autoload/RelicManager.gd` `_on_room_cleared()` — refactor to early-return style (Constitution VI): move `should_offer_for_room` check to a guard; read `promotion_chance` from `ResourceManager.get_meta_config()` path `magic_forge.upgrades.rarity_luck_upgrade.promotion_chance` (default `0.1`) when `MetaManager.is_rarity_luck_owned`, else `0.0`; pass `promotion_chance` as second argument to `_impl.draw_offer(tier, promotion_chance)`; add `promotion={p}` to the print statement

**Checkpoint**: Run GUT tests T009–T016. All should now pass. In-game: own the upgrade via DevPanel shard grant + purchase; clear several standard rooms; confirm uncommon relics appear in offers ~10% of draws.

---

## Phase 4: User Story 1 — Forge UI (Priority: P1)

**Goal**: The "Rarity Luck" upgrade entry appears in the Forge upgrade screen with correct state display (purchasable / owned / insufficient shards).

**Independent Test**: Open the Forge screen. Verify the button shows "Rarity Luck — 350 shards". With insufficient shards: button is disabled. With sufficient shards: button enabled; press it; entry changes to "Rarity Luck — Purchased"; shards decrease by 350.

### Implementation for Forge UI

- [x] T021 Add `@export var _rarity_luck_button: Button` to `scenes/hub/ForgeUpgradeScreen.gd` (after `_missile_charge_button`)
- [x] T022 In `ForgeUpgradeScreen._ready()`, add: `_rarity_luck_button.pressed.connect(_on_rarity_luck_buy)`
- [x] T023 In `ForgeUpgradeScreen._update_buttons()`, add call: `_update_rarity_luck_button()`
- [x] T024 Add `_update_rarity_luck_button()` method to `scenes/hub/ForgeUpgradeScreen.gd` — read `name` and `cost` from `ResourceManager.get_meta_config()` path `magic_forge.upgrades.rarity_luck_upgrade`; if `MetaManager.is_rarity_luck_owned`: set text to `"{n} — Purchased"`, disable; elif `MetaManager.can_spend(cost)`: set text to `"{n} — {c} shards"`, enable; else: set text to `"{n} — {c} shards (insufficient)"`, disable
- [x] T025 Add `_on_rarity_luck_buy()` method to `scenes/hub/ForgeUpgradeScreen.gd` — call `MetaManager.purchase_rarity_luck()`, then `_update_buttons()`
- [ ] T026 **EDITOR TASK** — Open `scenes/hub/ForgeUpgradeScreen.tscn` in the Godot Editor; add a new `Button` node as a sibling of the existing `MissileChargeButton` (same parent container); name it `RarityLuckButton`; select the root `ForgeUpgradeScreen` node → Inspector → assign `RarityLuckButton` to the `_rarity_luck_button` export slot; save the scene

**Checkpoint**: Launch game, visit hub, open Forge screen. All three button states (purchasable, owned, insufficient) work correctly. Purchase persists after restarting the game.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T027 [P] Verify `trigger_offer()` in `autoload/RelicManager.gd` (DevPanel path) still passes `draw_offer("common")` with no second argument — confirm the default `0.0` promotion_chance applies and DevPanel behavior is unchanged
- [x] T028 [P] Verify `trigger_boss_offer()` in `scripts/managers/RelicManagerImpl.gd` is unaffected — it uses `draw_boss_offer()` which bypasses `draw_offer()` entirely; no change needed; add a comment confirming this
- [x] T029 Print statement audit: confirm the updated `_on_room_cleared` log includes `promotion=` field so draw promotion is observable in Output panel during testing

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately. T003 and T004 are parallel (different lines in same file, no conflict).
- **Phase 2 (Foundational)**: Depends on Phase 1 (T002 must exist before T005 references `meta_state.rarity_luck_owned`). T005 → T006 → T007 in sequence.
- **Phase 3 (Draw Logic)**: Depends on Phase 2 complete. Tests T008–T016 written first; T017–T020 implement against them.
- **Phase 4 (Forge UI)**: Depends on Phase 2 complete (`MetaManager.is_rarity_luck_owned` and `purchase_rarity_luck()` must exist). T021–T025 can run after Phase 2; T026 is an editor task that can proceed after T021–T025.
- **Phase 5 (Polish)**: Depends on Phases 3 and 4 complete.

### User Story Dependencies

- **US1 + US2 (draw promotion)**: Phase 3 — depends on Phase 2 only. Tests confirm correctness.
- **US1 (Forge UI)**: Phase 4 — depends on Phase 2 only. Can be worked alongside Phase 3.
- **US3 (elite promotion)**: Covered by T016 in Phase 3 (same draw_offer code path, different base tier).

### Within Phase 3

- T008 (test scaffold) → T009–T016 (individual tests, all parallel) → confirm tests FAIL → T017 → T018 → T019 → T020 → re-run tests to confirm pass

---

## Parallel Execution Examples

### Phase 1
```
T001 (meta_config.json) — independent
T002 (MetaState.gd)     — independent
T003 (SaveManager save) — independent of T004
T004 (SaveManager load) — independent of T003
```

### Phase 3 Tests (after T008 scaffold exists)
```
T009 test_next_tier_common
T010 test_next_tier_uncommon
T011 test_next_tier_rare
T012 test_no_promotion_when_chance_zero
T013 test_promotion_when_chance_one
T014 test_promotion_fallback_when_next_tier_empty
T015 test_offer_cards_are_distinct
T016 test_elite_promotion_uncommon_to_rare
```

### Phase 3 Implementation (sequential)
```
T017 (_next_tier) → T018 (_draw_one_with_promotion) → T019 (draw_offer update) → T020 (RelicManager update)
```

### Phase 4 (after Phase 2)
```
T021–T025 (script changes, sequential within file) → T026 (editor task, after script)
```

---

## Implementation Strategy

### MVP Scope (User Story 1 only)

1. Complete Phase 1 (T001–T004)
2. Complete Phase 2 (T005–T007)
3. Complete Phase 3 draw logic (T008–T020)
4. Complete Phase 4 Forge UI (T021–T026)
5. **VALIDATE**: Purchase upgrade → clear rooms → confirm uncommon relics appear in standard room offers

### Full Feature Scope

All phases in order. US3 (elite promotion to rare) is covered automatically by Phase 3 — no additional tasks needed beyond T016.

---

## Notes

- T003/T004 edit the same file (`SaveManager.gd`) but different methods — safe to do in one edit pass; marked [P] because they are logically independent.
- T026 is an editor-only task and cannot be automated via script; it blocks the Phase 4 checkpoint.
- `draw_boss_offer()` in `RelicManagerImpl` draws directly from the `rare` pool and never calls `draw_offer()` — it is unaffected by this feature and requires no changes.
- The `trigger_offer()` DevPanel method passes `"common"` to `draw_offer()` with no second argument — the `promotion_chance = 0.0` default ensures no promotion in DevPanel flows.
