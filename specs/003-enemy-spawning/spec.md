# Feature Specification: Enemy Spawning

**Feature Directory**: `003-enemy-spawning`
**Created**: 2026-02-20
**Status**: Draft
**Input**: User description: "enemy spawning"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Room Populates with Enemies on Entry (Priority: P1)

When the player enters a dungeon room, enemies appear at predefined positions within that room. The player can then engage them using the combat system. Without spawning, the combat feature has no enemies to fight.

**Why this priority**: Enemy spawning is the bridge between the dungeon navigation and the combat system. It is the minimum viable slice that makes combat functional in actual gameplay.

**Independent Test**: Enter a room that has one spawn point configured. Confirm one enemy appears at that position within half a second of entry. No room-clearing or randomisation required.

**Acceptance Scenarios**:

1. **Given** a room with two spawn points configured, **When** the player enters the room, **Then** one enemy appears at each spawn point before the player can act.
2. **Given** the player re-enters a room that has already been cleared, **When** entry occurs, **Then** no new enemies are spawned.
3. **Given** a room with zero spawn points configured, **When** the player enters, **Then** no enemies appear and no error occurs.

---

### User Story 2 - Enemy Composition Defined in Game Data (Priority: P2)

Each room type specifies which enemy types spawn and in what quantities through external game data, not hardcoded values. A designer can change which enemies appear in a room without touching any game logic.

**Why this priority**: Data-driven spawning is what separates a rigid prototype from a tunable game. It enables room variety across the dungeon without additional code.

**Independent Test**: Define two different room types in game data — one with slimes, one with skeletons. Enter both rooms and confirm each spawns the correct enemy type and quantity as defined in the data file.

**Acceptance Scenarios**:

1. **Given** a room type configured with two slimes in game data, **When** the player enters that room, **Then** exactly two Slime enemies appear.
2. **Given** a room type configured with one skeleton in game data, **When** the player enters that room, **Then** exactly one Skeleton enemy appears.
3. **Given** a designer changes an enemy type in the room's data entry, **When** the game is launched, **Then** the updated enemy type appears with no code changes required.

---

### User Story 3 - Room Clears When All Enemies Are Defeated (Priority: P3)

The room tracks how many enemies are alive. When the last enemy is defeated, the room transitions to a "cleared" state. This gives combat a win condition and prevents re-spawning on re-entry.

**Why this priority**: Without a cleared state, the player has no feedback that a room is done, and re-entering would spawn enemies again — breaking the roguelite structure.

**Independent Test**: Spawn two enemies in a room. Defeat them both. Confirm the room is marked cleared immediately after the second death. Re-enter the room and confirm no enemies appear.

**Acceptance Scenarios**:

1. **Given** a room with two enemies, **When** one is defeated, **Then** the room is not yet cleared and the remaining enemy is still active.
2. **Given** a room with two enemies, **When** the second is defeated, **Then** the room transitions to cleared state within one frame.
3. **Given** a cleared room, **When** the player enters it again, **Then** no enemies spawn.

---

### User Story 4 - Randomised Spawn Positions (Priority: P4)

Each spawn point has a configurable randomisation radius. On each run, enemies appear at a random position within that radius rather than at the exact same coordinates, creating variety between playthroughs.

**Why this priority**: Deterministic spawn positions make the game feel repetitive quickly. Slight randomisation is low-cost variety that meaningfully improves replayability.

**Independent Test**: Configure one spawn point with a non-zero randomisation radius. Run the room twice. Confirm the enemy appears at a different position each time, within the defined radius.

**Acceptance Scenarios**:

1. **Given** a spawn point with radius 0, **When** the room is entered on two separate runs, **Then** the enemy appears at the same position both times.
2. **Given** a spawn point with radius 50, **When** the room is entered on two separate runs, **Then** the enemy positions differ and both are within 50 units of the spawn point centre.
3. **Given** a spawn point with a non-zero radius, **When** the enemy spawns, **Then** its position is always within the room's navigable area.

---

### Edge Cases

- What happens if a spawn point is placed outside the room boundary?
- What happens if two enemies spawn at exactly the same position?
- What happens if the enemy type ID in a spawn config does not exist in game data?
- What happens if the player defeats all enemies before the spawn animation completes?
- What happens if a room is entered before the previous room's state is saved?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the player enters a room, the system MUST spawn all enemies defined in that room's spawn configuration before gameplay begins.
- **FR-002**: A room with no spawn points configured MUST be entered without error and without spawning any enemies.
- **FR-003**: Each spawn point MUST reference an enemy type by ID; the system MUST assert that the ID exists in game data and report a clear error if it does not.
- **FR-004**: Enemy type, quantity, position, and randomisation radius for each room MUST be defined in external game data, not hardcoded.
- **FR-005**: The room MUST track the number of living enemies and decrement this count when each enemy is defeated.
- **FR-006**: When the living enemy count reaches zero, the room MUST transition to cleared state immediately.
- **FR-007**: A cleared room MUST NOT spawn enemies again if the player re-enters during the same run.
- **FR-008**: Each spawn point MAY specify a randomisation radius; if greater than zero, the enemy MUST appear at a random position within that radius of the point's centre.
- **FR-009**: At most 10 enemies may be configured per room (enforced by data validation at load time).

### Key Entities

- **SpawnPoint**: A single spawn definition within a room. Has a centre position, an enemy type ID, and a randomisation radius (0 = exact position).
- **RoomSpawnConfig**: The complete spawn configuration for one room type — an ordered collection of SpawnPoints. Stored in game data.
- **Room**: A dungeon area that holds a RoomSpawnConfig, tracks living enemy count, and holds cleared state for the current run.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All configured enemies appear within 0.5 seconds of the player entering a room, measured from the moment of entry detection.
- **SC-002**: Editing an enemy type or quantity in a room's data entry is reflected in the next game launch with zero code changes.
- **SC-003**: A room transitions to cleared state within one frame of the last enemy being defeated, with no delay.
- **SC-004**: Two playthroughs of the same room with a non-zero randomisation radius produce enemy start positions that differ by at least 1 unit on at least one axis.
- **SC-005**: Ten enemies spawning simultaneously in one room produce no visible frame-rate drop on the target mobile device.

## Assumptions

- Enemies spawn all at once when the room is entered; wave-based or timed spawning is a future feature.
- "Cleared state" means the room is flagged done for the current run; visual feedback (fanfare, door unlocking) is out of scope.
- The player's start position within a room is always clear of enemy spawn points — overlap prevention is the designer's responsibility via data.
- Room scenes already exist as scaffolding (`CombatRoom01.tscn`, etc.); this feature adds spawn logic to them.
- Run-level persistence of cleared rooms (so the state survives scene transitions) is assumed to be handled by an existing RunManager; this feature only sets the cleared flag.
- Enemy type IDs referenced in spawn configs must exist in `enemies.json`; this feature validates at load time but does not create new enemy types.
