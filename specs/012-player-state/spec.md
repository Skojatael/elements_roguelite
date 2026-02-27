# Feature Specification: Player State Snapshot

**Feature Branch**: `012-player-state`
**Created**: 2026-02-27
**Status**: Draft
**Input**: "add playerstate.gd which is referenced by runstate. player state should have current hp, items, modifiers, skill changes, cooldown state for skills. keep everything as stubs for now except player hp. playerstate should correctly reset on run end"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The Run Always Knows the Player's Health (Priority: P1) 🎯 MVP

At any moment during a run, the game has a single, authoritative record of the player's current health. Any part of the game that needs this information — a HUD, a death screen, a future save system — can read it from the run snapshot without querying the player directly. The player state record is part of the run snapshot, so any consumer that already reads run state automatically gains access to player health.

**Why this priority**: Player health is the most critical player stat during a run. It drives the death condition, informs the HUD, and is foundational for any future player-state feature. Without a live record, every consumer must independently track the player's component tree — the player state record establishes a stable contract.

**Independent Test**: Start a run. Confirm the player state record exists within the run snapshot and that `current_hp` matches the player's actual starting health. Deal damage to the player. Confirm `current_hp` decreases to reflect the new value. Heal the player. Confirm `current_hp` increases accordingly.

**Acceptance Scenarios**:

1. **Given** a run has started, **When** any system reads the run snapshot's player state, **Then** `current_hp` accurately reflects the player's actual current health.
2. **Given** the player takes damage, **When** the player state is read, **Then** `current_hp` reflects the reduced health value.
3. **Given** the player heals, **When** the player state is read, **Then** `current_hp` reflects the increased health value.
4. **Given** the player is at full health, **When** the player state is read, **Then** `current_hp` equals the player's maximum health.
5. **Given** no run is active, **When** the player state is read, **Then** all fields return safe defaults — no crash.

---

### User Story 2 - Player State Resets When a Run Ends (Priority: P1) 🎯 MVP

When a run ends — whether through death, cashing out, or any other reason — the player state record is immediately cleared to safe defaults. The cleared state reflects a player ready for a fresh run: health is restored to full, and stub fields return their zero defaults. This reset happens at run end, not at the next run start.

**Why this priority**: Stale player state carrying over after a run ends would pollute any system reading it between runs. Since the player state record is accessed via the run snapshot (which persists until the next run starts), it must be clean the moment the run ends so downstream systems see accurate post-run data.

**Independent Test**: Start a run. Deal damage to the player (reducing `current_hp`). End the run. Immediately read the player state. Confirm `current_hp` is back at full health. Confirm stub fields are at their zero defaults.

**Acceptance Scenarios**:

1. **Given** a run ends with the player at low health, **When** the player state is read after run end, **Then** `current_hp` reflects full health (reset occurred).
2. **Given** a run ends, **When** a new run begins, **Then** the player state already shows full health before any gameplay events occur.
3. **Given** a run ends, **When** any stub field is read, **Then** it returns its zero default — no error.

---

### User Story 3 - Future Player Data Fields Are Reserved and Safe (Priority: P2)

