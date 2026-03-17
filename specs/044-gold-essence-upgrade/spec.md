# Feature Specification: Gold-Purchased Essence Gain Upgrade

**Feature Branch**: `044-gold-essence-upgrade`
**Created**: 2026-03-16
**Status**: Draft
**Input**: User description: "add gold price on essence upgrade: 50 gold for first level, 100 gold next level, 150 next, etc. each level should be 5% increase essence gain (compounding, similar to damage upgrade). there should be 5 levels for now"

## Context

The Alchemy Lab building (feature 040) already exists and contains an Essence Gain upgrade entry, but its purchase button was intentionally disabled with no cost assigned. This feature activates that upgrade: it assigns a gold cost per level, expands the upgrade to 5 purchasable levels, and wires the compounding multiplier into the run essence formula.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Purchase Essence Gain Upgrade with Gold (Priority: P1)

A player who has accumulated gold opens the Alchemy Lab upgrade screen and purchases the Essence Gain upgrade. The previously-disabled button is now active when the player can afford it. Each purchase deducts gold and increments the upgrade level.

**Why this priority**: Core feature — without the purchase path working, nothing else can be tested.

**Independent Test**: Can be fully tested by having 50+ gold, pressing the Essence Gain purchase button in the Alchemy Lab, and verifying gold is deducted and the level increments.

**Acceptance Scenarios**:

1. **Given** the player has 50+ gold and the upgrade is at level 0, **When** they tap the purchase button, **Then** 50 gold is deducted and the upgrade moves to level 1.
2. **Given** the player has 100+ gold and the upgrade is at level 1, **When** they tap the purchase button, **Then** 100 gold is deducted and the upgrade moves to level 2.
3. **Given** the player's gold is less than the next level cost, **When** they view the upgrade, **Then** the purchase button is disabled (same visual as the original stub state).
4. **Given** the upgrade is at level 5 (max), **When** the player views the upgrade screen, **Then** the button shows a "Max Level" / locked indicator and no further purchase is possible.

---

### User Story 2 - Essence Gain Multiplier Applied During Runs (Priority: P2)

A player who owns one or more levels of the Essence Gain upgrade earns proportionally more essence per enemy kill. The bonus compounds across owned levels, identical in structure to the Damage Multiplier in the Magic Forge.

**Why this priority**: Validates that the purchased upgrade delivers its promised in-run benefit.

**Independent Test**: Start a run with the upgrade at level N, kill an enemy, and verify the essence awarded matches the expected compounded multiplier.

**Acceptance Scenarios**:

1. **Given** the upgrade is at level 0, **When** any enemy is killed, **Then** essence is awarded with no change from pre-feature behaviour.
2. **Given** the upgrade is at level 1 (×1.05), **When** a slime is killed at depth 1, **Then** the essence awarded is `floor(10 × 1.05)` = 10.
3. **Given** the upgrade is at level 3 (×1.05^3 ≈ ×1.1576), **When** a skeleton is killed at depth 2, **Then** the multiplier applied is 1.05^3 (compounded, not additive summed).
4. **Given** the upgrade is at level 5 (×1.05^5 ≈ ×1.2763), **When** any enemy is killed, **Then** essence awarded reflects the full 5-level compounded bonus.

---

### User Story 3 - Persistent Upgrade Level Across Sessions (Priority: P3)

A player who purchases Essence Gain upgrade levels sees those levels retained after closing and reopening the game.

**Why this priority**: Persistence is critical for a meta-upgrade, but the save system already handles identical cases (damage upgrade), so this is low-risk.

**Independent Test**: Purchase a level, close the game, reopen, and verify the upgrade level is unchanged and the gold deducted in the previous session is still gone.

**Acceptance Scenarios**:

1. **Given** the upgrade is at level 3 and the game is closed, **When** the game is reopened, **Then** the Alchemy Lab upgrade screen shows level 3 and the next-level cost is 200 gold.
2. **Given** the upgrade is at level 3, **When** the player views the Alchemy Lab, **Then** the displayed level and cost reflect the persisted state, not a reset.

---

### Edge Cases

