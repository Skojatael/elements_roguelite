# Research: 053-magic-missile-chain

## Existing Magic Missile Damage Pipeline

**Decision**: Extend the existing `Projectile.setup()` signature to carry `chain_damage_mult`; store it; apply in `_on_body_entered()` via a new `_try_chain()` helper.

**Rationale**: Damage is pre-computed in `SkillComponent` at fire time and passed as a float to `Projectile.setup()`. The same fire-time value is reused for the chain hit (scaled by `chain_damage_mult`). No recomputation needed at impact time. This is consistent with how `_damage` already flows — one source of truth per shot.

**Alternative rejected**: Reading `chain_damage_mult` from `ResourceManager` inside `Projectile._on_body_entered()` directly. Rejected because it couples the projectile to the resource-loading layer without gain — the value is fixed per skill and is already known when the projectile is spawned.

---

## Enemy Discovery at Hit Time

**Decision**: `Projectile._try_chain()` iterates `RunManager.current_room.get_parent().get_children()`, checking `is Enemy` and `is_instance_valid()` — the same pattern as `SkillComponent._find_closest_enemy()`.

**Rationale**: Enemies are not registered in a Godot group. The existing pattern in `SkillComponent` (lines 85–98) iterates the room node's children with a type check. No infrastructure change needed; reusing the pattern is correct.

**Alternative rejected**: Adding enemies to a group (`add_to_group("enemies")`) and querying via `get_tree()`. This would work but touches `Enemy.gd` and is a separate architectural decision beyond this feature's scope (YAGNI, Principle V).

---

## Conditional Relic Pattern

**Decision**: `chaining_stone` follows the same conditional-relic pattern as `executioners_mark` and `berserker_stone`: `effect_stat: ""`, `effect_mult: 1.0` in JSON; logic gated by an `active_relic_ids.has()` check in `RelicManagerImpl`.

**Rationale**: `compute_stat_mult()` ignores entries with `effect_stat: ""`, which is the correct behaviour — the relic doesn't modify a numeric stat, it enables a behaviour. Existing pattern already handles this cleanly with no special-casing needed.

**New query method**: `has_chain_relic() -> bool` on both `RelicManagerImpl` and `RelicManager` (thin-wrapper delegation, Principle I).

**Alternative rejected**: Reusing `get_hit_damage_mult()` to encode chain activation. Rejected because chain activation is not a damage multiplier — it's a structural behaviour change. Conflating the two would violate SRP.

---

## SkillData Model

**Finding**: `scripts/data_models/SkillData.gd` is an empty stub (not used). `SkillComponent._load_skill_data()` reads raw dictionary fields from `ResourceManager.get_skills()` inline. No typed wrapper is active.

**Decision**: Add `_chain_damage_mult: float` as a plain instance variable on `SkillComponent`, populated in `_load_skill_data()` via `entry.get("chain_damage_mult", 1.0)`. Default `1.0` chosen so missing-key behaviour applies full damage rather than zeroing it (safe fallback).

**Rationale**: Matching the existing inline-read pattern in `_load_skill_data()` keeps the change minimal and consistent. Introducing a typed SkillData model now would be a speculative abstraction with no second caller (Principle V).

---

## queue_free() Ordering

**Finding**: `Projectile._on_body_entered()` calls `queue_free()` immediately after `take_damage()`. `queue_free()` defers node removal to end-of-frame, so the projectile node remains valid for the rest of the current call. Chain logic can safely run between `take_damage()` and `queue_free()`.

**Decision**: Call `_try_chain(primary)` before `queue_free()`.

---

## Resolved Unknowns

| Unknown | Resolution |
|---------|-----------|
| How does projectile find other enemies? | Iterate `RunManager.current_room.get_parent().get_children()`, `is Enemy` type check |
| Does chain re-check HP ratios for Executioner's Mark? | Yes — `take_damage()` is called directly; Executioner's Mark is applied at damage-receive time inside `Enemy`, not at hit time on `CombatComponent`. Chain receives no explicit bonus, but FR-005 scope only requires `_damage * chain_damage_mult` |
| Is `SkillData.gd` used? | No — empty stub; not referenced by SkillComponent |
| Default for missing `chain_damage_mult` key? | `1.0` (full damage) — safe fallback; actual JSON will always have `0.5` |
