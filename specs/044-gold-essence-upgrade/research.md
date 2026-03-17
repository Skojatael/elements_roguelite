# Research: Gold-Purchased Essence Gain Upgrade

**Feature**: 044-gold-essence-upgrade
**Date**: 2026-03-16

---

## Finding 1 — MetaState field already exists

**Decision**: Use `essence_gain_level: int` (existing field in `MetaState.gd`).
**Rationale**: Feature 040 already added this field as a stub. No new field needed.
**Alternatives considered**: `essence_upgrade_level` (spec assumption) — wrong name; actual field is `essence_gain_level`.

---

## Finding 2 — Multiplier formula must be changed to compounding

**Decision**: Change `get_essence_gain_multiplier()` in `MetaManagerImpl` from additive to `pow(1.0 + essence_per_level, level)`.
**Rationale**: Current formula is `1.0 + level * per_level` (additive, yields 1.25 at level 5). User explicitly requested compounding, identical to the damage upgrade which uses `pow()`. Compounding yields ≈1.2763 at level 5 with 5% per level.
**Alternatives considered**: Leaving additive — rejected, does not match user requirement.

---

## Finding 3 — Essence multiplier is already applied in RunManager

**Decision**: No RunManager changes needed.
**Rationale**: `RunManager._on_enemy_defeated()` already multiplies by `MetaManager.essence_gain_multiplier` at the end of the formula. Fixing the multiplier formula (Finding 2) is sufficient.
**Alternatives considered**: Patching RunManager — unnecessary complexity.

---

## Finding 4 — Cost structure: linear array, not scale formula

**Decision**: Store costs as a flat array in config: `"costs": [50, 100, 150, 200, 250]`.
**Rationale**: Existing `get_upgrade_cost()` in MetaManagerImpl uses exponential `floori(cost * scale)` iteration. The user's cost schedule is linear (+50/level) and cannot be expressed cleanly with that formula. A flat array is simpler, data-driven, and directly expresses intent. `max_levels` becomes `costs.size()`.
**Alternatives considered**:
- `base_cost: 50, cost_increment: 50` with a new linear helper — adds a new code path for marginal gain.
- Keeping exponential formula with tuned scale — cannot produce exact 50/100/150/200/250 sequence.

---

## Finding 5 — Gold spending: no existing `spend_gold()` method

**Decision**: Add `spend_gold(cost: float, save_manager: Node) -> bool` to `MetaManagerImpl` and expose via `MetaManager`.
**Rationale**: `MetaManager` exposes `total_gold` (read) and `tick_gold()` / `apply_offline_gold()` (accumulation), but no deduction API exists. The Essence Gain upgrade is the first gold-spending upgrade.
**Alternatives considered**: Direct `meta_state.total_gold -= cost` in the screen script — violates thin-wrapper rule (Constitution I). Logic must stay in impl.

---

## Finding 6 — LabUpgradeScreen button uses `base_cost == 0` as disabled sentinel

**Decision**: Replace `base_cost: 0` in config with the costs array. Update `_update_essence_button()` to read `costs[level]` instead of `base_cost`. Disabled state: `level >= costs.size()` (max) or `not MetaManager.can_spend_gold(cost)` (unaffordable).
**Rationale**: The existing sentinel (`base_cost == 0 → disable`) is no longer needed — the button is now conditionally enabled based on gold balance. The UI must subscribe to `MetaManager.gold_changed` (in addition to `shards_changed`) to re-evaluate on gold tick.
**Alternatives considered**: Keeping `base_cost: 0` for other upgrades — retained; only the `essence_gain` entry is changed.

---

## Finding 7 — gold_changed signal already exists on MetaManager

**Decision**: Connect `MetaManager.gold_changed` in `LabUpgradeScreen._ready()` to trigger `_update_buttons()`.
**Rationale**: `MetaManager` already emits `gold_changed(new_floor: int)` every frame-tick when gold changes. LabUpgradeScreen needs to update the essence button's enabled/disabled state reactively. The signal exists and is the correct hook.
**Alternatives considered**: Polling gold in `_process()` — wasteful. Custom signal — redundant.

---

## Finding 8 — No new scenes required

**Decision**: All changes are script-only (config JSON + GDScript). No new `.tscn` files.
**Rationale**: The Alchemy Lab upgrade screen scene (`LabUpgradeScreen.tscn`) and its Essence Gain button already exist. The existing button node is wired up via `@export var`. Only the script logic and config change.
**Alternatives considered**: New scene — rejected (YAGNI, Constitution V).

---

## Summary of Changes Required

| Layer | File | Change |
|-------|------|--------|
| Config | `data/meta_config.json` | `essence_gain`: replace `base_cost: 0, max_levels: 1` with `costs: [50,100,150,200,250], max_levels: 5`; keep `essence_per_level: 0.05` |
| Impl | `scripts/managers/MetaManagerImpl.gd` | Fix `get_essence_gain_multiplier()` to `pow()`; add `can_spend_gold()`, `spend_gold()`, `purchase_essence_gain()` |
| Autoload | `autoload/MetaManager.gd` | Expose `can_spend_gold()`, `spend_gold()`, `purchase_essence_gain()`, `get_next_essence_gain_cost()` |
| UI | `scenes/hub/LabUpgradeScreen.gd` | Update `_update_essence_button()` for gold costs; connect `gold_changed`; wire button to `purchase_essence_gain()` |
