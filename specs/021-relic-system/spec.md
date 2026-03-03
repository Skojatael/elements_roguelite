# Feature Specification: Relic System

**Feature Branch**: `021-relic-system`
**Created**: 2026-03-02
**Status**: Ready
**Input**: User description: "implement modifier system (called relics). Implement: ModifierData.tres (id, name, tier, tags, effect params). PlayerState.active_modifiers: Array[String] (store IDs). ModifierService.apply(player, modifier_id) (for now can just change stats multipliers). A simple post-clear offer UI with 2 choices. Offer frequency: every 2 rooms (and always after elite, if you want)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Receive and Pick a Relic After Clearing a Room (Priority: P1)

After defeating all enemies in a qualifying room, the player is presented with an offer screen showing 2 relics to choose from. Each relic has a name and a brief description of its effect. The player taps one to collect it, the offer screen closes, and the relic's effect is immediately applied to their character stats for the remainder of the run.

**Why this priority**: This is the core roguelite progression loop within a run. Without relic selection, no other aspect of the feature delivers value. The offer UI, relic data, and stat application must all work together as a single coherent experience.

**Independent Test**: Clear a qualifying room. Confirm the offer screen appears with 2 distinct relics. Tap one. Confirm the screen closes and the chosen relic's stat effect is active (e.g., attack damage increased if a damage relic was chosen). Confirm the other relic was not applied.

**Acceptance Scenarios**:

