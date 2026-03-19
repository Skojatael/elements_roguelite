# Data Model: HP Regeneration (060-hp-regen)

## JSON Schema Change — data/relics.json

New entry in the `"common"` tier:

```json
"common_regen": {
    "name": "Regeneration Stone",
    "tags": ["survival"],
    "effect_stat": "hp_regen",
    "effect_mult": 0.01,
    "description": "+1% HP per second"
}
```

| Field | Value | Notes |
|---|---|---|
| `id` | `common_regen` | Key name in the JSON object |
| `tier` | `common` | Offered from standard room clears |
| `name` | `"Regeneration Stone"` | Display name in RelicCard UI |
| `tags` | `["survival"]` | For future filtering |
| `effect_stat` | `"hp_regen"` | New stat key; consumed by StatsComponent |
| `effect_mult` | `0.01` | Fraction of max HP regenerated per second |
| `description` | `"+1% HP per second"` | Shown on RelicCard |

`effect_mult: 0.01` flows through `RelicManagerImpl.compute_stat_addend("hp_regen")` unchanged. No schema migration or new data model class is required — `RelicData.from_dict()` already handles arbitrary `effect_stat` values.

---

## Runtime State — StatsComponent

No new persistent fields. The regen amount is computed on every frame:

```
regen_per_second = RelicManager.get_stat_addend("hp_regen")   # sum of all hp_regen effect_mult
heal_this_frame  = regen_per_second × max_health × delta
current_health   = min(current_health + heal_this_frame, max_health)
```

| Expression | Description |
|---|---|
| `regen_per_second` | Accumulated fraction (e.g., 0.01 for one relic, 0.02 for two) |
| `max_health` | Live value already owned by StatsComponent; reflects any relic bonuses |
| `delta` | Frame delta from `_process(delta)` |

`health_changed` signal is emitted by the existing `heal()` call — the HP bar and RunManager player-state sync already respond correctly with no extra wiring.
