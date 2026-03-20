# Tasks: Relic Mechanic Unlock Tags

**Input**: Design documents from `specs/064-relic-mechanic-unlock/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅

**Organization**: Tasks grouped by user story. No setup phase required — all work is in-place modifications to existing files.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Foundational (Blocking Prerequisites)

**Purpose**: JSON data and the new impl methods must exist before any story-level draw behaviour can be verified.

**⚠️ CRITICAL**: US1, US2, and US3 all depend on this phase.

- [x] T001 Add `burn_damage` and `chain_reach` relic entries (with `_unlocked` tags) to `data/relics.json` under the `"uncommon"` tier

- [x] T00X Add `_activated_mechanics: Array[String]` and `_mechanic_tag_names: Array[String]` fields to `scripts/managers/RelicManagerImpl.gd`; extend `reset()` to clear both fields

- [x] T00X Add `_compute_mechanic_tags()` private method to `scripts/managers/RelicManagerImpl.gd`; call it at the end of `build_pool()` — scans `_relics_by_id.values()` for `_unlocked`-suffixed tags and populates `_mechanic_tag_names`

- [x] T00X Add `_is_relic_eligible(r: RelicData) -> bool` private method to `scripts/managers/RelicManagerImpl.gd` — returns `false` if any `_unlocked` tag's prerequisite mechanic is not in `_activated_mechanics`, or if any mechanic tag is already in `_activated_mechanics`

**Checkpoint**: `_mechanic_tag_names` computed from JSON, `_activated_mechanics` cleared on reset, eligibility predicate implemented. Ready for per-story tasks.

---

## Phase 2: User Story 1 — Picking a Mechanic Relic Unlocks Follow-up Relics (Priority: P1) 🎯 MVP

**Goal**: Picking `burn` activates the mechanic; subsequent deck reshuffles exclude `burn` and include `burn_damage`.

**Independent Test**: Build a stub pool with `burn` + `burn_damage`; call `pick_relic("burn")`; call `_build_expanded_deck("uncommon")`; assert `burn` absent and `burn_damage` present.

### Tests for User Story 1

> **Write tests FIRST — confirm they FAIL before implementation**

- [x] T00X [P] [US1] Add test stub `STUB_RELICS_MECHANIC` (burn/burn_damage/chain/chain_reach/generic) and test `test_unlocked_relic_absent_before_mechanic_activated` to `tests/unit/test_relic_deck.gd` — verify `burn_damage` is not in the initial deck (no mechanics active)

- [x] T00X [P] [US1] Add `test_mechanic_tag_names_computed_from_pool` to `tests/unit/test_relic_deck.gd` — after `build_pool(STUB_RELICS_MECHANIC)`, assert `_impl._mechanic_tag_names` contains `"burn"` and `"chain"` but not `"combat"`

### Implementation for User Story 1

- [x] T00X [US1] Extend `pick_relic(relic_id)` in `scripts/managers/RelicManagerImpl.gd` to inspect the picked relic's tags via `_relics_by_id`; for each tag that is in `_mechanic_tag_names`, append it to `_activated_mechanics` (guard: skip if already present); print `[RelicManager] mechanic activated — tag={tag}`

- [x] T00X [US1] Add eligibility guard inside the `for r` loop of `_build_expanded_deck()` in `scripts/managers/RelicManagerImpl.gd`: `if not _is_relic_eligible(r): continue` (placed before the `deck_count` inner loop)

- [x] T00X [US1] Add `test_mechanic_relic_excluded_after_activation` to `tests/unit/test_relic_deck.gd` — `pick_relic("burn")`, call `_build_expanded_deck("uncommon")`, assert `burn` is absent from result

- [x] T0XX [US1] Add `test_unlocked_relic_present_after_mechanic_activated` to `tests/unit/test_relic_deck.gd` — `pick_relic("burn")`, call `_build_expanded_deck("uncommon")`, assert `burn_damage` is present in result

**Checkpoint**: US1 independently verifiable via GUT tests — pick burn → burn gone, burn_damage appears.

---

## Phase 3: User Story 2 — Mechanic Exclusion Resets on New Run (Priority: P2)

**Goal**: `_activated_mechanics` and `_mechanic_tag_names` are empty after `reset()`; a fresh `build_pool()` restores all mechanic relics and excludes all `_unlocked` relics.

**Independent Test**: Call `pick_relic("burn")`, then `reset()` + `build_pool()`; assert `_activated_mechanics` is empty and `burn` is back in the deck while `burn_damage` is absent.

### Tests for User Story 2

- [x] T0XX [US2] Add `test_activated_mechanics_cleared_on_reset` to `tests/unit/test_relic_deck.gd` — `pick_relic("burn")`, assert `_activated_mechanics` has `"burn"`, then `reset()`; assert `_activated_mechanics` is empty and `_mechanic_tag_names` is empty

- [x] T0XX [US2] Add `test_mechanic_relic_returns_after_reset_and_rebuild` to `tests/unit/test_relic_deck.gd` — `pick_relic("burn")`, `reset()`, `build_pool(STUB_RELICS_MECHANIC)`, `_build_expanded_deck("uncommon")`; assert `burn` present and `burn_damage` absent

**Checkpoint**: US2 independently verifiable — reset + rebuild returns pool to initial state.

---

## Phase 4: User Story 3 — Multiple Independent Mechanic Pairs Coexist (Priority: P3)

**Goal**: Activating `burn` does not affect `chain` or `chain_reach`; activating both activates both `_unlocked` relics.

**Independent Test**: `pick_relic("burn")` only; assert `chain` eligible and `chain_reach` not eligible. Then `pick_relic("chain")`; assert `chain_reach` eligible.

### Tests for User Story 3

- [x] T0XX [US3] Add `test_non_mechanic_tag_does_not_activate_mechanic` to `tests/unit/test_relic_deck.gd` — `pick_relic("generic")` (tags: `["combat"]`); assert `_activated_mechanics` is empty (no `_unlocked` counterpart for `"combat"`)

- [x] T0XX [P] [US3] Add `test_mechanic_pairs_independent_burn_does_not_affect_chain` to `tests/unit/test_relic_deck.gd` — `pick_relic("burn")`; `_build_expanded_deck("uncommon")`; assert `chain` present and `chain_reach` absent

- [x] T0XX [P] [US3] Add `test_mechanic_pairs_independent_chain_does_not_affect_burn` to `tests/unit/test_relic_deck.gd` — `pick_relic("chain")`; `_build_expanded_deck("uncommon")`; assert `burn` present and `burn_damage` absent

- [x] T0XX [US3] Add `test_both_mechanics_unlock_both` to `tests/unit/test_relic_deck.gd` — `pick_relic("burn")`, `pick_relic("chain")`, `_build_expanded_deck("uncommon")`; assert `burn_damage` present and `chain_reach` present; assert `burn` absent and `chain` absent

**Checkpoint**: All three user stories independently verifiable. Full GUT suite should be green.

---

## Phase 5: Polish & Cross-Cutting Concerns

- [x] T0XX Extend `draw_boss_offer()` in `scripts/managers/RelicManagerImpl.gd` to also apply `_is_relic_eligible()` filtering alongside the existing `active_relic_ids.has(r.id)` guard (FR-008 compliance for boss offer path)

- [x] T0XX Add `test_boss_offer_excludes_unlocked_relic_when_mechanic_inactive` to `tests/unit/test_relic_deck.gd` — pool with rare `burn_unlocked` relic; no mechanic active; assert it is absent from `draw_boss_offer()` result

- [x] T0XX Run full GUT suite (`tests/unit/test_relic_deck.gd`) and confirm all existing tests still pass (regression check)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: No dependencies — start immediately. T001–T004 can run in parallel (different concerns within the same file; take care of ordering if editing same file sequentially).
- **Phase 2 (US1)**: Depends on T001–T004. T005–T006 (tests) can be written in parallel with T007–T008 (impl).
- **Phase 3 (US2)**: Depends on Phase 1 only. Can start independently of Phase 2 (US2 tests only exercise `reset()` + `build_pool()` which exist after Phase 1).
- **Phase 4 (US3)**: Depends on Phase 1 only. T014 and T015 are independent of each other.
- **Phase 5 (Polish)**: Depends on Phases 2–4 being complete.

### Within Each User Story

- Write tests first → confirm they FAIL → implement → confirm tests PASS.
- Phase 1 T001 (JSON) must precede T003 (`_compute_mechanic_tags`) because `build_pool` needs `_unlocked` entries in the JSON to populate `_mechanic_tag_names`.

### Parallel Opportunities

- T005 and T006 (US1 tests) can be written in parallel.
- T014 and T015 (US3 independence tests) are fully independent.
- T011 and T012 (US2 tests) are independent of each other.
- After Phase 1 completes, US1/US2/US3 phases can be worked in parallel.

---

## Parallel Example: Phase 1

```
Parallel group A (data): T001 — extend relics.json
Parallel group B (fields): T002 — new fields + reset extension
Parallel group C (methods): T003 + T004 — _compute_mechanic_tags, _is_relic_eligible
  (T003/T004 depend on T002 for the new fields; T001 is independent)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Foundational (T001–T004)
2. Complete Phase 2: User Story 1 (T005–T010)
3. **STOP and VALIDATE**: Run GUT on `test_relic_deck.gd`; start run in-editor, pick `burn`, trigger next offer — `burn_damage` should appear.
4. Proceed to Phase 3–5 for full feature coverage.

### Incremental Delivery

1. Phase 1 → foundational state tracking in place
2. Phase 2 (US1) → mechanic unlock works mid-run → testable MVP
3. Phase 3 (US2) → confirmed reset across runs
4. Phase 4 (US3) → multi-pair independence verified
5. Phase 5 → boss offer compliance + regression

---

## Notes

- No scenes or autoloads modified. All work is `RelicManagerImpl.gd`, `relics.json`, and `test_relic_deck.gd`.
- `burn_damage` and `chain_reach` are pool-eligibility stubs — their actual combat effects (FR-008 defers runtime behaviour) are out of scope.
- The `_is_relic_eligible` predicate is pure and side-effect-free, making it trivially unit-testable via `_build_expanded_deck` output inspection.
- Commit after each logical unit: JSON change, impl methods, test group.
