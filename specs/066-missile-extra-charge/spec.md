# Feature Specification: Magic Forge — Missile Extra Charge Upgrade

**Feature Branch**: `066-missile-extra-charge`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "add a forge upgrade that adds 1 extra charge (pip) to magic missile"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Purchase Extra Charge Upgrade (Priority: P1)

A player visits the Magic Forge hub building after accumulating enough shards. They see a new purchasable upgrade called something like "Arcane Reservoir" that permanently grants Magic Missile one additional charge pip for all future runs. They spend their shards and the upgrade is confirmed.

**Why this priority**: This is the core of the feature — acquiring the upgrade is the primary action.

**Independent Test**: Can be fully tested by opening the Forge upgrade screen, purchasing the upgrade (with sufficient shards), and verifying the confirmation/state change.

**Acceptance Scenarios**:

1. **Given** the player has sufficient shards and has not yet purchased the upgrade, **When** they open the Magic Forge upgrade screen, **Then** the extra-charge upgrade is displayed with its shard cost and a purchase button.
2. **Given** the player has sufficient shards, **When** they tap the purchase button, **Then** shards are deducted, the upgrade is marked as owned, and the button becomes a "Purchased" indicator (disabled).
3. **Given** the player has already purchased the upgrade, **When** they open the Forge screen again, **Then** the upgrade shows as already owned (button disabled / label changed).
4. **Given** the player does not have enough shards, **When** they view the upgrade, **Then** the purchase button is disabled and the cost is clearly visible.

---

### User Story 2 - Extra Charge Active During a Run (Priority: P1)

After purchasing the upgrade, the player starts a new run. Magic Missile now shows one additional pip in the HUD charge display. The extra charge behaves identically to the base charges — it is consumed on fire and refills on the standard cooldown/reload cycle.

**Why this priority**: The in-run effect is the actual game-feel payoff. Without it the purchase means nothing.

**Independent Test**: Can be tested by starting a run with the upgrade owned and verifying the charge display shows the correct number and that the extra pip fires and reloads correctly.

**Acceptance Scenarios**:

1. **Given** the upgrade is owned, **When** a run begins, **Then** Magic Missile's maximum charge count is base charges + 1.
2. **Given** the upgrade is owned and all charges are depleted, **When** the reload cycle completes, **Then** all charges (including the extra one) are restored.
3. **Given** the upgrade is NOT owned, **When** a run begins, **Then** Magic Missile's charge count is unchanged from base.

---

### User Story 3 - Upgrade Persists Across Sessions (Priority: P2)

The player closes the game and reopens it. The extra-charge upgrade is still owned and Magic Missile still has the additional pip.

**Why this priority**: Meta-progression upgrades are meant to be permanent — loss on session end would feel like a bug.

**Independent Test**: Purchase the upgrade, quit the game, reopen, and verify the upgrade is still owned and the charge count is still elevated.

**Acceptance Scenarios**:

1. **Given** the player owned the upgrade before quitting, **When** the game is relaunched, **Then** the upgrade is still shown as owned in the Forge screen.
2. **Given** the game is relaunched with the upgrade owned, **When** the player starts a run, **Then** Magic Missile still has the extra charge.

---

### Edge Cases

- What happens when the player purchases the upgrade mid-hub (not in a run)? The extra charge should apply starting from the next run.
- How does the extra charge interact with any future charge-granting relics or upgrades? The charges should stack additively.
- What if the save file is missing or corrupted? The upgrade defaults to not-owned (standard save fallback behaviour).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Magic Forge upgrade screen MUST display the extra-charge upgrade with its name, shard cost, and purchase status.
- **FR-002**: The purchase button MUST be disabled when the player's shard balance is below the upgrade cost.
- **FR-003**: The purchase button MUST be disabled (and replaced with an "owned" indicator) after the upgrade has been purchased.
- **FR-004**: Purchasing the upgrade MUST deduct the correct shard cost from the player's meta balance.
- **FR-005**: The extra-charge upgrade MUST be persisted in the save file so it survives game restarts.
- **FR-006**: When the upgrade is owned, Magic Missile's maximum charge count during any run MUST be base charges + 1.
- **FR-007**: The extra charge pip MUST appear in the HUD charge display during a run.
- **FR-008**: The extra charge MUST refill on the same cooldown/reload cycle as the base charges.
- **FR-009**: When the upgrade is NOT owned, Magic Missile charge behaviour MUST be identical to the pre-feature baseline.

### Key Entities

- **Magic Forge Upgrade — Extra Missile Charge**: A one-time purchasable meta upgrade stored in `MetaState`. Has a shard cost (configured in `meta_config.json`). Grants `missile_extra_charge_owned: bool`.
- **Magic Missile Charge Count**: The maximum number of charges Magic Missile can hold. Computed at run start as `base_charges + (1 if upgrade owned else 0)`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The upgrade appears in the Magic Forge screen and can be purchased in a single tap when funds are sufficient.
- **SC-002**: After purchase, every subsequent run has exactly one additional Magic Missile charge pip compared to the un-upgraded baseline.
- **SC-003**: The owned state survives a full game quit-and-relaunch cycle with no data loss.
- **SC-004**: The charge display in the HUD correctly reflects the upgraded count at all times during a run (including after depleting and reloading).

## Assumptions

- The Magic Forge upgrade screen already exists (feature 036); this feature adds one entry to it following the same pattern as the existing Damage Multiplier upgrade.
- The base Magic Missile charge count is a constant defined in player/skill code or config; the upgrade adds +1 on top of whatever that base is.
- Shard cost will be set at 150 shards (configurable in `meta_config.json`) — a meaningful but reachable mid-game cost comparable to existing upgrades.
- The upgrade is a flat +1 and is not tiered (no "level 2 for +2 charges"). A single purchase completes the upgrade.
- No in-run relic currently grants extra charges, so no conflict resolution is needed for this iteration.
