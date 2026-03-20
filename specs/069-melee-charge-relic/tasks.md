# Tasks: Melee Charge Relic

**Input**: Design documents from `/specs/069-melee-charge-relic/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 2: Foundational (Blocking Prerequisite)

**Purpose**: JSON relic entry must exist before pool machinery can include the relic, and before any unit test can load a fixture that mirrors production data.

**⚠️ CRITICAL**: Complete before Phase 3.

- [x] T001 Add `"melee_missile_charge"` entry to `data/relics.json` under `"common"` — fields: `name: "Arcane Knuckles"`, `tags: ["projectile", "melee"]`, `effect_stat: ""`, `effect_mult: 1.0`, `condition_type: ""`, `condition_threshold: 3.0`, `condition_mult: 1.0`, `description: "Every 3 melee hits restore 1 Magic Missile charge."`, `deck_count: 2`

**Checkpoint**: JSON entry committed — pool can now draw this relic.

---

## Phase 3: User Story 1 — 3rd Melee Hit Grants Extra Charge (Priority: P1) 🎯 MVP

**Goal**: `RelicManagerImpl.on_melee_hit()` tracks a per-run counter and returns `true` on every 3rd hit when the relic is held. `SkillComponent` grants an extra charge when it receives `true`.

**Independent Test**: Acquire relic via DevPanel, perform 3 melee attacks; charge count on hit 3 increases by 2 (baseline +1 unconditional, +1 relic). Hits 1-2 each increase by 1 only.

### Tests for User Story 1

- [x] T002 [P] [US1] Create `tests/unit/test_melee_charge_relic.gd` — GUT test suite for `RelicManagerImpl.on_melee_hit()`: (a) returns `false` for hit 1, `false` for hit 2, `true` for hit 3, then `false` for hit 4 (counter reset verified); (b) returns `false` on every call when `"melee_missile_charge"` is not in `active_relic_ids`; (c) calling `on_melee_hit()` while relic absent does not corrupt counter when relic is later added. Use inline dict fixture to call `build_pool()` with a minimal relics JSON containing only `"melee_missile_charge"`.

### Implementation for User Story 1

- [x] T003 [US1] In `scripts/managers/RelicManagerImpl.gd`: add `const MELEE_CHARGE_RELIC_ID: String = "melee_missile_charge"` and `var _melee_hit_count: int = 0`; add `_melee_hit_count = 0` to `reset()`; add `on_melee_hit() -> bool` — early-return `false` if relic not in `active_relic_ids`; read threshold via `(_relics_by_id[MELEE_CHARGE_RELIC_ID] as RelicData).condition_threshold`; increment `_melee_hit_count`; if `_melee_hit_count >= threshold` reset to 0 and return `true`; else return `false`. (Depends on T001 for relic data to exist at runtime; unit tests use fixture so T001 not a hard blocker for T002.)
- [x] T004 [US1] In `autoload/RelicManager.gd`: add `on_melee_hit() -> bool` thin-wrapper method that returns `_impl.on_melee_hit()`. (Depends on T003.)
- [x] T005 [US1] In `scenes/player/components/SkillComponent.gd`, extend `_on_melee_hit_landed()`: after the existing unconditional +1 charge block, add a second block — call `RelicManager.on_melee_hit()` and, if it returns `true` and `_current_charges < _max_charges`, increment `_current_charges` by 1 and emit `charges_changed`. (Depends on T004.)

**Checkpoint**: US1 fully functional. Relic mechanic works in-game.

---

## Phase 4: User Story 2 — Relic Appears in Common Offer Pool (Priority: P1)

**Goal**: The new relic is a valid candidate when drawing common-tier offers. Standard duplicate-exclusion applies.

**Independent Test**: Trigger a post-clear relic offer; `"melee_missile_charge"` is a possible result. After picking it, it is no longer offered.

### Tests for User Story 2

- [x] T006 [P] [US2] In `tests/unit/test_melee_charge_relic.gd`, add test: after `build_pool()` with the fixture dict, call `draw_offer("common")` in a loop and assert `"melee_missile_charge"` appears at least once within 20 draws. Also verify `active_relic_ids = ["melee_missile_charge"]` causes the relic to be absent from subsequent draws (duplicate exclusion via deck rebuild). (Depends on T001 fixture data.)

**Checkpoint**: US2 verified — the relic participates in the standard pool draw.

---

## Phase 5: User Story 3 — Counter Resets at Run End (Priority: P2)

**Goal**: The melee-hit counter does not carry over between runs. A partially-advanced counter (e.g., 2 hits in) is zeroed when `reset()` is called.

**Independent Test**: `RelicManagerImpl.reset()` zeroes `_melee_hit_count` regardless of its value before the call.

### Tests for User Story 3

- [x] T007 [US3] In `tests/unit/test_melee_charge_relic.gd`, add test: call `on_melee_hit()` twice (counter at 2, returns `false` both times), then call `reset()`, then call `on_melee_hit()` twice more — assert neither returns `true` (counter restarted from 0, not continuing from 2). (Depends on T003.)

**Checkpoint**: All three user stories verified. Counter lifecycle is correct.

---

## Phase 6: Polish & Validation

- [ ] T008 Manual in-game validation: start run, use DevPanel to grant `"melee_missile_charge"` relic, perform 1 melee attack (charges +1 only), perform 2nd attack (+1 only), perform 3rd attack (+2 total: unconditional +1 and relic +1). Repeat cycle; confirm 6th attack also yields +2. Confirm behaviour with zero relics held (every hit = +1, no extras).

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately.
- **US1 (Phase 3)**: T002 (tests) can start after T001. T003 depends on T001 for runtime (but not for unit tests). T004 depends on T003. T005 depends on T004.
- **US2 (Phase 4)**: T006 can run in parallel with Phase 3 implementation tasks after T001.
- **US3 (Phase 5)**: T007 depends on T003.
- **Polish (Phase 6)**: Depends on T001–T005 all complete.

### Parallel Opportunities

- T002 and T006 can both be written in parallel once T001 is done (both only read the fixture).
- T003, T004, T005 must run sequentially (each depends on the previous).
- T007 can be written any time after T003.

---

## Implementation Strategy

### MVP (US1 + US2)

1. T001 — add JSON entry
2. T002 — write failing tests
3. T003 → T004 → T005 — implement logic (tests should now pass)
4. T006 — verify pool behaviour
5. T008 — manual smoke test

### Full Delivery

Add T007 (US3 counter-reset test) after T003 to complete all user stories.

---

## Notes

- `condition_threshold: 3.0` in JSON is the only balance constant — tune it there without touching GDScript.
- The unconditional charge restore in `_on_melee_hit_landed()` is NOT modified — relic logic is purely additive.
- `deck_count: 2` matches other common relics that should appear with moderate frequency.
