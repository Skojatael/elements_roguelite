# Feature Specification: Relic Weighted Draws

**Feature Branch**: `023-relic-weighted-draws`
**Created**: 2026-03-03
**Status**: Ready
**Input**: User description: "introduce weighted draws for relics. for common, uncommon, and rare, the odds should be 60%, 30% and 10% respectively"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Tier-Weighted Relic Offers (Priority: P1)

When a relic offer appears, each of the two cards is drawn independently. First a tier is selected by weight (common 60%, uncommon 30%, rare 10%), then a relic is drawn from that tier's deck. Each tier has its own shuffled deck; when a tier's deck runs out, it is automatically reshuffled from the full set of that tier's relics before the next draw. Because decks always reshuffle, a tier is never empty at draw time — no weight redistribution is needed.

**Why this priority**: Core feature request. Creates meaningful rarity tiers so rare relics feel special and appear infrequently.

**Independent Test**: Trigger many relic offers via DevPanel and observe that rare relics appear significantly less often than common ones. Over 20 draws, rare relics should appear roughly 2 times, uncommon roughly 6, common roughly 12.

**Acceptance Scenarios**:

1. **Given** relics of all three tiers exist, **When** an offer is drawn, **Then** each card's tier is selected with common ~60%, uncommon ~30%, rare ~10%.
2. **Given** a tier's deck has been fully drawn, **When** the next draw selects that tier, **Then** the deck is reshuffled from all relics of that tier before drawing.
3. **Given** a reshuffle just occurred for a tier, **When** cards are drawn from that tier, **Then** all relics of that tier can appear again (no permanent depletion).
4. **Given** the entire relic pool is empty (no relics defined in any tier), **When** a draw is attempted, **Then** no offer screen appears.
5. **Given** only one relic exists across all tiers, **When** an offer is drawn, **Then** both cards show that relic.

---

### Edge Cases

- A tier's deck reaches zero cards → reshuffle that tier's full set before drawing.
- A tier has only one relic → that relic always appears when that tier is selected.
- Both cards roll the same tier → each draws independently from the same deck (second draw may get same relic if deck was just reshuffled with one entry).
- Run ends → all decks are discarded; rebuilt fresh on next run start.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each card in a relic offer MUST be drawn by first selecting a tier according to the defined weights (common 60%, uncommon 30%, rare 10%), then drawing the next card from that tier's deck.
- **FR-002**: Each tier MUST maintain its own independent shuffled deck containing all relics of that tier.
- **FR-003**: When a tier's deck is exhausted, it MUST be reshuffled from the full set of that tier's relics before the draw proceeds.
- **FR-004**: Tier weights MUST be stored in the game's balance configuration file, not hard-coded.
- **FR-005**: The two cards in an offer MUST be drawn independently — each goes through the full weighted tier selection and deck draw separately.
- **FR-006**: All decks MUST be reset and reshuffled at the start of every run.
- **FR-007**: When no relics are defined at all, no offer screen MUST appear (existing behaviour preserved).

### Key Entities

- **Per-tier deck**: A shuffled ordered list of all relics belonging to one tier. Drawn from front; reshuffled when empty. One deck per tier (common, uncommon, rare).
- **Tier weights config**: Mapping of tier name → probability (common: 0.6, uncommon: 0.3, rare: 0.1). Stored in balance config.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Over 100 independent card draws, rare relics appear in 8–12% of draws, uncommon in 26–34%, common in 56–64% (±4% statistical tolerance).
- **SC-002**: No draw ever fails or produces an empty card while relics are defined for all three tiers.
- **SC-003**: After a deck reshuffles, all relics of that tier can appear again within the next cycle.
- **SC-004**: Tier weights can be changed in the config file and take effect on the next run start without any code changes.

## Assumptions

- "Uncommon" is a new tier; `relics.json` will be extended with an `"uncommon"` section.
- Deck state is per-run only — it is not persisted to save file.
- Both cards in a single offer are drawn independently; the same relic CAN appear on both cards.
- Weights are read from config and normalised at run start if they do not sum to exactly 1.0.
