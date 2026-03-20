# Research: Magic Forge — Missile Extra Charge Upgrade

## How Magic Missile charges work

`SkillComponent.gd` loads `max_charges` from `data/skills.json` (currently `3`) inside `_load_skill_data()`, which is called in `_ready()`. The method ends with `_current_charges = _max_charges`. On each `run_started` the `_reset_charges()` method resets `_current_charges` to `_max_charges`. Charges are consumed on skill fire and restored one-at-a-time via `_on_melee_hit_landed()`.

**Decision**: Apply the meta bonus inside `_load_skill_data()` immediately after reading `_max_charges` from JSON, so the bump is reflected in `_current_charges = _max_charges` at the bottom of that same method. This is the single natural write point for max-charge state and requires no new hook or signal.

## How the Magic Forge upgrade screen works

`ForgeUpgradeScreen.gd` exports one `Button` (`_damage_button`). `_update_buttons()` sets button text and disabled state based on `MetaManager.damage_upgrade_level` and cost. A new `_missile_charge_button: Button` follows the identical pattern for a one-time (boolean) upgrade.

**Decision**: Add one `@export var _missile_charge_button: Button` to `ForgeUpgradeScreen.gd`, with a matching node in the scene (Editor task). Text = `"{name} — {cost} shards"` when unpurchased / affordable, `"{name} (insufficient shards)"` when can't afford, `"Purchased"` when owned. Button disabled after purchase.

## MetaState pattern for boolean upgrades

All one-time purchases (e.g., `adventuring_gear_owned`, `boss_run_unlocked`) are `bool` fields on `MetaState`. They are saved/loaded in `SaveManagerImpl` via `.get(key, false)`. The purchase method in `MetaManagerImpl` follows an early-return guard pattern.

**Decision**: Add `missile_extra_charge_owned: bool = false` to `MetaState`. Follow the identical save/load and purchase pattern used by every other boolean unlock.

## meta_config.json structure

The forge section uses nested structure: `magic_forge.upgrades.<key>.name` and `.cost`. The new key will be `missile_charge_upgrade` with `name: "Arcane Reservoir"` and `cost: 150`.

**Decision**: Add under `magic_forge.upgrades`:
```json
"missile_charge_upgrade": {
  "name": "Arcane Reservoir",
  "cost": 150
}
```

## No contracts/ needed

This is a pure in-game Godot feature with no REST API or external service boundary. The "contracts" between systems are GDScript signals and method calls covered in data-model.md.

## Interaction with existing relics

No relic currently modifies `_max_charges`. The upgrade sets `_max_charges += 1` in `_load_skill_data()` before `_current_charges = _max_charges`. Any future charge-granting relic would modify `_max_charges` after skill init, so additive stacking is guaranteed by ordering.
