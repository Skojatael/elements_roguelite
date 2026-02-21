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
├── dungeon/       DungeonGenerator.gd, RoomManager.gd, RoomBase.tscn, rooms/
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

`dungeon_config.json` contains a `spawn_configs` section keyed by room type ID, defining per-room enemy spawn points (enemy ID, position, randomisation radius).

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
| `current_room_index` | `int` | How many rooms entered this run (starts at 0) |
| `cleared_rooms` | `Dictionary` | Map of `room_id → true` for cleared rooms |

**Key methods**: `start_run(mode)`, `end_run()`, `register_room(spawner)`, `add_currency(amount)`, `mark_room_cleared(room_id)`, `is_room_cleared(room_id)`.

**Signals**: `run_ended` (on `end_run()`), `room_cleared(room_id)` (re-emitted from RoomSpawner).

**Services** (stubs — real logic in a future feature):
- `RunManager.difficulty_service.get_multiplier() -> float` — returns `1.0`
- `RunManager.rewards_service.get_room_reward(room_id) -> Dictionary` — returns `{}`
- Service scripts: `scripts/services/DifficultyService.gd`, `scripts/services/RewardsService.gd`

## Folder Conventions

| Path | Purpose |
|------|---------|
| `res://autoload/` | Autoloaded singletons |
| `res://data/` | JSON data/config files |
| `res://scenes/` | Scenes and co-located scripts |
| `res://scripts/` | Standalone scripts (data models, managers) |
| `res://assets/` | Sprites, audio, fonts |
