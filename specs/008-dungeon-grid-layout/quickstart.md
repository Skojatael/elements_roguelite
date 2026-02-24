# Quickstart / Validation Guide: Dungeon Grid Layout (008)

**Date**: 2026-02-24
**Feature**: [spec.md](spec.md)

These are the manual validation steps to confirm the feature works correctly after implementation.

**How to inspect output**: In Godot, run the game and use the **Remote** tab in the Scene dock. Select the `DungeonGenerator` node — its `rooms_by_id`, `neighbours_by_id`, and `start_room_id` properties are readable in the Inspector. Alternatively, the generator prints a layout summary to the Output panel on every generation.

---

## Prerequisites

- `data/dungeon_config.json` has `"combat_room_pool": ["CombatRoom01", "CombatRoom02"]` (no `room_sequence`).
- `DungeonGenerator` node is a child of Main.tscn in the Godot Editor.
- The game's `start_run()` is reachable (dev panel or auto-call).

---

## Scenario 1 — Room Count (SC-001)

1. Start a run.
2. In the remote inspector, select `DungeonGenerator` and inspect `rooms_by_id`.
3. **Expected**: `rooms_by_id` has exactly 8 keys.

---

## Scenario 2 — Center Cell Always Present (SC-003)

1. Start a run.
2. Inspect `rooms_by_id` on `DungeonGenerator`.
3. **Expected**: key `"room_2_2"` is always present. Its `world_pos` entry is `(0, 0)`.

---

## Scenario 3 — `start_room_id` (FR-015)

1. Start a run.
2. Inspect `start_room_id` on `DungeonGenerator`.
3. **Expected**: value is `"room_2_2"`.

---

## Scenario 4 — Player at Center (FR-009)

1. Start a run.
2. Check the Player node's `global_position` in the remote inspector.
3. **Expected**: Player position is `(0, 0)` — matching `rooms_by_id["room_2_2"].world_pos`.

---

## Scenario 5 — Connectivity (SC-002)

1. Start a run.
2. Inspect `neighbours_by_id` on `DungeonGenerator`.
3. **Expected**: every key maps to a non-empty Array — no room is isolated.
4. Cross-check: if room A lists room B as a neighbour, room B must list room A (bidirectional).

---

## Scenario 6 — Grid Boundary (FR-001)

1. Start a run.
2. For each key in `rooms_by_id`, decode (col, row) from the name (e.g. `"room_1_3"` → col=1, row=3).
3. **Expected**: all values satisfy `0 ≤ col ≤ 4` and `0 ≤ row ≤ 4`.

---

## Scenario 7 — Only CombatRoom* Types (SC-006)

1. Start a run.
2. For each entry in `rooms_by_id`, check the `room_type_id` field.
3. **Expected**: all values are `"CombatRoom01"` or `"CombatRoom02"` — no EliteRoom, BossRoom, or others.

---

## Scenario 8 — Both Pool Types Appear (US2 AS2)

1. Run the game 5 times.
2. Check `room_type_id` values in `rooms_by_id` across all runs.
3. **Expected**: both `CombatRoom01` and `CombatRoom02` appear across the 5 runs.

---

## Scenario 9 — Randomness (SC-004)

1. Start three separate runs.
2. Record the full set of `rooms_by_id` keys for each run.
3. **Expected**: at least two of the three runs produce different key sets (different layout shapes).

---

## Scenario 10 — World Position Formula (FR-007)

1. Start a run.
2. Pick any room from `rooms_by_id`, e.g. `"room_3_1"` (col=3, row=1).
3. **Expected**: `world_pos = Vector2((3-2)*2000, (1-2)*1200) = Vector2(2000, -1200)`.

---

## Scenario 11 — Clean Re-Run (Decision 5)

1. Start a run. Record the `rooms_by_id` key set.
2. Without restarting the game, start a second run.
3. Inspect `rooms_by_id` again.
4. **Expected**: `rooms_by_id` is rebuilt (8 entries, potentially different layout). Previous data is gone.

---

## Scenario 12 — Empty Pool Error Handling (FR-011)

1. Temporarily edit `dungeon_config.json` to set `"combat_room_pool": []`.
2. Start a run.
3. **Expected**: an error is printed via `push_error`. `rooms_by_id`, `neighbours_by_id`, `start_room_id` are empty. No crash.
4. Restore the config.

---

## Scenario 13 — Missing Config Key (FR-011)

1. Temporarily edit `dungeon_config.json` to remove `combat_room_pool` entirely.
2. Start a run.
3. **Expected**: an error is printed and generation halts gracefully. No crash.
4. Restore the config.

---

## Scenario 14 — No Scenes in Scene Tree (FR-016)

1. Start a run.
2. Inspect the scene tree in the Remote tab.
3. **Expected**: no `room_*` nodes appear as children of Main (or anywhere). Generation produces data only.
