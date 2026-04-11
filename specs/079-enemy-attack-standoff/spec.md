# Feature Specification: Enemy Attack Standoff Distance

**Feature Branch**: `079-enemy-attack-standoff`
**Created**: 2026-03-21
**Status**: Draft
**Input**: User description: "make enemy stop in attack radius - 10 from a player when enemy is pursuing"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enemy Stops Before Attack Radius Edge (Priority: P1)

When an enemy is pursuing the player, it slows and stops at a position that is 10 units inside the outer edge of its attack radius. The enemy does not walk all the way up to the boundary — it holds a small standoff gap.

**Why this priority**: This is the entire feature. The standoff distance produces more natural-feeling enemy spacing and ensures the enemy is clearly within attack range before halting.

**Independent Test**: Observe a pursuing enemy — it should stop before touching the attack radius edge, with a visible gap of ~10 units.

**Acceptance Scenarios**:

1. **Given** an enemy is in PURSUING state and the player is farther than `attack_range - 10`, **When** the enemy moves toward the player, **Then** the enemy continues approaching.
2. **Given** an enemy is in PURSUING state and `dist <= attack_range - 10`, **When** physics is processed, **Then** the enemy's velocity is zero and it does not move closer.
3. **Given** `attack_range` is 100, **When** the player is at distance 89, **Then** the enemy has already stopped (89 < 90 = attack_range - 10).
4. **Given** the enemy has already stopped at standoff, **When** the player moves further away beyond `attack_range - 10`, **Then** the enemy resumes pursuit.

---

### User Story 2 - Standoff Does Not Apply to Healer Follow (Priority: P2)

The healer enemy follow behavior (orbiting an ally at `heal_radius - 20`) is unaffected by this change.

**Why this priority**: The healer uses a separate movement path and already has its own standoff logic; this feature must not accidentally change it.

**Independent Test**: Observe a healer enemy orbiting an ally — its standoff distance is still `heal_radius - 20`, unchanged.

**Acceptance Scenarios**:

1. **Given** a healer enemy is following an ally, **When** it moves, **Then** it stops at `heal_radius - 20`, not at `attack_range - 10`.

---

### Edge Cases

- What happens when `attack_range` is less than 10? The standoff becomes `attack_range - 10 < 0`; the enemy should clamp to a minimum standoff of 0 (never require the enemy to be inside the player).
- What if the player stands exactly at distance `attack_range - 10`? The enemy remains stopped (boundary is inclusive stop condition).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When an enemy is in the PURSUING state, it MUST stop moving when the distance to the player is less than or equal to `attack_range - 10`.
- **FR-002**: The standoff threshold MUST be clamped to a minimum of 0 to handle edge cases where `attack_range < 10`.
- **FR-003**: The enemy MUST resume pursuit when the player's distance exceeds `attack_range - 10`.
- **FR-004**: The healer enemy's orbit standoff (`heal_radius - 20`) MUST remain unchanged.
- **FR-005**: All other enemy movement logic (rooting, poisoning, speed scaling) MUST remain unaffected.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A pursuing enemy stops at a distance of exactly `attack_range - 10` (clamped to ≥ 0) from the player in all test configurations.
- **SC-002**: No existing enemy movement behaviors (healer follow, root, poison) are altered by this change.
- **SC-003**: The change is a single-line modification to the pursuit stop condition in `Enemy.gd`.
