# Research: Damage Reduction

**Feature**: 062-damage-reduction
**Date**: 2026-03-18

---

## Decision 1: Where to apply damage reduction

**Decision**: Inside `StatsComponent.take_damage(amount)`, before subtracting from `current_health`.

**Rationale**: Both player and enemies share `StatsComponent` for HP management. All damage pathways (melee contact, projectile, burn DoT) already funnel through `take_damage()`. A single application point prevents double-application and ensures burn, melee, and future damage sources all respect the cap without per-caller changes.

**Alternatives considered**:
- At the call site (CombatComponent, Enemy contact loop) — rejected: requires changes to every damage-dealing location; future sources could forget to apply it.
- In a separate damage calculator service — rejected: YAGNI; the logic is one line and there is no reuse need.

---

## Decision 2: How the player's damage_reduction stat is computed

**Decision**: Use the existing `RelicManager.get_stat_addend("damage_reduction")` path (already implemented in `RelicManagerImpl.compute_stat_addend`). No new methods are needed.

**Rationale**: `compute_stat_addend` already sums `effect_mult` across all held relics with a matching `effect_stat`. Damage reduction is additive (per spec) and `compute_stat_addend` is exactly additive. The cap (clamp to 0.5) is applied in `StatsComponent._on_relic_applied()` using `minf()`.

**Alternatives considered**:
- A dedicated `compute_damage_reduction()` method — rejected: identical to `compute_stat_addend("damage_reduction")`; duplication violates YAGNI.

---

## Decision 3: Where to store the 0.5 player cap

**Decision**: In `data/player.json` under `stats.damage_reduction_cap: 0.5`.

**Rationale**: The project already reads player balance values (max_health, attack_damage, crit_chance) from `data/player.json`. Adding `damage_reduction_cap` here follows the existing data-driven pattern and makes the balance value tunable without code changes (Constitution II).

**Alternatives considered**:
- Hardcoded `const DR_CAP = 0.5` in StatsComponent — rejected: violates Constitution II (no balance constants in code).
- In `data/meta_config.json` — rejected: meta_config is for meta-progression costs and rates; player combat stats belong in `player.json`.

---

## Decision 4: Whether to floor final damage

**Decision**: Do NOT floor. Apply as a simple float multiplication: `amount * (1.0 - damage_reduction)`.

**Rationale**: `StatsComponent.take_damage()` currently accepts and stores float HP values with no flooring. Consistent float math is simpler. The spec's `floor()` in FR-003 is a display-side concern — the real invariant is `max(0, reduced_amount)`, which `maxf()` already handles.

**Alternatives considered**:
- Floor only for direct hits — rejected: moot since burn now bypasses `take_damage()` entirely (see Decision 6).

---

## Decision 6: How burn bypasses damage reduction

**Decision**: Add `StatsComponent.take_damage_raw(amount: float)` — identical to `take_damage()` minus the DR multiplication. In `Enemy._physics_process()`, replace `take_damage(burn_dmg)` with a direct call to `_stats.take_damage_raw(burn_dmg)`.

**Rationale**: Burn ticks are already computed inside `_physics_process()` which has direct access to `_stats`. Calling `_stats.take_damage_raw()` is the minimal, explicit bypass — it requires no flag parameter and the name makes the intent obvious. FR-008 (updated) requires burn to ignore DR.

**Alternatives considered**:
- `take_damage(amount, mitigated: bool = true)` boolean parameter — adds a parameter to every call site to express a concept that only burn needs; adds noise to the common path.
- Apply DR at the CombatComponent/contact-damage call site instead of inside StatsComponent — rejected: forces every future damage source to remember to apply DR manually; the in-StatsComponent approach is safer and centralised.

---

## Decision 5: Enemy damage_reduction field

**Decision**: Add `damage_reduction: float = 0.0` to `EnemyData.gd` and have `Enemy.initialize()` write it to `_stats.damage_reduction`. No enemies need a non-zero value at this time — the field is present and defaults to 0.0.

**Rationale**: FR-005 requires the data layer to support the field. The enemy JSON is authoritative for enemy stats (Constitution II). Authors add non-zero values simply by including the field in an enemy's JSON entry.

**Alternatives considered**:
- Store DR on `Enemy` itself rather than `StatsComponent` — rejected: `StatsComponent.take_damage()` is the application point; the stat must be accessible there.

---

## Integration Map (no new files required)

| File | Change |
|------|--------|
| `scripts/data_models/EnemyData.gd` | Add `damage_reduction: float = 0.0`; read in `from_dict()` |
| `scenes/player/components/StatsComponent.gd` | Add `damage_reduction`, `_damage_reduction_cap`; apply in `take_damage()`; recompute in `_on_relic_applied()` |
| `scenes/combat/enemies/Enemy.gd` | `initialize()` sets `_stats.damage_reduction`; burn tick uses `_stats.take_damage_raw()` |
| `data/player.json` | Add `"damage_reduction_cap": 0.5` under `stats` |
| `data/relics.json` | Add `iron_veil` common relic (`effect_stat: "damage_reduction"`, `effect_mult: 0.10`) |
