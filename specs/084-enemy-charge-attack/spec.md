# Feature Specification: Enemy Charge Attack

**Feature Branch**: `084-enemy-charge-attack`
**Created**: 2026-03-28
**Status**: Draft
**Input**: User description: "implement an enemy mechanic: charge attack. the enemy should stop for 2 seconds, display a telegraph of a straight zone (rectangle from enemy) and then move with 3x speed through this rectangle, stopping so that its border is touching the rectangle border. the contact damage should be data driven, parameter should be charge_attack_damage. there should also be a data-driven charge_attack_cooldown, which starts counting down when enemy detects player. each time the cooldown timer reaches zero, a charge attack is performed. make the placeholder value 10. add this charge attack to forest_boss_thorns. there should be a data-driven value of the charge_attack length which will make the rectangle side. the other side of the rectangle should be the enemy size. the charge attack should be in the direction of player"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enemy Telegraphs and Executes Charge (Priority: P1)

When a player enters a room containing an enemy with the charge attack mechanic, the enemy detects the player and begins a cooldown. Once the cooldown expires, the enemy freezes in place, a visible rectangular warning zone appears in the direction of the player, and after 2 seconds the enemy launches through that zone at high speed, damaging the player on contact. The enemy stops once it has traveled the full charge distance.

**Why this priority**: This is the core mechanic — without the telegraph and charge execution, no other part of the feature has value.

**Independent Test**: Can be fully tested by placing `forest_boss_thorns` in a test room, entering detection range, waiting for the cooldown, and observing freeze → telegraph → charge → stop sequence.

**Acceptance Scenarios**:

1. **Given** the player is within enemy detection range, **When** the charge cooldown timer reaches zero, **Then** the enemy halts all normal movement for 2 seconds and a rectangular zone appears extending from the enemy toward the player.
2. **Given** the telegraph is displayed and 2 seconds have elapsed, **When** the charge begins, **Then** the enemy moves at 3× its normal speed in the telegraphed direction.
3. **Given** the enemy is charging, **When** the enemy has traveled the full `charge_attack_length` distance, **Then** the enemy stops with its body border touching the end border of the telegraph rectangle.
4. **Given** the enemy is mid-charge, **When** the player is inside the telegraph rectangle, **Then** the player receives `charge_attack_damage` damage.

---

### User Story 2 - Charge Cooldown Cycles (Priority: P2)

After completing a charge (or at the start of enemy detection), the cooldown timer resets and another charge will trigger when it expires — creating a repeating threat pattern throughout the encounter.

**Why this priority**: Without cycling, the charge is a one-shot event and the mechanic loses strategic depth.

**Independent Test**: Survive a full encounter long enough to observe two consecutive charge attacks, confirming the cooldown resets after each charge completes.

**Acceptance Scenarios**:

1. **Given** a charge has just completed, **When** `charge_attack_cooldown` seconds pass, **Then** another charge attack is initiated.
2. **Given** the enemy first detects the player, **When** `charge_attack_cooldown` seconds pass with no prior charge, **Then** the first charge attack is initiated.

---

### User Story 3 - Data-Driven Configuration for forest_boss_thorns (Priority: P3)

The charge attack parameters (`charge_attack_damage`, `charge_attack_cooldown`, `charge_attack_length`) are stored in the enemy data file and applied to `forest_boss_thorns`. Both placeholder and tuned values can be set without code changes.

**Why this priority**: Ensures the mechanic is reusable and balance-tunable via data only.

**Independent Test**: Edit the JSON values for `forest_boss_thorns` and confirm changed behavior in-game without modifying any script.

**Acceptance Scenarios**:

1. **Given** `forest_boss_thorns` has `charge_attack_damage: 10`, `charge_attack_cooldown: 10`, **When** the enemy charges and hits the player, **Then** the player takes exactly 10 damage.
2. **Given** `charge_attack_length` is set to a specific value, **When** the charge completes, **Then** the telegraph rectangle length matches that value and the enemy stops at its far edge.

---

### Edge Cases

- What happens when the player moves out of the telegraphed rectangle after the telegraph phase begins but before the charge completes — the charge still fires in the locked direction; no re-targeting mid-charge.
- What happens when the enemy dies during the telegraph phase — the charge is cancelled and the telegraph disappears.
- What happens when the player is at point-blank range (distance less than `charge_attack_length`) — charge still fires; enemy travels the full length regardless of player position, overshooting if needed.
- What happens when `charge_attack_cooldown` is 0 or negative — treat as immediate: first charge fires as soon as player is detected.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Enemy MUST freeze all normal movement and targeting for exactly 2 seconds before each charge.
- **FR-002**: During the 2-second telegraph phase, a visible rectangle MUST be displayed extending from the enemy in the direction of the player at the moment the telegraph begins.
- **FR-003**: The telegraph rectangle dimensions MUST be `charge_attack_length` (long axis) × enemy collision size (short axis).
- **FR-004**: After the telegraph phase, the enemy MUST travel in the telegraphed direction at 3× its base movement speed.
- **FR-005**: The enemy MUST stop when it has traveled `charge_attack_length` distance (its border touching the far edge of the telegraph zone).
- **FR-006**: Any player contact during the charge movement MUST deal `charge_attack_damage` damage to the player.
- **FR-007**: The charge cooldown timer MUST begin counting down when the enemy first detects the player.
- **FR-008**: Each time the cooldown reaches zero, one charge attack sequence MUST be triggered and the cooldown resets.
- **FR-009**: `charge_attack_damage`, `charge_attack_cooldown`, and `charge_attack_length` MUST be read from enemy data (JSON); default placeholder value for each is 10.
- **FR-010**: The enemy `forest_boss_thorns` MUST have all three charge attack parameters set in enemy data.
- **FR-011**: Direction for the charge MUST be locked at the moment the telegraph begins (player position at telegraph start) and MUST NOT change during the 2-second wind-up or the charge movement.

### Key Entities

- **Charge Attack State**: Per-enemy state machine tracking phases: Idle → Cooldown → Telegraph → Charging → Recovery.
- **Telegraph Zone**: Transient visual rectangle parented to the enemy; visible only during the telegraph phase; dimensions derived from `charge_attack_length` and enemy size.
- **EnemyData (extended)**: Existing data model gains three optional numeric fields: `charge_attack_damage`, `charge_attack_cooldown`, `charge_attack_length`. Absence of these fields means the enemy has no charge attack.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: `forest_boss_thorns` performs a charge attack every `charge_attack_cooldown` seconds (±0.1 s) after player detection.
- **SC-002**: The telegraph rectangle is visible for exactly 2 seconds before every charge, with no charge movement occurring during that window.
- **SC-003**: Enemy travel distance per charge equals `charge_attack_length` within a 1-pixel tolerance.
- **SC-004**: Player hit during a charge receives damage equal to `charge_attack_damage` with no deviation.
- **SC-005**: Changing any of the three charge parameters in JSON produces the corresponding behavioral change without modifying scripts.

## Assumptions

- Enemy detection range is the existing mechanic already present on enemies; charge cooldown starts when the enemy's normal "player detected" condition becomes true.
- "Enemy size" for the rectangle short axis refers to the enemy's collision shape diameter/width.
- Contact damage is a one-time hit per charge (not continuous per-frame damage while overlapping).
- The charge does not interrupt the enemy's invulnerability or collision — it uses the same damage-dealing pathway as melee contact.
- Enemies without charge parameters defined in data simply skip the mechanic entirely.
