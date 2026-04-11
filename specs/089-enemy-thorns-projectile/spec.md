# Feature Specification: Enemy Thorns Projectile

**Feature Branch**: `089-enemy-thorns-projectile`
**Created**: 2026-03-29
**Status**: Draft
**Input**: User description: "rework reflect mechanic on enemies. instead of reflecting damage, make enemy fire projectiles ('thorns') on hit. for regular enemies, make it four static directions (SE,SW,NE,NW) from the enemy, travelling in straight line. for forest boss thorns, make it six directions (+N,S). all stats should be data-driven"

---

## Overview

Replace the existing `reflect_amount` damage-reflect mechanic on enemies with a projectile-based thorns system. When an enemy with the thorns trait is hit, it fires thorn projectiles outward in fixed directions instead of reflecting damage fractions back to the attacker. Regular enemies fire in four diagonal directions (NE, NW, SE, SW); the forest boss fires in six directions (adding N and S). All projectile behaviour values are data-driven in `enemies.json`.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Regular Enemy Fires Thorns on Hit (Priority: P1)

A regular enemy (e.g. a forest common enemy) has the thorns trait configured in its data. When the player's projectile or melee strike connects with this enemy, four thorn projectiles immediately burst out in the diagonal directions (NE, NW, SE, SW) from the enemy's position. Each thorn travels in a straight line and damages the player if it makes contact.

**Why this priority**: This is the core mechanic change — the player-visible behaviour that replaces reflect. Everything else builds on this foundation.

**Independent Test**: Spawn a thorns-capable enemy, fire one attack at it, and confirm four thorn projectiles appear at the enemy position travelling diagonally. Confirm each thorn deals the configured damage if the player is in its path.

**Acceptance Scenarios**:

1. **Given** an enemy has thorns configured, **When** the player deals damage to it, **Then** four thorn projectiles spawn at the enemy's position heading NE, NW, SE, SW.
2. **Given** a thorn projectile is in flight, **When** it contacts the player, **Then** the player takes the configured thorn damage.
3. **Given** a thorn projectile is in flight, **When** it travels past the player without contact, **Then** no damage occurs and the projectile despawns after its max range.
4. **Given** an enemy does NOT have thorns configured, **When** the player attacks it, **Then** no thorn projectiles are spawned.

---

### User Story 2 — Forest Boss Fires Six-Direction Thorns During Thorns Window (Priority: P2)

During the forest boss's THORNS_ACTIVE phase windows (Phases 2 and 3), when the player's attack connects with the boss, it fires thorn projectiles in six directions (NE, NW, SE, SW, N, S) instead of reflecting damage. The increased direction count compared to regular enemies makes the boss more dangerous to engage during this window.

**Why this priority**: Builds on P1; the six-direction variant depends on the core system being established first.

**Independent Test**: Fight the forest boss until Phase 2 activates, trigger THORNS_ACTIVE, then attack the boss and confirm six thorn projectiles spawn — two additional (N and S) compared to regular enemies.

**Acceptance Scenarios**:

1. **Given** the forest boss is in THORNS_ACTIVE, **When** the player attacks it, **Then** six thorn projectiles spawn heading NE, NW, SE, SW, N, S.
2. **Given** the forest boss is NOT in THORNS_ACTIVE, **When** the player attacks it, **Then** no thorn projectiles spawn (no thorns outside the active window).
3. **Given** the forest boss is in Phase 3 THORNS_ACTIVE, **When** the player attacks it, **Then** thorn projectile damage uses the Phase 3 value from data (same direction count, possibly higher damage).

---

### User Story 3 — Reflect Mechanic Removed from Enemies (Priority: P3)

The old `reflect_amount`-based damage-reflect pathway no longer applies to enemies. Enemies that previously had `reflect_amount` values now use the thorns projectile system instead. No enemy causes direct reflected damage to the player.

**Why this priority**: Cleanup/consistency requirement — ensures the old and new systems do not coexist and conflict.

**Independent Test**: Attack a thorns-capable enemy 10 times and confirm the player only loses HP by being struck by thorn projectiles, never by an instantaneous reflect event.

**Acceptance Scenarios**:

1. **Given** an enemy had `reflect_amount` in data before this feature, **When** the player attacks it after the rework, **Then** no instantaneous HP loss occurs on the player from reflect.
2. **Given** the game has no enemies with `reflect_amount > 0`, **When** any combat occurs, **Then** the `reflect_amount` code path is never triggered for enemies.

---

### Edge Cases

