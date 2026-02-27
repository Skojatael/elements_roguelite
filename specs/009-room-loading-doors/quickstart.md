# Quickstart / Validation Guide: Room Loading & Doors (009)

**Date**: 2026-02-24
**Feature**: [spec.md](spec.md)

These are the manual validation steps to confirm the feature works correctly after implementation.

**How to test**: Open `project.godot` in Godot 4.6. Run the game with F5 (or the Play button). Use the **Remote** tab in the Scene dock to inspect live nodes. The Output panel shows `[RoomLoader]` print statements on each room load.

---

## Prerequisites

- `data/dungeon_config.json` has `"StartRoom01": { "spawn_points": [] }` in `spawn_configs`.
- `data/rooms/StartRoom01.tres` exists with `room_type_id = "StartRoom01"` and correct scene reference.
- `scenes/dungeon/rooms/StartRoom01.tscn` exists (inherited from RoomBase.tscn).
- `scenes/dungeon/doors/Door.tscn` exists with Area2D + CollisionShape2D (200×200).
- `RoomBase.tscn` has four door slot children: `DoorN`, `DoorS`, `DoorE`, `DoorW`.
- `RoomLoader` node is a child of `Main.tscn`.
- `DungeonGenerator` emits `dungeon_layout_ready` signal.
- The game's `start_run()` is reachable (dev panel or auto-call).

---

## Scenario 1 — Start Room Loads Immediately (FR-001, SC-001)

1. Start a run.
2. In the Remote tab, inspect the scene tree under `Main`.
3. **Expected**: a `StartRoom01` node is present in the scene tree. The player node is visible and inside it.

---

## Scenario 2 — Player Placed at Room Center (FR-001, SC-001)

1. Start a run.
2. In the Remote inspector, check the Player node's `global_position`.
3. **Expected**: `global_position = (0, 0)` — matching the start room's `world_pos`.

---

## Scenario 3 — No Enemies in Start Room (FR-002, SC-002)

1. Start a run.
2. Inspect the start room scene tree in the Remote tab.
3. **Expected**: no enemy nodes are present. The `RoomSpawner` on `StartRoom01` shows `_spawned = false` and `_living_count = 0` (or equivalent empty state).

---

## Scenario 4 — Doors Match Neighbours (FR-003, FR-004, SC-003)

1. Start a run.
2. Inspect `DungeonGenerator.neighbours_by_id["room_2_2"]` in the Remote inspector — note how many neighbours the start room has.
3. In the Remote scene tree, inspect the start room's door nodes.
4. **Expected**: exactly as many door nodes are visible (`visible = true`) as there are neighbours. All other door nodes are hidden (`visible = false`).
5. Repeat for a second run with a different layout shape and confirm the door count matches again.

---

## Scenario 5 — Door Touch Transitions to Adjacent Room (FR-005, SC-004)

1. Start a run. Note the start room is `StartRoom01`.
2. Walk the player into any visible door.
3. **Expected**:
   - `StartRoom01` is no longer present in the Remote scene tree.
   - A new combat room node is present.
   - The player is inside the new room.
4. Check the Output panel: a `[RoomLoader]` log line should appear for the new room load.

---

## Scenario 6 — Player Placed at Correct Entrance (FR-006, SC-004)

1. Start a run. Note which door is visible (e.g., the east door).
2. Touch the east door.
3. In the Remote inspector, check the Player's `global_position` in the new room.
4. **Expected**: the player is near the west entrance of the new room — approximately `world_pos + Vector2(-810, 0)`. The exact position is `new_room.world_pos + Vector2(-810, 0)` for east→west entry.
5. Verify the player is NOT at the room center and NOT at the exact wall edge.

---

## Scenario 7 — Only One Room in Scene at a Time (FR-011, SC-005)

1. Start a run. Move through several rooms.
2. After each room transition, inspect the Remote scene tree.
3. **Expected**: at most one room node (e.g., `CombatRoom01`, `CombatRoom02`, or `StartRoom01`) is present under `Main` at any time. No previous room nodes linger.

---

## Scenario 8 — Re-Enter Cleared Room Has No Enemies (FR-007, SC-006)

1. Start a run. Enter a combat room. Clear all enemies (defeat every enemy).
2. Go back through the door you entered from.
3. Re-enter the cleared room through its door again.
4. **Expected**: the room is instantiated fresh with zero enemies. The `RoomSpawner` does not spawn because `RunManager.is_room_cleared(room_id)` returns `true`.

---

## Scenario 9 — Re-Enter Non-Cleared Room Respawns Enemies (FR-007, SC-006)

1. Start a run. Enter a combat room. Do NOT defeat any enemies.
2. Go back through the door you entered from (retreat to previous room).
3. Re-enter the combat room.
4. **Expected**: a fresh set of enemies spawns. The room was not cleared, so `RoomSpawner` spawns new enemies on re-entry.

---

## Scenario 10 — Directional Continuity (FR-006)

1. Start a run. Touch the east door of the start room to enter room B.
2. In room B, touch the west door to return to the start room.
3. **Expected**: the player appears near the east entrance of the start room — approximately `Vector2(810, 0)` relative to the start room center (i.e., `world_pos + Vector2(810, 0)`).
4. The entry side matches the direction of the door just touched.

---

## Scenario 11 — Duplicate Door Touch Ignored (Edge Case)

1. Start a run. Position the player on a door.
2. Observe the transition start (room begins loading).
3. During the transition, there should be no duplicate room load or error.
4. **Expected**: only one room load occurs. The `_loading` guard prevents re-entrance. Output panel shows a single load log, not two.

---

## Scenario 12 — Missing RoomData Asset (Edge Case)

1. Temporarily rename `data/rooms/CombatRoom01.tres` to `_CombatRoom01.tres`.
2. Start a run. Touch a door that leads to a `CombatRoom01` room.
3. **Expected**: a `push_error` appears in the Output panel. The current room is not freed — the player remains in the current room. No crash.
4. Restore the file name.

---

## Scenario 13 — Missing `neighbours_by_id` (Edge Case)

1. Temporarily break `DungeonGenerator` so it does not populate `neighbours_by_id` (e.g., comment out `_build_neighbours(occupied)`).
2. Start a run.
3. **Expected**: `push_warning` appears. The start room loads with no doors visible (no exits). No crash.
4. Restore the code.
