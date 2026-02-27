# Feature Specification: Room Loading & Doors

**Feature Branch**: `009-room-loading-doors`
**Created**: 2026-02-24
**Status**: Draft
**Input**: "when player is in a room, instantiate a scene. always instantiate first room, do not spawn enemies in the first room (maybe a new type should be created for start room). implement doors. a door should be created only if a neighbour exists. when a player touches door, next room scene is instantiated"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Start Room Loads at Run Start (Priority: P1) 🎯 MVP

When a run begins, the starting room is immediately loaded and the player is placed inside it. The start room is a safe zone — no enemies spawn there. All other room scenes remain unloaded until the player reaches them.

**Why this priority**: The player must have somewhere to exist at run start. Without the start room being loaded, the dungeon is invisible and the game cannot begin. The no-enemy guarantee gives the player a moment to orient before combat.

**Independent Test**: Start a run. Confirm the player is inside a loaded room scene. Confirm no enemies appear in that room. Confirm that rooms other than the start room are not yet present in the scene.

**Acceptance Scenarios**:

1. **Given** a run starts, **When** the player first appears, **Then** the start room scene is loaded and the player is positioned inside it.
2. **Given** the start room is loaded, **When** inspecting its contents, **Then** no enemies are spawned — the room is empty except for the player and doors.
3. **Given** a dungeon layout with 8 rooms, **When** the run starts, **Then** only the start room scene is loaded; the other 7 rooms are not yet present.

---

### User Story 2 - Doors Appear Where Neighbours Exist (Priority: P1) 🎯 MVP

Each loaded room shows doors on the sides that connect to a neighbouring room. Sides with no neighbour have no door — just a wall. This gives the player clear, accurate navigation cues without exposing non-existent paths.

**Why this priority**: Delivered with US1. A room without doors has no navigable exits — the dungeon is unplayable. Doors must match the actual layout or the player will be confused or stuck.

**Independent Test**: Load the start room. Confirm doors appear only on the sides listed in its neighbour data. Confirm sides with no neighbour have no door. Load a room with 3 neighbours and confirm 3 doors appear.

**Acceptance Scenarios**:

1. **Given** a room is loaded, **When** inspecting its sides, **Then** a door is present on every side that has a neighbour in the layout.
2. **Given** a room is loaded, **When** inspecting its sides, **Then** no door is present on any side that has no neighbour.
3. **Given** the start room has 2 neighbours (e.g., east and south), **When** the room loads, **Then** exactly 2 doors appear — one east, one south.

---

### User Story 3 - Touching a Door Loads the Adjacent Room (Priority: P1) 🎯 MVP

When the player walks into a door, the current room is unloaded, the room on the other side is instantiated fresh, and the player is placed just inside the entrance of that room at the door on the matching side. If the destination room was previously cleared, it reappears without enemies. If it was not cleared, enemies respawn fresh.

**Why this priority**: Delivered with US1 and US2. Doors are useless without this behaviour. Unloading rooms on departure keeps only one room in memory at a time, which is the correct approach for mobile. Respawning enemies in non-cleared rooms ensures the dungeon stays challenging if the player retreats.

**Independent Test**: Start a run. Touch a door. Confirm the start room is no longer in the scene and the adjacent room is loaded with the player inside. Clear that room. Go back through the door. Re-enter — confirm the cleared room has no enemies. Leave without clearing another room. Re-enter it — confirm enemies respawn.

**Acceptance Scenarios**:

1. **Given** the player touches a door in room A, **When** the door is activated, **Then** room A is unloaded, room B is instantiated, and the player is placed just inside room B at the corresponding entrance.
2. **Given** room B was previously cleared, **When** the player re-enters room B, **Then** room B is instantiated with no enemies.
3. **Given** room B was not yet cleared, **When** the player re-enters room B, **Then** room B is instantiated and enemies spawn fresh.
4. **Given** the player enters room B from the east door of room A, **When** placed in room B, **Then** the player appears near room B's west entrance (the matching side).
5. **Given** a door connects room A (east) to room B (west), **When** the player returns from B to A through the same pair of doors, **Then** the player appears near room A's east entrance.

---

### Edge Cases

