# Data Model: Alchemy Lab (040)

## MetaState — new fields

| Field | Type | Default | Description |
|---|---|---|---|
| `alchemy_lab_unlocked` | `bool` | `false` | Persisted. True after restoration purchase. |
| `essence_gain_level` | `int` | `0` | Persisted. Level of the Essence Gain upgrade (0 = not purchased). Max 1 in this iteration. |

Backward-compatible: missing keys default to `false`/`0` on load.

---

## meta_config.json — new block

```json
"alchemy_lab": {
    "name": "Alchemy Lab",
    "cost": 500,
    "upgrades": {
        "essence_gain": {
            "name": "Essence Gain",
            "base_cost": 0,
            "max_levels": 1,
            "essence_per_level": 0.05
        }
    }
}
```

Key semantics:
- `cost` — shards required to restore the building.
- `essence_gain.base_cost = 0` — sentinel: upgrade screen disables the button when cost = 0.
- `essence_gain.essence_per_level = 0.05` — each level adds 5% to the essence gain multiplier.
- `essence_gain.max_levels = 1` — one purchasable level in this iteration.

---

## Derived value — essence_gain_multiplier

Computed in `MetaManager` (analogous to `damage_multiplier`):

```
essence_gain_multiplier = 1.0 + essence_gain_level × essence_per_level
```

At level 0 → `1.0` (no effect). At level 1 → `1.05`.

---

## Save file — added keys

`user://meta_save.json` gains two new keys:

```json
{
  "alchemy_lab_unlocked": false,
  "essence_gain_level": 0
}
```

Old save files without these keys load correctly — `SaveManagerImpl.load_meta_state()` defaults missing keys to `false`/`0`.

---

## State transitions

```
AlchemyLab:
  RUINED ──[purchase_alchemy_lab() success]──► RESTORED

EssenceGainUpgrade:
  Level 0 ── [button disabled in this iteration, no transition]
```
