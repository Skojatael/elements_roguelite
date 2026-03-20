# Feature Specification: Root Mechanic

**Feature Branch**: `072-root-mechanic`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "add root relic (uncommon, data-driven, placeholder values: duration 0.6 seconds, chance of root: 20%) and root logic to enemies."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Enemy Roots Player on Melee Hit (Priority: P1)

Certain enemies carry a root ability. When one of these enemies lands a melee hit on the player, the player is briefly prevented from moving. This adds tactical depth: rooted players must avoid those enemies or endure the lockout.

**Why this priority**: Core deliverable of the mechanic — without this, root as a status effect doesn't exist in the game.

**Independent Test**: Spawn a root-capable enemy, let it hit the player, and verify the player cannot move for the configured duration then regains movement automatically.

**Acceptance Scenarios**:

1. **Given** an enemy with `root_duration > 0` in its data, **When** it lands a melee hit on the player, **Then** the player cannot move for exactly `root_duration` seconds.
2. **Given** the player is rooted, **When** `root_duration` seconds elapse, **Then** the player regains full movement automatically with no input required.
3. **Given** an enemy with no `root_duration` field (or `root_duration = 0`), **When** it hits the player, **Then** the player is NOT rooted.

---

### User Story 2 — Player Roots Enemies via Root Relic (Priority: P2)

The player can acquire a Root Relic (uncommon tier) during a run. Once held, each of the player's melee hits has a configurable percentage chance to root the struck enemy, preventing it from moving for a configurable duration. This rewards the player for holding position and maintaining melee pressure.

**Why this priority**: The relic is the player-facing expression of the mechanic; it completes the feature loop and gives the root mechanic strategic value in the player's kit.

**Independent Test**: Equip the Root Relic, land multiple melee hits on an enemy — over a sufficient sample the enemy is visibly frozen approximately 20% of the time for approximately 0.6 s per activation.

**Acceptance Scenarios**:

1. **Given** the player holds the Root Relic, **When** a melee hit lands on an enemy, **Then** the enemy has a 20% chance of being rooted for 0.6 seconds (placeholder values; governed by relic data).
2. **Given** an enemy is rooted, **When** the root duration elapses, **Then** the enemy resumes normal movement with no player input required.
3. **Given** the player does NOT hold the Root Relic, **When** melee hits land, **Then** no root is ever applied to enemies (zero false positives).
4. **Given** relic data specifies `root_chance` and `root_duration`, **When** the relic is loaded, **Then** the game uses those values rather than any hardcoded constants.

---

### User Story 3 — Root Stacks/Refresh Behaviour (Priority: P3)

If a root is applied while the target (player or enemy) is already rooted, the outcome must be predictable and consistent: the remaining duration refreshes to whichever is longer — no stacking, no infinite extension.

**Why this priority**: Edge case that must be decided before implementation to avoid inconsistent feel.

**Independent Test**: Root a target, then apply a second root of a different duration before the first expires — verify remaining root time equals the longer of the two durations.

**Acceptance Scenarios**:

1. **Given** a target already rooted with T seconds remaining, **When** a new root of duration D is applied, **Then** the remaining root time becomes `max(T, D)` — no stacking, no infinite extension.

---

### User Story 4 — Root Prevents Dodge (Priority: P4)

Root is a hard movement lockout for the player: movement and dodge are both suppressed while rooted. Skills and attacks remain available.

**Why this priority**: Scoping decision that must be consistent from day one; doesn't block the core feature.

**Independent Test**: Root the player and attempt to dodge; verify the dodge is suppressed for the full root duration then works normally after expiry.

**Acceptance Scenarios**:

1. **Given** the player is rooted, **When** the player attempts a dodge roll, **Then** the dodge does not execute.
2. **Given** the player is rooted and `root_duration` elapses, **When** the player attempts a dodge roll, **Then** the dodge executes normally.
3. **Given** the player is rooted, **When** the player attacks or uses a skill, **Then** those actions execute normally.

