# Feature Specification: Hub Boss Run

**Feature Branch**: `034-hub-boss-run`
**Created**: 2026-03-07
**Status**: Draft
**Input**: User description: "implement boss run. a button in the hub allows to teleport to boss (similar to dev panel). however, this is mode "boss", not "endless" and it awards 35 shards on boss kill, no relics. it does not count as first boss kill" — Correction: button has unlock gate, priced at 300 shards, unlocks after 3 boss kills.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unlock Boss Run Feature (Priority: P1)

After accumulating 3 boss kills from endless runs and spending 300 shards, the player permanently unlocks the Boss Run button in the hub. This is a one-time purchase.

**Why this priority**: The unlock gate is the prerequisite for everything else — without it, the Boss Run button never appears.

**Independent Test**: Can be tested by completing 3 endless boss kills, visiting the hub, spending 300 shards on the unlock, and verifying the Boss Run button appears permanently.

**Acceptance Scenarios**:

1. **Given** the player has fewer than 3 endless boss kills, **When** they visit the hub, **Then** no Boss Run unlock option is visible.
2. **Given** the player has 3 or more endless boss kills but has not yet purchased the unlock, **When** they visit the hub, **Then** a "Unlock Boss Run (300 shards)" option is shown.
3. **Given** the unlock option is shown and the player has at least 300 shards, **When** they press the unlock button, **Then** 300 shards are deducted and the Boss Run button is permanently unlocked.
4. **Given** the unlock option is shown and the player has fewer than 300 shards, **When** they press the unlock button, **Then** nothing happens (insufficient funds).
5. **Given** the player has unlocked Boss Run, **When** they return to the hub in any future session, **Then** the Boss Run button is present without needing to unlock again.

---

### User Story 2 - Boss Run and Cash Out (Priority: P2)

A player with Boss Run unlocked presses the Boss Run button in the hub, is immediately transported to the boss room, defeats the boss, and cashes out to receive 35 shards. No relic offer appears and no dungeon traversal is required.

**Why this priority**: This is the core gameplay loop of the feature once unlocked.

**Independent Test**: Can be fully tested by pressing Boss Run from the hub, killing the boss, pressing Cash Out, and verifying exactly 35 shards were added to the player's shard total.

**Acceptance Scenarios**:

1. **Given** the player has Boss Run unlocked and is in the hub, **When** they press the Boss Run button, **Then** a boss run starts and the player is placed in the boss room with no dungeon rooms to traverse.
2. **Given** the player is in the boss room during a boss run, **When** the boss is defeated, **Then** no relic offer appears and the victory overlay is shown immediately.
3. **Given** the boss has been defeated and the victory overlay is shown, **When** the player presses Cash Out, **Then** exactly 35 shards are added to their permanent shard balance and the run ends normally.
4. **Given** a boss run has just been completed, **When** the results screen is shown, **Then** the shard balance reflects the 35-shard award.

---

### User Story 3 - Death in Boss Run (Priority: P3)

A player starts a boss run but is killed by the boss before defeating it. No shards are awarded.

**Why this priority**: The death path must be explicitly handled so no partial rewards leak.

**Independent Test**: Can be tested by starting a boss run, dying to the boss, and verifying the shard balance is unchanged.

**Acceptance Scenarios**:

1. **Given** the player is in the boss room during a boss run, **When** the player dies, **Then** the run ends with 0 shards awarded and the shard balance is unchanged.

---

### User Story 4 - Isolation from Meta-Progression Flags (Priority: P4)

Completing a boss run (win or lose) does not affect any meta-progression flags tracked for endless runs — specifically, the first-boss-kill flag and the endless boss kill counter.

**Why this priority**: Correctness requirement — boss mode must not interfere with the unlock conditions tied to endless-run progression.

**Independent Test**: Can be tested by completing a boss run victory with a fresh save (no endless boss kills), then verifying the Adventuring Gear shop remains hidden and the boss kill count toward Boss Run unlock is still 0.

**Acceptance Scenarios**:

