# Feature Specification: Door Lock During Combat

**Feature Branch**: `058-door-lock`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "make doors lock when enemies are not cleared"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Doors Are Locked While Enemies Are Alive (Priority: P1)

When a player enters a combat room and enemies spawn, all doors in that room become impassable. The player cannot leave until every enemy in the room is defeated. Once the room is cleared, the doors unlock and the player can proceed.

**Why this priority**: This is the core feature. Without locked doors, the player can trivially skip all combat by walking straight to the next room.

**Independent Test**: Enter CombatRoom01. Attempt to walk through any door while enemies are alive — verify the door cannot be passed. Kill all enemies. Attempt to walk through a door — verify it opens normally.

**Acceptance Scenarios**:

1. **Given** a combat room has been entered and enemies have spawned, **When** the player walks toward a door, **Then** the door is blocked and the player cannot pass through it.
2. **Given** the last enemy in a room is defeated, **When** the player walks toward any door, **Then** the door is passable and leads to the next room normally.
3. **Given** a room that was previously cleared (e.g. player re-enters), **When** the player approaches a door, **Then** the door is open and passable immediately — no re-locking.
4. **Given** a room with the wave system active, **When** the first wave spawns but the room is not yet cleared, **Then** doors remain locked for the entire wave sequence until the final kill.

---

### Edge Cases

- Player enters room but no enemies spawn (e.g. StartRoom01, already-cleared room) — doors must remain open.
- Boss room — door locking should not interfere with the boss teleport flow (boss room has doors suppressed in code already).
- Room cleared signal fires — doors must unlock in the same frame or within one physics frame.
- Player standing in a doorway when enemies spawn — player should be pushed back or door should block movement without teleporting the player.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Doors in a combat room MUST become impassable the moment enemies spawn (on the same frame as the first wave or flat spawn).
- **FR-002**: Doors MUST remain locked for the entire duration of combat, including across all waves in a wave-system room.
- **FR-003**: Doors MUST unlock immediately when the room is cleared (all enemies defeated).
- **FR-004**: Doors in rooms with no enemies (StartRoom01, already-cleared rooms) MUST remain passable at all times — locking MUST NOT apply.
- **FR-005**: The locked state MUST be purely physical — the player cannot walk through a locked door. Visual feedback (e.g. colour change) is out of scope for this iteration.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of doors in an active combat room are impassable while at least one enemy is alive.
- **SC-002**: Doors unlock within one game frame of the last enemy being defeated in all observed test cases.
- **SC-003**: Doors in non-combat rooms (start room, cleared rooms) remain passable in 100% of test cases.
- **SC-004**: The wave system room (3-wave sequence) keeps doors locked across all waves until the 6th kill.

## Assumptions

- "Locked" means physically blocked — collision prevents passage. No animation, visual indicator, or sound is included in this iteration.
- Door locking applies only to rooms that have a `RoomSpawner` with at least one enemy configured. Rooms with empty spawn configs are unaffected.
- The boss room is out of scope — its doors are already suppressed separately in code.
