# Implementation Plan: Room Wave System

**Branch**: `056-wave-system` | **Date**: 2026-03-18 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/056-wave-system/spec.md`

## Summary

Combat rooms gain a three-wave enemy spawn system. Wave 1 (3 enemies) spawns on room entry; waves 2 and 3 (2 and 1 enemy) trigger when the alive count drops to 1. Enemies are always placed at the spawn points farthest from the player. Room clear fires only after all 6 total enemies are killed. Wave config lives in `dungeon_config.json`; logic lives entirely in `RoomSpawner.gd`.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing throughout
**Primary Dependencies**: Godot 4.6 engine; existing `RoomSpawner`, `RoomSpawnConfig`, `SpawnPointData`, `dungeon_config.json`
**Storage**: `data/dungeon_config.json` — adds top-level `wave_config` block and expands combat room spawn point arrays
**Testing**: GUT (`tests/unit/`) — `WaveConfig` has a testable `from_dict` static method; unit tests are mandatory
**Target Platform**: Android mobile / Windows dev
**Project Type**: Single Godot project
**Performance Goals**: 60 fps; sorting 4 spawn points is O(n log n) on a 4-element array — negligible
**Constraints**: Mobile renderer; no new physics bodies or shaders
**Scale/Scope**: 4 files changed (1 new); ~80 lines of logic; no new scenes

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| **I. Single Responsibility** | ✅ Pass | Wave progression is part of `RoomSpawner`'s existing spawn-lifecycle responsibility. No new autoloads. `WaveConfig` is a pure data model. |
| **II. Data-Driven Content** | ✅ Pass | Wave sizes, trigger threshold, alive cap, and min spawn distance all in `dungeon_config.json`, wrapped by `WaveConfig` typed model. |
| **III. Mobile-First** | ✅ Pass | Sorting a 4-element array once per wave (max 3 times per room) has no measurable cost. |
| **IV. Editor-Centric** | ✅ Pass | No scene structure changes. All changes are GDScript + JSON. `RoomSpawner` already exists in scenes via Inspector. |
| **V. Simplicity & YAGNI** | ✅ Pass | Wave logic stays in `RoomSpawner` — no separate `WaveController` abstraction. Per-room wave overrides deferred. |
| **VI. Early Return** | ✅ Pass | `_spawn_wave` guards on empty pool and alive_cap. `_on_enemy_defeated` uses early return for room-clear path. |

**Result**: All principles satisfied. No violations.

## Project Structure

### Documentation (this feature)

```text
specs/056-wave-system/
├── plan.md          ← this file
├── research.md      ← Phase 0 output
├── data-model.md    ← Phase 1 output
├── quickstart.md    ← Phase 1 output
└── tasks.md         ← Phase 2 output (/speckit.tasks — not yet created)
```

### Source Code (files changed)

```text
data/
└── dungeon_config.json          ← add wave_config block; expand combat room spawn points

scripts/data_models/
├── WaveConfig.gd                ← NEW — typed wrapper for wave_config JSON
└── RoomSpawnConfig.gd           ← add wave_config: WaveConfig field

scripts/dungeon/
└── RoomSpawner.gd               ← replace _spawn_enemies() with wave-aware logic

tests/unit/
└── test_wave_config.gd          ← NEW — GUT tests for WaveConfig.from_dict
```

## Phase 0: Research

See [research.md](research.md). Decisions summary:

| Decision | Choice |
|----------|--------|
| Wave logic location | `RoomSpawner.gd` — extends existing spawn lifecycle |
| Wave config data location | Top-level `wave_config` key in `dungeon_config.json` |
| Data model | New `WaveConfig.gd` in `scripts/data_models/` |
| Spawn point selection | Sort by distance from player (farthest first) at spawn time |
| Room-clear condition | `_total_killed == _total_enemies` replaces `_living_count == 0` |
| Combat room spawn points | Expanded to 4 per room to support wave 1 size of 3 |

## Phase 1: Design

### Data Model

See [data-model.md](data-model.md). One new data class (`WaveConfig`), one modified (`RoomSpawnConfig`), two JSON changes.

### Internal Contracts

**`WaveConfig.from_dict(data: Dictionary) -> WaveConfig`**
- Reads `waves` (Array), `trigger_threshold` (int), `alive_cap` (int), `min_spawn_distance` (float)
- All fields have safe defaults: `waves=[]`, `trigger_threshold=1`, `alive_cap=4`, `min_spawn_distance=200.0`

**`RoomSpawner._spawn_wave(wave_idx: int) -> void`**
- Pre-condition: `wave_idx < _config.wave_config.waves.size()`
- Reads wave size, clamps to `alive_cap - _living_count`
- Sorts `_config.spawn_points` by descending distance from player
- Spawns `count` enemies using `sorted[i % pool_size]` cycling
- Increments `_living_count` per spawn; increments `_wave_index`

**`RoomSpawner._on_enemy_defeated(enemy_type_id: String) -> void`** (modified)
- Decrements `_living_count`; increments `_total_killed`
- If `_total_killed == _total_enemies` → room clear (early return after)
- Else if `_wave_index < waves.size()` and `_living_count <= trigger_threshold` → `_spawn_wave(_wave_index)`

**Wave system opt-in guard**
- `if _config.wave_config == null: _spawn_enemies_legacy()` — BossRoom01, StartRoom01 unaffected
- `_spawn_enemies_legacy()` is the current `_spawn_enemies()` renamed; no changes to its logic

### Agent Context Check

No new technology or architectural patterns. `CLAUDE.md` requires no updates.
