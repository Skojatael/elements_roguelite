# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Repo map**: `repo_map.md` at the project root lists every `.gd` file with its class name, signals, exports, and public methods. Reference it whenever you need to locate a symbol or understand project structure before opening files. **Use Grep to read only relevant entries — never read the full file.**

> **Feature numbering**: When creating a new spec directory under `specs/`, always `ls specs/` first and use the **highest existing number + 1**. Never infer the next number from CLAUDE.md feature mentions — the `specs/` directory is the source of truth.

> **Speckit token efficiency**: When running speckit commands, follow these rules to avoid unnecessary token use:
> - **plan.md**: prose descriptions only — no code blocks. Code is written once during `/speckit.implement`.
> - **Simple features** (≤3 decisions, ≤3 schema changes): inline `## Decisions` and `## Schema Changes` in `plan.md` instead of creating separate `research.md` / `data-model.md`.
> - **implement**: reads `tasks.md` + `plan.md` only — skip research.md, data-model.md, contracts/ unless a task explicitly references them.
> - **tasks.md checkboxes**: flip `[ ]` → `[x]` with targeted `Edit` calls per phase — never rewrite the full file.

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

Component scripts live in `scenes/player/components/` without their own `.tscn` files — they are attached directly to child nodes inside `Player.tscn`. This is the **one permitted exception** to the co-location rule: a script may exist without a co-located scene if it is attached exclusively to nodes within a single parent scene and is never referenced from outside that scene. If a component script is ever used by a second scene it MUST be moved to `res://scripts/`.

### Autoloads (singletons)

Registered in `autoload/`:  `ResourceManager`, `SaveManager`, `MetaManager`, `RunManager`.
Implementation counterparts live in `scripts/managers/`.

**Thin-wrapper rule** (Constitution I): autoload scripts MUST be thin wrappers — they expose signals, state fields, and delegating methods, but MUST NOT contain algorithmic game logic. Logic goes in `scripts/managers/` or `scripts/services/`; the autoload calls into those scripts.

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
| `cleared_rooms` | `Dictionary` | Map of `room_id → true` for cleared rooms |

**Key methods**: `start_run(mode)`, `end_run(reason)`, `register_room(spawner)`, `add_currency(amount)`, `mark_room_cleared(room_id)`, `is_room_cleared(room_id)`.

**Signals**: `run_started(mode)` (emitted at end of `start_run()`), `run_ended(reason)` (on `end_run()`), `room_cleared(room_id)` (re-emitted from RoomSpawner).

**Services** (stubs — real logic in a future feature):
- `RunManager.difficulty_service.get_multiplier() -> float` — returns `1.0`
- `RunManager.rewards_service.get_room_reward(room_id) -> Dictionary` — returns `{}`
- Service scripts: `scripts/services/DifficultyService.gd`, `scripts/services/RewardsService.gd`

**Essence currency (014-essence-currency)**:
- `RunManager.run_currency: float` — accumulates during a run. Awarded per enemy kill via `add_currency()`.
- Earn formula: `floori(base_essence × (1 + 0.10 × (depth − 1)))` per kill. `base_essence` is per-enemy-type data in `enemies.json` (slime=10, skeleton=15). `depth` is the room's grid depth set on `RoomSpawner` by `RoomLoader`. Depth 1 awards the full base amount; each additional depth step adds 10%.
- Cash-out fires in `end_run()`: 100% on `CASH_OUT`, `floori(run_currency × 0.85)` on `DIED`. Prints `[Essence] X essence cashed out`. No persistent wallet in this iteration.
- `run_currency` resets to `0.0` in `start_run()`.

**Run state snapshot (011-run-state)**:
- `RunManager.run_state: RunState` — a `RefCounted` data class at `scripts/data_models/RunState.gd`. Non-null at all times (initialized at declaration). RunManager is the sole writer; all other systems are read-only consumers.
- **Fields**: `current_room_id: String`, `cleared_rooms: Dictionary` (shared reference with RunManager.cleared_rooms), `run_currency: float`, `run_mode: String`, `max_depth_reached: int` (updated in `_on_room_entered()` via `maxi`), `seed: int` (stub, always 0), `player_state: PlayerState` (see below).
- **Reset**: A fresh `RunState.new()` is created in `start_run()`. Final values remain accessible after `end_run()` until the next run starts. No signals — consumers poll `RunManager.run_state`.

