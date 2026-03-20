# Implementation Plan: Book of Skill

**Branch**: `071-book-of-skill` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)

## Summary

Add a new hub building "Book of Skill" that is hidden until the player kills 3 bosses. On the kill that hits that threshold a one-time popup fires (reusing `BossKillPopup`); on the next hub visit the building appears. Tapping it in "not created" state shows a shard purchase overlay (250 shards, data-driven). After purchase the building enters "created" state permanently, and tapping it opens a minimal interior screen containing only a Close button.

## Technical Context

**Language/Version**: GDScript 4.6, static typing
**Primary Dependencies**: Existing `BossKillPopup.tscn`, `MetaManagerImpl`, `SaveManagerImpl`, `MetaState`, `meta_config.json`
**Storage**: `user://meta_save.json` — two new boolean fields; `data/meta_config.json` — one new building section
**Testing**: GUT unit tests (`tests/unit/`)
**Target Platform**: Android mobile portrait; Windows dev
**Performance Goals**: 60 fps; building visibility check is a one-time read on `hub_entered` — O(1)
**Constraints**: No new autoloads; no raw `.tscn` edits; all cost/text in JSON

## Constitution Check

- **I. Single Responsibility** ✅ — `BookOfSkill.gd` owns building state display. `BookOfSkillBuyOverlay.gd` owns the purchase dialog. `BookOfSkillInterior.gd` owns the interior screen. All gate logic in `MetaManagerImpl`. Main.gd only coordinates popup sequencing.
- **II. Data-Driven Content** ✅ — Cost (250) and popup message live in `meta_config.json`. No numeric literals in `.gd` files.
- **III. Mobile-First** ✅ — Visibility check is a single property read on `hub_entered`. No per-frame work introduced.
- **IV. Editor-Centric** ✅ — All new scenes created in Godot Editor. `@export var` for all node references. No raw `.tscn` edits.
- **V. Simplicity & YAGNI** ✅ — No interior content beyond Close button; no abstraction for "hub building" (only 2 exist with slightly different state names — insufficient for a shared base class per YAGNI). Buy overlay is a new minimal scene rather than over-parameterising RestoreTowerOverlay.
- **VI. Early Return** ✅ — `record_book_of_skill_gate` returns early if already set. `purchase_book_of_skill` returns early if owned or unaffordable.

## Decisions

1. **Popup reuse**: The 3-boss kill popup reuses the existing `BossKillPopup.tscn` scene and text-from-config pattern already used for the first boss. No new scene needed.
2. **Pending flag pattern**: `_book_of_skill_popup_pending: bool` in Main.gd mirrors `_first_boss_popup_pending` exactly — checked at the top of `_show_boss_victory_overlay()` so the popup always fires before the boss victory overlay. Dismissed via `_on_book_of_skill_popup_ok()` which calls `_show_boss_victory_overlay()` again, identical to the first-boss flow.
3. **Gate flag ownership**: `MetaManager.record_book_of_skill_gate()` sets the flag and saves (delegated to `MetaManagerImpl`). Called from `Main._on_boss_room_cleared()` when `endless_boss_kill_count == 3 and not is_book_of_skill_gate_reached`. This keeps gate logic in the manager layer and Main only orchestrates the popup.
4. **Buy overlay as new scene**: `BookOfSkillBuyOverlay.gd/.tscn` is a dedicated minimal Control (not a fork of `RestoreTowerOverlay`) because the signal names and label content differ enough that reuse would require parameterisation with no second call site to justify it.

## Schema Changes

**`scripts/data_models/MetaState.gd`** — add two fields:
- `book_of_skill_gate_reached: bool = false`
- `book_of_skill_owned: bool = false`

**`scripts/managers/SaveManager.gd`** — add to the save/load dictionary:
- `"book_of_skill_gate_reached"` → `state.book_of_skill_gate_reached`
- `"book_of_skill_owned"` → `state.book_of_skill_owned`
Both use `.get("key", false)` default for backward compatibility.

**`data/meta_config.json`** — add top-level `"book_of_skill"` object:
```
"book_of_skill": {
  "cost": 250,
  "popup_message": "The ancient Book of Skill stirs... Return to the hub to claim it."
}
```
(Text is a placeholder; any string here is surfaced verbatim to the popup.)

## Affected Files

### New — Scripts & Scenes

