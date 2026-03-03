# Feature Specification: Elite Room Bonuses

**Feature Branch**: `020-elite-room-bonuses`
**Created**: 2026-03-02
**Status**: Draft
**Input**: User description: "give elite rooms 1.8 essence multiplier. make the amount of enemies 1.5 times larger, rounded down"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Elite Rooms Spawn More Enemies (Priority: P1)

When a player enters an elite room, they face more enemies than the room's base configuration: the enemy count is 1.5 times the configured amount, rounded down. This increases the challenge and reinforces that elite rooms are distinct, harder encounters.

**Why this priority**: The increased enemy count is the primary gameplay signal that an elite room is dangerous. Without it, elite rooms feel identical to standard rooms. It is independently testable and defines the room's core identity.

**Independent Test**: Enter an elite room and count the enemies that spawn. Confirm the count equals floor(base_count × 1.5). For a base count of 2, expect 3 enemies; for a base count of 4, expect 6.

**Acceptance Scenarios**:

1. **Given** an elite room with 2 configured enemies, **When** the player enters, **Then** 3 enemies spawn (floor(2 × 1.5) = 3).
2. **Given** an elite room with 1 configured enemy, **When** the player enters, **Then** 1 enemy spawns (floor(1 × 1.5) = 1 — no increase at this count).
3. **Given** a standard (non-elite) room, **When** the player enters, **Then** the enemy count is unchanged from its base configuration.

---

### User Story 2 - Elite Rooms Yield More Essence (Priority: P2)

Each enemy killed inside an elite room awards 1.8 times more essence than it would in a standard room at the same depth. This rewards players who take on the added risk of elite encounters with a meaningfully larger essence haul.

**Why this priority**: The bonus essence is the payoff that makes the increased difficulty worthwhile. It can be added independently of the enemy count change, and its correctness is verifiable per-kill.

**Independent Test**: Kill an enemy in an elite room and compare the essence earned against the same enemy type killed in a standard room at the same depth. Confirm the elite room kill yields exactly 1.8× the standard amount (with normal depth scaling applied before the multiplier).

**Acceptance Scenarios**:

1. **Given** an enemy that would yield 10 essence in a standard room at depth 2, **When** killed in an elite room at depth 2, **Then** the essence earned is floor(10 × 1.8) = 18.
2. **Given** depth scaling already applied (e.g., base 10 × depth factor = 11 at depth 2), **When** killed in an elite room, **Then** the 1.8 multiplier is applied on top: floor(11 × 1.8) = 19.
3. **Given** an enemy killed in a standard room, **When** the room is not an elite room, **Then** no essence multiplier is applied and the reward is the standard depth-scaled amount.

---

### Edge Cases

- A base count of 1 enemy yields floor(1 × 1.5) = 1 — no increase. This is expected behaviour, not a bug.
- A base count of 0 (empty spawn config) yields floor(0 × 1.5) = 0 — room stays empty.
- The essence multiplier stacks with depth scaling, not replaces it. Both are applied.
- The enemy count multiplier applies only to elite rooms, not boss rooms or standard rooms.
- The extra enemies spawned (above the base count) are of the same types already configured for that elite room.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Elite rooms MUST spawn floor(base_count × 1.5) enemies, where base_count is the number of enemies defined in the room's spawn configuration.
- **FR-002**: The enemy count multiplier MUST apply only to elite rooms. Standard rooms, boss rooms, and the start room MUST be unaffected.
- **FR-003**: The extra enemies spawned above the base count MUST be chosen from the enemy types already configured for that elite room.
- **FR-004**: Each enemy kill in an elite room MUST award essence equal to the standard depth-scaled amount multiplied by 1.8.
- **FR-005**: The essence multiplier MUST apply only to elite rooms. Non-elite rooms MUST be unaffected.
- **FR-006**: Both the enemy count multiplier (1.5) and the essence multiplier (1.8) MUST be stored in configuration data, not hardcoded.

### Key Entities

- **Elite room**: A room designated as elite in the dungeon layout. Has its own spawn configuration and is the only room type affected by these bonuses.
- **Essence multiplier**: A per-room-type factor applied to each enemy's essence reward on top of existing depth scaling.
- **Enemy count multiplier**: A per-room-type factor applied to the configured spawn count, floored to a whole number.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Enemy count in elite rooms equals exactly floor(configured_count × 1.5) in 100% of runs — no deviation.
- **SC-002**: Essence earned per kill in an elite room equals exactly floor(depth_scaled_essence × 1.8) in 100% of kills — no rounding discrepancy.
- **SC-003**: Standard rooms are unaffected by either multiplier in 100% of cases — zero regression.
- **SC-004**: Both multiplier values can be changed in configuration and take effect on the next run without any code changes.

## Assumptions

- "Base count" refers to the number of spawn point entries in the elite room's spawn configuration (e.g., EliteRoom01 currently has 2 entries → 3 enemies after multiplier).
- The 1.8 essence multiplier is applied after depth scaling: `essence = floor(base_essence × depth_factor × 1.8)`.
- The additional enemies (to reach the floored total) are randomly selected from the same pool of enemy types already defined in that room's spawn config.
- Multiplier values (1.5 enemy count, 1.8 essence) are stored in the existing dungeon config data file alongside other balance values.
- Boss rooms and other special room types are out of scope — only elite rooms are affected.

## Scope

**In scope**: Elite room enemy count scaling (×1.5 floor), elite room essence reward scaling (×1.8), config-driven multiplier values.

**Out of scope**: Visual indicators of elite room bonuses, UI displaying expected elite room rewards, boss room scaling, per-enemy-type elite bonuses, stacking multipliers across multiple room types.
