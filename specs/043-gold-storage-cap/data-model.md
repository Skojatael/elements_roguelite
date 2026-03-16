# Data Model: Gold Offline Storage Cap (043)

## Changed Files

### `data/meta_config.json` — Config schema addition

Add `gold_storage_cap` entry under `alchemy_lab.upgrades`:

```json
"alchemy_lab": {
  "name": "Alchemy Lab",
  "cost": 500,
  "upgrades": {
    "essence_gain": { ... },
    "gold_generator": { ... },
    "gold_storage_cap": {
      "name": "Gold Storage",
      "base_hours": 4,
      "hours_per_level": 4,
      "base_cost": 100,
      "cost_scale": 1.5,
      "max_levels": 2
    }
  }
}
```

| Field | Type | Description |
|---|---|---|
| `name` | string | Display name shown in upgrade UI |
| `base_hours` | int | Storage cap at level 0 (default: 4) |
| `hours_per_level` | int | Hours added per upgrade level (default: 4) |
| `base_cost` | int | Shard cost for level 1 purchase |
| `cost_scale` | float | Multiplier applied to cost at each subsequent level |
| `max_levels` | int | Maximum number of purchasable upgrade levels (default: 2) |

**Cap table** (defaults):
| Level | Cap | Cost to reach this level |
|---|---|---|
| 0 | 4h | free |
| 1 | 8h | 100 shards |
| 2 | 12h | 150 shards |

---

### `scripts/data_models/MetaState.gd` — New field

Add after `gold_generator_owned`:

```gdscript
var gold_storage_cap_level: int = 0
```

| Field | Type | Default | Description |
|---|---|---|---|
| `gold_storage_cap_level` | int | 0 | Player's current storage cap upgrade level |

---

### `scripts/managers/SaveManager.gd` — Persistence

Add to `save_meta_state()` dict:
```gdscript
"gold_storage_cap_level": state.gold_storage_cap_level,
```

Add to `load_meta_state()` deserialization:
```gdscript
state.gold_storage_cap_level = int((parsed as Dictionary).get("gold_storage_cap_level", 0))
```

---

### `scripts/managers/MetaManager.gd` (MetaManagerImpl) — Logic changes

#### Modified: `apply_offline_gold()`

New signature:
```gdscript
func apply_offline_gold(now_unix: int, rate_per_hour: float, cap_seconds: int, save_manager: Node) -> void:
```

New behaviour:
1. Guard: `if not meta_state.gold_generator_owned: return` (unchanged)
2. First-boot: `if meta_state.gold_last_saved_timestamp == 0:` → set timestamp to now_unix, save, return (no gold credit on first boot)
3. `elapsed = now_unix - meta_state.gold_last_saved_timestamp`
4. Guard: `if elapsed <= 0: return` (clock rollback — no timestamp update)
5. `capped_elapsed = mini(elapsed, cap_seconds)` ← **new**
6. `meta_state.total_gold += float(capped_elapsed) * rate_per_hour / 3600.0`
7. `meta_state.gold_last_saved_timestamp = now_unix` ← **now implemented**
8. `_save(save_manager)`

#### New: `get_gold_storage_cap_seconds(base_hours: int, hours_per_level: int) -> int`

```gdscript
func get_gold_storage_cap_seconds(base_hours: int, hours_per_level: int) -> int:
    return (base_hours + hours_per_level * meta_state.gold_storage_cap_level) * 3600
```

#### New: `purchase_gold_storage_cap(cost: int, max_levels: int, save_manager: Node) -> bool`

Pattern identical to `purchase_damage_upgrade()`:
1. If `meta_state.gold_storage_cap_level >= max_levels: return false`
2. If `not can_spend(cost): return false`
3. Deduct shards, increment level, save, return true

---

### `autoload/MetaManager.gd` — Thin-wrapper additions

#### New computed property: `gold_storage_cap_hours: int`

```gdscript
var gold_storage_cap_hours: int:
    get:
        var cfg := _storage_cap_cfg()
        return cfg.get("base_hours", 4) + cfg.get("hours_per_level", 4) * meta_state.gold_storage_cap_level
```

(Where `_storage_cap_cfg()` is a private helper returning the config dict for `alchemy_lab.upgrades.gold_storage_cap`.)

#### New method: `purchase_gold_storage_cap() -> bool`

Reads `base_cost`, `cost_scale`, `max_levels` from config. Calls `_impl.get_upgrade_cost(level, base_cost, cost_scale)` for current level's cost. Delegates to `_impl.purchase_gold_storage_cap(cost, max_levels, SaveManager)`. Emits `shards_changed` on success.

#### Modified: `_ready()` call to `apply_offline_gold()`

Reads cap config and passes computed `cap_seconds`:
```gdscript
var cap_cfg := ...  # read gold_storage_cap config
var cap_seconds: int = _impl.get_gold_storage_cap_seconds(cap_cfg.get("base_hours", 4), cap_cfg.get("hours_per_level", 4))
_impl.apply_offline_gold(int(Time.get_unix_time_from_system()), rate, cap_seconds, SaveManager)
```

---

### `scenes/hub/LabUpgradeScreen.gd` — New upgrade button

Add:
- `@export var _storage_cap_button: Button`
- Wire in `_ready()`
- New method `_update_storage_cap_button()` called from `_update_buttons()` coordinator
- New method `_on_storage_cap_pressed()` calling `MetaManager.purchase_gold_storage_cap()`

Button text logic:
- At max level: `"{name} — MAX"` (disabled)
- Otherwise: `"{name} {current_h}h → {next_h}h ({cost} shards)"` (enabled/disabled by affordability)

#### Editor task: `scenes/hub/LabUpgradeScreen.tscn`

Add a `Button` node named `StorageCapButton` as sibling of `TransmuterButton`. Assign to `_storage_cap_button` export in Inspector.

---

### `scenes/hub/GoldDisplay.gd` — Show cap

Add:
- `@export var _cap_label: Label`
- In `_ready()`: set initial cap label text; connect `MetaManager.shards_changed` → `_update_cap_label()`
- `_update_cap_label()`: if `MetaManager.is_gold_generator_owned` → show `"Cap: {n}h".format({"n": MetaManager.gold_storage_cap_hours})`; else hide cap label

#### Editor task: `scenes/hub/GoldDisplay.tscn`

Add a `Label` node named `CapLabel` as child of GoldDisplay. Assign to `_cap_label` export in Inspector.

---

## Field: `gold_storage_cap_level`

| Property | Value |
|---|---|
| Type | `int` |
| Default | 0 |
| Min | 0 |
| Max | `max_levels` from config (default 2) |
| Persisted | Yes |
| Invariant | Always ≥ 0; never exceeds max_levels |
