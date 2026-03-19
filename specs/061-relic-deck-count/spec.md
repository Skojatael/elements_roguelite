# Feature Specification: Relic Deck Count

**Feature Branch**: `061-relic-deck-count`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "add relic parameter in relic.json that equals to amount of cards of this type in deck. example: regen - base amount 1, sharp_edge - base amount 3 (btw, rename sharp_edge is to common_damage)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tune How Often Each Relic Appears (Priority: P1)

Each relic has a `deck_count` value that determines how many copies of it exist in the shared offer pool. When the game draws relics to show the player, it samples from this pool — so a relic with `deck_count: 3` is three times as likely to appear as one with `deck_count: 1`. This lets designers directly express "common damage boost should appear often, regeneration should appear rarely" through a single, readable number rather than opaque probability weights.

**Why this priority**: Without `deck_count`, the draw pool has no tuning knob for relative frequency. All relics appear equally often, which is almost never the design intent.

**Independent Test**: Check that the relic data file contains a `deck_count` field on every relic entry with the specified values. Observe many relic offers and confirm that relics with higher counts appear noticeably more often than those with count 1.

**Acceptance Scenarios**:

1. **Given** `common_damage` has `deck_count: 3` and `common_regen` has `deck_count: 1`, **When** many relic offers are drawn, **Then** `common_damage` appears roughly three times as often as `common_regen`.
2. **Given** any relic is missing a `deck_count` field, **When** the game builds the offer pool, **Then** that relic does not appear in any offer (or the game logs a clear error — no silent inclusion with a default).
3. **Given** a relic has `deck_count: 1`, **When** an offer is drawn, **Then** the relic can appear but is the least common representation in the pool.

---

### User Story 2 - Rename `sharp_edge` to `common_damage` (Priority: P1)

The relic previously identified as `sharp_edge` is renamed to `common_damage`. This is a data correction — the new ID is more descriptive of what the relic does (+10% attack damage) and aligns with the naming conventions used by other common relics.

**Why this priority**: The rename is a prerequisite for any consistency in relic IDs and should ship together with `deck_count` to avoid a second migration later.

**Independent Test**: Open the relic data file and confirm `sharp_edge` no longer exists. Confirm `common_damage` exists with the same stats (attack_damage, +10%, common tier).

**Acceptance Scenarios**:

1. **Given** the relic data is loaded, **When** the system looks up `sharp_edge`, **Then** no entry is found.
2. **Given** the relic data is loaded, **When** the system looks up `common_damage`, **Then** the entry is found with `effect_stat: "attack_damage"`, `effect_mult: 1.10`, and `deck_count: 3`.
3. **Given** a save file that stored `sharp_edge` as an active relic, **When** the save is loaded, **Then** the relic is treated as absent (no crash; missing IDs are silently dropped on load).

---

### Edge Cases

- What if a relic's `deck_count` is set to 0? That relic should never appear in offers. It is effectively disabled without being deleted from the data file.
- What if the same relic is already held by the player and also has multiple copies in the pool? Existing de-duplication logic (already-held relics excluded from offers) still applies; `deck_count` only affects the initial pool construction, not the filtering stage.
- What happens for relics whose counts are not explicitly specified by the designer? Default assumption is `deck_count: 1` — but the recommended practice is to set it explicitly for every relic.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every relic entry in the relic data file MUST include a `deck_count` integer field with a value of 1 or greater.
- **FR-002**: The relic offer pool MUST be constructed by including each relic ID exactly `deck_count` times, so that higher-count relics appear proportionally more often when drawn.
- **FR-003**: The relic ID `sharp_edge` MUST be renamed to `common_damage` in the relic data file. All stats (tier, effect, multiplier) remain unchanged.
- **FR-004**: A relic with `deck_count: 0` MUST NOT appear in any offer pool.
- **FR-005**: The following initial `deck_count` values MUST be set:
  - `common_damage` (formerly `sharp_edge`): 3
  - `common_regen`: 1
  - All other relics: 1 (unless overridden by designer judgment during implementation)
- **FR-006**: Any code that references `sharp_edge` by ID MUST be updated to reference `common_damage` instead (no broken references after rename).

### Key Entities

- **Relic Entry**: A relic definition in the data file. Gains a new `deck_count: int` field alongside its existing `name`, `tags`, `effect_stat`, `effect_mult`, and `description` fields.
- **Offer Pool**: The constructed set of relic IDs from which offers are drawn. Built once per draw event by expanding each relic's ID `deck_count` times (e.g., `["common_damage", "common_damage", "common_damage", "common_regen", ...]`).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of relic entries in the data file have a `deck_count` field with value ≥ 1 after the feature ships.
- **SC-002**: `sharp_edge` is absent from the relic data file; `common_damage` is present with identical stats.
- **SC-003**: Over a large sample of relic draw events (100+), `common_damage` appears in the candidate pool approximately 3× more often than `common_regen`, within a reasonable margin (±15%).
- **SC-004**: Zero runtime errors are introduced by the rename — no code path references `sharp_edge` after the change.

## Assumptions

- The rename affects only the internal relic ID (`sharp_edge` → `common_damage`). The display name ("Whetstone") and all gameplay stats remain unchanged.
- `deck_count` applies uniformly across all relic tiers (common, uncommon, rare). Tier-based frequency tuning is done via `deck_count` values rather than separate tier weights.
- The existing offer de-duplication (already-held relics excluded) is unaffected by this change; `deck_count` only influences pool construction before filtering.
- Deck counts for relics other than `common_damage` (3) and `common_regen` (1) are left at 1 by default; designers may adjust them in a follow-up tuning pass.
- No in-game UI displays `deck_count` to the player — it is purely a backend tuning field.
