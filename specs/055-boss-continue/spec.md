# Feature Specification: Boss Continue (Endless Mode)

**Feature Branch**: `1-boss-continue`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "implement continue for the boss in endless. on press, player should be teleported back to the room where the boss button was pressed."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Continue After Boss Kill (Priority: P1)

The player defeats the boss during an endless run and chooses to keep playing. Pressing "Continue" on the victory overlay dismisses it and returns the player to the dungeon room they were in when they activated the boss teleport — the run stays active and they can explore further.

**Why this priority**: This is the sole feature — the continue path is currently a stub with no behaviour.

**Independent Test**: Start an endless run, clear enough rooms to unlock the boss button, press it, defeat the boss, press "Continue" — verify player lands in the correct dungeon room with ExplorationHUD visible and run still active.

**Acceptance Scenarios**:

1. **Given** a player in dungeon room R in an active endless run, **When** they press the boss button and defeat the boss then press "Continue", **Then** room R is loaded and the player is placed at its center.
2. **Given** room R was already cleared before the boss teleport, **When** the player returns via Continue, **Then** room R loads as cleared (no enemies respawn) and its doors are correctly configured.
3. **Given** the boss victory overlay is showing, **When** the player presses "Continue", **Then** the overlay is dismissed and the ExplorationHUD becomes visible.

---

### User Story 2 — Continue Unavailable in Boss Mode (Priority: P2)

In a dedicated boss-mode run (not endless), the "Continue" button is already hidden. This behaviour remains unchanged — Continue is an endless-only option.

**Why this priority**: Correctness guard; the overlay's `setup(show_continue)` already controls visibility based on run mode. No new logic needed, but it must be validated.

**Independent Test**: Start a boss-mode run, kill the boss — verify "Continue" button is not visible on the victory overlay.

**Acceptance Scenarios**:

1. **Given** a boss-mode run, **When** the boss is defeated, **Then** the victory overlay shows only the "Cash Out" button; "Continue" is hidden.

---

### Edge Cases

- What if the player activated the boss from the DevPanel ("Start Boss" button) without having been in any dungeon room? The return room ID is empty — "Continue" must not be shown in this case (or the button is disabled/absent with no crash).
- What if the return room's data no longer exists in `DungeonGenerator.rooms_by_id`? This should not occur in a single run, but a graceful error log and no teleport is acceptable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When the player presses the boss teleport button in the ExplorationHUD, the system MUST record the `room_id` of the current dungeon room before that room is freed.
- **FR-002**: On "Continue" pressed, the system MUST free the boss room and load the recorded return room via `RoomLoader`.
- **FR-003**: On "Continue" pressed, the system MUST place the player at the center of the return room (same placement behaviour as initial room load — `entry_direction` empty).
- **FR-004**: On "Continue" pressed, the system MUST dismiss the boss victory overlay and restore the ExplorationHUD.
- **FR-005**: The "Continue" button MUST only be shown when a valid return room ID exists (i.e., the boss was reached via the HUD button during an active endless run, not via DevPanel or boss mode).
- **FR-006**: The current run MUST remain active after Continue — `RunManager.is_run_active` stays `true`, `run_currency` and all run stats are preserved.
- **FR-007**: `RoomLoader` MUST expose a public method to load a specific room by ID (reusing existing `_load_room` logic) so `Main.gd` can trigger the return without bypassing access modifiers.

### Key Entities

- **Return Room ID**: The `room_id` string of the dungeon room the player occupied immediately before pressing the boss teleport button. Stored on `Main.gd` for the duration of the boss encounter; cleared on run start and run end.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Pressing "Continue" after defeating the boss returns the player to the correct dungeon room in a single tap with no visible delay beyond normal room load time.
- **SC-002**: The return room loads with enemies absent (room was already cleared — `is_room_cleared` returns true), doors visible, and the run state (essence, rooms cleared count) unchanged from before the boss teleport.
- **SC-003**: "Continue" is absent or disabled in every non-endless path (boss mode, DevPanel direct boss start with no prior room), producing no error or crash.
- **SC-004**: Cash Out behaviour is unaffected — pressing "Cash Out" after a boss kill still ends the run and shows the results screen correctly.

## Assumptions

- `RoomLoader._load_room` will be exposed as a public method `load_room(room_id, entry_direction)`. No scene or resource changes are needed; the existing loading pipeline handles cleared rooms correctly via `RunManager.is_room_cleared`.
- The boss room is always at a fixed world position outside the dungeon grid; freeing it before calling `load_room` on the return room is safe and mirrors the existing `free_current_room` pattern.
- No camera or transition effect is required for the return teleport — same instant placement used throughout the game.
- `Main.gd` tracks the return room ID in a new field `_boss_return_room_id: String`; it is set in `_on_boss_teleport_pressed()` and cleared in `_on_run_started()` / `_on_run_ended()`.
