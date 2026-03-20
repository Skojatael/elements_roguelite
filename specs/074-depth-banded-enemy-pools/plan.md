# Implementation Plan: Depth-Banded Enemy Pools

**Branch**: `074-depth-banded-enemy-pools` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/074-depth-banded-enemy-pools/spec.md`

## Summary

Replace the flat per-room-type enemy spawn configs for combat rooms with a depth-banded weighted pool system. Each depth band defines one or more waves; each wave defines a fixed set of enemy slots; each slot holds a weighted pool of enemy IDs that resolves to exactly one enemy at spawn time. All composition data lives in `dungeon_config.json`. The room-type scene selection remains unchanged; only the enemy composition changes.

## Technical Context

**Language/Version**: GDScript, Godot 4.6
**Primary Dependencies**: `dungeon_config.json`, `RoomSpawner.gd`, `SpawnPointData.gd`, `RoomSpawnConfig.gd`
**Storage**: JSON (`data/dungeon_config.json`)
**Testing**: GUT (`tests/unit/`)
**Target Platform**: Android mobile / Windows dev
**Project Type**: Single Godot project
**Performance Goals**: 60 fps mobile — pool resolution is O(n) in pool size (max ~4 entries), negligible cost
**Constraints**: No new scenes, no editor tasks, no new autoloads
**Scale/Scope**: 4 depth bands, 3 wave depths, up to 4 slots per wave, up to 4 pool entries per slot

## Constitution Check

- **I. Single Responsibility**: Pool resolution logic added to `SpawnPointData` (cohesive — it owns slot data). Depth-band loading added to `RoomSpawner` (cohesive — it owns config loading). No new autoloads. ✅
- **II. Data-Driven Content**: All band, wave, slot, enemy IDs, weights, and positions live in `dungeon_config.json`. No numeric constants in GDScript. ✅
- **III. Mobile-First**: Pool sampling is O(pool_size) per slot (≤4 iterations). No physics or shader changes. ✅
- **IV. Editor-Centric**: No `.tscn` edits. `@export var depth: int` on `RoomSpawner` already set by `RoomLoader` — no new node-reference patterns. ✅
- **V. Simplicity & YAGNI**: `wave_spawn_points` field added to `RoomSpawnConfig` is immediately consumed by `RoomSpawner._spawn_wave()`. No speculative abstractions. ✅
- **VI. Early Return**: All new methods (`pick_enemy_id`, `_load_depth_band_config`) use guard clauses; no nesting deeper than 2 levels. ✅

## Decisions

**Decision 1 — Per-wave slot storage vs. flat list**
`RoomSpawnConfig` gains a `wave_spawn_points: Array` field (array of arrays of `SpawnPointData`), indexed by wave index. This replaces the flat `spawn_points` cycling pattern for depth-band combat rooms. Legacy code (`_spawn_enemies_legacy`, Elite and Boss configs) continues to use `spawn_points` unchanged.

Rationale: the spec requires each wave to define its own specific slots with their own pools. A flat list cannot distinguish wave-0 slots from wave-1 slots when the pools differ (e.g., depth 3-4 wave 0 has 4 fixed enemies while wave 1 has 2 with a pooled slot).

**Decision 2 — Pool resolution in SpawnPointData vs. RoomSpawner**
`SpawnPointData` gains `enemy_pool: Array` and `pick_enemy_id() -> String`. Resolution is encapsulated in the data model. `RoomSpawner._spawn_wave()` calls `sp.pick_enemy_id()` per slot without knowing pool internals.

Rationale: keeps `RoomSpawner` free of pool-sampling logic (SRP). `SpawnPointData.from_dict()` handles both legacy `enemy_id` key (wraps as single-entry 100% pool) and new `pool` key.

**Decision 3 — depth_tiers wave counts vs. depth_bands slot counts**
For depth-band combat rooms, `WaveConfig.waves` is derived from `wave_spawn_points[i].size()` (slot count per wave in the band). The `depth_tiers` entry for the matching depth is still consulted for `trigger_threshold`, `alive_cap`, and `min_spawn_distance`; only its `waves` array is ignored for band rooms (the band is the authoritative source of wave slot counts).

Rationale: a single source of truth for wave composition avoids a consistency constraint between two JSON sections.

**Decision 4 — Combat room detection for band lookup**
A room is treated as a band-eligible combat room when its `room_type_id` is present in `combat_room_pool` (read from `dungeon_config.json`). With the pool now containing only `"ForestRoom01"`, this is a clean single-type check. Elite, Boss, and Start rooms continue using `spawn_configs` as today.

## Schema Changes

**`data/dungeon_config.json` additions:**

Add a top-level `depth_bands` array. Each entry has `min_depth: int`, `max_depth: int` (−1 = open-ended), and `waves: Array` — an array of wave definitions. Each wave definition is an array of slot objects, each slot having `pool: Array` (list of `{enemy_id, weight}` objects), `position: {x, y}`, and `radius: float`.

The four bands encode the compositions from the spec:
- Band 1 (depth 1): 1 wave, 3 slots — slots 1 and 2 fixed forest_tank; slot 3 is 90% forest_tank / 10% forest_disruptor.
- Band 2 (depth 2): 1 wave, 4 slots — slots 1–2 fixed forest_tank; slot 3 is 50%/50% forest_tank/forest_healer; slot 4 fixed forest_disruptor.
- Band 3 (depth 3–4): 2 waves — wave 0: 4 fixed slots (tank, tank, healer, disruptor); wave 1: 2 slots (fixed tank; 70/10/10/10 pool).
- Band 4 (depth 5+, max_depth=−1): 3 waves — wave 0: 4 fixed slots (tank, poisoner, healer, disruptor); wave 1: same as band 3 wave 1; wave 2: 1 slot (50%/50% tank/poisoner).

Remove the `ForestRoom01` entry from `spawn_configs` (replaced by the depth-band system per FR-010). Update `combat_room_pool` from `["CombatRoom01", "CombatRoom02"]` to `["ForestRoom01"]`.

**`scripts/data_models/SpawnPointData.gd` additions:**

New field `enemy_pool: Array` — stores raw pool entries as `{enemy_id: String, weight: int}` dictionaries. Updated `from_dict()` accepts either the legacy `enemy_id` key (converts to single-entry 100% pool) or the new `pool` key. New method `pick_enemy_id() -> String` performs weighted random sampling from `enemy_pool`; returns the first entry if pool has one entry (deterministic fast path); logs a warning and returns an empty string if pool is empty.

## Affected Files

**`data/dungeon_config.json`** — Update `combat_room_pool` to `["ForestRoom01"]` (rename from CombatRoom01; remove CombatRoom02). Add `depth_bands` array (4 bands, positions chosen to match existing room geometry: `(-350,-250)`, `(350,-250)`, `(-150,250)`, `(150,250)` for 4-slot waves; `(-350,-250)`, `(350,-250)`, `(0,250)` for 3-slot waves; `(-200,0)`, `(200,0)` for 2-slot waves; `(0,0)` for 1-slot waves). Remove the `ForestRoom01` key from `spawn_configs`.

**`scripts/data_models/SpawnPointData.gd`** — Add `enemy_pool: Array` field, update `from_dict()` to parse both `enemy_id` and `pool` schemas, add `pick_enemy_id() -> String` weighted-sampling method. The existing `enemy_id: String` field is retained and populated to the resolved enemy id at spawn time for logging and signal emission (called from `RoomSpawner._spawn_wave()`).

**`scripts/data_models/RoomSpawnConfig.gd`** — Add `wave_spawn_points: Array` field (empty by default). This field is populated by `RoomSpawner._load_depth_band_config()` and consumed by `_spawn_wave()`.

**`scripts/dungeon/RoomSpawner.gd`** — Three targeted changes: (1) `_load_config()` checks whether `room_type_id` is in `combat_room_pool`; if so, calls new `_load_depth_band_config()` instead of the `spawn_configs` lookup; (2) new private method `_load_depth_band_config() -> RoomSpawnConfig` iterates `depth_bands`, finds the matching band for `self.depth` (deepest band whose `min_depth ≤ depth` and `max_depth == -1` or `max_depth >= depth`), builds `wave_spawn_points` from band slot data, validates all pool enemy IDs via `ResourceManager.enemy_id_exists()`, and returns the populated `RoomSpawnConfig`; (3) `_resolve_wave_config()` derives `WaveConfig.waves` from `wave_spawn_points[i].size()` (when `wave_spawn_points` is non-empty) instead of from `depth_tiers.waves`, while still reading `trigger_threshold`, `alive_cap`, and `min_spawn_distance` from the matching depth tier; (4) `_spawn_wave()` checks whether `wave_spawn_points` has an entry for `wave_idx`; if so, iterates those slots directly (calling `sp.pick_enemy_id()` per slot), bypassing the existing sorted flat-list cycling; otherwise falls through to the existing legacy path.

**`tests/unit/test_spawn_point_data.gd`** (new) — GUT unit tests for `SpawnPointData.pick_enemy_id()`: single-entry pool always returns that enemy_id; empty pool returns empty string; 100-sample test over a 50/50 pool verifies both entries appear; 100-sample test over 70/10/10/10 pool verifies the dominant entry wins the majority; deterministic 100%-weight pool always returns the same id.

**`repo_map.md`** — Update `SpawnPointData`, `RoomSpawnConfig`, and `RoomSpawner` entries to reflect new fields and methods.

**`CLAUDE.md`** — Update the `dungeon_config.json` row in the data layer table to mention `depth_bands` alongside `spawn_configs`.
