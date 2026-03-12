# Feature Specification: Boss Challenge Gate

**Feature Branch**: `038-boss-challenge-gate`
**Created**: 2026-03-12
**Status**: Draft
**Input**: User description: "add a gate for boss challenge unlock. on first boss kill, set flag first boss killed. for player, a popup should be shown with custom text and okay button. if the relic system is already unlocked, the popup should be shown after the relic is chosen (maybe hide the popup behind relic offer screen). if the flag is false, button for boss challenge unlock should be disabled with new text: 'Major essence required'. make sure this doesn't break existing button display/disable mechanism"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - First Boss Kill Unlocks Gate (Priority: P1)

A player kills the boss for the first time in an endless run. After the victory sequence concludes, a popup appears acknowledging the achievement with a brief message and an OK button. From that point on, the Boss Challenge entry in the Mage Tower becomes purchasable — the player still needs to spend shards to unlock it.

**Why this priority**: The gate flag is the foundation — without it, neither the popup nor the button state change can be tested. It is also the simplest slice to verify.

**Independent Test**: Kill the boss in an endless run for the first time. Confirm the `first_boss_killed` flag is set and persists after an app restart.

**Acceptance Scenarios**:

1. **Given** the player has never killed the boss, **When** the boss room is cleared in an endless run, **Then** the `first_boss_killed` flag is set and saved to persistent storage.
2. **Given** `first_boss_killed` is already true, **When** the boss is killed again, **Then** the flag remains true and no duplicate popup or state change occurs.
3. **Given** the flag was set in a previous session, **When** the game is restarted, **Then** the flag is still true and the Boss Challenge button is in the purchasable state.

---

### User Story 2 - Boss Kill Popup (No Relics) (Priority: P2)

After killing the boss for the first time in a run where the relic system has not been unlocked, a popup appears immediately after the boss room is cleared. The popup shows a short message acknowledging the kill and informing the player that Boss Challenge Mode can now be purchased in the Mage Tower. An OK button dismisses it.

**Why this priority**: The popup is the primary player-facing feedback for the gate unlock. The no-relic case is simpler and forms the baseline.

**Independent Test**: Kill the boss for the first time with relic system inactive. Confirm the popup appears before the boss victory overlay.

**Acceptance Scenarios**:

1. **Given** it is the first boss kill and relics are not active, **When** the boss room is cleared, **Then** the popup appears with a message and an OK button.
2. **Given** the popup is visible, **When** the player taps OK, **Then** the popup closes and the normal post-boss flow continues (victory overlay).
3. **Given** it is not the first boss kill, **When** the boss room is cleared, **Then** no popup appears.

---

### User Story 3 - Boss Kill Popup After Relic Offer (Priority: P3)

When the relic system is active, the boss kill triggers a rare relic offer before the victory overlay. In this case the popup must appear after the player picks their relic — not before — so it does not interrupt the relic selection flow.

**Why this priority**: Ordering matters for experience correctness; the relic offer must resolve first.

**Independent Test**: Kill the boss for the first time with relic system active. Confirm the relic offer appears first, then the popup on relic pick, then the victory overlay.

**Acceptance Scenarios**:

1. **Given** it is the first boss kill and relics are active, **When** the boss room is cleared, **Then** the relic offer appears first; the popup is not yet visible.
2. **Given** the relic offer is shown, **When** the player picks a relic, **Then** the popup appears before the victory overlay.
3. **Given** the popup is visible after relic pick, **When** OK is tapped, **Then** the popup closes and the boss victory overlay appears.

---

### User Story 4 - Boss Challenge Button Gated (Priority: P4)

Before the first boss kill, the Boss Challenge entry in the Mage Tower upgrade screen shows "Major essence required" and is non-interactive, regardless of the player's shard balance. After the first boss kill the entry reverts to the standard cost display and affordability rules.

**Why this priority**: Pure UI gate — no new persistence required; depends on US1's flag.

**Independent Test**: Open the Mage Tower upgrade screen before and after the first boss kill. Confirm button text and disabled state change correctly in both cases.

**Acceptance Scenarios**:

