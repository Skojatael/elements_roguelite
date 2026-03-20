# Feature Specification: Forge Rarity Upgrade

**Feature Branch**: `067-forge-rarity-upgrade`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "create an upgrade in forge that allows relics to be upgraded to next rarity with 10% chance. example: with upgrade purchased, in regular rooms you have 10% chance that a draw is from uncommon tier deck. suggest the upgrade cost, it should be midgame, so no less than 300 shards, I think"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Purchase Rarity Luck Upgrade in Forge (Priority: P1)

A player who has restored the Magic Forge visits the Forge upgrade screen and spends shards to purchase the "Rarity Luck" upgrade. From that point forward, every relic draw has a 10% chance of being pulled from the next higher rarity tier instead of the normal tier for that room type.

**Why this priority**: This is the core deliverable. Without the upgrade existing and being purchasable, nothing else in this feature functions.

**Independent Test**: Open the hub, enter the Forge screen, verify the upgrade entry appears with its shard cost. Spend enough shards and confirm it purchases. The upgrade node is the MVP.

**Acceptance Scenarios**:

1. **Given** the player has the Forge restored and has not yet purchased "Rarity Luck", **When** they open the Forge upgrade screen, **Then** a "Rarity Luck" upgrade entry is shown with cost 350 shards and a "purchase" affordance.
2. **Given** the player has at least 350 shards, **When** they purchase "Rarity Luck", **Then** 350 shards are deducted, the entry shows "Owned", and the effect is active for all future runs.
3. **Given** the player has fewer than 350 shards, **When** they view the entry, **Then** the purchase button is disabled and the player cannot buy it.
4. **Given** the upgrade has already been purchased, **When** the player opens the Forge screen again in a later session, **Then** the entry shows "Owned" (persisted across sessions).

---

### User Story 2 - Higher-Tier Draw in Regular Rooms (Priority: P1)

During a run, when a standard combat room is cleared and a relic offer fires, each individual draw has a 10% chance to be resolved from the uncommon pool rather than the common pool.

**Why this priority**: This is the primary run-time effect of the feature. It must work correctly for the upgrade to have any gameplay meaning.

**Independent Test**: With the upgrade owned, clear a standard combat room. The offer screen shows 3 relics. At least in aggregate over many rooms, ~10% of shown relics should be uncommon tier. This can be verified by running many rooms or by a unit test on the draw logic.

**Acceptance Scenarios**:

1. **Given** "Rarity Luck" is owned and a standard room is cleared, **When** the relic offer is generated, **Then** each draw independently has a 10% chance to sample from the uncommon pool (and 90% chance from common).
2. **Given** the uncommon pool is empty or depleted (all uncommons already held), **When** a promoted draw occurs, **Then** the draw falls back to the common pool — the player always receives an offer.
3. **Given** "Rarity Luck" is NOT owned, **When** a standard room relic offer fires, **Then** all draws come exclusively from the common pool (no change from current behaviour).

---

### User Story 3 - Rarity Promotion Applies to Elite Rooms (Priority: P2)

In elite rooms, the existing behaviour draws from the uncommon pool. With "Rarity Luck" owned, each draw has a 10% chance to be promoted one step further to the rare pool.

**Why this priority**: Consistent application of the mechanic across all offer contexts adds depth and makes the upgrade relevant throughout the full run, not just in early rooms.

**Independent Test**: Clear an elite room with the upgrade owned. Verify a rare relic can appear in the offer. Without the upgrade, rare relics must not appear in elite rooms.

**Acceptance Scenarios**:

1. **Given** "Rarity Luck" is owned and an elite room is cleared, **When** the relic offer is generated, **Then** each draw has a 10% chance to sample from the rare pool and 90% chance from the uncommon pool.
2. **Given** the rare pool has no available relics (all held), **When** a promoted draw occurs in an elite room, **Then** the draw falls back to the uncommon pool.
3. **Given** a boss relic offer fires (always rare pool), **When** "Rarity Luck" is owned, **Then** boss draws are unaffected — there is no tier above rare to promote to.

---

### Edge Cases

- What happens when the upgraded tier's pool has no available relics (all already held by the player)? → Fall back to the base tier for that room type.
- What if all pools (base and upgraded) are exhausted? → Existing exhaustion/fallback logic handles this; no change needed.
- Does the 10% apply per-card in the 3-card offer, or once for the whole offer batch? → Per-card (each draw is an independent 10% roll).
- Does the upgrade stack or can it be purchased more than once? → One-time purchase; no stacking.
- Does the promotion apply to the DevPanel "get relic" flow? → No; DevPanel bypasses the normal draw pipeline.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Forge upgrade screen MUST display a purchasable "Rarity Luck" upgrade entry when the Forge is restored.
- **FR-002**: The "Rarity Luck" upgrade MUST cost 350 shards (one-time purchase, not level-based).
- **FR-003**: The upgrade MUST be persisted in `MetaState` across sessions; once owned it is always active.
- **FR-004**: When "Rarity Luck" is owned, each individual relic draw MUST independently roll a 10% chance to be promoted one rarity tier higher than the room's default tier.
- **FR-005**: The promotion MUST be per-draw (independent roll for each card in the offer), not per-offer.
- **FR-006**: If the promoted tier's available pool is empty (all relics already held), the draw MUST fall back to the room's base tier pool.
- **FR-007**: The promotion MUST apply consistently: common → uncommon in standard rooms; uncommon → rare in elite rooms.
- **FR-008**: Boss relic offers (always rare) MUST NOT be affected by the promotion mechanic.
- **FR-009**: When "Rarity Luck" is not owned, relic draw behaviour MUST remain identical to the current implementation.
- **FR-010**: The upgrade entry in the Forge screen MUST show "Owned" and disable the purchase affordance after purchase.
- **FR-011**: The shard cost (350) MUST be stored in `data/meta_config.json` under the `magic_forge.upgrades` section, not hardcoded.

### Key Entities

- **Rarity Luck Upgrade**: One-time meta-progression purchase; boolean owned/not-owned state stored in `MetaState`; governs the per-draw tier promotion mechanic.
- **Draw Context**: Per-draw resolution step that determines which rarity pool to sample from, taking into account room type (common / uncommon / rare default) and the promotion roll result.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After purchase, 100% of runs show the promotion mechanic active for all standard and elite room relic offers.
- **SC-002**: Over a large sample of draws in standard rooms with the upgrade owned, approximately 10% of drawn relics are uncommon tier (±2% tolerance).
- **SC-003**: The upgrade appears correctly in the Forge upgrade screen in all states: unpurchased (with cost), purchased (owned), and unaffordable (disabled).
- **SC-004**: The purchased state persists correctly after restarting the game session — the upgrade is never lost.
- **SC-005**: Fallback draws (when promoted tier is empty) always produce a valid relic — zero empty offer slots.

## Assumptions

- **Cost: 350 shards** — midgame positioning. The damage upgrade costs 50–253 shards across levels; the Mage Tower costs 200 shards. At 350 shards this upgrade is meaningfully gated behind several early runs but reachable before a player has finished the dungeon expansion content.
- Rarity tiers are ordered: `common < uncommon < rare`. The existing relic system already uses these tier labels.
- The upgrade is a single flat boolean (like `adventuring_gear_owned`), not a leveled upgrade.
- The 10% rate is fixed (not configurable per-relic or variable). If balance requires tuning the rate should be exposed in `meta_config.json`.
- The promotion roll happens at draw time inside `RelicManagerImpl.draw_offer()` (or an equivalent per-draw helper), not at offer-screen display time.
- Boss offers are out of scope for promotion because the boss already offers rare relics and there is no "legendary" tier.