- **`scenes/hub/BookOfSkill.gd`** (`class_name BookOfSkill extends Control`) — Hub building script. Exports: `_not_created_visual: ColorRect`, `_created_visual: ColorRect`, `_label: Label`, `_button: Button`, `_buy_overlay_scene: PackedScene`, `_interior_scene: PackedScene`. Connects `MetaManager.shards_changed` and `GlobalSignals.hub_entered` to `_update_visuals()`. Visibility gated on `MetaManager.is_book_of_skill_gate_reached`. On button press: shows buy overlay when not owned, interior screen when owned. Manages overlay via `_overlay_layer: CanvasLayer`. Follows `MageTower.gd` pattern exactly.

- **`scenes/hub/BookOfSkill.tscn`** — **[EDITOR]** New `Control` scene. Children: two `ColorRect` nodes (`NotCreatedVisual`, `CreatedVisual`) and a `Button`. Attach `BookOfSkill.gd`; assign all `@export` vars in Inspector.

- **`scenes/hub/BookOfSkillBuyOverlay.gd`** (`class_name BookOfSkillBuyOverlay extends Control`) — Purchase confirmation dialog. Exports: `_buy_button: Button`, `_cancel_button: Button`, `_cost_label: Label`. Signals: `buy_pressed`, `cancel_pressed`. On `_ready()` reads cost from `MetaManager`/config to populate label and disable buy button when unaffordable. Connects `MetaManager.shards_changed` to recheck affordability. Follows `RestoreTowerOverlay.gd` pattern.

- **`scenes/hub/BookOfSkillBuyOverlay.tscn`** — **[EDITOR]** New `Control` scene with two buttons and a cost label. Attach script; assign exports.

- **`scenes/hub/BookOfSkillInterior.gd`** (`class_name BookOfSkillInterior extends Control`) — Interior screen shell. Single export: `_close_button: Button`. Signal: `close_pressed`. On close button press, emits `close_pressed`. No other logic.

- **`scenes/hub/BookOfSkillInterior.tscn`** — **[EDITOR]** New `Control` scene with a single Close button. Attach script; assign export.

### Modified

- **`data/meta_config.json`** — Add the `"book_of_skill"` section with `cost` and `popup_message` fields.

- **`scripts/data_models/MetaState.gd`** — Add `book_of_skill_gate_reached: bool = false` and `book_of_skill_owned: bool = false`.

- **`scripts/managers/SaveManager.gd`** — Add both new fields to the save dictionary in `save_meta_state()` and to the `load_meta_state()` dictionary read (with `false` defaults).

- **`scripts/managers/MetaManager.gd`** (`MetaManagerImpl`) — Add `record_book_of_skill_gate(save_manager) -> bool`: sets `book_of_skill_gate_reached = true` if not already set and saves; returns true if state changed. Add `purchase_book_of_skill(cost, save_manager) -> bool`: standard idempotent purchase guard (owned / can_spend), deducts shards, sets `book_of_skill_owned = true`, saves.

- **`autoload/MetaManager.gd`** — Add computed properties `is_book_of_skill_gate_reached` and `is_book_of_skill_owned` (read-through to `_impl.meta_state`). Add delegating methods `record_book_of_skill_gate() -> bool` and `purchase_book_of_skill() -> bool` (reads cost from `meta_config.json`, delegates to impl, emits `shards_changed` on purchase success).

- **`scenes/core/Main.gd`** — Add `var _book_of_skill_popup_pending: bool = false`. In `_on_boss_room_cleared()`, after the existing count==1 check, add: if count==3 and not `MetaManager.is_book_of_skill_gate_reached`, call `MetaManager.record_book_of_skill_gate()` and set `_book_of_skill_popup_pending = true`. In `_show_boss_victory_overlay()`, add a guard for `_book_of_skill_popup_pending` immediately after the first-boss-popup guard: clear flag, call `_show_book_of_skill_popup()`, return. Add `_show_book_of_skill_popup()`: reads message from config, instantiates `BossKillPopup` inside a new `CanvasLayer` (reusing `_boss_kill_popup_layer`), calls `setup(message)`, connects `ok_pressed` to `_on_book_of_skill_popup_ok()`. Add `_on_book_of_skill_popup_ok()`: frees `_boss_kill_popup_layer`, calls `_show_boss_victory_overlay()`.

- **`scenes/hub/HubRoom.tscn`** — **[EDITOR]** Add `BookOfSkill.tscn` as a child node; position it in the hub. Assign `_buy_overlay_scene` and `_interior_scene` exports in Inspector.
