# Feature Specification: Room Factory

**Feature Directory**: `006-room-factory`
**Created**: 2026-02-23
**Status**: Draft
**Input**: User description: "RoomFactory: spawn_room(room_data, room_id, context) returns a RoomController, handles attaching under a world parent node, sets spawn point / positions"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Request a Room by Type and Receive a Controller (Priority: P1)

A developer using RunManager can say "give me a room of type X with identifier Y at position Z" and receive
back a RoomController without knowing anything about which scene to load, where to attach it in the
scene tree, or how to set its position. The factory takes care of all of that.

**Why this priority**: This is the entire point of the feature. Without it, nothing else matters.
RunManager currently has no way to spawn rooms dynamically — it relies on rooms being pre-placed in the
scene. This story enables procedural / on-demand room spawning.

**Independent Test**: Call the factory with a known room type, a unique room ID, and a context containing
a parent node and world position. Confirm a RoomController is returned, the room node appears as a child
of the specified parent, and the room is positioned at the specified location.

**Acceptance Scenarios**:

1. **Given** a valid room type and a placement context, **When** the factory is asked to spawn a room,
   **Then** a RoomController instance is returned without error.
2. **Given** a spawn request, **When** the factory completes, **Then** the room node is attached as a
   child of the parent node specified in the context.
3. **Given** a spawn request with a world position in the context, **When** the factory completes,
   **Then** the room is placed at that position in the game world.
4. **Given** a valid spawn request, **When** the factory completes, **Then** the caller does not need
   to perform any additional setup — the room is immediately active.

---

### User Story 2 — RoomController Exposes Room Lifecycle (Priority: P2)

The RoomController returned by the factory gives RunManager a clean handle to observe the room's
lifecycle — when the player enters and when the room is cleared — without RunManager reaching into room
internals.

**Why this priority**: RunManager must track room state (entered, cleared) to manage run progression.
The controller is the contract between the factory output and RunManager's room-tracking logic.

**Independent Test**: Spawn a room via the factory, hold the returned RoomController, simulate player
entry and enemy defeat, and confirm the controller emits the expected lifecycle events.

**Acceptance Scenarios**:

1. **Given** a RoomController from the factory, **When** the player enters the room, **Then** the
   controller notifies observers that the room was entered.
2. **Given** a RoomController from the factory, **When** all enemies in the room are defeated, **Then**
   the controller notifies observers that the room is cleared.
3. **Given** a RoomController, **When** RunManager connects to its events, **Then** RunManager receives
   all room lifecycle notifications without accessing the room's internal nodes directly.

---

### Edge Cases

- What happens if an unknown room type is requested?
- What happens if the context specifies a parent node that no longer exists in the scene tree?
- What happens if the factory is called while a previous room of the same ID still exists?
- What happens if the factory is called with a null or missing context?

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The factory MUST accept three inputs: a room type descriptor, a unique room instance
  identifier, and a placement context.
- **FR-002**: The factory MUST return a RoomSpawner instance for every successful spawn.
- **FR-003**: The factory MUST attach the spawned room as a child of the parent node provided in the
  context — the caller MUST NOT need to call `add_child` manually.
- **FR-004**: The factory MUST apply the world position from the context to the spawned room.
- **FR-005**: The factory MUST select the correct room scene based on the room type descriptor — the
  caller MUST NOT reference scene file paths.
- **FR-006**: The RoomController MUST emit a signal when the player enters the room.
- **FR-007**: The RoomController MUST emit a signal when the room is cleared (all enemies defeated).
- **FR-008**: If an unrecognised room type is requested, the factory MUST log an error and return null
  rather than crashing.
- **FR-009**: The factory MUST NOT require the caller to perform any post-spawn setup to make the room
  functional.
- **FR-010**: The room instance identifier MUST be supplied by the caller. Neither RoomFactory nor
  RunManager MUST generate, assign, or modify room IDs — ID generation is the responsibility of
  whatever system composes the dungeon layout (e.g., a future DungeonGenerator).

### Key Entities

- **RoomFactory**: The service that receives a spawn request and returns a fully initialised
  RoomController. Owns scene loading and scene-tree attachment.
- **SpawnContext**: The placement descriptor passed to the factory. Contains at minimum the parent node
  to attach to and the world position for the room.
- **RoomData**: A saveable asset that describes one room type — the scene to spawn and an identifier.
  Authored in the editor and saved as a `.tres` file. Passed to the factory as the room type
  descriptor; the factory reads the scene reference directly from it.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: RunManager can spawn any supported room type by providing only a type identifier and
  context — zero scene path references in RunManager.
- **SC-002**: The spawned room is visible and active in the game world within one frame of the factory
  call returning.
- **SC-003**: The RoomController returned by the factory delivers all room lifecycle events to connected
  observers with no additional wiring required by the caller.
- **SC-004**: Requesting an invalid room type produces a logged error and a null return — no crash, no
  orphaned nodes.

---

## Assumptions

- Room types map to concrete scene files via a registry or configuration; this mapping is the factory's
  internal concern.
- `SpawnContext` contains exactly two pieces of caller-supplied data: the parent node and the world
  position. Additional context fields (e.g., rotation, scale) are out of scope for this feature.
- `RoomController` wraps the existing room/spawner behaviour; it does not replace the enemy spawning
  logic inside the room — it only surfaces lifecycle events to the caller.
- The factory is not an autoload; it is instantiated and owned by the caller (RunManager).
- Only one room per room_id is expected to exist at a time; the factory does not manage a pool of rooms.
- Room IDs are opaque strings from the factory's perspective — it stores and passes them through but
  never constructs or derives them. The caller is solely responsible for uniqueness.
