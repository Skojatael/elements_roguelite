# Feature Specification: Enemy Buff Zone

**Feature Branch**: `080-enemy-buff-zone`
**Created**: 2026-03-21
**Status**: Draft
**Input**: User description: "add new type of enemy interaction, buffing zone: when enemy casts buff, a circle is created on the ground that gives enemies inside and those who enter x% regen and +x% attack speed. it does not affect player. enemy buffer has buff_cooldown and buff_zone_radius defined in enemies.json. the buff circle radius should correspond to buff_zone_radius"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Buff Zone Appears and Persists (Priority: P1)

A "buffer" enemy periodically casts a buff, placing a glowing circle on the ground at its own position. The circle remains active for a fixed duration, visually indicating the buff area to the player.

**Why this priority**: Core mechanic — without the zone appearing, nothing else works.

**Independent Test**: Spawn a buffer enemy in a combat room and observe that a circle appears at the enemy's position after `buff_cooldown` seconds, then disappears after its duration.

**Acceptance Scenarios**:

1. **Given** a buffer enemy is alive, **When** `buff_cooldown` seconds elapse, **Then** a circular zone appears on the ground centered on the enemy currently closest to the player, with radius equal to `buff_zone_radius`.
2. **Given** a buff zone is active, **When** the zone duration expires, **Then** the circle is removed from the scene.
3. **Given** a buff zone has expired, **When** another `buff_cooldown` elapses, **Then** a new zone is cast again.

---

### User Story 2 — Enemies Inside Zone Receive Buffs (Priority: P2)

Enemies standing inside the buff circle gain only the bonuses configured for that specific caster — a regen-only caster grants regen, a speed-only caster grants attack speed, and a caster with both fields set grants both.

**Why this priority**: The core gameplay effect — buffed enemies are more threatening, raising encounter difficulty.

**Independent Test**: Place two enemies inside the zone of a regen-only caster and verify HP regenerates but attack interval is unchanged; repeat with an attack speed-only caster and verify the inverse.

**Acceptance Scenarios**:

1. **Given** a buff zone is active with a non-zero regen rate, **When** an enemy is inside the zone, **Then** it regenerates HP each second at that rate.
2. **Given** a buff zone is active with a non-zero attack speed bonus, **When** an enemy is inside the zone, **Then** its attack interval is shorter than baseline by that bonus.
3. **Given** a buff zone is active with zero regen rate, **When** an enemy is inside, **Then** the enemy's HP does not regenerate from the zone.
4. **Given** a buff zone is active, **When** an enemy moves out of the zone, **Then** any bonuses granted by that zone are removed.
5. **Given** a buff zone expires, **When** enemies were inside at expiry, **Then** the buffs are removed immediately from all affected enemies.

---

### User Story 3 — Entering Enemies Receive Buffs (Priority: P2)

An enemy that walks into an active buff zone receives whatever bonuses that zone provides — only the effects configured on the caster, not a fixed set.

**Why this priority**: Ensures the mechanic works dynamically for enemies that move around, not just those who happened to be standing in the zone at cast time.

**Independent Test**: Cast the zone from a regen-only caster, move an enemy in, and confirm it gains regen but no attack speed change.

**Acceptance Scenarios**:

1. **Given** a buff zone is active and an enemy is outside it, **When** the enemy moves into the zone's radius, **Then** it immediately gains whichever bonuses are configured on that zone (regen, attack speed, or both).

---

### User Story 4 — Player Is Not Affected (Priority: P1)

The buff zone has no effect on the player character in any circumstance.

**Why this priority**: Explicitly required; if the player receives buffs it fundamentally breaks the game balance.

**Independent Test**: Walk the player into an active buff zone and confirm no regen or attack speed change occurs.

**Acceptance Scenarios**:

1. **Given** a buff zone is active, **When** the player walks into or stands inside the zone, **Then** the player's HP regeneration and attack speed are unchanged.

---

### Edge Cases

