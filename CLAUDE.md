# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Godot 4.6 mobile roguelite game (portrait, 1080×1920). Renderer: Mobile (D3D12 on Windows). Physics: Jolt.

## Development

All scene/node editing is done through the **Godot Editor** — open `project.godot` in Godot 4.6 to launch it. There is no build CLI; export is handled via the editor's Export menu.

The **godot-git-plugin** addon is active, providing Git integration directly inside the editor.

## Architecture

### Scene structure

```
scenes/
├── core/          Bootstrap.tscn → Main.tscn (entry point and main game scene)
├── player/        Player.tscn + components/
├── combat/        projectiles/, skills/, effects/ (empty, TBD)
├── dungeon/       DungeonGenerator.gd, RoomLoader.gd, RoomManager.gd, RoomBase.tscn, rooms/, doors/
├── run/           RunManager.gd, RunStats.gd, RewardSystem.gd
├── meta/          MetaManager.gd, UpgradeTree.tscn, UpgradeNode.tscn, PassiveIncomeSystem.gd
├── ui/            hud/, meta_ui/, menus/
└── shared/        GlobalSignals.gd, Utilities.gd, NumberFormatter.gd
```

### Player — component-based

`scenes/player/Player.tscn` composes behavior from child component scripts:

| Component | Responsibility |
|---|---|
| `MovementComponent.gd` | Locomotion |
| `DodgeComponent.gd` | Dodge/roll |
| `CombatComponent.gd` | Attacks |
| `SkillComponent.gd` | Skills/abilities |
| `StatsComponent.gd` | Health, stats, attributes |

### Autoloads (singletons)

Registered in `autoload/`:  `ResourceManager`, `SaveManager`, `MetaManager`, `RunManager`.
Implementation counterparts live in `scripts/managers/`.

### Data layer

JSON configs in `data/` (`upgrades.json`, `skills.json`, `enemies.json`, `dungeon_config.json`).
GDScript data models in `scripts/data_models/` (`UpgradeData`, `SkillData`, `EnemyData`, `SpawnPointData`, `RoomSpawnConfig`).

`dungeon_config.json` contains a `combat_room_pool` array (CombatRoom* type IDs for random selection) and a `spawn_configs` section keyed by room type ID, defining per-room enemy spawn points (enemy ID, position, randomisation radius). `StartRoom01` has an empty `spawn_points` array in `spawn_configs`.

### Enemy spawning (003-enemy-spawning)

- `scenes/dungeon/RoomSpawner.gd` — attached to each room scene; reads spawn config, instantiates enemies, tracks living count, signals `room_cleared` and `room_entered`.
- Each room scene (`CombatRoom01.tscn` etc.) has an `EntryArea` (Area2D) sibling that triggers spawning on player entry.
- `RoomSpawner._ready()` calls `RunManager.register_room(self)` so RunManager auto-connects to `room_entered` and `room_cleared` signals.
- `RunManager` holds `cleared_rooms: Dictionary` for the current run; `RoomSpawner` checks `is_room_cleared(room_id)` on entry.

### Run session (004-run-manager)

`autoload/RunManager.gd` manages the full run session lifecycle.

**Session state** (reset on each `start_run()`):

| Field | Type | Description |
|---|---|---|
| `run_id` | `String` | Temporary unique ID for this run (`str(Time.get_ticks_msec())`) |
| `is_run_active` | `bool` | True between `start_run()` and `end_run()` |
| `run_mode` | `String` | `"endless"` or `"boss"` |
| `current_tier` | `int` | Difficulty tier (starts at 1; set externally by meta-progression) |
| `run_start_time` | `float` | Engine time at run start (seconds) |
| `run_currency` | `float` | Gold accumulated this run (floor 0) |
| `current_room` | `Node` | Reference to active `RoomSpawner`; null between rooms |
| `rooms_entered` | `int` | How many rooms entered this run (starts at 0) |
| `cleared_rooms` | `Dictionary` | Map of `room_id → true` for cleared rooms |

**Key methods**: `start_run(mode)`, `end_run()`, `register_room(spawner)`, `add_currency(amount)`, `mark_room_cleared(room_id)`, `is_room_cleared(room_id)`.

**Signals**: `run_started(mode)` (emitted at end of `start_run()`), `run_ended(reason)` (on `end_run()`), `room_cleared(room_id)` (re-emitted from RoomSpawner).

**Services** (stubs — real logic in a future feature):
- `RunManager.difficulty_service.get_multiplier() -> float` — returns `1.0`
- `RunManager.rewards_service.get_room_reward(room_id) -> Dictionary` — returns `{}`
- Service scripts: `scripts/services/DifficultyService.gd`, `scripts/services/RewardsService.gd`

### Dungeon generation (008-dungeon-grid-layout)

`scenes/dungeon/DungeonGenerator.gd` — `Node` child of Main.tscn. Connects to `RunManager.run_started` in `_ready()`. On signal: runs a frontier-expansion algorithm on a 5×5 virtual grid and **produces data only — no scenes are instantiated**.

**Output properties** (public, populated after every `run_started`):

