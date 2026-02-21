# Feature Specification: Run Manager

**Feature Directory**: `004-run-manager`
**Created**: 2026-02-21
**Status**: Draft
**Input**: User description: "implement RunManager that consists of: current run state, current room, difficulty service (stub), rewards service (stub), events (room cleared, run ended)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Run Lifecycle (Priority: P1)

A run can be started and ended. When a run starts, all session state is initialised to known values and the game is ready to accept player input. When a run ends, the session is closed and state is preserved for any post-run summary. Without a defined lifecycle, no other run feature can work safely.

**Why this priority**: Every other user story — room tracking, currency, difficulty, rewards — depends on a run being active. This is the foundation.

**Independent Test**: Call `start_run(mode)`. Confirm `is_run_active` is true, `run_id` is non-empty, `run_start_time` is set, `current_room_index` is 0, `run_currency` is 0, `current_tier` is 1, and `run_mode` matches the argument. Then call `end_run()`. Confirm `is_run_active` is false and `run_ended` signal fires exactly once.

**Acceptance Scenarios**:

1. **Given** no run is active, **When** `start_run("endless")` is called, **Then** all session fields are initialised and `is_run_active` returns true.
2. **Given** a run is active, **When** `end_run()` is called, **Then** `run_ended` signal fires, `is_run_active` returns false, and session state is retained for reading until the next `start_run`.
3. **Given** a run is active, **When** `start_run()` is called again, **Then** session state is fully reset and a new `run_id` is generated.

---

### User Story 2 - Room Navigation Tracking (Priority: P2)

As the player moves through the dungeon, RunManager automatically tracks the current room and how many rooms have been visited. Other systems can query RunManager at any time to know where the player is and how far into the run they are.

**Why this priority**: Room tracking drives difficulty scaling and reward calculation. It must work before those services are meaningful.

**Independent Test**: Start a run. Have the player enter a room. Confirm `current_room` matches the entered room and `current_room_index` has incremented by 1. Defeat all enemies. Confirm `room_cleared` signal fires on RunManager.

**Acceptance Scenarios**:

1. **Given** a run is active, **When** the player enters a room, **Then** `current_room` is updated to that room and `current_room_index` increments by 1.
2. **Given** a run is active and a room is entered, **When** all enemies in the room are defeated, **Then** RunManager emits `room_cleared` with the room ID.
3. **Given** no run is active, **When** a room entry signal is received, **Then** RunManager ignores it and does not update state.

---

### User Story 3 - Run Currency Tracking (Priority: P3)

Gold collected during a run is accumulated in RunManager. Any system can add gold to the current run total or query how much has been collected. The total resets to zero when a new run starts.

**Why this priority**: Currency is the reward loop driver. It depends on runs being active (US1) but not on room tracking (US2), so it can be developed in parallel with US2.

**Independent Test**: Start a run. Call `add_currency(10)`. Confirm `run_currency` is 10. Call `add_currency(5)`. Confirm `run_currency` is 15. End the run and start a new one. Confirm `run_currency` is 0.

**Acceptance Scenarios**:

1. **Given** a run is active, **When** `add_currency(amount)` is called, **Then** `run_currency` increases by that amount.
2. **Given** a run is active, **When** `add_currency` is called with a negative value, **Then** `run_currency` does not drop below zero.
3. **Given** a completed run with non-zero currency, **When** a new run starts, **Then** `run_currency` resets to zero.

---

### User Story 4 - Difficulty and Rewards Access (Priority: P4)

The difficulty service and rewards service are accessible through RunManager. Both are stubs that return fixed placeholder values, ready to be replaced with real logic in a future feature. Callers do not need to know whether the service is a stub or a full implementation.

**Why this priority**: These stubs establish the interfaces that other systems will depend on, but no real behaviour is needed yet. Can be added last without blocking anything.

**Independent Test**: Call `DifficultyService.get_multiplier()`. Confirm it returns a numeric value (e.g. 1.0) without error. Call `RewardsService.get_room_reward(room_id)`. Confirm it returns a valid (possibly empty) reward structure without error.

**Acceptance Scenarios**:

