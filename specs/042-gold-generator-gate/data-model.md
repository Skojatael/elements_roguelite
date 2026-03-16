# Data Model: Gold Generator Gate (042)

## Changed Files

### `data/meta_config.json`

Add `gold_generator` entry under `alchemy_lab.upgrades`:

```json
"alchemy_lab": {
  "name": "Alchemy Lab",
  "cost": 500,
  "upgrades": {
    "essence_gain": { ... },
    "gold_generator": {
      "name": "Transmuter",
      "cost": 50
    }
  }
}
```

Fields:
- `name` (String) — display name shown in `LabUpgradeScreen`
- `cost` (int) — shard cost for one-time purchase

---

### `scripts/data_models/MetaState.gd`

Add one field:

```gdscript
var gold_generator_owned: bool = false
```

Default `false` — safe for backward-compatible load (missing key → unpurchased).

---

### `scripts/managers/SaveManager.gd` (SaveManagerImpl)

**`save_meta_state()`** — add to the serialized Dictionary:
```gdscript
"gold_generator_owned": state.gold_generator_owned,
```

**`load_meta_state()`** — add to the deserialization block:
```gdscript
state.gold_generator_owned = bool((parsed as Dictionary).get("gold_generator_owned", false))
```

Default `false` for missing key → backward compatible with existing saves.

---

### `scripts/managers/MetaManager.gd` (MetaManagerImpl)

**`tick_gold()` — add early-return gate**:
```gdscript
func tick_gold(delta: float, rate_per_hour: float) -> int:
    if not meta_state.gold_generator_owned:
        return floori(meta_state.total_gold)
    meta_state.total_gold += delta * rate_per_hour / 3600.0
    return floori(meta_state.total_gold)
```

**`apply_offline_gold()` — add early-return gate**:
```gdscript
func apply_offline_gold(now_unix: int, rate_per_hour: float, save_manager: Node) -> void:
    if not meta_state.gold_generator_owned:
        return
    if meta_state.gold_last_saved_timestamp == 0:
        return
    ...  # rest unchanged
```

**New method `purchase_gold_generator()`**:
```gdscript
## Purchases the Transmuter (gold generator) if affordable and not already owned. Returns true on success.
func purchase_gold_generator(cost: int, save_manager: Node) -> bool:
    if meta_state.gold_generator_owned:
        return false
    if not can_spend(cost):
        return false
    meta_state.total_shards -= cost
    meta_state.gold_generator_owned = true
    _save(save_manager)
    return true
```

---

### `autoload/MetaManager.gd`

Add computed property:
```gdscript
var is_gold_generator_owned: bool:
    get: return _impl.meta_state.gold_generator_owned
```

Add purchase delegation method:
```gdscript
func purchase_gold_generator() -> bool:
    var cost: int = ResourceManager.get_meta_config().get("alchemy_lab", {}).get("upgrades", {}).get("gold_generator", {}).get("cost", 50)
    var success: bool = _impl.purchase_gold_generator(cost, SaveManager)
    if success:
        shards_changed.emit(meta_state.total_shards)
    return success
```

No changes to `_ready()` or `_process()` — the gate lives in the impl.

---

### `scenes/hub/LabUpgradeScreen.gd`

Add export:
```gdscript
@export var _transmuter_button: Button
```

Update `_ready()` to wire the new button:
```gdscript
_transmuter_button.pressed.connect(_on_transmuter_pressed)
```

Extend `_update_buttons()` to handle the Transmuter entry:
```gdscript
func _update_buttons() -> void:
    _update_essence_button()
    _update_transmuter_button()


func _update_essence_button() -> void:
    # ... existing logic extracted here unchanged ...


func _update_transmuter_button() -> void:
    var upgrade: Dictionary = ResourceManager.get_meta_config().get("alchemy_lab", {}).get("upgrades", {}).get("gold_generator", {})
    var upgrade_name: String = upgrade.get("name", "gold_generator")
    var cost: int = upgrade.get("cost", 50)
    if MetaManager.is_gold_generator_owned:
        _transmuter_button.text = "{n} — ACTIVE".format({"n": upgrade_name})
        _transmuter_button.disabled = true
        return
    _transmuter_button.text = "{n} ({cost} shards)".format({"n": upgrade_name, "cost": cost})
    _transmuter_button.disabled = not MetaManager.can_spend(cost)


func _on_transmuter_pressed() -> void:
    MetaManager.purchase_gold_generator()
    # _update_buttons() is called automatically via shards_changed signal
```

### `scenes/hub/LabUpgradeScreen.tscn` (Editor task)

Add a new `Button` node (`TransmuterButton`) as a sibling of the existing `EssenceButton`. Assign it to the `_transmuter_button` export in the Inspector.

---

## State Transitions

```
gold_generator_owned: false (default)
    → purchase_gold_generator() succeeds
gold_generator_owned: true (permanent — no revert path)
```

Once `gold_generator_owned` is `true`:
- `tick_gold()` accumulates each `_process()` frame
- `apply_offline_gold()` credits offline time on next launch
- `LabUpgradeScreen` shows "Transmuter — ACTIVE" (button disabled)
- Gold display starts incrementing visibly
