# Feature Specification: Boss Rewards

**Feature Branch**: `032-boss-rewards`
**Created**: 2026-03-05
**Status**: Draft
**Input**: User description: "boss should have a base reward that scales based on rooms_cleared, same formula as hp. on boss defeat three rare relics should be offered."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Boss Awards Scaled Essence on Defeat (Priority: P1)

When the player defeats the boss, they receive an essence reward. The reward has a base value defined in the boss data and scales upward based on how many rooms the player cleared before reaching the boss — using the same multiplier formula as boss HP. More rooms cleared before fighting the boss means a larger essence reward.

**Why this priority**: The essence reward is the primary economic payoff for completing the boss encounter. Without it the boss provides no progression value beyond the relic offer.

**Independent Test**: Kill the boss with 0 rooms cleared → verify essence matches base reward value. Kill the boss after clearing 6 rooms → verify essence is approximately `base × 1.36` (floored to int).

**Acceptance Scenarios**:

1. **Given** the boss is defeated with 0 rooms cleared, **When** the run ends, **Then** the essence cashed out includes the boss base reward with no scaling bonus.
2. **Given** the boss is defeated after clearing N rooms, **When** the run ends, **Then** the boss reward added to run currency equals `floor(base_reward × (1 + 0.06 × max(0, N − 6)))`.
3. **Given** a boss base reward is defined in the game data, **When** that value is changed, **Then** all scaling calculations automatically use the new base — no other data changes are needed.

---

### User Story 2 — Three Rare Relics Offered on Boss Defeat (Priority: P2)

Immediately after the boss is defeated, the player is presented with an offer of exactly three rare relics to choose from. This offer appears before the victory overlay (Cash Out / Continue Further). The player picks one relic, which is added to their active modifiers for the remainder of the run.

**Why this priority**: The relic offer is the primary run-progression reward for defeating the boss. It is more impactful to the run than the essence reward but depends on US1 establishing the defeat event.

**Independent Test**: Kill the boss → confirm relic offer screen appears immediately with exactly 3 options → all 3 options are rare tier → pick one → confirm relic is active → confirm victory overlay appears after the pick.

**Acceptance Scenarios**:

1. **Given** the boss is defeated, **When** the boss death event fires, **Then** a relic offer screen appears showing exactly 3 relics.
2. **Given** the relic offer screen is showing, **When** the player inspects the options, **Then** all 3 relics are of rare tier.
3. **Given** the relic offer screen is showing, **When** the player picks a relic, **Then** the relic is added to their active modifiers and the victory overlay (Cash Out / Continue Further) appears.
4. **Given** fewer than 3 distinct rare relics are available (all already owned or pool exhausted), **When** the boss is defeated, **Then** the offer shows as many rare relics as are available (minimum 1); if none remain, the offer is skipped.

---

### Edge Cases

- Boss reward essence is added to run currency at the moment of boss death, before cash-out. If the player later presses "Cash Out", the boss reward is included in the payout. If the player dies before pressing "Cash Out" (edge case: another source of damage kills them?), the DIED penalty applies to the full accumulated amount including boss reward.
- If the player has already collected all rare relics in the pool, the relic offer shows whatever rare relics remain, or skips the offer if none are available.
- The relic offer should not stack with the regular room-clear relic offer — if a regular relic offer was pending when the boss was entered, it should be resolved separately or discarded (assumption: entering the boss room skips pending regular offers).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The boss enemy data MUST define a numeric base reward value.
- **FR-002**: When the boss is defeated, the game MUST add `floor(base_reward × (1 + 0.06 × max(0, rooms_cleared − 6)))` to the player's run currency, where `rooms_cleared` is the count of standard rooms cleared at the moment of boss death.
- **FR-003**: The scaling formula MUST be identical to the boss HP scaling formula (`1 + 0.06 × max(0, rooms_cleared − 6)`). Both scale only beyond the 6-room unlock threshold.
- **FR-004**: Immediately after boss defeat, the game MUST present an offer of exactly 3 rare relics.
- **FR-005**: All relics in the boss relic offer MUST be of rare tier.
- **FR-006**: If fewer than 3 rare relics are available (due to the player already holding them), the offer MUST contain as many as are available; if 0 are available, the offer MUST be skipped entirely.
- **FR-007**: The relic offer MUST appear before the victory overlay (Cash Out / Continue Further). The victory overlay MUST NOT appear until the player has made their relic selection.
- **FR-008**: The boss relic offer MUST use the existing relic selection UI — no new interface is required.

### Key Entities

- **Boss Reward**: A numeric value stored in the boss enemy data representing the base essence award for defeating the boss.
- **Scaled Boss Reward**: The actual essence credited to run currency — `floor(base_reward × (1 + 0.06 × rooms_cleared))`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Boss essence reward at 0 or 6 rooms cleared equals exactly 80 (base, no scaling at or below threshold) — verified in 3 consecutive runs.
- **SC-002**: Boss essence reward at 12 rooms cleared equals `floor(80 × 1.36)` = 108 — verified in 3 consecutive runs.
- **SC-003**: The relic offer always contains exactly 3 options when at least 3 rare relics remain in the pool — verified across 5 boss kills.
- **SC-004**: Every relic in the boss offer is of rare tier — 0 non-rare relics appear across all tested boss kills.
- **SC-005**: The victory overlay never appears before the relic pick is made — verified in 10 sequential boss kills.

## Assumptions

- The boss base reward value is 80 (tunable in data without code changes).
- Rare relics are defined by a `tier` field in the relic data (`tier: "rare"`). The existing relic pool and draw system already supports filtering by tier.
- The existing relic offer screen and pick flow are reused without modification.
- Rooms cleared at the time of boss death includes only standard rooms (same `cleared_rooms` count used for HP scaling), not the boss room itself.
- A "pending" regular relic offer from the last cleared dungeon room (if any) does not interfere with the boss relic offer — the boss offer sequence takes priority.

## Dependencies

- Feature 029 (Boss Room) — boss enemy and spawn flow must exist.
- Feature 030 (Boss Victory Outcome) — victory overlay must exist; its appearance is deferred until after relic pick in this feature.
- Feature 021 (Relic System) — relic pool, offer screen, and pick flow must exist.
