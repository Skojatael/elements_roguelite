# Feature Specification: Crit Relic Integration

**Feature Branch**: `052-crit-relic-integration`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "tie crit chance and crit multiplier to relics. so if I introduce new relics that modify those stats, they are correctly updated"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Relic Grants Bonus Crit Chance (Priority: P1)

When the player picks a relic that grants crit chance, the player's effective crit chance immediately increases. Subsequent hits use the updated value for the crit roll. If the relic is cleared at run end, crit chance returns to the base config value.

**Why this priority**: Core of the feature — without reactive crit chance updating, picking a crit relic has no effect.

**Independent Test**: Add a relic with `effect_stat = "crit_chance"` and `effect_mult = 0.15` (represents +15% flat bonus), pick it, hit an enemy with crit chance set to 100% baseline — confirm crits fire. Then end the run and verify crit chance reverts to base.

**Acceptance Scenarios**:

1. **Given** a relic with a crit chance bonus exists and base crit chance is 0%, **When** the player picks the relic, **Then** the player's effective crit chance increases by the relic's bonus amount.
2. **Given** a crit chance relic is active, **When** the player deals damage, **Then** the crit roll uses the updated effective crit chance (not the base config value).
3. **Given** one or more crit chance relics are active, **When** the run ends and relics are cleared, **Then** effective crit chance reverts to the base config value.

---

### User Story 2 - Relic Grants Bonus Crit Multiplier (Priority: P1)

When the player picks a relic that grants crit multiplier, the effective crit multiplier immediately updates. A critical hit then deals more damage than before. On run end and relic clear, crit multiplier reverts to the base config value.

**Why this priority**: Symmetric with crit chance — both stats must be relic-modifiable for the feature to be complete. Both are P1 since the feature is specifically about wiring up these two stats.

**Independent Test**: Set crit chance to 100% and base crit multiplier to 0.5 (50% bonus). Add a relic with `effect_stat = "crit_multiplier"` and `effect_mult = 0.25`. After picking, each hit should apply a 75% bonus instead of 50%. Verify by checking damage output.

**Acceptance Scenarios**:

1. **Given** a relic with a crit multiplier bonus and base crit_multiplier = 0.5, **When** the player picks the relic, **Then** the effective crit multiplier increases beyond 0.5.
2. **Given** the updated crit multiplier, **When** a critical hit occurs, **Then** damage uses the new effective multiplier in the formula `damage × (1 + effective_crit_multiplier)`.
3. **Given** the run ends, **When** relics are cleared, **Then** effective crit multiplier reverts to base config value (0.5 default).

---

### User Story 3 - Multiple Crit Relics Stack Correctly (Priority: P2)

If the player holds more than one relic that boosts the same crit stat, their combined effect is applied when calculating the effective value. Order of pickup does not matter — the total bonus is the sum of all active relic contributions.

**Why this priority**: Stacking relics is the standard relic behaviour for all other stats; crit stats must be consistent.

**Independent Test**: Pick two relics each granting +10% crit chance. Effective crit chance should be base + 20% total (not just 10% from the last relic picked).

**Acceptance Scenarios**:

1. **Given** two crit chance relics are active, **When** damage is dealt, **Then** the effective crit chance reflects both bonuses combined.
2. **Given** two crit multiplier relics are active, **When** a crit occurs, **Then** the damage calculation uses the combined crit multiplier bonus.
3. **Given** relics boosting different stats (e.g. one crit chance, one crit multiplier), **When** a crit occurs, **Then** both stats reflect their respective relic bonuses independently.

---

### Edge Cases

- What if a crit chance relic bonus would push effective crit chance above 1.0? Effective crit chance is clamped to 1.0 (consistent with base config clamping rule from spec 051).
- What if there are no crit relics active? Effective values equal the base config values — no change to existing behaviour.
- What if base crit chance is 0.0 and a crit relic uses a multiplicative approach? The base value must be treated as a flat addend from the relic — the spec assumes additive semantics for crit chance (see Assumptions).
- What happens when a relic is applied mid-run? The new effective values take effect immediately on the next hit; no retroactive recalculation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST recognise `"crit_chance"` as a valid relic `effect_stat` category.
- **FR-002**: The system MUST recognise `"crit_multiplier"` as a valid relic `effect_stat` category.
- **FR-003**: When a relic with `effect_stat = "crit_chance"` is picked, the player's effective crit chance MUST update immediately.
- **FR-004**: When a relic with `effect_stat = "crit_multiplier"` is picked, the player's effective crit multiplier MUST update immediately.
- **FR-005**: Effective crit chance MUST be computed as `base_crit_chance + sum of all active crit chance relic bonuses`, clamped to [0.0, 1.0].
- **FR-006**: Effective crit multiplier MUST be computed as `base_crit_multiplier + sum of all active crit multiplier relic bonuses`.
- **FR-007**: When relics are cleared (run end), effective crit chance and crit multiplier MUST revert to their base config values.
- **FR-008**: The damage formula MUST use effective crit chance for the crit roll and effective crit multiplier for the damage bonus.
- **FR-009**: Crit stat updates from relics MUST follow the same reactive pattern as existing relic-driven stats (attack damage, attack speed, etc.) — recalculated whenever a relic is applied or cleared.
- **FR-010**: Effective crit chance MUST be clamped to a maximum of 1.0 regardless of how many crit chance relics are active.

### Key Entities

- **Crit Chance Relic**: A relic whose `effect_stat` is `"crit_chance"`. Its `effect_mult` represents the flat bonus added to base crit chance (e.g. `0.15` = +15%).
- **Crit Multiplier Relic**: A relic whose `effect_stat` is `"crit_multiplier"`. Its `effect_mult` represents the flat bonus added to base crit multiplier (e.g. `0.25` = +25% bonus on top of base).
- **Effective Crit Chance**: The crit chance actually used in the roll — base config value plus all active relic bonuses, clamped to [0.0, 1.0].
- **Effective Crit Multiplier**: The crit multiplier actually used in the damage formula — base config value plus all active relic bonuses.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Picking a crit chance relic with a positive bonus increases the observed crit frequency above the base rate in the same run.
- **SC-002**: Picking a crit multiplier relic with a positive bonus increases the damage of observed crits above the base-multiplier amount.
- **SC-003**: Two crit chance relics each granting +10% result in an effective crit chance of base + 20%, not base + 10%.
- **SC-004**: After a run ends (relics cleared), crit behaviour is identical to a fresh run with no relics.
- **SC-005**: No existing relic stat categories (attack damage, attack speed, max health, move speed) are affected by this change.
- **SC-006**: With `crit_chance = 0.0` base and a single relic granting +15%, the effective crit chance is exactly 0.15.

## Assumptions

- Crit relic bonuses use additive semantics for both stats: `effective = base + sum(relic bonuses)`. This is necessary because `base_crit_chance = 0.0` makes multiplicative semantics useless (0 × anything = 0).
- Relic `effect_mult` for crit stats represents the flat bonus amount (e.g. `0.15` = 0.15 added to the base), not a multiplier over the current value.
- This feature does not add any new relic data entries — it only wires up the plumbing so future crit relics work. New relic JSON entries are authored separately.
- The reactive update pattern (connect to `relic_applied` and `relics_cleared`, recompute) mirrors the existing pattern used for attack damage, attack speed, max health, and move speed.
- Crit logic continues to apply to all player damage sources (melee + magic missile) as established in spec 051. This feature does not change that scope.
- No visual crit indicator is added in this feature.
