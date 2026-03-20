# Implementation Plan: Chain Damage Relic

**Branch**: `068-chain-damage-relic` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/068-chain-damage-relic/spec.md`

## Summary

Add a new common conditional relic (`chain_power_stone`) gated behind the `chain_unlocked` tag. When held, it adds +0.15 to the effective `chain_damage_mult` when resolving chain hits — making the second target of a chained magic missile take 0.65× primary damage instead of 0.50×. The bonus is stored in `relics.json` via the existing `condition_type`/`condition_mult` fields on `RelicData`, keeping the value data-driven.

## Technical Context

**Language/Version**: GDScript 4.6 (static typing)
**Primary Dependencies**: RelicManagerImpl, Projectile, relics.json
**Storage**: `data/relics.json` (relic entries)
**Testing**: GUT unit tests
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: 60 fps — no impact (one additional lookup per chain hit)
**Constraints**: Must follow Constitution I–VI; no raw balance constants in code
**Scale/Scope**: 4 file modifications, 0 new files

## Constitution Check

- **I. Single Responsibility**: `get_chain_damage_bonus()` logic lives in `RelicManagerImpl` (the relic domain). `Projectile` reads the bonus at chain-hit time — no responsibility leakage. `RelicManager` autoload remains a thin wrapper. ✅
- **II. Data-Driven Content**: The +0.15 bonus is stored as `condition_mult: 0.15` in `relics.json`, read via `RelicData.condition_mult`. No balance constant in code. ✅
- **III. Mobile-First**: No new physics, shaders, or draw calls. One dictionary lookup per chain event. ✅
- **IV. Editor-Centric**: No scene changes required. ✅
- **V. Simplicity & YAGNI**: Reuses the existing `condition_type`/`condition_mult` fields on `RelicData`. No new abstraction introduced. ✅
- **VI. Early Return**: `get_chain_damage_bonus()` and `_try_chain()` already use guard clauses; the bonus summation will use a `continue` loop guard. ✅

## Decisions

1. **Store bonus as `condition_mult: 0.15` with `condition_type: "chain_damage_bonus"`** — The existing `RelicData` fields (`condition_type`, `condition_mult`) already support per-relic data. Using them for the chain bonus avoids adding a new field to `RelicData` and keeps the value in JSON (Constitution II). `get_chain_damage_bonus()` sums `condition_mult` for all active relics whose `condition_type == "chain_damage_bonus"`, making it trivially extensible if a second such relic is added later.

2. **Additive composition in `Projectile._try_chain()`** — The chain hit uses `_damage * (_chain_damage_mult + RelicManager.get_chain_damage_bonus())`. This matches the spec's explicit additive requirement (0.50 + 0.15 = 0.65).

3. **Common tier, `deck_count: 1`** — Matches the `burn_dot_damage` (`Bottled Oil`) common relic which is also a `burn_unlocked` chain-gated entry with `deck_count: 1`.

## Schema Changes

Single new entry added to the `"common"` block of `data/relics.json`:

| Field | Value |
|-------|-------|
| id (key) | `chain_power_stone` |
| name | `Chain Amplifier` |
| tier | `"common"` |
| tags | `["chain_unlocked"]` |
| effect_stat | `""` |
| effect_mult | `1.0` |
| condition_type | `"chain_damage_bonus"` |
| condition_threshold | `0.0` |
| condition_mult | `0.15` |
| description | `"Chain hits deal 65% of primary damage instead of 50%."` |
| deck_count | `1` |

No changes to `RelicData.gd` — all fields already exist.

## Affected Files

**`data/relics.json`** — Add the `chain_power_stone` entry in the `"common"` tier block, after `burn_dot_damage`. Uses existing JSON structure with no new fields.

**`scripts/managers/RelicManagerImpl.gd`** — Add `get_chain_damage_bonus() -> float` method. Iterates `active_relic_ids`, looks up each `RelicData` in the pool, and sums `condition_mult` for entries where `condition_type == "chain_damage_bonus"`. Returns 0.0 if none held.

**`autoload/RelicManager.gd`** — Add thin-wrapper `get_chain_damage_bonus() -> float` that delegates to `_impl.get_chain_damage_bonus()`. Follows existing delegation pattern (`has_chain_relic`, `get_stat_mult`, etc.).

**`scenes/combat/projectiles/Projectile.gd`** — In `_try_chain()`, change the chain damage application from `_damage * _chain_damage_mult` to `_damage * (_chain_damage_mult + RelicManager.get_chain_damage_bonus())`. The call is a single-line change.
