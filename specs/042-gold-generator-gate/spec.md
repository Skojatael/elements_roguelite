# Feature Specification: Gold Generator Gate (Transmuter)

**Feature Branch**: `042-gold-generator-gate`
**Created**: 2026-03-16
**Status**: Draft
**Input**: User description: "add an unlock gate on gold generation. give it a tech name 'gold_generator' and display name 'transmuter'. it should cost 50 shards (make everything data-driven as with other upgrades). gold generation should start only after purchase of this upgrade"

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unlock Gold Generation via Transmuter (Priority: P1)

A player who has accumulated at least 50 shards opens the Alchemy Lab upgrade screen in the hub and sees a "Transmuter" entry. They spend 50 shards to unlock it, and from that moment forward gold begins accumulating automatically. Before the purchase, no gold accrues — not in-session, not offline.

**Why this priority**: The core feature is the gate itself. Without this purchase flow, the unlock has no entry point and gold generation never starts.

**Independent Test**: Start with ≥ 50 shards and the Transmuter not yet purchased. Open the Alchemy Lab, press the Transmuter unlock button. Verify the shard balance decreases by 50 and the gold balance begins incrementing (observable within 36 seconds of hub time).

**Acceptance Scenarios**:

1. **Given** the player has ≥ 50 shards and has not purchased the Transmuter, **When** they press the unlock button, **Then** 50 shards are deducted and the Transmuter enters its active state.
2. **Given** the Transmuter is now active, **When** time passes, **Then** gold accumulates at the configured rate (100/hour).
3. **Given** the player has < 50 shards, **When** they view the Transmuter, **Then** the unlock button is disabled and they cannot purchase.
4. **Given** the Transmuter has already been purchased, **When** the player views it, **Then** no second purchase is possible and no shard deduction occurs.

---

### User Story 2 - Gold Remains Zero Before Purchase (Priority: P2)

A player who has never purchased the Transmuter sees 0 gold at all times — after sessions, after going offline overnight, after any amount of real-world time. The gold currency display exists in the hub but shows a static zero until the Transmuter is bought.

**Why this priority**: This is the gating behaviour. Without explicit verification that idle generation is suppressed pre-purchase, the gate has no meaning.

**Independent Test**: Launch the game with the Transmuter not purchased, wait 60 seconds in the hub, verify gold remains 0. Then close and reopen the game after 1 minute; verify gold is still 0.

**Acceptance Scenarios**:

1. **Given** the Transmuter has not been purchased, **When** the player is in the hub for any duration, **Then** the gold display remains 0.
2. **Given** the Transmuter has not been purchased, **When** the player closes and reopens the game after any elapsed time, **Then** no offline gold is credited and the display shows 0.
3. **Given** the Transmuter has not been purchased, **When** the player completes a run, **Then** no gold accumulates during the run.

---

### User Story 3 - Transmuter State Persists Across Sessions (Priority: P3)

A player purchases the Transmuter, closes the game, and reopens it. The Transmuter is still active — they do not need to buy it again. Gold accumulated during the offline period is credited normally, as the gate was cleared before the session ended.

**Why this priority**: Persistence of the purchased state is a fundamental save/load requirement. Without it, the player would lose their purchase on every restart.

**Independent Test**: Purchase the Transmuter, record gold and timestamp, close the game, wait 1 minute, reopen — verify Transmuter shows as active, gold has increased by ~1.67 (1/60 of 100).

**Acceptance Scenarios**:

1. **Given** the Transmuter has been purchased, **When** the player closes and reopens the game, **Then** the Transmuter still shows as active without requiring re-purchase.
2. **Given** the Transmuter is active, **When** the player was offline for 1 hour, **Then** 100 gold is credited on relaunch (same as the 041 offline credit behaviour, now correctly gated).
3. **Given** a save file from before this feature was added (no Transmuter field), **When** the game loads, **Then** the Transmuter defaults to unpurchased — no gold is awarded retroactively.

---

### Edge Cases

