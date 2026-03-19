# Tasks: Additive-Multiplicative Modifier Stacking

**Input**: Design documents from `/specs/063-additive-multiplicative-modifiers/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup (Shared Infrastructure)

*No setup tasks required. No new files, no new JSON schemas, no new autoloads.*

---

## Phase 2: Foundational (Blocking Prerequisites)

*No foundational blocking tasks. The single code change in `RelicManagerImpl` is self-contained.*

---

## Phase 3: User Story 1 — Relic Bonuses Stack Additively (Priority: P1) 🎯 MVP

**Goal**: `compute_stat_mult` returns the additive relic factor (`1.0 + Σ(effect_mult − 1.0)`) instead of the multiplicative product. Two ×1.10 relics yield 1.20 instead of 1.21.

**Independent Test**: In GUT, call `compute_stat_mult("attack_damage")` on a `RelicManagerImpl` instance with two relics each having `effect_mult = 1.10` and assert the result equals `1.20`.

### Tests for User Story 1

> **Write these tests FIRST, ensure they FAIL before the implementation change.**

- [x] T001 [US1] Write unit tests for additive stacking in `tests/unit/test_modifier_stacking.gd` covering: (a) two ×1.10 relics → 1.20, (b) three ×1.10 relics → 1.30, (c) zero relics → 1.0, (d) one relic → equals `effect_mult`, (e) only matching-stat relics contribute (mixed-stat guard)

### Implementation for User Story 1

- [x] T002 [US1] Change `compute_stat_mult` in `scripts/managers/RelicManagerImpl.gd` to use early-return guard pattern and sum `(effect_mult − 1.0)` per matching relic, returning `1.0 + bonus_sum` (see plan.md for before/after code)

**Checkpoint**: T001 tests must now pass. Two ×1.10 relics produce 1.20.

---

## Phase 4: User Story 2 — Cross-Source Bonuses Multiply (Priority: P1)

**Goal**: Confirm that the relic factor (now additive) and the meta upgrade factor multiply correctly across sources. No code changes needed — calling code in `CombatComponent` is already correct. This phase is test-only.

**Independent Test**: In GUT, set up a `RelicManagerImpl` with two ×1.10 relics and simulate `MetaManager.damage_multiplier = 1.10` (one upgrade level); assert `base × 1.10 × compute_stat_mult("attack_damage")` = `base × 1.32`.

### Tests for User Story 2

- [x] T003 [US2] Add cross-source multiplication test to `tests/unit/test_modifier_stacking.gd`: two ×1.10 relics + simulated 1.10 upgrade multiplier → combined factor 1.32 (= 1.20 × 1.10). Use a local float variable for the upgrade factor (no autoload dependency).
- [x] T004 [P] [US2] Add edge-case test: zero relics + upgrade multiplier → final factor equals upgrade multiplier only (no regression).

**Checkpoint**: Stacking formula verified end-to-end. Cross-source multiplication confirmed correct.

---

## Phase 5: User Story 3 — Rule Applies to All Affected Stats (Priority: P2)

**Goal**: Confirm all seven moddable stats produce correct results. `attack_damage`, `attack_speed`, `max_health`, `move_speed` use the now-additive `compute_stat_mult`. `crit_chance`, `crit_multiplier`, `damage_reduction` already use `compute_stat_addend` (additive, unchanged) — covered by regression tests here.

**Independent Test**: For each of the seven stats, two identical relics produce an additive combined bonus (not a multiplicative one).

### Tests for User Story 3

- [x] T005 [P] [US3] Add `compute_stat_mult` coverage tests to `tests/unit/test_modifier_stacking.gd` for each remaining stat: two ×1.15 `max_health` relics → 1.30; two ×1.15 `move_speed` relics → 1.30; two ×1.10 `attack_speed` relics → 1.20.
- [x] T006 [P] [US3] Add `compute_stat_addend` regression tests to `tests/unit/test_modifier_stacking.gd` confirming the already-additive stats are unaffected: two `crit_chance` relics (+0.20 each) → 0.40 total; two `damage_reduction` relics (+0.10 each) → 0.20 total; two `crit_multiplier` relics (+0.10 each) → 0.20 total.

**Checkpoint**: All seven stats verified. No regressions in addend-path stats.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [ ] T007 Run all tests via GUT and confirm zero failures: `tests/unit/test_modifier_stacking.gd` and all pre-existing tests in `tests/unit/test_relic_deck.gd`
- [ ] T008 Run quickstart.md manual verification checklist in-editor: confirm two `common_damage` relics + one upgrade level → `attack_damage = base × 1.32`
<!-- T007 and T008 require the Godot editor / GUT runner — manual steps -->

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1–2**: Skipped (no tasks)
- **Phase 3 (US1)**: No prerequisites — start immediately
- **Phase 4 (US2)**: Depends on T002 (compute_stat_mult changed) before tests can pass
- **Phase 5 (US3)**: Can start in parallel with Phase 4 after T002 is done
- **Phase 6 (Polish)**: Depends on all prior phases complete

### User Story Dependencies

- **US1 (P1)**: No dependencies — implement first
- **US2 (P1)**: Depends on T002 (US1 implementation) — tests build on changed function
- **US3 (P2)**: Depends on T002 (US1 implementation) — regression tests require changed function

### Parallel Opportunities

- T003 and T004 are independent of each other (both read-only test additions)
- T005 and T006 are independent of each other (different stat paths)
- T007 and T008 can start together once all test tasks complete

---

## Parallel Execution Example: After T002 is complete

```
# These can be written in parallel (all add to same test file, non-conflicting test cases):
T003 — cross-source multiplication test
T004 — zero-relics edge case
T005 — mult-path stat coverage (max_health, move_speed, attack_speed)
T006 — addend-path regression (crit_chance, crit_multiplier, damage_reduction)
```

---

## Implementation Strategy

### MVP First (US1 only — 2 tasks)

1. Write T001 tests (expect failures)
2. Implement T002 (one function body change)
3. **STOP and VALIDATE**: T001 tests now pass

### Full Delivery (all stories — 8 tasks total)

1. T001 → T002 (US1 complete)
2. T003 + T004 in parallel (US2 complete)
3. T005 + T006 in parallel (US3 complete)
4. T007 + T008 (Polish complete)

---

## Notes

- Total tasks: **8**
- Tasks per story: US1 → 2, US2 → 2, US3 → 2, Polish → 2
- Parallel opportunities: T003/T004 together; T005/T006 together; T007/T008 together
- No editor work required (no scenes, no Inspector assignments)
- `effect_mult` values in `relics.json` remain unchanged — no data migration
- `CombatComponent`, `StatsComponent`, `MovementComponent` untouched
