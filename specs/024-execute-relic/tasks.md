# Tasks: Conditional Damage Relics

**Input**: Design documents from `specs/024-execute-relic/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/interfaces.md ✅, quickstart.md ✅

---

## Phase 1: Foundational (Data + Shared Infrastructure)

**Purpose**: Prerequisites that unblock all four user stories. US1 and US3 ("collect the relic") are fully satisfied here — the existing relic offer system requires only data entries. US2 and US4 also depend on `Enemy.get_hp_ratio()` before their combat code can be written.

- [X] T001 [P] Add `executioners_mark` and `berserker_stone` entries under `"uncommon"` in `data/relics.json` (per contracts/interfaces.md — `effect_stat: ""`, `effect_mult: 1.0`, correct names and descriptions)
- [X] T002 [P] Add `get_hp_ratio() -> float` method to `scenes/combat/enemies/Enemy.gd` (returns `_stats.current_health / _stats.max_health`; returns `1.0` if `_stats.max_health <= 0.0`)

**Checkpoint**: After T001 — start a run, press "Get Relic" until Executioner's Mark or Berserker Stone appears. US1 and US3 are now independently testable. After T002 — Enemy exposes HP ratio for use by the execute check in US2.

---

## Phase 2: User Story 2 — Execute Bonus in Combat (Priority: P1) 🎯 MVP

**Goal**: Attacks against enemies below 30% HP deal 35% more damage when the execute relic is held.

**Independent Test**: Hold Executioner's Mark. Attack a full-HP enemy — damage is normal. Reduce an enemy to below 30% HP, attack again — damage is ≈1.35× baseline (visible in output log via `take_damage` print or observed damage numbers).

- [X] T003 [US2] Add `get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float) -> float` to `scripts/managers/RelicManagerImpl.gd` — implement execute check only: `if active_relic_ids.has("executioners_mark") and target_hp_ratio < 0.30: mult *= 1.35`; return `mult` (berserker check added in US4)
- [X] T004 [US2] Add delegating method `get_hit_damage_mult(target_hp_ratio: float, attacker_hp_ratio: float) -> float` to `autoload/RelicManager.gd` — returns `_impl.get_hit_damage_mult(target_hp_ratio, attacker_hp_ratio)`
- [X] T005 [US2] Update `_physics_process` in `scenes/player/components/CombatComponent.gd` — replace `(_overlapping_enemies[0] as Enemy).take_damage(attack_damage)` with: `var target: Enemy = _overlapping_enemies[0] as Enemy` / `var dmg: float = attack_damage * RelicManager.get_hit_damage_mult(target.get_hp_ratio(), 1.0)` / `target.take_damage(dmg)` (attacker_ratio hardcoded to 1.0 until US4)

**Checkpoint**: Run quickstart scenarios 1–3.

---

## Phase 3: User Story 4 — Berserker Bonus in Combat (Priority: P1)

**Goal**: All attacks deal 30% more damage when the player is below 50% HP and the berserker relic is held.

**Independent Test**: Hold Berserker Stone at full HP — damage is normal. Take damage until below 50% HP, attack — damage is ≈1.30× baseline. Heal above 50% HP, attack — damage returns to baseline.

- [X] T006 [US4] Add berserker check to `get_hit_damage_mult()` in `scripts/managers/RelicManagerImpl.gd` — append after the execute check: `if active_relic_ids.has("berserker_stone") and attacker_hp_ratio < 0.50: mult *= 1.30`
- [X] T007 [US4] Add `@onready var _stats_component: StatsComponent = $"../StatsComponent"` to `scenes/player/components/CombatComponent.gd`; update `_physics_process` to replace `1.0` with `_stats_component.current_health / _stats_component.max_health` as the attacker_ratio argument to `get_hit_damage_mult()`

**Checkpoint**: Run quickstart scenarios 4–7.

---

## Phase 4: Polish

- [ ] T008 Run all 8 quickstart scenarios from `specs/024-execute-relic/quickstart.md`

---

## Dependencies & Execution Order

- T001 and T002 are parallel (different files, no dependencies)
- T003 depends on T001 (relic IDs must exist) and T002 (Enemy.get_hp_ratio must exist)
- T004 depends on T003 (delegation target must exist)
- T005 depends on T004 (RelicManager.get_hit_damage_mult must be callable)
- T006 depends on T003 (adds to the same method body)
- T007 depends on T005 (modifies the same _physics_process block; also must be consistent with T006)
- T008 requires T001–T007 complete

---

## Implementation Strategy

1. T001 + T002 in parallel (data + Enemy method)
2. T003 → T004 → T005 (RelicManagerImpl → RelicManager → CombatComponent for execute)
3. T006 → T007 (extend impl → update CombatComponent for berserker)
4. T008 validate all 8 scenarios
