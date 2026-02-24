# Feature Specification: Dungeon Generator

**Feature Branch**: `007-dungeon-generator`
**Created**: 2026-02-23
**Status**: Draft
**Input**: User description: "dungeon generator. should spawn rooms on start_run (for now, combat room 1, 2 and elite room 1) in a straight line and put the player in the first room spawned."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Rooms Spawn on Run Start (Priority: P1) 🎯 MVP

When a run begins, the dungeon generator automatically spawns a fixed sequence of rooms laid out in a straight horizontal line. For now the sequence is always: CombatRoom01, CombatRoom02, EliteRoom01. Each room appears at a fixed interval along the X axis so they are visually separated and non-overlapping.

**Why this priority**: Without rooms there is no dungeon. This is the foundational capability every other dungeon feature builds on. The room sequence and layout algorithm (straight line, fixed spacing) can be iterated later without changing this contract.

**Independent Test**: Start a run. Confirm three room scenes appear in the world at evenly-spaced positions along the X axis. Confirm each room has the correct visual/type (CombatRoom01, CombatRoom02, EliteRoom01 in order).

**Acceptance Scenarios**:

1. **Given** a new run is started, **When** the dungeon generator runs, **Then** exactly three rooms appear in the world: CombatRoom01 at position index 0, CombatRoom02 at index 1, EliteRoom01 at index 2.
2. **Given** three rooms are spawned, **When** inspecting their world positions, **Then** each room is offset from the previous by a fixed spacing along the X axis (e.g. 1200 px), so rooms do not overlap.
3. **Given** a run is started, **When** all rooms are spawned, **Then** each room has a unique, caller-supplied room ID (e.g. `"room_0"`, `"room_1"`, `"room_2"`).
4. **Given** the dungeon generator spawns rooms, **When** a room's `room_entered` signal fires, **Then** RunManager correctly tracks entry (existing behavior, unaffected).

---

### User Story 2 - Player Placed in First Room (Priority: P1) 🎯 MVP

After rooms are spawned the player is teleported to the first room so the run begins at the correct location. The player should be at the room's world position so they are standing inside it when gameplay starts.

**Why this priority**: Delivered together with US1 — rooms without a starting position are unplayable. Placing the player is a one-liner that completes the MVP slice.

**Independent Test**: Start a run. Confirm the player's world position matches (or is within) the first spawned room's position.

**Acceptance Scenarios**:

1. **Given** rooms are spawned, **When** the dungeon generator finishes, **Then** the player node's global position is set to the first room's world position.
2. **Given** the player is placed in the first room, **When** they move into the EntryArea, **Then** `room_entered` fires normally (existing spawner behaviour unaffected).

---

### Edge Cases

- What if a RoomData `.tres` asset is missing or its scene field is null? The factory returns null — the generator logs an error and stops spawning further rooms.
- What if the player node cannot be found in the scene tree? Log an error; rooms are still spawned.
- Starting a second run while the first is still active: rooms from the previous run remain (cleanup is out of scope for this feature).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On `start_run`, the dungeon generator MUST spawn rooms in this fixed order: CombatRoom01, CombatRoom02, EliteRoom01.
- **FR-002**: Rooms MUST be positioned in a straight horizontal line, each offset by a fixed spacing from the previous room (default: 1200 px along X axis).
- **FR-003**: The generator MUST assign a unique, deterministic room ID to each spawned room (format: `"room_0"`, `"room_1"`, `"room_2"`).
- **FR-004**: The generator MUST use `RunManager.spawn_room()` to instantiate each room (delegates to RoomFactory — no direct scene instantiation).
- **FR-005**: After all rooms are spawned, the generator MUST set the player's `global_position` to the first room's world position.
- **FR-006**: The generator MUST load room types from `data/rooms/*.tres` RoomData assets (not hardcoded scene paths).
- **FR-007**: If `RunManager.spawn_room()` returns null for a room, the generator MUST log an error and skip that room (partial dungeon is acceptable over a crash).
- **FR-008**: The generator MUST NOT generate room IDs — IDs are caller-supplied constants (`"room_0"`, `"room_1"`, `"room_2"`).

### Key Entities

- **DungeonGenerator**: Autoloaded or scene-attached node that reacts to run start and orchestrates room spawning. Holds the room sequence definition and spacing constant.
- **Room Sequence**: Ordered list of RoomData resources defining which rooms to spawn, in order. Hard-coded for now (3 rooms).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Starting a run always produces exactly 3 rooms in the scene tree, no more, no less.
- **SC-002**: Room positions are non-overlapping — each room center is at least 1000 px from the next.
- **SC-003**: The player's starting position after run start matches the first room's world position (within 1 px tolerance).
- **SC-004**: No errors or warnings are printed to the Godot output when a valid run is started.
- **SC-005**: Pre-placed rooms (auto_register path) continue to work correctly — DungeonGenerator does not interfere with them.

## Assumptions

- Room spacing of 1200 px along X is sufficient to prevent visual overlap for the current room scene sizes. This can be tuned later.
- The player node is accessible via a group (`"player"`) or a known scene path. Generator uses the group lookup `get_tree().get_first_node_in_group("player")`.
- Rooms are spawned as children of the same parent node the generator lives under (or a designated world/level node). A `SpawnContext` is constructed with that parent and computed position.
- The first room spawns at the generator's own position (or `Vector2.ZERO` relative to the parent), and subsequent rooms are offset by `+1200` on X.
- Room cleanup between runs is out of scope — handled by a future run-reset feature.
- The generator attaches to the existing Main scene or a dedicated level node; it does not need its own scene file (script-only node is acceptable).