**Player state snapshot (012-player-state)**:
- `RunManager.player_state: PlayerState` — a `RefCounted` data class at `scripts/data_models/PlayerState.gd`. Non-null at all times. RunManager is the sole writer; all other systems are read-only consumers.
- `RunState.player_state` points to the same instance as `RunManager.player_state` during and after a run. Read via `RunManager.run_state.player_state`.
- **Live field**: `current_hp: float` — synced from `StatsComponent.health_changed` signal. Connected in `start_run()` with `is_connected()` guard; never disconnected.
- **Stub fields** (always empty in this feature): `items: Array`, `modifiers: Array`, `skill_changes: Array`, `skill_cooldowns: Dictionary`.
- **Reset timing**: `PlayerState` resets at `end_run()` (not `start_run()`). A fresh `PlayerState.new()` is created with `current_hp = stats.max_health`. Both `RunManager.player_state` and `run_state.player_state` are updated to the new instance.
- Signal handler: `RunManager._on_player_health_changed(new_health, _max_health)` writes `player_state.current_hp = new_health`.

### Dungeon generation (008-dungeon-grid-layout)

`scenes/dungeon/DungeonGenerator.gd` — `Node` child of Main.tscn. Connects to `RunManager.run_started` in `_ready()`. On signal: runs a frontier-expansion algorithm on an 11×11 virtual grid and **produces data only — no scenes are instantiated**.

**Output properties** (public, populated after every `run_started`):

| Property | Type | Description |
|---|---|---|
| `rooms_by_id` | `Dictionary` | `room_id → { room_type_id, grid_pos: Vector2i, world_pos: Vector2, depth: int, difficulty_mult: float }` |
| `neighbours_by_id` | `Dictionary` | `room_id → Array[String]` of adjacent room_ids in the layout |
| `start_room_id` | `String` | Always `"room_6_6"` (center cell) |

**Algorithm**: starts at center cell (col=6, row=6), keeps an `Array[Vector2i]` frontier of unoccupied N/S/E/W neighbours, picks a random frontier cell each step, assigns a random `room_type_id` from `combat_room_pool`, records data into `rooms_by_id` (including `depth` and `difficulty_mult`). Repeats until `base_room_count` (9 — read from `dungeon_config.json`) rooms recorded. Then builds `neighbours_by_id` in one pass. Then calls `_promote_elite_rooms()` to override `room_type_id = "EliteRoom01"` for one room at each elite depth slot. Emits `dungeon_layout_ready` at the end.

**Dungeon expansion (033-dungeon-expansion)**: if `MetaManager.is_adventuring_gear_owned`, `_expand_dungeon()` runs after base generation. It finds Room A (deepest base room), then frontier-expands 4 more rooms from Room A, constraining new rooms to depth strictly > Room A's depth. `expansion_room_count: 4` in `dungeon_config.json`. Total rooms = 13 when gear owned. Grid is 13×13 (was 5×5, changed in 033) to guarantee 4 expansion rooms always fit — 11×11 is insufficient for 9 base rooms (max depth 8).

**Depth & difficulty (010-depth-difficulty)**:

- `depth = |col − 6| + |row − 6|` (grid Manhattan distance from center; start room = 0).
- `difficulty_mult = 1.0 + 0.12 × depth` stored per room in `rooms_by_id`.
- `RoomLoader` reads `difficulty_mult` from `rooms_by_id` and sets it on `RoomSpawner` after `spawn_room()` returns.
- `RoomSpawner._spawn_enemies()` calls `enemy.apply_difficulty(difficulty_mult)` after each `add_child(enemy)`.
- `Enemy.apply_difficulty(mult)` multiplies `_stats.max_health` and resets `current_health`.
- **Elite rooms**: constants `ELITE_START = 2`, `ELITE_STEP = 2`. Depth slots 2, 4, 6… each get one randomly promoted room. `EliteRoom01` scene and `.tres` resource already exist.

