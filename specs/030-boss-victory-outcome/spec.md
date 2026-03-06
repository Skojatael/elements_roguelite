# Feature Specification: Boss Victory Outcome

**Feature Branch**: `030-boss-victory-outcome`
**Created**: 2026-03-05
**Status**: Draft
**Input**: User description: "boss room should not have doors. in boss room after boss is defeated two buttons should become available: 'cash out' (the same as in dev panel) and 'continue further' (stub it for now)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Boss Room Has No Doors (Priority: P1)

When the player teleports into the boss room, no exit doors exist. The boss encounter is a one-way commitment — the player cannot walk out through a door as they can in regular combat rooms.

**Why this priority**: Without this constraint the boss room is structurally broken — the player could simply walk away from the boss, bypassing the encounter entirely.

**Independent Test**: Teleport to the boss room and observe that no door zones are visible or accessible in any direction.

**Acceptance Scenarios**:

1. **Given** the player has cleared enough rooms and presses "Teleport to Boss", **When** the boss room loads, **Then** no door passages are visible on any wall.
2. **Given** the player is in the boss room, **When** the player moves toward any wall, **Then** the player hits the boundary and cannot exit via a door.

---

### User Story 2 — Victory Outcome Buttons Appear After Boss Defeat (Priority: P2)

When the boss enemy is defeated, an outcome overlay appears with two buttons: "Cash Out" and "Continue Further". The player must choose one to proceed — they are not forced out of the room automatically.

**Why this priority**: Core boss loop requires a post-victory decision point. Without it, killing the boss produces no result.

**Independent Test**: Kill the boss enemy and confirm that the outcome overlay appears with both buttons visible and labeled correctly.

**Acceptance Scenarios**:

1. **Given** the player is in the boss room and the boss is alive, **When** the boss's health reaches zero, **Then** the outcome overlay appears with exactly two buttons: "Cash Out" and "Continue Further".
2. **Given** the outcome overlay is visible, **When** the player has not yet pressed either button, **Then** neither button is pressed and the overlay remains on screen.
3. **Given** the outcome overlay is visible, **When** the player presses "Cash Out", **Then** the run ends and the player receives their accumulated essence — identical to the existing cash-out run-end flow.
4. **Given** the outcome overlay is visible, **When** the player presses "Continue Further", **Then** the button acknowledges the press with a visible placeholder response (stub — no further content exists yet).

---

### Edge Cases

- What happens if the boss room is loaded but the boss dies before the player enters? The outcome overlay must still appear correctly on first contact after defeat (assumed impossible in normal flow; boss room only loaded on teleport with boss alive).
- What if the player presses "Cash Out" multiple times rapidly? The run-end flow must only trigger once.
- The outcome overlay must not appear in regular combat rooms when clearing them — it is exclusive to the boss room.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The boss room MUST load with no door nodes present on any wall (N, S, E, W).
- **FR-002**: The outcome overlay MUST NOT be visible when the player enters the boss room.
- **FR-003**: The outcome overlay MUST become visible exactly once when the boss enemy's health reaches zero.
- **FR-004**: The outcome overlay MUST contain exactly two interactive buttons: "Cash Out" and "Continue Further".
- **FR-005**: Pressing "Cash Out" MUST trigger the same run-end result as the existing DevPanel cash-out action — the player receives all accumulated essence and the run ends.
- **FR-006**: Pressing "Cash Out" MUST be idempotent — triggering the run-end flow more than once from a single boss fight is not permitted.
- **FR-007**: Pressing "Continue Further" MUST produce a visible stub response (e.g., a disabled state or placeholder label); it MUST NOT crash or silently do nothing with no feedback.
- **FR-008**: The outcome overlay MUST be exclusive to the boss room and MUST NOT appear in any other room type.

### Key Entities

- **Boss Victory Overlay**: The UI panel shown after the boss is defeated. Contains the two action buttons. Hidden by default; shown on boss death.
- **Cash Out action**: Ends the current run and awards all accumulated essence to the player — reuses the existing run-end flow, no new logic required.
- **Continue Further (stub)**: A button that exists in the UI but whose destination content is not implemented in this feature. Must provide minimal feedback to the player.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of boss room loads result in zero visible door exits.
- **SC-002**: The outcome overlay appears within one game frame of the boss enemy's death in all tested runs.
- **SC-003**: Pressing "Cash Out" always produces the same essence payout and run-end screen as the existing cash-out path — zero discrepancy across 5 consecutive test runs.
- **SC-004**: "Continue Further" never causes a crash or freeze in any test scenario.
- **SC-005**: The outcome overlay never appears in a non-boss room across all tested regular and elite room clears.

## Assumptions

- The existing "Cash Out" run-end flow (used by DevPanel) is triggered by a single call that ends the run and awards essence. This feature reuses that call without modification.
- "Continue Further" content (e.g., a second boss floor or endless mode) is out of scope; only the stub button is required.
- The boss room scene (`BossRoom01.tscn`) is the correct scene to modify for door removal. Doors are simply absent from this scene rather than hidden at runtime.
- A single boss enemy is present in the boss room; the victory overlay triggers on that enemy's defeat signal.
- The outcome overlay is a screen-space UI element (not world-space) so it appears regardless of camera position.

## Dependencies

- Feature 029 (Boss Room) — boss room scene and teleport flow must be in place.
- Existing run-end / cash-out flow from RunManager — reused without modification.
