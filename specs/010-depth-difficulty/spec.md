# Feature Specification: Dungeon Depth & Difficulty Scaling

**Feature Branch**: `010-depth-difficulty`
**Created**: 2026-02-27
**Status**: Draft
**Input**: "add depth to dungeon. it should be calculated using manhattan distance. add difficulty scaling. difficulty_mult = 1.0 + 0.12 * depth. if depth >= some value, create an elite room in a dungeon (1 or 2), do this every 2 depth"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Every Room Has a Depth (Priority: P1) 🎯 MVP

Every room in a dungeon run is assigned a depth — the minimum number of room-to-room steps from the starting room. The starting room is depth 0; each step away adds 1. Depth is computed once when a run begins and does not change.

**Why this priority**: Depth is the foundation for every other story. Without it, difficulty scaling and elite room placement have no input. It is a pure data computation with no visible player-facing effect on its own, but it unblocks everything else.

**Independent Test**: Start a run. Inspect the dungeon layout data. Confirm the start room has depth 0. Confirm every other room has a depth equal to its minimum room-to-room step count from the start room. Confirm rooms one step away have depth 1, rooms two steps away have depth 2, and so on.

**Acceptance Scenarios**:

1. **Given** a dungeon is generated, **When** inspecting each room's depth, **Then** the start room has depth 0 and every other room's depth equals its shortest path (in room hops) from the start room.
2. **Given** a room is 2 steps from the start, **When** inspecting its depth, **Then** its depth is 2 regardless of world-space distance.
3. **Given** a run ends and a new one begins, **When** the new dungeon is generated, **Then** depths are recalculated fresh for the new layout.

---

### User Story 2 - Deeper Rooms Have Tougher Enemies (Priority: P1) 🎯 MVP

Enemies in deeper rooms are harder to defeat — they have more health the further the room is from the start. The scaling formula is: `difficulty multiplier = 1.0 + 0.12 × depth`. A room at depth 0 has a 1.0× multiplier (no change); depth 1 has 1.12×; depth 3 has 1.36×; and so on. In this feature, the multiplier applies to enemy maximum health only.

**Why this priority**: This is the core gameplay value of the feature. The dungeon feels spatially meaningful only when going deeper is genuinely more dangerous. The formula provides a smooth, predictable ramp that rewards risk-taking.

**Independent Test**: Start a run. Enter a room at depth 1 and observe enemy health. Enter a room at depth 2 and observe enemy health. Confirm depth-2 enemies have proportionally more health (1.24× relative to depth-0 baseline, 1.11× relative to depth-1 enemies).

**Acceptance Scenarios**:

1. **Given** a room at depth 1, **When** enemies spawn, **Then** their maximum health is 1.12× the base value.
2. **Given** a room at depth 3, **When** enemies spawn, **Then** their maximum health is 1.36× the base value.
3. **Given** the start room (depth 0), **When** the run begins, **Then** the difficulty multiplier is 1.0 (no scaling — and the start room has no enemies anyway).
4. **Given** a cleared room is re-entered, **When** revisiting it, **Then** its depth and multiplier are unchanged (no re-computation on re-entry).

---

### User Story 3 - Elite Rooms Appear at Depth Milestones (Priority: P1) 🎯 MVP

At dungeon generation time, rooms at specific depth milestones are promoted to elite rooms. Elite rooms replace the standard combat room at that position with a tougher encounter. The milestone rule: starting at depth 2, every 2 depth levels is a milestone (depth 2, depth 4, depth 6…). At each milestone, one room at that exact depth is randomly chosen to become elite. If no room exists at a milestone depth, the milestone is skipped.

With a typical 8-room dungeon, this produces 1–2 elite rooms per run:
- Depth-2 milestone: almost always has 1+ rooms → 1 elite room promoted
- Depth-4 milestone: rarely reached in a small dungeon → 0–1 additional elite rooms

Elite rooms use the existing dedicated elite room type and receive the same depth-based difficulty multiplier as any combat room at that depth.

**Why this priority**: Elite rooms are the dungeon's high-stakes moments — a clear signal to the player that they have reached dangerous territory. They are designed alongside depth and difficulty scaling as part of the same system.

**Independent Test**: Start 5 runs. In each, inspect the dungeon layout. Confirm 1–2 rooms are marked as elite type. Confirm every elite room is at depth 2 or depth 4. Confirm no elite rooms appear at depth 0, 1, or 3. Confirm exactly one room per qualifying depth level is elite (never two at the same depth).

**Acceptance Scenarios**:

1. **Given** a dungeon is generated, **When** inspecting all rooms, **Then** rooms at depth 2 and depth 4 (if they exist) have exactly one elite room each; all other rooms are combat rooms.
2. **Given** a depth-2 milestone, **When** multiple rooms exist at depth 2, **Then** exactly one is randomly promoted to elite; the others remain combat rooms.
3. **Given** no room exists at depth 4, **When** that milestone is evaluated, **Then** it is silently skipped and no error occurs.
4. **Given** an elite room at depth 2, **When** enemies spawn inside it, **Then** they use the depth-2 difficulty multiplier (1.24×), same as any other room at that depth.
5. **Given** an elite room is cleared and re-entered, **When** the player returns, **Then** it is still the elite room type and spawns no enemies (cleared state preserved).

