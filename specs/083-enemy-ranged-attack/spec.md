# Feature Specification: Enemy Ranged Attack

**Feature Branch**: `083-enemy-ranged-attack`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "if attack range of an enemy is more than 40, it should fire a projectile towards the player instead of doing melee attack when the player is in attack range. the projectile should travel in straight line, go through enemies without damaging them."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Ranged Enemy Fires Projectile Instead of Melee (Priority: P1)

A player encounters a ranged enemy (one whose attack range exceeds 40 units). When the player enters that enemy's attack range, the enemy fires a projectile toward the player rather than dealing instant melee damage. The player can see the projectile and has a brief window to dodge it.

**Why this priority**: Core mechanic — defines the entire feature. Without the projectile firing, nothing else applies.

**Independent Test**: Spawn a `forest_healer` or `forest_buffer` (both have attack_range 80), walk the player into range, and confirm a projectile is spawned and travels toward the player rather than the player receiving instant damage.

**Acceptance Scenarios**:

1. **Given** an enemy with attack_range > 40, **When** the player enters that enemy's attack range, **Then** the enemy fires a projectile toward the player's position at the moment of firing — no instant melee damage is applied.
2. **Given** an enemy with attack_range ≤ 40, **When** the player enters attack range, **Then** the existing melee damage behaviour is unchanged.
3. **Given** a ranged enemy on its damage cooldown, **When** the cooldown expires and the player is still in range, **Then** the enemy fires again.

---

### User Story 2 - Projectile Travels in a Straight Line (Priority: P1)

Once fired, the projectile moves in a straight line toward the player's position at the moment of firing. It does not track or curve. The player can sidestep it after it is launched.

**Why this priority**: Directly required by the spec; determines the skill ceiling for the player interaction.

**Independent Test**: Fire a projectile, then move the player perpendicular to the projectile's path — the projectile continues in its original direction and misses.

**Acceptance Scenarios**:

1. **Given** a projectile is fired toward the player's current position, **When** the player moves sideways after the projectile is launched, **Then** the projectile does not change course and continues on its original trajectory.
2. **Given** a projectile in flight, **When** it reaches the player, **Then** it applies the firing enemy's damage value to the player and disappears.
3. **Given** a projectile in flight, **When** it travels beyond the room bounds without hitting the player, **Then** it disappears automatically.

---

### User Story 3 - Projectile Passes Through Enemies (Priority: P1)

The projectile moves through other enemies in the room without damaging or interacting with them. Only the player can be hit by it.

**Why this priority**: Explicitly required; if enemies could block each other's projectiles the encounter design would break.

**Independent Test**: Position enemies between the firing enemy and the player; confirm the projectile passes through intermediate enemies and does not reduce their HP.

**Acceptance Scenarios**:

1. **Given** a projectile in flight, **When** it overlaps another enemy, **Then** the enemy's HP is unchanged and the projectile continues on its path.
2. **Given** a projectile in flight, **When** it overlaps the player, **Then** the player receives damage and the projectile disappears.

---

### Edge Cases

- What if the player is at zero distance from the enemy when the projectile fires? → Projectile fires in the direction the enemy is facing; if direction is undefined, use the last known player direction.
- What if the player leaves attack range immediately after a projectile is fired? → The projectile continues to its natural end — it is not recalled.
- What if multiple ranged enemies fire simultaneously? → Each spawns its own independent projectile; they do not interact with each other.
- What if a ranged enemy is killed while its projectile is in flight? → The projectile continues until it hits the player or leaves the room.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Any enemy whose `attack_range` value exceeds 40 MUST fire a projectile when the player enters its attack range, instead of applying melee damage.
- **FR-002**: Enemies with `attack_range` ≤ 40 MUST continue to use the existing melee attack behaviour unchanged.
- **FR-003**: The projectile MUST travel in a straight line from the enemy's position toward the player's position at the moment of firing.
- **FR-004**: The projectile MUST NOT home, curve, or adjust course after being fired.
- **FR-005**: The projectile MUST deal damage equal to the firing enemy's `damage` value when it hits the player.
- **FR-006**: The projectile MUST disappear on hitting the player.
- **FR-007**: The projectile MUST disappear when it travels outside the room bounds.
- **FR-008**: The projectile MUST pass through other enemies without dealing damage to them or being stopped by them.
- **FR-009**: The ranged attack MUST respect the enemy's `damage_cooldown` — the enemy fires no more than once per cooldown cycle.
- **FR-010**: The threshold value of 40 MUST be a data-driven constant, not hard-coded in game logic.

### Key Entities

- **Ranged Enemy**: Any enemy whose `attack_range` exceeds the ranged threshold. Uses the existing `damage` and `damage_cooldown` fields. No new data fields required.
- **Enemy Projectile**: A short-lived moving object fired by a ranged enemy. Carries a damage value, travels at fixed speed in a straight line, collides only with the player, and auto-despawns on hit or when out of bounds.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every ranged enemy encounter results in a visible projectile being fired — zero cases of silent instant damage when attack_range > 40.
- **SC-002**: The projectile reaches the player's launch-time position on a straight path in all observed test cases — no curve or homing detected.
- **SC-003**: Across 20 observed projectile flights through enemy-occupied positions, zero enemy HP reductions occur from projectile contact.
- **SC-004**: All existing melee-only enemies (attack_range ≤ 40) exhibit unchanged behaviour after this feature is introduced.

## Assumptions

- **Projectile speed**: Fixed at 400 px/s — fast enough to require player attention but slow enough to be visible. Can be tuned per enemy via a future `projectile_speed` field without code changes if needed.
- **Ranged threshold**: The value 40 will be stored in `dungeon_config.json` as `enemy_ranged_threshold` (or equivalent) so it can be tuned without touching GDScript.
- **Damage value**: Projectile deals the same `damage` as the melee attack would — no separate projectile damage field is required at this stage.
- **Visual**: A simple colored shape is sufficient for initial implementation; no sprite asset is required at spec stage.
- **No new enemy data fields**: The existing `attack_range`, `damage`, and `damage_cooldown` fields fully define ranged behaviour. No schema additions to `enemies.json` are needed.
- **Affected enemies** (current data): `forest_healer` (attack_range 80) and `forest_buffer` (attack_range 80) become ranged attackers. All others remain melee.
