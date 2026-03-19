# Implementation Plan: Additive-Multiplicative Modifier Stacking

**Branch**: `063-additive-multiplicative-modifiers` | **Date**: 2026-03-19 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/063-additive-multiplicative-modifiers/spec.md`

## Summary

Change `RelicManagerImpl.compute_stat_mult` to stack relic bonuses additively (sum of `effect_mult − 1.0`) rather than multiplicatively. The cross-source multiplication (relics × meta upgrade) is already handled by calling code and remains unchanged. This is a single-function change with no JSON migration and no scene edits.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: `RelicManagerImpl`, `RelicManager` (autoload thin wrapper)
**Storage**: N/A — no new persistence
**Testing**: GUT (`tests/unit/test_relic_deck.gd`)
**Target Platform**: Android mobile / Windows dev
**Project Type**: Single Godot project
**Performance Goals**: 60 fps — no impact (arithmetic change in a rare event handler)
**Constraints**: No raw `.tscn` edits; no new autoloads; no hardcoded balance constants
**Scale/Scope**: One function modified; two files touched (impl + tests)

## Constitution Check

| Principle | Status | Notes |
|---|---|---|
| **I. Single Responsibility** | ✅ Pass | Only `RelicManagerImpl` (the algorithmic manager) changes. Autoload wrapper untouched. |
| **II. Data-Driven Content** | ✅ Pass | No balance constants introduced in code. `effect_mult` values remain in JSON. |
| **III. Mobile-First** | ✅ Pass | Arithmetic-only change; zero performance impact. |
| **IV. Editor-Centric** | ✅ Pass | No `.tscn` edits; no new `@export` references. |
| **V. Simplicity & YAGNI** | ✅ Pass | Smallest possible change: one function body replaced. No new abstractions. |
| **VI. Early Return** | ✅ Pass | New implementation uses the same loop-with-continue guard pattern as `compute_stat_addend`. |

## Project Structure

### Documentation (this feature)

```text
specs/063-additive-multiplicative-modifiers/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/           ← N/A (no API surface changes)
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code (affected files only)

```text
scripts/managers/RelicManagerImpl.gd   ← compute_stat_mult() body changes
tests/unit/test_relic_deck.gd          ← new test cases for additive stacking
```

No new files. No scene changes. No JSON changes.

## Implementation Detail

### `RelicManagerImpl.compute_stat_mult` — before vs after

**Before** (multiplicative stacking):
```gdscript
func compute_stat_mult(stat: String) -> float:
    var mult: float = 1.0
    for relic_id: String in active_relic_ids:
        var relic: Variant = _relics_by_id.get(relic_id)
        if relic is RelicData and (relic as RelicData).effect_stat == stat:
            mult *= (relic as RelicData).effect_mult
    return mult
```

**After** (additive stacking within source):
```gdscript
func compute_stat_mult(stat: String) -> float:
    var bonus_sum: float = 0.0
    for relic_id: String in active_relic_ids:
        var relic: Variant = _relics_by_id.get(relic_id)
        if not relic is RelicData:
            continue
        if (relic as RelicData).effect_stat != stat:
            continue
        bonus_sum += (relic as RelicData).effect_mult - 1.0
    return 1.0 + bonus_sum
```

Early-return guard pattern (Principle VI) matches `compute_stat_addend`.

### Why calling code is unchanged

`CombatComponent._recompute_stats()`:
```
attack_damage = base × MetaManager.damage_multiplier × RelicManager.get_stat_mult("attack_damage")
```

This is already a product of two independent source factors:
- `MetaManager.damage_multiplier` = meta upgrade source = `1.0 + level × 0.10`
- `RelicManager.get_stat_mult(...)` = relic source = `1.0 + Σ(bonus)`

After the change, `get_stat_mult` returns the additive-within-source relic factor. The cross-source multiplication is untouched.

### Stats already correct (no changes needed)

`crit_chance`, `crit_multiplier`, `hp_regen`, `damage_reduction` all use `compute_stat_addend`, which already sums raw bonus values. These are in scope for test coverage but require no logic changes.

### New test cases required

In `tests/unit/test_relic_deck.gd` (or a new `test_modifier_stacking.gd`):

1. **Two same-stat relics stack additively**: two ×1.10 → `compute_stat_mult` returns 1.20
2. **Three same-stat relics**: three ×1.10 → returns 1.30
3. **Zero relics**: returns 1.0 (neutral)
4. **One relic**: returns exactly `1.0 + (effect_mult − 1.0)` = `effect_mult` (unchanged)
5. **Mixed-stat relics**: only matching stat relics contribute
6. **Cross-source example** (integration test with MetaManager stub): two ×1.10 relics + 1 upgrade level → 1.20 × 1.10 = 1.32