---

### Edge Cases

- What if no room exists at depth 2? The milestone is skipped — this should be theoretically impossible with 8 rooms expanding from the center, but is handled silently if it occurs.
- What if two rooms are at depth 4 and the depth-4 milestone fires? One is chosen at random; the other remains a combat room.
- What if the dungeon has fewer than 8 rooms due to frontier exhaustion? Depth and difficulty_mult are still computed for all rooms that exist; elite milestones apply normally.
- What if the player re-enters a room? Its depth, multiplier, and room type do not change. Cleared rooms retain their cleared state regardless of type.
- What if a future feature adds depth 6 to the reachable grid? The milestone rule extends naturally (depth 6 would also be a milestone) without any changes to the rule definition.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Every room in the dungeon layout MUST be assigned a depth value equal to the minimum number of room-to-room steps from the start room (grid Manhattan distance).
- **FR-002**: The start room MUST always have depth 0.
- **FR-003**: Every room MUST have a difficulty multiplier computed as `1.0 + 0.12 × depth`, where depth is that room's depth value.
- **FR-004**: Enemies spawned in a room MUST have their maximum health scaled by that room's difficulty multiplier.
- **FR-005**: The difficulty multiplier MUST affect maximum health only in this feature. Damage, speed, and other stats are unaffected.
- **FR-006**: Depth values and difficulty multipliers MUST be computed at dungeon generation time and stored with each room's data for the duration of the run.
- **FR-007**: At dungeon generation time, elite depth milestones MUST be evaluated in ascending order: 2, 4, 6, 8… (every 2 starting at 2).
- **FR-008**: For each milestone, if one or more rooms exist at that exact depth, exactly one of them MUST be randomly selected and promoted to the elite room type.
- **FR-009**: For each milestone, if no room exists at that depth, the milestone MUST be silently skipped — no error, no elite room forced elsewhere.
- **FR-010**: The elite room type used for promotion MUST be the dedicated elite room type (distinct from any CombatRoom type).
- **FR-011**: Elite rooms MUST receive the same depth-based difficulty multiplier as any other room at that depth.
- **FR-012**: A promoted elite room MUST NOT also appear in the random combat room pool — once promoted, its type is elite only.
- **FR-013**: Depth and difficulty multiplier values MUST be recomputed fresh for each new run and MUST NOT carry over from a previous run.

### Key Entities

- **Room Depth**: An integer assigned to each room at generation time. Always 0 for the start room. Equals the minimum number of room steps from the start room.
- **Difficulty Multiplier**: A floating-point scaling factor per room. Derived from depth via `1.0 + 0.12 × depth`. Applied to enemy maximum health at spawn time.
- **Elite Depth Milestone**: A depth value in the sequence 2, 4, 6… At each milestone, one room is promoted to elite type.
- **Elite Room**: A room whose type has been changed from a standard combat type to the dedicated elite type at generation time. Follows normal cleared-state rules.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every room in every generated dungeon has a depth value; the start room always has depth 0; no room has a negative depth.
- **SC-002**: The difficulty multiplier formula is correctly applied — a room at depth 3 has multiplier exactly 1.36; a room at depth 2 has exactly 1.24.
- **SC-003**: Across 10 runs, every run contains at least 1 elite room and no run contains more than 2 elite rooms.
- **SC-004**: In every run, all elite rooms are located at depth 2 or depth 4 — never at any other depth.
- **SC-005**: Enemies in a depth-2 room have exactly 1.24× the maximum health of an equivalent enemy in a depth-0 room.
- **SC-006**: No errors or warnings in the output for a valid dungeon layout.

## Assumptions

- Depth is computed from grid coordinates (Manhattan distance in grid steps), not world-space Euclidean distance.
- The formula `1.0 + 0.12 × depth` is fixed and not configurable in this feature. Tuning it is a future concern.
- The starting elite milestone is T = 2 and the step size is 2; these values are constants, not data-driven, in this feature.
- Elite rooms use the existing `EliteRoom01` scene and room type (already present in the codebase). No new elite scene is created.
- Difficulty multiplier affects enemy maximum health only. Damage output and other stats are deferred.
- Depth and difficulty_mult are stored as part of the dungeon layout data (extending the existing room record structure). They are produced by the same system that generates the layout.
- The depth calculation is performed using the same grid-adjacency data that already exists in the neighbours-by-room map — no new pathfinding algorithm is needed.
- The start room (depth 0, no enemies) will always have a multiplier of 1.0, which is effectively unused since no enemies spawn there.
- This feature depends on the dungeon layout being available before room scenes are loaded (guaranteed by the existing `dungeon_layout_ready` signal chain from feature 009).
