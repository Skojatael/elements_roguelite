# Implementation Plan: Depth Scaling Gate

**Branch**: `085-depth-scaling-gate` | **Date**: 2026-03-28 | **Spec**: [spec.md](spec.md)

## Summary

Gate both the depth-based difficulty multiplier and the depth-based essence formula behind a new Mage Tower upgrade (`depth_scaling_unlocked`). Without it the difficulty multiplier is always 1.0 and essence uses depth 1 (no scaling). With it the pre-existing formulas apply unchanged. The upgrade costs 300 shards (data-driven) and is added as a fourth entry in MageTowerUpgradeScreen.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Storage**: `user://meta_save.json` (existing MetaState persistence)
**Testing**: GUT unit tests
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: No runtime cost — gate is a single boolean read at run-start (dungeon generation) and per-kill (essence calc)
**Constraints**: No new autoloads; no new scene types; flag must survive game restart

## Constitution Check

- **I. Single Responsibility**: No new autoloads. MetaManagerImpl gains one purchase method. DungeonGenerator and RunManager each gain one boolean guard. All within their existing domains. ✅
- **II. Data-Driven Content**: Cost and display name stored in `meta_config.json` under `mage_tower.upgrades.depth_scaling`. No hard-coded cost in scripts. ✅
- **III. Mobile-First**: Boolean flag read is zero-cost. ✅
- **IV. Editor-Centric**: New Button node in `MageTowerUpgradeScreen.tscn` added via Godot Editor. `@export var _ds_button: Button` used for the reference. ✅
- **V. Simplicity & YAGNI**: Minimal change — one flag, one purchase method, two one-line guards, one new button. No new abstractions. ✅
- **VI. Early Return**: Existing guard clause patterns in purchase methods followed exactly. ✅

No constitution violations.

## Decisions

**D-001 — Where to check the flag for difficulty_mult**: In `DungeonGenerator._record_room()` at layout-generation time (run start). Rooms are generated once per run; the multiplier is baked into `rooms_by_id` and consumed by `RoomSpawner` at spawn time. A run-start check is sufficient because upgrades can only be purchased in the hub (between runs), making mid-run purchase impossible in practice.

**D-002 — Where to check the flag for essence**: In `RunManager._on_enemy_defeated()`, resolve an effective depth variable: if the flag is off, use depth 1 (yielding a multiplier of 1.0); if on, use `current_room_depth` as today. This is a minimal, local change to one formula line.

**D-003 — MageTowerUpgradeScreen pattern**: Follow the existing `_entries` array pattern exactly. Add one more entry dict keyed `"depth_scaling"` from the JSON config, merged with `button: _ds_button`, `owned_prop: "is_depth_scaling_unlocked"`, and `purchase: MetaManager.purchase_depth_scaling`. No gating condition (`gate_prop` omitted — upgrade is always visible once the tower is unlocked).

## Schema Changes

**SC-001 — `data/meta_config.json`**: Add `"depth_scaling": { "name": "Depth Scaling", "cost": 300 }` inside `mage_tower.upgrades`.

**SC-002 — `scripts/data_models/MetaState.gd`**: Add `var depth_scaling_unlocked: bool = false`.

**SC-003 — `scripts/managers/SaveManager.gd`**: Add `"depth_scaling_unlocked"` key to the save dict and a matching load line with `bool(...get("depth_scaling_unlocked", false))`.

## Affected Files

**`data/meta_config.json`** — Add the `depth_scaling` entry (name + cost 300) inside `mage_tower.upgrades`. Insertion point: after the `boss_challenge` entry on approximately line 41.

**`scripts/data_models/MetaState.gd`** — Append `var depth_scaling_unlocked: bool = false` as the last field. Currently 26 lines; append at line 27.

**`scripts/managers/SaveManager.gd` (SaveManagerImpl)** — Add `"depth_scaling_unlocked": state.depth_scaling_unlocked` to the save dictionary and `state.depth_scaling_unlocked = bool(parsed.get("depth_scaling_unlocked", false))` in the load block. Save dict currently at lines 8–31; load block at lines 50–72.

**`scripts/managers/MetaManager.gd` (MetaManagerImpl)** — Add `purchase_depth_scaling(cost: int, save_manager: Node) -> bool`. Follows the same guard-clause pattern as the other boolean-flag purchase methods (`purchase_adventuring_gear`, `purchase_mage_tower_relic_system`, etc.): return false if already owned or can't spend; otherwise deduct shards and save.

**`autoload/MetaManager.gd`** — Add computed property `var is_depth_scaling_unlocked: bool` (getter delegates to `_impl.meta_state.depth_scaling_unlocked`). Add delegating method `purchase_depth_scaling() -> bool` that reads the cost from `meta_config.json` under `mage_tower.upgrades.depth_scaling.cost` (default 300), calls `_impl.purchase_depth_scaling(cost, SaveManager)`, and emits `shards_changed` on success.

**`scripts/dungeon/DungeonGenerator.gd`** — In `_record_room()`, replace the `difficulty_mult` computation line with a guard: if `MetaManager.is_depth_scaling_unlocked` is true, use `1.0 + difficulty_scale * float(depth)`; otherwise set it to `1.0`. This is a single-line change at approximately line 78.

**`scripts/managers/RunManager.gd`** — In `_on_enemy_defeated()`, introduce a local `effective_depth: int` variable before the essence formula: it is `current_room_depth` when `MetaManager.is_depth_scaling_unlocked` is true, or `1` otherwise. Substitute `effective_depth` for `current_room_depth - 1` in the existing formula. Approximately lines 149–158; single additional line before the formula.

**`scenes/hub/MageTowerUpgradeScreen.gd`** — Add `@export var _ds_button: Button`. In `_ready()`, append a fourth entry to `_entries` using `upgrades.get("depth_scaling", {})` merged with `button: _ds_button`, `owned_prop: "is_depth_scaling_unlocked"`, `purchase: MetaManager.purchase_depth_scaling`. No other changes required — `_update_entries()` and `_apply_entry()` handle the new entry automatically.

**`scenes/hub/MageTowerUpgradeScreen.tscn`** *(Editor task)* — Add a fourth `Button` child node (name `DepthScalingButton`) in the Godot Editor. Assign it to the `_ds_button` export on `MageTowerUpgradeScreen` via the Inspector.

**`tests/unit/test_depth_scaling_gate.gd`** *(new file)* — GUT unit tests covering: (a) essence formula with flag off returns base value at depth 4; (b) essence formula with flag on returns scaled value at depth 4; (c) `DungeonGenerator._record_room` produces `difficulty_mult = 1.0` with flag off; (d) `difficulty_mult > 1.0` at depth > 0 with flag on; (e) `purchase_depth_scaling` deducts shards and sets flag; (f) double-purchase returns false.
