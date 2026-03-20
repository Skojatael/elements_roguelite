# Feature Specification: Poison Mechanic

**Feature Branch**: `073-poison-mechanic`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "add a new mechanic: poison. it affects both player and enemy. it should read two parameters: poison duration and poison modifier. modifier makes attack damage of target <value>% less. when several hits apply poison, the duration stacks, the modifier doesn't (implied: all poison modifiers from one source are equal). if enemy has poison_duration, it can apply poison. if player has a specific poison relic (common), melee hits apply poison with relic-defined chance (placeholder: 25% chance, 15% damage modifier)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Enemy Applies Poison to Player (Priority: P1)

A poisonous enemy (e.g. a slime) hits the player, inflicting a poison status. For the duration, the player's outgoing attack damage is reduced by the poison modifier percentage. If the same enemy hits the player again before the first poison expires, the remaining duration extends rather than resetting, and the modifier stays the same.

**Why this priority**: Core mechanic that introduces a new threat type — poisonous enemies — and demonstrates the full poison lifecycle (application, stacking duration, expiry).

**Independent Test**: Configure one enemy with `poison_duration` and `poison_modifier` in `enemies.json`. Enter combat, get hit twice. Verify damage reduction is applied and duration stacks correctly.

**Acceptance Scenarios**:

1. **Given** a player with no active poison, **When** a poison-capable enemy lands a hit, **Then** the player receives the Poisoned status, their attack damage is reduced by `poison_modifier`%, and a timer starts for `poison_duration` seconds.
2. **Given** a player already poisoned with T seconds remaining, **When** the same poison-capable enemy lands another hit, **Then** the remaining duration increases by `poison_duration` (stacks additively), and the damage modifier does not change.
3. **Given** a poisoned player, **When** the poison duration expires, **Then** the Poisoned status is removed and the player's attack damage returns to normal.
4. **Given** an enemy with no `poison_duration` field (or value 0), **When** it lands a hit, **Then** no poison is applied to the player.

---

### User Story 2 - Player Applies Poison to Enemy via Relic (Priority: P2)

The player holds a specific common relic (e.g. "Venomous Strike"). Each time the player lands a melee hit, there is a relic-defined chance (placeholder: 25%) to inflict poison on the enemy. The enemy's attack damage is then reduced by the relic-defined modifier (placeholder: 15%) for the duration. Multiple melee hits stack the duration; the modifier stays constant.

**Why this priority**: Delivers the offensive side of the mechanic and ties poison into the existing relic system, enabling player strategic choices.

**Independent Test**: Equip the poison relic (via DevPanel or relic offer), land multiple melee hits. Verify probabilistic application and duration stacking on the enemy.

**Acceptance Scenarios**:

1. **Given** a player holding the poison relic, **When** a melee hit lands, **Then** there is a 25% chance the struck enemy becomes Poisoned (damage output reduced by 15% for the relic-defined duration).
2. **Given** an already-poisoned enemy, **When** another melee hit lands and the chance roll succeeds, **Then** the enemy's poison duration increases additively; the modifier remains 15%.
3. **Given** a player without the poison relic, **When** melee hits land, **Then** no poison is applied to any enemy.
4. **Given** a poisoned enemy, **When** the poison duration expires, **Then** the enemy's attack damage returns to normal.

---

### User Story 3 - Poison Parameters Configured in Data (Priority: P3)

All poison parameters (duration, modifier, relic chance) are driven by data — enemy entries in `enemies.json` and relic entries in `relics.json` — with no hard-coded values. Adding a new poisonous enemy or adjusting balance only requires editing data files.

**Why this priority**: Enables future balance iteration without code changes; required for clean integration with the existing data-driven architecture.

**Independent Test**: Change `poison_duration` and `poison_modifier` for a test enemy in `enemies.json`; verify in-game behaviour reflects the new values without recompilation.

**Acceptance Scenarios**:

