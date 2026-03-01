# Feature Specification: Run End Screen

**Feature Branch**: `015-run-end-screen`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "when run ends, a static screen with run info is shown instead of the room. no exploration hud is available on this screen. it displays text with data like 'essence found' which ties to currency cashed out, enemies slain, rooms cleared. there should be a button that says 'return' that leads to the hub screen."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - View Run Summary on Run End (Priority: P1)

When a run ends for any reason (the player died or cashed out), the dungeon is torn down and a dedicated results screen replaces it. The player can read their performance stats for that run before leaving.

**Why this priority**: The summary screen is the core of this feature — the stats and the return button are both meaningless without it. It is also the natural closure moment of the run loop.

**Independent Test**: Trigger `end_run()` (by dying or via DevPanel cash-out). Confirm the dungeon is gone and a static results screen is the only thing visible. Confirm all three stat lines display correct values matching the run. Confirm the ExplorationHUD is not visible.

**Acceptance Scenarios**:

1. **Given** a run is active, **When** the run ends for any reason, **Then** the dungeon root is freed and a results screen is shown in its place.
2. **Given** the results screen is visible, **Then** it displays the amount of essence cashed out for that run.
3. **Given** the results screen is visible, **Then** it displays the number of enemies slain during that run.
4. **Given** the results screen is visible, **Then** it displays the number of rooms cleared during that run.
5. **Given** the results screen is visible, **Then** the ExplorationHUD is not visible.
6. **Given** the run ended with reason DIED, **Then** the cashed-out essence shown reflects the 85%-floored penalty amount.
7. **Given** the run ended with reason CASH_OUT, **Then** the cashed-out essence shown is the full accumulated amount.

---

### User Story 2 - Return to Hub from Results Screen (Priority: P1)

From the results screen, the player taps a "Return" button and is taken back to the hub, ready to start a new run.

**Why this priority**: Without a return path the player is stuck on the results screen. Both stories together form the minimum viable run loop closure.

**Independent Test**: On the results screen, tap "Return". Confirm the results screen is freed and the hub is the active scene. Confirm the player can start a new run from the hub.

**Acceptance Scenarios**:

1. **Given** the results screen is visible, **Then** a button labelled "Return" is present and tappable.
2. **Given** the player taps "Return", **Then** the results screen is freed and the hub screen is shown.
3. **Given** the player is back at the hub after returning, **Then** the game state is clean and a new run can be started normally.

---

### Edge Cases

- What if the run ends with 0 essence, 0 enemies slain, or 0 rooms cleared? All three stats display as zero — no crash, no missing labels.
- What if the run ends via DevPanel while not in a room (e.g., still in hub)? Screen should still appear; stats display zero or current values without error.
- What if the player taps "Return" multiple times rapidly? Only one hub transition should occur — guard against double-activation.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When a run ends (any `EndReason`), the system MUST compute the run summary, free the dungeon root, and show the results screen.
- **FR-002**: The results screen MUST display the essence cashed out for that run (post-penalty amount).
- **FR-003**: The results screen MUST display the number of enemies slain during that run.
- **FR-004**: The results screen MUST display the number of rooms cleared during that run.
- **FR-005**: The ExplorationHUD MUST NOT be visible while the results screen is shown.
- **FR-006**: The results screen MUST contain a button labelled exactly "Return".
- **FR-007**: Tapping "Return" MUST free the results screen and return the player to the hub.
- **FR-008**: The hub shown after "Return" MUST be in a state that allows starting a new run.
- **FR-009**: RunManager MUST track the total number of enemies defeated during a run, resetting to 0 at `start_run()`.
- **FR-010**: At `end_run()`, the system MUST capture all summary values into a `RunSummary` snapshot before any scene teardown occurs. The results screen reads exclusively from this snapshot — never from live dungeon nodes or RunManager runtime state.

### Key Entities

- **Results Screen**: A dedicated scene shown after a run ends. Receives a `RunSummary` snapshot at display time and reads all stat values from it. Freed when the player returns to the hub.
- **RunSummary**: A lightweight data snapshot computed at `end_run()` from the `RunState` at that moment. Contains: `essence_cashed_out: int`, `enemies_slain: int`, `rooms_cleared: int`. Passed to the results screen on instantiation. Immutable after creation.
- **Enemies Slain**: Count of enemies defeated during the run. Tracked in RunManager, incremented on each enemy defeat, reset on `start_run()`. Copied into `RunSummary` at `end_run()`.
- **Rooms Cleared**: Count of distinct rooms cleared during the run. Derived from `RunState.cleared_rooms` at `end_run()` time. Copied into `RunSummary`.
- **Cashed-out Essence**: The final essence amount awarded at run end (full amount for CASH_OUT, 85% floored for DIED). Computed at `end_run()` and stored in `RunSummary`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The results screen appears on 100% of run-end events with no exceptions.
- **SC-002**: All three stat values displayed are accurate — matching the actual run data — verifiable by manual comparison against Output log.
- **SC-003**: Tapping "Return" always transitions the player to the hub with no leftover run state visible in the UI.
- **SC-004**: The ExplorationHUD is never visible simultaneously with the results screen.
- **SC-005**: The results screen never reads from live dungeon nodes — all data comes from the `RunSummary` snapshot, verifiable by confirming the dungeon root is freed before the screen is populated.

## Assumptions

- The dungeon root is freed immediately at `end_run()` time, before the results screen is shown. The results screen therefore has no access to dungeon nodes and must rely entirely on the `RunSummary` snapshot.
- The results screen is instantiated and added to the main scene (or shown via scene change) at `end_run()` — not as an overlay on a live dungeon.
- No animations or transitions are required in this iteration — the screen appears immediately on run end.
- The three stats (essence, enemies, rooms) are displayed as plain labelled text. No icons, charts, or visual decoration required in this iteration.
- "Enemies slain" is a new counter added to RunManager, incremented in `_on_enemy_defeated()` and reset in `start_run()`.

## Out of Scope

- Animations, transitions, or particle effects on the results screen.
- Per-room or per-enemy breakdowns.
- Leaderboard or persistent high-score comparison.
- "Play Again" shortcut — player must go through the hub.
- Visual theming or art assets beyond placeholder text and button.
