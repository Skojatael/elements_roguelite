# Quickstart: Additive-Multiplicative Modifier Stacking (063)

## What changes

One function in one file:

**`scripts/managers/RelicManagerImpl.gd` → `compute_stat_mult(stat)`**

| Before | After |
|---|---|
| Multiplies `effect_mult` values together | Sums `(effect_mult − 1.0)` bonus values, returns `1.0 + sum` |
| Two ×1.10 relics → 1.21 | Two ×1.10 relics → 1.20 |

## What does NOT change

- `CombatComponent`, `MovementComponent`, `StatsComponent` — formulas unchanged
- `RelicManager` autoload — thin wrapper, no logic changes
- `compute_stat_addend` — already additive; crit_chance, crit_multiplier, hp_regen, damage_reduction unaffected
- `relics.json`, `meta_config.json`, `player.json` — no data changes
- All JSON `effect_mult` values — no migration needed

## Verification steps

1. Two `common_damage` relics active, no meta upgrades → `attack_damage` = base × **1.20** (not 1.21)
2. Two `common_damage` relics + one damage upgrade level → `attack_damage` = base × **1.32** (= 1.20 × 1.10)
3. Two `iron_hide` relics (×1.15 each) → `max_health` = base × **1.30** (not 1.3225)
4. One `crit_projectile` relic (+0.20 crit_chance) — behavior unchanged (uses `get_stat_addend`)
5. One `iron_veil` relic (+0.10 damage_reduction) — behavior unchanged (uses `get_stat_addend`)
6. `executioners_mark` and `berserker_stone` — hit-time behavior unchanged
