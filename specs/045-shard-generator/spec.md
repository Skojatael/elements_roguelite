# Feature Specification: Alchemy Lab — Essence Condenser Upgrade

**Feature Branch**: `045-shard-generator`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "add a new upgrade in alchemy lab. tech name "shard generator", display name "essence condenser". it should add passive shard generation, with three levels being 2 shards/hour, 3 shards and 5 shards respectively. the base cost should be 600 gold, then each level cost should be multiplied by 2 (1200 and 2400 respectively)."

## Context

The Alchemy Lab already contains several purchasable upgrades (Essence Gain, Transmuter, Gold Storage). This feature adds a fourth upgrade — the **Essence Condenser** — which generates shards passively over time, giving players who invest in the Alchemy Lab a stream of meta-currency without needing to complete runs.

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Purchase First Level of Essence Condenser (Priority: P1)

A player with 600 or more gold opens the Alchemy Lab upgrade screen, sees the Essence Condenser entry with its cost and effect, and purchases level 1. Their gold is deducted and passive shard generation begins at 2 shards/hour.

**Why this priority**: The purchase path must exist before the passive benefit can be tested or valued by players.

**Independent Test**: Open the Alchemy Lab with ≥ 600 gold → Essence Condenser button shows "2 shards/hour — 600 gold" → purchase → gold reduced by 600, shards begin accumulating.

**Acceptance Scenarios**:

1. **Given** the player has ≥ 600 gold and the upgrade is at level 0, **When** they tap the purchase button, **Then** 600 gold is deducted and the upgrade moves to level 1.
2. **Given** the player has < 600 gold, **When** they view the upgrade screen, **Then** the Essence Condenser button is disabled.
3. **Given** the upgrade is at level 1, **When** the player views the screen, **Then** the button shows the level 2 cost (1200 gold) and rate (3 shards/hour).

---

### User Story 2 — Passive Shard Accumulation While Playing (Priority: P2)

A player who owns at least level 1 of the Essence Condenser sees their shard balance grow over time at the configured rate, mirroring how the gold Transmuter works for gold.

**Why this priority**: The passive reward is the core value proposition of the upgrade — without it the purchase is meaningless.

**Independent Test**: Own level 1, wait or simulate time passing, verify shards increase at 2/hour (e.g. after 30 minutes, +1 shard).

**Acceptance Scenarios**:

1. **Given** the upgrade is at level 1 (2 shards/hour), **When** one hour of real time passes, **Then** the player's shard balance increases by exactly 2.
2. **Given** the upgrade is at level 2 (3 shards/hour), **When** one hour passes, **Then** shards increase by 3.
3. **Given** the upgrade is at level 3 (5 shards/hour), **When** one hour passes, **Then** shards increase by 5.
4. **Given** the upgrade is at level 0 (not purchased), **When** any amount of time passes, **Then** no passive shard income accrues.

---

### User Story 3 — Offline Shard Accumulation (Priority: P3)

A player who owns the Essence Condenser closes the game and reopens it later. Shards accumulated while offline are credited on startup, subject to the same storage cap logic used by the gold generator.

**Why this priority**: Offline progression is a key engagement loop for idle/meta systems. Without it the upgrade loses most of its long-term value.

**Independent Test**: Own level 1, close the game, reopen after a known duration, verify shards credited match `floor(rate × elapsed_hours)` up to cap.

**Acceptance Scenarios**:

1. **Given** the upgrade is at level 2 (3 shards/hour) and the game is closed for 2 hours, **When** the game reopens, **Then** 6 shards are added to the balance on startup.
2. **Given** offline time exceeds the Gold Storage cap, **When** the game reopens, **Then** shards are credited only for the capped duration — the same cap that limits offline gold accumulation.

---

### User Story 4 — Upgrade to Level 2 and Level 3 (Priority: P4)

A player who has already purchased level 1 can continue purchasing levels 2 and 3, each deducting the correct gold cost and increasing the shard rate.

**Why this priority**: Multi-level progression is the stated design; without it only a single-level stub exists.

**Independent Test**: Start at level 1 with ≥ 1200 gold → purchase level 2 → gold reduced by 1200, rate becomes 3/hour → with ≥ 2400 gold purchase level 3 → rate becomes 5/hour, button shows MAX.

**Acceptance Scenarios**:

1. **Given** the upgrade is at level 1 and the player has ≥ 1200 gold, **When** they purchase, **Then** gold is reduced by 1200 and the rate becomes 3 shards/hour.
2. **Given** the upgrade is at level 2 and the player has ≥ 2400 gold, **When** they purchase, **Then** gold is reduced by 2400 and the rate becomes 5 shards/hour.
3. **Given** the upgrade is at level 3 (max), **When** the player views the screen, **Then** the button shows "MAX" and cannot be pressed.

