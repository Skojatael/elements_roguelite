# Feature Specification: Additive-Multiplicative Modifier Stacking

**Feature Branch**: `063-additive-multiplicative-modifiers`
**Created**: 2026-03-19
**Status**: Draft
**Input**: User description: "change modifiers in such a way that several modifiers of the same type would be additive, and modifiers of different types would be multiplicative. example: two relics 10% damage and one 10% damage upgrade =base_damage*(1+0.1+0.1)*(1+0.1)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Relic Bonuses Stack Additively (Priority: P1)

A player collects two relics that each grant +10% attack damage. Instead of each relic multiplying independently (which would yield 1.21× combined), the bonuses are summed first, giving 1.20× combined. This feels fairer and more intuitive — each additional relic of the same kind adds a flat bonus on top of the others.

**Why this priority**: This is the core mechanic change. Without additive stacking within a modifier source, all other parts of this feature are moot.

**Independent Test**: Equip two +10% damage relics with no other bonuses; verify final damage equals base × 1.20 (not 1.21).

**Acceptance Scenarios**:

1. **Given** a player has no relics, **When** two relics each granting +10% attack damage are applied, **Then** the combined relic damage multiplier is 1.20 (not 1.21).
2. **Given** a player has two +10% damage relics, **When** a third +10% damage relic is applied, **Then** the combined relic damage multiplier is 1.30.
3. **Given** a player has relics of different stat types (e.g., one +10% attack damage, one +10% move speed), **When** damage is calculated, **Then** only the damage relics contribute additively to the damage multiplier; speed relics do not interfere.

---

### User Story 2 - Cross-Source Bonuses Multiply (Priority: P1)

A player has two +10% damage relics (relic source) and a +10% damage meta upgrade (upgrade source). The relic bonuses combine additively into a 1.20× factor, then that factor is multiplied by the upgrade's 1.10× factor, yielding 1.32× total — matching the formula: `base_damage × (1 + 0.1 + 0.1) × (1 + 0.1)`.

**Why this priority**: The multiplicative cross-source interaction is the second half of the design. Without it, additive stacking within a source is incomplete.

**Independent Test**: With two +10% damage relics and one +10% damage meta upgrade active, verify final damage is base × 1.32.

**Acceptance Scenarios**:

1. **Given** two +10% damage relics and one +10% damage meta upgrade are active, **When** damage is dealt, **Then** final damage = base × (1 + 0.1 + 0.1) × (1 + 0.1) = base × 1.32.
2. **Given** one +20% damage relic and one +10% damage meta upgrade, **When** damage is dealt, **Then** final damage = base × 1.20 × 1.10 = base × 1.32.
3. **Given** only one +10% damage meta upgrade (no relics), **When** damage is dealt, **Then** final damage = base × (1 + 0.0) × (1 + 0.1) = base × 1.10.

---

### User Story 3 - Rule Applies to All Affected Stats (Priority: P2)

The same additive-within-source, multiplicative-across-sources rule applies to every stat that relics and upgrades can modify: attack damage, attack speed, max health, move speed, crit chance, crit multiplier, and damage reduction. The system is consistent and not limited to damage alone.

**Why this priority**: Consistency matters for game balance and player trust. A partial implementation covering only damage would create confusing asymmetries.

**Independent Test**: Equip two +10% move speed relics; verify combined speed multiplier is 1.20, not 1.21.

**Acceptance Scenarios**:

1. **Given** two relics each granting +10% move speed, **When** move speed is computed, **Then** the combined relic multiplier is 1.20.
2. **Given** two relics each granting +10% max health, **When** max health is computed, **Then** the combined relic multiplier is 1.20.
3. **Given** two relics each granting +10% attack speed, **When** attack speed is computed, **Then** the combined relic multiplier is 1.20.
4. **Given** two relics each granting +10% crit chance, **When** crit chance is computed, **Then** the combined relic bonus is +20% (additive).
5. **Given** two relics each granting +10% crit multiplier, **When** crit multiplier is computed, **Then** the combined relic bonus is +20% (additive).
6. **Given** two relics each granting +10% damage reduction, **When** incoming damage is computed, **Then** the combined relic damage reduction bonus is +20% (additive).

