# Feature Specification: Melee Charge Relic

**Feature Branch**: `069-melee-charge-relic`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "add common relic that gives every 3 melee attacks give an extra missile charge"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Relic Grants Charge on Third Melee Hit (Priority: P1)

The player collects the new common relic from a post-clear offer screen. From that point in the run, every 3rd melee attack they land grants an extra Magic Missile charge (up to the maximum charge capacity). The player can see their charge pip count increase after hitting the 3-attack threshold.

**Why this priority**: This is the core game loop of the relic — the melee-to-missile synergy is the entire value of the feature.

**Independent Test**: Can be fully tested in a single run by acquiring the relic, performing exactly 3 melee attacks, and verifying that one extra missile charge is added.

**Acceptance Scenarios**:

1. **Given** the relic is active, **When** the player lands their 1st or 2nd melee attack, **Then** no extra charge is granted.
2. **Given** the relic is active, **When** the player lands their 3rd melee attack, **Then** one extra Magic Missile charge is added and the melee counter resets to 0.
3. **Given** the relic is active, **When** the player lands their 6th melee attack (two full cycles), **Then** two extra charges have been granted in total (one per cycle).
4. **Given** the relic is active and Magic Missile is already at maximum charge, **When** the 3rd melee attack lands, **Then** no charge is added (cannot exceed maximum capacity).

---

### User Story 2 - Relic Appears in Offer Pool as Common (Priority: P1)

The new relic is available in the standard post-clear offer pool at common rarity. A player who does not yet hold it may be offered it as one of the offer screen choices.

**Why this priority**: If the relic cannot appear in offers, it can never be collected — the feature would be unreachable.

**Independent Test**: Can be verified by inspecting the relic pool data and confirming the new entry has tier "common" and is drawn correctly in offer screens.

**Acceptance Scenarios**:

1. **Given** the player clears a room and the offer screen triggers, **When** the relic pool is sampled, **Then** the new relic is a valid candidate alongside other common relics.
2. **Given** the player already holds this relic, **When** the offer pool is sampled, **Then** this relic is excluded (standard duplicate-exclusion rule applies).

---

### User Story 3 - Counter Resets at Run End (Priority: P2)

When a run ends (by death or cash-out), the melee attack counter for this relic resets. Starting a new run with the relic re-acquired begins the counter fresh at 0.

**Why this priority**: Correct counter isolation between runs is required for consistent game behaviour.

**Independent Test**: Can be tested by verifying counter state is 0 at the start of a new run even when the relic was active in the previous run.

**Acceptance Scenarios**:

1. **Given** the player ends a run with the relic active and the counter at 1 or 2, **When** a new run begins and the relic is re-acquired, **Then** the counter starts at 0.

---

### Edge Cases

- What if the player has 0 missile charges and gains one from the relic — does it immediately become available? Yes, the charge should be usable immediately.
- What happens if the player holds two copies of this relic? The relic pool already excludes duplicates (unique per run), so this cannot occur.
- What counts as a "melee attack"? The base melee swing (auto-attack) — not projectile hits or skill activations.
- What if missile charges are already full when the 3rd melee lands? The extra charge is lost (cannot overflow maximum capacity).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A new common-tier relic MUST be added to the relic data pool with the effect: every 3rd melee attack grants +1 Magic Missile charge.
- **FR-002**: The game MUST track a per-run melee attack counter for this relic, incrementing by 1 on each melee attack landed.
- **FR-003**: When the melee counter reaches 3, the game MUST grant +1 Magic Missile charge and reset the counter to 0.
- **FR-004**: The granted charge MUST NOT exceed the current maximum charge capacity of Magic Missile.
- **FR-005**: The melee counter MUST reset to 0 when the relic is first applied (acquired) in a run.
- **FR-006**: The melee counter MUST NOT carry over between runs.
- **FR-007**: The relic MUST be excluded from offer pools when the player already holds it in the current run (standard duplicate-exclusion rule).
- **FR-008**: The relic MUST be offered only from standard post-clear offer screens (not boss-exclusive rare-only offers).

### Key Entities

- **Relic — Melee Charge Trigger**: Common-tier relic entry in `data/relics.json`. Fields: `id`, `name`, `tier: "common"`, `tags`, `effect_stat: ""`, `effect_mult: 1.0`, `description`. Logic is conditional (not a simple stat multiplier), so `effect_stat` is empty analogous to `executioners_mark` and `berserker_stone`.
- **Melee Attack Counter**: A per-run integer counter, owned by `RelicManagerImpl` or a dedicated handler. Tracks how many melee attacks have landed since the last cycle completion. Resets on relic acquisition and on run end.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Performing exactly 3 melee attacks while the relic is active always results in exactly 1 additional missile charge appearing in the HUD.
- **SC-002**: The relic appears correctly in the standard offer pool and is never offered twice in the same run.
- **SC-003**: The melee counter is 0 at the start of every relic application — no state bleeds between runs or between offer-and-pick cycles.
- **SC-004**: When missile charges are already full, the 3rd melee hit does not grant a charge and the HUD charge count remains unchanged.

## Assumptions

- "Melee attack" means the player's base auto-attack melee swing, as implemented in `CombatComponent`. Projectile hits and skill activations do not count.
- The relic tracks hits landed (attack connects), not swings attempted (attack button pressed). If the melee attack misses or is blocked, it does not increment the counter. (Assumption — simplify to swing-based if hit detection is unavailable.)
- The charge grant adds to the current charge count, capped at maximum — the same `add_charge()` API used elsewhere.
- Relic cost/unlock follows the standard relic system (no additional meta gate required for a common relic).
- Shard cost to add via meta unlock is covered by the existing relic system gate (`relic_offers_active`).
