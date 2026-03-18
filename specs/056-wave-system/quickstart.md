# Quickstart: Room Wave System

## What This Feature Does

Combat rooms now spawn enemies in three waves rather than all at once. Wave 1 (3 enemies) spawns on room entry. Each subsequent wave triggers when the alive count drops to 1. Enemies always spawn at the positions farthest from the player.

## Files Changed

| File | Change |
|------|--------|
| `data/dungeon_config.json` | Add top-level `wave_config`; expand CombatRoom01 + CombatRoom02 to 4 spawn points each |
| `scripts/data_models/WaveConfig.gd` | New data model |
| `scripts/data_models/RoomSpawnConfig.gd` | Add `wave_config: WaveConfig` field |
| `scripts/dungeon/RoomSpawner.gd` | Replace `_spawn_enemies()` with wave-aware logic; add distance-sorted spawn selection |

## Implementation Steps (summary)

1. **`WaveConfig.gd`** — create with fields `waves: Array[int]`, `trigger_threshold: int`, `alive_cap: int`, `min_spawn_distance: float` and `static func from_dict`.
2. **`RoomSpawnConfig.gd`** — add `var wave_config: WaveConfig` field.
3. **`dungeon_config.json`** — add `wave_config` block at top level; expand combat room spawn point arrays.
4. **`RoomSpawner._load_config()`** — after calling `RoomSpawnConfig.from_dict()`, read `dungeon_config["wave_config"]` and set `cfg.wave_config = WaveConfig.from_dict(...)`.
5. **`RoomSpawner`** — add fields `_wave_index`, `_total_killed`, `_total_enemies`. Replace `_spawn_enemies()` with `_spawn_wave(wave_idx)` that:
   - Respects `alive_cap`
   - Sorts spawn points by distance from player (farthest first)
   - Increments `_living_count` per enemy spawned
   - Increments `_wave_index`
6. **`RoomSpawner._on_player_entered()`** — call `_spawn_wave(0)` instead of `_spawn_enemies()`.
7. **`RoomSpawner._on_enemy_defeated()`** — decrement `_living_count`, increment `_total_killed`. Check room clear against `_total_enemies`. Check wave trigger against `trigger_threshold`.

## Guard: Wave system is opt-in

If `_config.wave_config == null`, `RoomSpawner` falls back to the original flat `_spawn_enemies()` behaviour. This means BossRoom01 and any future room types without wave config are unaffected.

## Testing

1. Enter CombatRoom01 — verify exactly 3 enemies spawn.
2. Kill 2 enemies — verify wave 2 spawns (alive goes from 1 → 3).
3. Kill 2 more — verify wave 3 spawns (alive goes from 1 → 2).
4. Kill final enemy — verify `room_cleared` fires and run stats increment.
5. At no point should alive count exceed 4.
6. Stand at room center; verify no enemy spawns within 200 units of player.
