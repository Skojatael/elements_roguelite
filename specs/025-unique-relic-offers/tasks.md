# Tasks: Unique Relic Offers

**Input**: Design documents from `specs/025-unique-relic-offers/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

---

## Phase 1: User Story 1 — Offer Always Shows Two Distinct Relics (Priority: P1) 🎯 MVP

**Goal**: The two relics in every offer are always different.

**Independent Test**: Press "Get Relic" 30 times across a run — no offer ever shows the same relic on both cards.

- [X] T001 [US1] Rewrite `draw_offer()` in `scripts/managers/RelicManagerImpl.gd` — replace `return [_draw_one(), _draw_one()]` and the `size() == 1` branch with: draw left via `_draw_one()`; if `_decks[left.tier]` is empty, refill it from `_all_by_tier[left.tier]` filtering out `left.id` then shuffle; draw right via `_draw_one()`; return `[left, right]` (see contracts/interfaces.md for exact code)

---

## Phase 2: Polish

- [ ] T002 Run all 4 quickstart scenarios from `specs/025-unique-relic-offers/quickstart.md`

---

## Dependencies & Execution Order

- T001 has no dependencies — start immediately
- T002 requires T001 complete

## Implementation Strategy

1. T001 — rewrite `draw_offer()`
2. T002 — validate
