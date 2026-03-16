# Feature Specification: Gold Idle Currency

**Feature Branch**: `041-gold-idle-currency`
**Created**: 2026-03-13
**Status**: Draft
**Input**: User description: "add a new currency called gold. it should be displayed on top of the screen together with shards in hub screen. it should be an automatically generated currency, with base rate of 100 gold/hour, even when game is closed. only integer part should be displayed to user, so when gold = 10.34, user sees 10. suggest ways of implementing idle generation."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See Gold Balance in Hub (Priority: P1)

A player opens the game and sees their current gold balance displayed at the top of the hub screen alongside their shard count. If they were away for 2 hours, the gold balance has grown automatically — they immediately see the reward for their time away.

**Why this priority**: The display is the only player-facing surface of the feature. Nothing else is meaningful without it.

**Independent Test**: Launch the game, enter the hub, verify a "Gold: N" label appears near the shard display with an integer value ≥ 0.

**Acceptance Scenarios**:

1. **Given** the player is in the hub screen, **When** the hub loads, **Then** a gold balance label is visible near the shard display showing a non-negative integer.
2. **Given** gold = 10.34 (internal), **When** displayed, **Then** the label shows "10" (floor, not round).
3. **Given** the player has never played before, **When** they first enter the hub, **Then** gold displays as 0.

---

### User Story 2 - Gold Visibly Increments in Hub (Priority: P2)

While the player is in the hub, the gold label visibly ticks upward in real time — no button press, no refresh. After watching for a minute they can see the number grow. Gold also accumulates silently during runs (no display there), so returning to the hub always shows a higher balance.

**Why this priority**: Core mechanic — the display in P1 is only useful if the number actually changes, and the live increment in hub is a key satisfying feedback loop.

**Independent Test**: Start the game, enter the hub, watch the gold label for 36 seconds — verify it has incremented by at least 1.

**Acceptance Scenarios**:

1. **Given** the player is in the hub, **When** 1 real-world hour elapses, **Then** the gold label has increased by 100 (no player action required).
2. **Given** the player is watching the hub, **When** the internal gold value crosses an integer boundary (e.g. 9.99 → 10.00), **Then** the displayed number increments automatically within 1 second.
3. **Given** gold accumulation is active during a run, **When** the player returns to the hub, **Then** gold balance is higher than when they left (accumulation is never paused).
4. **Given** any amount of time has passed, **When** the gold display updates, **Then** only the integer part is shown (e.g. 10.99 → 10).

---

### User Story 3 - Offline Gold Generation (Priority: P3)

A player closes the game for 8 hours and reopens it. The game calculates how much gold accumulated during that offline period and credits it automatically on next launch. The player sees their larger balance immediately without any manual action.

**Why this priority**: The "even when game is closed" requirement is a key feature promise. It requires a separate mechanism from the in-session tick.

**Independent Test**: Record the current gold and timestamp, close the game, wait at least 1 minute, reopen — verify gold increased by approximately `(elapsed_minutes / 60) × 100`.

**Acceptance Scenarios**:

1. **Given** the player closes the game with 0 gold and reopens after exactly 1 hour, **Then** gold is 100.
2. **Given** the player was offline for 30 minutes, **When** they reopen, **Then** gold increased by 50.
3. **Given** the player was offline for 0 seconds, **When** they open the game, **Then** gold is unchanged (no double-credit).

---

### Edge Cases