- What happens when the player has exactly the required gold (boundary: afford vs. cannot-afford)?
- What if the save file has an `essence_upgrade_level` value higher than max_levels (5) — e.g., a future save loaded in an older build?
- How does the compounding multiplier stack with the existing depth bonus (they should be multiplicative)?
- What if gold drops to zero concurrently (e.g., another upgrade is purchased from a different screen) between opening the upgrade screen and tapping the button?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Alchemy Lab upgrade screen's Essence Gain entry MUST display the current level, next-level gold cost, and next-level effect (e.g., "+5% essence").
- **FR-002**: The Essence Gain upgrade MUST have exactly 5 purchasable levels.
- **FR-003**: Level costs MUST be: level 1 = 50 gold, level 2 = 100 gold, level 3 = 150 gold, level 4 = 200 gold, level 5 = 250 gold.
- **FR-004**: All cost values MUST be sourced from `data/meta_config.json` and not hardcoded.
- **FR-005**: The essence gain multiplier MUST compound at 5% per level: multiplier = 1.05^level.
- **FR-006**: The multiplier MUST be applied multiplicatively on top of the existing per-kill essence formula.
- **FR-007**: The purchase button MUST be disabled when the player's current gold is below the next level cost.
- **FR-008**: The purchase button MUST show a "Max Level" or equivalent indicator when the upgrade is at level 5.
- **FR-009**: Purchasing a level MUST atomically deduct the gold cost and increment the upgrade level, then persist both values immediately.
- **FR-010**: The `essence_upgrade_level` field MUST be stored in the meta save file and loaded on startup; a missing field defaults to 0 (backward compatible).
- **FR-011**: The upgrade screen MUST re-evaluate the button's enabled/disabled state whenever the player's gold balance changes while the screen is open.

### Key Entities

- **Essence Gain Upgrade**: Tracks `essence_upgrade_level: int` (0–5). Already owned by MetaState. Exposes a computed `essence_multiplier: float` = 1.05^level. Previously stubbed at max_levels=1 with disabled button — now expanded to 5 purchasable levels with gold costs.
- **Gold Balance**: Existing idle currency balance (feature 041). Reduced by the upgrade cost on purchase.
- **Meta Save**: Existing JSON save file. Gains the `essence_upgrade_level` field (new; defaults to 0 if absent).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player can purchase all 5 levels, spending exactly 50 + 100 + 150 + 200 + 250 = 750 gold total, with each transaction atomic and independently verified.
- **SC-002**: At each level 1–5, the per-kill essence reward matches the expected compounded value (1.05^N × base depth formula) to within ±1 due to floor rounding.
- **SC-003**: The purchase button is disabled in 100% of cases where the player's gold is strictly less than the next level cost.
- **SC-004**: After a game restart, the upgrade level and gold balance match their values at the time the game was closed — 0 regressions across save/load cycles.
- **SC-005**: Changing a cost value in config is reflected in the upgrade screen without any code changes.

## Assumptions

- The upgrade costs **gold** (idle currency, feature 041), not shards — matching the user's description.
- The cost schedule is a flat array or explicit fields in `meta_config.json` under `alchemy_lab.upgrades.essence_gain`: `[50, 100, 150, 200, 250]`. No cost-scale formula is used.
- The compounding multiplier stacks multiplicatively with the depth bonus: `floori(base_essence × depth_bonus × essence_multiplier)`.
- The existing `essence_upgrade_level` field in MetaState (introduced in feature 040 as a stub) is reused — its `max_levels` is updated from 1 to 5 in config.
- Level 0 means no upgrade owned; multiplier = 1.0 (no change to existing behaviour).
- No new scenes are required — the existing Alchemy Lab upgrade screen entry is wired up with a live gold-spend path, mirroring how the Magic Forge damage upgrade works with shards.

## Dependencies

- Feature 040 (Alchemy Lab) — building, upgrade screen, and `essence_upgrade_level` stub already exist.
- Feature 041 (gold idle currency) — gold balance must exist as a spendable resource.
- Feature 014 (essence currency) — the per-kill formula this upgrade multiplies.
