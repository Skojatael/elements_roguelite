# Data Model: Magic Forge — Missile Extra Charge Upgrade

## MetaState (extended)

**File**: `scripts/data_models/MetaState.gd`

New field added to existing `MetaState` class:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `missile_extra_charge_owned` | `bool` | `false` | Whether the Arcane Reservoir Forge upgrade has been purchased. Permanent; survives all sessions. |

All other MetaState fields are unchanged.

---

## JSON Config: meta_config.json (extended)

New entry under `magic_forge.upgrades`:

```json
"missile_charge_upgrade": {
  "name": "Arcane Reservoir",
  "cost": 150
}
```

Full forge upgrades block after change:
```json
"magic_forge": {
  "name": "Magic Forge",
  "cost": 120,
  "upgrades": {
    "damage_upgrade": { ... },
    "missile_charge_upgrade": {
      "name": "Arcane Reservoir",
      "cost": 150
    }
  }
}
```

---

## Save/Load: SaveManagerImpl (extended)

The save dictionary gains one key:

| JSON Key | MetaState Field | Type | Default on missing |
|----------|-----------------|------|--------------------|
| `"missile_extra_charge_owned"` | `missile_extra_charge_owned` | `bool` | `false` |

---

## Computed Value: Magic Missile max charges

**Computed in**: `SkillComponent._load_skill_data()` (called once in `_ready()`)

```
_max_charges = skills.json["max_charges"]   # currently 3
if MetaManager.is_missile_extra_charge_owned:
    _max_charges += 1                        # → 4 when owned
_current_charges = _max_charges             # existing line, unchanged
```

No new field; `_max_charges` is the single source of truth inside `SkillComponent`.

---

## Public API additions

### MetaManager (autoload) — new members

| Kind | Signature | Behaviour |
|------|-----------|-----------|
| Computed property | `var is_missile_extra_charge_owned: bool` | Delegates to `_impl.meta_state.missile_extra_charge_owned` |
| Method | `purchase_missile_extra_charge() -> bool` | Delegates to `_impl.purchase_missile_extra_charge(cost, SaveManager)`; emits `shards_changed` on success |

### MetaManagerImpl — new method

```gdscript
func purchase_missile_extra_charge(cost: int, save_manager: Node) -> bool:
    if meta_state.missile_extra_charge_owned:
        return false
    if not can_spend(cost):
        return false
    meta_state.total_shards -= cost
    meta_state.missile_extra_charge_owned = true
    _save(save_manager)
    return true
```

### ForgeUpgradeScreen — new export

```gdscript
@export var _missile_charge_button: Button
```

Button text/state logic (inside `_update_buttons()`):

| Condition | Button text | Disabled |
|-----------|-------------|----------|
| Already owned | `"Arcane Reservoir — Purchased"` | `true` |
| Can afford | `"Arcane Reservoir — 150 shards"` | `false` |
| Cannot afford | `"Arcane Reservoir — 150 shards (insufficient)"` | `true` |
