# Quickstart: Crit Relic Integration

**Feature**: 052-crit-relic-integration

## What changed

The crit stats (`crit_chance`, `crit_multiplier`) in `CombatComponent` and `SkillComponent` are now reactively recalculated whenever a relic is applied or cleared — the same pattern already used for `attack_damage` and `attack_speed`.

A new additive accumulator (`compute_stat_addend`) was added to `RelicManagerImpl` alongside the existing multiplicative `compute_stat_mult`. Crit stats use additive accumulation because `base_crit_chance` starts at 0.0.

## How to add a crit relic

Add an entry to `data/relics.json` under any tier:

```json
"lucky_charm": {
    "name": "Lucky Charm",
    "tags": ["combat"],
    "effect_stat": "crit_chance",
    "effect_mult": 0.15,
    "description": "+15% crit chance"
}
```

`effect_mult` is a **flat addend** to the base value (0.15 = adds 15% crit chance). No code changes needed — the plumbing handles the rest automatically.

## Effective value formulas

```
effective_crit_chance     = min(1.0, base + sum of all crit_chance relic effect_mults)
effective_crit_multiplier = base + sum of all crit_multiplier relic effect_mults
```

Defaults: `base_crit_chance = 0.0`, `base_crit_multiplier = 0.5` (from `data/player.json`).

## Testing

Use DevPanel to grant a crit relic during a run. With `crit_chance = 0.0` in config, no crits should fire before picking. After picking a +15% crit_chance relic, 15% of hits should crit. After run end, behaviour resets to base.
