# Implementation Plan: Damage Reflect

**Branch**: `081-damage-reflect` | **Date**: 2026-03-21 | **Spec**: [spec.md](spec.md)

## Summary

Add a reflect mechanic that automatically deals a percentage of incoming direct-hit damage back to the attacker. Reflect is a stat on `StatsComponent` — sourced from `EnemyData` for enemies and from relic addends for the player. A new Thorn Bark relic (forest domain, `deck_count: 2`) activates player reflect and stacks additively with additional copies.

## Technical Context

**Language/Version**: GDScript (Godot 4.6, static typing)
**Primary Dependencies**: Existing `StatsComponent`, `CombatComponent`, `Enemy`, `RelicManagerImpl`
**Storage**: `data/enemies.json`, `data/relics.json`
**Testing**: Manual in-editor; unit tests in `tests/unit/`
**Target Platform**: Android mobile portrait; Windows dev
**Performance Goals**: 60 fps mobile — reflect is a single synchronous damage call per hit, negligible cost
**Constraints**: Reflect must not chain; must not fire on DoT (`take_damage_raw` path); must respect attacker's invincibility frames and damage reduction

## Constitution Check

- **I. Single Responsibility** ✅ — Reflect logic lives entirely in `StatsComponent.take_damage()`. No new autoloads. No new managers.
- **II. Data-Driven Content** ✅ — `reflect_amount` for enemies lives in `enemies.json`; relic values in `relics.json`. No balance constants in GDScript.
- **III. Mobile-First** ✅ — One synchronous `take_damage()` call per hit. Zero per-frame overhead when reflect_amount is 0.
- **IV. Editor-Centric** ✅ — No `.tscn` edits. No hardcoded `$NodeName` paths introduced.
- **V. Simplicity & YAGNI** ✅ — Reflect reuses existing `take_damage()` plumbing. No new base classes or utility layers.
- **VI. Early Return** ✅ — Reflect block in `take_damage()` is guarded by early-return conditions before the reflect call.

## Decisions

**D-001 — Chain prevention via null attacker**: `take_damage()` gains an optional `attacker: StatsComponent = null` parameter. When reflect fires, it calls `attacker.take_damage(reflect_dmg)` without forwarding self — attacker is null on that call, so reflect is skipped. No boolean flag needed.

**D-002 — Reflect fires on effective (post-DR) damage**: The reflected amount is `floori(effective_damage × reflect_amount)`, where `effective_damage` is already reduced by the receiver's DR. This means a tanky enemy with high DR reflects less damage, which is the correct balance behaviour.

**D-003 — Thorn Bark uses `compute_stat_addend` path**: `effect_stat: "reflect_amount"`, `effect_mult: 0.15`. `RelicManager.get_stat_addend("reflect_amount")` already works for any stat string — no new autoload method needed. Multiple copies stack because `active_relic_ids` allows duplicates and `compute_stat_addend` sums all matching entries. Standard deck draws do not filter by held relic IDs, so re-offering Thorn Bark is already the default behaviour — no code change required.

## Schema Changes

**`data/relics.json`** — add one entry under the `forest` domain key:
```
"thorn_bark": {
  "name": "Thorn Bark",
  "tier": "common",
  "tags": [],
  "effect_stat": "reflect_amount",
  "effect_mult": 0.15,
  "description": "Reflect 15% of incoming damage back to attackers.",
  "deck_count": 2
}
```

**`data/enemies.json`** — add `"reflect_amount": 0.0` to all existing enemy entries (default, no behavioural change). Set a non-zero value on the specific enemy/enemies designated to have reflect. No enemies currently have reflect — one can be given a value at design discretion (e.g., 0.20) to demonstrate the mechanic.

**`scripts/data_models/EnemyData.gd`** — add `var reflect_amount: float = 0.0`; parse with `float(data.get("reflect_amount", 0.0))` in `from_dict()`.

## Affected Files

**`data/relics.json`** — New Thorn Bark entry added under `"forest"` domain. `effect_stat: "reflect_amount"`, `effect_mult: 0.15`, `deck_count: 2`.

**`data/enemies.json`** — `reflect_amount` field added to all enemy entries. At least one enemy (design choice) receives a non-zero value to exercise the mechanic.

**`scripts/data_models/EnemyData.gd`** — New `reflect_amount: float = 0.0` field; `from_dict()` reads it from JSON.

**`scenes/player/components/StatsComponent.gd`** — New `var reflect_amount: float = 0.0` property. `take_damage(amount: float, attacker: StatsComponent = null)` gains the optional attacker parameter. After computing and applying `effective_damage`, if `reflect_amount > 0.0` and `attacker != null` and `not attacker.is_invulnerable`, call `attacker.take_damage(floori(effective_damage * reflect_amount))` with no attacker argument (null, preventing chain). `_on_relic_applied()` gains a line to recompute `reflect_amount` from `RelicManager.get_stat_addend("reflect_amount")` — player-only path, already gated by `is_player` inside that function.

**`scenes/combat/enemies/Enemy.gd`** — `take_damage(amount: float)` gains an optional `attacker: StatsComponent = null` parameter and forwards it to `_stats.take_damage(amount, attacker)`. In `_setup(data)`, `_stats.reflect_amount` is set from `data.reflect_amount`. The contact-damage call `_player_stats.take_damage(damage * mult)` is updated to `_player_stats.take_damage(damage * mult, _stats)` so the player's reflect can fire back at the enemy.

**`scenes/player/components/CombatComponent.gd`** — The melee hit call `target.take_damage(dmg)` is updated to `target.take_damage(dmg, _stats_component)` so the enemy's reflect can fire back at the player.

**`scenes/combat/projectiles/Projectile.gd`** — `setup()` gains a final optional parameter `attacker_stats: StatsComponent = null`, stored as `_attacker_stats`. Both `primary.take_damage(_damage)` and the chain-target call are updated to pass `_attacker_stats`, so enemy reflect can fire back at the player on projectile hits.

**`scenes/player/components/SkillComponent.gd`** — The `projectile.setup(...)` call is updated to pass `_combat_component._stats_component` as the new `attacker_stats` argument.
