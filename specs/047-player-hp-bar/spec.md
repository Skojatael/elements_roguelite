# Feature Specification: Player HP Bar

**Feature Branch**: `047-player-hp-bar`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "add simple hp bar. it should be a straight rectangle that changes its length based on current player hp. there should be on overlsy on it that displays current/max hp"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See Health at a Glance (Priority: P1)

While exploring the dungeon or fighting enemies, the player needs to monitor their current health so they can make tactical decisions (retreat, use healing, or push forward).

**Why this priority**: Core gameplay feedback. Without visible HP, the player cannot assess risk or react to damage — foundational to combat readability.

**Independent Test**: Run the game, enter a combat room, take damage. The bar visually shortens and the numeric text updates. Fully testable with a live enemy.

**Acceptance Scenarios**:

1. **Given** the player is in a run, **When** the ExplorationHUD is visible, **Then** the HP bar is displayed showing a filled rectangle proportional to current HP out of max HP.
2. **Given** the player takes damage, **When** health decreases, **Then** the bar length shrinks immediately in proportion to the new HP value without delay.
3. **Given** the player has full health, **When** the HUD is shown, **Then** the bar is fully filled (100% width).
4. **Given** the player is at 1 HP, **When** the HUD is shown, **Then** the bar shows a very small but non-zero filled segment.

---

### User Story 2 - Read Exact HP Values (Priority: P2)

The player wants to know their precise HP numbers (e.g., "47 / 100") rather than estimating from the bar alone.

**Why this priority**: The numeric overlay removes ambiguity, especially at low health when bar width is hard to judge.

**Independent Test**: Check that the label on the bar reads "current / max" and updates correctly when health changes.

**Acceptance Scenarios**:

1. **Given** the player has 47 out of 100 HP, **When** looking at the HP bar, **Then** the overlay label reads "47 / 100".
2. **Given** max health changes (e.g., relic applied), **When** viewing the bar, **Then** both the bar fill and the label reflect the new max health.
3. **Given** the player is at full health, **When** looking at the bar, **Then** the label reads "[max] / [max]" (e.g., "100 / 100").

---

### Edge Cases

- What happens when HP drops to exactly 0? Bar shows empty / zero-width fill; label reads "0 / [max]".
- What if max health changes mid-run (relic)? Bar fill ratio and label both update to reflect new max.
- What if the player is in the hub (no active run)? HP bar still displays since StatsComponent is always active — no special hiding required unless decided otherwise.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The HP bar MUST be a horizontal rectangle whose filled width scales linearly with `current_hp / max_hp`.
- **FR-002**: The HP bar MUST update immediately whenever the player's health changes.
- **FR-003**: The HP bar MUST display a text overlay showing `current_hp / max_hp` as integer values.
- **FR-004**: The HP bar MUST be visible during active gameplay (when ExplorationHUD is shown).
- **FR-005**: The HP bar MUST react to max health changes (e.g., from relics) and re-scale accordingly.
- **FR-006**: The bar fill MUST never exceed 100% width or go below 0% width regardless of incoming values.

### Key Entities

- **HP Bar**: Visual element with a background rectangle (full width) and a foreground fill rectangle (width proportional to HP ratio).
- **HP Label**: Text overlay on the bar displaying `[current] / [max]` in integer format.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The HP bar fill updates within the same frame that health changes — no visible lag.
- **SC-002**: The numeric label always matches the actual HP values reported by StatsComponent — zero tolerance for stale display.
- **SC-003**: The bar fill width is exactly proportional to `current_hp / max_hp` — visually verifiable at 0%, 50%, and 100% health states.
- **SC-004**: After a relic increases max health, both bar fill and label reflect the new max without requiring a scene reload.

## Assumptions

- HP bar lives inside `ExplorationHUD` (the existing in-run HUD) since that is where gameplay UI elements reside.
- HP values are displayed as integers (floored), consistent with the existing numeric display conventions in the project.
- No animation (smooth lerp) on the bar fill — it snaps to the new value immediately, matching the "simple" intent.
- A single background ColorRect (empty bar) and a foreground ColorRect (fill) are sufficient — no gradient or texture required.
- The bar is always visible while ExplorationHUD is shown; it is not hidden between rooms or during transitions.
