# Feature Specification: Dodge Skill

**Feature Branch**: `070-dodge-skill`
**Created**: 2026-03-20
**Status**: Draft
**Input**: User description: "create dodge skill. it should be a button on hud with 1.5sec cooldown (data-driven), that grants 0.20sec of invulnerability and moves the player in the direction where player was moving previously with x2 speed."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Activate Dodge (Priority: P1)

The player taps the Dodge button on the HUD during combat. The character instantly dashes a fixed distance in the last movement direction and is invulnerable for the duration of the dash, evading incoming attacks.

**Why this priority**: Core mechanic — without this, no other story is testable.

**Independent Test**: Place the player in a combat room, tap Dodge, verify the player travels the configured distance and takes no damage during the dash.

**Acceptance Scenarios**:

1. **Given** the player is moving, **When** the Dodge button is tapped, **Then** the player dashes the configured distance (default: 300 units) in the last recorded movement direction.
2. **Given** the player is stationary (no prior movement input), **When** Dodge is tapped, **Then** the player dashes south (default fallback direction).
3. **Given** the player is mid-dash, **When** an enemy projectile or contact would deal damage, **Then** no damage is applied until the dash completes.

---

### User Story 2 — Cooldown Enforcement (Priority: P2)

After a dodge, the button becomes visually unavailable until the cooldown expires, preventing spam.

**Why this priority**: Cooldown is the primary balance lever; without it the skill has no cost.

**Independent Test**: Tap Dodge; immediately tap again; verify second tap does nothing until cooldown expires.

**Acceptance Scenarios**:

1. **Given** dodge was just used, **When** the player taps Dodge again, **Then** the action is ignored and the button remains visually unavailable.
2. **Given** 1.5 seconds have passed since the last dodge, **When** the player taps Dodge, **Then** the dodge activates normally.
3. **Given** the cooldown is active, **When** the cooldown timer expires, **Then** the HUD button visually resets to the ready state.

---

### User Story 3 — Data-Driven Configuration (Priority: P3)

All dodge parameters (cooldown duration, dash distance) are stored in a data file so they can be tuned without code changes.

**Why this priority**: Enables live tuning and supports future relic/upgrade modifiers.

**Independent Test**: Change the dash distance in the config file, restart, verify the new distance is used.

**Acceptance Scenarios**:

1. **Given** the config cooldown is changed to 3.0 seconds, **When** dodge is used, **Then** the button is unavailable for 3.0 seconds.
2. **Given** the config dash distance is changed to 500 units, **When** dodge is used, **Then** the player travels 500 units.

---

### Edge Cases

- What happens when the player has no prior movement direction (spawned or standing still)? → dash south.
- What happens if the player dodges into a wall — does the dash stop at the wall or clip through?
- Does invulnerability block all damage types (projectiles, contact, AoE)?
- The Dodge button is suppressed outside of an active run (hub room).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The HUD MUST display a Dodge button visible during active runs.
- **FR-002**: Tapping the Dodge button MUST move the player a fixed configured distance (default: 300 units) in their last recorded movement direction.
- **FR-003**: The player MUST be invulnerable to all damage for the entire duration of the dash movement.
- **FR-004**: Invulnerability MUST end as soon as the dash distance is fully covered.
- **FR-005**: After a dodge, the button MUST become inactive for the configured cooldown duration (default: 1.5 seconds).
- **FR-006**: The HUD button MUST reflect cooldown state visually (e.g., greyed out).
- **FR-007**: Dodge parameters (cooldown duration, dash distance) MUST be read from a data config file at startup.
- **FR-008**: If no prior movement direction is recorded, the dodge MUST use south as the default direction.
- **FR-009**: The Dodge button MUST only respond to input during an active run.

### Key Entities

- **Dodge Config**: Cooldown duration, dash distance — stored in `data/skills.json`.
- **Invulnerability State**: Boolean flag on the player's stats component; set true at dash start, false at dash end.
- **Last Movement Direction**: Normalised `Vector2` cached by the movement component each frame the player moves.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Player travels the configured dash distance each time Dodge is activated.
- **SC-002**: No damage is applied to the player during the dash in 100% of test cases.
- **SC-003**: The Dodge button becomes available again within ±0.05 seconds of the configured cooldown duration.
- **SC-004**: Changing any dodge parameter in the config file changes in-game behaviour without code modifications.

## Assumptions

- `skills.json` already exists and can host a new `"dodge"` entry.
- `DodgeComponent.gd` in `scenes/player/components/` already exists — the feature wires it up rather than creating from scratch.
- Invulnerability is modelled as a flag on `StatsComponent` that blocks incoming damage calls.
- Last movement direction is already tracked (or trivially addable) in `MovementComponent.gd`.
- The HUD button is added to `ExplorationHUD` alongside existing skill buttons.
- Dash speed is high enough that the fixed distance feels instantaneous; exact dash speed is an implementation detail derived from the distance config.
