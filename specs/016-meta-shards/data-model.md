# Data Model: Meta Currency — Shards

## MetaState (`scripts/data_models/MetaState.gd`)

`class_name MetaState extends RefCounted`

| Field          | Type  | Default | Description                                              |
|----------------|-------|---------|----------------------------------------------------------|
| `total_shards` | `int` | `0`     | Cumulative shards earned across all runs and sessions.   |

**Constraints**:
- Always non-negative. Never decremented in this feature.
- Persisted as `{ "total_shards": <int> }` in `user://meta_save.json`.
- Initialized to `0` on first launch (no save file present).

---

## meta_config.json (`data/meta_config.json`)

Balance configuration for meta-progression. Consumed by `ResourceManager.get_meta_config()`.

```json
{
  "shard_conversion_rate": 0.3333
}
```

| Field                   | Type    | Value    | Description                                              |
|-------------------------|---------|----------|----------------------------------------------------------|
| `shard_conversion_rate` | `float` | `0.3333` | Multiplier applied to `essence_cashed_out` when computing shards earned. `floori(essence × rate)`. ~3 essence = 1 shard (e.g. 100 essence → 33 shards). |

---

## Relationships

```
RunManager.run_summary: RunSummary
  └── essence_cashed_out: int
        │
        ▼ (× shard_conversion_rate from meta_config.json)
MetaManager._on_run_ended()
        │
        ▼ floori(essence × rate)
MetaState.total_shards += shards_earned
        │
        ▼
SaveManager.save_meta_state(meta_state)
        │
        ▼
user://meta_save.json
```

---

## Existing types consumed (read-only)

| Type         | Source                                    | Field used               |
|--------------|-------------------------------------------|--------------------------|
| `RunSummary` | `scripts/data_models/RunSummary.gd`       | `essence_cashed_out: int`|