- What happens when the player is at the exact enemy position when thorns fire? → Thorns spawn at enemy position and travel outward; the player takes damage if their hitbox overlaps at spawn (normal collision rules apply).
- What if the enemy is killed by the same hit that would trigger thorns? → No thorns fire; the enemy is already dead when the hit resolves.
- What if thorns fire into a wall immediately? → Thorn projectiles despawn on wall contact (same behaviour as other projectiles in the game).
- What if the enemy takes multiple rapid hits? → Each hit triggers a thorn burst independently; a per-enemy fire-rate cooldown (data-driven) prevents excessive projectile spam.
- What if the player has i-frames from a dodge? → Thorn projectiles cannot damage the player during active i-frames (standard dodge immunity applies).
- Does the player's Thorn Bark relic (081 — player reflect) change? → No; the rework is enemy-only. The player relic is out of scope.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Enemies MUST support a boolean flag (e.g. `thorns_on_hit: bool`) in their data; when `false` or absent, no thorn projectiles are fired.
- **FR-002**: When a thorns-enabled enemy is hit, the system MUST spawn thorn projectiles at the enemy's world position in each configured direction.
- **FR-003**: Regular thorns-capable enemies MUST fire in exactly four diagonal directions: NE (45°), NW (135°), SW (225°), SE (315°).
- **FR-004**: The forest boss thorns variant MUST fire in exactly six directions: N (0°/360°), NE (45°), SE (315°), S (180°), SW (225°), NW (135°).
- **FR-005**: The number of directions MUST be data-driven — stored per enemy type in `enemies.json` as a list or count that maps to the correct direction set.
- **FR-006**: Thorn projectile speed MUST be data-driven (`thorns_speed`) per enemy type.
- **FR-007**: Thorn projectile damage MUST be data-driven (`thorns_damage`) per enemy type. The forest boss MAY define phase-specific damage values (`thorns_damage_p2`, `thorns_damage_p3`).
- **FR-008**: Thorn projectiles MUST despawn on player contact (dealing damage) or on reaching a maximum travel distance (`thorns_range`, data-driven).
- **FR-009**: A per-enemy fire-rate cooldown (`thorns_fire_cooldown`, data-driven) MUST prevent multiple thorn bursts within the cooldown window, even if the enemy is hit multiple times rapidly.
- **FR-010**: Thorn projectiles MUST NOT deal damage to other enemies — they only damage the player.
- **FR-011**: The `reflect_amount` mechanic MUST be removed or bypassed for all enemies (existing enemy data entries with `reflect_amount` are migrated to the thorns system or the field is zeroed out).
- **FR-012**: For the forest boss, thorn projectiles MUST only fire during the THORNS_ACTIVE state; outside this window, hits do not spawn thorns regardless of the enemy's `thorns_on_hit` flag.

### Key Entities

- **Thorn Projectile**: A short-lived projectile spawned at an enemy's position on hit. Travels in a straight line at fixed speed, deals a fixed damage amount to the player on contact, and despawns on contact or at max range. Defined by: speed, damage, range, direction angle.
- **Thorns Config** (per enemy): Data fields stored in `enemies.json` defining whether thorns are active, how many directions, the direction set, projectile damage, speed, range, and fire-rate cooldown.
- **Thorns Active Window** (forest boss only): The THORNS_ACTIVE state from spec 088. Thorn projectile firing is gated to this window for the boss; outside it the boss fires no thorns.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Hitting a thorns-capable regular enemy always produces exactly four projectile instances heading in the four diagonal directions — verifiable by counting spawned nodes per hit in test conditions.
- **SC-002**: Hitting the forest boss during THORNS_ACTIVE produces exactly six projectile instances — verifiable by counting spawned nodes per hit.
- **SC-003**: Each thorn projectile deals the configured `thorns_damage` value to the player on contact — verifiable against the data value over 10 consecutive contacts.
- **SC-004**: No enemy causes instantaneous (reflect-style) damage to the player — verifiable by confirming player HP only changes when a thorn projectile physically connects.
- **SC-005**: Rapid hits on a thorns enemy within the `thorns_fire_cooldown` window produce only one thorn burst, not multiple — verifiable by firing at double the cooldown rate and observing burst frequency.
- **SC-006**: All thorn numeric values (damage, speed, range, cooldown) can be changed in `enemies.json` with no code modifications, and the in-game behaviour changes accordingly.

---

## Assumptions

- A1: The direction set for each enemy type is encoded in `enemies.json` as an integer count (`thorns_directions: 4` or `6`) rather than explicit angle lists; the code maps 4 → diagonal set and 6 → diagonal + cardinal set. If a different encoding is preferred, this can be clarified before planning.
- A2: The existing `Projectile.gd` / thorn projectile scene from spec 083 (enemy ranged attack) is reused or a minimal variant is created — no new general projectile system is needed.
- A3: The forest boss thorn firing is integrated into `ForestBossThorns.gd` (spec 088); no changes to `Enemy.gd` are required for the boss.
- A4: Regular thorns-capable enemies' thorn firing logic is added to `Enemy.gd` (or a small helper), gated by `thorns_on_hit`.
- A5: Thorn projectiles do not interact with the relic system (no relic currently modifies incoming projectile damage type).
- A6: The player's Thorn Bark relic (`reflect_amount` on the player side) is unchanged by this feature — player reflect is out of scope.

---

## Out of Scope

- Changes to the player's Thorn Bark relic or the player-side reflect mechanic.
- Animated thorn projectile sprites — placeholder visuals (ColorRect or existing projectile assets) are acceptable.
- Thorn projectiles affecting enemy AI behaviour (they do not interact with enemies).
- Directional variation beyond the two defined sets (4-diagonal, 6-cardinal+diagonal).