1. **Given** a qualifying room is cleared, **When** all enemies are defeated, **Then** an offer screen appears showing exactly 2 relic choices.
2. **Given** the offer screen is showing, **When** the player taps a relic, **Then** the screen closes, the relic is added to the player's active collection, and its stat modifier takes effect immediately.
3. **Given** the player has selected a relic, **When** they attack or take damage, **Then** the game uses the post-relic stat values (e.g., attack damage is multiplied by the relic's damage factor).
4. **Given** a relic is collected, **When** the player enters the next room, **Then** the relic's effect is still active — it does not reset between rooms.

---

### User Story 2 - Offer Appears at the Correct Frequency (Priority: P2)

Relic offers appear at a predictable cadence: after every second room cleared, and always after clearing an elite room regardless of the room counter. This rhythm gives players something to anticipate and ensures elite rooms carry an extra reward.

**Why this priority**: Offer frequency defines the pacing of relic acquisition. Too frequent feels overwhelming; too rare feels unrewarding. The frequency rule is independently verifiable without requiring the relic effects to be tuned.

**Independent Test**: Clear rooms in sequence without dying. Confirm no offer after room 1. Confirm an offer after room 2. Confirm no offer after room 3. Confirm an offer after room 4. Then enter an elite room at any point in the sequence — confirm an offer appears immediately after clearing it, regardless of the current counter.

**Acceptance Scenarios**:

1. **Given** a run has started, **When** the player clears their 1st non-elite room, **Then** no relic offer appears.
2. **Given** the player has cleared 1 non-elite room, **When** they clear their 2nd non-elite room, **Then** a relic offer appears.
3. **Given** any point in a run, **When** the player clears an elite room, **Then** a relic offer always appears, regardless of the room counter.
4. **Given** an elite room triggered an offer (resetting the counter), **When** the player clears the next 2 standard rooms, **Then** the counter resumes correctly (offer after 2 more clears).

---

### User Story 3 - Relics Persist and Stack Through the Run (Priority: P3)

All relics collected during a run remain active and their effects combine. A player who picks a damage relic then a speed relic benefits from both simultaneously. Relics are lost when the run ends (they are run-scoped, not permanent meta-upgrades).

**Why this priority**: Without persistence and stacking, relics have no cumulative value. This story confirms the system works correctly when multiple relics are held. It is independently verifiable by collecting two+ relics and confirming both are active.

**Independent Test**: Collect a damage relic (e.g., ×1.2 damage). Note the new damage value. Collect a second damage relic (e.g., another ×1.2). Confirm damage is now base × 1.2 × 1.2. End the run. Start a new run. Confirm damage returns to base (no relics carried over).

**Acceptance Scenarios**:

1. **Given** the player holds 2 relics that both modify the same stat, **When** they use that stat in combat, **Then** both modifiers are applied (multiplicatively or additively per spec — see Assumptions).
2. **Given** a run ends (cash-out or death), **When** a new run begins, **Then** the player starts with no active relics.
3. **Given** the player holds 3 relics, **When** viewing the relic collection (future feature — out of scope here), **Then** all 3 are tracked correctly.

---

### Edge Cases

- No eligible relics remain in the pool: relics are drawn with replacement — the same relic can appear again in later offers within the same run (pool never fully exhausts).
- Player clears an elite room that also happens to be the 2nd room: offer appears once, not twice.
- Run ends mid-offer (edge condition — not expected in normal flow; offer only appears after clear before room transition).
- A relic that modifies a stat to zero or negative: stat is clamped to a safe minimum (not a concern with pure multipliers > 0).
- Player cannot skip or decline the relic offer — exactly one relic must be chosen before the game continues. There is no dismiss or close button on the offer screen.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: After clearing a qualifying room, the game MUST present an offer screen with exactly 2 relic choices drawn from the available relic pool.
- **FR-002**: The player MUST be able to select one relic from the offer; the chosen relic is immediately added to their active collection for the current run.
- **FR-003**: Each relic MUST display a name and a short description of its effect on the offer screen.
- **FR-004**: A relic's stat effect MUST be applied to the player immediately upon selection and remain active until the run ends.
- **FR-005**: Multiple relics modifying the same stat MUST stack — their effects combine on the player's stats.
- **FR-006**: Relic offers MUST appear after every 2nd room cleared (standard rooms), and always after clearing an elite room.
- **FR-007**: Clearing an elite room MUST always trigger an offer, regardless of the current room counter; the counter continues from its current position after the elite offer.
- **FR-008**: All active relics MUST be reset (cleared) when a run ends; they MUST NOT carry over to the next run.
- **FR-009**: Relics MUST be defined as data (id, name, tier, tags, effect type, effect value) with all balance values in configuration — no hardcoded relic effects in game logic.
- **FR-010**: The initial relic pool MUST include at least one relic for each supported stat category (attack damage, attack speed, max health) to cover all testable effect types.

### Key Entities

- **Relic**: A collectible run-scoped modifier with a unique id, display name, tier (common/rare/epic), tags (e.g., "combat", "survival"), and one or more effect parameters (stat targeted, multiplier value). Defined in data configuration.
- **Active relic collection**: The set of relic IDs the player has collected in the current run. Stored in run state. Cleared on run end.
- **Relic offer**: A transient UI event presenting 2 randomly drawn relics from the pool. Triggered by room clear at qualifying intervals.
- **Relic pool**: The full set of available relics the game can offer. All defined in data config.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Relic offer appears within 1 second of a qualifying room being cleared in 100% of qualifying clears.
- **SC-002**: Chosen relic's stat effect is applied before the player can enter the next room in 100% of cases — no offer can be bypassed without making a choice.
- **SC-003**: Offer frequency is correct in 100% of runs — offers appear exactly after every 2nd standard clear and after every elite clear, never more or fewer.
- **SC-004**: All collected relics remain active for the entire run and are cleared between runs in 100% of test cases across at least 3 consecutive runs.
- **SC-005**: Stacking relics produce the correct combined stat value in 100% of cases (verified across all supported stat types).

## Assumptions

- **Run-scoped only**: Relics are per-run items — they are not saved to disk or carried into the next run. This is consistent with the roguelite design pattern.
- **Stat multipliers**: For this iteration, all relic effects are simple stat multipliers (e.g., attack damage × 1.2). Additive flat bonuses and conditional effects are out of scope.
- **Stacking rule**: Multiple relics modifying the same stat multiply together (e.g., two ×1.2 relics → ×1.44), not additively. This is the standard roguelite compounding pattern.
- **Offer skipping**: The player MUST choose one relic — no skip option exists. The offer screen has no dismiss or close button. This prevents players from avoiding meaningful choices and is the standard roguelite pattern.
- **Duplicate offers**: The 2 relics offered in a single offer screen are always distinct (cannot offer the same relic twice in one screen). The same relic can reappear in later offers within the same run.
- **Pool exhaustion**: If fewer than 2 distinct relics remain in the pool (because all have been offered and the pool is small), relics are drawn with replacement (same relic can appear again).
- **Counter reset**: The every-2-rooms counter does NOT reset after an elite offer — it continues counting standard room clears as if the elite offer didn't happen.
- **Initial relic count**: 3–5 relics are implemented for this feature (enough to cover the 3 stat categories and validate the pool/offer system). Exact set defined during planning.
- **Relic tier**: Tier (common/rare/epic) is stored in data but does NOT affect offer probability in this iteration. All relics are drawn with equal probability.
- **No relic display outside offer**: The current active relic collection is not displayed in any HUD in this iteration (future feature). Only the offer screen shows relic info.

## Scope

**In scope**: Relic data definition, relic pool, post-clear offer UI (2 choices), relic application to player stats (attack damage, attack speed, max health multipliers), offer frequency logic (every 2 standard clears + always after elite), run-scoped active relic collection, multi-relic stacking.

**Out of scope**: Relic inventory HUD, relic synergy bonuses, relic removal/rerolling, relic drop from enemies (only post-clear offers), per-tier offer weighting, saving relics between runs, relic animations, relic lore/flavor text beyond name and effect description.