**Room IDs**: `"room_{col}_{row}"` (e.g. `"room_6_6"` for center).

**World positions**: `Vector2((col − 6) × SPACING_X, (row − 6) × SPACING_Y)` where `SPACING_X = 2000`, `SPACING_Y = 1200`. Center (6,6) → (0, 0).

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

### Run End Screen (015-run-end-screen)

**Scenes** (`scenes/ui/run_end/`):
- `ResultsScreen.tscn` + `ResultsScreen.gd` — shown immediately after a run ends. Replaces the dungeon (freed at `end_run()` time). Freed when player taps "Return". Exports: `_essence_row`, `_enemies_row`, `_rooms_row` (`StatRow`), `_return_button` (`Button`). Exposes `setup(summary: RunSummary)` and signal `return_pressed`.
- `StatRow.tscn` + `StatRow.gd` — reusable `HBoxContainer` with a name `Label` (text set per-instance in Inspector) and a value `Label` (assigned to `_value_label` export). Exposes only `set_value(n: int)`.

**Data source**: `RunManager.run_summary: RunSummary` — immutable snapshot created in `end_run()` before scene teardown. ResultsScreen reads exclusively from this via `setup(summary)`.

**`RunSummary`** (`scripts/data_models/RunSummary.gd`) — `RefCounted` with fields: `essence_cashed_out: int`, `enemies_slain: int`, `rooms_cleared: int`, `end_reason: RunManager.EndReason`. Created via `RunSummary.create(...)`.

**Flow**: `RunManager.end_run()` → creates `RunSummary`, emits `run_ended` → RoomLoader frees current room → ExplorationHUD hides → Main.gd creates a `CanvasLayer` (`_results_layer`), instantiates ResultsScreen as its child, calls `setup()`.

**CanvasLayer**: ResultsScreen is parented to a dynamically created `CanvasLayer` so it renders in screen space regardless of Camera2D position. `_results_layer` and `_results_screen` are both tracked on Main.

**Return**: ResultsScreen emits `return_pressed` → Main.gd calls `_results_layer.queue_free()` (frees layer and screen together), reinstantiates HubRoom, teleports player to hub center (`_player.global_position = _hub_room.global_position`).

**Main.gd scene cleanup** — Main connects to `RunManager.run_started` via `_on_run_started()`, which runs before any run begins. It frees stale scene objects so DevPanel bypasses don't leave orphaned nodes:
- If `_hub_room` is still valid (DevPanel "Start Run" pressed while hub was active) → `queue_free()` + null.
- If `_results_layer` is non-null (DevPanel "Start Run" pressed while results screen was showing) → `queue_free()` + null.
`_on_run_ended` also frees `_hub_room` via `is_instance_valid()` as a secondary guard.

**RunManager additions**: `enemies_slain: int` (reset in `start_run()`, incremented in `_on_enemy_defeated()`); `run_summary: RunSummary` (written in `end_run()`, null before first run ends).

**RoomLoader**: connects to `run_ended`; frees `_current_room_node` and nulls `RunManager.current_room` on run end.

**ExplorationHUD**: connects to both `GlobalSignals.gameplay_ended` and `RunManager.run_ended` to hide on all end-run paths.

---

### Hub Room (013-hub-room)

`scenes/hub/HubRoom.tscn` — the game's entry point. Player spawns here at launch. Not part of any run (`RunManager.is_run_active == false` while in hub).

- `scenes/hub/TeleportDoor.tscn` — `Node2D` placeholder containing a Godot `Button` (text="Teleport") and a `ColorRect` visual. Activates when the `Button` is pressed (tap on mobile, click on desktop). Guard: `not RunManager.is_run_active`. Emits `teleport_activated` signal. The `Button` is a Control node (screen-space); the visual will be replaced with a world-space asset in a future iteration.
- `HubRoom.gd` — connects to `TeleportDoor.teleport_activated`; on activation emits `hub_exited` then calls `queue_free()`.
- `Main.gd` connects to `hub_exited`: calls `RunManager.start_run("endless")` then `GlobalSignals.gameplay_started.emit()`.
- `Main._ready()` no longer calls `start_run()` directly — run only starts when player activates TeleportDoor (or via DevPanel bypass in DEV_MODE).
- ExplorationHUD is hidden during hub (not shown until `gameplay_started` fires or `RunManager.run_started` emits).

