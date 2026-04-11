# Tasks: Damage Reflect

**Input**: Design documents from `/specs/081-damage-reflect/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)

---

## Phase 1: Setup

No project initialization required — this feature extends existing systems only.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The reflect logic in `StatsComponent` underpins both US1 (player reflect) and US2 (enemy reflect). Must be complete before any story work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [x] T001 Add `var reflect_amount: float = 0.0` field to `scenes/player/components/StatsComponent.gd` (no logic yet — field declaration only)
- [x] T002 Update `StatsComponent.take_damage(amount: float)` in `scenes/player/components/StatsComponent.gd` to accept an optional second parameter `attacker: StatsComponent = null`; after `effective` damage is applied, guard-return if `reflect_amount <= 0.0` or `attacker == null`; otherwise call `attacker.take_damage(floori(effective * reflect_amount))` with no attacker argument (null = chain guard)
- [x] T003 Create unit test `tests/unit/test_reflect_mechanic.gd` covering: (a) reflect fires when reflect_amount > 0 and attacker is non-null, dealing `floori(effective * reflect_amount)` damage to attacker; (b) reflect does not fire when attacker is null; (c) reflect does not chain — calling take_damage with a null attacker on a StatsComponent that itself has reflect_amount > 0 does not trigger a second reflect; use inline StatsComponent instances, no autoloads

**Checkpoint**: `StatsComponent.take_damage()` reflect logic is in place and unit-tested. User story work can now begin.

---

## Phase 3: User Story 1 — Player Equips Reflect Relic (Priority: P1) 🎯 MVP

**Goal**: Player acquires Thorn Bark relic; any enemy that hits the player automatically receives 15% of the dealt damage back.

**Independent Test**: In-editor: run a room, pick Thorn Bark from relic offer (or assign directly via DevPanel), take a hit from a standard enemy, confirm the enemy's HP drops by `floori(damage_dealt * 0.15)`.

- [x] T004 [P] [US1] Add `"reflect_amount": 0.0` field to every enemy entry in `data/enemies.json` (all existing enemies — slime, skeleton, boss, etc.)
- [x] T005 [P] [US1] Add `var reflect_amount: float = 0.0` to `scripts/data_models/EnemyData.gd` and parse it in `from_dict()` with `float(data.get("reflect_amount", 0.0))`
- [x] T006 [US1] In `scenes/combat/enemies/Enemy.gd` `_setup(data: EnemyData)`, add assignment `_stats.reflect_amount = _data.reflect_amount` alongside the existing `_stats.damage_reduction = data.damage_reduction` line (depends on T005)
- [x] T007 [US1] In `scenes/combat/enemies/Enemy.gd` `_process()`, update the contact-damage call from `_player_stats.take_damage(_data.damage * ...)` to `_player_stats.take_damage(_data.damage * ..., _stats)` so the player's reflect can fire back at the enemy (depends on T006)
- [x] T008 [P] [US1] In `scenes/player/components/StatsComponent.gd` `_on_relic_applied()`, add `reflect_amount = RelicManager.get_stat_addend("reflect_amount")` after the existing `damage_reduction` recompute line (this is inside the `is_player` branch — no change needed to the guard)
- [x] T009 [P] [US1] Add `thorn_bark` entry to `data/relics.json` under the `"forest"` domain key: `"name": "Thorn Bark"`, `"tier": "common"`, `"tags": []`, `"effect_stat": "reflect_amount"`, `"effect_mult": 0.15`, `"description": "Reflect 15% of incoming damage back to attackers."`, `"deck_count": 2`

**Checkpoint**: Player can equip Thorn Bark and enemies take reflected damage on hit. Verify: equip relic, take damage, check enemy HP. US1 fully functional.

---

## Phase 4: User Story 2 — Enemy Has Reflect Stat (Priority: P2)

**Goal**: Designated enemies have a non-zero `reflect_amount`; the player takes back a fraction of every hit dealt to them.

**Independent Test**: In-editor: enter a room containing a reflect-capable enemy, attack it with melee and a projectile, confirm player HP drops by `floori(damage_dealt * enemy_reflect_amount)` per hit. Confirm no freeze or damage loop with Thorn Bark also equipped.

- [x] T010 [P] [US2] In `data/enemies.json`, set `"reflect_amount": 0.20` (or design-chosen value) on the enemy/enemies designated to reflect; all others remain 0.0 (depends on T004)
- [x] T011 [US2] Update `Enemy.take_damage(amount: float)` in `scenes/combat/enemies/Enemy.gd` to `take_damage(amount: float, attacker: StatsComponent = null)` and forward both args to `_stats.take_damage(amount, attacker)`
- [x] T012 [P] [US2] In `scenes/player/components/CombatComponent.gd`, update `target.take_damage(dmg)` to `target.take_damage(dmg, _stats_component)` (depends on T011)
- [x] T013 [P] [US2] In `scenes/combat/projectiles/Projectile.gd`, add `attacker_stats: StatsComponent = null` as the final parameter of `setup()`, store as `var _attacker_stats: StatsComponent`; update `primary.take_damage(_damage)` to `primary.take_damage(_damage, _attacker_stats)` and the chain-target call similarly (depends on T011)
- [x] T014 [US2] In `scenes/player/components/SkillComponent.gd`, update the `projectile.setup(...)` call to pass `_combat_component._stats_component` as the final `attacker_stats` argument (depends on T013)

**Checkpoint**: Reflect-capable enemies cause the player to lose HP on each direct hit. Verify both melee and projectile paths. Verify no chain loop when player also has Thorn Bark. US2 fully functional.

---

## Phase 5: User Story 3 — Relic Available in Forest Domain Offers (Priority: P3)

**Goal**: Thorn Bark appears in relic offer draws for the forest domain at a common-tier frequency; it can be offered again even if already held.

**Independent Test**: Trigger relic offer draws with the forest domain unlocked; confirm Thorn Bark appears across repeated draws and is not suppressed when already held.

- [x] T015 [US3] Verify `data/relics.json` `thorn_bark` entry (added in T009): confirm `deck_count: 2`, entry is under `"forest"` domain key, no tag that would cause `_is_relic_eligible()` to filter it, no held-ID exclusion in `_build_expanded_deck()` — no code changes expected; this is a validation task confirming acquisition completeness

**Checkpoint**: Forest domain offers can surface Thorn Bark. Confirm by running `RelicManagerImpl.build_pool()` with forest_domain_unlocked=true and inspecting the built deck.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [x] T016 [P] Update `repo_map.md` entry for `StatsComponent` to include `reflect_amount: float` in its properties list and the updated `take_damage()` signature
- [x] T017 [P] Update `repo_map.md` entry for `EnemyData` to include `reflect_amount: float = 0.0`
- [x] T018 [P] Update `repo_map.md` entry for `Projectile` to include `attacker_stats` in its `setup()` signature
- [ ] T019 Manual end-to-end validation: (a) equip Thorn Bark, take three enemy hits, confirm enemy HP decrements by reflect each time; (b) attack a reflect enemy with melee and skill projectile, confirm player HP loss matches `floori(dmg * reflect_amount)` both times; (c) equip Thorn Bark AND attack a reflect enemy — confirm no infinite loop, both players take one level of reflect each; (d) confirm poison/burn ticks do not trigger reflect

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately. **BLOCKS all user stories.**
- **US1 (Phase 3)**: Depends on Phase 2 (T001, T002). Tasks T004, T005, T008, T009 are parallel; T006 depends on T005; T007 depends on T006.
- **US2 (Phase 4)**: Depends on Phase 2. T010 depends on T004 (from US1). T011 is entry point; T012 and T013 depend on T011; T014 depends on T013.
- **US3 (Phase 5)**: Depends on T009 (from US1) — validation only.
- **Polish (Phase 6)**: Depends on all story phases.

### User Story Dependencies

- **US1 (P1)**: Requires Phase 2 complete. No dependency on US2 or US3.
- **US2 (P2)**: Requires Phase 2 complete. Shares T004/T005 data changes with US1 (do US1 first or run T004/T005 as shared setup). Enemy.take_damage() forwarding (T011) is US2-only.
- **US3 (P3)**: Requires T009 from US1. Validation only — no new code.

### Parallel Opportunities Within US1

```
T004 (enemies.json field) ─┐
T005 (EnemyData.gd field)  ├── can run in parallel
T008 (StatsComponent relic ┘
     recompute)
