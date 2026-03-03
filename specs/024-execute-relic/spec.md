# Feature Specification: Conditional Damage Relics

**Feature Branch**: `024-execute-relic`
**Created**: 2026-03-03
**Status**: Draft
**Input**: Two uncommon relics with conditional damage bonuses: execute (target HP) and berserker (player HP)

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Collect the Execute Relic (Priority: P1)

A player completes a room and is offered the "Executioner's Mark" relic. They read its description — "+35% damage to enemies below 30% HP" — and pick it up. The relic is active for the rest of the run.

**Why this priority**: The relic must exist and be obtainable before its effect can matter.

**Independent Test**: Start a run, trigger relic offers until the execute relic appears, pick it up. Confirm it is listed as active.

**Acceptance Scenarios**:

1. **Given** the player is in a run, **When** a relic offer is triggered, **Then** the execute relic can appear as one of the two offer cards with the text "+35% damage to enemies below 30% HP".
2. **Given** the player picks the execute relic, **When** the offer screen closes, **Then** the relic is registered as active for the remainder of the run.
3. **Given** the run ends, **When** a new run begins, **Then** the execute relic is no longer active.

---

### User Story 2 — Execute Bonus Applied During Combat (Priority: P1)

When the player attacks an enemy whose current HP is below 30% of its maximum, the attack deals 35% more damage. Attacks against healthy enemies are unaffected.

**Why this priority**: This is the entire gameplay value of the execute relic.

**Independent Test**: Hold the execute relic. Attack a full-HP enemy — damage is normal. Reduce an enemy to below 30% HP, attack again — the hit deals 35% more damage.

**Acceptance Scenarios**:

1. **Given** the player holds the execute relic and attacks an enemy at 31% HP or above, **When** the hit lands, **Then** damage equals the base amount with no execute bonus.
2. **Given** the player holds the execute relic and attacks an enemy at exactly 30% HP, **When** the hit lands, **Then** damage includes the +35% bonus.
3. **Given** the player holds the execute relic and attacks an enemy at 1 HP, **When** the hit lands, **Then** damage includes the +35% bonus.
4. **Given** the player does NOT hold the execute relic, **When** they attack an enemy at any HP%, **Then** damage is unaffected.

---

### User Story 3 — Collect the Berserker Relic (Priority: P1)

A player is offered the "Berserker Stone" relic with description "+30% damage when below 50% HP". They pick it up. The relic is active for the rest of the run.

**Why this priority**: The relic must exist and be obtainable before its effect can matter.

**Independent Test**: Start a run, trigger relic offers until the berserker relic appears, pick it up. Confirm it is listed as active.

**Acceptance Scenarios**:

1. **Given** the player is in a run, **When** a relic offer is triggered, **Then** the berserker relic can appear with the text "+30% damage when below 50% HP".
2. **Given** the player picks the berserker relic, **When** the offer screen closes, **Then** the relic is registered as active for the remainder of the run.
3. **Given** the run ends, **When** a new run begins, **Then** the berserker relic is no longer active.

---

### User Story 4 — Berserker Bonus Applied During Combat (Priority: P1)

When the player's current HP is below 50% of their maximum, all attacks deal 30% more damage. When the player is at 50% HP or above the bonus does not apply.

**Why this priority**: This is the entire gameplay value of the berserker relic.

**Independent Test**: Hold the berserker relic at full HP — attacks deal normal damage. Take damage until below 50% HP, attack — the hit deals 30% more damage. Heal back above 50% HP, attack again — damage returns to normal.

**Acceptance Scenarios**:

1. **Given** the player holds the berserker relic and is at 51% HP or above, **When** they attack, **Then** damage equals the base amount with no berserker bonus.
2. **Given** the player holds the berserker relic and is at exactly 50% HP, **When** they attack, **Then** damage includes the +30% bonus.
3. **Given** the player holds the berserker relic and is at 1 HP, **When** they attack, **Then** damage includes the +30% bonus.
4. **Given** the player does NOT hold the berserker relic, **When** they attack at any HP%, **Then** damage is unaffected.

---

### Edge Cases

- **Both relics held simultaneously**: if the player is below 50% HP and the enemy is below 30% HP, both bonuses apply (multiplicative stack: ×1.35 × ×1.30).
- **Execute with invalid enemy data**: if enemy max HP is 0 or unavailable, the execute bonus does not apply and no crash occurs.
- **Berserker with full heal mid-combat**: the bonus checks the player's HP at the moment the hit lands, not when the attack began.
- **Multiple damage-boosting relics**: all bonuses stack multiplicatively with each other and with the meta damage upgrade.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The execute relic MUST be available as an uncommon-tier relic obtainable through the standard relic offer system.
- **FR-002**: The execute relic's offer card MUST display the description "+35% damage to enemies below 30% HP".
- **FR-003**: When the player holds the execute relic, any attack that hits an enemy at strictly less than 30% of its maximum HP MUST deal 35% additional damage.
- **FR-004**: The execute bonus MUST NOT apply to attacks against enemies at 30% HP or above.
- **FR-005**: The berserker relic MUST be available as an uncommon-tier relic obtainable through the standard relic offer system.
- **FR-006**: The berserker relic's offer card MUST display the description "+30% damage when below 50% HP".
- **FR-007**: When the player holds the berserker relic and their current HP is strictly less than 50% of their maximum HP, all attacks MUST deal 30% additional damage.
- **FR-008**: The berserker bonus MUST NOT apply when the player is at 50% HP or above.
- **FR-009**: Both bonuses MUST stack multiplicatively with each other and with all other damage multipliers.
- **FR-010**: Both relics MUST be run-scoped — cleared when the run ends, inactive in the hub.
- **FR-011**: Adding or removing either relic entry from the data file MUST require no code changes.

### Key Entities

- **Execute Relic**: Uncommon relic. Bonus condition: target enemy HP < 30% of target max HP. Evaluated per-hit at the moment damage is calculated.
- **Berserker Relic**: Uncommon relic. Bonus condition: player current HP < 50% of player max HP. Evaluated per-hit at the moment damage is calculated.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Both relics appear in relic offers at the expected uncommon frequency (≈30% of draws).
- **SC-002**: 100% of hits against enemies below 30% max HP while holding the execute relic deal exactly 35% more damage (verifiable via output log).
- **SC-003**: 100% of attacks made while the player is below 50% max HP and holding the berserker relic deal exactly 30% more damage.
- **SC-004**: 0% of hits outside their respective conditions receive a conditional bonus.
- **SC-005**: No errors or crashes occur when either or both relics are active across a full run.

## Assumptions

- "Below X% HP" means strictly less than X% in both cases (`current_hp < max_hp * threshold`).
- Both bonuses are ×1.35 and ×1.30 multipliers applied at damage calculation time, stacking multiplicatively with all other multipliers.
- The player HP condition (berserker) is read from `StatsComponent` at the moment of the hit — the same component `CombatComponent` already interacts with.
- Both relics require a one-time code change to support per-hit conditional checks; future relics of the same type (target-HP or player-HP conditional) require only a data entry.