The player state record includes four fields that are not yet active: **items** (a collection of items the player has acquired this run), **modifiers** (stat multipliers applied by items or upgrades), **skill changes** (run-specific modifications to the player's skills), and **skill cooldowns** (the current cooldown state for each skill). All four fields exist with defined default values and can be read without error. They are never populated in this feature — population is deferred to when their respective systems are built.

**Why this priority**: Declaring these fields now establishes the data contract. When items, the modifier system, skill changes, and skill cooldown tracking are built, they slot into existing fields — no structural change to the player state record is needed. Reading a stub field must never cause an error.

**Independent Test**: Start a run. Read `items` — confirm it returns an empty collection, no error. Read `modifiers` — confirm empty, no error. Read `skill_changes` — confirm empty, no error. Read `skill_cooldowns` — confirm empty, no error. End the run. Confirm all four still return empty defaults, no error.

**Acceptance Scenarios**:

1. **Given** a run is active, **When** any system reads `items`, **Then** it returns an empty collection — no error, no crash.
2. **Given** a run is active, **When** any system reads `modifiers`, **Then** it returns an empty collection — no error.
3. **Given** a run is active, **When** any system reads `skill_changes`, **Then** it returns an empty collection — no error.
4. **Given** a run is active, **When** any system reads `skill_cooldowns`, **Then** it returns an empty collection — no error.
5. **Given** a run ends, **When** any stub field is read, **Then** it returns its empty default — no error.

---

### Edge Cases

- What if the player state is read before any run has started? All fields return safe defaults — `current_hp` at full health, stubs empty. No crash.
- What if `current_hp` is read during the brief moment between run end and the next run start? Returns full health (reset occurred at run end).
- What if the player dies mid-run? `current_hp` hits zero; the player state record accurately reflects `0` until run end fires, at which point it resets to full.
- What if a future feature populates `items` during a run? The reset at run end clears it — items do not carry over between runs without a dedicated persistence feature.
- What if `current_hp` changes multiple times in one frame (e.g., area damage)? The record reflects the final value each time it is read — no intermediate states are cached.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: A player state record MUST exist as part of the run snapshot and be accessible whenever the run snapshot is accessible.
- **FR-002**: The player state record MUST contain a `current_hp` field reflecting the player's current health at the time of reading. It MUST update whenever the player's health changes.
- **FR-003**: The player state record MUST contain an `items` field — a collection of items acquired this run. In this feature it is a stub: always empty, never updated. It MUST NOT cause any error when read.
- **FR-004**: The player state record MUST contain a `modifiers` field — a collection of active stat modifiers. In this feature it is a stub: always empty, never updated. It MUST NOT cause any error when read.
- **FR-005**: The player state record MUST contain a `skill_changes` field — a collection of run-specific skill modifications. In this feature it is a stub: always empty, never updated. It MUST NOT cause any error when read.
- **FR-006**: The player state record MUST contain a `skill_cooldowns` field — a record of per-skill cooldown state. In this feature it is a stub: always empty, never updated. It MUST NOT cause any error when read.
- **FR-007**: When a run ends, ALL fields in the player state record MUST immediately reset to their initial values: `current_hp` to full health, stubs to empty.
- **FR-008**: The reset in FR-007 MUST occur at run end — not deferred to the next run start.
- **FR-009**: The player state record MUST be read-only for all systems other than the one that owns and updates it. Consumers observe; they do not write.
- **FR-010**: The player state record is defined as a dedicated data file (one file, one class). It is not embedded in another system's file.
- **FR-011**: The run snapshot (RunState) MUST include a reference to the player state record so consumers can access player state through the run snapshot.

### Key Entities

- **PlayerState**: A structured data record capturing the player's in-run state. Fields: `current_hp` (numeric, live), `items` (collection, stub), `modifiers` (collection, stub), `skill_changes` (collection, stub), `skill_cooldowns` (collection, stub).
- **Stub field**: A declared field with a defined type and safe default value (empty), not populated by any active system in this feature. Reserved for a named future system. Must never produce an error when read.
- **Run Owner**: The system that creates, updates, and resets PlayerState. All other systems are consumers.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: During any active run, `current_hp` in the player state record always matches the player's actual health — verified at 10 different health values (start, after damage, after healing, at zero, after recovery).
- **SC-002**: Immediately after a run ends, `current_hp` equals the player's maximum health — verified across 5 run endings via different causes.
- **SC-003**: All four stub fields return their empty defaults without error during any run lifecycle phase (before start, during run, after end) — 0 errors across all reads.
- **SC-004**: The run snapshot provides access to player state — any system reading the run snapshot can reach `current_hp` without additional queries.
- **SC-005**: No errors or warnings appear in the output when reading any player state field at any point in a run lifecycle.

## Assumptions

- PlayerState is implemented as a dedicated data class file. One file, one class.
- The run state owner (RunManager) also owns PlayerState — it creates it, updates it, and is the only writer.
- All other systems are read-only consumers of PlayerState via the run snapshot.
- `current_hp` is a numeric value matching the player's actual current health. It is updated by the same system that manages the player's health component.
- Stub fields (`items`, `modifiers`, `skill_changes`, `skill_cooldowns`) are collections (arrays or equivalent). They default to empty and never contain entries in this feature.
- The reset at run end restores `current_hp` to the player's maximum health, not to a fixed value. Maximum health is determined by the player's base stats (not modified by items in this feature, since items are a stub).
- PlayerState is not persisted to disk in this feature. Save/load is a future concern.
- RunState is extended to include a `player_state` reference — this is an additive change to the existing RunState record. No previously-defined RunState fields are removed or changed.
- The reset timing (at run end, not run start) is intentional and differs from RunState's own reset behavior. RunState retains its final values after a run for summary screens; PlayerState resets immediately since player health is not needed for post-run summaries.
