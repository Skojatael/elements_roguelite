# Research: Unique Relic Offers

**Feature**: 025-unique-relic-offers
**Date**: 2026-03-03

---

## Decision 1: How to guarantee the two drawn relics are different

**Decision**: Sequential draw with exhaustion-refill-excluding-left between draws.

**Mechanism**:
1. Draw left relic via `_draw_one()` — pops it from its tier deck.
2. If that tier's deck is now exhausted: refill it from `_all_by_tier[left.tier]` **excluding** `left.id`, then shuffle. This leaves the deck ready for any right draw that lands on the same tier, with the left relic absent.
3. Draw right relic via `_draw_one()` — unchanged. Uniqueness is structurally guaranteed: if right lands on the same tier as left, left relic is not in that deck; if right lands on a different tier, left relic was never in that deck.

**Why this works given FR-003**: Every tier has 2+ relics. After excluding left relic from the exhaustion-refill, the deck always has at least 1 relic remaining. No empty-deck-after-exclusion case can occur.

**Rationale**: No ID comparison, no retry loop, no post-draw filtering. Uniqueness emerges from deck state. `_draw_one()` is unchanged. The exclusion-refill only executes when a tier deck is exhausted — uncommon in practice (requires exhausting a full tier cycle first).

**Alternatives considered**:
- Post-draw ID comparison with retry: simpler to describe but introduces a loop with unbounded retries in degenerate cases.
- Force different tier for right draw: violates FR-004 (distorts tier weight distribution).
- Tag left relic as temporarily excluded via a parameter to `_draw_one()`: works but leaks offer-level logic into a lower-level method.

---

## Decision 2: What happens to the size() == 1 special case in draw_offer()

**Decision**: Remove it.

**Rationale**: FR-003 requires every tier to have 2+ relics, so the total pool is always at least 2. The `_relics_by_id.size() == 1` path is now unreachable under valid configuration. The `is_empty()` guard (0 relics) is kept.

---

## Decision 3: Where the exclusion-refill lives

**Decision**: Inside `draw_offer()`, between the two `_draw_one()` calls.

**Rationale**: The exclusion is offer-scoped — it must not persist beyond the current offer. `draw_offer()` owns the offer lifecycle and is the correct place to orchestrate it. `_draw_one()` remains a pure single-draw method with no awareness of offer context.
