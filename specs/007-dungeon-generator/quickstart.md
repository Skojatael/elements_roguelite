# Quickstart Validation: Dungeon Generator

**Feature**: 007-dungeon-generator
**Date**: 2026-02-23
**Prerequisites**: 006-room-factory complete (RoomData .tres assets exist in `data/rooms/`)

Run each scenario manually in the Godot Editor (Play Scene on Main.tscn). Check the Output panel for logs and inspect the scene tree via the Remote tab in the Editor.

---

## Scenario 1 — Three rooms spawn on run start

**Setup**: Main.tscn has DungeonGenerator node; `dungeon_config.json` has `room_sequence`; all three `.tres` files exist.

**Action**: Press Play. A run starts automatically via `RunManager.start_run("endless")` in `Main._ready()`.

**Expected**:
- Output contains:
  ```
  [DungeonGenerator] spawned type='CombatRoom01' id='room_0' at (0, 0)
  [DungeonGenerator] spawned type='CombatRoom02' id='room_1' at (1200, 0)
  [DungeonGenerator] spawned type='EliteRoom01' id='room_2' at (2400, 0)
  ```
- Remote scene tree shows three room nodes as children of Main.
- No errors or warnings in Output.

---

## Scenario 2 — Rooms are spaced 1200 px apart

**Action**: After Play, open Remote tab in the SceneTree. Select each spawned room node.

**Expected**:
- `CombatRoom01` (room_0): `global_position ≈ (0, 0)`
- `CombatRoom02` (room_1): `global_position ≈ (1200, 0)`
- `EliteRoom01` (room_2): `global_position ≈ (2400, 0)`
- Distance between consecutive rooms is exactly 1200 px on X.

---

## Scenario 3 — Room IDs are assigned correctly

**Action**: In the Remote scene tree, inspect each room's `RoomSpawner` child node.

**Expected**:
- `room_0/RoomSpawner.room_id = "room_0"`
- `room_1/RoomSpawner.room_id = "room_1"`
- `room_2/RoomSpawner.room_id = "room_2"`
- `auto_register = false` on all three (factory path).

---

## Scenario 4 — Player placed at first room's position

**Action**: Press Play. Inspect Player node in Remote scene tree.

**Expected**:
- `Player.global_position ≈ (0, 0)` (matches room_0 origin).
- Output contains: `[DungeonGenerator] player placed at (0, 0)`

---

## Scenario 5 — room_entered fires when player enters room

**Action**: Press Play. Move player into the EntryArea of the first room.

**Expected**:
- Output contains: `[RoomSpawner] player entered room 'room_0'`
- Output contains: `[RunManager] room entered 'room_0' — index=1`

---

## Scenario 6 — Missing RoomData .tres logs error and stops

**Setup**: Temporarily rename `data/rooms/CombatRoom01.tres` to `CombatRoom01.tres.bak`.

**Action**: Press Play.

**Expected**:
- Output contains an error: `RoomFactory: room_data is null` or `DungeonGenerator: RoomData not found for type='CombatRoom01'`
- Fewer than 3 rooms appear (spawning stopped at the missing asset).
- No crash.

**Teardown**: Rename `CombatRoom01.tres.bak` back to `CombatRoom01.tres`.

---

## Scenario 7 — run_started fires correctly (re-start)

**Setup**: DevPanel is visible (DEV_MODE = true).

**Action**: Press "Start Run" in DevPanel (triggers a second `RunManager.start_run("endless")`).

**Expected**:
- A new set of three rooms is spawned (existing rooms from the first run remain — cleanup is out of scope).
- Output repeats the three `[DungeonGenerator] spawned ...` lines.
- Player is repositioned to `(0, 0)` again.
- No errors.
