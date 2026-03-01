# Feature Specification: Damage Multiplier Upgrade

**Feature Branch**: `019-damage-upgrade`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "add one upgrade button: damage multiplier. it should have 10 levels for now. the ui should be one button that says 'damage multiplier cost * shards'. the level cost should scale cost = previous_cost*1.2, with base_cost being 50 shards. when purchased, damage should be modified by +10%. the upgrade is cumulative, with each modifier applied to base damage (so second upgrade will grant +20% damage from base, third +30%, etc)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Purchase a Damage Upgrade in the Hub (Priority: P1)

While in the hub, the player sees a button showing the damage multiplier upgrade and its current cost in shards. They can tap the button to purchase the next level if they have enough shards. The button updates immediately to show the cost of the following level. When the maximum level is reached, the button indicates it is maxed out and cannot be purchased further.

**Why this priority**: This is the core loop — the player earns shards in runs and spends them in the hub to become stronger. Without the purchase flow, no other aspect of the feature delivers value.

**Independent Test**: Enter hub with enough shards. Tap the upgrade button. Confirm shard balance decreases by the correct cost and button shows the next level's cost. Tap again until level 10. Confirm button changes to max state and no further purchase is possible.

**Acceptance Scenarios**:

1. **Given** the player has 50+ shards and the upgrade is at level 0, **When** they tap the button, **Then** 50 shards are deducted and the button updates to show the level 1→2 cost (60 shards).
2. **Given** the player has fewer shards than the current level cost, **When** they view the button, **Then** the button is visually disabled and the purchase cannot be made.
3. **Given** the upgrade is at level 10 (maximum), **When** the player views the hub, **Then** the button shows a "MAX" state and no purchase is possible regardless of shard balance.
4. **Given** the upgrade is purchased, **When** the player returns to the hub after a run, **Then** the button correctly shows the cost for the next level (not reset to level 0).

---

### User Story 2 - Upgrade Persists Across Sessions (Priority: P2)

The player's purchased upgrade level is saved and restored on game relaunch. Progress is never lost.

**Why this priority**: Meta-progression has no meaning if it resets on restart. Persistence is the contract that makes shard spending worthwhile.

**Independent Test**: Buy 2 levels. Close and relaunch the game. Enter the hub. Confirm the button shows the cost for level 3 (not level 1).

**Acceptance Scenarios**:

1. **Given** the player has purchased 3 upgrade levels, **When** the game is closed and reopened, **Then** the upgrade remains at level 3 and the button shows the correct level 4 cost.
2. **Given** the game is launched for the first time, **When** the player enters the hub, **Then** the upgrade is at level 0 and shows the base cost of 50 shards.

---

### User Story 3 - Upgrade Affects Player Damage in Runs (Priority: P3)

When a run begins, the player's damage reflects the purchased upgrade level. Each level adds +10% of base damage additively: level 1 = +10%, level 2 = +20%, level 3 = +30%, up to level 10 = +100%.

**Why this priority**: Without this, the shard spend has no gameplay impact. The upgrade must translate into a tangible run benefit.

**Independent Test**: Purchase level 1. Start a run. Attack an enemy and confirm damage is 10% higher than without the upgrade. Purchase level 2. Start another run. Confirm damage is 20% higher than the base (not 21% — the bonus is additive from base, not compounding).

**Acceptance Scenarios**:

1. **Given** the upgrade is at level 1, **When** the player attacks in a run, **Then** their damage is base damage × 1.1 (110% of base).
2. **Given** the upgrade is at level 3, **When** the player attacks in a run, **Then** their damage is base damage × 1.3 (130% of base, not 1.1 × 1.1 × 1.1).
3. **Given** the upgrade is at level 0, **When** the player attacks in a run, **Then** their damage is unchanged from base.
4. **Given** the upgrade is at level 10, **When** the player attacks in a run, **Then** their damage is base damage × 2.0 (200% of base).

---

### Edge Cases

- Player has exactly the cost amount — purchase succeeds, balance reaches zero.
- Player tries to purchase at max level — purchase rejected; balance unchanged.
- Damage formula at level 0 produces no bonus (multiplier = 1.0), identical to before the feature.
- Cost values are floored to whole shards at each step; the exact table is determined during planning from the formula `cost[n] = floor(cost[n-1] * 1.2)` with `cost[0] = 50`.
- Game launched for the first time: upgrade level = 0, balance = 0, button shows "50 shards" but is disabled.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The hub MUST display a single upgrade button for the damage multiplier, showing the label and the current shard cost for the next level.
- **FR-002**: The button MUST be purchasable by tapping it when the player has sufficient shards; on success, the shard balance decreases by the displayed cost.
- **FR-003**: The button MUST be visually disabled (non-interactive) when the player cannot afford the current cost.
- **FR-004**: The upgrade MUST have exactly 10 purchasable levels. The base cost is 50 shards; each subsequent level costs the previous level's cost × 1.2, rounded down to the nearest whole shard.
- **FR-005**: At level 10, the button MUST display a maxed state and reject all purchase attempts.
- **FR-006**: Each purchased level MUST add +10% of the player's base damage additively; the total bonus at level N is N × 10% of base damage.
- **FR-007**: The purchased upgrade level MUST be saved immediately on purchase and restored on game relaunch.
- **FR-008**: The damage bonus MUST apply at the start of every run based on the current upgrade level at that moment.

### Key Entities

- **Damage upgrade level**: A single integer (0–10) representing how many times the damage multiplier has been purchased. Persisted alongside other meta-progression data.
- **Level cost table**: The pre-computed shard cost for each level transition (level 0→1 = 50, 1→2 = 60, etc.), derived from the scaling formula.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After purchasing a level, the shard balance decreases by exactly the displayed cost in 100% of cases — no rounding discrepancy between shown cost and actual deduction.
- **SC-002**: The button correctly enables/disables based on affordability in 100% of cases — a player who cannot afford the upgrade can never accidentally purchase it.
- **SC-003**: The upgrade level is correctly restored after game relaunch in 100% of test cases across at least 3 consecutive save-and-reload cycles.
- **SC-004**: Player damage in a run matches the expected multiplier for the current upgrade level (base × (1 + level × 0.1)) in 100% of test cases across all 10 levels.

## Assumptions

- Costs are floored to whole integers at each level using the formula: `cost[0] = 50`, `cost[n] = floor(cost[n-1] * 1.2)`. Flooring is applied at each step (not just at display), so each level's cost is based on the already-floored previous cost.
- The button label format is: `"Damage Multiplier — [cost] shards"` (or equivalent). The current upgrade level number is not displayed on the button (MVP assumption).
- The upgrade level is stored in `MetaState` alongside `total_shards`, using the existing save system.
- "Base damage" refers to the player's unmodified damage stat as defined by `StatsComponent`. The multiplier is applied once per run start, not recalculated each hit.
- The upgrade shop is accessible in the hub at all times (not gated behind run count or other conditions).
- The upgrade UI is a separate scene from `HubRoom.tscn`, displayed alongside the shard counter.

## Scope

**In scope**: Single damage multiplier upgrade with 10 levels, hub button UI, shard cost deduction, damage application per run, persistence.

**Out of scope**: Multiple upgrade types, upgrade preview/tooltip, upgrade reset, visual upgrade animation, upgrade level display on button, upgrade effects on anything other than damage.
