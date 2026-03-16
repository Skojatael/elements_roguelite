# Feature Specification: Gold Offline Storage Cap

**Feature Branch**: `043-gold-storage-cap`
**Created**: 2026-03-16
**Status**: Draft
**Input**: User description: "add an offline storage cap for gold generation. plan it so this storage can be upgradeable and data-driven. the base level should be 4 hours, after 4 hours the gold generation should be stopped. when player opens the game, the offline storage timer should be reset. ask for clarifications if needed"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Offline Gold Is Capped at the Storage Limit (Priority: P1)

When a player has purchased the Transmuter and closes the game, gold accumulates offline. However, the accumulation is capped: once the player has been away for longer than the storage limit (base: 4 hours), no additional gold is earned. When the player reopens the game, they receive only the gold earned up to the storage limit, and the offline timer resets.

**Why this priority**: This is the core feature — without the cap, gold would accumulate indefinitely, breaking game balance. The timer reset is the companion mechanic that prevents confusion about "lost" time.

**Independent Test**: Close the game with Transmuter active. Wait more than 4 hours (or simulate it). Reopen — gold credited must equal exactly 4 hours of generation at the current rate, not more. Wait 2 hours and reopen — gold credited must equal 2 hours.

**Acceptance Scenarios**:

1. **Given** the Transmuter is owned and the player has been offline for 6 hours, **When** the player opens the game, **Then** only 4 hours of gold is credited (the base cap), not 6 hours.
2. **Given** the player has been offline for 2 hours (under cap), **When** the player opens the game, **Then** the full 2 hours of gold is credited.
3. **Given** the player has been offline for exactly 4 hours, **When** the player opens the game, **Then** exactly 4 hours of gold is credited.
4. **Given** the player reopens the game and then immediately closes it again, **When** the player reopens after 5 hours, **Then** the timer restarted from the moment the game was last opened, so 4 hours is credited (not 5+previous gap).

---

### User Story 2 — Player Can Upgrade the Storage Cap (Priority: P2)

The player can purchase an upgrade that increases the storage cap beyond the base 4 hours. Each upgrade level extends the cap by a configurable number of hours. Upgrade cost and the number of available levels are set in the game configuration data.

**Why this priority**: Upgradeable storage is a meta-progression sink and a reason to spend shards. It is not required for the core cap to function, so it is P2.

**Independent Test**: With sufficient shards, purchase a storage cap upgrade from the designated hub screen. Verify the cap increases. Simulate longer offline periods to confirm the new (higher) cap is enforced correctly.

**Acceptance Scenarios**:

1. **Given** the player has purchased one storage cap upgrade (extending to 8 hours), **When** offline for 7 hours, **Then** the full 7 hours of gold is credited.
2. **Given** the player has purchased one storage cap upgrade, **When** offline for 10 hours, **Then** only 8 hours of gold is credited.
3. **Given** the upgrade is already at maximum level, **When** the player views the upgrade UI, **Then** the upgrade button shows "MAX" and cannot be purchased again.
4. **Given** the player has insufficient shards for the next upgrade level, **When** viewing the upgrade, **Then** the upgrade button is visible but disabled.

---

### User Story 3 — Storage Cap Is Reflected in the Gold Display (Priority: P3)

The gold generation display in the hub shows the current storage cap alongside the generation rate, so players understand the ceiling before they close the game.

**Why this priority**: Informational — players need to know the cap exists and what it is. Adds transparency but does not change core mechanics.

**Independent Test**: Open the hub with Transmuter active. Verify the display shows the current cap (e.g., "Cap: 4h") and updates if an upgrade is purchased during the session.

**Acceptance Scenarios**:

1. **Given** the Transmuter is owned at base cap, **When** the hub gold display is visible, **Then** it shows the current cap (e.g., "4h max storage").
2. **Given** the player purchases a storage upgrade during a session, **When** the display refreshes, **Then** the cap shown increases immediately.
3. **Given** the Transmuter is not yet owned, **When** the hub gold display is visible, **Then** no storage cap information is shown (gold display is already gated by Transmuter ownership).

---

### Edge Cases

- Player closes and reopens the game in under 1 second — no gold credited, timer still resets to current time.
- Player has Transmuter but storage cap upgrade data is missing from config — system defaults to base 4 hours gracefully.
- Player's device clock jumps forward (e.g., clock change) — elapsed time is clamped to the cap, preventing a windfall.
- Storage cap is upgraded while the player is in-session — the new cap applies to the *next* offline period; in-session gold is unaffected.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST cap offline gold accumulation at the player's current storage cap (base: 4 hours).
- **FR-002**: When the player opens the game, the offline storage timer MUST reset to the current time, regardless of how long they were away.
- **FR-003**: The base storage cap MUST be read from configuration data, not hard-coded.
- **FR-004**: Players MUST be able to purchase storage cap upgrades using shards, increasing the cap by a data-driven increment per level.
- **FR-005**: The upgrade cost per level, the hours added per level, and the maximum number of levels MUST all be defined in configuration data.
- **FR-006**: The storage cap upgrade MUST be purchasable from the Alchemy Lab screen, alongside the Transmuter upgrade.
- **FR-007**: The upgrade button MUST show the current level's cost and resulting cap; at maximum level it MUST show "MAX" and be disabled.
- **FR-008**: The gold display in the hub MUST show the current storage cap when the Transmuter is owned.
- **FR-009**: The cap MUST apply only to offline accumulation; in-session gold generation is not affected by the storage cap.
- **FR-010**: The storage cap level MUST persist across game sessions.

### Key Entities

- **Storage Cap Config**: Data entry defining base cap hours, hours added per upgrade level, cost per level, and maximum number of levels. Lives in the game's meta configuration data.
- **Storage Cap Level**: The player's current upgrade level for the storage cap (integer, starts at 0). Persisted with meta-progression data.
- **Offline Elapsed Time**: The time in seconds between when the player last closed (or opened) the game and when they next open it. Clamped to the current cap before gold is calculated.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player offline for longer than the base cap (4 hours) receives gold equal to exactly 4 hours of generation — no more, no less — verified across 3 different offline durations above the cap.
- **SC-002**: After purchasing a storage cap upgrade, the new cap is correctly enforced on the very next offline period.
- **SC-003**: All storage cap values (base hours, increment, cost, max levels) can be changed in configuration data with no code changes, and the UI and offline calculation reflect the updated values immediately on next launch.
- **SC-004**: The offline timer resets on every game open — verified by opening the game twice in quick succession, closing for 5 hours, and confirming only post-last-open time is credited.

## Assumptions

- The Transmuter (feature 042) must be purchased before any offline gold or storage cap mechanics apply. If Transmuter is not owned, no offline gold is awarded and no storage cap UI is shown.
- In-session gold accumulation (while the app is open) is not subject to the storage cap — only the offline credit applied on game open is capped.
- The storage cap upgrade is a separate upgrade entry from the Transmuter purchase; it is not auto-unlocked when Transmuter is purchased.
- Upgrade progression is linear: each level adds the same fixed number of hours (e.g., +4h per level), making the cap predictable for players.
- The default upgrade progression assumption: base 4h, up to 2 purchasable levels (+4h each) → max 12h. All values are data-driven and can be tuned.
- "Timer resets when player opens the game" means the timestamp used to track offline start is updated to the current time after offline gold is credited on launch.
