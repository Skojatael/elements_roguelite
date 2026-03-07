# Feature Specification: Boss Entry Position

**Feature Branch**: `035-boss-entry-position`
**Created**: 2026-03-07
**Status**: Draft
**Input**: User description: "when teleporting to boss room, place the player in lower center part of the screen (around (0,400))"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Player Enters Boss Room at Lower Center (Priority: P1)

When the player teleports to the boss room — either via the "Teleport to Boss" button in the ExplorationHUD or via the hub's boss-run shortcut — the player character appears near the bottom-center of the visible screen area rather than at the room's center. This places the player in a natural starting position with the boss and combat arena visible ahead of them.

**Why this priority**: Core gameplay feel — the player's spawn position directly impacts where they perceive the boss encounter to begin. Spawning at center obscures the intended entry framing.

**Independent Test**: Can be fully tested by pressing "Teleport to Boss" and observing that the player appears at the lower-center of the screen, visually distinct from the room's center point.

**Acceptance Scenarios**:

1. **Given** a run is active with enough rooms cleared, **When** the player presses "Teleport to Boss", **Then** the player spawns at approximately (0, 400) relative to the boss room origin — lower center of the screen.
2. **Given** a boss run started from the hub, **When** the teleport fires automatically, **Then** the player spawns at the same lower-center offset.
3. **Given** the camera is centered on the boss room, **When** the player teleports in, **Then** the player is visible on screen at the lower-center region, not clipped or off-screen.

---

### Edge Cases

- What happens when the y-offset places the player outside the boss room floor area? (The offset should remain within navigable space — +400 in local y is a safe floor position given the room's layout.)
- Does the dev panel "Start Boss" shortcut also use the correct spawn position? (It calls the same `_on_boss_teleport_pressed()` path, so it should be covered automatically.)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the player teleports to the boss room, the player MUST be placed at an offset of (0, 400) relative to the boss room's world origin — not at the room origin itself.
- **FR-002**: The camera MUST remain centered on the boss room origin (unchanged behavior); only the player position changes.
- **FR-003**: The spawn position offset MUST apply to all entry paths into the boss room: ExplorationHUD teleport button, hub boss-run shortcut, and dev panel shortcut.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After teleporting to the boss room, the player character is visually positioned in the lower-center region of the screen.
- **SC-002**: The camera does not move from the boss room center, so the player appears offset downward relative to the room center in the viewport.
- **SC-003**: All three boss entry paths (HUD button, hub boss-run, dev panel) result in the same player spawn position.
