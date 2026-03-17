# Feature Specification: Enemy Detection Radius

**Feature Branch**: `049-enemy-detection-radius`
**Created**: 2026-03-17
**Status**: Draft
**Input**: User description: "make data-driven detection radius that reads detection range from enemies.json"

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Enemy Detects Player at Correct Range (Priority: P1)

Each enemy type activates and pursues the player only when the player enters that enemy's configured detection radius. Different enemy types can have different detection ranges, all controlled by data without touching scenes.

**Why this priority**: Core behaviour — without this the detection_range field in enemies.json has no effect.

**Independent Test**: Place a Slime (detection_range 800) and a Skeleton (detection_range 800) in a room. Verify each begins pursuing the player exactly when the player crosses their respective radius.

**Acceptance Scenarios**:

1. **Given** an enemy type with a configured detection range, **When** the player enters that radius, **Then** the enemy begins pursuing the player.
2. **Given** an enemy type with a configured detection range, **When** the player is outside that radius, **Then** the enemy remains stationary.
3. **Given** two enemy types with different detection ranges, **When** the player moves through a room, **Then** each enemy activates independently at its own configured threshold.

---

### User Story 2 — Designer Tunes Range in Data Only (Priority: P2)

A game designer can change any enemy's detection range by editing enemies.json. No scene files or scripts need to be modified for the change to take effect.

**Why this priority**: This is the explicit goal of the feature — the value already exists in the data but is not yet applied.

**Independent Test**: Change a detection_range value in enemies.json, run the game, confirm the enemy's activation distance matches the new value exactly.

**Acceptance Scenarios**:

1. **Given** a detection_range value is changed in enemies.json, **When** the game runs, **Then** the enemy activates at the new distance with no other files changed.
2. **Given** detection_range is missing or zero for an enemy entry, **When** the game loads, **Then** a clear error is surfaced and a safe fallback is used rather than crashing.

---

### Edge Cases

- What if detection_range is 0 or negative in the data? Treat as a configuration error: log a warning and use a safe default (e.g. 300) rather than producing a zero-radius or broken collision shape.
- What if two enemies of the same type are in the same room? Each instance applies its own range independently — no shared state.
- What happens if an enemy is already overlapping the player when spawned? The enemy should immediately begin pursuing (detection fires on the first physics frame).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Each enemy instance MUST set its detection radius from the `detection_range` field in enemies.json for its enemy type, applied at spawn time before the enemy becomes active.
- **FR-002**: The detection radius MUST match the `detection_range` value exactly (in world-space pixels).
- **FR-003**: Changing `detection_range` in enemies.json MUST change enemy behaviour with no modifications to scene files or scripts.
- **FR-004**: If `detection_range` is missing, zero, or negative for an enemy type, the system MUST log a warning and apply a safe fallback value rather than crashing or producing a broken enemy.
- **FR-005**: Each enemy instance's detection radius MUST be independent — changing one instance does not affect others.

### Key Entities

- **EnemyData**: Existing typed wrapper; `detection_range: float` field already present and parsed from JSON.
- **Enemy scene**: The scene containing the detection collision shape; its radius must be set at runtime from `EnemyData.detection_range`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An enemy begins pursuing the player at a distance that matches its `detection_range` value in enemies.json within one physics frame (≤ 1/60 s).
- **SC-002**: Changing `detection_range` in enemies.json produces a measurably different activation distance with 100% consistency across all instances of that enemy type.
- **SC-003**: Zero enemy types have a hardcoded detection radius in any scene or script after this feature is complete.
- **SC-004**: An invalid (zero/negative/missing) detection_range entry produces a visible warning in the output log and does not crash the game.

## Assumptions

- `detection_range` values already exist and are valid in enemies.json for all current enemy types (slime, skeleton, boss = 800).
- The detection collision shape is a circle/sphere; setting its radius to `detection_range` directly maps to world-space pixels.
- The fallback value for invalid detection_range is 300 pixels — large enough to remain functional without being unreasonably large.
- Difficulty scaling (apply_difficulty) does not affect detection range — only max_health is scaled.
