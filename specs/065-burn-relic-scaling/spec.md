# Feature Specification: Burn Relic Damage Scaling

**Feature Branch**: `065-burn-relic-scaling`
**Created**: 2026-03-19
**Status**: Draft
**Input**: User description: "Changes needed to support burn damage relic scaling"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Bottled Oil Increases Burn Tick Damage (Priority: P1)

The player holds the "Bottled Oil" relic, which promises to increase burn damage. When they ignite an enemy — whether from a projectile or a skill — each tick of the burning effect deals more damage than it would without the relic. The player can observe this in combat by watching enemy health drain faster during the burning status.

**Why this priority**: The Bottled Oil relic already exists in the game's item pool and is collectible by players today. Its stated effect is non-functional, meaning players who pick it up receive no actual benefit. Fixing this is the highest-priority item because it corrects a broken player-facing promise.

**Independent Test**: Equip Bottled Oil, ignite an enemy, and measure how much health the enemy loses per burn tick. Compare against a run without the relic — the per-tick loss must be visibly and numerically higher by the relic's stated 20% bonus.

**Acceptance Scenarios**:

1. **Given** the player has no burn relics, **When** a burn is applied to an enemy and ticks, **Then** the enemy loses health equal to the base burn tick damage amount.
2. **Given** the player holds Bottled Oil (+20% burn damage), **When** a burn is applied and ticks, **Then** each tick deals 20% more damage than the base amount.
3. **Given** the player holds Bottled Oil, **When** burn is applied via a projectile, **Then** the increased tick damage applies.
4. **Given** the player holds Bottled Oil, **When** burn is applied via a skill, **Then** the increased tick damage applies equally.
5. **Given** the player holds multiple burn damage relics (if stacking is possible), **When** a burn ticks, **Then** all burn damage bonuses are combined and applied together.

---

### User Story 2 - Searing Seal Rewards Burning Targets With Bonus Hit Damage (Priority: P2)

The player holds the "Searing Seal" relic (uncommon). Its description reads: "Burning enemies take 50% more damage while burning." When the player deals a direct hit — from a projectile or combat strike — against an enemy that is currently on fire, that hit deals 50% more damage. Enemies that are not burning are unaffected by this bonus.

**Why this priority**: This is a new conditional relic that creates an intentional synergy: the player is rewarded for applying burn before striking. This adds meaningful decision-making and build depth, but requires both burn application and direct damage in the same encounter to show value. It is lower priority than P1 because it is net-new functionality rather than a fix for a broken existing feature.

**Independent Test**: Equip Searing Seal, find an enemy, and attack it both while it is burning and while it is not burning. The hit damage against a burning enemy must be 50% higher than the hit damage against the same enemy type when not burning.

**Acceptance Scenarios**:

1. **Given** the player holds Searing Seal and an enemy is not burning, **When** the player lands a hit, **Then** the hit deals normal damage with no Searing Seal bonus.
2. **Given** the player holds Searing Seal and an enemy is currently burning, **When** the player lands a hit, **Then** the hit deals 50% more damage.
3. **Given** the player does not hold Searing Seal, **When** an enemy is burning and the player lands a hit, **Then** no bonus damage is applied (the relic has no passive effect without being held).
4. **Given** the player holds both Searing Seal and another conditional relic (e.g. Executioner's Mark), **When** the player hits a burning enemy that is also below the execute threshold, **Then** both conditional multipliers apply to the same hit.
5. **Given** the player holds Searing Seal and an enemy's burn expires mid-combat, **When** the player lands a hit after the burn has expired, **Then** no Searing Seal bonus applies to that hit.

---

### Edge Cases

- What happens when burn is applied and immediately expires in the same frame — does Searing Seal apply to a hit in that same frame?
- How does the system handle a Bottled Oil bonus when multiple burn sources are active (e.g. burn extended by a skill and a projectile simultaneously)?
- If the player picks up Bottled Oil mid-run after enemies have already been ignited, do currently active burns benefit from the new bonus, or only new burns applied after pickup?
- What if an enemy becomes burning from a non-player source — does Searing Seal still apply?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The burn tick damage dealt to enemies MUST be multiplied by the combined burn damage bonus from all held relics with the "burn_damage" effect.
- **FR-002**: The burn damage multiplier MUST apply to burn ticks regardless of whether the burn was applied via a projectile or a skill.
- **FR-003**: The game MUST be able to determine at any point during combat whether a specific enemy is currently in a burning state.
- **FR-004**: When the player holds the Searing Seal relic and lands a direct hit on a burning enemy, that hit's damage MUST be multiplied by 1.50 (50% bonus).
- **FR-005**: The Searing Seal damage bonus MUST only trigger when the target is actively burning at the moment of the hit — not before burn is applied, and not after it expires.
- **FR-006**: The Searing Seal bonus MUST stack correctly with other conditional hit damage bonuses (e.g. execute-threshold relics) — all applicable conditional multipliers apply to the same hit.
- **FR-007**: The Searing Seal relic MUST exist in the relic data as an uncommon-tier item with a blank stat effect (its bonus is conditional, not a flat multiplier) and an appropriate player-facing description.
- **FR-008**: The Bottled Oil relic's burn damage bonus MUST be additive with other "burn_damage" relics using the same formula already used for all other additive relic stats.
- **FR-009**: Relics with the "burn_damage" effect stat MUST NOT affect direct hit damage — only burn tick damage.
- **FR-010**: The Searing Seal conditional check MUST NOT affect burn tick damage — it applies only to direct hits.

### Key Entities

- **Burn Status**: A time-limited damage-over-time effect applied to an enemy. Has an active/inactive state and a per-tick damage value. The active state is what Searing Seal inspects, and the per-tick value is what Bottled Oil scales.
- **Burn Damage Multiplier**: A run-scoped value assembled from all held relics that affect burn damage. Applied as a multiplier on every burn tick. Computed from the same additive relic system used by other stat bonuses.
- **Conditional Hit Multiplier**: A per-hit value computed at the moment of a direct hit, based on runtime context (target burning state, player HP ratio, target HP ratio). Searing Seal contributes to this value.
- **Relic — Bottled Oil** (common, burn_damage effect): Increases all burn tick damage by 20% per copy held.
- **Relic — Searing Seal** (uncommon, conditional): Increases direct hit damage by 50% against enemies that are currently burning. Uses no flat stat effect; evaluated at hit time.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Holding Bottled Oil produces a measurable 20% increase in burn tick damage compared to a baseline run without the relic — verifiable by observing per-tick health loss on an enemy.
- **SC-002**: Holding Searing Seal produces a measurable 50% increase in direct hit damage against a burning enemy, and zero bonus against a non-burning enemy — verifiable by comparing hit numbers in both states.
- **SC-003**: Burn ticks and direct hits remain independent — Bottled Oil does not affect hit damage and Searing Seal does not affect burn tick damage.
- **SC-004**: Both relic effects combine correctly with all other relic bonuses active in the same run — no relic interaction causes incorrect damage values (zero damage, negative damage, or unintended multiplicative explosion).
- **SC-005**: The Searing Seal relic entry appears correctly in the relic offer pool as an uncommon item and can be collected and held during a run without errors.
