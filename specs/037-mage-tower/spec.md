# Feature Specification: Mage Tower

**Feature Branch**: `037-mage-tower`
**Created**: 2026-03-09
**Status**: Draft
**Input**: User description: "similar to forge, let's introduce another building: 'Mage Tower', it should contain system unlocks: dungeon expansion, relic system, boss challenge mode. it also should have ruined mode (unlock mage tower for 200 shards/maybe later buttons) and restored mode (purchasable system upgrades/close button)"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Player Restores the Mage Tower (Priority: P1)

A player with enough shards visits the hub and sees the Ruined Mage Tower. They tap it, a small overlay appears offering to restore it for 200 shards. They tap "Restore the Mage Tower", the shards are deducted, and the building visually switches to its restored state. From this point on, tapping the tower always opens the system upgrades screen directly.

**Why this priority**: The tower restoration is the gateway to all system unlocks — without it, dungeon expansion, relics, and boss challenge mode are inaccessible through this screen.

**Independent Test**: Can be tested by tapping the Ruined Mage Tower, purchasing the restoration, and confirming the shard deduction and visual change.

**Acceptance Scenarios**:

1. **Given** the tower is not yet restored, **When** the player taps the tower zone, **Then** a small overlay appears with "Restore the Mage Tower (200 shards)" and "Maybe Later" buttons.
2. **Given** the overlay is open and the player has ≥ 200 shards, **When** "Restore the Mage Tower" is tapped, **Then** 200 shards are deducted, the overlay closes, and the tower visual switches from the ruined to the restored state.
3. **Given** the overlay is open and the player has < 200 shards, **Then** the "Restore the Mage Tower" button is visually disabled and non-functional.
4. **Given** the overlay is open, **When** "Maybe Later" is tapped, **Then** the overlay closes with no changes.
5. **Given** the tower was restored in a previous session, **When** the player returns to the hub, **Then** the tower still shows in its restored state (persists across app restarts).

---

### User Story 2 - Player Unlocks the Relic System (Priority: P2)

With the tower restored, the player opens the system upgrades screen and sees the Relic System entry as available to purchase. They spend shards to unlock it. From the next run onward, after clearing combat rooms, relic offers appear.

**Why this priority**: The relic system meaningfully enriches run variety and is likely the most impactful of the three system unlocks for ongoing gameplay.

**Independent Test**: Can be tested by purchasing the Relic System unlock in the tower screen, then starting a run and clearing a combat room to confirm a relic offer appears.

**Acceptance Scenarios**:

1. **Given** the tower is restored and the Relic System is not yet unlocked, **When** the player opens the system screen, **Then** the Relic System entry shows an "Unlock" button with its shard cost.
2. **Given** the player can afford the Relic System unlock, **When** the unlock button is tapped, **Then** the shards are deducted, the entry updates to show "Unlocked", and relic offers are active in future runs.
3. **Given** the Relic System is already unlocked, **When** the player opens the system screen, **Then** the Relic System entry shows an "Unlocked" indicator with no purchase button.
4. **Given** the player cannot afford the Relic System unlock, **Then** the unlock button is visually disabled.

---

### User Story 3 - Player Unlocks Dungeon Expansion (Priority: P3)

With the tower restored, the player opens the system upgrades screen and purchases Dungeon Expansion. Future runs now include 4 additional rooms beyond the base layout.

**Why this priority**: Important meta-progression upgrade but secondary to relics in immediate run impact.

**Independent Test**: Can be tested by purchasing Dungeon Expansion, starting an endless run, and confirming the room count increases from the base count.

**Acceptance Scenarios**:

1. **Given** the tower is restored and Dungeon Expansion is not owned, **When** the player opens the system screen, **Then** the Dungeon Expansion entry shows an "Unlock" button with its shard cost.
2. **Given** the player can afford the unlock, **When** the unlock button is tapped, **Then** shards are deducted and the entry updates to "Unlocked". Future runs generate the expanded dungeon layout.
3. **Given** Dungeon Expansion is already owned, **When** the player opens the system screen, **Then** the entry shows an "Unlocked" indicator.

---

### User Story 4 - Player Unlocks Boss Challenge Mode (Priority: P4)

With the tower restored, the player purchases Boss Challenge Mode. From the next run onward, a dedicated boss-run option becomes available in the hub.

**Why this priority**: Adds a high-stakes alternative run mode, but is a distinct feature layer that depends on prior engagement with the base dungeon.

**Independent Test**: Can be tested by purchasing Boss Challenge Mode, returning to the hub, and confirming the boss-run activation button appears.

**Acceptance Scenarios**:

1. **Given** the tower is restored and Boss Challenge Mode is not unlocked, **When** the player opens the system screen, **Then** the Boss Challenge Mode entry shows an "Unlock" button with its shard cost.
2. **Given** the player can afford the unlock, **When** the unlock button is tapped, **Then** shards are deducted, the entry updates to "Unlocked", and the boss run option becomes accessible in the hub.
3. **Given** Boss Challenge Mode is already unlocked, **When** the player opens the system screen, **Then** the entry shows an "Unlocked" indicator.

---

### User Story 5 - Player Cannot Afford Tower Restoration (Priority: P5)

A player with fewer than 200 shards taps the Ruined Mage Tower. The overlay appears but the restoration button is disabled, giving clear feedback that they need more shards.

**Why this priority**: Edge-case feedback scenario; builds on P1.

**Independent Test**: Can be tested by holding < 200 shards and tapping the ruined tower.

