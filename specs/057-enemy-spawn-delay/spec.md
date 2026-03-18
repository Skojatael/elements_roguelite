# Feature Specification: Enemy Spawn Delay

**Feature Branch**: `057-enemy-spawn-delay`
**Created**: 2026-03-18
**Status**: Draft
**Input**: User description: "add spawn delay timer as you suggested"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Enemies Pause Before Engaging (Priority: P1)

When enemies first appear in a room, they briefly stand still before chasing or damaging the player. This gives the player a moment to react to the newly spawned threat, especially important in the wave system where subsequent waves arrive mid-combat.

**Why this priority**: Core feel improvement — without a delay, enemies that spawn adjacent to the player deal immediate damage with no counterplay. This is the only user story; the feature is a single focused behaviour change.

**Independent Test**: Enter CombatRoom01, stand still. Observe that freshly spawned enemies do not move or deal contact damage for approximately 1–2 seconds after appearing. After the delay, they resume normal pursuit and contact damage behaviour.

**Acceptance Scenarios**:

1. **Given** an enemy has just spawned, **When** the player is within detection range, **Then** the enemy does not move or deal contact damage for 1–2 seconds.
2. **Given** the spawn delay has elapsed, **When** the player is within detection range, **Then** the enemy resumes normal pursuit and contact damage behaviour.
3. **Given** a wave system room with multiple waves, **When** wave 2 or 3 enemies spawn mid-combat, **Then** each newly spawned enemy individually waits its own delay before engaging.
4. **Given** an enemy is in its spawn delay, **When** the player attacks that enemy, **Then** the enemy can still take damage and be defeated normally.

---

### Edge Cases

- Enemy killed during its spawn delay — should die normally without errors.
- Player standing on top of the enemy spawn point — delay still prevents immediate contact damage.
- All enemies in a wave share the same delay range; their individual timers run independently.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every enemy MUST have a non-reactive delay of 1–2 seconds (random per instance) immediately after spawning.
- **FR-002**: During the delay, the enemy MUST NOT move toward the player.
- **FR-003**: During the delay, the enemy MUST NOT deal contact damage to the player.
- **FR-004**: The delay MUST be a fixed 1.0 second for all enemy instances.
- **FR-005**: After the delay expires, the enemy MUST resume all normal behaviours (detection, pursuit, contact damage).
- **FR-006**: Taking damage during the delay MUST function normally — the enemy can be hurt and killed.

### Key Entities

- **Enemy**: Gains a per-instance spawn delay timer that governs its initial inactive window.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of enemies are visually stationary for at least 1 second after spawning when the player is within detection range.
- **SC-002**: No contact damage is received by the player from an enemy within its first 1 second of existence.
- **SC-003**: All enemies engage normally within 2 seconds of spawning under standard conditions.
- **SC-004**: Enemies hit during their spawn delay respond to damage and death correctly in all observed cases.

## Assumptions

- Delay range of 1–2 seconds is fixed in code; no data-driven configuration needed for this iteration.
- The delay applies to all enemy types uniformly.
- Visual feedback (e.g. flash, opacity) during the delay is out of scope.