| Property | Type | Description |
|---|---|---|
| `rooms_by_id` | `Dictionary` | `room_id → { room_type_id, grid_pos: Vector2i, world_pos: Vector2 }` |
| `neighbours_by_id` | `Dictionary` | `room_id → Array[String]` of adjacent room_ids in the layout |
| `start_room_id` | `String` | Always `"room_2_2"` (center cell) |

**Algorithm**: starts at center cell (col=2, row=2), keeps an `Array[Vector2i]` frontier of unoccupied N/S/E/W neighbours, picks a random frontier cell each step, assigns a random `room_type_id` from `combat_room_pool`, records data into `rooms_by_id`. Repeats until `TARGET_ROOM_COUNT` (8) rooms recorded. Then builds `neighbours_by_id` in one pass. Emits `dungeon_layout_ready` signal at the end — `RoomLoader` connects to this to load the start room and place the player.

**Room IDs**: `"room_{col}_{row}"` (e.g. `"room_2_2"` for center).

**World positions**: `Vector2((col − 2) × SPACING_X, (row − 2) × SPACING_Y)` where `SPACING_X = 2000`, `SPACING_Y = 1200`. Center (2,2) → (0, 0).

**Re-run**: `rooms_by_id`, `neighbours_by_id`, and `start_room_id` are cleared and rebuilt each generation. No scene cleanup required.

**Scene loading** is handled by `RoomLoader` (feature 009), which reads `rooms_by_id` after `dungeon_layout_ready` fires.

### Room loading & doors (009-room-loading-doors)

`scenes/dungeon/RoomLoader.gd` — `Node` child of Main.tscn, sibling of `DungeonGenerator`. Owns all room scene lifecycle: loading, unloading, door configuration, and player placement.

**Key behaviour**:
- Connects to `DungeonGenerator.dungeon_layout_ready` in `_ready()`.
- On layout ready: overrides `start_room_id`'s type to `"StartRoom01"`, loads the scene via `RunManager.spawn_room()`, configures doors, places player at room center.
- On door touch: sets `RunManager.current_room = null`, calls `queue_free()` on the current room root, loads next room, places player at the entry offset from the matching opposite wall.
- `_loading: bool` guard prevents double-loads.

**Door architecture**: `scenes/dungeon/doors/Door.tscn` — `Area2D` (200×200 collision) with `Door.gd`. Four static instances (`DoorN`, `DoorS`, `DoorE`, `DoorW`) are children of `RoomBase.tscn` at positions `(0, ±540)` and `(±960, 0)`. `RoomLoader` shows/hides each door and sets `target_room_id` after each room load.

**Player entry offset**: `ENTRY_OFFSET = 150` px inward from wall. Player placed at `world_pos + ENTRY_LOCAL[entry_direction]`.

| Entry side | Local offset |
|---|---|
| `"N"` | `Vector2(0, -390)` |
| `"S"` | `Vector2(0, 390)` |
| `"E"` | `Vector2(810, 0)` |
| `"W"` | `Vector2(-810, 0)` |

**StartRoom01**: `scenes/dungeon/rooms/StartRoom01.tscn` (inherits `RoomBase.tscn`). `RoomData` at `data/rooms/StartRoom01.tres`. Has empty `spawn_points` — no enemies. Assigned by `RoomLoader` at load time; `DungeonGenerator` is unaware of it.

**One room in memory**: At all times exactly one room scene is present. Current room is `queue_free()`'d before next is instantiated.

---

### Room Factory (006-room-factory)

`scenes/dungeon/RoomFactory.gd` — stateless `RefCounted` service owned by RunManager. Receives a `RoomData` resource, reads `room_data.scene` directly (no internal registry), sets `room_id` and `auto_register=false` on the spawner before `add_child`, positions the room, and returns the `RoomSpawner` directly.

`scripts/data_models/RoomData.gd` — `Resource` with `@export room_type_id: String` and `@export scene: PackedScene`. Instances saved as `.tres` files in `res://data/rooms/` (one per room type). Authored in the Godot Inspector.

`scripts/data_models/SpawnContext.gd` — data bundle: `parent: Node` and `position: Vector2`. Constructed via `SpawnContext.create(parent, position)`. Passed to `RoomFactory.spawn_room()` and `RunManager.spawn_room()`.

**Room assets** (`res://data/rooms/`): `CombatRoom01.tres`, `CombatRoom02.tres`, `EliteRoom01.tres`, `BossRoom01.tres`.

**RoomSpawner fields**:
- `room_type_id` — matches a key in `dungeon_config.json → spawn_configs` (e.g. `"CombatRoom01"`); used for spawn config lookup, tracking (`cleared_rooms`), and signals. Set via Inspector (pre-placed) or by RoomFactory (dynamic).
- `auto_register` — factory sets `false` before `add_child`; pre-placed Editor rooms use default `true`.

## Folder Conventions

| Path | Purpose |
|------|---------|
| `res://autoload/` | Autoloaded singletons |
| `res://data/` | JSON data/config files |
| `res://scenes/` | Scenes and co-located scripts |
| `res://scripts/` | Standalone scripts (data models, managers) |
| `res://assets/` | Sprites, audio, fonts |