---

### Room Factory (006-room-factory)

`scenes/dungeon/RoomFactory.gd` — stateless `RefCounted` service owned by RunManager. Receives a `RoomData` resource, reads `room_data.scene` directly (no internal registry), sets `room_id` and `auto_register=false` on the spawner before `add_child`, positions the room, and returns the `RoomSpawner` directly.

`scripts/data_models/RoomData.gd` — `Resource` with `@export room_type_id: String` and `@export scene: PackedScene`. Instances saved as `.tres` files in `res://data/rooms/` (one per room type). Authored in the Godot Inspector.

`scripts/data_models/SpawnContext.gd` — data bundle: `parent: Node` and `position: Vector2`. Constructed via `SpawnContext.create(parent, position)`. Passed to `RoomFactory.spawn_room()` and `RunManager.spawn_room()`.

**Room assets** (`res://data/rooms/`): `CombatRoom01.tres`, `CombatRoom02.tres`, `EliteRoom01.tres`, `BossRoom01.tres`.

**RoomSpawner fields**:
- `room_type_id` — matches a key in `dungeon_config.json → spawn_configs` (e.g. `"CombatRoom01"`); used for spawn config lookup, tracking (`cleared_rooms`), and signals. Set via Inspector (pre-placed) or by RoomFactory (dynamic).
- `auto_register` — factory sets `false` before `add_child`; pre-placed Editor rooms use default `true`.

### Meta Progression (016-meta-shards)

**MetaState** (`scripts/data_models/MetaState.gd`) — `RefCounted` data class. Fields: `total_shards: int = 0`, `damage_upgrade_level: int = 0`. Persisted across sessions. Analogous to `RunState` but for meta data that survives runs.

**MetaManager** (`autoload/MetaManager.gd`) — owns meta-progression. Holds `meta_state: MetaState` (non-null after `_ready()`). Connects to `RunManager.run_ended` in `_ready()`. On run end: computes `essence_cashed_out / shard_divisor` and calls `add_shards(earned)`. Prints `[MetaManager] N shards earned — total=M`.

**Shard spending API** (018-shard-spending):
- `signal shards_changed(new_total: int)` — emitted after every successful balance mutation (spend, grant, run-end conversion). NOT emitted for zero-amount operations.
- `can_spend(cost: int) -> bool` — pure affordability check; no side effects. Returns `false` for negative cost.
- `spend(cost: int) -> bool` — deducts cost if `total_shards >= cost`; saves and emits `shards_changed` on success. `spend(0)` returns `true` with no mutation.
- `add_shards(amount: int) -> void` — adds shards from any source; saves and emits `shards_changed` if `amount > 0`. No-op for `amount <= 0`.
- **Invariant**: `total_shards >= 0` always. `spend` enforces the guard; no deduction without a matching save.

**Damage upgrade API** (019-damage-upgrade):
- `var damage_multiplier: float` (computed property) — `1.0 + damage_upgrade_level * 0.1`. Read by `CombatComponent` at each run start.
- `get_next_upgrade_cost() -> int` — cost for the next level purchase (0 if maxed).
- `purchase_damage_upgrade() -> bool` — atomic: checks max level, deducts cost, increments level, saves, emits `shards_changed`. Returns `false` if maxed or insufficient balance.

**SaveManager** (`autoload/SaveManager.gd`) — owns file persistence. Save path: `user://meta_save.json`. Methods: `save_meta_state(MetaState)`, `load_meta_state() -> MetaState`. JSON format: `{"total_shards": <int>, "damage_upgrade_level": <int>}`. Missing fields default to 0 (backward compatible). Returns `MetaState.new()` if file missing or malformed; never returns null.

