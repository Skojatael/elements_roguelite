# Feature Specification: DevPanel Start Boss

**Feature Branch**: `031-devpanel-start-boss`
**Created**: 2026-03-05
**Status**: Draft
**Input**: User description: "implement start boss button from dev panel. it should teleport player to the boss room, as if it was from the dungeon"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — DevPanel "Start Boss" Teleports Player to Boss Room (Priority: P1)

A developer presses the "Start Boss" button in the DevPanel. The player is immediately transported to the boss room — exactly the same outcome as clearing 6 rooms in a normal run and pressing the in-game "Teleport to Boss" button. If no run is currently active, one is started automatically before the teleport occurs.

**Why this priority**: This is the entire feature — there is only one story.

**Independent Test**: Press DevPanel "Start Boss" from the hub (no run active) → run starts → player appears in boss room → boss enemy is present → boss HP reflects 0 cleared rooms → victory overlay appears on boss death.

**Acceptance Scenarios**:

1. **Given** no run is active (player is in the hub), **When** the developer presses "Start Boss", **Then** a run starts and the player is immediately placed in the boss room with the boss enemy spawned.
2. **Given** a run is already active (player is in a dungeon room), **When** the developer presses "Start Boss", **Then** the current room is freed and the player is placed in the boss room with the boss enemy spawned.
3. **Given** the player is already in the boss room, **When** the developer presses "Start Boss" again, **Then** nothing happens (the button is effectively a no-op while the boss room is active).
4. **Given** the player reaches the boss room via DevPanel, **When** the boss is defeated, **Then** the victory overlay (Cash Out / Continue Further) appears — identical to the normal game flow.
5. **Given** the player reaches the boss room via DevPanel with 0 rooms cleared, **When** the boss spawns, **Then** boss HP equals the base value (no scaling bonus from cleared rooms).

### Edge Cases

- Pressing "Start Boss" while the victory overlay is already showing should do nothing.
- Boss HP scaling uses `RunManager.cleared_rooms.size()` at the moment of teleport — from DevPanel with no rooms cleared this will be 0, producing base HP. This is correct and expected.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Pressing "Start Boss" from DevPanel MUST produce the same result as pressing the in-game "Teleport to Boss" button — same boss room, same boss enemy, same HP scaling formula.
- **FR-002**: If no run is active when "Start Boss" is pressed, a run MUST be started automatically before the boss room is loaded.
- **FR-003**: The existing room (hub or dungeon room) MUST be freed before the boss room loads — no orphaned room nodes.
- **FR-004**: Pressing "Start Boss" while already in the boss room MUST be a no-op — no double-spawn, no crash.
- **FR-005**: Pressing "Start Boss" while the boss victory overlay is showing MUST be a no-op.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pressing "Start Boss" always results in the player appearing in the boss room within the same frame, across all starting states (hub, dungeon room, run not active).
- **SC-002**: Boss enemy HP at 0 rooms cleared equals exactly the base HP value defined in the enemy data — no rounding artefacts.
- **SC-003**: No orphaned nodes remain in the scene tree after pressing "Start Boss" from any starting state.
- **SC-004**: The post-boss victory flow (Cash Out / Continue Further) works identically whether the boss room was reached via DevPanel or via normal play.

## Assumptions

- The DevPanel "Start Boss" signal (`start_boss_pressed`) already exists and is connected to a stub in Main.gd — the implementation replaces the stub body only.
- Starting a run via DevPanel uses the same `RunManager.start_run("endless")` call as the hub teleport door.
- The hub room (if present) will be freed by the existing `_on_run_started()` cleanup logic when a new run starts.

## Dependencies

- Feature 029 (Boss Room) — `_on_boss_teleport_pressed()` and the full boss spawn flow must exist.
- Feature 030 (Boss Victory Outcome) — victory overlay must exist for end-to-end validation.
