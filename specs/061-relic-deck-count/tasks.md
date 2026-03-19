# Tasks: Relic Deck Count

**Input**: Design documents from `/specs/061-relic-deck-count/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, quickstart.md ✅

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2)

---

## Phase 1 & 2: Setup / Foundational

**Purpose**: No project initialization or new infrastructure required. This feature modifies three existing files only. No new autoloads, scenes, or directories are created.

*Proceed directly to user story phases.*

---

## Phase 3: User Story 2 — Rename `sharp_edge` → `common_damage` (Priority: P1)

**Goal**: Replace the `sharp_edge` relic ID with `common_damage` in `data/relics.json`. All stats (name, tier, effect, description) remain unchanged. This phase is a prerequisite for Phase 4 because `deck_count` values will reference the renamed key.

**Independent Test**: Open `data/relics.json`. Confirm `"sharp_edge"` key is absent. Confirm `"common_damage"` key exists under `"common"` with `effect_stat: "attack_damage"`, `effect_mult: 1.10`, and the name `"Whetstone"`.

- [x] T001 [US2] Rename the `"sharp_edge"` key to `"common_damage"` in `data/relics.json` under `relics.common` — change only the key, leave all field values unchanged

**Checkpoint**: `sharp_edge` is gone. `common_damage` exists with identical stats. No `.gd` code changes needed.

---

## Phase 4: User Story 1 — Deck Count Field (Priority: P1)

**Goal**: Add `deck_count: int` to `RelicData`, populate it in `relics.json` for all 12 relics, and update `RelicManagerImpl` to expand the draw deck by that count so higher-count relics appear proportionally more often in offers.

**Independent Test**: Start a run via DevPanel. Trigger multiple relic offers. Confirm `common_damage` (Whetstone) appears noticeably more often than `common_regen` (Regeneration Stone) across 10+ offers. Confirm no `sharp_edge` references appear in logs.

### Tests for User Story 1

- [x] T002 [P] [US1] Add `deck_count`-aware test cases to `tests/unit/test_relic_deck.gd`:
  - Add a new `STUB_RELICS_DECK` constant with `"relic_a"` having `deck_count: 3` and `"relic_b"` having `deck_count: 1` (all other fields identical to `STUB_RELICS`)
  - Test `_build_expanded_deck("common")` returns an array of size 4 (3+1) when two relics have counts 3 and 1
  - Test that `_build_expanded_deck("common", "relic_a")` returns only `relic_b` entries (exclude_id respected)
  - Test that a relic with `deck_count: 0` does not appear in the built deck
  - Test that existing `STUB_RELICS` (no `deck_count` field) defaults all relics to count 1 — existing deck-exhaustion test still passes with 3 draws = 3 distinct relics
  - Test that after deck exhaustion, refill via `_draw_one_from_tier` produces the same expanded ratio (draw many times, confirm count-3 relic appears ~3× more than count-1 relic over 30 draws)

### Implementation for User Story 1

- [x] T003 [P] [US1] Add `var deck_count: int = 1` field to `scripts/data_models/RelicData.gd` and add `r.deck_count = int(data.get("deck_count", 1))` in `from_dict`

- [x] T004 [US1] Add `deck_count` values to all relic entries in `data/relics.json` (depends on T001 for correct key name):
  - `common_damage`: 3
  - `swift_strike`: 3
  - `iron_hide`: 3
  - `feather`: 3
  - `common_regen`: 1
  - `chaining_stone`: 1
  - `burn`: 1
  - `crit_projectile`: 1
  - `rage_crystal`: 1
  - `vital_core`: 1
  - `berserker_stone`: 1
  - `executioners_mark`: 1

- [x] T005 [US1] Add `_build_expanded_deck(tier: String, exclude_id: String = "") -> Array[RelicData]` helper to `scripts/managers/RelicManagerImpl.gd` (depends on T003 for `RelicData.deck_count`):
  - Iterate `_all_by_tier[tier]`; skip any entry whose `id == exclude_id`
  - For each relic, append it `r.deck_count` times to the result array
  - Shuffle result before returning

- [x] T006 [US1] Update `build_pool` in `scripts/managers/RelicManagerImpl.gd` to replace the manual shuffle loop with `_build_expanded_deck` (depends on T005):
  - Replace the loop that does `deck.assign(_all_by_tier[tier])` + `deck.shuffle()` with `_decks[str(tier)] = _build_expanded_deck(str(tier))`

- [x] T007 [US1] Update `_draw_one_from_tier` refill path in `scripts/managers/RelicManagerImpl.gd` to use `_build_expanded_deck` (depends on T005):
  - Replace `refill.assign(_all_by_tier[tier])` + `refill.shuffle()` + `_decks[tier] = refill` with `_decks[tier] = _build_expanded_deck(tier)`

- [x] T008 [US1] Update `draw_offer` de-dup refill path in `scripts/managers/RelicManagerImpl.gd` to use `_build_expanded_deck` (depends on T005):
  - Replace the manual `for r in _all_by_tier[tier]: if r.id != left.id: refill.append(r)` + `refill.shuffle()` block with `_decks[tier] = _build_expanded_deck(tier, left.id)`

**Checkpoint**: All three `RelicManagerImpl` refill/build sites use `_build_expanded_deck`. `RelicData.deck_count` is populated. JSON has all 12 values set. Tests pass.

---

## Phase 5: Polish & Validation

**Purpose**: End-to-end verification and documentation consistency.

- [ ] T009 Run GUT unit tests for `tests/unit/test_relic_deck.gd` and confirm all existing tests still pass alongside the new `deck_count` tests
- [ ] T010 Follow `quickstart.md` manual verification: start a run via DevPanel, trigger 10+ relic offers, confirm `common_damage` (Whetstone) appears more frequently than `common_regen` (Regeneration Stone)


---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 3 (US2)**: No dependencies — start immediately
- **Phase 4 (US1)**: T003 can start in parallel with Phase 3 (different file). T004 depends on T001 (Phase 3 complete). T005 depends on T003. T006–T008 depend on T005 and run sequentially (same file). T002 (test) can be written before or after implementation.
- **Phase 5**: Depends on Phase 4 complete

### User Story Dependencies

- **US2 (Phase 3)**: Independent — rename only
- **US1 (Phase 4)**: Logically depends on US2 (T004 needs the renamed key) but T003 and T005 are independent of US2

### Within Phase 4

```
T003 ──────────────────────────── T005 → T006 → T007 → T008
T001 (Phase 3) ── T004 ──────────────────────────────────┘
T002 (tests) — write anytime, run after T008
```

### Parallel Opportunities

- T001 (JSON rename) and T003 (RelicData field) — different files, run together
- T002 (new tests) can be authored before implementation is complete (write first, expect failure)

---

## Parallel Example: Phase 4 Start

```text
# Start these together after Phase 3:
T003 — Add deck_count field to RelicData.gd
T004 — Add deck_count values to relics.json (after T001)

# Then sequentially in RelicManagerImpl.gd:
T005 → T006 → T007 → T008
```

---

## Implementation Strategy

### MVP (All work is P1 — ship together)

1. T001 — Rename JSON key
2. T003 — Add RelicData field (parallel with T001)
3. T004 — Add JSON values (after T001)
4. T005 → T006 → T007 → T008 — Implement expanded deck (after T003)
5. T002 → T009 — Add and run tests
6. T010 — Manual validation

### Total Tasks: 10

| Phase | Tasks | Count |
|---|---|---|
| US2 - Rename | T001 | 1 |
| US1 - Deck Count | T002–T008 | 7 |
| Polish | T009–T010 | 2 |

---

## Notes

- [P] tasks operate on different files with no cross-dependency — safe to run simultaneously
- T002 (tests) should be written before T005–T008 where possible (TDD)
- `_all_by_tier` intentionally stays as a unique list (one entry per relic) — boss offers use it directly. Only `_decks` gets the expanded representation
- No scene or editor work in this feature — all changes are JSON and GDScript only
- Commit order suggestion: T001+T003 together (data layer), then T004, then T005–T008 (impl), then T002+T009 (tests), then T010 (validation)
