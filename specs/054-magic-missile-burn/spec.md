# Feature Specification: Magic Missile Burn

**Feature Branch**: `054-magic-missile-burn`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "add following ability: burn on magic missile. it deals 20% attack damage over 2s, tick each second. multiple hits increase duration (each hit +2s). ask for clarification if needed"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Acquire the Living Ember Relic (Priority: P1)

The player is offered the "Living Ember" relic after clearing a room. Picking it up permanently enables burn on all subsequent magic missile hits for the remainder of the run. Without the relic, magic missile behaves exactly as before — no burn.

**Why this priority**: The relic must exist in the pool and be acquirable before any burn behaviour can be tested.

**Independent Test**: Pick up the relic via the offer screen; verify it appears in the active relics list. Fire a missile without the relic — no burn. Fire after picking it up — burn applies.

**Acceptance Scenarios**:

1. **Given** a relic offer is shown, **When** the player picks the relic with ID `burn`, **Then** it appears in the active relics list.
2. **Given** the player does NOT hold `burn`, **When** a magic missile hits an enemy, **Then** no burn is applied and the enemy's HP does not decrease after the hit.
3. **Given** the player holds `burn`, **When** a magic missile hits a living enemy, **Then** the enemy loses HP from the missile impact AND subsequently loses HP at t=1s and t=2s from the burn.
4. **Given** an enemy has a burn applied, **When** the 2-second duration expires, **Then** the enemy stops losing HP from burn.
5. **Given** an enemy dies from missile impact damage, **When** the burn would have ticked, **Then** no burn ticks occur (enemy is already dead).

---

### User Story 2 - Burn Duration Extends on Re-hit (Priority: P1)

If a burning enemy is struck by another magic missile while the burn is still active, the burn duration is extended by 2 additional seconds rather than starting a new separate burn instance. Each subsequent hit adds another 2 seconds to the remaining burn time.

**Why this priority**: This is explicitly specified behaviour and makes the burn mechanic strategically interesting in multi-enemy rooms.

**Independent Test**: With the relic held, apply burn to an enemy (2s duration). At t=1.5s, fire a second missile at the same enemy. Confirm burn continues past t=2s and is still ticking at t=3s and t=4s.

**Acceptance Scenarios**:

1. **Given** an enemy has an active 2s burn with 1s remaining, **When** a magic missile hits it, **Then** the burn duration becomes 1s + 2s = 3s from that moment.
2. **Given** an enemy has an active burn, **When** two missiles hit it in quick succession, **Then** each hit adds 2s independently — two hits total = 4s extension on top of any remaining duration.
3. **Given** an enemy has no active burn (burn has expired), **When** a missile hits it, **Then** a fresh 2s burn is applied (not an extension of nothing).

---

### User Story 3 - Burn Damage Scales with Attack Damage (Priority: P2)

The burn tick damage is a configurable fraction of the player's attack damage, stored in data config so it can be tuned without code changes. The total burn damage over the base 2-second duration is 20% of attack damage — meaning each tick deals 10% (20% ÷ 2 ticks). Default `burn_damage_per_tick: 0.10`.

**Why this priority**: Establishes the power level of the feature and ensures the value is data-driven per the project constitution.

**Independent Test**: Set the burn damage fraction to a known value in config. Fire a missile dealing known damage. Confirm each burn tick deals exactly `attack_damage × burn_damage_fraction`.

**Acceptance Scenarios**:

1. **Given** `burn_damage_per_tick` is `0.10` in config and the missile deals 50 damage, **When** the burn ticks, **Then** each tick deals 5 damage (50 × 0.10), for a total burn damage of 10 (20% of 50) over the base 2-second duration.
2. **Given** `burn_damage_per_tick` is updated in config, **When** the game is run, **Then** burn tick damage reflects the new value without any code change.
3. **Given** the player's attack damage is boosted by relics during a run, **When** a burn is applied, **Then** the tick damage reflects the attack damage value at the time the burn was applied.

---

### Edge Cases