- What happens when the device clock is set backwards (anti-cheat)? Negative elapsed time should award 0 gold, not subtract.
- What is the maximum offline accumulation cap (if any)? No cap specified — assume uncapped (document as assumption).
- What happens if the save file is missing the last-saved timestamp? Treat as 0 elapsed time (award nothing).
- What happens when gold reaches very large values? Display must remain readable (no overflow).
- What happens on an unexpected crash (force-close, power loss)? The gold balance and the last-saved timestamp MUST always be written together as an atomic pair. If only one is written, the math on next launch will over- or under-credit. The offline credit on relaunch naturally covers any in-session gold that was accumulated since the last save, so no gold is lost — provided the two values are always in sync.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST maintain a gold balance as a persistent floating-point value (stored to disk so it survives app restarts).
- **FR-002**: Gold MUST accumulate automatically at a base rate of 100 gold per real-world hour, continuously — including while the game is closed.
- **FR-003**: On game launch, the system MUST calculate the time elapsed since the last session ended and credit the corresponding gold (elapsed hours × 100) before any hub UI is shown.
- **FR-004**: The hub screen MUST display the current gold balance as an integer (floor of the internal float) in a label positioned near the shard display.
- **FR-005**: While the player is in the hub, the gold display MUST update automatically (no player action) at least once per second, visibly incrementing the label whenever the integer floor increases.
- **FR-006**: Gold accumulation MUST NOT pause during active runs — it continues in real-world time regardless of game state. The gold label is not shown during runs; the updated balance is visible when the player returns to the hub.
- **FR-007**: If elapsed offline time would result in a negative gold delta (e.g., device clock was set back), the system MUST award 0 gold for that period.
- **FR-008**: The gold balance and its associated timestamp MUST always be saved together as an atomic pair — never one without the other. This ensures that an unexpected crash does not cause over- or under-crediting on the next launch.
- **FR-009**: The gold balance MUST be saved to disk whenever other meta state is saved (same save cadence as shards).

### Idle Generation — Implementation Options

Three approaches are viable for this engine/platform; all satisfy FR-002 and FR-003:

| Option | Approach | Tradeoff |
|--------|----------|----------|
| **A — Timestamp delta** | Save a Unix timestamp at session end (or periodically). On launch, compute `(now − saved_time) × rate` and add to balance. In-session: `_process()` adds `delta × rate_per_second`. | Simplest. Accurate to ±1 s. Recommended. |
| **B — Periodic auto-save** | Same as A, but also write the timestamp every N minutes while the app runs, so a crash only loses N minutes of offline progress. | More robust crash recovery. Slight extra disk I/O. |
| **C — OS background task** | Use platform background scheduling (iOS BGAppRefreshTask / Android WorkManager via GDExtension) to actually run accumulation logic periodically while closed. | Accurate to ±15 min natively. High complexity; requires native plugin; overkill for a simple rate. |

**Recommended**: Option A (timestamp delta). Option B is a low-cost enhancement. Option C is not worth the complexity at this rate/feature scope.

### Key Entities

- **GoldBalance**: Floating-point value representing the player's gold. Persisted in meta save. Owned by MetaManager (or a dedicated GoldManager). Attributes: `total_gold: float`, `last_tick_timestamp: int` (Unix seconds).
- **MetaState**: Existing data class — gains `total_gold: float` and `gold_last_saved_timestamp: int` fields.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: After exactly 1 real-world hour of combined online + offline time, the player's displayed gold balance increases by exactly 100 (integer).
- **SC-002**: The gold label in the hub updates visually within 1 second of gold crossing the next integer boundary (e.g., 9.99 → 10 shows "10" within 1 s).
- **SC-003**: Offline credit is applied within 3 seconds of the game launching (before the player sees the hub).
- **SC-004**: Closing and immediately reopening the game awards 0 gold (no rounding artefact credits time that hasn't passed).
- **SC-005**: The gold balance survives a full device restart without data loss.
- **SC-006**: Setting the device clock backwards does not decrease the player's gold balance.

---

## Assumptions

- No gold spending mechanic is in scope for this feature — gold is display-only.
- No cap on maximum gold accumulation (uncapped).
- Gold is a hub-only display; it does not appear on the in-run ExplorationHUD.
- The rate (100/hour) is a fixed constant for this feature; no upgrades to the rate are in scope.
- Offline accumulation has no upper time limit (a player absent for 30 days earns 72,000 gold).
- The save format extends the existing `user://meta_save.json` with two new fields; backward compatibility: missing fields default to `total_gold = 0`, `gold_last_saved_timestamp = 0` (awards 0 offline gold on first run after update).
