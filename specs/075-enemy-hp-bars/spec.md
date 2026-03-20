# Feature Specification: Enemy HP Bars

**Feature Branch**: `075-enemy-hp-bars`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "draw placeholder hpbars for enemies under each enemy. should work as player hp bar. should move with the enemy"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - HP Bar Visible Under Enemy (Priority: P1)

While in combat, each living enemy displays a health bar positioned just below its sprite. As the enemy takes damage, the bar shrinks proportionally. As the enemy moves around the room, the bar stays attached beneath it.

**Why this priority**: Core readability feature — players cannot gauge combat threat or prioritise targets without visible enemy health.

**Independent Test**: Spawn any enemy; confirm a health bar appears under it, shrinks on damage, and follows the enemy's position.

**Acceptance Scenarios**:

1. **Given** an enemy spawns in a combat room, **When** the room is entered, **Then** a health bar is visible beneath the enemy at all times.
2. **Given** an enemy has taken damage, **When** the player looks at it, **Then** the bar width reflects the current HP fraction (e.g. 50% HP = half-width bar).
3. **Given** an enemy is moving, **When** observing it, **Then** the health bar moves with the enemy and remains centred below it.
4. **Given** an enemy dies, **When** the defeat animation plays, **Then** the health bar disappears along with the enemy.

---

### User Story 2 - Bar Matches Player HP Bar Behaviour (Priority: P2)

The enemy HP bar follows the same visual logic as the existing player HP bar: it shrinks from right to left as HP decreases and stretches back as HP recovers (e.g. from a healer enemy).

**Why this priority**: Visual consistency reduces cognitive load — players already understand the player bar metaphor.

**Independent Test**: Damage an enemy to partial HP, then let a healer enemy restore it; confirm the bar shrinks and grows accordingly.

**Acceptance Scenarios**:

1. **Given** an enemy at full HP, **When** no damage has been taken, **Then** the bar is fully filled.
2. **Given** an enemy at partial HP, **When** a healer restores health, **Then** the bar grows to reflect the new HP value.

---

### Edge Cases

- What happens when an enemy is at exactly 0 HP (dying frame)? Bar should disappear with the enemy node.
- What happens if difficulty scaling raises max HP after spawn? Bar should reflect the scaled max HP, not the base value.
- What happens for the boss enemy? Bar should appear the same as regular enemies (no special treatment required at this stage).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each enemy MUST display a health bar positioned below its visual centre.
- **FR-002**: The health bar MUST update immediately whenever the enemy's current HP changes.
- **FR-003**: The bar fill fraction MUST equal `current_hp / max_hp` at all times.
- **FR-004**: The health bar MUST follow the enemy's world position — it is attached to the enemy, not fixed to the screen.
- **FR-005**: The health bar MUST disappear when the enemy is removed from the scene.
- **FR-006**: The health bar MAY use placeholder coloured rectangles (no sprite assets required).
- **FR-007**: The health bar MUST work correctly after difficulty scaling changes the enemy's max HP.

### Key Entities

- **EnemyHPBar**: A visual component attached to each enemy instance. Tracks current and max HP, renders a fill bar, and updates position each frame to follow the enemy.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every enemy in a combat room has a visible health bar at all times during combat.
- **SC-002**: The bar fill accurately represents current HP fraction — verified at 100%, 50%, and 1 HP.
- **SC-003**: The bar position stays within 5px of its target offset below the enemy across all movement speeds.
- **SC-004**: No health bars remain visible after an enemy is defeated.