1. **Given** `first_boss_killed` is false, **When** the upgrade screen is opened, **Then** the Boss Challenge entry shows "Major essence required" and is disabled.
2. **Given** `first_boss_killed` is false and the player has sufficient shards, **When** the upgrade screen is opened, **Then** the Boss Challenge entry still shows "Major essence required" and is disabled (shard balance is irrelevant).
3. **Given** `first_boss_killed` is true and Boss Challenge is not yet purchased, **When** the upgrade screen is opened, **Then** the entry shows the normal cost text and respects affordability.
4. **Given** `first_boss_killed` is true and Boss Challenge is already purchased, **When** the upgrade screen is opened, **Then** the entry shows "Unlocked" — unchanged from existing behaviour.
5. **Given** the upgrade screen is open when the first boss kill occurs in the same session, **When** the player returns to the hub and reopens the screen, **Then** the entry now shows the normal cost display.

---

### Edge Cases

- What if the player kills the boss but closes the game before the popup is dismissed? The flag is already saved on kill; the popup should not reappear on next launch.
- What if the relic offer produces no rare relics (fallback path)? The popup must still appear at the correct point in the post-boss flow.
- What if Boss Challenge Mode is already purchased when the first boss kill occurs? The popup should still appear (it acknowledges the kill, not the unlock), but the button state is already "Unlocked" and unchanged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `first_boss_killed` flag MUST be set and persisted on the first endless-mode boss room clear. (Note: this flag already exists in `MetaState` and is set by `MetaManagerImpl.record_boss_kill()` — this feature reuses it without duplication.)
- **FR-002**: A one-time popup MUST appear to the player after their first boss kill, containing a short descriptive message and a single OK button.
- **FR-003**: The popup MUST appear only once — never on subsequent boss kills.
- **FR-004**: When the relic system is inactive, the popup MUST appear immediately after the boss room is cleared, before the boss victory overlay.
- **FR-005**: When the relic system is active, the popup MUST appear after the player selects their post-boss relic, before the boss victory overlay.
- **FR-006**: Tapping OK on the popup MUST close it and resume the normal post-boss flow.
- **FR-007**: The popup message text MUST be read from `data/meta_config.json` so it can be changed without code edits.
- **FR-008**: When `first_boss_killed` is false, the Boss Challenge entry in the Mage Tower upgrade screen MUST display the text "Major essence required" and be non-interactive.
- **FR-009**: When `first_boss_killed` is false, shard balance MUST NOT influence the Boss Challenge button state — it is always disabled.
- **FR-010**: The existing button display logic for all other upgrade entries (Dungeon Expansion, Relic System) MUST be unaffected by this change.
- **FR-011**: The existing Unlocked display state for Boss Challenge MUST be unaffected when `boss_run_unlocked` is true.

### Key Entities

- **First Boss Kill Flag**: Boolean persisted across sessions. True after the first endless-mode boss clear. Already part of meta-progression storage.
- **Boss Kill Popup**: A one-time overlay with a message (sourced from config) and an OK button. Transient — not persisted.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After the first boss kill, the Boss Challenge entry transitions from "Major essence required" to the normal cost display within the same session — no restart required.
- **SC-002**: The popup appears exactly once across all runs; killing the boss a second time produces no popup.
- **SC-003**: When relics are active, the popup never interrupts the relic selection screen — it appears only after a relic is chosen.
- **SC-004**: The "Major essence required" state correctly blocks purchase attempts regardless of shard balance — no edge case allows the button to become interactive before the first boss kill.
- **SC-005**: All other Mage Tower upgrade entries continue to display and behave identically to before this feature.

## Assumptions

- `first_boss_killed` is already recorded by `MetaManagerImpl.record_boss_kill()` on boss room clear in endless mode. This feature adds the popup and button gate on top of the existing flag — no change to when or how the flag is set.
- The popup message is a single static string (not formatted with dynamic values). Stored under `mage_tower.first_boss_killed.popup_message` in `meta_config.json` — keyed under the kill event, not the unlock, because the popup acknowledges the kill and the purchase is still required separately.
- The popup is a new lightweight scene (Control root + Label + Button), following the same CanvasLayer pattern used by other hub overlays. It does not reuse `BossVictoryOverlay` or any existing overlay.
- The popup appears in the post-boss flow managed by `Main.gd`. No changes to `RoomSpawner`, `RunManager`, or `MetaManager` are required beyond wiring the display call.
- The `_apply_entry` mechanism in `MageTowerUpgradeScreen` is extended to support a `gate_prop` key per entry — when the gate property is false, the button shows the gate text instead of the cost text and is always disabled. Entries without a `gate_prop` are unaffected.