T009 (relics.json thorn_bark)

T006 (Enemy._setup wire) → T007 (Enemy contact-damage attacker arg)
```

### Parallel Opportunities Within US2

```
T011 (Enemy.take_damage sig) is the entry point:
  T012 (CombatComponent) ─┐
  T013 (Projectile)        ├── parallel after T011
                           └── T014 (SkillComponent) depends on T013
T010 (enemies.json non-zero) — parallel to all T011-T014
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 2: Foundational (T001–T003)
2. Complete Phase 3: US1 (T004–T009)
3. **STOP and VALIDATE**: Player reflect works end-to-end with Thorn Bark
4. Ship US1 as standalone feature

### Incremental Delivery

1. Phase 2 → Phase 3 (US1) → Validate → player reflect live
2. Phase 4 (US2) → Validate → enemy reflect live
3. Phase 5 (US3 validation) → confirm forest domain acquisition
4. Phase 6 → repo_map cleanup

---

## Notes

- T003 unit test should use inline `StatsComponent.new()` instances — `StatsComponent` has `is_player` which gates relic recompute, but the reflect logic in `take_damage()` has no autoload dependency and is fully unit-testable
- T007 and T011 both modify `Enemy.gd` — do them in that order (T007 first for US1, T011 for US2) to avoid conflicts
- Thorn Bark `deck_count: 2` matches existing common-tier relics (several existing forest relics also use deck_count 2); rare relics typically use deck_count 1
- No new autoloads, managers, or scenes required — all changes are to existing files
