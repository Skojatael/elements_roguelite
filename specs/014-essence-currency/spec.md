# Feature Specification: Essence Currency

**Feature Branch**: `014-essence-currency`
**Created**: 2026-02-28
**Status**: Draft
**Input**: User description: "implement run currency called 'essence'. it should be recieved when killing enemies. the amount of currency recieved should depend on enemy type (expand each enemy in enemies.json so it has base_essence parameter) and depth (depth_multiplier: 1 + 0.10 * depth). after run_ends, currency is cashed out (for now, print message '* essence cashed out'), if run_ends with reason died, 0.85*currency is cashed out"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Earning Essence by Killing Enemies (Priority: P1)

When the player kills an enemy during a run, they receive a quantity of essence determined by the enemy's base value and the depth of the room where the kill occurred. Deeper rooms yield more essence per kill, rewarding exploration.

**Why this priority**: Earning is the foundation of the currency system. Without it, cashing out has nothing to work with. All other currency features depend on this.

**Independent Test**: Start a run, enter a combat room, kill an enemy. Confirm the run's essence total increases by the correct amount (enemy base_essence × depth multiplier). Kill multiple enemies; confirm each adds the correct amount individually.

**Acceptance Scenarios**:

1. **Given** a run is active and the player is in a room at depth 1, **When** the player kills a slime (base_essence = 10), **Then** the run's essence total increases by `floor(10 × (1 + 0.10 × (1 − 1))) = 10`.
2. **Given** a run is active and the player is in a room at depth 3, **When** the player kills a skeleton (base_essence = 15), **Then** the run's essence total increases by `floor(15 × (1 + 0.10 × (3 − 1))) = floor(18) = 18`.
3. **Given** the player kills two enemies in the same room, **Then** each kill adds its own individual amount (amounts are additive, not averaged).
4. **Given** no run is active, **When** an enemy dies, **Then** no essence is awarded.

---

### User Story 2 - Cashing Out Essence at Run End (Priority: P1)

When a run ends, the player's accumulated essence is cashed out. If the run ended by completing it (cash out), the full amount is awarded. If the player died, a penalty applies and only 85% of the accumulated essence is awarded. A confirmation message records the transaction.

**Why this priority**: Cashing out is the payoff moment that gives earning its meaning. Together with US1, this forms the complete MVP of the currency loop.

**Independent Test**: Complete a run via cash-out — confirm the full essence total is cashed out and the message shows the correct amount. Start a second run, kill enemies, die — confirm 85% of the accumulated essence is cashed out and the message reflects the reduced amount.

**Acceptance Scenarios**:

1. **Given** a run ends with reason CASH_OUT and the player accumulated 100 essence, **Then** 100 essence is cashed out and the confirmation message shows 100.
2. **Given** a run ends with reason DIED and the player accumulated 100 essence, **Then** `floor(100 × 0.85) = 85` essence is cashed out and the confirmation message shows 85.
3. **Given** a run ends with 0 essence accumulated, **Then** 0 is cashed out and the message still fires (showing 0).
4. **Given** a run ends, **Then** the cash-out message is always printed regardless of amount or end reason.

---

### Edge Cases

- What if an enemy has no `base_essence` defined in config? Award 0 essence for that kill; do not crash.
- What if the room's depth is 0 (start room)? Multiplier is `1 + 0.10 × (0 − 1) = 0.9` — a 10% reduction. Start room has no enemies by design, so this case never occurs in practice.
- What if `start_run()` is called while a run is already active (dev re-run)? Essence resets to 0, same as all other run state.
- What if the player accumulates fractional essence (e.g., 2.2 + 3.9 = 6.1)? The running total is stored as a decimal; cash-out amount is floored to the nearest whole number before printing.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each enemy type in the enemy configuration MUST have a `base_essence` numeric value that defines how much essence that enemy is worth at depth 1.
- **FR-002**: When an enemy is killed during an active run, the system MUST award `floor(base_essence × (1 + 0.10 × (depth − 1)))` essence to the run total, where `depth` is the depth of the room in which the kill occurred. At depth 1 the full base amount is awarded; each additional depth step adds 10%.
- **FR-003**: Essence MUST NOT be awarded when no run is active.
- **FR-004**: When a run ends with reason CASH_OUT, the system MUST cash out `floor(run_essence)` essence.
- **FR-005**: When a run ends with reason DIED, the system MUST cash out `floor(run_currency × 0.85)` essence, floored (rounded down) to guarantee an integer result.
- **FR-006**: On cash-out, the system MUST print a confirmation message of the form `"[Essence] X essence cashed out"` (where X is the final cashed-out amount).
- **FR-007**: The run's essence total MUST reset to 0 at the start of each new run.
- **FR-008**: If an enemy's `base_essence` is missing or zero, the kill MUST award 0 essence without error.

### Key Entities

- **Essence**: The in-run currency. Accumulated as a decimal during a run; expressed as a whole number on cash-out. Scoped to a single run — not persisted between runs in this iteration.
- **Enemy base_essence**: A per-enemy-type configuration value (numeric) stored alongside other enemy stats. Determines the base earn rate for killing that enemy type.
- **Depth multiplier**: A scalar derived from the room's grid depth (`1 + 0.10 × (depth − 1)`). Applied at the point of kill, not stored separately. Depth 1 yields a multiplier of 1.0 (no bonus); each additional depth step adds 10%.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every enemy kill during an active run produces a non-negative essence gain that matches the formula `floor(base_essence × (1 + 0.10 × (depth − 1)))` with 100% accuracy.
- **SC-002**: Cash-out amount at run end is always correct: 100% of accumulated essence for CASH_OUT, 85% (floored) for DIED — verifiable by manual run.
- **SC-003**: The cash-out confirmation message is printed on every run end without exception.
- **SC-004**: No run-end path (DIED or CASH_OUT) silently drops essence or skips the message.

## Assumptions

- `base_essence` values for the two current enemy types: slime = 10, skeleton = 15. These are sized so that the 10%-per-depth bonus produces a visible integer difference from depth 2 onwards.
- Essence is floored per-kill (not accumulated as a decimal). Each kill awards `floor(base_essence × multiplier)` as a whole number.
- "Cashed out" in this iteration means logging a message only — no persistent wallet or meta-progression storage.
- Room depth is already available from the dungeon layout data; the system that awards essence has access to it.

## Out of Scope

- Persistent essence wallet or carry-over between runs (meta-progression — future feature).
- Spending essence (shop, upgrades) — future feature.
- Visual feedback (floating numbers, HUD counter) — future feature.
- Per-run essence history or breakdown — future feature.
