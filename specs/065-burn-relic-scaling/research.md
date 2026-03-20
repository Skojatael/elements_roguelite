# Research: Burn Relic Damage Scaling (065)

**Feature Branch**: `065-burn-relic-scaling`
**Date**: 2026-03-19

---

## Current State Analysis

### What already exists

`data/relics.json` already contains both relics this feature activates:

- **Bottled Oil** — common tier, JSON key `"burn_dot_damage"`, `effect_stat: "burn_damage"`, `effect_mult: 0.20`, tagged `burn_unlocked`. The `effect_stat` field and the `compute_stat_mult` machinery in `RelicManagerImpl` are already wired for arbitrary stat keys, including `"burn_damage"`. The only missing piece is that nothing reads `RelicManager.get_stat_mult("burn_damage")` at burn-application time.

- **Searing Seal** — uncommon tier, JSON key `"searing_seal"` (renamed by user to resolve ID collision), `effect_stat: ""`, `effect_mult: 1.0`, tagged `burn_unlocked`. Its empty `effect_stat` correctly marks it as a conditional relic, consistent with `executioners_mark` and `berserker_stone`.

Both relics are behind the `burn_unlocked` mechanic gate — they only enter the offer pool once the player holds the "Living Ember" (`burn`) relic.

### The gap

**Bottled Oil**: `Projectile._on_body_entered()` calls `enemy.on_burn_hit(_damage * _burn_damage_per_tick, ...)`. The tick damage is a fixed ratio of projectile damage with no relic multiplier applied. `compute_stat_mult("burn_damage")` would compute the correct value but there is no call site reading it before the tick value is passed to `on_burn_hit()`. The same applies in `_try_chain()`.

**Searing Seal**: `RelicManagerImpl.get_hit_damage_mult()` takes `target_hp_ratio` and `attacker_hp_ratio` but has no parameter for burn state. `CombatComponent` calls this without any burn context. `Enemy` has no public `is_burning()` query method — `_burn` is private.

---

## Design Decisions

### Decision 1: Where to apply the burn damage multiplier

**Options considered**:

A. Apply in `Projectile._on_body_entered()` / `_try_chain()` — multiply `_burn_damage_per_tick` by `RelicManager.get_stat_mult("burn_damage")` at call time.

B. Apply inside `Enemy.on_burn_hit()` — read the mult inside the enemy, requiring the enemy to call `RelicManager`.

C. Apply inside `BurnEffect.process()` — bake the mult into `tick_damage` at apply time.

D. Apply inside `Enemy._physics_process()` at tick-fire time.

**Decision: Option A** — applied at the call sites in `Projectile`.

**Rationale**: The projectile already owns burn-application. Multiplying before calling `on_burn_hit()` bakes the scaled value into `BurnEffect.tick_damage` at apply time — consistent with how `_damage` is already scaled at projectile creation. `Enemy` remains engine-agnostic with no RelicManager dependency. Options B–D couple Enemy or BurnEffect to the relic system.

**Edge case — currently active burns**: Burns already active when Bottled Oil is picked retain their original `tick_damage`. New burns after pickup use the scaled value. This is acceptable — it matches how all other relic mults work (not retroactive) and avoids scanning all active enemies.

### Decision 2: Where to apply the Searing Seal multiplier + make conditional relics data-driven

**Options considered**:

A. Hard-code a third `if active_relic_ids.has("burn_damage") and target_is_burning: mult *= 1.50` check alongside the existing two, keeping all multiplier values in code.

B. Add `target_is_burning: bool` parameter and replace the entire `get_hit_damage_mult()` body with a generic loop that reads `condition_type`, `condition_threshold`, and `condition_mult` from `RelicData` — values sourced from JSON.

C. Add a separate `get_burning_bonus_mult()` method.

D. Query `target.is_burning()` directly inside `CombatComponent` and multiply inline.

**Decision: Option B** — data-driven generic loop.

**Rationale**: Option A would be the third hard-coded conditional relic in this function, making it a maintenance liability. With the condition fields in JSON, future conditional relics require zero code changes. The condition type names (`"target_hp_below"`, `"attacker_hp_below"`, `"target_is_burning"`) form a stable, closed enum in code — this is unavoidable since they map to runtime context — but the multiplier values and thresholds are fully in data. Option C splits conditional hit-mult logic. Option D embeds relic logic in CombatComponent.

**Breaking change**: `get_hit_damage_mult()` is called in one place (`CombatComponent`) and tested in `test_relic_deck.gd`. All existing test call sites need `false` added as third argument. Existing tests for `executioners_mark` and `berserker_stone` remain valid — they will now exercise the generic loop path rather than hard-coded branches, providing regression coverage for the refactor.

### Decision 3: How Enemy exposes its burning state

**Options considered**:

A. Add `is_burning() -> bool` as a public method on `Enemy`.

B. Make `_burn` public.

C. Keep burn state opaque; use a callback.

**Decision: Option A** — add `is_burning() -> bool` to `Enemy.gd`.

**Rationale**: A named method with clear semantics is correct. Making `_burn` public breaks encapsulation. Option C is unnecessarily complex. The method body is trivially short with a null guard following the Early Return principle.

### Decision 4: No changes to SkillComponent

**Rationale**: `SkillComponent` passes `_burn_damage_per_tick` to `Projectile.setup()`. The multiplier is applied downstream in `Projectile._on_body_entered()` at hit time — SkillComponent does not need to know about burn damage scaling.

### Decision 5: No new JSON data needed

All data is already present in `data/relics.json`. Bottled Oil's `effect_mult: 0.20` is correctly read by `compute_stat_mult("burn_damage")`, returning `1.20` when held. Searing Seal's `effect_stat: ""` correctly opts out of the additive stat system.

### Decision 6: Searing Seal relic ID in code

The relic ID for Searing Seal in `relics.json` is the JSON key `"burn_damage"`. The check in `get_hit_damage_mult()` must use `active_relic_ids.has("burn_damage")`.

---

## Alternatives Rejected

| Alternative | Rejected Because |
|---|---|
| Apply burn mult in `BurnEffect.process()` | BurnEffect has no access to RelicManager; would need to be passed in, violating SRP |
| Apply burn mult in `Enemy._physics_process()` | Same coupling problem; Enemy should not reference RelicManager |
| New `get_burning_bonus_mult()` on RelicManager | Splits conditional hit-mult logic across two methods; harder to test combined stacking |
| Retroactive burn scaling when relic picked | Complex, requires scanning all active enemies; spec is silent on this; YAGNI |
| Make `_burn` public on Enemy | Breaks encapsulation; callers should not depend on BurnEffect's internals |
