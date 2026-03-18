# Feature Specification: Room Wave System

**Feature Branch**: `056-wave-system`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "add wave system to rooms. the room should do this: initial_spawn = 3, alive_cap = 4, wave_1: 3 enemies, trigger: alive <= 1, wave_2: 2 enemies, trigger: alive <= 1, wave_3: 1 enemy. room is cleared when all enemies in all waves are killed. the enemies should not spawn on top of the player"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Waves Spawn and Progress Automatically (Priority: P1)

When the player enters a combat room, wave 1 spawns immediately (3 enemies). As the player kills enemies and the alive count drops to 1, wave 2 spawns automatically (2 enemies), then wave 3 (1 enemy) by the same trigger. The room is not cleared until every enemy across all three waves is dead — 6 total kills.

**Why this priority**: This is the core mechanic — without wave spawning and progression the feature doesn't exist.

**Independent Test**: Enter a combat room. Verify 3 enemies spawn immediately (wave 1). Kill 2 (leaving 1 alive). Verify wave 2 spawns (2 enemies). Kill all but 1. Verify wave 3 spawns (1 enemy). Kill that last enemy. Verify room is marked cleared after the 6th kill and not before.

**Acceptance Scenarios**:

1. **Given** a player enters a combat room, **When** the room loads, **Then** exactly 3 enemies spawn (the initial wave).
2. **Given** 3 enemies are alive, **When** the player kills 2 (leaving 1 alive), **Then** the next wave spawns immediately, bringing alive count to `1 + wave_size` (capped at `alive_cap = 4`).
3. **Given** wave 1 has triggered and wave 2 enemies are alive, **When** all but 1 are killed, **Then** wave 3 spawns.
4. **Given** all three waves have been spawned, **When** the last enemy dies, **Then** the room is marked cleared.
5. **Given** waves 1 and 2 are pending, **When** enemies die faster than waves spawn, **Then** the alive count never exceeds `alive_cap = 4` at the moment of any spawn.

---

### User Story 2 — Enemies Do Not Spawn on the Player (Priority: P2)

All enemies — initial wave and subsequent waves — spawn at positions that are not occupied by the player, ensuring no instant-damage or overlap on spawn.

**Why this priority**: Player experience integrity. Spawning on the player would cause unavoidable damage and feel unfair.

**Independent Test**: Enter a combat room and stand still. Observe 3 initial spawns and all subsequent wave spawns. Verify no enemy appears at or immediately adjacent to the player's position.

**Acceptance Scenarios**:

1. **Given** a player is standing anywhere in the room, **When** any wave spawns, **Then** all enemies in that wave appear at positions at least a minimum safe distance from the player.
2. **Given** a spawn point is within the minimum safe distance of the player, **When** that wave spawns, **Then** an alternate spawn position is chosen for that enemy (not suppressed entirely).

---

### Edge Cases

- What if all waves are triggered before all prior-wave enemies are dead (e.g., player kills very fast)? The alive cap of 4 limits concurrent alive enemies; later waves only trigger when the threshold is met after all prior wave enemies are also counted.
- What if the room has fewer spawn points than the wave size? All available spawn points are used; any excess enemies in that wave are queued or dropped (see Assumptions).
- What if the player stands on every spawn point? The system picks the farthest available point or falls back to any non-blocked point rather than refusing to spawn.
- What happens if the player dies mid-wave? Room state is abandoned with the run; waves do not persist or resume on re-entry within the same run (room already marked visited).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: On room entry, the system MUST spawn wave 1 immediately — exactly 3 enemies.
- **FR-002**: After any spawn event, the system MUST monitor alive enemy count and trigger the next wave when `alive_count <= 1`.
- **FR-003**: Wave 1 MUST contain 3 enemies; Wave 2 MUST contain 2 enemies; Wave 3 MUST contain 1 enemy.
- **FR-004**: At no spawn event MUST the total alive enemies exceed `alive_cap = 4`.
- **FR-005**: The room MUST NOT emit the "room cleared" signal until all enemies across all waves (6 total: 3 + 2 + 1) are dead.
- **FR-006**: Each enemy MUST spawn at a position that is at least a configurable minimum distance from the player's current position at spawn time.
- **FR-007**: The wave configuration (initial count, alive cap, wave sizes, trigger threshold) MUST be defined in data, not hard-coded in script logic, so values can be tuned without code changes.
- **FR-008**: The wave system MUST be compatible with the existing `RoomSpawner` component and the existing room-cleared signal flow consumed by `RunManager`.

### Key Entities

- **Wave**: An ordered group of enemies to spawn. Attributes: `size` (enemy count), `trigger_threshold` (alive count at which this wave fires). Waves are numbered and resolved in order.
- **WaveState**: Runtime tracking of which wave is next, how many enemies are alive, and how many total have been spawned. Transient — discarded when the room is freed.
- **SpawnPoint**: A position in the room where an enemy can be placed. Already exists in the room scene; the wave system reads these and filters by player proximity.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every combat room session produces exactly 6 enemy kills required for room clear (3 + 2 + 1 across waves).
- **SC-002**: The alive enemy count never exceeds 4 at any point during a room encounter.
- **SC-003**: Wave transitions (next wave spawning) occur within one game frame of the alive count reaching the trigger threshold.
- **SC-004**: Zero percent of spawn events place an enemy closer than the configured minimum safe distance to the player.
- **SC-005**: Room clear fires exactly once per room, only after the 6th enemy dies — not after any intermediate wave completes.

## Assumptions

- Enemy type per spawn point is determined by the room's existing spawn config in `dungeon_config.json` (unchanged). The wave system controls *when* and *how many* enemies spawn, not *which* enemy type — that remains driven by the existing spawn config.
- The minimum safe spawn distance defaults to 200 units. This will be a configurable value in `dungeon_config.json` or the room's spawn config.
- If a wave is triggered before the previous wave's enemies are all dead (all alive slots taken), the trigger check is re-evaluated each time an enemy dies rather than queued — the wave fires as soon as the threshold is met.
- The wave sizes (3, 2, 1) and trigger threshold (alive <= 1) apply uniformly to all combat rooms. Per-room overrides are out of scope for this feature.
- `alive_cap = 4` is enforced as a hard cap at spawn time: if spawning a full wave would push alive count above 4, only as many enemies as fit within the cap are spawned (remainder are discarded for this wave, not queued). In normal play the cap is never hit: wave 1 spawns 3, trigger fires at 1 alive, so wave 2 spawns 2 (total 3), and wave 3 spawns 1 (total 2 max). The cap acts as a safety guard rather than a regular constraint.
