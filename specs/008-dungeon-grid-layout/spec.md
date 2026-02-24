# Feature Specification: Dungeon Grid Layout

**Feature Branch**: `008-dungeon-grid-layout`
**Created**: 2026-02-24
**Status**: Draft
**Input**: "implement grid layout for dungeon. 5×5 grid canvas. player starts at center. expand randomly to neighbours until target room count (8) is reached. rooms picked randomly from CombatRoom* types. output rooms_by_id, neighbours_by_id, start_room_id. no scenes assigned during generation (room-at-a-time principle)."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Dungeon Layout Expands Organically from the Center (Priority: P1) 🎯 MVP

On run start, the dungeon generator computes a layout on a 5×5 virtual grid starting from the center cell. It expands outward one cell at a time by randomly selecting an unoccupied neighbour of any already-assigned cell, until a target of 8 rooms is recorded. The result is a data structure describing an organic, connected cluster that looks different every run. No scenes are loaded or instantiated during this step.

**Why this priority**: This is the core generation algorithm. Without it there is no dungeon layout. The random expansion produces layouts that feel hand-crafted without being repetitive, and the connected-from-center guarantee ensures the player always has a valid path through the dungeon.

**Independent Test**: Generate a dungeon. Inspect `rooms_by_id` — confirm exactly 8 entries. Inspect `neighbours_by_id` — confirm every room has at least one neighbour. Confirm `rooms_by_id` contains key `"room_2_2"`. Run twice more and confirm the key sets differ.

**Acceptance Scenarios**:

1. **Given** a dungeon is generated, **When** inspecting `rooms_by_id`, **Then** exactly 8 entries are present (TARGET_ROOM_COUNT).
2. **Given** a generated dungeon, **When** inspecting `neighbours_by_id`, **Then** every room_id maps to at least one neighbour — the cluster is fully connected.
3. **Given** a generated dungeon, **When** inspecting `rooms_by_id`, **Then** the key `"room_2_2"` (center cell) is always present.
4. **Given** three consecutive runs, **When** comparing the key sets of `rooms_by_id`, **Then** at least two produce different arrangements (randomness confirmed).
5. **Given** a 5×5 grid canvas, **When** generating 8 rooms, **Then** no entry in `rooms_by_id` encodes a grid position outside columns 0–4 or rows 0–4.

---

### User Story 2 - Random Combat Room Type per Cell (Priority: P1) 🎯 MVP

Each cell recorded during expansion is assigned a type chosen randomly and uniformly from all registered CombatRoom* types. Every cell in every run can be any combat room type.

**Why this priority**: Delivered together with US1 — expansion without random type variety produces a monotonous dungeon.

**Independent Test**: Generate a dungeon with 2+ CombatRoom types available. Inspect `rooms_by_id` values — confirm every `room_type_id` field is a CombatRoom* type. Confirm over several runs that both types appear.

**Acceptance Scenarios**:

1. **Given** a dungeon is generated, **When** inspecting `room_type_id` in each `rooms_by_id` entry, **Then** every value is a CombatRoom* type.
2. **Given** the CombatRoom* pool has 2 types, **When** generating across multiple runs, **Then** both types appear in `rooms_by_id` values.
3. **Given** only one CombatRoom* type exists, **When** generating, **Then** all 8 entries have that type — no error.

---

### User Story 3 - Player Placed at Center Room (Priority: P1) 🎯 MVP

After the layout is generated, the player is repositioned to the world position recorded for `start_room_id` (the center cell). This gives the player a central position with rooms branching outward in multiple directions.

**Why this priority**: Delivered with US1 and US2. Center placement is the payoff of center-first expansion — the player is always surrounded by reachable rooms from the start.

**Independent Test**: Generate a dungeon and start a run. Confirm the player's world position matches `rooms_by_id[start_room_id].world_pos` (which is always (0, 0)).

**Acceptance Scenarios**:

1. **Given** a dungeon is generated, **When** the run starts, **Then** the player is at the world position recorded in `rooms_by_id[start_room_id]` — always (0, 0).
2. **Given** `start_room_id`, **When** inspecting `neighbours_by_id[start_room_id]`, **Then** adjacent rooms exist in multiple directions confirming the player is surrounded by the layout.

---

### Edge Cases

