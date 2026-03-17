# Implementation Plan: Crit Relic Integration

**Branch**: `052-crit-relic-integration` | **Date**: 2026-03-17 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/052-crit-relic-integration/spec.md`

## Summary

`CombatComponent` and `SkillComponent` both read crit stats from config once at startup but never reactively update them when relics are applied or cleared. This plan adds an additive stat accumulator to `RelicManagerImpl`, exposes it via `RelicManager`, and wires both components to recompute effective crit values on every relic event — the same pattern already used for `attack_damage` and `attack_speed`.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: RelicManager autoload, RelicManagerImpl, CombatComponent, SkillComponent
**Storage**: N/A — no new persisted data
**Testing**: GUT unit tests (`tests/unit/`)
**Target Platform**: Android mobile / Windows dev
**Project Type**: Single Godot project
**Performance Goals**: 60 fps; crit recompute is O(n relics) per relic event — negligible
**Constraints**: No raw `.tscn` edits; no hardcoded constants; additive semantics required for crit stats (base = 0.0)

## Constitution Check

- ✅ **I. Single Responsibility** — `compute_stat_addend` stays in `RelicManagerImpl`; `RelicManager` remains a thin wrapper; no logic added to the autoload.
- ✅ **II. Data-Driven Content** — crit relic values live in `relics.json`; no new hardcoded constants in code.
- ✅ **III. Mobile-First** — recompute is O(active relics) triggered only on relic events (not per-frame); no performance concern.
- ✅ **IV. Editor-Centric** — no `.tscn` changes; all changes are in `.gd` scripts.
- ✅ **V. Simplicity & YAGNI** — no speculative abstractions; exactly the two stats and two components needed.
- ✅ **VI. Early Return** — new methods use guard clauses; loop body continues on non-match.

## Project Structure

### Documentation (this feature)

```text
specs/052-crit-relic-integration/
├── plan.md              ← this file
├── spec.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── interfaces.md
├── checklists/
│   └── requirements.md
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code (affected files only)

```text
scripts/managers/RelicManagerImpl.gd      ← add compute_stat_addend()
autoload/RelicManager.gd                  ← add get_stat_addend() wrapper
scenes/player/components/CombatComponent.gd   ← add base crit fields; extend _recompute_stats()
scenes/player/components/SkillComponent.gd    ← add base crit fields; add _recompute_crit_stats(); wire signals
```

No new files. No scene changes.

## Implementation Detail

### 1. `RelicManagerImpl` — `compute_stat_addend(stat: String) -> float`

Sums `effect_mult` for every held relic whose `effect_stat == stat`. Returns `0.0` when none match.

```gdscript
func compute_stat_addend(stat: String) -> float:
    var total: float = 0.0
    for relic_id: String in active_relic_ids:
        var relic: Variant = _relics_by_id.get(relic_id)
        if not relic is RelicData:
            continue
        if (relic as RelicData).effect_stat != stat:
            continue
        total += (relic as RelicData).effect_mult
    return total
```

### 2. `RelicManager` — `get_stat_addend(stat: String) -> float`

Thin wrapper:

```gdscript
func get_stat_addend(stat: String) -> float:
    return _impl.compute_stat_addend(stat)
```

### 3. `CombatComponent` — base crit fields + extended `_recompute_stats()`

- Rename `_crit_chance` → keep as effective field; add `_base_crit_chance: float = 0.0`.
- Rename `_crit_multiplier` → keep as effective field; add `_base_crit_multiplier: float = 0.5`.
- In `_ready()`: assign config values to `_base_crit_chance` and `_base_crit_multiplier`.
- In `_recompute_stats()`: add two lines at the end:

```gdscript
_crit_chance     = minf(1.0, _base_crit_chance    + RelicManager.get_stat_addend("crit_chance"))
_crit_multiplier = _base_crit_multiplier + RelicManager.get_stat_addend("crit_multiplier")
```

### 4. `SkillComponent` — base crit fields, reactive connections, `_recompute_crit_stats()`

- Add `_base_crit_chance` and `_base_crit_multiplier` fields.
- In `_load_skill_data()`: assign config values to the base fields, then call `_recompute_crit_stats()`.
- Add `_recompute_crit_stats()` method:

```gdscript
func _recompute_crit_stats() -> void:
    _crit_chance     = minf(1.0, _base_crit_chance    + RelicManager.get_stat_addend("crit_chance"))
    _crit_multiplier = _base_crit_multiplier + RelicManager.get_stat_addend("crit_multiplier")
```

- In `_ready()`, connect relic signals (after `_load_skill_data()` call):

```gdscript
RelicManager.relic_applied.connect(func(_id: String) -> void: _recompute_crit_stats())
RelicManager.relics_cleared.connect(func() -> void: _recompute_crit_stats())
RunManager.run_started.connect(func(_m: String) -> void: _recompute_crit_stats())
```

## Complexity Tracking

No constitution violations. No complexity exceptions required.
