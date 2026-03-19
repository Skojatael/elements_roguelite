# Data Model: Additive-Multiplicative Modifier Stacking (063)

## No new data entities

This feature introduces no new data classes, JSON schemas, or autoloads. All changes are algorithmic — confined to `RelicManagerImpl.compute_stat_mult`.

## Effect mult conventions (unchanged)

| Effect type | `effect_stat` | `effect_mult` stored as | Stacking method |
|---|---|---|---|
| Multiplicative stat boost | `"attack_damage"` / `"attack_speed"` / `"max_health"` / `"move_speed"` | Full multiplier: `1.10`, `1.15`, `1.30`, `1.50` | `compute_stat_mult` — now additive (bonus = `effect_mult − 1.0`) |
| Additive stat bonus | `"crit_chance"` / `"crit_multiplier"` / `"hp_regen"` / `"damage_reduction"` | Raw bonus: `0.01`, `0.10`, `0.20` | `compute_stat_addend` — already additive (sum of values) |
| Conditional hit-time | `""` (empty) | Always `1.0` | `get_hit_damage_mult` — unaffected |
| Behavior flag | `""` (empty) | Always `1.0` | `has_chain_relic` / `has_burn_relic` — unaffected |

## Stat computation formulas (post-feature)

### Multiplicative stats

```
attack_damage  = _base_attack_damage  × MetaManager.damage_multiplier × RelicManager.get_stat_mult("attack_damage")
attack_interval = _base_attack_interval / RelicManager.get_stat_mult("attack_speed")
max_health     = _base_max_health     × RelicManager.get_stat_mult("max_health")
move_speed     = _base_move_speed     × RelicManager.get_stat_mult("move_speed")

where:
  MetaManager.damage_multiplier = 1.0 + damage_upgrade_level × damage_per_level
  RelicManager.get_stat_mult(stat) = 1.0 + Σ(effect_mult − 1.0) for each held relic with effect_stat == stat
```

### Additive stats (no change)

```
_crit_chance    = min(1.0, _base_crit_chance    + RelicManager.get_stat_addend("crit_chance"))
_crit_multiplier = _base_crit_multiplier        + RelicManager.get_stat_addend("crit_multiplier")
hp_regen_rate  = RelicManager.get_stat_addend("hp_regen")
damage_reduction = min(cap, RelicManager.get_stat_addend("damage_reduction"))

where:
  RelicManager.get_stat_addend(stat) = Σ(effect_mult) for each held relic with effect_stat == stat
```

### Hit-time damage (no change)

```
final_damage = attack_damage × RelicManager.get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio)
             -- then apply crit roll
```

## Worked example

Two `common_damage` relics (each `effect_mult = 1.10`) + one damage upgrade level (`damage_per_level = 0.10`):

```
MetaManager.damage_multiplier   = 1.0 + 1 × 0.10 = 1.10
relic bonus per relic            = 1.10 − 1.0 = 0.10
Σ relic bonuses                  = 0.10 + 0.10 = 0.20
RelicManager.get_stat_mult(...)  = 1.0 + 0.20 = 1.20
attack_damage = base × 1.10 × 1.20 = base × 1.32
```