---

### User Story 5 — Persistence Across Sessions (Priority: P5)

The owned upgrade level and any partially-accumulated fractional shards survive a game restart.

**Why this priority**: Without persistence the upgrade is useless — it resets on every launch.

**Independent Test**: Purchase level 2, close the game, reopen, confirm the Alchemy Lab still shows level 2 and next cost is 2400 gold.

**Acceptance Scenarios**:

1. **Given** the upgrade is at level 2 when the game is closed, **When** the game is reopened, **Then** the Alchemy Lab shows level 2 and the next-level cost is 2400 gold.
2. **Given** the player's gold was reduced by 1200 at purchase, **When** the game restarts, **Then** that gold deduction is still reflected.

---

### Edge Cases

- What happens when the player's gold drops to exactly 600 — can they still purchase? (Yes — boundary is inclusive.)
- What if two upgrades are purchased in rapid succession from the UI before the balance is re-evaluated?
- What is the shard accumulation cap for offline credit? (Assumed: same cap mechanism as gold storage — time-based.)
- What happens if the shard rate config is missing or malformed on load?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The Alchemy Lab upgrade screen MUST display a new "Essence Condenser" entry with current level, next-level gold cost, and next-level shard rate.
- **FR-002**: The Essence Condenser MUST have exactly 3 purchasable levels.
- **FR-003**: Level costs MUST be: level 1 = 600 gold, level 2 = 1200 gold, level 3 = 2400 gold (each level doubles the previous).
- **FR-004**: All cost values and shard rates MUST be sourced from `data/meta_config.json` — no hardcoded numbers in scripts.
- **FR-005**: Shard rates per level MUST be: level 1 = 2 shards/hour, level 2 = 3 shards/hour, level 3 = 5 shards/hour.
- **FR-006**: Passive shard generation MUST tick continuously while the game is running (same mechanism as gold ticking).
- **FR-007**: Offline shard accumulation MUST be credited on game startup, capped by the same duration used for offline gold accumulation (the Gold Storage upgrade cap).
- **FR-008**: The purchase button MUST be disabled when the player's gold balance is below the next level cost.
- **FR-009**: The purchase button MUST show a "MAX" indicator and be non-interactive at level 3.
- **FR-010**: Purchasing a level MUST atomically deduct the gold cost and increment the upgrade level, with both values persisted immediately.
- **FR-011**: The `shard_generator_level` field MUST be stored in the meta save file; a missing field defaults to 0 (backward compatible).
- **FR-012**: The upgrade screen button MUST re-evaluate its enabled/disabled state whenever the player's gold balance changes while the screen is open.

### Key Entities

- **Essence Condenser Upgrade**: Tracks `shard_generator_level: int` (0–3). Generates passive shard income at a rate determined by the current level. Level 0 = no income.
- **Shard Rate Config**: Array of per-level rates (shards/hour) sourced from JSON. Index 0 = level 1 rate.
- **Meta Save**: Gains `shard_generator_level` field (new; defaults to 0 if absent).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player can purchase all 3 levels by spending exactly 600 + 1200 + 2400 = 4200 gold total, with each transaction atomic and independently verifiable.
- **SC-002**: At each owned level, the shard balance increases at the exact configured rate (2, 3, or 5 per hour) to within ±1 shard per hour due to tick timing.
- **SC-003**: The purchase button is disabled in 100% of cases where the player's gold is strictly less than the next level cost.
- **SC-004**: After a game restart, the upgrade level and gold balance match their values at close — 0 regressions across save/load cycles.
- **SC-005**: Offline shard credit on startup matches `floor(rate × elapsed_hours)` within ±1 shard for any elapsed time up to the storage cap.

## Assumptions

- Shard generation uses the same tick-and-offline-credit pattern as the gold generator (real-time delta accumulation + startup catch-up).
- The offline credit cap is the Gold Storage upgrade cap (feature 043) — both gold and shard offline accumulation are bounded by the same elapsed-time window. No separate shard cap config is needed.
- Fractional shards are accumulated internally as a float and floored when added to the shard balance, matching the gold generator's approach.
- The Essence Condenser costs **gold** (idle currency), not shards — consistent with other Alchemy Lab upgrades.
- The upgrade is available from the start once the Alchemy Lab is restored; no additional gate is required beyond lab ownership.

## Dependencies

- Feature 040 (Alchemy Lab) — building and upgrade screen already exist.
- Feature 041 (Gold idle currency) — gold must be spendable.
- Feature 016/018 (Shards) — shard balance must accept programmatic additions.
- Feature 043 (Gold Storage Cap) — the offline accumulation cap is read from this upgrade's configured duration; both generators share it.
