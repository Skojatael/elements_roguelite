# Feature Specification: Player Crit Chance

**Feature Branch**: `051-player-crit-chance`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "add crit chance, data-driven stat for player only. by default it's 0. it should change the damage to damage = damage*(1 + crit multiplier), ex. dmg*(1+0.5) equals 50% crit multiplier. add crit multiplier too, base = 50%"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Crit Chance Triggers Bonus Damage (Priority: P1)

When the player deals damage (melee or magic missile), each hit has a percentage chance to critically strike. A critical hit multiplies the base damage using the formula `damage × (1 + crit_multiplier)`. With the default 50% crit multiplier, a 10-damage hit becomes 15 on a crit. By default, crit chance is 0% so no crits occur out of the box.

**Why this priority**: Core mechanic — without the crit roll and damage formula, the entire feature does nothing. All other stories depend on this.

**Independent Test**: Set crit chance to 100% in config, hit an enemy — every hit deals `base_damage × 1.5` (with 50% multiplier). Set crit chance back to 0% — all hits deal normal damage.

**Acceptance Scenarios**:

1. **Given** crit chance is 0%, **When** the player deals any damage, **Then** damage is always the base value (no crits ever occur).
2. **Given** crit chance is 100%, **When** the player deals any damage, **Then** every hit deals `base_damage × (1 + crit_multiplier)`.
3. **Given** crit chance is 50%, **When** the player deals many hits over time, **Then** approximately half the hits are crits and half are normal.
4. **Given** a crit occurs, **When** damage is calculated, **Then** the formula `damage × (1 + crit_multiplier)` is applied, floored to an integer.

---

### User Story 2 - Values are Data-Driven (Priority: P2)

Both `crit_chance` (default 0.0) and `crit_multiplier` (default 0.5) are defined in the game's data config. Changing these values in the config file changes in-game behaviour without any code modification.

**Why this priority**: The user explicitly required data-driven values. Hardcoding defeats the purpose and violates the project's data-driven principle.

**Independent Test**: Change `crit_multiplier` to `1.0` in config — crits deal double damage (`damage × 2.0`). Change `crit_chance` to `0.25` — roughly 1 in 4 hits crits. Both take effect on relaunch with no code change.

**Acceptance Scenarios**:

1. **Given** the config has `crit_chance: 0.0` and `crit_multiplier: 0.5`, **When** the game loads, **Then** those values drive all crit calculations.
2. **Given** a developer changes `crit_multiplier` to `2.0` in config, **When** the game relaunches, **Then** crits deal `base_damage × 3.0` total.
3. **Given** the config fields are absent, **When** the game loads, **Then** defaults of `crit_chance: 0.0` and `crit_multiplier: 0.5` apply and the game does not crash.

---

### User Story 3 - Crit Applies to All Player Damage Sources (Priority: P3)

Crit chance applies to all player-initiated damage: melee attacks and magic missile projectile hits. Enemy damage is never affected.

**Why this priority**: Consistency — a crit system that only works on some attacks would feel broken. Enemies are explicitly excluded per the user's requirement ("player only").

**Independent Test**: With crit chance 100%: melee hit crits. Magic missile hit crits. Enemy hit on player does NOT crit (enemy damage unchanged).

**Acceptance Scenarios**:

1. **Given** crit chance is 100%, **When** a melee attack lands, **Then** the hit deals `base_melee_damage × (1 + crit_multiplier)`.
2. **Given** crit chance is 100%, **When** a magic missile hits an enemy, **Then** the hit deals `base_missile_damage × (1 + crit_multiplier)`.
3. **Given** any crit chance, **When** an enemy attacks the player, **Then** enemy damage is always the base value (crits do not apply to enemies).

---

### Edge Cases

- What if `crit_chance` is set above 1.0 in config? Treat as 100% (clamp to 1.0).
- What if `crit_multiplier` is 0.0? A "crit" deals the same as a normal hit — valid, no special handling needed.
- What if `crit_multiplier` is negative? Result is damage reduction — allowed by the formula, no guard needed (designer's responsibility).
- Crit roll is per-hit, independent of previous hits — no streak protection or guaranteed-crit logic in this feature.
- Damage is floored to an integer after the crit multiplier is applied (consistent with existing floorf usage).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST roll a random chance per player damage event to determine if the hit is a critical strike.
- **FR-002**: The crit roll MUST use `crit_chance` (float 0.0–1.0) from config; a roll below `crit_chance` is a crit.
- **FR-003**: On a critical hit, damage MUST be calculated as `floorf(base_damage × (1 + crit_multiplier))`.
- **FR-004**: On a non-critical hit, damage MUST equal the base value unchanged.
- **FR-005**: `crit_chance` MUST default to `0.0` if absent from config (no crits by default).
- **FR-006**: `crit_multiplier` MUST default to `0.5` if absent from config (50% bonus).
- **FR-007**: Crit logic MUST apply to melee damage dealt by the player.
- **FR-008**: Crit logic MUST apply to magic missile damage dealt by the player.
- **FR-009**: Enemy damage MUST NOT be affected by crit logic.
- **FR-010**: `crit_chance` values above 1.0 in config MUST be treated as 1.0 (clamped).

### Key Entities

- **Crit Config**: A pair of floats (`crit_chance: float`, `crit_multiplier: float`) stored in the player stats config. Read at game load; immutable at runtime in this feature.
- **Crit Roll**: A per-hit random float in [0, 1). If less than `crit_chance`, the hit is a crit.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With `crit_chance = 0.0`, zero out of any number of player hits are crits.
- **SC-002**: With `crit_chance = 1.0` and `crit_multiplier = 0.5`, every player hit deals exactly `floorf(base_damage × 1.5)`.
- **SC-003**: Changing `crit_chance` or `crit_multiplier` in config and relaunching changes in-game crit behaviour with no code modification.
- **SC-004**: Enemy hits on the player are never modified by crit logic regardless of config values.
- **SC-005**: Both melee and magic missile hits crit independently based on the same `crit_chance` roll.

## Assumptions

- Crit chance and crit multiplier are global player stats (not per-skill, not per-weapon). One pair of values covers all damage sources.
- There is no visual crit indicator (floating text, color change) in this feature — that is a future concern.
- Crit stats are not yet grantable via relics or meta upgrades in this feature; they are fixed by config only.
- The config values live in `data/player_stats.json` (a new JSON file), consistent with the data-driven pattern already used for enemies and skills.
- Crit multiplier is additive to 1.0 as described: `damage × (1 + crit_multiplier)`. A multiplier of 0.5 = 50% bonus, not 50% of base.
