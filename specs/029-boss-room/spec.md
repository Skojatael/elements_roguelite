# Feature Specification: Boss Room

**Feature Branch**: `029-boss-room`
**Created**: 2026-03-05
**Status**: Draft
**Input**: User description: "implement first boss/boss room. it should be one large enemy, example stats: {hp=40, dmg=5, attack_interval=2}. all boss base data should come from a single source, like enemies.json. main feature: boss is unlocked when X rooms are cleared (make X part of boss data). for now, make X=6. boss_hp = base_hp*(1+0.06*rooms_cleared)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Boss Room Contains a Single Scaled Enemy (Priority: P1)

When the player enters the boss room, they encounter one large enemy. This enemy's HP is scaled by how many rooms the player has cleared in the current run. All base stats (HP, damage, attack interval, and the rooms-cleared threshold) come from the shared enemy data — no values are hardcoded in game logic.

**Why this priority**: The scaled boss encounter is the core gameplay payoff of the feature. Without it, the boss room has no content.

**Independent Test**: Navigate to the boss room. Confirm exactly one enemy spawns. Confirm that enemy's HP matches `base_hp × (1 + 0.06 × rooms_cleared)` for the current run's room count. Clear the boss room normally.

**Acceptance Scenarios**:

1. **Given** the player enters the boss room, **When** the room loads, **Then** exactly one boss enemy spawns.
2. **Given** the player has cleared 6 rooms before the boss room, **When** the boss spawns, **Then** the boss HP is `40 × (1 + 0.06 × 6) = 54.4` (rounded per game rules).
3. **Given** the player has cleared 0 rooms (direct access via DevPanel), **When** the boss spawns, **Then** the boss HP equals the base value (40).
4. **Given** all boss base stats come from data, **When** the data values are changed, **Then** the boss reflects those new values without any code change.

---

### User Story 2 — "Teleport to Boss" Button Unlocks When Required Rooms Are Cleared (Priority: P2)

The boss room is not connected to the dungeon via doors and cannot be reached by normal exploration. Instead, a "Teleport to Boss" button becomes available in the run UI once the player has cleared at least X rooms in the current run (X defined in data, currently 6). Pressing the button transports the player directly to the boss room, ending normal dungeon exploration for that run.

**Why this priority**: The unlock gate is the "main feature" per the description. The button is the only access path to the boss — without it, the boss is either unreachable or always accessible.

**Independent Test**: Start a run. Clear fewer than 6 rooms. Confirm the "Teleport to Boss" button is not visible or not interactable. Clear the 6th room. Confirm the button appears. Press it. Confirm the player is transported to the boss room.

**Acceptance Scenarios**:

1. **Given** fewer rooms have been cleared than the required threshold, **When** the player is in the dungeon, **Then** the "Teleport to Boss" button is not visible.
2. **Given** the player clears the threshold number of rooms, **When** they are in the dungeon, **Then** the "Teleport to Boss" button becomes visible.
3. **Given** the button is visible, **When** the player presses it, **Then** the player is transported to the boss room and dungeon exploration ends.
4. **Given** the threshold value is changed in data (e.g., from 6 to 8), **When** a run is started, **Then** the button appears at the new threshold without any code change.

---

### Edge Cases

- What if the player clears more rooms than the threshold before reaching the boss? Boss should still be accessible and HP should scale correctly with the actual room count.
- What if the player enters the boss room via DevPanel bypass with 0 rooms cleared? The boss spawns with base HP (formula still applies: `base_hp × 1.0`).
- What if the boss is defeated? The room is marked cleared like any other combat room; run continues (cash-out or continue).
- What if the player clears exactly the threshold number of rooms and then immediately presses "Teleport to Boss"? Should work — the button appears as soon as the threshold is met.
- What happens to the "Teleport to Boss" button after the player enters the boss room? It should no longer be relevant (player is in the boss room); the button can be hidden or removed.
- Can the player return to the dungeon after entering the boss room? Out of scope — for now, entering the boss room via the button is a one-way transition.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The boss room MUST contain exactly one boss enemy when entered.
- **FR-002**: The boss enemy's maximum HP MUST be calculated as `base_hp × (1 + 0.06 × rooms_cleared)`, where `rooms_cleared` is the count of rooms cleared in the current run at the time of boss spawn.
- **FR-003**: All boss base stats (base HP, damage, attack interval) and the rooms-cleared threshold MUST be defined in the shared enemy data source — no hardcoded values in game logic scripts.
- **FR-004**: The boss room MUST NOT be reachable via dungeon doors — it is only accessible by pressing the "Teleport to Boss" button.
- **FR-005**: The "Teleport to Boss" button MUST be hidden until the player has cleared at least the threshold number of rooms in the current run.
- **FR-006**: The "Teleport to Boss" button MUST become visible as soon as the threshold is met, without requiring any additional player action.
- **FR-007**: The rooms-cleared threshold MUST be read from the same data source as boss stats (currently: 6 rooms).
- **FR-008**: When the player is teleported to the boss room, the camera MUST reposition to display the boss room — the player must not see the wrong area of the world.
- **FR-009**: The boss enemy MUST deal damage and attack at intervals defined by its data — no special boss-only combat system.
- **FR-010**: Defeating the boss MUST mark the room as cleared, consistent with how other combat rooms are cleared.

### Key Entities

- **Boss enemy**: A single large enemy. Base stats: hp=40, dmg=5, attack_interval=2. Rooms-cleared threshold: 6. HP scaling factor: 0.06 per room cleared. All values in data.
- **Boss room**: A room that contains exactly one boss enemy. Exists as a distinct room type in the dungeon.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The boss room always contains exactly 1 enemy in 100% of playtests.
- **SC-002**: Boss HP equals `base_hp × (1 + 0.06 × rooms_cleared)` in 100% of test scenarios, verified by inspecting the spawned enemy's HP at room entry.
- **SC-003**: The "Teleport to Boss" button is hidden in 100% of states where fewer than 6 rooms have been cleared, and visible in 100% of states where 6 or more rooms have been cleared within a run.
- **SC-004**: Changing any boss stat or the threshold in data (without touching code) produces the expected behavior on the next run.

## Assumptions

- The dungeon already has a BossRoom01 room type/scene. This feature wires the boss enemy into it and adds the unlock gate — not building the room scene from scratch.
- "Rooms cleared" means the count of rooms marked cleared in the current run at the moment the boss spawns (consistent with the existing `cleared_rooms` dictionary in RunManager).
- HP rounding: `floori()` (truncate toward zero), consistent with the existing essence currency formula.
- The boss room is NOT part of the dungeon door graph. It is reached exclusively via the "Teleport to Boss" button in the run UI.
- The "Teleport to Boss" button is a run UI element (not a world object) — it appears in the HUD or a similar screen-space location. Its exact visual design is deferred to a later iteration.
- The boss room uses the same standard room scene structure as other combat rooms (it inherits from the shared room base). No bespoke room architecture is introduced.
- The boss room is placed in world space adjacent to the hub, not within the dungeon grid. This keeps the world layout coherent — the player always transitions from hub-adjacent space, not from deep dungeon coordinates.
- "Rooms cleared" for the HP scaling formula counts all rooms cleared in the current run (standard + elite) at the moment of boss spawn, consistent with existing `cleared_rooms` tracking.
- The 0.06 scaling factor is fixed in code (not in data) for this iteration, consistent with the essence scaling pattern.
- No special boss music, arena, or cutscene in scope for this feature — pure gameplay only.