**ResourceManager** addition — `get_meta_config() -> Dictionary`: reads and caches `data/meta_config.json`.

**Balance config** (`data/meta_config.json`):
- `shard_divisor: 3` — essence-to-shard conversion (3 essence = 1 shard).
- `damage_upgrade.base_cost: 50`, `cost_scale: 1.2`, `max_levels: 10`, `damage_per_level: 0.1` — upgrade costs floor at each step; cost table: 50, 60, 72, 86, 103, 123, 147, 176, 211, 253.

**Shard conversion formula**: `shards_earned = essence_cashed_out / shard_divisor` (GDScript integer division, truncates toward zero). Only `essence_cashed_out` from `RunSummary` is used (already accounts for DIED penalty).

---

### Relic System (021-relic-system)

Run-scoped modifier system. Relics are collected via a post-clear offer screen and apply stat multipliers for the duration of the run.

**Data** (`data/relics.json`) — 6 initial relics across 4 stat categories: `attack_damage`, `attack_speed`, `max_health`, `move_speed`. Each entry: `id`, `name`, `tier`, `tags`, `effect_stat`, `effect_mult`, `description`.

**RelicData** (`scripts/data_models/RelicData.gd`) — `RefCounted` typed wrapper. Factory: `RelicData.from_dict(data)`.

**RelicManagerImpl** (`scripts/managers/RelicManagerImpl.gd`) — `RefCounted`. Owns algorithmic logic: `should_offer_for_room(room_type_id)` (frequency), `draw_offer(pool)`, `pick_relic(id)`, `compute_stat_mult(stat, pool)`. State: `active_relic_ids: Array[String]`, `standard_rooms_cleared: int`. `OFFER_INTERVAL = 1`.

**RelicManager** (`autoload/RelicManager.gd`) — thin wrapper. Connects to `RunManager.run_started`, `run_ended`, `room_cleared`. On room_cleared: reads `RunManager.current_room.room_type_id`, delegates to impl, emits `relic_offer_ready(options: Array)`. Exposes `pick_relic(id)`, `get_stat_mult(stat)`, `active_relic_ids`. Signals: `relic_offer_ready`, `relic_applied(relic_id)`, `relics_cleared`.

**Elite detection**: `room_type_id.contains("Elite")` → always offer. Standard rooms: offer every `OFFER_INTERVAL` clears (counter does NOT reset on elite offer).

**PlayerState** (`scripts/data_models/PlayerState.gd`) — `active_modifiers: Array[String]` (replaces `modifiers: Array` stub). Updated by `RelicManager.pick_relic()`.

**Stat application** — reactive pattern: `CombatComponent`, `StatsComponent`, and `MovementComponent` connect to `RelicManager.relic_applied` and `relics_cleared`, then recompute from cached base values:
- `attack_damage = _base_attack_damage × MetaManager.damage_multiplier × RelicManager.get_stat_mult("attack_damage")`
- `attack_interval = _base_attack_interval / RelicManager.get_stat_mult("attack_speed")`
- `max_health = _base_max_health × RelicManager.get_stat_mult("max_health")` (current_health scales proportionally)
- `move_speed = _base_move_speed × RelicManager.get_stat_mult("move_speed")`

**Offer UI** — `scenes/ui/relic_offer/RelicOfferScreen.tscn` + `RelicCard.tscn`. `Main.gd` listens to `relic_offer_ready`: hides ExplorationHUD, creates CanvasLayer, instantiates RelicOfferScreen, calls `setup(options)`. On `relic_picked`: calls `RelicManager.pick_relic(id)`, frees layer, shows ExplorationHUD.

**ResourceManager** addition — `get_relics() -> Dictionary`: reads and caches `data/relics.json`.

**Conditional relics (024-execute-relic)** — relics whose bonus depends on runtime context (target HP, player HP) use `effect_stat: ""` and `effect_mult: 1.0` in JSON (so `compute_stat_mult` ignores them). All conditional relic logic lives in `RelicManagerImpl.get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio) -> float`, exposed via `RelicManager.get_hit_damage_mult()`. `CombatComponent` calls this at hit time with context ratios and applies the returned multiplier — it is unaware of specific relic IDs. Two relics of this type exist:
- `executioners_mark` — ×1.35 damage when `target_hp_ratio < 0.30` (`Enemy.get_hp_ratio()` added).
- `berserker_stone` — ×1.30 damage when `attacker_hp_ratio < 0.50` (`_stats_component` export on `CombatComponent`, assigned in Inspector).

