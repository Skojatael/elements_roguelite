# Feature Specification: Enemy Shield Mechanic

**Feature Branch**: `087-enemy-shield`
**Created**: 2026-03-29
**Status**: Draft
**Input**: User description: "add a shield mechanic to enemies (currently, forest_boss_thorns only). the trigger condition for shield will be added separately. when shield is active, another visual is added on top of the enemy (in future - sprite). the shield itself is another type of hit points which is not affected by heal and is depleted before regular hp. when shield hp are depleted, enemy is stunned for 3 seconds (data-driven). ask for clarifications of needed."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Shield Absorbs Incoming Damage (Priority: P1)

When a shielded enemy is hit, damage depletes the shield HP first before touching regular HP. The player sees a distinct shield visual layered on top of the enemy, making it immediately clear the enemy has extra protection.

**Why this priority**: This is the core shield mechanic — the damage-absorption behaviour is the defining feature and everything else depends on it.

**Independent Test**: Can be tested by programmatically activating the shield on an enemy, dealing damage, and verifying regular HP is unchanged while shield HP decreases.

**Acceptance Scenarios**:

1. **Given** an enemy with active shield (shield_hp > 0), **When** the player deals damage, **Then** shield HP decreases by the damage amount and regular HP is unchanged.
2. **Given** an enemy with active shield, **When** damage exceeds remaining shield HP, **Then** shield is fully depleted (shield_hp = 0), overflow damage reduces regular HP, and the shield visual is removed.
3. **Given** an enemy with active shield, **When** a heal effect would restore regular HP, **Then** shield HP is unaffected and regular HP is also unaffected (heals do not cross-restore between HP pools).

---

### User Story 2 — Shield Break Stuns the Enemy (Priority: P2)

When the shield is fully depleted, the enemy is stunned for a configurable duration (default 3 seconds), becoming unable to attack or move. A stun indicator communicates this state to the player.

**Why this priority**: The stun reward for breaking a shield is the primary gameplay incentive, making the shield mechanic strategically interesting.

**Independent Test**: Can be tested by dealing exactly enough damage to zero the shield HP and verifying the enemy enters a stunned state lasting the configured duration.

**Acceptance Scenarios**:

1. **Given** an enemy with shield_hp > 0, **When** damage reduces shield_hp to exactly 0, **Then** the enemy is stunned for the duration specified in enemy data (default 3 s) and cannot move or attack.
2. **Given** a stunned enemy, **When** the stun duration elapses, **Then** the enemy resumes normal behaviour (movement and attacks re-enabled).
3. **Given** a stunned enemy, **When** the player deals damage, **Then** regular HP decreases normally (stun does not grant damage immunity).

---

### User Story 3 — Shield Visual Feedback (Priority: P3)

While the shield is active a layered visual (placeholder ColorRect; future sprite) is displayed on top of the enemy. The visual is removed when the shield breaks.

**Why this priority**: Visual feedback is important for player clarity but is cosmetically separate from the mechanical behaviour. A placeholder suffices for the initial implementation.

**Independent Test**: Can be tested by activating the shield and verifying the visual node becomes visible; verifying it becomes invisible when shield HP reaches 0.

**Acceptance Scenarios**:

1. **Given** an enemy whose shield is activated, **When** the enemy is rendered, **Then** a shield visual overlay is visible on top of the enemy sprite.
2. **Given** an enemy with an active shield, **When** the shield HP reaches 0, **Then** the shield visual overlay is hidden.
3. **Given** an enemy with no shield active, **When** the enemy is rendered, **Then** no shield visual overlay is visible.

---

### Edge Cases

- What happens when damage exactly equals remaining shield HP? (Shield breaks, stun triggers, no overflow to regular HP.)
- What happens if the enemy dies from overflow damage in the same hit that breaks the shield? (Enemy death processing takes precedence; stun is irrelevant.)
- What happens if a shield is applied to an already-stunned enemy? (Shield HP is set; stun state is independent — the new shield does not cancel an ongoing stun.)
- What happens when an enemy is healed while stunned? (Heals restore regular HP only; shield HP remains 0 while shield is inactive.)
- Can shield HP exceed its maximum when re-applied? (No — re-activation resets shield HP to the configured maximum, capped at that value.)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each enemy data entry MAY define `shield_hp: int` (maximum shield hit points) and `shield_stun_duration: float` (seconds stunned on break); enemies without these fields have no shield capability.
- **FR-002**: An enemy with shield capability MUST expose a method to activate the shield, setting current shield HP to its maximum.
- **FR-003**: While shield HP > 0, all incoming damage MUST reduce shield HP first; any overflow from a single hit that zeroes the shield MUST carry over to regular HP in the same hit.
- **FR-004**: Healing effects MUST NOT increase shield HP under any circumstances.
- **FR-005**: When shield HP reaches 0 (from any hit), the enemy MUST enter a stunned state for the configured duration, during which movement and attacks are disabled.
- **FR-006**: The stun duration MUST be read from enemy data (the field defaults to 3.0 seconds if not specified).
- **FR-007**: When the stun duration expires, the enemy MUST resume normal movement and attack behaviour automatically.
- **FR-008**: While the shield is active (shield HP > 0), a shield visual overlay MUST be displayed on top of the enemy; it MUST be hidden when shield HP reaches 0.
- **FR-009**: The shield visual is a placeholder ColorRect for this feature; it MUST be structured so it can be swapped for a sprite in a future iteration without changing shield logic.
- **FR-010**: The trigger that activates the shield will be implemented in a separate feature; this feature MUST provide the activation API but need not define when it is called.
- **FR-011**: `forest_boss_thorns` MUST be updated in `data/enemies.json` with `shield_hp` and `shield_stun_duration` values appropriate to its difficulty.

### Key Entities

- **ShieldState**: Per-enemy runtime state tracking `current_shield_hp: int` and whether the shield is active. Not persisted between rooms.
- **EnemyData (extended)**: Optional `shield_hp: int` (max shield HP; absent = no shield) and `shield_stun_duration: float` (stun seconds on break; default 3.0).
- **StunState**: Runtime flag and countdown timer on the enemy governing whether movement and attacks are suppressed.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A shielded enemy takes 0 regular HP damage on any hit while shield HP > 0 (verified per-hit in unit tests).
- **SC-002**: Overflow damage from a shield-breaking hit correctly reduces regular HP in the same frame, with no damage lost.
- **SC-003**: The shield stun duration matches the configured value within ±0.1 s (measurable via timer inspection).
- **SC-004**: The shield visual is shown/hidden in sync with shield activation/depletion in every tested scenario.
- **SC-005**: Heal effects produce no change to shield HP in all tested scenarios.
- **SC-006**: `forest_boss_thorns` has shield data configured and the mechanic functions end-to-end in a live run.
