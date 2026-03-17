# Implementation Plan: Gold-Purchased Essence Gain Upgrade

**Branch**: `044-gold-essence-upgrade` | **Date**: 2026-03-16 | **Spec**: [spec.md](spec.md)

## Summary

Activates the stubbed Essence Gain upgrade in the Alchemy Lab: assigns a gold cost per level (50/100/150/200/250), expands to 5 levels, changes the multiplier formula from additive to compounding (pow), and adds a gold-spending API. The essence multiplier hook in RunManager already exists — only the formula and UI wiring change.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: MetaManager, MetaManagerImpl, MetaState, LabUpgradeScreen, RunManager (read-only)
**Storage**: `user://meta_save.json` (existing), `data/meta_config.json` (existing)
**Testing**: Manual in-editor; GUT unit tests for multiplier formula and spend_gold guard
**Target Platform**: Android mobile (portrait 1080×1920); Windows dev
**Project Type**: Single Godot project
**Performance Goals**: 60 fps sustained; this feature has no per-frame cost (gold_changed signal already ticks)
**Constraints**: No new scenes; no new autoloads; no raw `.tscn` edits
**Scale/Scope**: 4 files modified, 0 files created

## Constitution Check

- **I. Single Responsibility** ✅ — New `spend_gold` / `purchase_essence_gain` logic goes in `MetaManagerImpl`. `MetaManager` autoload remains a thin wrapper. `LabUpgradeScreen` owns only UI state. No responsibility mixing.
- **II. Data-Driven Content** ✅ — All costs (`[50,100,150,200,250]`), `max_levels`, and `essence_per_level` live in `data/meta_config.json`. No numeric constants in GDScript.
- **III. Mobile-First** ✅ — No new draw calls, shaders, or physics. `gold_changed` signal already emitted per-tick; subscribing from one more screen has negligible cost.
- **IV. Editor-Centric** ✅ — No `.tscn` edits. All child-node references in `LabUpgradeScreen` already use `@export var`. No new nodes.
- **V. Simplicity & YAGNI** ✅ — No new abstractions. Flat cost array is the simplest data structure that satisfies the exact linear cost schedule. `spend_gold` is the minimum API needed.
- **VI. Early Return** ✅ — All new methods (`spend_gold`, `purchase_essence_gain`) use guard clauses at the top, happy path last.

## Project Structure

### Documentation (this feature)

```text
specs/044-gold-essence-upgrade/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (files changed)

```text
data/
└── meta_config.json                          # Update essence_gain section

scripts/
└── managers/
    └── MetaManagerImpl.gd                   # Fix multiplier; add spend_gold, purchase_essence_gain

autoload/
└── MetaManager.gd                           # Expose can_spend_gold, spend_gold, get_next_essence_gain_cost, purchase_essence_gain

scenes/
└── hub/
    └── LabUpgradeScreen.gd                  # Update essence button: gold cost, gold_changed signal
```

**Structure Decision**: Single Godot project. No new files. Four existing files modified.

## Implementation Details

### Step 1 — data/meta_config.json

In `alchemy_lab.upgrades.essence_gain`, replace:
```json
"base_cost": 0,
"max_levels": 1,
```
With:
```json
"costs": [50, 100, 150, 200, 250],
"max_levels": 5,
```
Keep `essence_per_level: 0.05` unchanged.

### Step 2 — MetaManagerImpl.gd

**Fix multiplier** (change additive → compounding):
```gdscript
func get_essence_gain_multiplier(essence_per_level: float) -> float:
    return pow(1.0 + essence_per_level, meta_state.essence_gain_level)
```

**Add gold spending API**:
```gdscript
func can_spend_gold(cost: float) -> bool:
    return cost >= 0.0 and meta_state.total_gold >= cost

func spend_gold(cost: float, save_manager: Node) -> bool:
    if not can_spend_gold(cost):
        return false
    meta_state.total_gold -= cost
    _save(save_manager)
    return true

func purchase_essence_gain(costs: Array, max_levels: int, save_manager: Node) -> bool:
    if meta_state.essence_gain_level >= max_levels:
        return false
    var cost: float = float(costs[meta_state.essence_gain_level])
    if not spend_gold(cost, save_manager):
        return false
    meta_state.essence_gain_level += 1
    _save(save_manager)
    return true
```

### Step 3 — MetaManager.gd (autoload)

Add thin-wrapper methods:
```gdscript
func can_spend_gold(cost: float) -> bool:
    return _impl.can_spend_gold(cost)

func spend_gold(cost: float) -> bool:
    if not _impl.spend_gold(cost, SaveManager):
        return false
    gold_changed.emit(floori(meta_state.total_gold))
    return true

func get_next_essence_gain_cost() -> int:
    var costs: Array = ResourceManager.get_meta_config()\
        .get("alchemy_lab", {}).get("upgrades", {})\
        .get("essence_gain", {}).get("costs", [])
    var level: int = meta_state.essence_gain_level
    if level >= costs.size():
        return 0
    return costs[level]

func purchase_essence_gain() -> bool:
    var upgrade: Dictionary = ResourceManager.get_meta_config()\
        .get("alchemy_lab", {}).get("upgrades", {}).get("essence_gain", {})
    var costs: Array = upgrade.get("costs", [])
    var max_levels: int = upgrade.get("max_levels", 5)
    if not _impl.purchase_essence_gain(costs, max_levels, SaveManager):
        return false
    gold_changed.emit(floori(meta_state.total_gold))
    return true
```

### Step 4 — LabUpgradeScreen.gd

**In `_ready()`**: add signal connection:
```gdscript
MetaManager.gold_changed.connect(func(_n: int) -> void: _update_buttons())
```

**Replace `_update_essence_button()`**:
```gdscript
func _update_essence_button() -> void:
    var upgrade: Dictionary = ResourceManager.get_meta_config()\
        .get("alchemy_lab", {}).get("upgrades", {}).get("essence_gain", {})
    var costs: Array = upgrade.get("costs", [])
    var max_levels: int = upgrade.get("max_levels", 5)
    var essence_per_level: float = upgrade.get("essence_per_level", 0.05)
    var level: int = MetaManager.meta_state.essence_gain_level
    if level >= max_levels or costs.is_empty():
        _essence_button.text = "Essence Gain — MAX"
        _essence_button.disabled = true
        return
    var cost: int = costs[level]
    var pct: int = roundi(pow(1.0 + essence_per_level, level + 1) * 100.0) - 100
    _essence_button.text = "Essence Gain +{pct}% (Lv{lv}) — {cost} gold".format(
        {"pct": pct, "lv": level + 1, "cost": cost})
    _essence_button.disabled = not MetaManager.can_spend_gold(float(cost))
```

**Wire button** (connect `_essence_button.pressed` if not already connected):
```gdscript
_essence_button.pressed.connect(_on_essence_pressed)

func _on_essence_pressed() -> void:
    MetaManager.purchase_essence_gain()
    _update_buttons()
```

> Note: if the button was previously connected to a no-op handler (disabled sentinel), replace that connection.
