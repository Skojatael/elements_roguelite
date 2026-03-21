# Tasks: Forest Domain Unlock

**Input**: Design documents from `/specs/076-forest-domain-unlock/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Tasks grouped by user story. US1 = forest relics gated. US2 = purchase UI in Book of Skill.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: US1 or US2

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data schema, persistence, and MetaManager purchase method. Both user stories depend on this.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 [P] Add `forest_domain` upgrade entry to `data/meta_config.json` under `book_of_skill.upgrades` with keys `"name": "Forest Domain"` and `"cost": 40`, matching the Mage Tower upgrade nesting structure.
- [x] T002 [P] Add `var forest_domain_unlocked: bool = false` to `scripts/data_models/MetaState.gd` after the `book_of_skill_owned` field.
- [x] T003 In `scripts/managers/SaveManager.gd`, add `"forest_domain_unlocked": state.forest_domain_unlocked` to the `save_meta_state` dict, and add `state.forest_domain_unlocked = bool(parsed.get("forest_domain_unlocked", false))` in `load_meta_state`. Depends on T002.
- [x] T004 Add `func purchase_forest_domain(cost: int, save_manager: Node) -> bool` to `scripts/managers/MetaManagerImpl.gd`. Guard: if `meta_state.forest_domain_unlocked` return false. Call `spend(cost, save_manager)`, set `meta_state.forest_domain_unlocked = true` on success, return result. Follows the same pattern as `purchase_book_of_skill`. Depends on T002, T003.
- [x] T005 In `autoload/MetaManager.gd`, add computed property `var is_forest_domain_unlocked: bool` delegating to `meta_state.forest_domain_unlocked`. Add delegating method `purchase_forest_domain() -> bool` that reads cost from `ResourceManager.get_meta_config().get("book_of_skill", {}).get("upgrades", {}).get("forest_domain", {}).get("cost", 40)` and calls `_impl.purchase_forest_domain(cost, SaveManager)`. Depends on T004.

**Checkpoint**: MetaState, persistence, and purchase logic are complete. Both stories can proceed.

---

## Phase 3: User Story 1 — Forest Relics Blocked Until Unlocked (Priority: P1) 🎯 MVP

**Goal**: Forest relics are excluded from the relic offer pool when the upgrade is not owned, and included when it is.

**Independent Test**: Start a run without the upgrade. Clear rooms until a relic offer appears — verify no forest relics (Venom Fang / Rootweave Band) appear. Grant the upgrade via MetaManager directly and start a new run — verify forest relics can now appear in offers.

### Tests for User Story 1

- [x] T006 [P] [US1] Create `tests/unit/test_relic_manager_impl_forest_domain.gd` extending `GutTest`. Preload `RelicManagerImpl`. Use an inline relics dict with `"domain": {"forest": {"root_relic": {"tier": "common", ...}}, "neutral": {"common_damage": {"tier": "common", ...}}}` and an empty config dict. Test: (a) `build_pool(relics, config, false)` → `_relics_by_id` does NOT contain `"root_relic"`, `_all_by_tier["common"]` does not include any forest relic; (b) `build_pool(relics, config, true)` → `_relics_by_id` DOES contain `"root_relic"`.

### Implementation for User Story 1

- [x] T007 [US1] In `scripts/managers/RelicManagerImpl.gd`, add `forest_domain_unlocked: bool` as a third parameter to `build_pool(relics_raw, _config_raw, forest_domain_unlocked)`. Inside the domain iteration loop (over `relics_raw.get("domain", {}).keys()`), add the guard `if domain_str == "forest" and not forest_domain_unlocked: continue` before processing relics from that domain. Depends on T005 (for the autoload caller update).
- [x] T008 [US1] In `autoload/RelicManager.gd`, update the `build_pool` call in `_on_run_started()` from `_impl.build_pool(ResourceManager.get_relics(), ResourceManager.get_meta_config())` to `_impl.build_pool(ResourceManager.get_relics(), ResourceManager.get_meta_config(), MetaManager.is_forest_domain_unlocked)`. Depends on T005, T007.

**Checkpoint**: Forest relics are included/excluded correctly at run start based on upgrade ownership.

---

## Phase 4: User Story 2 — Purchase the Upgrade in Book of Skill (Priority: P2)

**Goal**: Book of Skill interior shows a Forest Domain upgrade entry. Player can purchase it for 40 shards. Button disables after purchase ("Unlocked") and state persists.

**Independent Test**: Open Book of Skill with < 40 shards — button is disabled. Add shards to reach 40 — button enables. Purchase — shards deducted, button shows "Unlocked". Close and reopen — still shows "Unlocked".

### Tests for User Story 2

- [x] T009 [P] [US2] Create `tests/unit/test_meta_manager_impl_forest_domain.gd` extending `GutTest`. Preload `MetaManagerImpl`. Use a stub `MetaState.new()`. Test: (a) `purchase_forest_domain(40, null)` when `forest_domain_unlocked = false` and `total_shards >= 40` → returns `true`, `meta_state.forest_domain_unlocked == true`, shards deducted; (b) same call when already owned → returns `false`, no state change; (c) call when `total_shards < 40` → returns `false`, flag stays `false`. Use a stub SaveManager node that no-ops save (pass `null` and guard in impl, or create a minimal stub).

### Implementation for User Story 2

- [x] T010 [US2] In `scenes/hub/BookOfSkillInterior.gd`, add `@export var _forest_button: Button` and `@export var _forest_label: Label`. In `_ready()`, connect `MetaManager.shards_changed` to `func(_n: int) -> void: _update_ui()` and connect `_forest_button.pressed` to `func() -> void: MetaManager.purchase_forest_domain(); _update_ui()`. Call `_update_ui()` at the end of `_ready()`. Implement `_update_ui() -> void`: read cost from config, set `_forest_label.text` to display name and cost, set `_forest_button.disabled = true` and `_forest_button.text = "Unlocked"` when `MetaManager.is_forest_domain_unlocked`, otherwise set `_forest_button.disabled = not MetaManager.can_spend(cost)` and `_forest_button.text = "Unlock ({cost} shards)".format({"cost": cost})`. Depends on T005.
- [ ] T011 [US2] In the Godot Editor, open `scenes/hub/BookOfSkillInterior.tscn`. Add a `Label` node (`_forest_label`) and a `Button` node (`_forest_button`) to the interior layout, positioned below the existing Close button or in a suitable VBoxContainer. Assign both nodes to their corresponding `@export var` slots on the `BookOfSkillInterior` script.

**Checkpoint**: All four acceptance scenarios for US2 are verifiable in-editor.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T012 Run existing unit tests to confirm no regressions in `RelicManagerImpl` or `MetaManagerImpl` from the signature and field changes.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: T001 and T002 can start in parallel immediately. T003 → T004 → T005 are sequential.
- **US1 (Phase 3)**: T006 (test) can start in parallel with T007 after T005. T008 depends on T007.
- **US2 (Phase 4)**: T009 (test) can start in parallel with T010 after T005. T011 (editor) can start after T010 exports are defined.
- **Polish (Phase 5)**: After T008 and T011.

### User Story Dependencies

- **US1**: Depends on full Foundational phase (T001–T005). Independent of US2.
- **US2**: Depends on full Foundational phase (T001–T005). Independent of US1.
- US1 and US2 can be worked in parallel once Foundational is done.

### Parallel Opportunities

- T001 ‖ T002 (data file vs data model)
- T006 ‖ T009 (different test files, both after T005)
- T007 ‖ T010 (different files, both after T005)

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. T001 + T002 in parallel
2. T003 → T004 → T005
3. T006 (write test, verify fail) → T007 → T008
4. **Validate**: start a run without upgrade, confirm no forest relics in offers

### Full Delivery

1. Foundational (T001–T005)
2. US1 (T006–T008) ‖ US2 (T009–T011)
3. Polish (T012)
