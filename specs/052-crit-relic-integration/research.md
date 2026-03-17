# Research: Crit Relic Integration

**Feature**: 052-crit-relic-integration
**Date**: 2026-03-17

## Current State Analysis

### CombatComponent (`scenes/player/components/CombatComponent.gd`)

- Loads `_crit_chance` and `_crit_multiplier` from config in `_ready()`.
- Connects to `RelicManager.relic_applied` and `RelicManager.relics_cleared` → `_recompute_stats()`.
- **Gap**: `_recompute_stats()` only recomputes `attack_damage` and `attack_interval`. Crit stats are never updated reactively.
- There is no split between "base crit" and "effective crit" — the fields are set once and never updated.

### SkillComponent (`scenes/player/components/SkillComponent.gd`)

- Loads `_crit_chance` and `_crit_multiplier` from config in `_load_skill_data()`.
- **Gap**: Does NOT connect to `RelicManager.relic_applied` or `relics_cleared`. Crit stats are never reactively updated.
- Magic missile damage is computed inline with local crit values.

### RelicManagerImpl (`scripts/managers/RelicManagerImpl.gd`)

- `compute_stat_mult(stat)` → multiplicative accumulation, returns 1.0 for unmatched stats.
- **Gap**: Multiplicative semantics are unusable for `crit_chance` when base = 0.0 (0.0 × anything = 0.0).
- A new **additive accumulator** is needed: sum `effect_mult` across matching relics, return 0.0 by default.

### RelicManager autoload (`autoload/RelicManager.gd`)

- Thin wrapper exposing `get_stat_mult()` → delegates to `_impl.compute_stat_mult()`.
- Needs a parallel `get_stat_addend()` wrapper for the new additive function.

## Decisions

### Decision 1: Additive vs Multiplicative for Crit Stats

- **Chosen**: Additive accumulation — `effective = base + sum(relic.effect_mult for matching relics)`
- **Rationale**: Base `crit_chance = 0.0` makes multiplicative useless. Additive is intuitive for chance stats ("add 15% crit chance"). Crit multiplier follows the same convention for consistency.
- **Alternatives considered**: Separate field type per relic (multiplicative/additive flag) — rejected as over-engineering for two stats.

### Decision 2: New method vs extending compute_stat_mult

- **Chosen**: New `compute_stat_addend(stat: String) -> float` on `RelicManagerImpl`; `get_stat_addend(stat: String) -> float` thin wrapper on `RelicManager`.
- **Rationale**: Keeps multiplicative and additive semantics clearly separated. Callers (CombatComponent, SkillComponent) explicitly choose the right accumulation.
- **Alternatives considered**: Overloading `compute_stat_mult` with a mode flag — rejected (violates SRP / confusing API).

### Decision 3: Crit stat storage in CombatComponent and SkillComponent

- **Chosen**: Add `_base_crit_chance` and `_base_crit_multiplier` fields (set once in `_ready()`). Existing `_crit_chance` / `_crit_multiplier` become the effective (recomputed) values.
- **Rationale**: Mirrors the existing `_base_attack_damage` / `attack_damage` pattern already used by `CombatComponent`.

## Files Changed

| File | Change |
|------|--------|
| `scripts/managers/RelicManagerImpl.gd` | Add `compute_stat_addend(stat)` method |
| `autoload/RelicManager.gd` | Add `get_stat_addend(stat)` thin wrapper |
| `scenes/player/components/CombatComponent.gd` | Add base crit fields; update `_recompute_stats()` |
| `scenes/player/components/SkillComponent.gd` | Connect relic signals; add base crit fields; add `_recompute_crit_stats()` |

No new scenes, JSON entries, or data models are required.
