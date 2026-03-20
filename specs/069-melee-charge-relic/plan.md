# Implementation Plan: Melee Charge Relic

**Branch**: `069-melee-charge-relic` | **Date**: 2026-03-20 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/069-melee-charge-relic/spec.md`

## Summary

Add a common-tier relic ("Arcane Knuckles") that tracks melee hits and grants one bonus Magic Missile charge every 3rd hit. The melee hit counter lives in `RelicManagerImpl`, keeping charge-granting logic in `SkillComponent` and relic state management in `RelicManagerImpl`. The existing unconditional `_on_melee_hit_landed()` in `SkillComponent` (which currently grants a charge on every hit) is replaced by a gated call to `RelicManager.on_melee_hit()`, so the mechanic only activates when the relic is held.

## Technical Context

**Language/Version**: GDScript (Godot 4.6)
**Primary Dependencies**: Existing `RelicManager`, `RelicManagerImpl`, `SkillComponent`, `CombatComponent`
**Storage**: `data/relics.json` (new relic entry)
**Testing**: GUT unit tests in `tests/unit/`
**Target Platform**: Android mobile (portrait); Windows dev
**Performance Goals**: 60 fps mobile — counter increment is O(1), no impact
**Constraints**: No new autoloads; no new data model fields; balance value (hit count = 3) encoded in `condition_threshold` in JSON per Constitution II

## Constitution Check

- **I. Single Responsibility** ✅ — Melee-hit counter and charge-grant logic are split correctly: `RelicManagerImpl` owns the counter and eligibility check; `SkillComponent` owns the charge mutation. No concern is duplicated.
- **II. Data-Driven Content** ✅ — The hit count threshold (3) is stored in `condition_threshold` in `relics.json`, not hard-coded. The relic name and description are in JSON.
- **III. Mobile-First** ✅ — No new `_process()` loop or per-frame cost; counter increment happens only on melee hit events.
- **IV. Editor-Centric** ✅ — No `.tscn` changes required; all wiring is done in `_ready()` via signals already connected.
- **V. Simplicity & YAGNI** ✅ — No new abstractions; reuses existing `melee_hit_landed` signal, `RelicData` model, and the `pick_relic` pathway unchanged.
- **VI. Early Return** ✅ — `on_melee_hit()` will use early return when relic is not held.

## Decisions

**D1 — Counter lives in `RelicManagerImpl`, not `SkillComponent`**
Relic-specific state (the hit counter) belongs in the relic manager, not the skill component. `SkillComponent` asks "did a charge event happen?" and acts on the answer; it does not track relic counters. `RelicManagerImpl.reset()` clears the counter on every run start/end, matching the run-scoped lifecycle.

**D2 — Preserve unconditional charge restore; relic is additive on top**
The existing `SkillComponent._on_melee_hit_landed()` behavior (every melee hit grants +1 charge, capped at max) is left unchanged. The relic adds a second charge grant when the 3-hit threshold is reached — on that hit the player receives both the baseline +1 and the relic +1, for a total of +2 charges on the 3rd hit. The unconditional restore remains active whether or not the relic is held.

**D3 — Hit count encoded as `condition_threshold` in JSON**
Rather than adding a new `RelicData` field (YAGNI), the threshold value of `3` is stored in the existing `condition_threshold` field. `RelicManagerImpl.on_melee_hit()` reads this value from the relic data at runtime. `condition_type` is left empty so `get_hit_damage_mult()` skips this relic correctly.

**D4 — Relic ID: `"melee_missile_charge"`**
Follows the existing naming convention (snake_case, descriptive). Hardcoded as a const `MELEE_CHARGE_RELIC_ID` in `RelicManagerImpl` (same pattern as chaining_stone in `has_chain_relic()`).

## Schema Changes

**`data/relics.json` — add under `"common"`:**
New entry key `"melee_missile_charge"` with:
- `name`: "Arcane Knuckles"
- `tags`: `["projectile", "melee"]`
- `effect_stat`: `""`
- `effect_mult`: `1.0`
- `condition_type`: `""` (ensures `get_hit_damage_mult()` ignores this relic)
- `condition_threshold`: `3.0` (the hit count before a charge is granted)
- `condition_mult`: `1.0`
- `description`: "Every 3 melee hits restore 1 Magic Missile charge."
- `deck_count`: `2`

No changes to `RelicData.gd` — all required fields already exist.

## Affected Files

**`data/relics.json`** — Add the `"melee_missile_charge"` common relic entry as described in Schema Changes above.

**`scripts/managers/RelicManagerImpl.gd`** — Add `const MELEE_CHARGE_RELIC_ID: String = "melee_missile_charge"`. Add `var _melee_hit_count: int = 0` to state. Clear `_melee_hit_count` in `reset()`. Add `on_melee_hit() -> bool`: early-return `false` if relic is not held; read the hit threshold from `_relics_by_id[MELEE_CHARGE_RELIC_ID].condition_threshold`; increment `_melee_hit_count`; if count reaches threshold, reset count to 0 and return `true`; otherwise return `false`.

**`autoload/RelicManager.gd`** — Add `on_melee_hit() -> bool` thin-wrapper method that delegates to `_impl.on_melee_hit()`.

**`scenes/player/components/SkillComponent.gd`** — Keep the existing unconditional +1 charge logic in `_on_melee_hit_landed()` unchanged. Append a second charge grant: call `RelicManager.on_melee_hit()` and, if it returns `true` and `_current_charges < _max_charges`, grant an additional +1 charge and emit `charges_changed`.

**`tests/unit/test_melee_charge_relic.gd`** — New GUT test suite. Verifies: (a) counter increments and returns false for first two hits, (b) third hit returns true and resets counter to 0, (c) when relic is not held, always returns false, (d) counter resets on `reset()`, (e) fourth hit after a cycle starts the counter fresh and returns false again.
