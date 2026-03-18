# Data Model: Depth-Scaled Combat

## DepthTierConfig (`scripts/data_models/DepthTierConfig.gd`)

Typed wrapper for a single depth-tier entry read from `dungeon_config.json → depth_tiers`.

| Field | Type | Description |
|-------|------|-------------|
| `depth_min` | `int` | Minimum room depth (inclusive) this tier applies to |
| `depth_max` | `int` | Maximum room depth (inclusive); `-1` = unbounded |
| `waves` | `Array[int]` | Wave sizes: `waves[0]` = initial spawn count, `waves[1+]` = reinforcement wave sizes |
| `trigger_threshold` | `int` | Alive enemy count at or below which the next wave fires |
| `alive_cap` | `int` | Maximum enemies that can be alive simultaneously |
| `min_spawn_distance` | `float` | Minimum distance from player for spawn point selection |

**Static methods:**

- `from_dict(data: Dictionary) -> Resource` — deserializes one tier entry; safe defaults: `depth_min=1`, `depth_max=-1`, `waves=[]`, `trigger_threshold=2`, `alive_cap=4`, `min_spawn_distance=200.0`
- `find_for_depth(tiers: Array, depth: int) -> Resource` — returns the first tier where `depth_min <= depth` and (`depth_max == -1` or `depth <= depth_max`); returns `null` if none match

**Invariants:**
- `depth_min >= 1`
- `depth_max == -1` or `depth_max >= depth_min`
- `waves` must not be empty for the tier to produce a valid `WaveConfig`

---

## dungeon_config.json schema change

Remove: `"wave_config": { ... }`

Add:
```json
"depth_tiers": [
  { "depth_min": 1, "depth_max": 1,  "waves": [3],       "trigger_threshold": 2, "alive_cap": 4, "min_spawn_distance": 200.0 },
  { "depth_min": 2, "depth_max": 2,  "waves": [4],       "trigger_threshold": 2, "alive_cap": 4, "min_spawn_distance": 200.0 },
  { "depth_min": 3, "depth_max": 4,  "waves": [4, 2],    "trigger_threshold": 2, "alive_cap": 4, "min_spawn_distance": 200.0 },
  { "depth_min": 5, "depth_max": -1, "waves": [4, 2, 1], "trigger_threshold": 2, "alive_cap": 4, "min_spawn_distance": 200.0 }
]
```

---

## RoomSpawner changes (data fields only)

New private field: `var _depth_tiers: Array[DepthTierConfig] = []`

Removed behaviour: `_load_config()` no longer reads `wave_config` key or sets `cfg.wave_config`.
New behaviour: `_on_player_entered()` calls `_resolve_wave_config()` which populates `_config.wave_config` from `_depth_tiers` before spawning begins.
