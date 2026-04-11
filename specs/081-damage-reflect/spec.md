# Feature Specification: Damage Reflect

**Feature Branch**: `081-damage-reflect`
**Created**: 2026-03-21
**Status**: Draft
**Input**: User description: "introduce new reflect mechanic for both player and enemies. if an character has reflect (defined by "reflect_amount: x%"), the x% of damage will be dealt towards the attacker automatically on attack. for player it will be a common relic of forest domain."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Player Equips Reflect Relic (Priority: P1)

A player acquires the "Thorn Bark" relic (or equivalent forest-domain common relic) during a run. From that point forward, any enemy that deals damage to the player automatically receives a percentage of that damage back. The player can observe this reflected damage as visible numbers on enemies.

**Why this priority**: This is the primary player-facing expression of the mechanic and delivers the core gameplay value — passive retaliation that rewards survival.

**Independent Test**: Equip the reflect relic via the relic offer screen, enter combat, receive a hit from any enemy, and confirm the enemy takes reflected damage equal to the configured percentage.

**Acceptance Scenarios**:

1. **Given** the player holds the reflect relic, **When** an enemy deals 20 damage and reflect is 15%, **Then** that enemy immediately receives 3 damage.
2. **Given** the player holds the reflect relic, **When** reflected damage would kill the enemy, **Then** the enemy dies from the reflected damage.
3. **Given** the player does NOT hold the reflect relic, **When** an enemy deals damage, **Then** no reflected damage occurs.

---

### User Story 2 - Enemy Has Reflect Stat (Priority: P2)

The player attacks an enemy that has `reflect_amount` defined in its data. The player's projectile or melee hit deals damage to the enemy, and simultaneously the player receives a portion of that damage back. This creates a risk/reward decision for the player when engaging reflect-capable enemies.

**Why this priority**: Enemy reflect adds strategic depth and variety to combat encounters, but the mechanic must be established for the player first (P1) before enemies can leverage it symmetrically.

**Independent Test**: Spawn a reflect-capable enemy, attack it, and confirm the player receives reflected damage proportional to the damage dealt.

**Acceptance Scenarios**:

1. **Given** an enemy has 20% reflect, **When** the player deals 50 damage to it, **Then** the player receives 10 damage.
2. **Given** an enemy has 20% reflect, **When** the player deals damage, **Then** the reflected damage does NOT trigger the enemy's own reflect (no infinite loop).
3. **Given** an enemy has 0% or no reflect stat, **When** the player deals damage, **Then** no reflected damage occurs.

---

### User Story 3 - Reflect Relic Available in Forest Domain Offers (Priority: P3)

The reflect relic is added to the forest domain section of the relic pool. Its `deck_count` value is set to reflect "common" frequency — a higher count means more copies in the shuffled deck and therefore a higher likelihood of appearing in any given offer draw.

**Why this priority**: Acquisition path completeness — the mechanic is only reachable if the relic can actually appear in offers at an appropriate rate.

**Independent Test**: Trigger multiple relic offer draws with the forest domain unlocked and confirm the reflect relic surfaces at a frequency consistent with its `deck_count` (more often than relics with lower counts).

**Acceptance Scenarios**:

1. **Given** the forest domain is unlocked, **When** the relic deck is built, **Then** the reflect relic is included with the number of copies equal to its `deck_count`.
2. **Given** the reflect relic is already held, **When** a relic offer generates, **Then** the reflect relic can still appear and be picked again (reflect stacks additively with each copy held).

---

### Edge Cases

- What happens when reflected damage is fractional (e.g., 15% of 7 damage)? → Round down to nearest integer (minimum 0).
- What if the attacker dies before reflected damage is applied (e.g., instant death from another source simultaneously)? → Reflected damage is silently discarded if the attacker is no longer valid.
- What if multiple reflect sources stack (e.g., player has reflect relic AND an enemy has reflect)? → Each source applies independently; reflected damage from an enemy's reflect does NOT itself trigger the player's reflect (one-level only — no chain reflection).
- What if reflected damage exceeds the attacker's remaining HP? → Normal damage death occurs.
- Does reflected damage trigger on damage-over-time effects (poison, etc.)? → No; reflect applies only to direct hit events.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Characters (player and enemies) MUST support a `reflect_amount` property expressed as a percentage (0–100).
- **FR-002**: When a character with `reflect_amount > 0` receives a direct hit, the system MUST automatically deal `floor(incoming_damage × reflect_amount)` damage back to the attacker.
- **FR-003**: Reflected damage MUST NOT itself trigger further reflect chains (one-level only).
- **FR-004**: Reflected damage MUST NOT trigger on damage-over-time (poison, burn) or environmental damage — only on direct attack hits.
- **FR-005**: A "Thorn Bark" relic (forest domain) MUST be added to `relics.json` under the `forest` domain key, with a `deck_count` value that places multiple copies in the shuffled deck (common frequency). It MUST NOT be excluded from future offers when already held — picking it again stacks its reflect additively.
- **FR-006**: Enemies MUST support a `reflect_amount` field in enemy data; it defaults to 0 (no reflect) when absent.
- **FR-007**: Reflected damage MUST be applied immediately at the moment the hit resolves, before any further game logic for that frame.
- **FR-008**: Reflected damage MUST use the same damage application path as normal damage (respecting damage reduction, invincibility frames, etc. on the attacker).

### Key Entities

- **Reflect Amount**: A percentage value (0–100) on a character indicating what fraction of received direct-hit damage is returned to the attacker. Stored as a float/int on the character's stat or relic effect.
- **Thorn Bark Relic**: A forest-domain relic granting the player a fixed `reflect_amount`. One entry in `relics.json` under the `forest` domain key, with a `deck_count` of 2 or more (common frequency) and `effect_stat: "reflect_amount"`.
- **Hit Event**: The moment a direct attack resolves and deals damage. The reflect check occurs at this point.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player with the reflect relic receives a hit and the attacking enemy takes reflected damage within the same hit frame — verifiable by inspecting enemy HP delta immediately after the player is hit.
- **SC-002**: An enemy with `reflect_amount` defined causes the player to lose HP equal to `floor(damage_dealt × reflect_amount)` on every direct hit — verifiable across 10 consecutive attacks with consistent results.
- **SC-003**: Reflect never produces an infinite damage loop — no game freeze or runaway damage escalation occurs when both player and enemy have reflect simultaneously.
- **SC-004**: The Thorn Bark relic's `deck_count` is higher than rare relics, making it statistically more likely to appear per offer draw — verifiable by comparing copy counts in the built deck.
- **SC-005**: Reflect produces zero effect on poison tick damage — enemy/player HP does not change from reflect during DoT-only damage application.

## Assumptions

- Reflect percentage for the Thorn Bark relic will be tuned by design (placeholder: 15%). This can be adjusted in JSON without code changes.
- "Direct hit" is defined as any damage event dispatched through the existing `take_damage()` / hit-resolution path, excluding periodic/DoT application.
- Reflected damage bypasses the target's invincibility frames on the attacker? — Assumed NO: standard damage rules apply (so a player with i-frames after a dodge will not receive reflected damage during that window).
- Multiple copies of the Thorn Bark relic stack additively (e.g., two copies at 15% each = 30% total reflect). This uses the existing `compute_stat_addend` / additive relic stacking path.