- What happens if the buffer enemy dies while a buff zone it cast is still active? (Zone remains until its own duration expires — independent of the caster's survival.)
- What happens if multiple buff zones overlap? (Each zone applies its buff independently; stacking is additive.)
- What happens if a buffed enemy is already at maximum HP? (Regen has no effect; attack speed buff still applies.)
- What happens if the buffer enemy casts again before the previous zone expires? (A second zone appears; both are active simultaneously.)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Any enemy with `buff_cooldown` and `buff_zone_radius` defined in `enemies.json` MUST periodically cast a buff zone; no separate "buffer type" flag is required.
- **FR-002**: After each `buff_cooldown` interval, the caster MUST spawn a buff zone centered on the enemy sibling closest to the player at cast time (falling back to the caster's own position if no player reference is active or no siblings exist), with radius equal to `buff_zone_radius`.
- **FR-003**: The buff zone's physical and visual radius MUST equal `buff_zone_radius` from the caster's data.
- **FR-004**: The buff zone MUST have a fixed active duration after which it disappears automatically.
- **FR-005**: If the caster has a non-zero `buff_regen_rate`, enemies inside the zone MUST regenerate HP each second at that rate; a zero value MUST have no regen effect.
- **FR-006**: If the caster has a non-zero `buff_attack_speed_bonus`, enemies inside the zone MUST attack faster by that bonus; a zero value MUST have no attack speed effect.
- **FR-007**: Buff effects MUST be applied to enemies that enter an already-active zone, not only those present at cast time.
- **FR-008**: Buff effects from a zone MUST be removed from an enemy the moment it exits that zone or the zone expires.
- **FR-009**: The buff zone MUST NOT affect the player character's stats or HP in any way.
- **FR-010**: The buff zone MUST be visually distinct on the ground so the player can see its boundaries.
- **FR-011**: A caster MUST continue to cast on cooldown regardless of whether its previous zones are still active.
- **FR-012**: Buff effects from multiple overlapping zones MUST stack additively on enemies inside them.

### Key Entities

- **Buffer Enemy**: Any enemy with `buff_cooldown` and `buff_zone_radius` set in `enemies.json`. Optionally also has `buff_regen_rate`, `buff_attack_speed_bonus`, or both — whichever are non-zero become the zone's active effects.
- **Buff Zone**: A temporary circular area spawned by a caster. Carries the effect values copied from the caster at spawn time; persists independently of the caster's survival. Has a radius and a duration.
- **Buff Effect**: The set of per-enemy bonuses currently applied by zones that enemy overlaps. Recomputed on zone entry, exit, and expiry — always the additive sum across all overlapping zones.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A buffer enemy reliably casts a zone every `buff_cooldown` seconds with no missed cycles during a full combat encounter.
- **SC-002**: An enemy inside a regen-configured zone visibly regenerates HP; an enemy inside an attack-speed-configured zone has a measurably shorter attack interval; neither effect appears when the corresponding field is zero.
- **SC-003**: The player receives zero stat changes from entering, standing in, or exiting any buff zone in any scenario.
- **SC-004**: Buff removal is immediate — no lingering regen or attack speed bonus is observable on an enemy after it exits the zone or the zone expires.
- **SC-005**: The buff zone's visible boundary matches its gameplay-effective radius exactly (no invisible hitbox extending beyond the visual circle or vice versa).

## Assumptions

- **Zone duration**: Fixed at 5 seconds (a reasonable default matching other timed zone mechanics in the genre). Can be tuned per enemy via a future `buff_zone_duration` field if needed.
- **Regen amount** (`buff_regen_rate`): Optional per-enemy field. Defined as a fraction of max HP restored per second (e.g. 0.05 = 5%/s). Omitting or setting to 0 means no regen effect.
- **Attack speed bonus** (`buff_attack_speed_bonus`): Optional per-enemy field. Additive multiplier bonus on attack speed (e.g. 0.25 = +25%). Omitting or setting to 0 means no attack speed effect.
- **Buff zone caster**: The buffer starts its cooldown timer from room entry (or spawn), not from player entry into the room.
- **No unique visual asset required at spec stage**: A colored translucent circle is sufficient for initial implementation.
- **Buff does not apply to the buffer enemy itself**: The buff zone aids nearby allies; whether the caster itself benefits is resolved by whether it overlaps its own zone (it does, so it receives the buff like any other enemy).
