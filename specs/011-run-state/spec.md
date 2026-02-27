# Feature Specification: Run State Snapshot

**Feature Branch**: `011-run-state`
**Created**: 2026-02-27
**Status**: Draft
**Input**: "also add runstate that is a snapshot of a current run that contains this data (use .gd file): What room you're in / What rooms are cleared / Current run currency / Mode (endless / boss) / Seed (optional) / Max depth reached. any unimplemented properties should be marked as stubs and deferred to later"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The Game Always Knows the Full Run State (Priority: P1) 🎯 MVP

At any moment during a run, the game has a single, authoritative record of what is happening: which room the player is in, which rooms have been cleared, how much currency has been collected, and which mode is active. Any part of the game that needs this information — the HUD, an end-of-run summary screen, a future save system — can read it from one place without knowing the internal details of how the run is managed.

**Why this priority**: Without a central state record, every consumer (HUD, analytics, save/load) must individually query the run manager's internal fields. A RunState record establishes a stable data contract that all consumers depend on, and that internal systems can change without breaking those consumers.

**Independent Test**: Start a run. Confirm the run state record exists and contains: a valid current_room_id matching the loaded room, an empty cleared_rooms set at the start, run_currency of 0, and the correct run mode. Clear a room — confirm cleared_rooms updates. Collect currency — confirm run_currency updates.

**Acceptance Scenarios**:

1. **Given** a run has started, **When** any system reads the run state, **Then** it returns a record containing current_room_id, cleared_rooms, run_currency, and run_mode — all accurately reflecting the current run.
2. **Given** the player enters a new room, **When** the run state is read, **Then** current_room_id matches the room just entered.
3. **Given** the player clears a room, **When** the run state is read, **Then** that room's identifier appears in cleared_rooms.
4. **Given** the player collects currency, **When** the run state is read, **Then** run_currency reflects the updated total.
5. **Given** the run is in "endless" mode, **When** the run state is read, **Then** run_mode is "endless".

---

### User Story 2 - Run State Resets Cleanly Between Runs (Priority: P1) 🎯 MVP

When a new run begins, the run state resets completely. No data from the previous run leaks into the new one. The record starts with the correct initial values: no current room, no cleared rooms, zero currency, and the chosen mode.

**Why this priority**: Stale state from a previous run causing incorrect HUD values, wrong currency counts, or ghost cleared-room data would be a critical gameplay bug. Clean reset is foundational.

