# Feature Specification: Hub Shard Display

**Feature Branch**: `017-hub-shard-display`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "implement hub overlay that displays current shards"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See Shard Total in Hub (Priority: P1)

When the player is in the hub, a persistent overlay shows their current shard total. The value is always up to date — if the player just completed a run and earned shards, the overlay reflects the new total immediately on hub entry.

**Why this priority**: Shards are the meta-progression currency. Players need to see their balance at a glance to make meaningful decisions about progression. Without visibility, the currency has no gameplay presence.

**Independent Test**: Launch the game, enter the hub, confirm the shard total is visible. Complete a run, return to the hub, confirm the displayed total matches the new accumulated amount.

**Acceptance Scenarios**:

1. **Given** the player enters the hub with 0 shards, **When** the hub overlay is visible, **Then** it displays "0" (or equivalent zero state) as the shard total.
2. **Given** the player has accumulated shards across prior runs, **When** they return to the hub, **Then** the overlay immediately shows the correct cumulative shard total.
3. **Given** the player is in the hub, **When** they look at the overlay, **Then** the display is clearly readable and labelled so they understand it represents shards.

---

### User Story 2 - Overlay Hidden During Runs (Priority: P2)

The shard overlay is not visible during active dungeon exploration. It appears only in the hub.

**Why this priority**: The exploration HUD has its own layout. Showing the shard total during runs would clutter the screen without adding value — shards cannot be spent or earned mid-run in the current design.

**Independent Test**: Start a run from the hub, confirm the shard overlay is no longer visible. End the run, return to the hub, confirm the overlay reappears.

**Acceptance Scenarios**:

1. **Given** the player starts a run, **When** the dungeon exploration begins, **Then** the shard overlay is hidden.
2. **Given** the player returns to the hub after a run, **When** the hub loads, **Then** the shard overlay is visible again with the updated total.

---

### Edge Cases

- Player has 0 shards (first launch, no runs completed) — overlay shows 0, not blank or missing.
- Very large shard totals — display must not overflow or truncate in a way that misleads the player.
- Overlay must not interfere with TeleportDoor interaction or other hub UI elements.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The hub MUST display a shard overlay showing the player's current `total_shards` from MetaState.
- **FR-002**: The overlay MUST be visible whenever the hub is active and hidden at all other times (during runs, on the results screen).
- **FR-003**: The displayed value MUST reflect the shard total at the moment the hub becomes active — no stale data.
- **FR-004**: The overlay MUST include a label identifying the value as shards (e.g., "Shards: 42"), not a bare number.
- **FR-005**: The overlay MUST remain visible and readable for the entire duration of the hub session without requiring player interaction.

### Key Entities

- **Shard total**: The `total_shards: int` field from `MetaState`, accessed via `MetaManager`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The shard total is visible within 1 second of the hub scene becoming active, in 100% of test cases.
- **SC-002**: The displayed value matches `MetaManager.meta_state.total_shards` exactly in 100% of test cases.
- **SC-003**: The overlay is absent during active runs in 100% of test cases — no shard UI visible on the exploration screen.
- **SC-004**: The overlay is present and correct after every hub entry across at least 5 consecutive run-and-return cycles.

## Assumptions

- `MetaManager.meta_state.total_shards` is always up to date when the hub loads (MetaManager saves and updates it at run end before the hub is reinstated).
- The overlay is a simple read-only display; no interaction (tap, click) is required.
- No animation or transition effect is required for the number updating — a static display is sufficient for this iteration.
- Shards are whole numbers; no decimal formatting needed.

## Scope

**In scope**: Shard total display in the hub, hiding during runs.

**Out of scope**: Shard spending UI, animated shard counters, shard history, shard display during runs or results screen, shard icon/artwork (placeholder text label is sufficient).
