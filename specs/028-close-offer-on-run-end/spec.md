# Feature Specification: Close Relic Offer on Run End

**Feature Branch**: `028-close-offer-on-run-end`
**Created**: 2026-03-03
**Status**: Draft
**Input**: User description: "if run is stopped when a relic offer is open, close the relic offer"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Relic Offer Is Automatically Dismissed When a Run Ends (Priority: P1)

A player is looking at the relic offer screen choosing between two relics. Before they pick, the run ends — either the player dies (their HP hits zero) or the run is ended via another path. The relic offer screen disappears automatically and the normal run-end flow proceeds: the results screen appears cleanly.

**Why this priority**: Without this, the relic offer screen stays open on top of (or behind) the results screen when the run ends. This is a broken UI state that blocks the player and leaves orphaned elements.

**Independent Test**: Open a relic offer (via DevPanel "Get Relic"). While the offer is visible, trigger run end (via DevPanel "End Run"). Verify the relic offer disappears and the results screen appears cleanly with no frozen or overlapping UI.

**Acceptance Scenarios**:

1. **Given** a relic offer screen is open, **When** the player dies (HP reaches zero), **Then** the relic offer screen is dismissed and the results screen appears.
2. **Given** a relic offer screen is open, **When** the run is ended by any other means (cash-out, DevPanel), **Then** the relic offer screen is dismissed and the results screen appears.
3. **Given** no relic offer screen is open, **When** the run ends, **Then** run-end behavior is identical to before this feature — no regressions.
4. **Given** the relic offer was dismissed due to run end, **Then** no relic is awarded — the dismissal is silent with no relic collection side-effect.

---

### Edge Cases

- What if the run ends at the exact same moment the player taps a relic card? The run-end takes priority; no relic is collected.
- What if the relic offer has already been closed by normal player interaction before the run end processes? No double-free occurs — the dismissal is a safe no-op when no offer is open.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: When a run ends for any reason while a relic offer screen is open, the relic offer screen MUST be dismissed immediately before the run-end UI (results screen) is shown.
- **FR-002**: Dismissing the relic offer due to run end MUST NOT award any relic to the player.
- **FR-003**: Dismissing the relic offer due to run end MUST restore any UI state that was hidden when the offer was shown (e.g., the exploration HUD, if applicable — though this is superseded by the run-end flow).
- **FR-004**: When no relic offer is open at run end, the run-end flow MUST behave identically to before this feature.
- **FR-005**: The dismissal MUST be safe to call even if no relic offer is currently open — it must not crash or produce errors.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of tests where a run ends while a relic offer is open, the relic offer disappears and the results screen appears with no overlapping or frozen UI elements.
- **SC-002**: In 100% of tests where a run ends without a relic offer open, the run-end behavior is unchanged from before this feature.
- **SC-003**: Zero crashes or errors occur when run end is triggered in any relic offer state (open, closed, or never opened).

## Assumptions

- "Run stopped" means any path through `RunManager.end_run()` — player death, cash-out, or DevPanel trigger. All three paths should dismiss the offer.
- The relic offer dismissal at run end is silent — no animation, no log line required beyond what's already there.
- The exploration HUD visibility does not need special handling at run end since the results screen replaces all gameplay UI anyway.