**Independent Test**: Complete or abandon a run. Start a new run. Confirm run_currency is 0, cleared_rooms is empty, and current_room_id reflects the new start room (not the previous run's last room).

**Acceptance Scenarios**:

1. **Given** a run ends (any reason), **When** a new run starts, **Then** run_currency resets to 0, cleared_rooms is empty, and run_mode reflects the new run's mode.
2. **Given** a run ends with 5 cleared rooms, **When** a new run starts, **Then** cleared_rooms contains 0 entries (no carry-over).
3. **Given** a run ends, **When** the end-of-run summary reads the run state, **Then** the final values (currency, cleared count, mode) are still accessible before the next run begins.

---

### User Story 3 - Future Fields Are Reserved and Safe (Priority: P2)

The run state record includes two fields that are not yet active: **max depth reached** (the deepest room the player visited, measured in room steps from the start) and **run seed** (a value for deterministic dungeon generation). Both fields exist with defined default values and can be read without error. They are not populated in this feature — population is deferred to when their respective systems are built.

**Why this priority**: Declaring these fields now establishes the data contract. Future features (depth tracking from feature 010, seeded generation) slot in by populating these fields — no structural change to RunState is needed. Reading a stub field must never cause an error.

**Independent Test**: Start a run. Read max_depth_reached — confirm it returns 0 (default, not an error). Read seed — confirm it returns 0 (default, not an error). Confirm neither field is populated or incremented by anything in this feature.

**Acceptance Scenarios**:

1. **Given** a run is active, **When** any system reads max_depth_reached, **Then** it returns 0 (stub default) — no error, no crash.
2. **Given** a run is active, **When** any system reads seed, **Then** it returns 0 (stub default) — no error, no crash.
3. **Given** the depth system (feature 010) is later integrated, **When** the player enters a room at depth 3, **Then** max_depth_reached updates to 3 — no structural change to RunState is required to support this.

---

### Edge Cases

- What if the run state is read before any run has started? All fields return safe defaults (empty string for IDs, empty set for collections, 0 for numeric values). No crash.
- What if current_room_id is read during a room transition (between rooms)? Returns an empty string — the transition is momentary and the consuming system should handle an empty value gracefully.
- What if the run ends and the state is read before the next run begins? The final values remain readable. State is only cleared at the start of the next run, not at run end.
- What if two systems read the run state simultaneously? The record is read-only for all consumers — no concurrent write conflict is possible.
- What if seed is set to a non-zero value by a future feature? All existing consumers transparently gain access to the value with no changes required on their side.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A run state record MUST exist and be accessible for the entire duration of an active run.
- **FR-002**: The run state record MUST contain a `current_room_id` field identifying which room the player is currently in. It updates whenever the player enters a new room.
- **FR-003**: The run state record MUST contain a `cleared_rooms` field — the set of room identifiers that have been cleared in this run. It updates whenever a room is cleared.
- **FR-004**: The run state record MUST contain a `run_currency` field — the total currency collected this run. It updates whenever currency is added.
- **FR-005**: The run state record MUST contain a `run_mode` field — the mode this run is using ("endless" or "boss"). Set at run start and does not change during the run.
- **FR-006**: The run state record MUST contain a `max_depth_reached` field. In this feature it is a stub: always 0, never updated. It MUST NOT cause any error when read.
- **FR-007**: The run state record MUST contain a `seed` field. In this feature it is a stub: always 0, never updated. It MUST NOT cause any error when read.
- **FR-008**: All live fields (FR-002 through FR-005) MUST be reset to their initial values at the start of each new run.
- **FR-009**: Stub fields (FR-006, FR-007) MUST also reset to 0 at the start of each new run.
- **FR-010**: The run state record MUST be read-only for all systems other than the one that owns and updates it. Consumers observe; they do not write.
- **FR-011**: The run state record MUST remain accessible with its final values after a run ends, until the next run begins.
- **FR-012**: The run state record is defined as a dedicated data file (one file per the user's specification). It is not embedded in another system's file.

### Key Entities

- **RunState**: A structured data record capturing the complete state of one run. Fields: `current_room_id` (String), `cleared_rooms` (collection of room identifiers), `run_currency` (numeric amount), `run_mode` (String), `max_depth_reached` (integer, stub), `seed` (integer, stub).
- **Stub field**: A declared field with a defined type and safe default value (0 / empty), not populated by any active system in this feature. Reserved for a named future feature. Must never produce an error when read.
- **Run Owner**: The system that creates, updates, and resets RunState. All other systems are consumers.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: During any active run, reading all six fields from the run state returns accurate, up-to-date values — 0 failures across 10 test reads at different points in a run.
- **SC-002**: After starting a new run, run_currency is exactly 0, cleared_rooms contains exactly 0 entries, and current_room_id matches the start room — verified immediately after run start.
- **SC-003**: Stub fields (max_depth_reached, seed) return exactly 0 when read during any run — 0 errors across all reads.
- **SC-004**: After a run ends and before the next run begins, the final run state values are still readable — run_currency and cleared_rooms count reflect the completed run.
- **SC-005**: No errors or warnings appear in the output when reading any run state field at any point in a run lifecycle (before start, during run, after end).

## Assumptions

- RunState is implemented as a dedicated GDScript data class file (as specified). One file, one class.
- RunManager owns the RunState instance — it creates it, updates it, and is the only writer.
- All other systems (HUD, save system, analytics) are read-only consumers of RunState.
- `cleared_rooms` in RunState mirrors the existing `cleared_rooms` Dictionary already maintained by RunManager — they refer to the same data, not separate copies.
- `current_room_id` is a String; it is empty ("") when no room is loaded (between runs or during transitions).
- `max_depth_reached` will be populated by the depth-difficulty feature (010). The stub value is 0.
- `seed` will be populated by a future deterministic dungeon generation feature. The stub value is 0.
- RunState is not persisted to disk in this feature. Save/load is a future concern.
- RunState is reset at the start of `start_run()` — not at `end_run()`. The final values survive until the next run begins.
- This feature does not add new signals. RunState is polled, not push-notified.
