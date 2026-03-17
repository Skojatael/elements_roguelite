# Data Model: 053-magic-missile-chain

## JSON Schema Changes

### `data/skills.json` — magic_missile entry (add field)

```json
{
  "id": "magic_missile",
  "speed": 600.0,
  "max_distance": 2200.0,
  "max_charges": 3,
  "cooldown": 1.0,
  "chain_damage_mult": 0.5
}
```

**New field**: `chain_damage_mult: float` — fraction of primary damage applied to the chained target. Range `[0.0, 1.0]`. Tunable without code changes. Default/fallback if key absent: `1.0` (safe, full damage).

---

### `data/relics.json` — add chaining_stone to uncommon tier

Current uncommon relics:
```json
"uncommon": {
  "storm_band": { ... },
  "bulwark_shard": { ... }
}
```

New entry to add:
```json
"chaining_stone": {
  "name": "Chaining Stone",
  "tier": "uncommon",
  "tags": ["projectile", "chain"],
  "effect_stat": "",
  "effect_mult": 1.0,
  "description": "Magic Missile strikes a second enemy for 50% damage."
}
```

**Why `effect_stat: ""`**: Same conditional-relic pattern as `executioners_mark` and `berserker_stone`. `compute_stat_mult()` skips entries with empty `effect_stat` — the relic activates a behaviour, not a multiplier.

---

## GDScript State Changes

### `SkillComponent` — new instance variable

```gdscript
var _chain_damage_mult: float = 1.0
```

Populated in `_load_skill_data()` from `entry.get("chain_damage_mult", 1.0)`.
Passed to `Projectile.setup()` as the new final argument.

---

### `Projectile` — new instance variable

```gdscript
var _chain_damage_mult: float = 1.0
```

Set in `setup()`. Used in `_try_chain()` to scale the secondary damage application.

---

## Relationships

```
skills.json["magic_missile"]["chain_damage_mult"]
  └─ read by SkillComponent._load_skill_data()
  └─ stored as _chain_damage_mult
  └─ passed to Projectile.setup()
  └─ stored as Projectile._chain_damage_mult
  └─ applied in Projectile._try_chain() → chain_target.take_damage(_damage * _chain_damage_mult)

relics.json["uncommon"]["chaining_stone"]
  └─ loaded by RelicManagerImpl.build_pool()
  └─ activated via RelicManager.pick_relic("chaining_stone")
  └─ queried by RelicManagerImpl.has_chain_relic() → active_relic_ids.has("chaining_stone")
  └─ exposed by RelicManager.has_chain_relic()
  └─ checked in Projectile._try_chain() → gate for chain execution
```
