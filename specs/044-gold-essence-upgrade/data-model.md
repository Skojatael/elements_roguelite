# Data Model: Gold-Purchased Essence Gain Upgrade

**Feature**: 044-gold-essence-upgrade
**Date**: 2026-03-16

---

## Entities

### MetaState (modified)

`scripts/data_models/MetaState.gd` — no new fields. Existing field `essence_gain_level: int = 0` is the sole write target.

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `essence_gain_level` | `int` | `0` | Already exists. Range: 0–5 (enforced by `max_levels = costs.size()`). |
| `total_gold` | `float` | `0.0` | Already exists. Decremented on purchase. |

**State transitions**:
- `essence_gain_level` increments by 1 per purchase; never decremented. Capped at `costs.size()` (5).
- `total_gold` decremented by `costs[essence_gain_level]` at time of purchase.

**Persistence**: Both fields already serialised in `user://meta_save.json`. No schema change required.

---

## Config Schema (meta_config.json — modified section)

`data/meta_config.json` — `alchemy_lab.upgrades.essence_gain` section updated:

```json
"essence_gain": {
  "name": "Essence Gain",
  "costs": [50, 100, 150, 200, 250],
  "max_levels": 5,
  "essence_per_level": 0.05
}
```

**Removed keys**: `base_cost: 0` (was disabled sentinel).
**Added key**: `costs` — Array of gold costs, one per level (index 0 = cost for level 1).
**Changed**: `max_levels` 1 → 5.
**Unchanged**: `essence_per_level: 0.05`.

**Invariant**: `costs.size() == max_levels` must hold. Violation → button remains disabled (safe degradation).

---

## Computed Properties

### MetaManager.essence_gain_multiplier (formula change)

Old formula (additive): `1.0 + essence_gain_level * essence_per_level`
New formula (compounding): `pow(1.0 + essence_per_level, essence_gain_level)`

| Level | Old multiplier | New multiplier |
|-------|---------------|---------------|
| 0 | 1.0000 | 1.0000 |
| 1 | 1.0500 | 1.0500 |
| 2 | 1.1000 | 1.1025 |
| 3 | 1.1500 | 1.1576 |
| 4 | 1.2000 | 1.2155 |
| 5 | 1.2500 | 1.2763 |

### MetaManager.get_next_essence_gain_cost() → int

Returns `costs[essence_gain_level]` from config, or `0` if at max level.
Used by UI to display cost and check affordability.

---

## New Methods (MetaManagerImpl)

### can_spend_gold(cost: float) -> bool

Pure affordability check. `cost >= 0.0 and meta_state.total_gold >= cost`. No side effects.

### spend_gold(cost: float, save_manager: Node) -> bool

Deducts `cost` from `total_gold` if affordable. Saves. Returns `true` on success.
Guard: `if cost < 0.0 or meta_state.total_gold < cost: return false`.

### purchase_essence_gain(costs: Array, max_levels: int, save_manager: Node) -> bool

Atomic purchase:
1. `if essence_gain_level >= max_levels: return false`
2. `var cost: float = float(costs[essence_gain_level])`
3. `if not spend_gold(cost, save_manager): return false`
4. `essence_gain_level += 1`
5. `_save(save_manager)`
6. `return true`

---

## New Methods (MetaManager autoload — thin wrappers)

### can_spend_gold(cost: float) -> bool

Delegates to `_impl.can_spend_gold(cost)`.

### spend_gold(cost: float) -> bool

Delegates to `_impl.spend_gold(cost, SaveManager)`. Emits `gold_changed(floori(meta_state.total_gold))` on success.

### get_next_essence_gain_cost() -> int

Reads `alchemy_lab.upgrades.essence_gain.costs` array from config. Returns `costs[essence_gain_level]` or `0` if maxed.

### purchase_essence_gain() -> bool

Reads config costs and max_levels. Delegates to `_impl.purchase_essence_gain(costs, max_levels, SaveManager)`. Emits `gold_changed` on success.

---

## Affected Formula (RunManager — no code change)

`_on_enemy_defeated()` already applies `MetaManager.essence_gain_multiplier` multiplicatively:

```
essence = floori(base_essence × (1 + depth_scale × (depth − 1)) × room_mult × essence_gain_multiplier)
```

Fixing the multiplier formula (compounding) is sufficient. No RunManager edit needed.
