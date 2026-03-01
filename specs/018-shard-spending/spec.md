# Feature Specification: Shard Spending

**Feature Branch**: `018-shard-spending`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "implement shard spending In MetaManager: can_spend(cost) -> bool, spend(cost) -> bool, add_shards(amount), signal shards_changed"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Spend Shards on a Purchase (Priority: P1)

A game system (e.g. an upgrade shop) checks whether the player can afford a cost, then deducts shards if they can. The purchase is rejected if the player has insufficient shards. The deduction is saved immediately so balance is never double-spent.

**Why this priority**: All shard spending features depend on the ability to safely verify and deduct a balance. Without this, no purchase system can be built.

**Independent Test**: Call spend with a valid cost → balance decreases by that amount and is persisted. Call spend with a cost exceeding the balance → balance unchanged, call returns failure.

**Acceptance Scenarios**:

1. **Given** the player has 50 shards and a purchase costs 20, **When** the purchase is attempted, **Then** the balance becomes 30 and the purchase succeeds.
2. **Given** the player has 10 shards and a purchase costs 30, **When** the purchase is attempted, **Then** the balance stays at 10 and the purchase fails.
3. **Given** the player has exactly enough shards to cover the cost, **When** the purchase is attempted, **Then** the balance reaches 0 and the purchase succeeds.
4. **Given** a system checks affordability before showing a purchase option, **When** the player's balance is less than the cost, **Then** the check returns false so the option can be disabled or hidden.

---

### User Story 2 - Grant Shards from Any Source (Priority: P2)

Shards can be awarded to the player from any in-game event — not only at run end. Examples: tutorial reward, chest find, achievement bonus. The balance updates and is persisted immediately.

**Why this priority**: Without a general-purpose shard grant method, every new reward source requires a custom integration with the shard system. This unblocks future content.

**Independent Test**: Call the grant method with a positive amount → balance increases by that amount and is saved. Existing run-end conversion continues to work unchanged.

**Acceptance Scenarios**:

1. **Given** the player has 0 shards, **When** 15 shards are granted from a chest reward, **Then** the balance becomes 15 and is persisted.
2. **Given** the player already has shards from prior runs, **When** additional shards are granted, **Then** the new total is the sum of prior and granted amounts.

---

### User Story 3 - React to Balance Changes in Real Time (Priority: P3)

Any game system (e.g. a shard counter overlay, an upgrade shop) is notified the moment the shard balance changes — whether from a spend, a grant, or a run-end conversion. No polling required.

**Why this priority**: Without a change notification, UI elements must either read-once (and go stale) or poll constantly (wasteful). The signal makes reactive UI straightforward.

**Independent Test**: Connect a listener to the shard balance change notification. Trigger a spend and a grant → listener is called each time with the updated total.

**Acceptance Scenarios**:

1. **Given** a UI element is listening for balance changes, **When** shards are spent, **Then** the listener receives the updated (lower) total immediately.
2. **Given** a UI element is listening for balance changes, **When** shards are granted, **Then** the listener receives the updated (higher) total immediately.
3. **Given** a run ends and shards are converted from essence, **When** MetaManager processes the result, **Then** the listener also receives the new total from that conversion.

---

### Edge Cases

- Spending exactly 0 shards: treated as a valid spend that always succeeds and changes nothing.
- Granting 0 shards: valid, balance unchanged; signal may or may not fire (assume it does not fire for zero-amount grants).
- Spending with a negative cost: rejected — costs are always non-negative.
- Granting a negative amount: rejected — grant amounts are always non-negative.
- Balance can reach 0 but never go below 0.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The shard system MUST expose a way to check whether the player can afford a given cost without modifying the balance.
- **FR-002**: The shard system MUST expose a way to deduct a given cost from the balance; the operation MUST succeed only when the balance is sufficient (balance >= cost).
- **FR-003**: A successful deduction MUST persist the new balance immediately and atomically — no deduction without a matching save.
- **FR-004**: A failed deduction (insufficient balance) MUST leave the balance unchanged and return a clear failure result.
- **FR-005**: The shard system MUST expose a way to add a positive integer amount of shards from any source, persisting the new balance immediately.
- **FR-006**: The shard system MUST emit a notification whenever `total_shards` changes, carrying the new total, so that other systems can update without polling.
- **FR-007**: The run-end shard conversion (existing feature 016) MUST also trigger the change notification introduced by this feature.
- **FR-008**: Costs and grant amounts MUST be non-negative integers; negative values MUST be rejected.

### Key Entities

- **Shard balance**: The player's current `total_shards` count — the single source of truth for all spend/grant operations.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A spend attempt with sufficient balance succeeds and persists the correct reduced total in 100% of cases.
- **SC-002**: A spend attempt with insufficient balance fails and leaves the balance unchanged in 100% of cases — no partial deductions.
- **SC-003**: Every balance change (spend, grant, run-end conversion) triggers the change notification within the same game frame in 100% of cases.
- **SC-004**: After any spend or grant, the persisted balance matches the in-memory balance in 100% of cases — no unsaved state.

## Assumptions

- Costs and grant amounts are whole numbers; no fractional shards.
- There is no shard cap — the balance can grow arbitrarily large.
- The change notification carries the new total as its only argument.
- The existing run-end conversion path (`on_run_ended`) will be updated to emit the new notification so US3 Scenario 3 is satisfied.
- `spend(0)` succeeds silently; `add_shards(0)` does nothing and does not emit the notification.

## Scope

**In scope**: Balance verification, deduction, arbitrary grant, change notification, persistence on every mutation.

**Out of scope**: Spend categories or reasons, transaction history, spending UI, spending animations, shard caps, negative balances.