**Acceptance Scenarios**:

1. **Given** the tower is not restored and the player has < 200 shards, **When** the overlay opens, **Then** the restoration button is visually disabled and non-functional.

---

### Edge Cases

- What happens if a player opens the system screen and their shard balance drops mid-session (e.g., via DevPanel)? Unlock buttons must reflect the live balance, not a stale snapshot.
- If all three system unlocks are already owned, the screen should display all entries as "Unlocked" with no purchase buttons — no crash or empty-state confusion.
- The tower's restored/ruined state must be re-evaluated on every hub visit (not cached in memory from a prior hub visit during the same session).
- If all three system unlocks are purchased and the player re-opens the screen, all entries show "Unlocked" cleanly with no purchase buttons visible.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The hub MUST contain a Mage Tower building zone placed at a distinct position from the Magic Forge.
- **FR-002**: When the tower is not yet restored, the zone MUST display a "Ruined Mage Tower" visual state and be interactable.
- **FR-003**: When the tower is restored, the zone MUST display a "Mage Tower" visual state and be interactable.
- **FR-004**: Tapping the Ruined Mage Tower MUST open a small restoration overlay.
- **FR-005**: The restoration overlay MUST contain a "Restore the Mage Tower (200 shards)" button and a "Maybe Later" button.
- **FR-006**: The restoration button MUST be disabled when the player's current shard balance is below 200.
- **FR-007**: Successfully tapping the restoration button MUST deduct 200 shards, persist the tower-restored state, close the overlay, and switch the visual to the restored state.
- **FR-008**: Tapping "Maybe Later" MUST close the overlay with no side effects.
- **FR-009**: Tapping the Mage Tower zone (restored state) MUST open the system upgrades screen directly, without showing the restoration overlay.
- **FR-010**: The system upgrades screen MUST display three entries: Dungeon Expansion, Relic System, and Boss Challenge Mode.
- **FR-011**: Each entry MUST show the system's name, a brief description, and either an "Unlock (X shards)" button or an "Unlocked" indicator depending on purchase state.
- **FR-012**: An unlock button MUST be disabled when the player cannot afford it.
- **FR-013**: When an unlock is purchased, the shard cost MUST be deducted immediately, the entry MUST update to "Unlocked", and the corresponding system MUST be active from the next run.
- **FR-015**: The system upgrades screen MUST have a close button that returns the player to the hub.
- **FR-016**: The tower's restored state and all system unlock states MUST persist across game sessions (survive app restart).
- **FR-017**: The three individual system unlock costs MUST be read from `data/meta_config.json` so they can be tuned without code changes. Costs: Dungeon Expansion = 200 shards, Relic System = 100 shards, Boss Challenge Mode = 200 shards.

### Key Entities

- **Mage Tower**: A hub building with two visual states (Ruined / Restored) and a persisted restoration flag. Restored once for 200 shards.
- **Restore Overlay**: A transient small panel shown only when the tower is not restored. Contains "Restore" and "Maybe Later" actions.
- **System Upgrades Screen**: A full hub screen listing the three system unlocks with purchase or unlocked state per entry. Always has a close button.
- **System Unlock Entry**: A single row on the screen representing one system (Dungeon Expansion, Relic System, or Boss Challenge Mode) with its name, description, current state, and optional purchase button.
- **Tower Restored State**: A boolean flag in meta-progression storage — false until purchased, then permanently true.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player with ≥ 200 shards can restore the tower and reach the system upgrades screen in 2 taps or fewer.
- **SC-002**: The tower visual state (Ruined / Restored) correctly reflects the persisted state on every hub visit, including after app restart.
- **SC-003**: Purchasing any system unlock deducts the correct shard amount and the system is active from the very next run (no session restart required).
- **SC-004**: All unlock buttons correctly reflect current affordability — disabled when funds are insufficient — with no false positives or negatives.
- **SC-005**: The system upgrades screen closes cleanly and returns the player to the hub with no orphaned UI elements on screen.

## Assumptions

- The Mage Tower uses the same UI composition pattern as the Magic Forge: a zone node with two visual states (two `ColorRect` placeholders), a `Button` for interaction, and a `CanvasLayer`-based overlay/screen system.
- The existing `AdventuringGearShop` node in `HubRoom.tscn` (which currently sells Dungeon Expansion separately) will be removed as part of this feature — its functionality is subsumed by the Mage Tower.
- The existing `boss_run_unlocked` hub UI element (wherever it currently appears) will be removed and its unlock moved into the Mage Tower system screen.
- The relic system auto-unlock mechanic (`adventurer_bag_unlocked` set on first elite clear, `relic_offers_active` set on hub return) is removed entirely. Purchasing the Relic System entry in the Mage Tower is the sole unlock path — it sets both flags atomically. No backward compatibility is needed (no existing saves).
- Individual system unlock costs are stored in `data/meta_config.json` under keys `mage_tower_dungeon_expansion_cost`, `mage_tower_relic_system_cost`, and `mage_tower_boss_challenge_cost`. Confirmed costs: 200, 100, and 200 shards respectively. Total to unlock everything: 700 shards (200 tower + 200 Dungeon Expansion + 100 Relic System + 200 Boss Challenge).
- The Mage Tower zone is always visible in the hub from first launch (no kill or unlock prerequisite to see it in ruined state), matching the Magic Forge behaviour.
- The Mage Tower restore cost of 200 shards is a one-time permanent unlock; it cannot be purchased more than once.