**Relic unlock gate** — `MetaState.relic_offers_active: bool` gates offer generation in `RelicManager._on_room_cleared()`. Set by `MetaManagerImpl.purchase_mage_tower_relic_system()` (via Mage Tower — see 037).

---

### Boss Room (029-boss-room)

Boss encounter accessed via a "Teleport to Boss" button in ExplorationHUD. Not part of the dungeon door graph.

**Data** — `data/enemies.json` is restructured: `"enemies"` is now a category Dictionary (`"common"` → Array, `"boss"` → Array) instead of a flat array. Consumers iterate all category values via `.values()`. Boss entry in the `"boss"` array: `id="boss"`, `max_health=40`, `damage=5`, `damage_cooldown=2`, `rooms_required=6`. `damage_cooldown` maps to `attack_interval` from the user description (same field, same semantics). Boss spawn config in `data/dungeon_config.json` under `"BossRoom01"` key: one spawn point at (0,0), `enemy_id="boss"`.

**`EnemyData.gd`** — adds `rooms_required: int = 0` (optional field; 0 for non-boss enemies).

**`ResourceManagerImpl`** — adds `_enemy_rooms_required_cache: Dictionary` and `get_enemy_rooms_required(id: String) -> int`, cached alongside `get_enemy_base_essence`. `ResourceManager` autoload exposes the wrapper.

**HP scaling** — computed in `Main._on_boss_teleport_pressed()`: `boss_mult = 1.0 + 0.06 * float(maxi(0, rooms_cleared - 6))`. Scaling starts only beyond the 6-room unlock threshold; at exactly 6 rooms cleared the boss has base HP. Set on `spawner.difficulty_mult` before the player enters the room. The existing `Enemy.apply_difficulty(boss_mult)` pathway handles `max_health × boss_mult`. No new Enemy methods needed.

**Boss room world position** — `Vector2(0, -3000)` (constant `Main.BOSS_ROOM_WORLD_POS`). North of hub (0,0), outside the dungeon grid (northernmost dungeon row is at y=−2400).

**Camera** — `Main._process()` gains an `else` branch: when `current_room.room_id` is not in `rooms_by_id`, use `(RunManager.current_room as RoomSpawner).get_parent().global_position`. Handles the boss room (and any future out-of-grid rooms) without boss-specific logic.

**RoomLoader** — adds one public method `free_current_room() -> void`. Called by `Main._on_boss_teleport_pressed()` before spawning the boss room, to cleanly null and free `_current_room_node` (preventing double-free in `_on_run_ended()`).

**ExplorationHUD** — adds `signal boss_teleport_pressed`, `@export var _boss_button: Button`, and `const BOSS_ENEMY_ID: String = "boss"`. Button shown when `cleared_rooms.size() >= ResourceManager.get_enemy_rooms_required(BOSS_ENEMY_ID)` (checked on each `RunManager.room_cleared`). Hidden on button press and reset on `run_started`.

**Main.gd additions**: preload `_BOSS_ROOM_DATA` (BossRoom01.tres), `@onready var _room_loader: RoomLoader = $RoomLoader`, connect `boss_teleport_pressed`, implement `_on_boss_teleport_pressed()`.

### Boss Victory Outcome (030-boss-victory-outcome)

**No doors**: After spawning the boss room, `_on_boss_teleport_pressed()` iterates `spawner.get_parent().get_children()` and sets `visible = false` + `monitoring = false` on every `Door` node (`Door` has `class_name Door`). Boss room Door nodes are inherited from `RoomBase.tscn` but suppressed in code rather than removed in the editor.

