# Feature Specification: Chain Damage Relic

**Feature Branch**: `068-chain-damage-relic`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "add conditional common relic with chain_unlocked that gives +15% damage on chain targets. that means on second target of a chained magic missile we will have 0.65 of normal damage (additive)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Relic Appears After Chain Mechanic is Unlocked (Priority: P1)

The player picks up the `chaining_stone` relic. In subsequent offers that run, a new common relic (tagged `chain_unlocked`) becomes eligible. The player picks it up, and from that point chain hits deal 0.65× primary damage instead of 0.50×.

**Why this priority**: The relic must be correctly gated and acquirable before any damage change can be tested.

**Independent Test**: Pick `chaining_stone` then trigger a relic offer — verify the new relic appears in the draw pool and can be selected.

**Acceptance Scenarios**:

1. **Given** the player has NOT picked `chaining_stone` in the current run, **When** a relic offer is drawn, **Then** the `chain_power_stone` relic does not appear.
2. **Given** the player has picked `chaining_stone`, **When** a relic offer is drawn, **Then** `chain_power_stone` is eligible to appear (it has `chain_unlocked` tag).
3. **Given** the player picks `chain_power_stone`, **Then** it appears in `RelicManager.active_relic_ids` and is excluded from future offers (uniqueness rule).
4. **Given** the full relic pool is loaded, **Then** `chain_power_stone` has `tier: "common"`.

---

### User Story 2 - Chain Hits Deal 0.65× Damage When Relic is Held (Priority: P1)

The player holds both `chaining_stone` and `chain_power_stone`. A magic missile hits a primary target, then chains to a second enemy. The second enemy receives 0.65× primary damage (additive: base chain_damage_mult 0.50 + relic bonus 0.15).

**Why this priority**: This is the core gameplay effect of the feature.

**Independent Test**: With both relics held and known primary damage, verify chained target takes exactly `primary_damage × 0.65`.

**Acceptance Scenarios**:

1. **Given** both relics held and `chain_damage_mult = 0.5` in config, **When** missile deals 20 damage to the primary target, **Then** the chained target receives 13 damage (20 × 0.65).
2. **Given** only `chaining_stone` held (no `chain_power_stone`), **When** missile chains, **Then** chained target receives 10 damage (20 × 0.50) — relic has no effect when absent.
3. **Given** both relics held and attack damage is boosted by another relic, **When** missile chains, **Then** chain damage is `(boosted primary damage) × 0.65`.
4. **Given** `chain_power_stone` is held but `chaining_stone` is not, **Then** no chain occurs — the chain_power_stone relic has no observable effect (it only modifies a chain that cannot happen).

---

### Edge Cases

- What if `chain_damage_mult` is changed in config to a non-default value? The relic bonus (0.15) is always additive on top of the config value.
- What if another future relic also adds to chain damage? Each such relic contributes its own additive bonus — the effective multiplier sums all bonuses onto `chain_damage_mult`.
- Can `chain_power_stone` be offered without `chaining_stone` ever being picked? No — the 064 mechanic unlock system gates `chain_unlocked` relics entirely.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST include a new relic entry with `id: "chain_power_stone"`, `tier: "common"`, `tags: ["chain_unlocked"]`, `effect_stat: ""`, `effect_mult: 1.0`, and appropriate `name` and `description` fields in `data/relics.json`.
- **FR-002**: `RelicManagerImpl` MUST expose `get_chain_damage_bonus() -> float` that returns `0.15` if `chain_power_stone` is in `active_relic_ids`, otherwise `0.0`.
- **FR-003**: The chain hit damage calculation MUST use `chain_damage_mult + RelicManager.get_chain_damage_bonus()` as the effective multiplier — additive composition.
- **FR-004**: The relic MUST be treated as a conditional relic (`effect_stat: ""`), consistent with `executioners_mark` and `berserker_stone`, so `compute_stat_mult` ignores it.
- **FR-005**: The mechanic unlock tag `chain_unlocked` MUST integrate with the 064 mechanic unlock system — the relic is ineligible for offers until `chaining_stone` is held in the current run.

### Key Entities

- **chain_power_stone relic**: Common, conditional. No stat multiplier. Additive +0.15 bonus to `chain_damage_mult` when computing chain hit damage.
- **chain_damage_bonus**: Float value returned by `get_chain_damage_bonus()`. Added to the config-defined `chain_damage_mult` at hit time.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With both relics held and known primary damage, chained target always takes exactly `primary_damage × (chain_damage_mult + 0.15)`. Verifiable by HP inspection.
- **SC-002**: Without `chain_power_stone`, chain damage is unchanged from the 053 baseline (`primary_damage × chain_damage_mult`).
- **SC-003**: `chain_power_stone` never appears in a relic offer unless `chaining_stone` was already picked in the current run.
- **SC-004**: `chain_power_stone` has `tier: "common"` in the relic pool and can appear in standard (non-boss) offers once eligible.

## Assumptions

- `chaining_stone` (053) is already implemented and its `chain_damage_mult` config field exists in `data/skills.json` under the magic missile entry.
- The 064 mechanic unlock system is implemented and correctly filters `chain_unlocked` relics based on active mechanics in the current run.
- The bonus value 0.15 is hardcoded in `get_chain_damage_bonus()` (not in config), consistent with how other conditional relic bonuses are defined (see `get_hit_damage_mult` for `executioners_mark`/`berserker_stone`).
- No visual distinction is needed on the chain hit for this iteration; the damage change is the full deliverable.
