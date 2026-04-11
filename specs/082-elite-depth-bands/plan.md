# Implementation Plan: Elite Room Depth Bands

**Branch**: `082-elite-depth-bands` | **Date**: 2026-03-23 | **Spec**: [spec.md](spec.md)

## Summary

Elite rooms currently use a static `spawn_configs` entry (slime/skeleton, legacy path) which belongs to the deleted `EliteRoom01` scene. This feature replaces that with a depth-banded composition system matching how common rooms work: a new `elite_depth_bands` JSON array defines weighted composition variants per depth range, and `RoomSpawner` gains a parallel routing branch that selects a variant at player-entry time and loads it as a single-wave band encounter. `DungeonGenerator` is updated to promote rooms to `"ForestEliteRoom01"` (the replacement scene already in the repo).

## Technical Context

**Language/Version**: GDScript (Godot 4.6, static typing)
**Storage**: JSON config at `res://data/dungeon_config.json`; `.tres` resource at `res://data/rooms/`
**Testing**: GUT unit tests in `tests/unit/`
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Performance Goals**: 60 fps — single wave spawn, no continuous per-frame logic introduced

## Constitution Check

- **I. Single Responsibility** ✅ — `RoomSpawner` already owns enemy spawning; new method `_load_elite_depth_band_config()` is a single-responsibility addition within that class. No new autoloads or scripts needed.
- **II. Data-Driven Content** ✅ — All compositions, weights, and multipliers live in `dungeon_config.json`. No balance constants in GDScript.
- **III. Mobile-First** ✅ — Single-wave spawn with no per-frame logic. Weighted random selection is O(n) where n ≤ 3 variants. No performance concern.
- **IV. Editor-Centric** ✅ — No `.tscn` edits. `ForestEliteRoom01.tscn` already exists; no structural changes required.
- **V. Simplicity & YAGNI** ✅ — Variant selection added as one method. Reuses existing `WaveConfig`, `RoomSpawnConfig`, `SpawnPointData` structures unchanged.
- **VI. Early Return** ✅ — `_load_elite_depth_band_config()` will use guard clauses (empty bands, no match, empty variants) matching the style of `_load_depth_band_config()`.

## Decisions

**D1 — Elite room detection in RoomSpawner**: Use `room_type_id.contains("Elite")` to route elite rooms to the new path, rather than adding a new `elite_room_pool` list to JSON. Rationale: only one elite type exists; the string check is consistent with how `_resolve_wave_config()` already skips elite rooms (same guard). YAGNI — no need for a pool list with one entry.

**D2 — DungeonGenerator promotes to `"ForestEliteRoom01"`**: Change the hard-coded type ID in `_promote_elite_rooms()` from `"EliteRoom01"` to `"ForestEliteRoom01"`. The old `.tres` is deleted; the new one already exists. This is a one-line change that does not affect which rooms get promoted or at what depths (promotion logic unchanged per FR-009).

**D3 — Multipliers stored in `spawn_configs.ForestEliteRoom01`**: Add a `"ForestEliteRoom01"` entry to `spawn_configs` containing only `essence_mult: 1.8` and `enemy_count_mult: 1.5` (no spawn_points). `_load_elite_depth_band_config()` reads these from `spawn_configs[room_type_id]` before building the band config. Reuses existing infrastructure; no new config keys needed. Remove `spawn_configs.EliteRoom01`.

**D4 — Trigger band-wave path via minimal `wave_config`**: `_load_elite_depth_band_config()` sets `cfg.wave_config` with `waves = [slot_count]`, `trigger_threshold = 0`, `alive_cap = MAX_ENEMIES`. This routes `_on_player_entered()` to the existing `_spawn_wave(0)` → `_spawn_band_wave(0)` path without any changes to that dispatch logic.

## Schema Changes

### `dungeon_config.json` additions

Add a new top-level `elite_depth_bands` array alongside `depth_bands`. Each entry has `min_depth`, `max_depth`, and a `variants` array. Each variant has a `weight` (integer) and a `wave` array of enemy slots (same `pool`/`position`/`radius` format as `depth_bands` waves).

The four bands and their compositions (corrected enemy IDs):

**Band 1** — `min_depth: 1`, `max_depth: 2`:
- Variant (weight 100): `forest_tank` × 2, `forest_disruptor` × 1, `{forest_buffer 50 / forest_reflector 50}` × 1

**Band 2** — `min_depth: 3`, `max_depth: 4`:
- Variant A (weight 70): `forest_tank` × 2, `forest_disruptor` × 1, `forest_healer` × 1, `{forest_buffer 50 / forest_reflector 50}` × 1
- Variant B (weight 30): `forest_tank` × 3, `forest_disruptor` × 1, `{forest_buffer 50 / forest_reflector 50}` × 1

**Band 3** — `min_depth: 5`, `max_depth: 6`:
- Variant A (weight 60): `forest_tank` × 1, `forest_disruptor` × 1, `forest_healer` × 1, `forest_poisoner` × 1, `{forest_buffer 50 / forest_reflector 50}` × 1
- Variant B (weight 30): `forest_tank` × 2, `forest_disruptor` × 1, `forest_poisoner` × 1, `{forest_buffer 50 / forest_reflector 50}` × 1
- Variant C (weight 10): `forest_tank` × 2, `forest_disruptor` × 1, `forest_healer` × 1, `forest_buffer` × 1, `forest_reflector` × 1

**Band 4** — `min_depth: 7`, `max_depth: -1`: identical variants and weights to Band 3.

### `dungeon_config.json` removals / renames

Remove `spawn_configs.EliteRoom01` (points to deleted scene/enemy IDs). Add `spawn_configs.ForestEliteRoom01` with `essence_mult: 1.8` and `enemy_count_mult: 1.5` (no `spawn_points` key needed).

## Affected Files

**`data/dungeon_config.json`** — Add the `elite_depth_bands` array as described above. Replace `spawn_configs.EliteRoom01` with `spawn_configs.ForestEliteRoom01` containing only the two multiplier fields.

**`scripts/dungeon/DungeonGenerator.gd`** — In `_promote_elite_rooms()`, change the promoted `room_type_id` string from `"EliteRoom01"` to `"ForestEliteRoom01"`. No other changes to the promotion algorithm.

**`scripts/dungeon/RoomSpawner.gd`** — Four changes: (1) Add `_is_elite_band_room: bool = false` field. (2) In `_load_config()`, after the `combat_room_pool` check, add a guard that sets `_is_elite_band_room = true` and returns `RoomSpawnConfig.new()` when `room_type_id.contains("Elite")`. (3) Add `_load_elite_depth_band_config(raw: Dictionary) -> RoomSpawnConfig` — finds the matching band in `raw.elite_depth_bands` by depth, performs weighted random variant selection, builds a `RoomSpawnConfig` with `wave_spawn_points[0]` from the selected variant's `wave` array, reads `essence_mult` and `enemy_count_mult` from `spawn_configs[room_type_id]`, and sets a minimal `wave_config`. (4) In `_on_player_entered()`, add routing: call `_load_elite_depth_band_config()` when `_is_elite_band_room`, otherwise call `_load_depth_band_config()` when `_is_depth_band_room`.

**`tests/unit/test_elite_depth_bands.gd`** (new) — GUT unit tests covering: band selection at each depth boundary (1, 2, 3, 4, 5, 6, 7, 8), variant weight distribution across 1000 draws for band 2 and band 3, pool resolution for the 50/50 buffer/reflector slot, and correct `essence_mult` / `enemy_count_mult` propagation.
