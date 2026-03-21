# Feature Specification: Healer Follow Behavior

**Feature Branch**: `078-healer-follow-behavior`
**Created**: 2026-03-21
**Status**: Draft
**Input**: User description: "introduce new behaviour for healers (*_healer in enemies.json). they should follow closest enemy at a distance that is heal_radius - 20. if closest enemy changes, they should follow the new closest enemy."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Healer Orbits Its Closest Ally (Priority: P1)

Healer enemies reposition themselves to stay near their closest ally rather than chasing the player directly. A healer always tries to maintain a distance of exactly `heal_radius - 20` units from its nearest ally — close enough to cover them with its heal, far enough not to crowd them. This makes healer enemies feel purposeful: they visibly protect their allies and reward the player for isolating or kiting them.

**Why this priority**: This is the entire feature. Without it, healers move like generic enemies. With it, they behave as a support role that creates tactical decisions (kill the healer first, break line of support, isolate allies from the healer).

**Independent Test**: Spawn a healer alongside one ally enemy. Observe the healer move toward the ally and stop once the gap between them equals `heal_radius - 20`. Move the player around — the healer should not chase the player; it should hold position relative to its ally.

**Acceptance Scenarios**:

1. **Given** a healer enemy and at least one ally enemy are alive in the room, **When** the healer's distance to its closest ally is greater than `heal_radius - 20`, **Then** the healer moves toward that ally until the gap equals `heal_radius - 20`.
2. **Given** a healer is at exactly `heal_radius - 20` distance from its closest ally, **When** no other change occurs, **Then** the healer does not move (it holds position).
3. **Given** a healer has multiple allies alive, **When** a different ally becomes the geometrically closest one (because enemies moved), **Then** the healer updates its follow target to the new closest ally and repositions accordingly.
4. **Given** a healer is following ally A and ally A dies, **When** ally B is still alive, **Then** the healer immediately switches to following ally B.
5. **Given** the player moves, **When** the healer has living allies, **Then** the healer does NOT pursue the player — it only adjusts position relative to its current follow target.

---

### User Story 2 - Healer Falls Back to Default Behavior When Alone (Priority: P2)

If all allies in the room are dead and only the healer remains, it should revert to the standard enemy movement behavior (chasing the player) so the encounter does not stall.

**Why this priority**: Without this, a lone healer would stand idle — an anti-climactic and confusing end to a wave. Falling back to standard behavior keeps the encounter completable.

**Independent Test**: Kill all non-healer enemies in a room. Observe the healer stop holding position and begin chasing the player like a standard enemy.

**Acceptance Scenarios**:

1. **Given** a healer has no living allies in the room, **When** any time passes, **Then** the healer moves toward the player using the standard enemy chase behavior.
2. **Given** the last ally dies while the healer was in follow mode, **When** the death is registered, **Then** the healer immediately transitions to chasing the player.
3. **Given** a healer starts a room alone (no allies spawned), **When** the room begins, **Then** the healer chases the player from the start.

---

### Edge Cases

- What if `heal_radius - 20 <= 0`? → The follow distance is clamped to 0 (healer stays on top of the ally). This should not occur with well-authored data but must not crash.
- What if two allies are equidistant from the healer at the same time? → Either may be chosen as the follow target; consistency is not required for ties.
- What if the healer is exactly at the follow distance but its ally is still moving? → The healer continues tracking and adjusting, essentially keeping pace with a moving ally.
- What if there are multiple healers? → Each healer independently picks its own closest ally; they may end up orbiting the same enemy or different ones.
- What if the healer's closest ally is the player? → The player is never considered an ally — only other Enemy instances count.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Any enemy whose `id` ends in `_healer` (as stored in enemies.json) MUST use the follow behavior described below instead of the default player-chase movement, whenever at least one other living enemy is present in the room.
- **FR-002**: The healer MUST continuously track the closest living ally enemy (by Euclidean distance, measured every frame).
- **FR-003**: The healer MUST move toward its current follow target when its distance to that target is greater than `heal_radius - 20` units.
- **FR-004**: The healer MUST stop moving toward the target when its distance to that target equals `heal_radius - 20` (within movement step tolerance).
- **FR-005**: When the closest ally changes (another ally becomes geometrically closer), the healer MUST update its follow target on the same frame the change is detected, with no delay.
- **FR-006**: When all allies in the room are dead, the healer MUST immediately revert to the standard player-chase movement behavior.
- **FR-007**: The healer's movement speed MUST remain unchanged — it uses the same `move_speed` value as always; only the destination changes.
- **FR-008**: The follow distance MUST be derived from the healer's own `heal_radius` data field minus 20 — it is not a global constant.
- **FR-009**: The behavior MUST be implemented without modifying any non-healer enemy's movement logic.

### Key Entities

- **Enemy (healer instance)**: Identifies itself as a healer via its `id` suffix. At runtime holds a reference to its current follow target (another Enemy node). Recomputes closest ally each frame. Moves toward target at `heal_radius - 20` standoff distance, or chases player if no allies exist.
- **EnemyData**: Already contains `heal_radius` — no new data fields are required for this feature.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A healer spawned alongside allies visibly moves toward and holds position near an ally rather than the player, observable in any combat room with mixed enemy types.
- **SC-002**: When one ally dies and a farther ally becomes the new closest, the healer begins moving toward the new target within one update frame — no visible hesitation or stuck behavior.
- **SC-003**: A healer left alone in the room after all allies die transitions to chasing the player within one update frame.
- **SC-004**: Non-healer enemies in the same room exhibit no change in movement behavior — zero regressions in existing enemy AI.
- **SC-005**: The standoff distance is `heal_radius - 20` units, verifiable by pausing or inspecting positions when the healer is holding still.

## Assumptions

- "Closest ally" is determined by Euclidean distance from the healer to each other living Enemy node in the current room scope — not by navigation path length.
- The healer checks for the closest ally every frame (in `_process` or `_physics_process`), not on a timer.
- "Living" means the enemy node exists and has `current_health > 0`.
- The healer does NOT change its attack target — it may still damage the player if the player comes within attack range. Only its movement destination changes.
- The player is never considered an ally and is excluded from the closest-ally search.
- The follow target update is instantaneous (same frame) — no lerp or smoothing is added to target switching in this feature.
