# Data Model: Crit Relic Integration

**Feature**: 052-crit-relic-integration
**Date**: 2026-03-17

## No New Entities

This feature introduces no new data models, JSON schemas, or scene files.

## Relic Stat Categories (extended)

The relic system already supports arbitrary `effect_stat` string values. This feature designates two new recognised categories:

| Stat Category | Accumulation | Default (no relics) | Applied to |
|---|---|---|---|
| `"crit_chance"` | Additive | 0.0 (base from config) | `CombatComponent`, `SkillComponent` |
| `"crit_multiplier"` | Additive | 0.5 (base from config) | `CombatComponent`, `SkillComponent` |

Relic JSON entries using these stat categories follow the existing format:
```json
{
  "id": "example_crit_relic",
  "name": "...",
  "tags": ["combat"],
  "effect_stat": "crit_chance",
  "effect_mult": 0.15,
  "description": "+15% crit chance"
}
```
`effect_mult` is the **flat bonus** added to the base value (not a multiplier).

## Effective Value Formulas

```
effective_crit_chance    = min(1.0, base_crit_chance    + sum(effect_mult for relics where effect_stat == "crit_chance"))
effective_crit_multiplier = base_crit_multiplier + sum(effect_mult for relics where effect_stat == "crit_multiplier")
```

Both values are recalculated whenever `RelicManager.relic_applied` or `RelicManager.relics_cleared` fires.
