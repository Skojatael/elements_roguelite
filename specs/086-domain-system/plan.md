# Implementation Plan: Domain System

**Branch**: `086-domain-system` | **Date**: 2026-03-28 | **Spec**: [spec.md](spec.md)

## Summary

Restructure enemy data from a flat-category model to a three-level tier/domain/id hierarchy. Replace the single combat room pool with per-domain pools. Add `run_domain` to RunManager. Replace the single TeleportDoor with three domain-specific buttons in the hub (only Forest active). Thread the domain through DungeonGenerator so it selects the correct room pool at generation time.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Storage**: `data/enemies.json`, `data/dungeon_config.json` (restructured), `scripts/managers/RunManager.gd` (new field)
**Testing**: GUT unit tests
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: No runtime cost — domain is a single string read at run-start
**Constraints**: No new autoloads; RunManager autoload extends RunManager script directly (no thin-wrapper split); ResourceManager autoload is a thin wrapper over ResourceManagerImpl

## Constitution Check

- **I. Single Responsibility**: RunManager gains one new field (`run_domain`). ResourceManagerImpl gains one new method (`get_combat_room_pool`). DungeonGenerator pools are selected from config via domain param. TeleportDoor gains a domain export. All within existing responsibilities. ✅
- **II. Data-Driven Content**: Combat room pools and enemy groupings live in JSON. No domain names hardcoded in scripts (read as strings from config/signals). ✅
- **III. Mobile-First**: String lookup at run-start only. No per-frame cost. ✅
- **IV. Editor-Centric**: Two new TeleportDoor instances added via Editor. `@export var domain: String` set in Inspector. `hub_exited(domain)` signal carries domain via existing signal wiring. ✅
- **V. Simplicity & YAGNI**: No new abstractions. Desert/Frost buttons are plain disabled Buttons — no stub scripts. ✅
- **VI. Early Return**: All modified functions follow existing guard-clause patterns. ✅

No constitution violations.

## Decisions

**D-001 — enemies.json root structure**: Remove the `"enemies"` wrapper key entirely. New root keys are `"normal"`, `"elite"`, `"boss"`. Within each tier, sub-keys are domain names (`"forest"`, `"desert"`, `"frost"`). Within each domain, entries are a dictionary keyed by enemy ID (not an array). The `"domain"` field is removed from each entry — domain membership is implicit from position. `"common"` is renamed to `"normal"`.

**D-002 — combat_room_pool rename**: Replace the single `"combat_room_pool": [...]` key in `dungeon_config.json` with `"combat_room_pools": {"forest": [...], "desert": [], "frost": []}`. All existing callers of `config.get("combat_room_pool", [])` are updated to `config.get("combat_room_pools", {}).get(domain, [])`. The old key is fully removed.

**D-003 — run_domain threading**: `RunManager.start_run(mode: String)` gains an optional second parameter `domain: String = "forest"`. This is backwards-compatible — existing callers (`DevPanel`, `_on_hub_boss_run_pressed`) that don't pass a domain default to `"forest"`. `run_domain: String` is added as a public state field on RunManager, reset in `start_run`. DungeonGenerator reads it via `RunManager.run_domain` in `_generate()` and passes it as a parameter to `_generate_with()` for testability.

**D-004 — TeleportDoor signal update**: `TeleportDoor` gains `@export var domain: String = "forest"`. The `teleport_activated` signal changes from no-arg to `teleport_activated(domain: String)`. `_on_button_pressed()` emits `teleport_activated.emit(domain)`. In HubRoom.tscn, a second and third TeleportDoor instance are added (Editor task) with `domain = "desert"` and `domain = "frost"` and their buttons set to `disabled = true` in the Inspector. `HubRoom.hub_exited` signal changes to `hub_exited(domain: String)`. `Main._on_hub_exited(domain: String)` calls `RunManager.start_run("endless", domain)`.

**D-005 — ResourceManager enemy loading**: `_load_enemy_data()` is updated to iterate the new three-level structure: iterate tier keys (`normal`, `elite`, `boss`), then domain keys, then enemy-id keys (the dict values). The public caches (`_enemy_ids_cache`, `_enemy_essence_cache`, `_enemy_rooms_required_cache`) remain unchanged — they are flat ID→value maps, unaffected by the new nesting. A new method `get_combat_room_pool(domain: String) -> Array` is added to `ResourceManagerImpl` and exposed on the `ResourceManager` autoload. `DungeonGenerator._generate()` calls `ResourceManager.get_combat_room_pool(RunManager.run_domain)` instead of reading `config.get("combat_room_pool", [])` from the raw dungeon config dict.

## Schema Changes

**SC-001 — `data/enemies.json`** (complete restructure):

Old root: `{ "enemies": { "common": [...], "elite": [...], "boss": [...] } }`

New root: `{ "normal": { "forest": { "forest_tank": {...}, "forest_healer": {...}, "forest_disruptor": {...}, "forest_poisoner": {...} } }, "elite": { "forest": { "forest_buffer": {...}, "forest_reflector": {...} } }, "boss": { "forest": { "forest_boss_thorns": {...} } } }`

Each enemy dict retains all existing fields except `"domain"` (removed). Key change: arrays replaced with dicts keyed by enemy ID.

**SC-002 — `data/dungeon_config.json`**:

Old: `"combat_room_pool": ["ForestRoom01"]`

