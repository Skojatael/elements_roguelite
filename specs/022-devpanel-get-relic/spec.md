# Feature Specification: DevPanel Get Relic Button

**Feature Branch**: `022-devpanel-get-relic`
**Created**: 2026-03-03
**Status**: Ready
**Input**: User description: "add button to devpanel: get relic. it should simulate relicoffer when run is active"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Trigger Relic Offer from DevPanel (Priority: P1)

A developer testing relic behavior wants to trigger a relic offer at any point during a run, without having to clear the required number of rooms. Pressing "Get Relic" on the DevPanel opens the same offer screen that appears after a room clear.

**Why this priority**: Core feature request. Enables relic system testing without playing through rooms.

**Independent Test**: Start a run via DevPanel, press "Get Relic", verify relic offer screen appears with two choices, pick one, verify it is applied to the player.

**Acceptance Scenarios**:

1. **Given** a run is active, **When** the developer presses "Get Relic", **Then** the relic offer screen appears with two relic choices drawn from the pool.
2. **Given** a run is active and the relic pool is empty, **When** "Get Relic" is pressed, **Then** no offer screen appears (silent no-op — same behaviour as natural empty-pool case).
3. **Given** no run is active, **When** "Get Relic" is pressed, **Then** nothing happens.

---

### Edge Cases

- Button pressed when run is not active → ignored silently.
- Button pressed when relic offer screen is already visible → ignored (no duplicate screen).
- Relic pool is empty → no screen, no error.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: DevPanel MUST display a "Get Relic" button alongside existing dev buttons.
- **FR-002**: Pressing "Get Relic" when a run is active MUST trigger the relic offer screen with two choices, identical to a natural post-clear offer.
- **FR-003**: Pressing "Get Relic" when no run is active MUST have no effect.
- **FR-004**: Pressing "Get Relic" when a relic offer is already visible MUST have no effect.
- **FR-005**: A relic picked from the dev-triggered offer MUST be applied to the player identically to a naturally triggered offer.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developer can trigger a relic offer in under 2 button presses from the DevPanel during any active run.
- **SC-002**: 100% of relics picked via the dev button are correctly applied to player stats.
- **SC-003**: The button produces no errors or side effects when pressed outside of an active run.