- What if a player had gold accumulating from feature 041 (gold idle currency) before the gate feature ships? On first load after the update, `gold_generator_owned` defaults to `false`, gold resets to 0 and stops accumulating. (Breaking change, acceptable for pre-release.)
- What if the player spends exactly their last 50 shards on the Transmuter? The balance reaches 0; the purchase completes normally.
- What if the save file is corrupted and `gold_generator_owned` cannot be read? Default to `false` (unpurchased) — conservative choice, does not award unearned gold.
- Can the Transmuter be purchased from within a run (e.g., via a debug panel)? Assume no — it is a hub-only interaction.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST define a persistent boolean flag (`gold_generator_owned`) in the meta save that tracks whether the Transmuter has been purchased. Default value on missing save data: `false`.
- **FR-002**: Gold accumulation (in-session ticking and offline credit) MUST be suppressed entirely when `gold_generator_owned` is `false`. No gold accrues before the purchase, regardless of time elapsed.
- **FR-003**: The Alchemy Lab upgrade screen MUST include a "Transmuter" entry showing its unlock cost (50 shards) read from configuration data — no hard-coded value in script.
- **FR-004**: The Transmuter's unlock button MUST be disabled when the player's shard balance is below the configured cost.
- **FR-005**: On a successful unlock, the system MUST atomically deduct the configured shard cost and set `gold_generator_owned = true`, then persist both changes together.
- **FR-006**: Once purchased, the Transmuter MUST NOT allow a second purchase — the unlock button is replaced by an "Active" or similar indicator.
- **FR-007**: All Transmuter configuration (tech name `gold_generator`, display name `Transmuter`, cost `50`) MUST reside in `data/meta_config.json` nested under `alchemy_lab.upgrades`, consistent with the pattern of other Alchemy Lab upgrades. Scripts read values from config; no values are hard-coded.
- **FR-008**: The gold balance field in the save file MUST remain at `0` and the last-saved timestamp MUST remain at `0` while `gold_generator_owned` is `false`, so that no offline gold is inadvertently credited when the Transmuter is later purchased.
- **FR-009**: After purchase, in-session gold accumulation MUST begin immediately (within 1 second) without requiring a game restart.

### Key Entities

- **Transmuter**: Upgrade within the Alchemy Lab that gates gold generation. Attributes: `gold_generator_owned: bool` (persisted in MetaState), `cost: int` (from config). States: Unpurchased → Active (one-way transition).
- **MetaState**: Gains field `gold_generator_owned: bool = false`. Persisted in `user://meta_save.json`.
- **meta_config.json**: `gold_generator` entry added under `alchemy_lab.upgrades`, with sub-keys `name` ("Transmuter") and `cost` (50). Pattern matches the existing `essence_gain` upgrade in the same building.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A player with ≥ 50 shards can complete the Transmuter purchase in one button press; shard balance decreases by exactly 50 and gold begins accumulating within 1 second.
- **SC-002**: A player with < 50 shards cannot activate the purchase button — 0 shards are deducted.
- **SC-003**: With the Transmuter unpurchased, gold balance stays at exactly 0 after any duration (in-session or offline), verified by waiting 60+ seconds and checking.
- **SC-004**: The Transmuter purchased state survives a full app restart — no re-purchase required on relaunch.
- **SC-005**: Changing the cost value in `meta_config.json` from 50 to any other value is reflected in the hub UI and purchase logic without any script edits.
- **SC-006**: After purchase, offline gold credit on the next launch is calculated correctly (elapsed hours × rate), consistent with the 041 behaviour.

---

## Assumptions

- The Transmuter is a hub-only purchase; it cannot be acquired during a run.
- No visual art is required for this feature — placeholder visuals (matching the pattern of Mage Tower / Alchemy Lab ColorRect placeholders) are acceptable.
- The gold balance and timestamp are reset to 0 on first load when the Transmuter defaults to unpurchased — this is acceptable for a pre-release feature.
- Gold spending is not in scope (same assumption as 041).
- The Transmuter is an upgrade nested under `alchemy_lab.upgrades.gold_generator` in `meta_config.json`, alongside the existing `essence_gain` upgrade. It is not a standalone hub building.
- The `shards_changed` signal (MetaManager) is used to refresh the Transmuter UI affordability state, consistent with how other hub buildings respond to shard balance changes.
