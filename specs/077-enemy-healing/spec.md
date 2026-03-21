# Feature Specification: Enemy Healing Mechanics

**Feature Branch**: `077-enemy-healing`
**Created**: 2026-03-21
**Status**: Draft
**Input**: User description: "add healing mechanic to enemies. add regen (+x% hp/sec) and direct heal (x hp on skill use). regen should be turned on if in enemies.json enemy has regen_rate (I will add such enemies later), and direct heal if the enemy has heal_amount. direct heal applies to other enemies, not self."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enemy Regeneration (Priority: P1)

Enemies with a configured regeneration rate slowly recover health over time during combat. A player fighting a regenerating enemy must deal damage faster than the enemy heals, adding urgency and strategic pressure to the encounter.

**Why this priority**: Regen is the simpler, always-on passive mechanic. It affects every hit of every fight against a regenerating enemy and creates the most immediate gameplay impact. It is also independently testable without any skill system.

**Independent Test**: Spawn an enemy with `regen_rate` set in enemies.json. Observe their HP bar slowly filling during combat. Verify that an enemy at less than full health gradually returns to full if the player stops attacking.

**Acceptance Scenarios**:

1. **Given** an enemy with `regen_rate > 0` is alive and below max HP, **When** time passes during combat, **Then** the enemy's current HP increases at a rate of `regen_rate × max_HP` per second.
2. **Given** an enemy is at full HP, **When** time passes, **Then** HP does not exceed max HP (no overheal).
3. **Given** an enemy has no `regen_rate` field (or `regen_rate = 0`), **When** time passes, **Then** the enemy's HP does not change passively.
4. **Given** a regenerating enemy takes damage, **When** regen tick fires shortly after, **Then** HP is restored by the regen amount (regen and damage are independent).

---

### User Story 2 - Enemy Ally Heal Skill (Priority: P2)

Enemies with a configured heal amount can use a heal skill during combat to instantly restore a fixed amount of HP to nearby ally enemies within a set radius. This creates reactive gameplay: the player must prioritize killing the healer before it sustains its allies, or position to isolate wounded enemies outside the heal radius.

**Why this priority**: The ally heal is a more complex, event-driven mechanic. It introduces a priority-target dynamic (kill the healer first) that enriches encounter design. It builds on the enemy stat system and the existing `heal_amount` and `heal_radius` data fields.

**Independent Test**: Spawn a healer enemy alongside one or more damaged ally enemies. Wait for the healer's skill cooldown to expire. Observe each ally within `heal_radius` instantly recover `heal_amount` HP. Verify the healer itself is NOT healed. Verify allies outside the radius are NOT healed.

**Acceptance Scenarios**:

1. **Given** a healer enemy with `heal_amount > 0` is alive and the skill cooldown has expired, **When** the skill triggers, **Then** every living ally enemy within `heal_radius` has its HP increased by exactly `heal_amount`, clamped to their individual max HP.
2. **Given** an ally enemy is already at full HP, **When** the healer skill triggers, **Then** that ally's HP remains at max (no overheal).
3. **Given** an ally enemy is outside `heal_radius`, **When** the healer skill triggers, **Then** that ally receives no HP.
4. **Given** the healer enemy itself is below full HP, **When** the skill triggers, **Then** the healer's own HP is NOT changed by the skill.
5. **Given** an enemy has no `heal_amount` field (or `heal_amount = 0`), **When** the skill cooldown expires, **Then** no heal occurs.
6. **Given** a healer enemy is killed, **When** its cooldown would have expired, **Then** no heal fires.

---

### Edge Cases

- What if there are no living allies within radius when the skill fires? → Skill fires but has no effect; cooldown still resets.
- What if `heal_amount` exceeds an ally's HP deficit? → Ally HP is clamped to their max HP.
- What happens when an enemy with both `regen_rate` and `heal_amount` is active? → Both mechanics operate independently; regen ticks continuously on self, heal fires on cooldown targeting allies.
- What happens when the healer is killed mid-heal? → Healer stays dead; the heal that already fired still applies to targets that were in range.
- What if `heal_radius = 0`? → No allies are in range; skill fires but heals nobody.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: An enemy with a positive `regen_rate` value MUST recover HP continuously during combat at a rate of `regen_rate × max_HP` HP per second.
- **FR-002**: Regen MUST be capped at max HP — an enemy cannot exceed its maximum health through regeneration.
- **FR-003**: An enemy without a `regen_rate` field or with `regen_rate = 0` MUST NOT regenerate HP.
- **FR-004**: An enemy with a positive `heal_amount` value MUST periodically restore that fixed HP amount to all living ally enemies within `heal_radius`, triggered on a configurable skill cooldown cycle.
- **FR-005**: The healer MUST NOT heal itself via the heal skill.
- **FR-006**: Each healed ally's HP MUST be capped at that ally's individual max HP.
- **FR-007**: An enemy without a `heal_amount` field or with `heal_amount = 0` MUST NOT perform a heal skill.
- **FR-008**: Both regen and ally heal MUST be visible via the affected enemy's HP bar updating in real time.
- **FR-009**: The heal skill cooldown MUST be data-driven — configurable per enemy type via enemies.json (defaults to 5 seconds if not specified).
- **FR-010**: The heal radius MUST be data-driven via the `heal_radius` field in enemies.json.
- **FR-011**: All new fields (`regen_rate`, `heal_amount`, `heal_radius`, heal cooldown) MUST be optional in enemies.json, defaulting to 0 so existing enemies are unaffected.

### Key Entities

- **EnemyData**: Extended with optional `regen_rate: float` (HP fraction per second; e.g. 0.02 = 2% max HP/sec), `heal_amount: float` (flat HP granted to each ally per skill use), `heal_radius: float` (distance within which allies are healed), and `heal_cooldown: float` (seconds between heal skill uses; default 5.0).
- **Enemy (instance)**: Gains two passive behaviors — a continuous self-regen tick driven by `regen_rate`, and a periodic ally-heal skill driven by `heal_amount`, `heal_radius`, and `heal_cooldown`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An enemy configured with `regen_rate = 0.02` recovers exactly 2% of its max HP per second, verifiable by observing HP bar movement over a timed interval.
- **SC-002**: An enemy configured with `heal_amount = 10` grants exactly 10 HP to each eligible ally per heal event (or brings them to max HP if the deficit is smaller), verifiable in a single heal trigger.
- **SC-003**: The healer's own HP does not change as a result of the heal skill firing, verifiable by inspecting the healer's HP bar before and after skill use.
- **SC-004**: Allies outside `heal_radius` receive no HP from the heal skill, verifiable by positioning enemies at known distances.
- **SC-005**: Existing enemies with no new fields set behave identically to before — zero regressions in current combat encounters.
- **SC-006**: Both regen and ally heal changes are visible on the affected enemy's HP bar within one frame of the event.

## Assumptions

- The heal skill cooldown defaults to 5 seconds when not specified in enemies.json.
- Regen ticks every frame (driven by delta time), not on a fixed-interval timer.
- The heal skill fires unconditionally on cooldown expiry as long as the healer is alive; whether any ally is in range is irrelevant to the cooldown reset.
- The existing `forest_healer` entry in enemies.json already has `heal_amount` and `heal_radius` fields — this feature gives those fields their implementation.
- No visual skill animation is required for this feature; HP bar updates are sufficient feedback.
- "Ally enemies" means all other living Enemy instances in the current room, excluding the healer itself.