1. **Given** an enemy entry with `poison_duration: 3` and `poison_modifier: 0.20`, **When** that enemy hits the player, **Then** poison lasts 3 seconds and reduces player attack damage by 20%.
2. **Given** the poison relic entry with `poison_chance: 0.25` and `poison_modifier: 0.15`, **When** the player applies poison via this relic, **Then** the 25% chance and 15% modifier are used.
3. **Given** an enemy entry with no `poison_duration` field (or value 0), **When** that enemy is loaded, **Then** it is treated as non-poisonous with no extra processing cost.

---

### Edge Cases

- What happens when a player or enemy is hit by two different poison sources simultaneously (e.g. a poisonous enemy AND a poison relic retaliation)? → Duration stacks from each application; the modifier is sourced from each applying entity independently (enemy uses its own modifier, relic uses its own modifier). The effective modifier used is the one currently active; if both are active the highest modifier value applies.
- What happens when a poisoned target dies mid-duration? → Poison status is discarded silently with no side effects.
- What happens when poison is applied with `poison_duration = 0`? → No status is applied; treat as non-poisonous.
- Does poison affect the player's skills (ranged damage, magic missile, etc.) or only melee? → Poison modifier reduces ALL outgoing attack damage from the target (both player and enemy), not only melee.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each entity (enemy or player) MUST track a Poisoned status with two runtime fields: `remaining_duration: float` and `damage_modifier: float`.
- **FR-002**: While Poisoned, an entity's outgoing attack damage MUST be multiplied by `(1.0 − damage_modifier)`.
- **FR-003**: Poison application MUST stack duration additively: `remaining_duration += poison_duration`. The modifier MUST NOT change on re-application.
- **FR-004**: When `remaining_duration` reaches 0, the Poisoned status MUST be removed and the damage modifier reverted.
- **FR-005**: An enemy MUST be capable of applying poison if and only if its data entry contains a positive `poison_duration` value.
- **FR-006**: The player MUST be capable of applying poison to enemies via melee hits if and only if the player holds the designated poison relic.
- **FR-007**: The poison relic MUST define `poison_chance` (probability per hit, 0–1) and `poison_modifier` (damage reduction fraction, 0–1) in `relics.json`; these MUST NOT be hard-coded.
- **FR-008**: Enemy poison parameters (`poison_duration`, `poison_modifier`) MUST be read from `enemies.json`; these MUST NOT be hard-coded.
- **FR-009**: Non-poisonous enemies (no `poison_duration` field or value ≤ 0) MUST incur no poison-related processing overhead.
- **FR-010**: The poison relic MUST be a Common-tier relic and MUST appear in the standard relic offer pool.

### Key Entities

- **PoisonStatus**: Runtime state attached to a combatant. Fields: `remaining_duration: float`, `damage_modifier: float` (fraction, e.g. 0.15 = 15% reduction). Absent means not poisoned.
- **Poison Relic** (`venomous_strike` or similar id in `relics.json`): Common-tier relic. Data fields: `poison_chance: float`, `poison_duration: float`, `poison_modifier: float`. Effect stat handled outside `compute_stat_mult` (conditional logic, same pattern as execute/berserker relics in feature 024).
- **Enemy Poison Parameters** (in `enemies.json` per-enemy): `poison_duration: float` (seconds), `poison_modifier: float` (fraction). Optional; absent = non-poisonous.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A poisonous enemy correctly reduces player attack damage by the configured percentage for the configured duration in 100% of hits that apply poison.
- **SC-002**: Duration stacking works correctly — after N successive poison applications, remaining duration equals N × `poison_duration` (assuming no time has elapsed between applications).
- **SC-003**: The poison relic applies poison at a rate statistically consistent with its configured chance (verifiable over ≥ 100 hits in automated testing).
- **SC-004**: All poison parameter changes made solely in `enemies.json` or `relics.json` are reflected in runtime behaviour with no code changes required.
- **SC-005**: Enemies without `poison_duration` never apply poison in any observed combat scenario.
- **SC-006**: The poison modifier does not compound with itself on re-application — only one modifier instance is active at a time per poisoning source.
