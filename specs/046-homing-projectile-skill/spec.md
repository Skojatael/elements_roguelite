# Feature Specification: Homing Projectile Skill

**Feature Branch**: `046-homing-projectile-skill`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "implement a projectile based skill. there should be a button on hud that is always shown when hud is shown. on press, it should release a projectile from player. if there are no enemies, it should do nothing. if there are enemies, it should fly to the closest enemy (homing). the projectile should deal half the player's damage."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fire Homing Projectile at Enemy (Priority: P1)

The player is exploring a combat room with enemies present. They tap the skill button on the HUD. A projectile immediately launches from the player's position and automatically steers toward the nearest living enemy. On contact, the projectile deals damage and disappears.

**Why this priority**: This is the core mechanic — the projectile's homing behavior and damage are the entire feature. Without this working, there is nothing to deliver.

**Independent Test**: Place the player in a room with at least one enemy. Tap the skill button. Verify a projectile appears at the player's position, visually moves toward the closest enemy, and deals damage equal to 50% of the player's attack damage on impact.

**Acceptance Scenarios**:

1. **Given** the player is in a combat room with one or more living enemies, **When** the skill button is pressed, **Then** a projectile spawns at the player's position and steers toward the closest enemy.
2. **Given** a projectile is in flight, **When** it reaches the target enemy, **Then** the enemy loses HP equal to 50% of the player's current attack damage and the projectile is removed.
3. **Given** a projectile is in flight toward a target, **When** the target enemy dies before impact, **Then** the projectile disappears immediately.

---

### User Story 2 - Skill Button Always Visible on HUD (Priority: P2)

Whenever the Exploration HUD is visible (i.e., a run is active), the skill button is always shown — regardless of enemy presence. It is never hidden or moved based on game state.

**Why this priority**: Consistent HUD layout matters for mobile play. Players should not need to search for the button or have the layout shift dynamically.

**Independent Test**: Start a run, enter a room, and verify the skill button is visible in the HUD at all times — in rooms with enemies, in rooms without enemies, and between rooms.

**Acceptance Scenarios**:

1. **Given** a run is active and the ExplorationHUD is shown, **When** the player enters any room type, **Then** the skill button is visible on the HUD.
2. **Given** the player is between rooms (transitioning), **When** the HUD is visible, **Then** the skill button remains visible.
3. **Given** the run ends or the HUD is hidden, **When** the HUD becomes invisible, **Then** the skill button is also hidden (it follows HUD visibility, not its own logic).

---

### User Story 3 - No-Op When No Enemies Present (Priority: P3)

If the player presses the skill button when there are no living enemies in the current room (e.g., in the start room, or after clearing all enemies), nothing happens. No projectile is fired. No error state or feedback is shown.

**Why this priority**: A clean no-op on invalid press prevents confusion and ensures the feature degrades gracefully in enemy-free contexts.

**Independent Test**: Enter the start room or a cleared combat room. Tap the skill button. Verify no projectile appears and nothing changes on screen.

**Acceptance Scenarios**:

1. **Given** there are no living enemies in the room, **When** the skill button is pressed, **Then** no projectile is spawned and nothing visually changes.
2. **Given** all enemies in a room have just been killed, **When** the skill button is pressed, **Then** no projectile is spawned.

---

### Edge Cases

- What happens when the skill button is pressed while a projectile is already in flight? Multiple projectiles may exist simultaneously — each press fires a new independent projectile toward the closest enemy at that moment.
- What happens if the projectile travels a very long distance without reaching an enemy (e.g., target is pushed far away)? The projectile is removed after exceeding a maximum travel distance.
- What if two enemies are equidistant from the player? Either one may be chosen — the outcome is acceptable.
- Does the skill button have a cooldown between uses? No cooldown in this iteration — the button can be pressed again immediately. Cooldown may be added in a future iteration.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The ExplorationHUD MUST always display the skill button while the HUD is visible, regardless of enemy presence or room type.
- **FR-002**: Pressing the skill button when no living enemies are present MUST produce no effect (no projectile spawned, no visual or audio feedback required).
- **FR-003**: Pressing the skill button when at least one living enemy is present MUST spawn a projectile at the player's current position.
- **FR-004**: The projectile MUST steer continuously toward the closest living enemy by distance, updating its direction as it moves.
- **FR-005**: The projectile MUST deal damage equal to exactly 50% of the player's current attack damage value on contact with an enemy.
- **FR-006**: The projectile MUST be removed from the game world immediately upon contact with any enemy.
- **FR-007**: If the projectile's current target enemy dies before the projectile reaches it, the projectile MUST be removed immediately.
- **FR-008**: The projectile MUST be removed if it travels beyond a maximum distance without hitting an enemy (prevents orphaned projectiles).
- **FR-009**: The skill button MUST follow the same visibility rules as the ExplorationHUD — shown when HUD is shown, hidden when HUD is hidden.

### Key Entities

- **Skill Button**: A HUD button always displayed during active runs. Triggers projectile launch on press.
- **Projectile**: A short-lived game object spawned at the player's position. Moves at a fixed speed, homes toward the nearest enemy, deals damage on impact, and is removed on hit or after exceeding maximum travel distance.
- **Target Enemy**: The living enemy closest (by straight-line distance) to the player at the moment the skill button is pressed. The projectile homes toward this enemy; if the enemy dies, the projectile disappears.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A projectile reaches and damages the closest enemy within 3 seconds of the skill button being pressed in 100% of valid test cases (enemies present, projectile unobstructed).
- **SC-002**: The skill button is visible and tappable at all times during an active run when the HUD is shown — verified across start room, combat rooms, and post-clear state.
- **SC-003**: Pressing the skill button when no enemies are present produces no visible change in game state in 100% of test cases.
- **SC-004**: Damage dealt by the projectile equals 50% of the player's attack damage (rounded down) in 100% of test cases, verified across different player damage levels.
- **SC-005**: No orphaned projectiles remain in the game world after a run ends or after a room transition.

## Assumptions

- "Player's damage" refers to the player's current computed attack damage value (same stat used for melee attacks, including meta-progression multipliers and relic bonuses).
- The projectile travels at a fixed speed (assumed ~600 pixels/second given the game's room scale). Exact value to be determined during planning.
- Maximum travel distance is assumed to be approximately the diagonal of one room (~2200px). Exact value to be determined during planning.
- The projectile does not pierce; it is consumed on first enemy contact.
- If the target enemy dies mid-flight, the projectile disappears rather than re-targeting (simpler behavior, avoids chain-homing complexity).
- Multiple projectiles may be in flight simultaneously; each button press fires an independent projectile.
- No cooldown is implemented in this iteration.
- The skill button does not need a disabled/grayed state for enemy-free rooms — it is always fully interactive but silently no-ops.
- The projectile is a simple visual (colored shape) with no art assets required for this iteration.
