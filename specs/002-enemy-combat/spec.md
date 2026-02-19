# Feature Specification: Enemy Combat System

**Feature Directory**: `002-enemy-combat`
**Created**: 2026-02-19
**Status**: Draft
**Input**: User description: "add enemy combat system"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Encounter and Defeat Enemies (Priority: P1)

A player exploring a dungeon room encounters one or more enemies. The player engages them and, after dealing enough damage, the enemies are defeated and removed from the room. This is the core gameplay loop that makes the dungeon feel dangerous and rewarding.

**Why this priority**: Without enemies that can be damaged and killed, there is no combat — this is the minimum viable combat feature. All other stories build on top of this.

**Independent Test**: Place a single enemy in a test room. Confirm the player can damage it repeatedly until it dies and disappears, without implementing player damage or AI pursuit.

**Acceptance Scenarios**:

1. **Given** an enemy is present in the room, **When** the player deals damage to the enemy, **Then** the enemy's remaining health decreases by the correct amount.
2. **Given** an enemy's health reaches zero, **When** that damage is applied, **Then** the enemy is immediately removed from the room and is no longer collidable.
3. **Given** multiple enemies are present, **When** one enemy is defeated, **Then** only that enemy is removed; the others continue normally.

---

### User Story 2 - Receive Damage from Enemies (Priority: P2)

Enemies deal damage to the player when they make contact or successfully perform an attack. The player's health decreases accordingly. If the player's health reaches zero, the run ends.

**Why this priority**: One-sided combat (player attacks but enemies cannot retaliate) removes all tension. This story completes the combat loop established in US1.

**Independent Test**: Place a stationary enemy that deals contact damage. Walk the player into it and confirm health decreases. Reduce health to zero and confirm the run-end state is triggered.

**Acceptance Scenarios**:

1. **Given** the player is in contact with an enemy, **When** contact damage is applied, **Then** the player's health decreases by the enemy's damage value.
2. **Given** the player has taken contact damage, **When** the damage interval has not yet elapsed, **Then** no additional contact damage is dealt (damage cooldown prevents instant drain).
3. **Given** the player's health reaches zero, **When** that damage is applied, **Then** the run-end state is triggered.

---

### User Story 3 - Enemies Pursue the Player (Priority: P3)

Enemies detect the player when they come within a set range and begin moving toward them. If the player leaves detection range, the enemy stops pursuing.

**Why this priority**: Stationary enemies are trivial to avoid. Pursuit makes encounters dynamic and forces the player to make movement decisions during combat.

**Independent Test**: Place a stationary enemy and walk the player into its detection radius. Confirm the enemy begins moving toward the player. Walk the player out of range and confirm the enemy stops.

**Acceptance Scenarios**:

1. **Given** the player is outside the enemy's detection range, **When** the player enters that range, **Then** the enemy begins moving toward the player within one second.
2. **Given** the enemy is pursuing the player, **When** the player moves outside detection range, **Then** the enemy stops pursuing and becomes idle.
3. **Given** the enemy is pursuing the player, **When** the enemy makes contact, **Then** contact damage is applied per US2 rules.

---

### User Story 4 - Enemy Variety via Configurable Stats (Priority: P4)

Each enemy type can have different values for health, damage, movement speed, and detection range, defined in game data rather than hardcoded. This allows designers to create distinct enemy archetypes without changing game logic.

**Why this priority**: Variety makes combat interesting over multiple runs. However, the system must work with at least one enemy type before variety is meaningful.

**Independent Test**: Define two enemy types with different health and damage values in the game data. Spawn both in the same room and confirm each behaves according to its own stats.

**Acceptance Scenarios**:

1. **Given** two enemy types with different health values, **When** both receive the same damage, **Then** each loses the correct amount of health according to their individual stat.
2. **Given** two enemy types with different speeds, **When** both are pursuing the player, **Then** the faster enemy visibly closes the gap sooner.
3. **Given** a designer edits an enemy's damage value in game data, **When** the game is launched, **Then** the enemy deals the updated damage amount with no code changes.

---

### Edge Cases

- What happens when an enemy is defeated at the exact moment it deals damage?
- How does the system handle an enemy outside the room's navigable area?
- What happens if multiple enemies deal contact damage simultaneously?
- How does the run-end state interact with in-progress enemy attacks?
- What happens when a room has no enemies (empty room)?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST track a current health value for each enemy instance, initialized from its type definition.
- **FR-002**: The system MUST reduce an enemy's health when it receives damage, by the exact damage amount.
- **FR-003**: When an enemy's health reaches zero or below, the system MUST remove that enemy from the room immediately.
- **FR-004**: The system MUST track the player's current health and reduce it when an enemy deals contact damage.
- **FR-005**: Contact damage MUST be subject to a per-enemy cooldown so the player cannot lose more than one damage instance per cooldown interval from a single enemy.
- **FR-006**: When the player's health reaches zero or below, the system MUST trigger the run-end state.
- **FR-007**: Each enemy MUST begin moving toward the player when the player enters the enemy's detection range.
- **FR-008**: Each enemy MUST stop moving when the player exits its detection range.
- **FR-009**: Enemy stats (health, damage, movement speed, detection range, damage cooldown) MUST be defined in external game data, not hardcoded.
- **FR-010**: Multiple enemies (at least 10) MUST be independently tracked and updated simultaneously without one affecting another's state.

### Key Entities

- **Enemy**: A hostile character in the dungeon. Has health, damage output, movement speed, detection range, and a damage cooldown timer. Can be in idle or pursuing state.
- **EnemyType**: A data record defining the base stats shared by all instances of a given enemy variety (e.g., "Slime", "Skeleton").
- **Player** *(existing)*: The character controlled by the player. Has a health value that enemies reduce. Already exists; this feature extends it with a health-damage contract.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An enemy with 3 health points is defeated after exactly 3 single-damage hits, with no enemy remaining in the room after the third hit.
- **SC-002**: Enemy pursuit begins within 1 second of the player entering detection range, measured from the moment of entry.
- **SC-003**: A player taking contact damage from a single enemy loses no more than one damage instance per 0.5-second cooldown window.
- **SC-004**: Ten simultaneously active enemies in one room maintain smooth gameplay (no visible slowdown) on the target mobile device.
- **SC-005**: Changing an enemy stat in game data is reflected in the next game launch with zero code modifications required.

## Assumptions

- The player already has a health value that can be read and written; this feature adds the write path from enemy damage.
- "Defeat" means the enemy disappears from the room; loot drops, animations, and sound are out of scope for this feature.
- Contact damage is the only damage mechanism in scope; ranged or projectile attacks are a future feature.
- Navigation/pathfinding (e.g., moving around walls) is out of scope; enemies move directly toward the player in open rooms.
- Enemy spawning (when/where enemies appear) is out of scope; this feature assumes enemies are already placed in the room.
- A single enemy type is sufficient to validate the system; the data-driven stat system (US4) enables variety without additional logic.
