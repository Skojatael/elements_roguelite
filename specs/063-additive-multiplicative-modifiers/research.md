# Research: Additive-Multiplicative Modifier Stacking (063)

## Current Modifier System — Findings

### Two existing stacking paths

`RelicManagerImpl` already exposes two distinct computation functions:

| Function | Logic | Return when two ×1.10 relics active |
|---|---|---|
| `compute_stat_mult(stat)` | `mult *= effect_mult` for each matching relic | 1.10 × 1.10 = **1.21** (multiplicative — WRONG) |
| `compute_stat_addend(stat)` | `total += effect_mult` for each matching relic | 0.10 + 0.10 = **0.20** (additive — correct) |

### Which stats use which path

**`get_stat_mult` (currently multiplicative, needs to become additive):**
- `attack_damage` — `CombatComponent._recompute_stats()`: `base × MetaManager.damage_multiplier × RelicManager.get_stat_mult("attack_damage")`
- `attack_speed` — `CombatComponent._recompute_stats()`: `base / RelicManager.get_stat_mult("attack_speed")`
- `max_health` — `StatsComponent._on_relic_applied()`: `_base_max_health × RelicManager.get_stat_mult("max_health")`
- `move_speed` — `MovementComponent._recompute_stats()`: `_base_move_speed × RelicManager.get_stat_mult("move_speed")`

**`get_stat_addend` (already additive — no change needed):**
- `crit_chance` — `CombatComponent`: `base + get_stat_addend("crit_chance")`
- `crit_multiplier` — `CombatComponent`: `base + get_stat_addend("crit_multiplier")`
- `hp_regen` — `StatsComponent._process()`: `get_stat_addend("hp_regen")`
- `damage_reduction` — `StatsComponent._on_relic_applied()`: `min(cap, get_stat_addend("damage_reduction"))`

### JSON effect_mult storage format

| Stat category | Example relic | `effect_mult` stored as | Bonus extraction |
|---|---|---|---|
| Multiplicative stats (mult path) | `common_damage` | `1.10` (full multiplier) | `effect_mult − 1.0 = 0.10` |
| Additive stats (addend path) | `iron_veil` | `0.10` (raw bonus) | already a bonus value |
| Conditional relics | `executioners_mark` | `1.0` (neutral) | not used in stacking |

### Cross-source multiplication — already correct

The calling code in `CombatComponent` already multiplies across sources:
```
attack_damage = base × MetaManager.damage_multiplier × RelicManager.get_stat_mult("attack_damage")
```
`MetaManager.damage_multiplier = 1.0 + damage_upgrade_level × 0.10`

So with one damage upgrade level and two ×1.10 relics:
- **Current**: `base × 1.10 × (1.10 × 1.10)` = `base × 1.10 × 1.21` = `base × 1.331` ❌
- **Target**: `base × 1.10 × (1.0 + 0.10 + 0.10)` = `base × 1.10 × 1.20` = `base × 1.32` ✓

The cross-source part is already multiplicative; only `compute_stat_mult` needs to change.

## Decisions

**Decision 1: Change `compute_stat_mult` to additive stacking**
- Rationale: The function currently multiplies `effect_mult` values together. Changing it to extract `effect_mult − 1.0` per relic, sum those bonuses, and return `1.0 + sum` produces additive stacking within the relic source. No other code needs to change.
- Alternatives considered: Renaming to `compute_relic_factor(stat)` — rejected (YAGNI; existing name is fine, semantics change is documented in the function body).

**Decision 2: No JSON data migration**
- `effect_mult` values for multiplicative stats (e.g., `1.10`) remain unchanged. The code extracts the bonus as `effect_mult − 1.0`. This is a pure code change.
- Rationale: Changing JSON values would require updating all `compute_stat_addend` call sites (which already store raw bonuses like `0.10`) and create two inconsistent formats. Keeping `effect_mult > 1.0` for multiplicative stats and `effect_mult <= 1.0` for additive stats preserves the current authoring convention.

**Decision 3: `crit_chance`, `crit_multiplier`, `damage_reduction` require no logic change**
- These already use `compute_stat_addend`, which sums raw bonus values — exactly the desired additive-within-source behavior.
- The spec includes them in scope for clarity and test coverage, but no code changes are needed for these stats specifically.

**Decision 4: Scope of change is one function**
- Only `RelicManagerImpl.compute_stat_mult` changes. `CombatComponent`, `StatsComponent`, `MovementComponent`, `RelicManager` (autoload), and all JSON files are unchanged.
- The existing unit tests in `tests/unit/test_relic_deck.gd` will need new test cases covering the additive stacking behavior.
