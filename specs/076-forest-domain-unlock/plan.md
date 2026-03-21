# Implementation Plan: Forest Domain Unlock

**Branch**: `076-forest-domain-unlock` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/076-forest-domain-unlock/spec.md`

## Summary

Adds a one-time purchasable upgrade inside the Book of Skill that gates the forest relic domain. When not owned, forest relics are excluded from the pool at run start. The upgrade costs 40 shards (config-driven) and its state persists in MetaState.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `MetaState`, `MetaManagerImpl`, `RelicManagerImpl`, `SaveManagerImpl`, `BookOfSkillInterior`, `meta_config.json`
**Storage**: `user://meta_save.json` (existing)
**Testing**: GUT unit tests (existing framework)
**Target Platform**: Android mobile, portrait 1080×1920
**Performance Goals**: 60 fps; no new per-frame cost
**Constraints**: Mobile renderer; all values in JSON
**Scale/Scope**: Single new bool field; single new UI button

## Constitution Check

- **I. Single Responsibility** ✅ — `MetaManagerImpl` adds one purchase method following the exact same pattern as the 10+ existing purchases. `RelicManagerImpl.build_pool` receives domain unlock state as a parameter — no autoload call inside the impl. `BookOfSkillInterior` owns the upgrade UI.
- **II. Data-Driven Content** ✅ — Cost lives under `book_of_skill.upgrades.forest_domain.cost` in `data/meta_config.json`. No numeric literal in logic.
- **III. Mobile-First** ✅ — Zero per-frame cost. One bool check at run start during `build_pool`.
- **IV. Editor-Centric** ✅ — `BookOfSkillInterior.tscn` updated in the Godot Editor to add button and label nodes; references via `@export var`.
- **V. Simplicity & YAGNI** ✅ — `build_pool` receives `forest_domain_unlocked: bool` rather than a generic domain registry. Only forest is gated today; other domains added when needed.
- **VI. Early Return** ✅ — Domain loop gains a single guard `if domain_str == "forest" and not forest_domain_unlocked: continue`. No nesting added.

## Decisions

1. **Filter location**: Domain filtering in `RelicManagerImpl.build_pool()` via a `forest_domain_unlocked: bool` parameter. The autoload passes `MetaManager.is_forest_domain_unlocked`. This keeps `RelicManagerImpl` autoload-free and fully testable.
2. **`build_pool` signature change**: One new parameter rather than a generic domain registry (YAGNI). Future domains follow the same pattern — add a bool, guard the loop key.
3. **UI pattern**: `BookOfSkillInterior` follows the `MageTowerUpgradeScreen` pattern — exports a `Button` and a `Label`, connects `MetaManager.shards_changed` to `_update_ui()`, disables the button when insufficient shards or already owned.

## Schema Changes

**`data/meta_config.json`** — add `upgrades` block under `book_of_skill`:
```
book_of_skill.upgrades.forest_domain.name = "Forest Domain"
book_of_skill.upgrades.forest_domain.cost = 40
```

**`scripts/data_models/MetaState.gd`** — one new field:
```
forest_domain_unlocked: bool = false
```

## Affected Files

### `data/meta_config.json` *(data)*
Add an `"upgrades"` key under `"book_of_skill"` containing a `"forest_domain"` entry with `"name"` and `"cost": 40`. Mirrors the Mage Tower upgrade structure.

### `scripts/data_models/MetaState.gd` *(code)*
Add `var forest_domain_unlocked: bool = false`. Defaults to `false` for backward compatibility — existing saves that lack the key will load as not unlocked.

### `scripts/managers/SaveManager.gd` *(code)*
In `save_meta_state`, add `"forest_domain_unlocked": state.forest_domain_unlocked` to the serialised dictionary. In `load_meta_state`, read `bool(parsed.get("forest_domain_unlocked", false))` into `state.forest_domain_unlocked`.

### `scripts/managers/MetaManagerImpl.gd` *(code)*
Add `purchase_forest_domain(cost: int, save_manager: Node) -> bool`. Follows the same pattern as `purchase_book_of_skill`: guard on `meta_state.forest_domain_unlocked` (return false if already owned), call `spend(cost, save_manager)`, set flag, return result.

### `autoload/MetaManager.gd` *(code)*
Add computed property `var is_forest_domain_unlocked: bool` delegating to `meta_state.forest_domain_unlocked`. Add delegating method `purchase_forest_domain() -> bool` that reads the cost from `ResourceManager.get_meta_config()` at call time and passes it to `_impl.purchase_forest_domain(cost, SaveManager)`.

### `scripts/managers/RelicManagerImpl.gd` *(code)*
Add `forest_domain_unlocked: bool` parameter to `build_pool`. Inside the domain iteration loop, add a guard `if domain_str == "forest" and not forest_domain_unlocked: continue` before processing any relics from that domain.

### `autoload/RelicManager.gd` *(code)*
In `_on_run_started()`, update the `build_pool` call to pass `MetaManager.is_forest_domain_unlocked` as the new third argument.

### `scenes/hub/BookOfSkillInterior.gd` *(code)*
Add `@export var _forest_button: Button` and `@export var _forest_label: Label`. In `_ready()`, connect `MetaManager.shards_changed` to `_update_ui()` and call `_update_ui()` immediately. `_update_ui()` reads the cost from config, sets the label text, disables the button if unaffordable or already owned (showing "Unlocked" text in the latter case). Connect the button's `pressed` signal to call `MetaManager.purchase_forest_domain()` then `_update_ui()`.

### `scenes/hub/BookOfSkillInterior.tscn` *(editor task)*
In the Godot Editor, add a `Label` node for the upgrade name/description and a `Button` node for the purchase action as children of the interior layout. Assign them to the `_forest_label` and `_forest_button` export slots on the `BookOfSkillInterior` script.
