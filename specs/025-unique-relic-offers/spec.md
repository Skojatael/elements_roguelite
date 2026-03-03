# Feature Specification: Unique Relic Offers

**Feature Branch**: `025-unique-relic-offers`
**Created**: 2026-03-03
**Status**: Draft
**Input**: User description: "two relics offered should be different"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Offer Always Shows Two Distinct Relics (Priority: P1)

When a relic offer appears, the player sees two different relics to choose from. The same relic never appears on both cards in a single offer.

**Why this priority**: Seeing two identical relics is confusing and makes the choice meaningless. This is the entire value of the feature.

**Independent Test**: Trigger relic offers 30 times across a run. Inspect every offer — both cards must always show different relics (different names/descriptions).

**Acceptance Scenarios**:

1. **Given** a relic offer is triggered, **When** the offer screen appears, **Then** the left card and right card show two different relics.
2. **Given** a relic offer is triggered repeatedly, **When** inspecting all offers across a run, **Then** no offer ever shows the same relic on both cards.

---

### Edge Cases

- **Very few relics (2 total across all tiers)**: offer must still show both distinct relics, never the same one twice.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When a relic offer contains two cards, the two relics MUST have different IDs.
- **FR-002**: The uniqueness constraint MUST hold regardless of which tiers the two draws land in.
- **FR-003**: Every tier in the relic data MUST contain at least 2 distinct relics. A tier with fewer than 2 relics is invalid configuration and MUST NOT be shipped.
- **FR-004**: The uniqueness guarantee MUST NOT change the weighted tier distribution in any statistically meaningful way — both draws should still reflect the configured tier weights.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Across 100 consecutive relic offers, 0% show the same relic on both cards.
- **SC-002**: The tier distribution across offers remains within expected tolerance of the configured weights (±5%) — uniqueness enforcement does not visibly skew rarity.

## Assumptions

- "Different" means different relic IDs — two relics with the same effect but different IDs are considered different.
- FR-003 is a data integrity rule enforced at content authoring time. The current relic data already satisfies it (common: 4, uncommon: 4, rare: 2).