---

### Edge Cases

- What happens if the player dies while rooted — does death animation/respawn behave normally?
- Can a rooted enemy still deal damage (melee contact) while frozen?
- What if `root_duration` is set to a very large value (e.g. 999)?
- What if `root_chance` is set to 1.0 (100%) — does every hit root?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Enemies MUST support an optional `root_duration` property in their data (numeric, seconds); absence or `0` means no root capability.
- **FR-002**: When a root-capable enemy lands a melee hit on the player, the game MUST apply a root status to the player for `root_duration` seconds.
- **FR-003**: While the player is rooted, the player MUST be unable to perform directional movement.
- **FR-004**: Root MUST expire automatically after the configured duration, restoring full movement with no player input.
- **FR-005**: If a root is applied while the target is already rooted, the remaining duration MUST be set to `max(current_remaining, new_duration)` — refresh-to-longest; no stacking.
- **FR-006**: Root MUST NOT prevent the player from attacking or using skills while active.
- **FR-007**: Root MUST prevent the player from dodging/rolling for the full root duration.
- **FR-008**: Enemies without `root_duration` (or with value `0`) MUST NOT apply root to the player.
- **FR-009**: The Root Relic MUST be an uncommon-tier relic available via the standard relic offer system.
- **FR-010**: The Root Relic's `root_chance` and `root_duration` values MUST be defined in relic data, not hardcoded. Placeholder values: `root_chance = 0.20`, `root_duration = 0.6` s.
- **FR-011**: When the player holds the Root Relic and a melee hit lands on an enemy, the game MUST perform a probability check using `root_chance` and, on success, apply a root of `root_duration` seconds to the struck enemy.
- **FR-012**: Enemies hit by the player's root MUST be unable to move for the root duration, then resume normal movement automatically.
- **FR-013**: The root mechanic (status state + duration logic) MUST be shared between enemy-roots-player and player-roots-enemy paths — no duplicate root timer logic.

### Key Entities

- **Root Status**: A timed active state on a combatant (player or enemy) that suppresses movement for a configurable duration. Duration is set per-application; the status auto-expires. Refresh-to-longest on reapplication.
- **Root Source (Enemy)**: An enemy with `root_duration > 0` in its data — applies root to the player on melee contact.
- **Root Relic**: An uncommon relic collectible during a run. Grants the player's melee hits a `root_chance` probability of applying a root of `root_duration` seconds to any struck enemy.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every enemy with `root_duration > 0` in its data roots the player on a successful melee hit — zero exceptions across all such enemy types.
- **SC-002**: Root expires within ±100 ms of the configured `root_duration` (no lingering or premature release) — verified for both player and enemy targets.
- **SC-003**: Player can continue attacking and using skills during root — verified for all active skills.
- **SC-004**: Enemies without `root_duration` (or with value 0) produce zero root events in 50 consecutive hits — no false positives.
- **SC-005**: Applying a second root while rooted produces a single uninterrupted root period equal to the longer duration — no double-trigger or timer reset anomalies.
- **SC-006**: The Root Relic applies root to enemies at a rate consistent with the configured `root_chance` (±5% variance over 100 hits).
- **SC-007**: Without the Root Relic equipped, no root is ever applied to enemies — zero false positives in 100 melee hits.
- **SC-008**: All relic parameters (`root_chance`, `root_duration`) are read from relic data — changing the data values changes in-game behaviour with no code modification.

## Assumptions

- Root suppresses movement only; skills, attacks, and other interactions are unaffected for both player and enemy targets.
- `root_duration` and `root_chance` are floating-point values authored in data files.
- Enemies rooted by the player cannot move but may still deal damage if the player is in contact range.
- Root has no visual indicator in this iteration (visual polish deferred).
- The root mechanic is reusable: both directions (enemy-roots-player, player-roots-enemy via relic) share the same timer/status logic.
- Only existing melee-capable enemies receive `root_duration` authored in JSON; adding new enemy types is out of scope.