---

### Edge Cases

- What happens when a player has zero relics for a stat? The relic contribution should be a neutral multiplier (1.0), leaving other sources unaffected.
- What happens when a single relic provides +100% to a stat? It should be treated as a +1.0 additive bonus for a combined relic multiplier of 2.0, then multiplied by other source factors.
- What happens when a conditional relic (executioner's mark, berserker stone) is active alongside standard damage relics? The conditional bonus is a separate multiplier applied at hit time and must continue to multiply against the already-combined relic × upgrade total.
- What happens if no modifier sources are active for a given stat? Final stat equals base stat (all multipliers default to 1.0).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST group stat modifiers by source category (e.g., "relic", "meta_upgrade"). Each source category constitutes one "modifier type."
- **FR-002**: For a given stat, all active modifiers within the same source category MUST have their bonus values summed additively. The combined factor for that category is `1 + sum_of_all_bonuses_in_category`.
- **FR-003**: The final stat value MUST be computed as the product of the combined factors across all active source categories: `base_stat × category_factor_1 × category_factor_2 × …`
- **FR-004**: When no modifiers of a given source category are active for a stat, that category contributes a neutral factor of 1.0 (no effect on the final value).
- **FR-005**: The stacking rule MUST apply uniformly to all stats that relics and upgrades affect: attack damage, attack speed, max health, move speed, crit chance, crit multiplier, and damage reduction.
- **FR-006**: Conditional hit-time modifiers (e.g., execute bonus, berserker bonus) MUST remain independent multipliers applied on top of the base stat calculation — they are not merged into the relic source category.
- **FR-007**: The change MUST NOT alter how modifier data is authored in data files; only the computation logic changes.

### Key Entities

- **Modifier Source Category**: A named grouping of modifiers (e.g., "relic", "meta_upgrade") that determines which bonuses stack additively with each other.
- **Bonus Value**: The fractional increase a single modifier contributes for a specific stat (e.g., 0.10 for a +10% bonus).
- **Category Factor**: The combined multiplier for one source category = `1 + sum(bonus values in category for a given stat)`.
- **Final Stat**: `base_stat × product(all category factors for that stat)`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Two relics each granting +10% to the same stat produce a combined multiplier of exactly 1.20 (additive), not 1.21 (multiplicative).
- **SC-002**: Two relics granting +10% damage combined with a +10% damage meta upgrade produce a final damage multiplier of exactly 1.32 (= 1.20 × 1.10).
- **SC-003**: All seven moddable stats (attack damage, attack speed, max health, move speed, crit chance, crit multiplier, damage reduction) obey the same stacking rule — verified independently for each.
- **SC-004**: A run with no relics and no upgrades produces stat multipliers of 1.0 — no regression in the zero-modifier baseline.
- **SC-005**: Conditional hit-time modifiers continue to function correctly alongside any combination of relic and upgrade modifiers.

## Assumptions

- "Relic" and "meta upgrade" are the two modifier source categories in scope for this feature. Additional categories (e.g., skill effects, status effects) are out of scope unless explicitly added later.
- The existing `effect_mult` field in relic data (e.g., 1.10 for a +10% bonus) will be reinterpreted as the raw bonus value (0.10), not a standalone multiplier. If the data stores 1.10, the system will extract the bonus as `effect_mult − 1.0 = 0.10`. Authoring format may need a one-time data migration or reinterpretation.
- The meta upgrade damage multiplier is computed from `damage_upgrade_level × damage_per_level` (e.g., level 1 → 0.10 bonus), forming the meta_upgrade category factor of `1 + bonus`.
- Existing conditional relics (executioner's mark, berserker stone) are excluded from the relic source category pool and continue to be applied as independent hit-time multipliers.
