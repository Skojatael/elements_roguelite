# Tasks: Close Relic Offer on Run End

**Input**: Design documents from `specs/028-close-offer-on-run-end/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

---

## Phase 1: User Story 1 — Relic Offer Dismissed When Run Ends (Priority: P1) 🎯 MVP

**Goal**: The relic offer CanvasLayer is freed at the start of `_on_run_ended()` if it is open, so the results screen appears cleanly with no overlapping UI.

**Independent Test**: Open a relic offer via DevPanel "Get Relic" → while offer is visible press DevPanel "End Run" → verify offer disappears and results screen appears with no UI overlap or errors.

- [X] T001 [US1] In `_on_run_ended()` in `scenes/core/Main.gd`, add a null-guard block immediately before the existing `if is_instance_valid(_hub_room):` check: `if _relic_offer_layer != null: _relic_offer_layer.queue_free(); _relic_offer_layer = null; _relic_offer_screen = null` (see contracts/interfaces.md for exact code and placement)

---

## Phase 2: Polish

- [ ] T002 Run all 5 quickstart scenarios from `specs/028-close-offer-on-run-end/quickstart.md`

---

## Dependencies & Execution Order

- T001 has no dependencies — start immediately
- T002 requires T001 complete

## Implementation Strategy

1. T001 — add guard block (4 lines)
2. T002 — validate all 5 scenarios
