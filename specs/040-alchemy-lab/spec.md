# Feature Specification: Alchemy Lab

**Feature Branch**: `040-alchemy-lab`
**Created**: 2026-03-13
**Status**: Draft
**Input**: User description: "add a new building similar to Magic Forge. it has to have the same ruined/restored state, same restore overlay (cost 500 shards), and upgrade overlay after restoration. the first upgrade that should be in the building is essence gain % increase (+5% on first level, no cost right now, button disabled). keep all costs and percentages data driven, as with other upgrades and buildings. the building name is Alchemy Lab."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Restore the Alchemy Lab (Priority: P1)

A player who has accumulated enough shards visits the hub and sees the Alchemy Lab in its ruined state. They tap on it, are shown a restore overlay displaying the shard cost, and confirm. The building visually transitions to its restored state and remains restored in all future sessions.

**Why this priority**: The building must exist and be restorable before any upgrades are accessible. This is the foundational gate for the entire feature.

**Independent Test**: Can be tested fully by tapping the ruined building, confirming restoration, and verifying the visual change and persistence across a session restart.

**Acceptance Scenarios**:

1. **Given** the Alchemy Lab is ruined and the player has fewer shards than the restore cost, **When** the player taps the building, **Then** the restore button in the overlay is disabled.
2. **Given** the Alchemy Lab is ruined and the player has enough shards, **When** the player confirms restoration, **Then** the shard cost is deducted, the building switches to its restored visual, and the state persists.
3. **Given** the Alchemy Lab is already restored, **When** the player taps the building, **Then** the upgrade screen opens instead of the restore overlay.
4. **Given** the player dismisses the restore overlay via "Maybe Later", **When** they return to the hub, **Then** the building is still ruined and no shards have been spent.

---

### User Story 2 - View Essence Gain Upgrade (Priority: P2)

A player with a restored Alchemy Lab opens the upgrade screen and sees the Essence Gain upgrade entry. Because no cost has been set yet for the first level, the purchase button is disabled. The player can read the upgrade description and the bonus it would grant.

**Why this priority**: The upgrade screen must be functional and display accurate data even when a purchase is not yet possible. This validates the data-driven display pipeline before any actual purchasing is implemented.

**Independent Test**: Can be tested by opening the upgrade screen on a restored lab and confirming the Essence Gain entry appears with correct values and a disabled button.

**Acceptance Scenarios**:

1. **Given** the Alchemy Lab is restored, **When** the player opens it, **Then** the upgrade screen shows an Essence Gain upgrade entry with its name, current bonus, and a disabled purchase button.
2. **Given** the Essence Gain upgrade is at level 0, **When** the screen is displayed, **Then** the shown bonus at level 1 is +5% (sourced from config, not hardcoded).
3. **Given** the upgrade is unpurchasable (disabled button), **When** the player taps the button, **Then** nothing happens and no shards are spent.

---

### Edge Cases

- What happens when the player taps the building before the hub has fully loaded?
- How does the restore overlay behave if the player spends shards elsewhere (e.g., Magic Forge) while the overlay is open and can no longer afford restoration?
- What if the config entry for the Essence Gain upgrade is missing or malformed — does the game degrade gracefully rather than crash?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The hub MUST contain an Alchemy Lab building with two distinct visual states: Ruined and Restored.
- **FR-002**: Tapping the Alchemy Lab in its Ruined state MUST open a restore overlay showing the shard cost and a confirm button.
- **FR-003**: The restore button in the overlay MUST be disabled when the player cannot afford the cost.
- **FR-004**: Confirming restoration MUST deduct the correct shard amount and permanently switch the building to its Restored state, persisted across sessions.
- **FR-005**: Tapping the Alchemy Lab in its Restored state MUST open an upgrade screen.
- **FR-006**: The upgrade screen MUST list the Essence Gain upgrade with its name, level, bonus per level, and a purchase button.
- **FR-007**: The Essence Gain upgrade purchase button MUST be disabled at all times in this iteration (no cost assigned yet).
- **FR-008**: All costs and percentage values (restoration cost, bonus per level) MUST be read from the data config and not hardcoded.
- **FR-009**: The Alchemy Lab's restored state MUST be persisted in the same save file as other meta-progression data.
- **FR-010**: The upgrade screen MUST update its displayed values immediately if the player's shard balance changes while the screen is open.

### Key Entities

- **Alchemy Lab**: Hub building with Ruined/Restored states. Interactable via tap. Drives two distinct UI flows depending on state.
- **Essence Gain Upgrade**: A single-level upgrade tracked in meta-progression. Defines a percentage bonus applied to essence earned during runs. Values sourced from config.
- **Restore Overlay**: Modal shown when tapping the ruined building. Displays cost, handles affordability check, and triggers the purchase.
- **Upgrade Screen**: Panel shown when tapping the restored building. Lists available upgrades with their current level, next-level bonus, and purchase action.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The Alchemy Lab building appears in the hub in all sessions, in the correct visual state (Ruined or Restored) matching the player's save data.
- **SC-002**: 100% of cost and percentage values are sourced from config — changing a value in config is reflected in-game without any code change.
- **SC-003**: The restore flow completes (overlay open → confirm → visual change) in a single tap confirmation with no additional steps.
- **SC-004**: The building's restored state is never lost across session restarts — 0 regressions in persistence after save/load cycles.
- **SC-005**: The Essence Gain upgrade entry displays the correct +5% level-1 bonus as defined in config, with no discrepancy between config value and displayed value.

## Assumptions

- The Alchemy Lab uses the same restore overlay scene and upgrade screen pattern as Magic Forge — reuse or extend existing scenes rather than creating entirely new ones.
- The restore cost is 500 shards, stored in `data/meta_config.json` under a nested `alchemy_lab` key (consistent with the `magic_forge` / `mage_tower` structure).
- The Essence Gain upgrade has `max_levels: 1`, `base_cost: 0`, and `essence_per_level: 0.05` (5%) in config. Cost of 0 is the signal to disable the button.
- Essence Gain bonus is applied multiplicatively to run essence earnings (e.g., at level 1: all earned essence × 1.05).
- The Alchemy Lab's unlocked state is stored as a new boolean field in `MetaState` (e.g., `alchemy_lab_unlocked`), following the same pattern as `mage_tower_unlocked`.
- No new save file format migration is needed — missing fields default to `false`/`0` for backward compatibility, consistent with the existing save system.
- The "Maybe Later" / dismiss path on the restore overlay leaves the building unchanged, matching Magic Forge behaviour.