1. **Given** a run is active or not, **When** `DifficultyService.get_multiplier()` is called, **Then** it returns 1.0 with no error.
2. **Given** any room ID, **When** `RewardsService.get_room_reward(room_id)` is called, **Then** it returns an empty reward with no error.
3. **Given** the stubs exist, **When** real implementations replace them in a future feature, **Then** no call sites need to change.

---

### Edge Cases

- What happens if `end_run()` is called when no run is active?
- What happens if `add_currency` is called when no run is active?
- What happens if a room entry signal fires before the room is fully loaded?
- What happens if `current_room_index` overflows (extremely long endless run)?
- What happens if two rooms emit entry signals simultaneously?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `start_run(mode: String)` MUST initialise all session fields: `run_id` (unique temporary string), `current_room_index` (0), `current_room` (null), `run_currency` (0), `run_start_time` (current time), `run_mode` (provided argument), `current_tier` (1).
- **FR-002**: `end_run()` MUST emit `run_ended` signal and mark the run as inactive. It MUST be a no-op if no run is active.
- **FR-003**: RunManager MUST expose `is_run_active: bool` readable by any system at any time.
- **FR-004**: RunManager MUST listen to each room's entry event and update `current_room` and `current_room_index` automatically — callers do not set these directly.
- **FR-005**: When a room's `room_cleared` signal fires, RunManager MUST re-emit its own `room_cleared(room_id: String)` signal for other systems to react to.
- **FR-006**: `add_currency(amount: float)` MUST add to `run_currency` and MUST NOT allow it to drop below zero.
- **FR-007**: `run_currency`, `current_room`, `current_room_index`, `run_mode`, `current_tier`, `run_start_time`, and `run_id` MUST all reset to their initial values when `start_run()` is called.
- **FR-008**: `DifficultyService` MUST expose `get_multiplier() -> float` returning 1.0 (stub).
- **FR-009**: `RewardsService` MUST expose `get_room_reward(room_id: String) -> Dictionary` returning an empty Dictionary (stub).
- **FR-010**: `end_run()` MUST NOT clear session state immediately — state MUST remain readable after the run ends (e.g. for a post-run summary screen) until `start_run()` is called again.

### Key Entities

- **RunSession**: The active run's snapshot. Contains `run_id`, `run_mode`, `current_tier`, `run_start_time`, `run_currency`, `current_room`, `current_room_index`. Lives entirely in memory; not persisted between app launches.
- **DifficultyService**: Stub service that provides a difficulty multiplier based on run state. Currently always returns 1.0. Future implementation will use `current_tier` and `current_room_index`.
- **RewardsService**: Stub service that determines what reward to offer after a room is cleared. Currently returns an empty structure. Future implementation will use room type and `current_tier`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All session fields are readable within the same frame that `start_run()` is called.
- **SC-002**: `current_room` and `current_room_index` update within the same frame the player enters a room — no one-frame delay.
- **SC-003**: `run_ended` fires exactly once per `end_run()` call, regardless of how many systems are listening.
- **SC-004**: Calling `DifficultyService.get_multiplier()` or `RewardsService.get_room_reward()` from any system produces no errors in any run state.
- **SC-005**: A run with 100 rooms cleared shows `current_room_index` of 100 with no state corruption.

## Assumptions

- `run_id` is a temporary in-memory identifier (e.g. timestamp string) and does not need to be globally unique across devices or sessions.
- `run_mode` accepts two values: `"endless"` and `"boss"`. Other values are treated as invalid and may produce a warning.
- `current_tier` starts at 1 and is managed externally (e.g. by a meta-progression system); RunManager stores it but does not compute it.
- RunManager is a singleton (autoload) — there is always exactly one instance; no concurrency concerns.
- Room entry detection reuses the existing `EntryArea` / `RoomSpawner` mechanism from `003-enemy-spawning`; RunManager connects to `RoomSpawner.room_cleared` signals rather than raw physics events.
- Currency is stored as a float to allow fractional amounts from future multipliers, but displayed as a whole number.
- DifficultyService and RewardsService are inner classes or companion scripts within the RunManager module — not separate autoloads.
