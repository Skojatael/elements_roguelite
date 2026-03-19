# Feature Specification: Damage Reduction

**Feature Branch**: `062-damage-reduction`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "add mechanic that reduces incoming damage (both player and enemies are eligible). example value 10% less damage taken"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Player Acquires Damage Reduction (Priority: P1)

A player picks up a relic or upgrade that grants damage reduction. For the rest of the run, all incoming damage to the player is reduced by the specified percentage. This makes the player more durable and rewards defensive build choices.

**Why this priority**: Core mechanic — without this the feature has no player-facing gameplay value.

**Independent Test**: Equip a relic granting 10% damage reduction, receive a hit that would deal 100 damage, observe the player takes 90 damage instead.

**Acceptance Scenarios**:

1. **Given** the player has 10% damage reduction, **When** an enemy deals 100 base damage, **Then** the player receives 90 damage.
2. **Given** the player has no damage reduction, **When** an enemy deals 100 base damage, **Then** the player receives 100 damage (no change from current behaviour).
3. **Given** the player has sources totalling more than 50% damage reduction, **When** an enemy deals any amount of damage, **Then** the player receives no less than 50% of the original damage (cap enforced).

---

### User Story 2 - Enemy Has Innate Damage Reduction (Priority: P2)

Certain enemy types have a built-in damage reduction value defined in game data. Hits against those enemies deal less damage, making them tougher to kill and requiring the player to adapt their strategy.

**Why this priority**: Enables enemy variety and difficulty tuning without changing raw health values; secondary to the player-facing use case.

**Independent Test**: Attack an enemy with 20% damage reduction using a 50-damage hit; observe the enemy loses 40 HP instead of 50.

**Acceptance Scenarios**:

1. **Given** an enemy has 20% damage reduction, **When** the player deals 50 damage, **Then** the enemy loses 40 HP.
2. **Given** two enemy types — one with 0% reduction and one with 25% reduction — **When** the same attack hits both, **Then** the reduced enemy takes 25% less damage than the unreduced enemy.
3. **Given** an enemy with damage reduction is scaled by the dungeon difficulty multiplier, **When** the enemy is hit, **Then** damage reduction applies independently of difficulty scaling (both stack multiplicatively on final result).

---

### User Story 3 - Multiple Reduction Sources Stack (Priority: P3)

A player accumulates multiple relics that each grant a percentage damage reduction. The combined effect reduces damage further, following a consistent stacking rule so the outcome is predictable.

**Why this priority**: Defines the stacking model, which is needed for balance — but is only testable once Story 1 is working.

**Independent Test**: Equip two relics each granting 10% damage reduction; receive a 100-damage hit and observe the player takes 80 damage (additive: 10% + 10% = 20% total reduction).

**Acceptance Scenarios**:

1. **Given** the player holds two relics each with 10% reduction, **When** struck for 100 damage, **Then** the player takes 80 damage (additive stacking: 20% total reduction).
2. **Given** the player holds three reduction sources (10%, 10%, 20%), **When** struck for 100 damage, **Then** the result follows the same additive rule (10% + 10% + 20% = 40% total, player takes 60 damage).
3. **Given** reduction from relics and a passive upgrade both apply, **When** damage is calculated, **Then** all sources are combined under the same stacking rule.

---

### Edge Cases

- What is the minimum damage dealt after reduction — can reduction bring damage to 0, or is there a floor of 1?
- How does damage reduction interact with the difficulty multiplier already applied to enemy max health?
- Burn DoT deals damage through a separate unmitigated pathway — it ignores `damage_reduction` entirely.
- Can damage reduction exceed 50% via enemy innate reduction? Enemy `damage_reduction` in data should also be authored within the 0.0–0.5 range — no runtime enforcement needed if data is controlled.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST apply a `damage_reduction` multiplier to any incoming hit before deducting HP from the recipient (player or enemy).
- **FR-002**: `damage_reduction` MUST be expressed as a value between 0.0 and 0.5, where 0.0 = no reduction and 0.5 = maximum 50% reduction. Example: 0.10 = 10% less damage taken.
- **FR-003**: Final damage after reduction MUST be `max(0, floor(raw_damage × (1.0 − damage_reduction)))`, capping at 0 and never going negative.
- **FR-004**: The player's `damage_reduction` MUST be computed by summing all active relic effects tagged `damage_reduction` using additive stacking: `r1 + r2 + …`, clamped to [0.0, 0.5].
- **FR-005**: Each enemy type in game data MUST support an optional `damage_reduction` field (default 0.0 when absent) that the spawning system reads and applies.
- **FR-006**: The player's `StatsComponent` MUST expose `damage_reduction` as a reactive stat that recomputes when relics change, consistent with how `max_health` and `move_speed` are currently handled.
- **FR-007**: The damage-dealt calculation in `CombatComponent` MUST apply the target's `damage_reduction` at hit time, regardless of whether the target is the player or an enemy.
- **FR-008**: Damage reduction MUST NOT affect healing, HP-regen, or burn/DoT damage — only direct incoming hits (melee contact, projectile).
- **FR-009**: The `data/relics.json` file MUST support at least one new relic entry using `effect_stat: "damage_reduction"` as a demonstration of the mechanic.

### Key Entities

- **DamageReduction stat**: A float [0.0–1.0] attached to either the player (via StatsComponent) or an enemy (via EnemyData). Represents the fraction of incoming damage negated.
- **Relic (damage_reduction tag)**: An existing Relic entry whose `effect_stat` is `"damage_reduction"`. Contributes to the player's combined reduction via additive stacking in `RelicManagerImpl.compute_stat_mult`.
- **EnemyData (damage_reduction field)**: Optional float field in `enemies.json` per enemy entry. Read by the enemy instance at spawn time.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player with a 10% damage-reduction relic equipped takes exactly 10% less damage per hit compared to baseline — verifiable by unit test or in-game hit log.
- **SC-002**: An enemy with `damage_reduction: 0.20` in game data receives exactly 20% less damage per hit — verifiable by unit test.
- **SC-003**: Two 10% reduction sources stack to produce exactly 20% total reduction (additive) — verifiable by unit test.
- **SC-004**: Damage reduction is capped at 50% regardless of how many sources are active — a 100-damage hit always deals at least 50 damage — verifiable by unit test.
- **SC-005**: The player's effective damage reduction updates immediately when a new relic is applied mid-run, with no restart required.

## Assumptions

- Stacking model is **additive** (all sources are summed, then clamped to 0.5). This differs from the multiplicative model used for damage/speed multipliers — damage reduction is a special case where simple addition is preferred for predictability. The 50% cap ensures enemies always deal meaningful damage regardless of build.
- Damage reduction caps at 0.5 (50%) — no over-cap mechanics.
- Burn/DoT (054-magic-missile-burn) bypasses `damage_reduction` entirely — it uses an unmitigated damage pathway so that DR cannot trivially nullify sustained burn damage.
- Enemy damage reduction is a fixed base stat from data — it does not scale with the dungeon difficulty multiplier (which scales HP only).
- At least one new relic with `effect_stat: "damage_reduction"` will be added to `relics.json` to make the mechanic accessible during gameplay.
- The floor of final damage is **0** (full immunity is permitted); there is no "minimum 1 damage" rule unless a future spec adds it.
