# Research: Depth-Scaled Combat

## Decision: Replace global wave_config with depth_tiers array

**Decision**: Remove the top-level `wave_config` key from `dungeon_config.json`. Replace with a `depth_tiers` array where each entry specifies a depth range and its full wave configuration (initial spawn = waves[0], subsequent waves = waves[1+], trigger threshold, alive cap, min spawn distance).
**Rationale**: The existing `WaveConfig.waves` array already represents all waves including the initial spawn as `waves[0]`. Extending this pattern to per-depth tiers requires only a new wrapper with depth range fields. No changes to the wave-spawning engine downstream.
**Alternatives considered**: Separate `initial_spawn` field from `waves` (rejected — redundant split of what is already a sequential wave list); keeping global `wave_config` and adding overrides per room type (rejected — depth is not a room-type property, rooms of the same type can appear at different depths).

---

## Decision: Where to store depth_tiers in RoomSpawner

**Decision**: `var _depth_tiers: Array[DepthTierConfig]` directly on `RoomSpawner`, populated in `_load_config()`. Not stored in `RoomSpawnConfig`.
**Rationale**: `depth_tiers` is global dungeon configuration, not per-room spawn configuration. Adding it to `RoomSpawnConfig` would give that model two distinct concerns (room-specific spawn points vs. global depth rules). Keeping it on `RoomSpawner` as a private cache keeps concerns separated.
**Alternatives considered**: Field on `RoomSpawnConfig` (rejected — mixes room-specific and global config in one model); re-reading `dungeon_config` in `_on_player_entered` (rejected — redundant parse on every room entry).

---

## Decision: When to resolve the wave config (deferred resolution)

**Decision**: Resolve `_config.wave_config` at the start of `_on_player_entered()`, in a new `_resolve_wave_config()` helper, not in `_load_config()`.
**Rationale**: `_load_config()` runs in `_ready()` before RoomLoader sets `depth` on the spawner. Attempting to resolve the tier in `_ready()` would always read `depth = 0` (the default). Deferring to `_on_player_entered()` guarantees depth is set.
**Alternatives considered**: Overriding depth in `_load_config()` via a deferred call (rejected — fragile ordering); exposing a `set_depth()` method that triggers config re-resolution (rejected — creates an unexpected two-phase init).

---

## Decision: depth_max = -1 for unbounded upper tier

**Decision**: Use `depth_max: -1` as a sentinel for "no upper bound" (depth 5+).
**Rationale**: Simple sentinel value. `find_for_depth` checks `depth_max == -1 or depth <= depth_max`. Avoids a large magic number like 999 in config data.
**Alternatives considered**: `depth_max: 999` (rejected — magic number); omitting `depth_max` for the last tier (rejected — all tiers should have uniform structure for predictable deserialization).

---

## Decision: Static return types -> Resource

**Decision**: `DepthTierConfig.from_dict` and `find_for_depth` declare `-> Resource`, not `-> DepthTierConfig`.
**Rationale**: Identical issue to `WaveConfig.from_dict` (feature 056): GDScript self-referential class_name return types fail compilation in headless GUT mode for files not yet opened in the Godot editor. Using `-> Resource` avoids the compile failure.
**Alternatives considered**: `-> DepthTierConfig` (rejected — causes headless test failures identical to WaveConfig bug).

---

## Decision: Elite and Boss rooms excluded from depth-tier resolution

**Decision**: `_resolve_wave_config()` skips tier lookup and leaves `_config.wave_config = null` when `room_type_id.contains("Boss")` or `room_type_id.contains("Elite")`.
**Rationale**: Spec FR-005 explicitly excludes these room types. Elite rooms use their own `enemy_count_mult` config. Boss room has a single boss spawn.
**Alternatives considered**: Separate exclusion list in JSON (rejected — over-engineering for two known room types with stable naming conventions).
