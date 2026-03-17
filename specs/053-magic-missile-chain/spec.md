# Feature Specification: Magic Missile Chain Relic

**Feature Branch**: `053-magic-missile-chain`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "introduce chain mechanic for magic missile. it should be a relic that adds +1 enemy struck if obtained. the chain should be to closest enemy to the first target. it should be uncommon. ask for clarification if needed"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Acquire Chaining Stone Relic (Priority: P1)

The player is offered the "Chaining Stone" relic after clearing a room. They pick it up. From that point forward, every magic missile that hits an enemy automatically travels to the closest other enemy in range.

**Why this priority**: This is the core deliverable — the relic must exist in the pool and be acquirable before any chaining behavior can be tested.

**Independent Test**: Pick up the relic via the offer screen; verify it appears in the active relics list. Can be tested without ever firing a missile.

**Acceptance Scenarios**:

1. **Given** a relic offer is shown, **When** the player picks the relic with ID `chaining_stone`, **Then** it appears in `RelicManager.active_relic_ids`.
2. **Given** the relic pool is loaded, **When** the game draws uncommon relics, **Then** `chaining_stone` can appear in the draw (it has `tier: "uncommon"`).
3. **Given** the player already holds `chaining_stone`, **When** a relic offer is generated, **Then** `chaining_stone` is excluded from the offer (unique-per-run, no duplicates).

---

### User Story 2 - Magic Missile Chains to Nearest Enemy (Priority: P1)

The player has the Chaining Stone relic. They fire a magic missile that strikes an enemy. The missile then automatically seeks and hits the closest other enemy to the first target, dealing damage to it as well.

**Why this priority**: This is the primary gameplay effect the feature delivers.

**Independent Test**: With relic held and two or more enemies alive, fire magic missile and observe it hit a second enemy. Measurable: enemies-hit count is 2 instead of 1.

**Acceptance Scenarios**:

1. **Given** the player holds `chaining_stone` and two enemies are in the room, **When** a magic missile hits the first enemy, **Then** the missile also deals damage to the second (nearest) enemy.
2. **Given** the player holds `chaining_stone` and three or more enemies are in the room, **When** a magic missile hits the primary target, **Then** the chain goes to the single closest enemy to the hit point (not the closest to the player).
3. **Given** the player holds `chaining_stone` and only one enemy is alive, **When** a magic missile hits that enemy, **Then** no chain occurs (no second target to hit).
4. **Given** the player does NOT hold `chaining_stone`, **When** a magic missile hits an enemy, **Then** the missile does not chain (baseline unchanged).

---

### User Story 3 - Chain Damage is Reduced by a Configurable Multiplier (Priority: P2)

The chained hit deals a fraction of the primary hit's damage. The multiplier is stored in config (default 0.5), so designers can tune it without touching code.

**Why this priority**: Establishes the power level of the relic so gameplay is predictable; important for balance expectations and tuning.

**Independent Test**: With primary damage known, verify the chained target takes exactly `primary_damage × chain_damage_mult` HP. Change the config value and re-run — damage must reflect the new value without redeployment.

**Acceptance Scenarios**:

1. **Given** `chaining_stone` is held and `chain_damage_mult = 0.5` in config, **When** the missile deals 20 damage to the primary target, **Then** the chained target receives 10 damage.
2. **Given** `chaining_stone` is held and attack damage is boosted by another relic, **When** the missile chains, **Then** the chained hit applies `(boosted primary damage) × chain_damage_mult` — multipliers stack correctly.
3. **Given** `chaining_stone` is held and Executioner's Mark is also held and the chained target is below 30% HP, **Then** Executioner's Mark bonus applies before `chain_damage_mult` is applied.
4. **Given** `chain_damage_mult` is updated in config to any value in [0.0, 1.0], **When** the game is run, **Then** chain damage reflects the new value without any code change.

---

### Edge Cases

- What happens when the only other "enemy" nearby is already dead at the moment the chain resolves? → Chain skips it; no chain occurs if no living second enemy exists.
- What happens if two enemies are equidistant from the first target? → Either may be selected (deterministic tie-breaking not required; nearest is sufficient).
- Does the chain trigger additional on-hit effects (future relics, DoTs)? → Out of scope for this feature; chain is a simple damage application.
- Can the missile chain back to the original target? → No; the original target is excluded from chain selection.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST include a new relic entry `chaining_stone` in `data/relics.json` with `tier: "uncommon"`, `effect_stat: ""`, `effect_mult: 1.0`, and appropriate `name`, `tags`, and `description` fields.
- **FR-002**: `RelicManagerImpl` MUST expose a query `has_chain_relic() -> bool` that returns `true` when `chaining_stone` is in `active_relic_ids`.
- **FR-003**: After a magic missile deals damage to a primary target, the system MUST check `RelicManager.has_chain_relic()`; if `true` and at least one other living enemy exists in the current room, the missile MUST deal damage to the closest living enemy to the impact point.
- **FR-004**: The chained target MUST be the enemy with the smallest distance from the primary hit position, excluding the primary target itself and any dead enemies.
- **FR-005**: The chain hit MUST apply `primary_damage × chain_damage_mult` damage, where `chain_damage_mult` is read from `data/skills.json` (or equivalent skill config) under the magic missile entry. Default value: `0.5`.
- **FR-006**: The chain MUST NOT propagate further (no chain-of-chain); exactly one additional enemy is hit per missile per firing event.
- **FR-007**: The relic MUST be treated as a conditional relic (`effect_stat: ""`), consistent with existing conditional relics (`executioners_mark`, `berserker_stone`), so `compute_stat_mult` ignores it.

### Key Entities

- **chaining_stone relic**: Uncommon relic. No stat multiplier. Activates chain behavior in the magic missile projectile system when present in `active_relic_ids`.
- **Chain resolution**: Post-hit logic that queries nearby living enemies, finds the closest to the impact point (excluding the struck enemy), and applies `primary_damage × chain_damage_mult` to it.
- **chain_damage_mult**: Numeric config field on the magic missile skill definition. Controls what fraction of primary damage the chain hit deals. Default `0.5`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With the relic held and two enemies present, every magic missile hit results in exactly 2 enemies taking damage (primary + 1 chain), verifiable by inspecting HP changes each shot.
- **SC-002**: Without the relic held, no second enemy takes damage from a single missile — baseline is unaffected.
- **SC-003**: The relic appears in drawn offers with `tier: "uncommon"` and is excluded from redraws once held.
- **SC-004**: Chain damage equals `primary_damage × chain_damage_mult` (0.5 by default). Changing `chain_damage_mult` in config and relaunching produces proportionally different chain damage with no code change.
- **SC-005**: With only one living enemy, no error or crash occurs — missile behaves identically to the no-relic baseline.

## Assumptions

- Magic missile projectile code already computes a damage value before applying it to the target; the chain feature reuses that computed value (multiplied by `chain_damage_mult`) rather than recomputing it.
- `chain_damage_mult` lives alongside other magic missile parameters in the skill config (`data/skills.json`).
- Enemy nodes in the current room are accessible from the projectile at hit time (e.g., via `get_tree().get_nodes_in_group("enemies")` or equivalent).
- Chain range is unlimited — closest living enemy regardless of physical distance. If range cap is desired in future, that is a separate feature.
- The relic is unique within a run (already guaranteed by the existing offer system that excludes held relics).
- No visual chain effect (e.g., lightning arc) is required in this iteration; the damage application is the deliverable. Visual effects are deferred to a future feature.
