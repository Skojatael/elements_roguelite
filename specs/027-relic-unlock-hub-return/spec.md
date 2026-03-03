# Feature Specification: Relic Offers Activate on Hub Return

**Feature Branch**: `027-relic-unlock-hub-return`
**Created**: 2026-03-03
**Status**: Draft
**Input**: User description: "do not offer relic upgrades until first return to hub after clearing elite room"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Relic Offers Withheld Until Hub Return After Unlock (Priority: P1)

A player clears an elite room for the first time, unlocking the Adventurer Bag. No relic offers appear in that run — even on subsequent room clears. The player finishes the run and returns to the hub. From that hub visit onward, relic offers appear normally in every future run.

**Why this priority**: This is the entire feature. Delivering it gives the player a clear moment of discovery — they earn the unlock in one run, they activate it by returning to the hub, and then relics become part of their game from the next run forward.

**Independent Test**: Fresh profile → earn Adventurer Bag (clear elite room) → continue clearing rooms in the same run → confirm zero relic offers appear → end run → return to hub → start a new run → clear 2 standard rooms → confirm relic offer appears.

**Acceptance Scenarios**:

1. **Given** the Adventurer Bag was just unlocked in the current run, **When** the player clears more rooms in that same run, **Then** no relic offers appear.
2. **Given** the Adventurer Bag is unlocked but the player has not yet returned to the hub, **When** the player starts a new run (e.g., immediately re-runs without visiting hub), **Then** no relic offers appear in that run either.
3. **Given** the player returns to the hub after the Adventurer Bag unlock, **When** they start the next run, **Then** relic offers appear on qualifying room clears.
4. **Given** relic offers are already active (hub return occurred in a previous session), **When** the player starts any run, **Then** relic offers appear normally — the activation state persists.

---

### User Story 2 — Backward Compatibility for Existing Saves (Priority: P2)

A player who already had the Adventurer Bag unlocked before this feature is in place should not be permanently locked out of relic offers. Their first hub visit after the update applies activates relic offers.

**Why this priority**: Without this, existing players who already unlocked the Adventurer Bag would never see relic offers (they already passed the elite-clear gate but can't "return to hub for the first time" again). This is a one-time migration concern.

**Independent Test**: Simulate a save file with `adventurer_bag_unlocked: true` but `relic_offers_active: false` → enter play mode → visit hub → start a run → verify relic offers appear.

**Acceptance Scenarios**:

1. **Given** a save with Adventurer Bag already unlocked and no recorded hub return, **When** the player visits the hub, **Then** relic offers become active.
2. **Given** a save with Adventurer Bag already unlocked and hub return already recorded, **When** the player starts a run, **Then** relic offers appear immediately (no second hub visit required).

---

### Edge Cases

- What if the player quits to desktop in the middle of a run (after elite clear, before hub return)? The activation state is not yet set — they must still complete a hub visit before offers begin.
- What if the player clears a second elite room in a subsequent run before ever returning to hub? Hub return is still required; multiple elite clears do not bypass it.
- What if the Adventurer Bag is not yet unlocked when the player visits the hub? Hub visits before the unlock have no effect — the activation only begins tracking once the Adventurer Bag is unlocked.
- What if the player dies and the run ends automatically? Dying ends the run and transitions back to the hub — this counts as a hub return and activates relic offers if the Adventurer Bag was already unlocked.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Relic offers MUST NOT be generated in any run in which the Adventurer Bag was unlocked, regardless of how many rooms are cleared after the unlock in that run.
- **FR-002**: Relic offers MUST NOT be generated in any subsequent run until the player has completed at least one hub visit following the Adventurer Bag unlock.
- **FR-003**: Relic offers MUST activate permanently on the player's first hub visit after the Adventurer Bag is unlocked. The activation MUST persist across sessions.
- **FR-004**: A run ending by any means (cash-out or death) that transitions the player to the hub counts as a qualifying hub visit for FR-003.
- **FR-005**: For saves where the Adventurer Bag is already unlocked (from feature 026), the next hub visit MUST activate relic offers — no special migration action required from the player.
- **FR-006**: Once relic offers are active, they behave identically to the existing relic offer system — this feature adds only the activation gate.

### Key Entities

- **Adventurer Bag unlock** (`adventurer_bag_unlocked: bool`): Existing flag — set on first elite clear. Unchanged.
- **Relic offers active** (`relic_offers_active: bool`): New persistent flag — set on the first hub visit after `adventurer_bag_unlocked` becomes `true`. This flag (not `adventurer_bag_unlocked`) is what gates relic offer generation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Zero relic offers appear in any run during which the Adventurer Bag was first unlocked, across all test scenarios.
- **SC-002**: Zero relic offers appear in runs started before the first post-unlock hub visit, regardless of run count.
- **SC-003**: After the first post-unlock hub visit, relic offers appear in 100% of qualifying room clears in all subsequent runs.
- **SC-004**: The activation state survives a full game restart — verified by quitting after the hub visit and confirming relic offers on the next session.
- **SC-005**: Players with existing saves (Adventurer Bag already unlocked) receive relic offers after their next hub visit with no additional steps.

## Assumptions

- "Returning to the hub" means the player reaches the HubRoom scene — which happens at the end of every run (whether the player cashes out or dies), and at game start.
- The game always starts in the hub, so the very first game session does NOT count as a post-unlock hub visit (the unlock has not happened yet at that point). Only hub visits that occur while `adventurer_bag_unlocked = true` count.
- `relic_offers_active` is a separate persisted field from `adventurer_bag_unlocked` — this keeps concerns distinct and enables US2 backward compatibility cleanly.
- No UI notification for this activation is in scope for this feature.