**Victory overlay**: `scenes/ui/boss_victory/BossVictoryOverlay.tscn` — `Control` root with two `Button` children (`CashOutButton`, `ContinueButton`). Script: `BossVictoryOverlay.gd` (`class_name BossVictoryOverlay`). Signals: `cash_out_pressed`, `continue_pressed`. On cash_out: button disables; on continue (stub): button disables + text changes to "Coming Soon...".

**Trigger**: `_on_boss_teleport_pressed()` stores the spawner ref and connects `room_cleared → _on_boss_room_cleared()`. On boss room cleared: ExplorationHUD hidden, overlay instantiated inside a new CanvasLayer (`_boss_victory_layer`).

**Cash Out flow**: `_on_boss_cash_out_pressed()` → `RunManager.end_run(CASH_OUT)` → existing `_on_run_ended()` shows ResultsScreen. Overlay layer freed in `_on_run_ended()` before ResultsScreen is shown.

**ExplorationHUD fix**: `_on_room_cleared_for_boss()` gains `const BOSS_ROOM_ID = "boss_room"` and an early return `if room_id == BOSS_ROOM_ID: return`, preventing the boss button from reappearing after the boss is killed.

**Main.gd new fields**: `_boss_room_spawner: RoomSpawner`, `_boss_victory_layer: CanvasLayer`, `_boss_victory_overlay: BossVictoryOverlay`. Both `_on_run_ended()` and `_on_run_started()` free `_boss_victory_layer` if non-null.

### Dungeon Expansion / Adventuring Gear (033-dungeon-expansion)

**MetaState new fields**: `first_boss_killed: bool` (set on first boss room clear), `adventuring_gear_owned: bool` (set on purchase). Both persist in `user://meta_save.json`.

**Detection**: `MetaManager._on_room_cleared()` gains a boss branch: `if room_id == "boss_room": _impl.record_boss_kill(SaveManager)` — returns early before the elite detection logic.

**Purchase**: `MetaManager.purchase_adventuring_gear()` delegates to `MetaManagerImpl.purchase_adventuring_gear(cost, SaveManager)`. Cost (`mage_tower_dungeon_expansion_cost: 200`) read from `data/meta_config.json`. Purchased via Mage Tower upgrade screen (see 037).

**Grid change**: `DungeonGenerator.GRID_SIZE` changed 5 → 13, `CENTER` changed `(2,2)` → `(6,6)`. Start room is now `"room_6_6"`. Grid size is a structural constant (not in JSON) because it defines the room ID namespace. `TARGET_ROOM_COUNT` const removed — base room count read from `dungeon_config.json` as `base_room_count: 9` (1 start + 8 combat).

### Boss Rewards (032-boss-rewards)

**Essence reward**: Boss `base_essence` in enemies.json is 80. On boss room cleared, `Main._on_boss_room_cleared()` computes `floori(base_essence × (1.0 + 0.06 × max(0, rooms_cleared − 6)))` and calls `RunManager.add_currency(reward)`. Same threshold as HP: no bonus at exactly 6 rooms, scaling starts at 7+. The normal `enemy_defeated` path is not used for the boss (depth=0 would apply a penalty).

**Rare relic offer**: After essence award, `RelicManager.trigger_boss_offer()` draws up to 3 rare relics (from full rare pool, excluding already-held relics) and emits `relic_offer_ready`. The existing `RelicOfferScreen` shows the offer. After the player picks, `_on_relic_picked()` checks `_boss_relic_pending: bool` — if true, calls `_show_boss_victory_overlay()` instead of restoring ExplorationHUD.

**Fallback**: If no rare relics are available, `trigger_boss_offer()` returns false and `_show_boss_victory_overlay()` is called directly.

**Bug fix**: `RelicManager._on_room_cleared()` now returns early for `room_id == "boss_room"` — prevents the boss room clear from incrementing the regular relic offer counter or triggering a spurious regular offer.

**RelicManagerImpl additions**: `draw_boss_offer() -> Array[RelicData]` — shuffles available (non-held) rare relics, returns up to 3.

**Main.gd additions**: `_boss_relic_pending: bool`, `_show_boss_victory_overlay()` (extracted helper called from both post-relic-pick and no-rare-fallback paths).

