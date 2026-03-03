# Feature Specification: Adventurer Bag

**Feature Branch**: `026-adventurer-bag`
**Created**: 2026-03-03
**Status**: Draft
**Input**: User description: "create an upgrade that is unlocked when an elite room is cleared for the first time in the game. it should be called 'adventurer bag'. this unlock allows for relic collection (unlocks relic system). ui presentation should be deferred to later stages"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — First Elite Clear Permanently Unlocks Adventurer Bag (Priority: P1)

A player clears an elite room for the very first time — across all their runs. The Adventurer Bag upgrade is permanently recorded. From this point forward, relic offers appear whenever the relic system would normally trigger one. This unlock persists across all future sessions.

**Why this priority**: The Adventurer Bag is the gate for the entire relic system. Nothing else in this feature matters until the unlock itself fires and persists correctly.

**Independent Test**: Start a fresh profile (no Adventurer Bag). Run until you clear an elite room. Start a new run. Verify relic offers now appear on room clears.

**Acceptance Scenarios**:

1. **Given** the player has never cleared an elite room, **When** they clear an elite room for the first time, **Then** the Adventurer Bag upgrade is permanently unlocked.
2. **Given** the Adventurer Bag is unlocked, **When** a new run is started, **Then** relic offers appear on qualifying room clears in that run.
3. **Given** the Adventurer Bag is already unlocked, **When** the player clears another elite room, **Then** no duplicate unlock event is fired and the unlock state is unchanged.
4. **Given** the player has closed and reopened the game with the Adventurer Bag unlocked, **When** they start a run, **Then** the relic system is still active (unlock persisted).

---

### User Story 2 — Relic System Gated Until Unlock (Priority: P2)

Before the Adventurer Bag is unlocked, no relic offers appear — even in situations where the relic system would otherwise trigger (e.g. after a standard room clear interval or after an elite clear). Once unlocked, relic offers behave exactly as specified by the relic system.

**Why this priority**: The gate must be hard — relic exposure before the unlock breaks the intended progression. But this story is secondary to P1 because P1 is what establishes the unlock in the first place.

**Independent Test**: Start a fresh profile. Clear elite rooms and standard rooms. Verify no relic offer ever appears. Unlock the Adventurer Bag. Verify relic offers now appear.

**Acceptance Scenarios**:

1. **Given** the Adventurer Bag is not unlocked, **When** any room is cleared (standard or elite), **Then** no relic offer is generated.
2. **Given** the Adventurer Bag is not unlocked, **When** the player clears an elite room (triggering the unlock), **Then** no relic offer fires for that same room clear event (the offer is not retroactive).
3. **Given** the Adventurer Bag is unlocked, **When** a qualifying room is cleared, **Then** a relic offer is generated normally per the relic system rules.

---

### Edge Cases

- What happens if the player clears an elite room multiple times before a save completes? Only the first detection counts; subsequent calls are no-ops.
- What happens if `MetaState` is missing or corrupt on load? The game defaults to "not unlocked" — the player must earn it again. No crash.
- What happens if both an elite clear and the unlock happen in the same frame? The unlock is recorded first; the relic offer for that room is skipped (unlock is not retroactive for the triggering room).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST detect when the player clears an elite room for the first time ever (across all runs and sessions).
- **FR-002**: On first elite room clear, the Adventurer Bag MUST be permanently recorded as unlocked in persistent meta-progression storage.
- **FR-003**: Relic offers MUST NOT be generated for any room clear while the Adventurer Bag is not unlocked.
- **FR-004**: The Adventurer Bag unlock state MUST survive game restarts (persisted in the same storage layer as other meta-progression data).
- **FR-005**: Subsequent elite room clears after the initial unlock MUST NOT re-trigger the unlock event.
- **FR-006**: The unlock event MUST NOT generate a relic offer for the room clear that triggered it.
- **FR-007**: UI notification of the unlock is explicitly out of scope for this feature — deferred to a later stage.

### Key Entities

- **Adventurer Bag**: A permanent boolean meta-unlock. Once set, it is never unset during normal gameplay. Stored as part of `MetaState`.
- **MetaState**: Existing persistent data class. Gains one new field: `adventurer_bag_unlocked: bool`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On a fresh profile, zero relic offers appear across any number of runs until the first elite room is cleared.
- **SC-002**: After the first elite room clear, relic offers appear on qualifying room clears within the same run and all subsequent runs.
- **SC-003**: The unlock survives a full game restart — verified by quitting after the unlock and confirming relic offers on the next session.
- **SC-004**: Clearing a second elite room produces no observable change to unlock state or relic offer behavior.

## Assumptions

- Elite room detection re-uses the existing `room_type_id.contains("Elite")` check already used by `RelicManagerImpl.should_offer_for_room()`.
- Persistence uses `SaveManager` (existing) with no new file or format — `MetaState` gains one additional field, defaulting to `false` on missing data.
- No UI feedback for this feature — the unlock is silent; the player discovers it by receiving relic offers.
- The relic offer gate is checked at the point where `RelicManager` decides to emit `relic_offer_ready` — a single boolean guard.
