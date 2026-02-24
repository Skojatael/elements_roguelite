# Data Model: Dungeon Grid Layout (008)

**Date**: 2026-02-24
**Feature**: [spec.md](spec.md)

---

## Persistent Data (JSON Config)

### `data/dungeon_config.json` — updated schema

The `room_sequence` key is removed and replaced by `combat_room_pool`.

```json
{
  "combat_room_pool": ["CombatRoom01", "CombatRoom02"],
  "spawn_configs": {
    "CombatRoom01": { "spawn_points": [ ... ] },
    "CombatRoom02": { "spawn_points": [ ... ] }
  }
}
```

| Field | Type | Description |
|---|---|---|
| `combat_room_pool` | `Array[String]` | Unordered pool of CombatRoom* type IDs available for random selection. Must not be empty. |
| `spawn_configs` | `Dictionary` | Unchanged. Keyed by room type ID; used by the scene-loading system for enemy instantiation. |

**Validation rules**:
- `combat_room_pool` must be present and non-empty; generator logs error and halts if absent or empty.

---

## Generator Output Properties

These three properties are written by `DungeonGenerator._generate()` and exposed publicly on the `DungeonGenerator` node. They are populated before `_place_player()` is called and remain readable for the lifetime of the run.

### `rooms_by_id: Dictionary`

Maps each `room_id` (String) to a record Dictionary describing that room.

```text
rooms_by_id = {
  "room_2_2": { "room_type_id": "CombatRoom01", "grid_pos": Vector2i(2, 2), "world_pos": Vector2(0, 0) },
  "room_1_2": { "room_type_id": "CombatRoom02", "grid_pos": Vector2i(1, 2), "world_pos": Vector2(-2000, 0) },
  ...
}
```

| Record Field | Type | Description |
|---|---|---|
| `room_type_id` | `String` | The CombatRoom* type assigned to this cell (e.g. `"CombatRoom01"`). |
| `grid_pos` | `Vector2i` | The cell's column and row in the 5×5 grid. |
| `world_pos` | `Vector2` | The cell's world-space position, computed as `Vector2((col−2)×2000, (row−2)×1200)`. |

**Invariants**:
- Always contains exactly `TARGET_ROOM_COUNT` (8) entries after a successful generation.
- Always contains key `"room_2_2"` (center cell).
- All `room_type_id` values are from `combat_room_pool`.
- Cleared and rebuilt on each `run_started` signal.

---

### `neighbours_by_id: Dictionary`

Maps each `room_id` (String) to an `Array[String]` of room_ids that are adjacent (N/S/E/W) and present in this layout.

```text
neighbours_by_id = {
  "room_2_2": ["room_1_2", "room_3_2", "room_2_1"],
  "room_1_2": ["room_2_2", "room_1_3"],
  ...
}
```

**Invariants**:
- Contains the same keys as `rooms_by_id`.
- Adjacency is bidirectional: if A is in B's list, B is in A's list.
- Every entry has at least one neighbour (connectivity guarantee from frontier expansion).
- Cleared and rebuilt on each `run_started` signal.

---

### `start_room_id: String`

The room_id of the center cell. Always `"room_2_2"`. Set immediately after the center room is recorded.

Used to place the player at the correct world position without the caller needing to know the center cell coordinates.

---

## Internal Runtime Structures

These exist only during `_generate()` execution and are not exposed as properties.

### `occupied: Dictionary[Vector2i → String]`

Temporary map from grid cell to room_id, used to track which cells have been assigned and to avoid duplicates in the frontier.

### `frontier: Array[Vector2i]`

Candidate cells for the next expansion step. Cells enter the frontier when a neighbouring cell is occupied; they leave when selected for placement.

---

## World Position Mapping

| Grid Cell | World Position |
|---|---|
| (0, 0) | (−4000, −2400) |
| (2, 2) | (0, 0) ← center / player start |
| (4, 4) | (4000, 2400) |
| (col, row) | `Vector2((col − 2) × 2000, (row − 2) × 1200)` |

Constants: `SPACING_X = 2000`, `SPACING_Y = 1200`.
