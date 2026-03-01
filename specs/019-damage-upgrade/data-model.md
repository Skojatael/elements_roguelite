# Data Model: Damage Multiplier Upgrade

## MetaState extension (`scripts/data_models/MetaState.gd`)

| Field                   | Type  | Default | Description                                            |
|-------------------------|-------|---------|--------------------------------------------------------|
| `total_shards`          | `int` | `0`     | Existing field — unchanged.                            |
| `damage_upgrade_level`  | `int` | `0`     | NEW — how many damage upgrade levels purchased (0–10). |

**Constraints**:
- `0 <= damage_upgrade_level <= max_levels` (10).
- Never decremented.
- Persisted alongside `total_shards`.

---

## Save format (`user://meta_save.json`)

```json
{
  "total_shards": 120,
  "damage_upgrade_level": 3
}
```

Backward compatible: loading a file without `"damage_upgrade_level"` returns `0` (no upgrade purchased).

---

## meta_config.json (`data/meta_config.json`)

```json
{
  "shard_divisor": 3,
  "damage_upgrade": {
    "base_cost": 50,
    "cost_scale": 1.2,
    "max_levels": 10,
    "damage_per_level": 0.1
  }
}
```

| Field                           | Type    | Value | Description                                                                |
|---------------------------------|---------|-------|----------------------------------------------------------------------------|
| `damage_upgrade.base_cost`      | `int`   | 50    | Shard cost for level 0→1.                                                  |
| `damage_upgrade.cost_scale`     | `float` | 1.2   | Multiplier applied to the previous cost at each level. Floor at each step. |
| `damage_upgrade.max_levels`     | `int`   | 10    | Maximum purchasable levels.                                                |
| `damage_upgrade.damage_per_level` | `float` | 0.1 | Additive damage fraction per level (`base * (1 + level * damage_per_level)`). |

**Pre-computed cost table** (floor at each step from base_cost=50, scale=1.2):

| Level transition | Shard cost |
|-----------------|------------|
| 0 → 1           | 50         |
| 1 → 2           | 60         |
| 2 → 3           | 72         |
| 3 → 4           | 86         |
| 4 → 5           | 103        |
| 5 → 6           | 123        |
| 6 → 7           | 147        |
| 7 → 8           | 176        |
| 8 → 9           | 211        |
| 9 → 10          | 253        |

Total to max: **1281 shards**.

---

## New/modified code entities

### MetaManagerImpl — new methods (`scripts/managers/MetaManager.gd`)

| Method | Signature | Description |
|--------|-----------|-------------|
| `get_upgrade_cost` | `(level: int, base_cost: int, scale: float) -> int` | Computes cost for a given level by iterating floor(prev*scale) from base_cost. |
| `purchase_damage_upgrade` | `(cost: int, save_manager: Node) -> bool` | Atomic: deducts `cost` from total_shards, increments damage_upgrade_level, saves. Returns false if balance insufficient. |
| `get_damage_multiplier` | `() -> float` | Returns `1.0 + float(damage_upgrade_level) * damage_per_level` (read from MetaState). |

### MetaManager autoload — new thin wrappers (`autoload/MetaManager.gd`)

| Member | Type | Description |
|--------|------|-------------|
| `damage_multiplier` | computed property `float` | `return _impl.get_damage_multiplier(damage_per_level)` |
| `get_next_upgrade_cost()` | `-> int` | Reads config, delegates to impl.get_upgrade_cost. Returns 0 if maxed. |
| `purchase_damage_upgrade()` | `-> bool` | Reads config, computes cost, delegates to impl, emits shards_changed on success. |

### UpgradeShop — new co-located component (`scenes/hub/UpgradeShop.gd`)

| Member | Description |
|--------|-------------|
| `@export var _button: Button` | Assigned in Inspector. |
| `_ready()` | Connects button.pressed and MetaManager.shards_changed; calls _update_button(). |
| `_update_button()` | Sets button text and disabled state based on current level and affordability. |
| `_on_buy_pressed()` | Calls MetaManager.purchase_damage_upgrade(); calls _update_button() on success. |

### CombatComponent — modified (`scenes/player/components/CombatComponent.gd`)

| Member | Description |
|--------|-------------|
| `_base_attack_damage: float` | Caches the Inspector-assigned `attack_damage` value in `_ready()`. |
| connects `RunManager.run_started` | In `_ready()`, calls `_apply_damage_multiplier()` each time a run starts. |
| `_apply_damage_multiplier()` | Sets `attack_damage = _base_attack_damage * MetaManager.damage_multiplier`. |

---

## Relationships

```
meta_config.json
  damage_upgrade.base_cost / cost_scale / max_levels / damage_per_level
        │
        ▼ (read by MetaManager autoload)
MetaManagerImpl.get_upgrade_cost(level, base, scale) → int
MetaManagerImpl.purchase_damage_upgrade(cost, save_manager) → bool
        │ mutates
        ▼
MetaState.total_shards -= cost
MetaState.damage_upgrade_level += 1
        │ saved to
        ▼
user://meta_save.json

MetaManagerImpl.get_damage_multiplier(damage_per_level) → float
        │ read by
        ▼
CombatComponent._apply_damage_multiplier()
  attack_damage = _base_attack_damage * multiplier
```
