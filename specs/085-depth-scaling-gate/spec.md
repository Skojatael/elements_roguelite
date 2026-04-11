# Feature Specification: Depth Scaling Gate

**Feature Branch**: `085-depth-scaling-gate`
**Created**: 2026-03-28
**Status**: Draft
**Input**: User description: "gate essence/difficulty scaling. create an upgrade in Tower that is unlocked for 300 shards (data-driven). before that, no scaling should happen. after that, existing scaling model should be applied"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unlock Scaling in Mage Tower (Priority: P1)

A player visits the Mage Tower upgrade screen and sees a new "Depth Scaling" upgrade available for 300 shards. After purchasing it, both essence rewards and enemy difficulty now increase with dungeon depth, making deeper runs more rewarding and more dangerous.

**Why this priority**: This is the entire feature — gating the scaling upgrade behind the purchase. Without this story there is no feature.

**Independent Test**: Open the Mage Tower upgrade screen, purchase the upgrade (requires 300 shards), then run a dungeon and verify that rooms at higher depths award more essence and have stronger enemies than depth-1 rooms.

**Acceptance Scenarios**:

1. **Given** the player has ≥ 300 shards and has not yet purchased the upgrade, **When** they open the Mage Tower upgrade screen, **Then** a "Depth Scaling" entry is displayed with its name, cost (300 shards), and a purchasable button.
2. **Given** the player clicks the upgrade button, **When** the purchase completes, **Then** the button changes to an "Unlocked" state, shards are deducted, and the change persists across sessions.
3. **Given** the upgrade is not purchased, **When** a run is active, **Then** all rooms award base essence (no depth bonus) and all enemies spawn with difficulty multiplier 1.0 regardless of depth.
4. **Given** the upgrade is purchased, **When** a run is active, **Then** rooms at higher depths award proportionally more essence and enemies have difficulty multipliers greater than 1.0, matching the pre-existing scaling formulas.

---

### User Story 2 - Flat Rewards for New Players (Priority: P2)

A new player who has not yet unlocked the upgrade experiences a flat difficulty and flat essence income regardless of how deep they go into the dungeon. This simplifies early progression before the scaling mechanic is introduced.

**Why this priority**: Correct ungated behavior is a prerequisite for the gate to be meaningful. Verifying the off-state is independently testable.

**Independent Test**: Start a run without purchasing the upgrade. Navigate to depth 4+. Confirm essence per kill equals the enemy's base essence value and enemy health equals base health (difficulty_mult 1.0).

**Acceptance Scenarios**:

1. **Given** the upgrade is not purchased, **When** an enemy is defeated at depth 4, **Then** the essence awarded equals the enemy's base essence value (no depth multiplier applied).
2. **Given** the upgrade is not purchased, **When** enemies spawn in any room, **Then** their health is exactly their base value (depth has no effect on spawned stats).

---

### Edge Cases

- What if the player purchases the upgrade mid-run? The scaling should take effect from the next room entered (rooms already spawned are unaffected).
- What happens when the player cannot afford the upgrade? The button is disabled or shows insufficient-funds feedback, no purchase occurs.
- What if `meta_config.json` is missing the cost entry? The upgrade cost falls back to a safe default (300 shards) and the feature remains functional.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Mage Tower upgrade screen MUST display a "Depth Scaling" upgrade entry with a name sourced from `meta_config.json`.
- **FR-002**: The upgrade cost MUST be read from `meta_config.json` (default: 300 shards) — no hard-coded cost in scripts.
- **FR-003**: Purchasing the upgrade MUST atomically deduct the shard cost and persist the unlocked state across sessions.
- **FR-004**: When the upgrade is **not** purchased, the essence reward formula MUST use the enemy's base essence value with no depth multiplier (equivalent to depth = 1 in the old formula, i.e. multiply by 1.0).
- **FR-005**: When the upgrade is **not** purchased, every room's difficulty multiplier MUST be 1.0 regardless of grid depth.
- **FR-006**: When the upgrade **is** purchased, the existing essence scaling formula MUST apply: `floor(base_essence × (1 + 0.10 × (depth − 1)))`.
- **FR-007**: When the upgrade **is** purchased, the existing difficulty multiplier formula MUST apply: `1.0 + 0.12 × depth`.
- **FR-008**: The upgrade button MUST be disabled (unclickable) when the player's shard balance is below the cost.
- **FR-009**: Once purchased, the upgrade entry MUST display an "Unlocked" state and MUST NOT be purchasable again.
- **FR-010**: The upgrade unlocked state MUST be stored in `MetaState` and saved to persistent storage.

### Key Entities

- **DepthScaling upgrade**: A new entry in the Mage Tower upgrade screen. Attributes: display name (from config), shard cost (from config), unlocked flag (persisted in MetaState).
- **MetaState**: Gains a new boolean field `depth_scaling_unlocked` that gates both scaling systems.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player without the upgrade always receives exactly the base essence value per kill at any depth (0% depth bonus).
- **SC-002**: A player without the upgrade always encounters enemies with health equal to 100% of their base value at any depth.
- **SC-003**: A player with the upgrade receives scaled essence and scaled enemy health consistent with the pre-existing formulas at every tested depth.
- **SC-004**: The upgrade cost displayed in the UI exactly matches the value in `meta_config.json` — changing the config value updates the UI without code changes.
- **SC-005**: Purchasing the upgrade is irreversible within a session and survives a game restart.

## Assumptions

- The Mage Tower upgrade screen already supports adding new entries (feature 037). This feature adds a fourth entry alongside the existing three.
- "Existing scaling model" refers specifically to the depth-based essence formula (feature 014) and the depth-based difficulty multiplier (feature 010). No other scaling is affected.
- The upgrade affects both scaling systems together — there is no separate gate per system.
- Mid-run purchases apply from the next spawned room; already-spawned enemies are unaffected.
- The Boss room difficulty (feature 029) uses a separate rooms-cleared-based formula and is **not** gated by this upgrade.