New: `"combat_room_pools": { "forest": ["ForestRoom01"], "desert": [], "frost": [] }`

All other keys (`depth_bands`, `elite_depth_bands`, `spawn_configs`, `depth_tiers`, etc.) remain unchanged.

**SC-003 — RunManager state**:

New public field: `run_domain: String = ""` — set in `start_run(mode, domain)`, cleared to `""` in `end_run()` (or reset in next `start_run`). `start_run` signature: `func start_run(mode: String, domain: String = "forest") -> void`.

## Affected Files

**`data/enemies.json`** — Full restructure per SC-001. Remove `"enemies"` wrapper, rename `"common"` → `"normal"`, convert each category from an array to a domain sub-dict, convert each domain value from an array to an id-keyed dict, remove `"domain"` field from each entry.

**`data/dungeon_config.json`** — Replace `"combat_room_pool"` key with `"combat_room_pools"` dict per SC-002.

**`scripts/managers/ResourceManager.gd` (ResourceManagerImpl)** — Update `_load_enemy_data()` to traverse the new three-level structure (tier → domain → id) instead of the old category-array structure. Add `get_combat_room_pool(domain: String) -> Array` that reads `dungeon_config.combat_room_pools[domain]` with empty-array fallback and a warning if the domain is unknown.

**`autoload/ResourceManager.gd`** — Add delegating `get_combat_room_pool(domain: String) -> Array` method that calls `_impl.get_combat_room_pool(domain)`.

**`scripts/managers/RunManager.gd`** — Add `run_domain: String = ""` public field. Update `start_run(mode: String)` to `start_run(mode: String, domain: String = "forest")`, set `run_domain = domain` after existing mode assignment, include domain in the existing log print and in `run_state.run_mode`-style fields if needed.

**`scripts/dungeon/DungeonGenerator.gd`** — Update `_generate()` to pass `RunManager.run_domain` into `_generate_with()` as a new `domain` parameter. Update `_generate_with(config, gear_owned, depth_scaling)` signature to `_generate_with(config, gear_owned, depth_scaling, domain: String = "forest")`. Replace `config.get("combat_room_pool", [])` with `ResourceManager.get_combat_room_pool(domain)`. Remove direct access to `combat_room_pool` from the config dict in this file.

**`scenes/hub/TeleportDoor.gd`** — Add `@export var domain: String = "forest"`. Change `signal teleport_activated` to `signal teleport_activated(domain: String)`. Update `_on_button_pressed()` to emit `teleport_activated.emit(domain)`.

**`scenes/hub/TeleportDoor.tscn`** — No direct text edit. Updated implicitly when the script changes (signal signature). The `domain` export is set per-instance in the Editor for each TeleportDoor node in HubRoom.tscn.

**`scenes/hub/HubRoom.gd`** — Change `signal hub_exited` to `signal hub_exited(domain: String)`. Update `_on_teleport_activated(domain: String)` to forward the domain: `hub_exited.emit(domain)`. Remove the no-arg version of the handler. Update `hub_boss_run_pressed` handling if needed (boss run always uses current run domain; no change needed — boss run bypasses domain selection).

**`scenes/hub/HubRoom.tscn`** *(Editor task)* — Add two more TeleportDoor instances (DesertTeleportDoor, FrostTeleportDoor) as siblings of the existing ForestTeleportDoor. Set `domain = "desert"` and `domain = "frost"` via Inspector. Set each new door's internal Button to `disabled = true` via Inspector. Assign both new door nodes to HubRoom exports (add two new exports: `_desert_teleport_door: TeleportDoor` and `_frost_teleport_door: TeleportDoor`) and wire their `teleport_activated` signals to `_on_teleport_activated` in the Inspector.

**`scenes/core/main.gd`** — Update `_on_hub_exited()` to `_on_hub_exited(domain: String)`. Pass domain to `RunManager.start_run("endless", domain)`. Update the connection in `_spawn_hub_room()` (lambda must forward domain: `hub_exited.connect(_on_hub_exited)`). The DevPanel start_run call keeps its `start_run("endless")` default.

**`tests/unit/test_dungeon_generation.gd`** — Update existing `_generate_with(STUB_CONFIG, false, false)` and `_generate_with(STUB_CONFIG, false, true)` calls to the new 4-arg signature: `_generate_with(STUB_CONFIG, false, false, "forest")`. Add a stub `"combat_room_pools"` key to `STUB_CONFIG` (replace current `"combat_room_pool"` key). The test for difficulty_mult is unaffected by domain; the room-pool selection tests should verify the correct domain pool is used.

**`tests/unit/test_resource_manager_enemy_domain.gd`** *(new file)* — GUT unit test for the new `_load_enemy_data()` logic using an inline stub dict with the new three-level structure. Covers: all enemy IDs from all tiers/domains are registered; `enemy_id_exists` returns true for a forest ID; `get_enemy_base_essence` returns the correct value; `get_enemy_rooms_required` returns the boss threshold; loading old structure (with `"enemies"` wrapper) fails gracefully (or emits a clear error).

## CLAUDE.md Note

The **Domain system** section of CLAUDE.md should be updated under the Run session heading to note: `RunManager.run_domain: String` stores the active domain for the run, set via `start_run(mode, domain)`. DungeonGenerator reads it to select `combat_room_pools[domain]` from dungeon_config. HubRoom emits `hub_exited(domain)` when a domain teleport button is pressed.