---

### Mage Tower (037-mage-tower)

Hub building with two visual states (Ruined / Restored). Once restored, opens a system upgrades screen with three purchasable system unlocks. Replaces the standalone `AdventuringGearShop` and `BossRunShop` nodes (deleted in this feature). The old two-stage elite-clear → hub-return relic auto-unlock path is removed entirely.

**Scenes** (`scenes/hub/`):
- `MageTower.tscn` + `MageTower.gd` (`class_name MageTower extends Control`) — zone node. Exports: `_ruined_visual: ColorRect`, `_magic_visual: ColorRect`, `_label: Label`, `_button: Button`, `_restore_overlay_scene: PackedScene`, `_upgrade_screen_scene: PackedScene`. Connects `MetaManager.shards_changed` and `GlobalSignals.hub_entered` → `_update_visuals()`. On button press: shows restore overlay if not unlocked, upgrade screen if unlocked. Overlay/screen managed via `_overlay_layer: CanvasLayer`.
- `RestoreTowerOverlay.tscn` + `RestoreTowerOverlay.gd` (`class_name RestoreTowerOverlay extends Control`) — restoration dialog. Signals: `restore_pressed`, `maybe_later_pressed`. Exports: `_restore_button: Button`, `_later_button: Button`. Disables restore button when `not MetaManager.can_spend(cost)`.
- `MageTowerUpgradeScreen.tscn` + `MageTowerUpgradeScreen.gd` (`class_name MageTowerUpgradeScreen extends Control`) — lists three system unlocks. Signal: `close_pressed`. Exports: `_de_button: Button`, `_de_unlocked_label: Label`, `_rs_button: Button`, `_rs_unlocked_label: Label`, `_bc_button: Button`, `_bc_unlocked_label: Label`, `_close_button: Button`. Connects `MetaManager.shards_changed` → `_update_entries()`. Ownership checks: DE = `is_adventuring_gear_owned`, RS = `is_relic_offers_active`, BC = `is_boss_run_unlocked`.

**MetaState new field**: `mage_tower_unlocked: bool = false` — persisted in `user://meta_save.json`.

**MetaManager additions**:
- `var is_mage_tower_unlocked: bool` — computed property
- `purchase_mage_tower() -> bool` — deducts `mage_tower_cost` (200 shards), sets `mage_tower_unlocked = true`
- `purchase_mage_tower_relic_system() -> bool` — deducts `mage_tower_relic_system_cost` (100 shards), sets `relic_offers_active = true`

**Relic System unlock**: Purchasing "Relic System" in the upgrade screen is the sole path — `MetaManagerImpl.purchase_mage_tower_relic_system()` sets both flags atomically with no intermediate state.

**Costs and display names** — all in `data/meta_config.json`, grouped by building:
```
magic_forge.cost                              → forge restoration cost
magic_forge.upgrades.damage_upgrade.name/cost → Damage Multiplier display name (+ upgrade stats)
mage_tower.cost                               → tower restoration cost
mage_tower.upgrades.dungeon_expansion.name/cost
mage_tower.upgrades.relic_system.name/cost
mage_tower.upgrades.boss_challenge.name/cost
```
Screen scripts read `.get("name", "<technical_key>")` as fallback so missing entries degrade gracefully.

**Removed**: `AdventuringGearShop.gd`, `BossRunShop.gd`, their nodes from `HubRoom.tscn`. `MetaManagerImpl.try_activate_relic_offers()` and `unlock_adventurer_bag()` methods deleted. Flat keys (`mage_tower_cost`, `mage_tower_dungeon_expansion_cost`, etc.) replaced by nested structure.

---

## Folder Conventions

| Path | Purpose |
|------|---------|
| `res://autoload/` | Autoloaded singletons |
| `res://data/` | JSON data/config files |
| `res://scenes/` | Scenes and co-located scripts. Every `.gd` here MUST be attached to a scene in the same directory — exception: component scripts inside a single parent scene (see Player components above) |
| `res://scripts/` | Standalone scripts (data models, managers) |
| `res://assets/` | Sprites, audio, fonts |
