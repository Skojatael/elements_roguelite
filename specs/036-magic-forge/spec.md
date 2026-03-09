# Feature Specification: Magic Forge

**Feature Branch**: `036-magic-forge`
**Created**: 2026-03-07
**Status**: Draft
**Input**: User description: "create a 'building' (it will later have building drawing in ui) that is called 'Magic Forge'. this building should be an upgrade hub for run upgrades like damage % increase. the ui should be a zone that, when pressed on, first opens a small overlay with two buttons 'restore the forge (120 shards)' (unlock the upgrade tree) and 'maybe later' (close the overlay). if unlock is purchased, the player gets a new screen with upgrade buttons like damage %. the forge should be in the top center part of the hub. when the forge is not unlocked, the ui should show 'ruined forge' (right now, a black colorrect that can be interacted with), when the forge is unlocked, ui should show 'magic forge' (right now, a grey colorrect that will give you upgrade screen on interaction)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Player Unlocks the Magic Forge (Priority: P1)

A player with enough shards visits the hub and sees the Ruined Forge at the top-center of the hub. They tap it, a small overlay appears offering to restore it for 120 shards. They tap "Restore the Forge", the shards are deducted, and the building visually changes to the Magic Forge. The overlay closes. From this point on, tapping the forge always opens the upgrade screen directly.

**Why this priority**: The unlock is the gateway to all forge functionality — without it, upgrade purchases are inaccessible.

**Independent Test**: Can be tested by tapping the Ruined Forge, purchasing the restoration, and confirming the visual changes and shards are deducted correctly.

**Acceptance Scenarios**:

1. **Given** the forge is not yet unlocked, **When** the player taps the forge zone, **Then** a small overlay appears with "Restore the Forge (120 shards)" and "Maybe Later" buttons.
2. **Given** the overlay is open and the player has ≥ 120 shards, **When** "Restore the Forge" is tapped, **Then** 120 shards are deducted, the overlay closes, and the forge visual changes from black (Ruined) to grey (Magic).
3. **Given** the overlay is open and the player has < 120 shards, **When** "Restore the Forge" is tapped, **Then** nothing happens (the button is disabled or has no effect and the player cannot proceed).
4. **Given** the overlay is open, **When** "Maybe Later" is tapped, **Then** the overlay closes with no changes.
5. **Given** the forge has been unlocked in a previous session, **When** the player returns to the hub, **Then** the forge still shows as the Magic Forge (unlock persists across sessions).

---

### User Story 2 - Player Purchases Run Upgrades at the Forge (Priority: P2)

With the forge unlocked, the player taps the Magic Forge and a full upgrade screen opens. They see the available run upgrades (starting with damage %). They can spend shards to purchase upgrade levels, and the upgrade takes effect in future runs.

**Why this priority**: This is the core utility of the forge — spending the persistent upgrade progression that the meta-system tracks.

**Independent Test**: Can be tested by tapping the Magic Forge, purchasing a damage upgrade level, and confirming the shard cost is deducted and the upgrade level increases.

**Acceptance Scenarios**:

1. **Given** the forge is unlocked, **When** the player taps the Magic Forge zone, **Then** the upgrade screen opens directly (no intermediate overlay).
2. **Given** the upgrade screen is open and the player can afford the next damage upgrade level, **When** the upgrade button is tapped, **Then** shards are deducted, the damage upgrade level increments, and the displayed cost updates to the next level cost.
3. **Given** the upgrade screen is open and the player cannot afford the next level, **Then** the upgrade button is visually disabled or grayed out.
4. **Given** the damage upgrade is at max level, **Then** the upgrade button is replaced by a "Maxed" indicator.
5. **Given** the upgrade screen is open, **When** the player taps a close/back button, **Then** the screen closes and the player returns to the hub.

---

### User Story 3 - Player Cannot Afford Restoration (Priority: P3)

A player who does not yet have 120 shards visits the hub and taps the Ruined Forge. The overlay appears but the "Restore the Forge" button is disabled (or non-functional), making it clear they need more shards.

**Why this priority**: Important for feedback but does not block the core flows above.

**Independent Test**: Can be tested by having fewer than 120 shards and attempting to restore the forge.

**Acceptance Scenarios**:

