# Data Model: Alchemy Lab — Essence Condenser Upgrade

**Feature**: 045-shard-generator
**Date**: 2026-03-17

---

## Entities

### MetaState (modified)

`scripts/data_models/MetaState.gd` — two new fields:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `shard_generator_level` | `int` | `0` | Range 0–3. 0 = not purchased. |
| `shard_accumulator` | `float` | `0.0` | Sub-shard fractional progress between floor extractions. |

**State transitions**:
- `shard_generator_level` increments by 1 per purchase; never decremented; capped at `max_levels` (3).
- `shard_accumulator` increases every `_process()` tick; whole-shard portion is drained into `total_shards` and accumulator is decremented by that integer amount.

**Persistence**: Both fields added to `save_meta_state()` and `load_meta_state()` in `SaveManagerImpl`. Missing fields default to 0 (backward compatible).

---

## Config Schema (`data/meta_config.json` — new section)

Added under `alchemy_lab.upgrades`:

```json
"shard_generator": {
  "name": "Essence Condenser",
  "base_cost": 600,
  "cost_scale": 2.0,
  "max_levels": 3,
  "rates_per_hour": [2, 3, 5]
}
```

| Key | Type | Notes |
|-----|------|-------|
| `name` | String | Display name shown in UI |
| `base_cost` | int | Gold cost at level 0 → 1 |
| `cost_scale` | float | Multiplier per level: 600 → 1200 → 2400 |
| `max_levels` | int | Maximum purchasable levels (3) |
| `rates_per_hour` | Array[int] | Index 0 = rate at level 1, etc. |

**Cost formula** (reuses existing `get_upgrade_cost`): `floori(base_cost × cost_scale^level)`.

| Current level | Cost to purchase next | Result |
|---|---|---|
| 0 | 600 | level 1 |
| 1 | 1200 | level 2 |
| 2 | 2400 | level 3 |
| 3 | — | MAX |

---

## New Methods (MetaManagerImpl)

### get_shard_rate_per_hour(rates: Array) -> float

Returns `float(rates[shard_generator_level - 1])` when level > 0, otherwise `0.0`.
Pure read — no side effects.

### tick_shard_generator(delta: float, rates: Array) -> int

Called every `_process()` frame.

```
1. if shard_generator_level == 0: return 0
2. rate = get_shard_rate_per_hour(rates)
3. shard_accumulator += delta * rate / 3600.0
4. earned = floori(shard_accumulator)  [as int]
5. shard_accumulator -= float(earned)
6. return earned
```

Returns whole shards earned this frame (usually 0; non-zero ~every 30 min at level 1).
Caller is responsible for calling `add_shards(earned, save_manager)` if `earned > 0`.

### apply_offline_shards(now_unix: int, rates: Array, cap_seconds: int, save_manager: Node) -> int

Called once in `MetaManager._ready()`, **before** `apply_offline_gold`.

```
1. if shard_generator_level == 0: return 0
2. if gold_last_saved_timestamp == 0: return 0   # first boot; gold will init timestamp
3. elapsed = now_unix - gold_last_saved_timestamp
4. if elapsed <= 0: return 0
5. capped = mini(elapsed, cap_seconds)
6. rate = get_shard_rate_per_hour(rates)
7. earned = floori(float(capped) * rate / 3600.0)  [as int]
8. if earned > 0: add_shards(earned, save_manager)
9. return earned
```

Does NOT update `gold_last_saved_timestamp` — that is `apply_offline_gold`'s responsibility. Does NOT call `_save()` directly; `add_shards()` calls it internally if `earned > 0`.

### purchase_shard_generator(cost: int, max_levels: int, save_manager: Node) -> bool

Atomic purchase:
```
1. if shard_generator_level >= max_levels: return false
2. if not spend_gold(float(cost), save_manager): return false
3. shard_generator_level += 1
4. _save(save_manager)
5. return true
```

---

## New Methods (MetaManager autoload — thin wrappers)

### shard_generator_rate: float (computed property)

```gdscript
var shard_generator_rate: float:
    get:
        var cfg = ResourceManager.get_meta_config()
            .get("alchemy_lab", {}).get("upgrades", {}).get("shard_generator", {})
        return _impl.get_shard_rate_per_hour(cfg.get("rates_per_hour", []))
```

### get_next_shard_generator_cost() -> int

Reads `base_cost` and `cost_scale` from config. Returns `_impl.get_upgrade_cost(meta_state.shard_generator_level, base_cost, cost_scale)`, or 0 if maxed.

### purchase_shard_generator() -> bool

Reads config, delegates to `_impl.purchase_shard_generator(cost, max_levels, SaveManager)`. Emits `gold_changed` and `shards_changed` on success.

---

## MetaManager._ready() call order (modified)

```
_impl.load(SaveManager)
_impl.apply_offline_shards(now, shard_rates, cap_seconds, SaveManager)  ← NEW (before gold)
_impl.apply_offline_gold(now, gold_rate, cap_seconds, SaveManager)
```

Shard offline credit must precede gold offline credit because `apply_offline_gold` updates `gold_last_saved_timestamp` via `_save()`.

## MetaManager._process() additions

```gdscript
var shard_cfg = ...  # read once per tick or cache
var earned: int = _impl.tick_shard_generator(delta, shard_rates)
if earned > 0:
    _impl.add_shards(earned, SaveManager)
    shards_changed.emit(meta_state.total_shards)
```

---

## LabUpgradeScreen (modified)

New export: `@export var _shard_gen_button: Button`

New call in `_update_buttons()`: `_update_shard_gen_button()`

### _update_shard_gen_button()

```
1. Read cfg from ResourceManager
2. level = MetaManager.meta_state.shard_generator_level
3. if level >= max_levels:
       button.text = "{name} — MAX"
       button.disabled = true
       return
4. cost = get_next_shard_generator_cost()
5. rate = rates_per_hour[level]  (next rate)
6. button.text = "{name} {rate}/hr (Lv{level+1}) — {cost} gold"
7. button.disabled = not MetaManager.can_spend_gold(float(cost))
```

New handler: `_on_shard_gen_pressed()` → `MetaManager.purchase_shard_generator(); _update_buttons()`

Connected in `_ready()`: `_shard_gen_button.pressed.connect(_on_shard_gen_pressed)`

---

## SaveManager (modified)

`save_meta_state` adds two keys:
```json
"shard_generator_level": state.shard_generator_level,
"shard_accumulator": state.shard_accumulator
```

`load_meta_state` adds two reads:
```gdscript
state.shard_generator_level = int(parsed.get("shard_generator_level", 0))
state.shard_accumulator = float(parsed.get("shard_accumulator", 0.0))
```