- What happens if the enemy dies from a burn tick? → Enemy dies normally; no further ticks occur.
- What if burn is applied to an enemy that is already at 1 HP? → Burn applies; if the first tick kills it, no further ticks.
- Can burn be extended beyond the initial duration by multiple rapid hits? → Yes, each hit adds +2s with no cap.
- Does burn damage count toward the player's kill credit (for essence drops)? → Yes — the enemy is killed by a player-sourced effect; normal kill logic applies.
- Does the chain relic (053) apply burn to the chained target as well? → [Out of scope for this feature; default: yes if the chained hit counts as a "missile hit", but this interaction is deferred.]

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST include a new relic entry `burn` in `data/relics.json` with `name: "Living Ember"`, `tier: "uncommon"`, `effect_stat: ""`, `effect_mult: 1.0`, and appropriate `tags` and `description` fields.
- **FR-002a**: A magic missile hit MUST apply or extend a burn status effect on the target enemy **only if** the player currently holds the `burn` relic. Without the relic, missile behaviour is unchanged.
- **FR-002**: When burn is active, it MUST deal damage to the affected enemy once per second for the duration of the burn.
- **FR-003**: The base burn duration MUST be 2 seconds (configurable in `data/skills.json` under the `magic_missile` entry as `burn_duration: 2.0`).
- **FR-004**: Each additional magic missile hit on an already-burning enemy MUST extend the remaining burn duration by 2 seconds (configurable as `burn_extend_seconds: 2.0` in `data/skills.json`).
- **FR-005**: The damage dealt per burn tick MUST equal `attack_damage_at_application × burn_damage_per_tick`, where `burn_damage_per_tick` is stored in `data/skills.json`. Default value: `0.10` (10% per tick × 2 ticks = 20% total damage over base duration).
- **FR-006**: The burn damage value (`attack_damage_at_application`) MUST be captured at the time the burn is first applied; subsequent stat changes during the burn duration do NOT alter the ticking damage.
- **FR-007**: When a burn-extended enemy already has an active burn, the new hit MUST add `burn_extend_seconds` to the current remaining duration rather than resetting to `burn_duration`.
- **FR-008**: Burn ticks MUST NOT occur after the enemy dies; if an enemy is dead when a tick would fire, the tick is skipped.
- **FR-009**: All burn parameters (`burn_duration`, `burn_extend_seconds`, `burn_damage_per_tick`) MUST be stored in `data/skills.json` under the `magic_missile` entry and read at runtime — no hardcoded values in script.
- **FR-010**: The burn tick and timing logic MUST be implemented as a self-contained, pure-logic object (`BurnEffect`) with no scene-tree or autoload dependencies, so that its behaviour can be fully verified by automated unit tests.

### Key Entities

- **burn relic** (display name: "Living Ember"): Uncommon relic. No stat multiplier (`effect_stat: ""`). Enables burn on all magic missile hits for the duration of the run.
- **BurnEffect**: A self-contained, pure-logic object (no scene or autoload dependencies) that manages burn state for a single enemy. Holds `remaining_duration: float`, `tick_damage: float`, `seconds_until_next_tick: float`. Exposes:
  - `apply(tick_damage, duration)` — initialises or resets the burn state.
  - `extend(seconds)` — adds `seconds` to `remaining_duration`.
  - `process(delta) -> float` — advances time by `delta`; returns `tick_damage` if a tick fired this frame, `0.0` otherwise. Returns `0.0` and stops ticking once `remaining_duration` reaches zero.
  - `is_active() -> bool` — returns `true` while `remaining_duration > 0`.
- This design is a deliberate requirement so that tick timing and damage logic can be fully covered by automated unit tests without requiring a running scene.
- **burn_damage_per_tick**: Config float on the magic missile skill. Controls what fraction of attack damage each burn tick deals.
- **burn_duration**: Config float. The initial duration (in seconds) applied on first hit. Default `2.0`.
- **burn_extend_seconds**: Config float. Duration added to an existing burn on each re-hit. Default `2.0`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: With `burn` held, after a single missile hit on a living enemy, that enemy takes damage at least once more within 2 seconds without any further player action — verifiable by watching enemy HP decrease post-impact.
- **SC-002**: A second missile hit on a burning enemy results in burn damage continuing beyond the original 2-second expiry — verifiable by timing from first hit to last tick.
- **SC-003**: Changing `burn_damage_per_tick` in config produces proportionally different tick damage on the next game launch with no code change.
- **SC-004**: With no further missiles fired, burn stops ticking exactly at the configured `burn_duration` after the last hit that applied or extended it.
- **SC-005**: Enemy kill from a burn tick correctly triggers all kill-credit consequences (essence drop, kill counter increment) identically to a direct damage kill.

## Assumptions

- Burn is gated behind the **`burn` relic** — it only applies when the player holds the relic. Without it, magic missile behaviour is identical to baseline.
- `attack_damage_at_application` is the player's current computed attack damage (post-multipliers) at the moment the missile hits. It is captured once and does not change for the duration of that burn instance.
- There is no cap on burn duration — repeated hits can extend it indefinitely.
- Burn ticks at exactly 1-second intervals; the first tick fires at t = 1s after application (not immediately on hit).
- The chain hit (from the Chaining Stone relic, feature 053) is treated as a separate missile hit and also applies/extends burn on the chained target. This interaction is noted but does not need special handling — it emerges naturally if burn is applied to any enemy that takes magic missile damage.
- No visual burn effect (particle/shader) is required in this iteration; the damage application is the deliverable. Visual feedback is deferred to a future feature.