1. **Given** the forge is locked and the player has < 120 shards, **When** the restore overlay opens, **Then** the "Restore the Forge" button is visually disabled.

---

### Edge Cases

- What happens if the player spends shards mid-hub (e.g., buys an Adventuring Gear) and can no longer afford forge restoration? The overlay's button state should reflect the current shard balance, not a stale value.
- What if the forge is locked and the player opens the overlay, then gains shards (not possible mid-overlay, so not a concern — hub is a single-frame context).
- The upgrade screen should handle the case where the damage upgrade is at max level gracefully (no crash, clear "Maxed" state).
- The forge unlock state must be re-checked on every hub visit (not cached from a previous run) to correctly show Ruined vs Magic.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The hub MUST contain a Magic Forge building zone positioned at the top-center of the hub.
- **FR-002**: When the forge is not yet unlocked, the zone MUST display a "Ruined Forge" state (black visual placeholder) and be interactable.
- **FR-003**: When the forge IS unlocked, the zone MUST display a "Magic Forge" state (grey visual placeholder) and be interactable.
- **FR-004**: Tapping the Ruined Forge zone MUST open a small restoration overlay.
- **FR-005**: The restoration overlay MUST contain a "Restore the Forge (120 shards)" button and a "Maybe Later" button.
- **FR-006**: The "Restore the Forge" button MUST be disabled when the player's current shard balance is below 120.
- **FR-007**: Successfully tapping "Restore the Forge" MUST deduct 120 shards, persist the forge-unlocked state, close the overlay, and switch the forge visual to the Magic Forge state.
- **FR-008**: Tapping "Maybe Later" MUST close the overlay with no side effects.
- **FR-009**: Tapping the Magic Forge zone (unlocked state) MUST open the forge upgrade screen directly, without showing the restoration overlay.
- **FR-010**: The forge upgrade screen MUST display the damage % upgrade with its current level, cost to next level, and a purchase button.
- **FR-011**: The damage upgrade purchase button MUST be disabled when the player cannot afford the next level.
- **FR-012**: When the damage upgrade is at maximum level, the purchase button MUST be replaced by a "Maxed" indicator.
- **FR-013**: The forge upgrade screen MUST have a close/back control that returns the player to the hub.
- **FR-014**: The forge unlock state MUST persist across game sessions (survives app restart).

### Key Entities

- **Magic Forge**: A hub building with two visual states (Ruined / Magic) and a persisted unlock flag. Unlocked once for 120 shards.
- **Forge Restoration Overlay**: A transient small UI panel shown only when the forge is locked. Contains two actions: restore and dismiss.
- **Forge Upgrade Screen**: A full hub screen showing available run upgrades. Reads live shard balance and upgrade levels; supports purchase interactions.
- **Forge Unlock State**: A boolean flag in meta-progression storage — false until the player purchases restoration, then permanently true.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player with ≥ 120 shards can unlock the forge and reach the upgrade screen in 2 taps or fewer.
- **SC-002**: The forge visual state (Ruined vs Magic) correctly reflects the persisted unlock state on every hub visit, including after app restart.
- **SC-003**: Purchasing a damage upgrade deducts the correct shard amount and increments the upgrade level within the same session (no stale data shown).
- **SC-004**: All interactive elements (restore button, upgrade button) correctly reflect affordability — disabled when the player lacks funds — with no false positives or negatives.
- **SC-005**: The upgrade screen closes cleanly and returns the player to the hub with no orphaned UI elements remaining on screen.

## Assumptions

- The damage % upgrade referenced is the existing damage upgrade already present in the meta-progression system (levels 0–10, variable shard cost per level). The forge screen exposes this existing system through a new UI entry point; no new upgrade type is introduced in this feature.
- The forge unlock cost of 120 shards is the only one-time cost; the upgrade purchases within the screen use the existing shard-spend flow.
- The forge zone is a new child node added to the existing Hub Room scene, positioned at the top-center (approximately `(0, -400)` in hub local space, to be tuned in the editor).
- The upgrade screen initially contains only the damage % upgrade. Additional upgrade types (attack speed, etc.) are out of scope for this feature and will be added in a future iteration.
- The forge cannot be unlocked more than once; the 120-shard cost is a one-time permanent unlock.