- What if the player leaves a room mid-combat (enemies still alive)? The room scene is freed; enemy state is lost. On re-entry enemies respawn fresh (Option B — intended behaviour).
- What if the player touches a door while the adjacent room is already being loaded? The second touch is ignored — no duplicate load.
- What if a room has no valid scene assigned in the layout data? Log an error and do not load; the door remains but nothing happens when touched.
- What if `neighbours_by_id` is empty or unavailable when a room loads? Log an error and create no doors — the room loads without exits.
- What if the player manages to touch two doors simultaneously? Only the first door interaction is processed; the second is ignored until the player is settled in the new room.
- What if the start room has no neighbours (isolated center)? This cannot happen with the frontier expansion algorithm (center always has at least one neighbour at TARGET_ROOM_COUNT = 8), but if it does, the start room loads with no doors and a warning is logged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When a run starts, the start room scene MUST be loaded immediately and the player MUST be placed inside it.
- **FR-002**: The start room MUST NOT spawn any enemies. A dedicated start room type with no enemy configuration MUST be used.
- **FR-003**: When a room scene is loaded, doors MUST be created for each side that has a neighbour in the dungeon layout.
- **FR-004**: Sides with no neighbour in the layout MUST NOT have a door.
- **FR-005**: When the player touches a door, the current room scene MUST be unloaded and the adjacent room scene MUST be instantiated fresh.
- **FR-006**: When the player touches a door, the player MUST be placed just inside the adjacent room at the entrance on the matching opposite side.
- **FR-007**: When a room is instantiated and its cleared state is recorded as cleared, it MUST NOT spawn enemies. When its cleared state is not cleared, enemies MUST spawn fresh.
- **FR-008**: Each door MUST know which room it connects to and which direction it faces (N/S/E/W).
- **FR-009**: The start room type MUST be a distinct room type (separate from CombatRoom* types), registered in the dungeon layout as the room at `start_room_id`.
- **FR-010**: Rooms other than the start room MUST NOT be loaded at run start — only when the player first reaches them via a door.
- **FR-011**: At any given moment, at most one room scene MUST be present in the scene — the room the player is currently in.

### Key Entities

- **Start Room**: A room type with no enemy configuration. Always assigned to the `start_room_id` cell. Loaded immediately at run start.
- **Combat Room**: Existing room type with enemy spawning. Loaded on demand when the player first touches a connecting door.
- **Door**: A navigable connection on a room's cardinal side (N/S/E/W). Only exists if a neighbour occupies the adjacent cell. Triggers the unload of the current room and the load of the neighbouring room when touched by the player.
- **Cleared Room Registry**: Persists which rooms have been fully cleared (all enemies defeated), keyed by room_id. Survives room unloading and is consulted on every room instantiation to determine whether enemies should spawn.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The start room is always loaded and contains the player within one frame of run start.
- **SC-002**: Zero enemies spawn in the start room across all runs.
- **SC-003**: Every loaded room has exactly as many doors as it has neighbours in the layout — no more, no less.
- **SC-004**: Touching a door loads the adjacent room within one frame and places the player at the correct entrance.
- **SC-005**: At all times during a run, exactly one room scene is present — the room the player currently occupies.
- **SC-006**: Re-entering a cleared room produces no enemies. Re-entering a non-cleared room produces a full fresh enemy spawn.
- **SC-007**: No errors or warnings in the output for a valid dungeon layout with correct config.

## Assumptions

- Dungeon layout (`rooms_by_id`, `neighbours_by_id`, `start_room_id`) is produced by the DungeonGenerator (008) before this system runs.
- The start room type is a new, dedicated room type (e.g., `StartRoom`) with no spawn config. It is assigned to `start_room_id` by the room-loading system at run start, overriding whatever `room_type_id` the DungeonGenerator assigned to that cell.
- Doors are placed at fixed positions at the center of each wall edge (N, S, E, W). Their world position within the room is derived from the room's world position and the door direction.
- When the player enters through a door, they are placed at a fixed entry offset from the door's position inside the new room — close to the wall but fully inside the room boundary.
- Only one room scene is in memory at a time. When the player touches a door, the current room scene is freed before the next is instantiated.
- Cleared state persists across unloads in the Cleared Room Registry (already provided by RunManager.cleared_rooms). This is the only room state that survives an unload.
- If a player leaves a non-cleared room (enemies still alive), enemy state is lost. On re-entry enemies respawn fresh — this is intentional (Option B) and serves as a soft punishment for retreating.
- Each room scene has one Door node slot per cardinal direction; the loading system enables or disables each slot based on neighbour presence.
- Corridors between rooms are out of scope — doors are direct teleport-style transitions.
- Enemy spawning in combat rooms (triggered by player entry) continues to use the existing `RoomSpawner` behaviour; this feature does not change spawning logic.
