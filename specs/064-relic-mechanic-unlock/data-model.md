# Data Model: Relic Mechanic Unlock Tags (064)

## No new data models required

`RelicData.gd` already carries `tags: Array[String]`. The two new state fields live entirely inside `RelicManagerImpl` (a `RefCounted`), not in a persistent data model.

## New state fields on RelicManagerImpl

| Field | Type | Description | Lifetime |
|---|---|---|---|
| `_activated_mechanics` | `Array[String]` | Mechanic tags activated this run (e.g. `["burn"]`). | Run-scoped — cleared in `reset()`. |
| `_mechanic_tag_names` | `Array[String]` | Tags that have `_unlocked` counterparts in the current pool. Precomputed at `build_pool()`. | Pool-scoped — cleared in `reset()`, rebuilt in `build_pool()`. |

## Tag eligibility rules (data logic)

A tag `T` on a relic is a **mechanic tag** if `_mechanic_tag_names.has(T)`.
A tag `T` is an **unlock tag** if `T.ends_with("_unlocked")`.

### `_is_relic_eligible(r: RelicData) -> bool`

```
for each tag in r.tags:
    if tag is an unlock tag:
        mechanic = tag without "_unlocked" suffix
        if mechanic NOT in _activated_mechanics → return false
    else if tag is a mechanic tag:
        if tag IS in _activated_mechanics → return false
return true
```

## New relic entries in relics.json

Both added under `"uncommon"` tier.

### burn_damage
```json
"burn_damage": {
    "name": "Searing Seal",
    "tags": ["burn_unlocked"],
    "effect_stat": "",
    "effect_mult": 1.0,
    "description": "Burning enemies take 50% more damage while burning.",
    "deck_count": 1
}
```

### chain_reach
```json
"chain_reach": {
    "name": "Arc Shard",
    "tags": ["chain_unlocked"],
    "effect_stat": "",
    "effect_mult": 1.0,
    "description": "Chain strikes can reach a third target for 25% damage.",
    "deck_count": 1
}
```

> **Note**: `effect_stat: ""` and `effect_mult: 1.0` follow the conditional-relic pattern (see `024-execute-relic`). Runtime effects for these relics are out of scope for this feature — they are pool eligibility stubs. Their actual combat behaviour is a separate feature.

## Invariants

- `_mechanic_tag_names` is always a subset of tag strings derived from `_unlocked` entries in the current pool.
- `_activated_mechanics` is always a subset of `_mechanic_tag_names`.
- `_activated_mechanics` grows monotonically during a run; it is never shrunk mid-run.
- Both fields are always `[]` immediately after `reset()` and before `build_pool()`.
