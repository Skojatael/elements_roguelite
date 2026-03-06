# Research: Boss Room

**Feature**: [spec.md](spec.md)
**Date**: 2026-03-05

---

## Decision 1: `attack_interval` field — maps to existing `damage_cooldown`

**Decision**: Use the existing `damage_cooldown` field in `enemies.json` and `EnemyData.gd`. The user-specified `attack_interval=2` maps directly to `damage_cooldown: 2.0`.

**Rationale**: `damage_cooldown` already controls the time between contact-damage ticks in `Enemy.gd` (`_damage_timer = _data.damage_cooldown`). The semantics are identical. Adding a new field name for the same concept would require renaming across Enemy.gd, all existing JSON entries, and EnemyData.

**Alternatives considered**: Renaming `damage_cooldown` → `attack_interval` globally — rejected because it breaks all 2 existing enemy entries and Enemy.gd without adding value.

---

## Decision 2: `rooms_required` — stored in enemies.json boss entry, read via ResourceManager

**Decision**: Add `rooms_required: int = 0` to `EnemyData.gd`. Boss entry in `enemies.json` sets `rooms_required: 6`. `ResourceManagerImpl` caches and exposes `get_enemy_rooms_required(id)`, mirroring the existing `get_enemy_base_essence(id)` pattern.

**Rationale**: FR-003 and FR-007 require all boss stats (including threshold) to live in the same data source as other boss stats. Keeping `rooms_required` in `enemies.json` alongside `max_health`, `damage`, etc., satisfies both requirements with no new file.

**Alternatives considered**: Putting `rooms_required` in `dungeon_config.json` — rejected because it splits boss data across two files, violating FR-003 (single data source for all boss base stats).

---

## Decision 3: HP scaling — reuse `difficulty_mult` / `apply_difficulty()` pathway

**Decision**: At teleport time, compute `boss_mult = 1.0 + 0.06 * float(rooms_cleared)` and set `spawner.difficulty_mult = boss_mult`. `RoomSpawner._spawn_enemies()` already calls `enemy.apply_difficulty(difficulty_mult)`, which multiplies `max_health` by `mult`. No new code path needed.

**Rationale**: The formula `base_hp × mult` is identical to what `apply_difficulty` already does. Reusing it avoids new Enemy methods, stays consistent with the dungeon scaling pattern, and requires only 2 lines in the teleport handler.

HP precision: `40 × 1.36 = 54.4` (float). StatsComponent stores health as `float`; combat math already operates on floats. The `floori()` assumption in the spec is a display convention; the stored value remains a precise float.

**Alternatives considered**: Custom `apply_boss_hp(scaled_hp: float)` on Enemy — rejected (YAGNI; `apply_difficulty` handles the math identically).

---

## Decision 4: Camera — fallback to spawner's parent world position

**Decision**: In `Main._process()`, when `RunManager.current_room.room_id` is not in `_dungeon_gen.rooms_by_id`, fall back to `(RunManager.current_room as RoomSpawner).get_parent().global_position`.

**Rationale**: The boss room is not part of the dungeon graph and is not registered in `rooms_by_id`. The room scene root's `global_position` equals the world position passed to `SpawnContext.create()`. This is a 2-line addition that covers any future rooms outside the grid, not just the boss room.

**Alternatives considered**: Inserting boss room into `rooms_by_id` — rejected because DungeonGenerator owns that dictionary and the boss room is not a dungeon-generated room.

---

## Decision 5: Teleport button — in ExplorationHUD, emits signal to Main.gd

**Decision**: Add a `Button` node to `ExplorationHUD.tscn`. `ExplorationHUD.gd` manages show/hide (via `RunManager.room_cleared` and `RunManager.run_started`), and emits `signal boss_teleport_pressed`. Main.gd connects to this signal and handles all room/player/camera transitions.

**Rationale**: ExplorationHUD already owns run-time UI visibility. Actual room spawning belongs in Main.gd (which owns run lifecycle, room spawning, and player placement). Signal boundary keeps them decoupled.

**Alternatives considered**: Button in a separate BossHUD scene — rejected (YAGNI; ExplorationHUD is the correct home for run UI elements).

---

## Decision 6: Current dungeon room cleanup — `RoomLoader.free_current_room()`

**Decision**: Add one public method `free_current_room() -> void` to `RoomLoader`. Main.gd obtains a reference via `@onready var _room_loader: RoomLoader = $RoomLoader` and calls it before spawning the boss room.

**Rationale**: RoomLoader owns `_current_room_node`. Freeing the room from Main.gd without updating `_current_room_node` would cause a double-free in `RoomLoader._on_run_ended()`. One clean method on the owning class resolves this.

**Alternatives considered**: Freeing via `RunManager.current_room.get_parent().queue_free()` in Main.gd only — rejected because it bypasses RoomLoader's ownership, leaving `_current_room_node` as a dangling reference.

---

## Decision 7: Boss room world position — `Vector2(0, -3000)`

**Decision**: Boss room spawned at `Vector2(0, -3000)`. Defined as `const BOSS_ROOM_WORLD_POS: Vector2 = Vector2(0, -3000)` in Main.gd.

**Rationale**: Hub is at `(0, 0)`. Northernmost dungeon room is `(0, (0−2)×1200) = (0, −2400)`. `(0, −3000)` is 600 units north of that — clearly outside the dungeon grid, visually "above" the map, and adjacent to hub origin. Consistent with spec assumption ("adjacent to hub, not within the dungeon grid").

**Alternatives considered**: `(−5000, 0)` or `(0, 3000)` — valid but north is most natural for a "boss encounter at the top of the map" metaphor.

---

## Decision 8: Boss button hidden on teleport, not re-shown

**Decision**: `ExplorationHUD._on_boss_button_pressed()` hides the button before emitting `boss_teleport_pressed`. Button stays hidden for the remainder of the run (no re-show logic). Button resets to hidden on `run_started`.

**Rationale**: Matches spec edge case: "button should no longer be relevant after player enters boss room." One-way transition. Run start signal already resets the button for the next run.

---

## Summary of affected files

| File | Change |
|------|--------|
| `data/enemies.json` | Add boss entry (8 fields + `rooms_required`) |
| `data/dungeon_config.json` | Add `BossRoom01` spawn_config with 1 boss spawn point |
| `scripts/data_models/EnemyData.gd` | Add `rooms_required: int = 0` field |
| `scripts/managers/ResourceManager.gd` | Add `rooms_required` cache + `get_enemy_rooms_required()` |
| `autoload/ResourceManager.gd` | Add `get_enemy_rooms_required()` wrapper |
| `scripts/dungeon/RoomLoader.gd` | Add `free_current_room()` public method |
| `scenes/ui/hud/ExplorationHUD.gd` | Add boss button signal + show/hide logic |
| `scenes/core/Main.gd` | Add teleport handler, camera fallback, RoomLoader ref |
| `scenes/ui/hud/ExplorationHUD.tscn` | Add Button node (editor task) |