1. **Given** the player has never killed the boss in an endless run, **When** they complete a boss run victory, **Then** the Adventuring Gear shop remains hidden, the first-boss-kill flag is unset, and the endless boss kill counter is unchanged.
2. **Given** the player has 4 endless boss kills (one short of the unlock threshold), **When** they complete a boss run victory, **Then** the endless boss kill counter remains at 4 and the Boss Run unlock option does not appear.

---

### Edge Cases

- What happens if the player presses Boss Run while a run is already active? The button must not trigger a second run.
- What happens if the player dies instantly or quits? Run ends with no shards — same as the death path.
- What if the player has exactly enough shards to hit a spending milestone after the 35-shard award? The award stacks normally with the existing balance.
- What if the player accumulates more than 3 endless boss kills before purchasing? The unlock option remains available regardless of how many kills are accumulated beyond 3.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The hub MUST display a "Unlock Boss Run" option only after the player has accumulated 3 or more boss kills from endless-mode runs.
- **FR-002**: The "Unlock Boss Run" option MUST cost exactly 300 shards as a one-time permanent purchase.
- **FR-003**: If the player cannot afford 300 shards, pressing the unlock option MUST have no effect.
- **FR-004**: Once purchased, the Boss Run button MUST be permanently available in the hub across all future sessions.
- **FR-005**: Pressing the Boss Run button MUST start a run in "boss" mode and immediately place the player in the boss room — no dungeon generation or traversal required.
- **FR-006**: The Boss Run button MUST be inactive while any run is already in progress.
- **FR-007**: On boss kill in "boss" mode, the player MUST receive exactly 35 shards added directly to their permanent balance — no relic offer, no essence conversion.
- **FR-008**: No relic offer MUST appear at any point during a boss run.
- **FR-008b**: On the boss victory overlay in "boss" mode, only the Cash Out button MUST be visible — the Continue button MUST be hidden.
- **FR-009**: Boss kills in "boss" mode MUST NOT increment the endless boss kill counter used to gate the Boss Run unlock.
- **FR-010**: Boss kills in "boss" mode MUST NOT set the first-boss-kill flag used by the Adventuring Gear unlock.
- **FR-011**: If the player dies during a boss run, zero shards are awarded and the permanent shard balance is unchanged.
- **FR-012**: The standard run end screen (results screen) MUST still appear after a boss run ends.

### Key Entities

- **Boss Run**: A run session with mode "boss", starting directly in the boss room. Distinct from an "endless" run in reward rules and flag effects.
- **Endless Boss Kill Counter**: A persistent count of boss kills earned exclusively in endless-mode runs. Gates the Boss Run unlock at 3. Not affected by boss-mode runs.
- **Boss Run Unlock**: A one-time permanent purchase (300 shards, requires counter ≥ 3) that makes the Boss Run button available in the hub.
- **Flat Shard Award**: A fixed 35-shard grant issued on boss-mode cash-out, bypassing the normal essence-to-shard conversion formula.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After 3 endless boss kills and spending 300 shards, the Boss Run button appears in the hub and persists across sessions.
- **SC-002**: A player can initiate a boss run from the hub and reach the boss room in a single tap, with no intermediate screens or room traversal.
- **SC-003**: On boss kill and cash-out in boss mode, the player's shard balance increases by exactly 35.
- **SC-004**: Completing a boss run (win or lose) leaves the first-boss-kill flag and the endless boss kill counter unchanged.
- **SC-005**: No relic selection screen appears at any point during a boss run.
- **SC-006**: Death in a boss run results in zero change to the player's shard balance.
- **SC-007**: The unlock option is not visible until exactly 3 endless boss kills have been recorded.

## Assumptions

- The 3-kill threshold counts only endless-mode boss kills; boss-mode kills are excluded, consistent with the "does not count" rule for all boss-mode meta-progression.
- The boss's HP scaling formula still applies; since no rooms are cleared in a boss run, the boss spawns at base HP.
- The standard results screen is shown after the run ends, consistent with all other run endings.
- The 35-shard flat award replaces the normal essence-to-shard conversion — there is no essence to convert anyway since boss runs have no room enemies.
- "Cash Out" on the boss victory overlay is the trigger for the shard award; dying awards nothing.
- The unlock purchase is a separate button/shop from the Boss Run trigger button (similar to how AdventuringGearShop is separate from TeleportDoor).
