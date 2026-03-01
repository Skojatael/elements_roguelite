# Feature Specification: Meta Currency — Shards

**Feature Branch**: `016-meta-shards`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "add meta currency called 'shards'. it should be converted from essence on run end. a manager called MetaManager should compute the amount of shards, increment total shards (that amount should be stored in meta info in MetaState, similar to run info in RunState)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Earn Shards on Run End (Priority: P1)

When a run ends (either by death or cash-out), the player's cashed-out essence is automatically converted into shards. MetaManager computes the shard amount, adds it to the player's cumulative shard total, and the updated total is stored in MetaState.

**Why this priority**: Shards are the foundation of meta-progression. Without earning them, no other meta features are possible. This is the core earning loop.

**Independent Test**: Trigger a run end, observe that MetaManager's shard total increases by the correct converted amount, and that MetaState reflects the new total.

**Acceptance Scenarios**:

1. **Given** a run ends with 100 essence cashed out, **When** MetaManager processes the run result, **Then** the shard total increases by 33 shards (floori(100 × 0.3333)) and MetaState stores the new cumulative total.
2. **Given** a run ends with 0 essence cashed out, **When** MetaManager processes the run result, **Then** the shard total does not change.
3. **Given** multiple runs completed in sequence, **When** each run ends, **Then** shards accumulate correctly across all runs and MetaState always reflects the running total.

---

### User Story 2 - MetaState Persists Across Sessions (Priority: P2)

The player's total shard count is saved when the game closes and restored when the game reopens. Shard progress is never lost between sessions.

**Why this priority**: Without persistence, meta-progression has no meaning — players would lose all earned shards on every restart.

**Independent Test**: Earn shards in one session, close and reopen the game, and verify the shard total matches what was earned.

**Acceptance Scenarios**:

1. **Given** the player has accumulated shards across several runs, **When** the game is closed and reopened, **Then** MetaState loads with the correct prior total and new shards are added on top.
2. **Given** the game is launched for the first time, **When** MetaState is initialized, **Then** shard total starts at 0.

---

### Edge Cases

- What happens when essence cashed out is 0 — shards earned should be 0 (no change to total).
- What happens on first-ever run — MetaState initializes with total_shards = 0 before any run completes.
- Conversion always produces a non-negative integer; fractional results are floored.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST convert essence cashed out at run end into a shard amount using a defined formula.
- **FR-002**: MetaManager MUST compute the shard conversion and add it to the cumulative total stored in MetaState.
- **FR-003**: MetaState MUST store `total_shards: int` as its primary field, non-negative, initialized to 0.
- **FR-004**: MetaState MUST persist across game sessions via the existing save system.
- **FR-005**: Shard conversion MUST use `floori()` so the result is always a whole number.
- **FR-006**: MetaManager MUST connect to `RunManager.run_ended` and process the conversion automatically — no manual trigger required.
- **FR-007**: The conversion formula is: `shards_earned = floori(essence_cashed_out × 0.3333)` — a 3:1 rate, so approximately 3 essence converts to 1 shard (e.g. 100 essence → 33 shards).

### Key Entities

- **MetaState**: Persistent data object holding `total_shards: int`. Analogous to RunState but for meta-progression data that survives across runs and sessions.
- **Shards**: Whole-number meta currency accumulated over multiple runs, derived from essence cashed out.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After every run end, MetaState's `total_shards` increases by exactly the correct converted amount (verifiable by logging or inspection).
- **SC-002**: `total_shards` is always a non-negative integer; no run can produce a negative shard delta.
- **SC-003**: MetaState shard total is correctly restored after a simulated session restart in 100% of test cases.
- **SC-004**: MetaManager responds to run end within the same frame the `run_ended` signal fires — no deferred processing.

## Assumptions

- MetaManager already exists as an autoload singleton (`autoload/MetaManager.gd`) and will be extended, not created from scratch.
- The existing `SaveManager` autoload handles persistence; MetaState will be saved and loaded through it.
- Only `essence_cashed_out` from `RunSummary` is used for shard conversion (not total essence earned during the run).
- Shards have no cap in this iteration — total can grow indefinitely.
- Shards are not spendable in this feature; spending is a future concern.

## Scope

**In scope**: Earning shards from essence at run end, MetaState data model, MetaManager integration with RunManager, persistence.

**Out of scope**: Spending shards, shard UI display during runs, shard bonuses or multipliers, shard cap.