- What if the 5×5 grid fills up before reaching TARGET_ROOM_COUNT? With 5×5 = 25 cells and a target of 8, this cannot happen. If the target ever exceeds 25, log an error and record as many rooms as possible.
- What if the CombatRoom* pool is empty? Log an error and produce no layout.
- What if no unexpanded neighbours remain before reaching target count? This cannot happen with TARGET_ROOM_COUNT ≤ 25 on a 5×5 grid, but if it does, log a warning and stop early.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The dungeon generator MUST assign rooms on a 5×5 virtual grid canvas (columns 0–4, rows 0–4).
- **FR-002**: Generation MUST start at the center cell (col 2, row 2).
- **FR-003**: Each expansion step MUST randomly select one unoccupied cell that is adjacent (N/S/E/W) to any already-occupied cell.
- **FR-004**: Expansion MUST stop when TARGET_ROOM_COUNT rooms are recorded. TARGET_ROOM_COUNT is a constant with a default value of 8.
- **FR-005**: Generation MUST be triggered by the `RunManager.run_started` signal, consistent with the existing dungeon generator pattern.
- **FR-006**: Each room's type MUST be selected randomly and uniformly from the `combat_room_pool` defined in `dungeon_config.json`.
- **FR-007**: Each room's world position MUST be calculated as `Vector2((col − 2) × SPACING_X, (row − 2) × SPACING_Y)` and stored in `rooms_by_id`.
- **FR-008**: Each room's ID MUST be `"room_{col}_{row}"` encoding its grid position, used as the key in `rooms_by_id`.
- **FR-009**: The player MUST be placed at the world position recorded in `rooms_by_id[start_room_id]` when the run starts.
- **FR-010**: If TARGET_ROOM_COUNT exceeds available grid cells, the generator MUST log an error and record as many rooms as possible.
- **FR-011**: If the combat pool is empty, the generator MUST log an error and produce no layout.
- **FR-012**: The `room_sequence` key in `dungeon_config.json` MUST be replaced by `combat_room_pool` (array of CombatRoom* type IDs).
- **FR-013**: The generator MUST expose `rooms_by_id: Dictionary` mapping each `room_id` to a record containing `room_type_id`, `grid_pos` (Vector2i), and `world_pos` (Vector2).
- **FR-014**: The generator MUST expose `neighbours_by_id: Dictionary` mapping each `room_id` to the array of adjacent room_ids that are also present in the generated layout.
- **FR-015**: The generator MUST expose `start_room_id: String` set to the center cell's room_id (`"room_2_2"`).
- **FR-016**: Generation MUST NOT instantiate or load any scene. Room scenes are loaded separately on a room-at-a-time basis by a different system.

### Key Entities

- **Grid Canvas**: A 5×5 virtual coordinate space. Each cell is identified by (col, row). Only occupied cells are recorded in the output.
- **Occupied Set**: The set of grid cells recorded during expansion. Internal to the generator; starts with just the center cell.
- **Frontier**: The set of unoccupied cells adjacent to any occupied cell. Internal to the generator; next room is always chosen from here.
- **Combat Room Pool**: Array of CombatRoom* type IDs in `dungeon_config.json`. Source of random type selection per cell.
- **TARGET_ROOM_COUNT**: Constant (default: 8). The number of rooms to record before generation stops.
- **rooms_by_id**: Generator output. Dictionary mapping room_id → `{ room_type_id, grid_pos, world_pos }`.
- **neighbours_by_id**: Generator output. Dictionary mapping room_id → Array of adjacent room_ids present in the layout.
- **start_room_id**: Generator output. String; always `"room_2_2"`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Every generated dungeon layout contains exactly TARGET_ROOM_COUNT (8) entries in `rooms_by_id`.
- **SC-002**: Every room in `neighbours_by_id` has at least one neighbour — the layout is a fully connected cluster.
- **SC-003**: The key `"room_2_2"` (center cell) is always present in `rooms_by_id`.
- **SC-004**: Over 5 runs, at least 3 produce a distinct set of room_id keys in `rooms_by_id` (confirms randomness).
- **SC-005**: `rooms_by_id`, `neighbours_by_id`, and `start_room_id` are all populated on every `run_started` signal emission.
- **SC-006**: Only CombatRoom* `room_type_id` values appear in `rooms_by_id` entries.
- **SC-007**: No errors or warnings in output for a valid scene load with correct config.

## Assumptions

- Grid canvas: 5×5 (25 cells). Target: 8 rooms. These values can never conflict (8 < 25).
- World origin is at (0, 0). The center cell (2, 2) maps to world position (0, 0). Other cells are offset by multiples of SPACING_X/SPACING_Y from there.
- SPACING_X: 2000 px (landscape room width 1920 px + 80 px gap).
- SPACING_Y: 1200 px (landscape room height 1080 px + 120 px gap).
- Neighbours are 4-directional only (N/S/E/W). Diagonal cells are not neighbours.
- Generation is triggered by the `RunManager.run_started` signal, consistent with the 007-dungeon-generator implementation.
- `room_sequence` key is removed from `dungeon_config.json` and replaced by `combat_room_pool`.
- EliteRoom and BossRoom types are excluded from this feature — placed at specific positions in a future feature.
- No corridors between rooms in this feature.
- Generation is a pure data step. Room scenes are loaded and placed in the scene tree by a separate system, on a room-at-a-time basis. That system is out of scope for this feature.
