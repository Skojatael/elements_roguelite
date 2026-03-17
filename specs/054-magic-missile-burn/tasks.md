# Tasks: Magic Missile Burn

**Feature**: 054-magic-missile-burn
**Generated**: 2026-03-17
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

---

## Phase 1 — Setup (Foundational Data)

- [x] T001 Add burn_damage_per_tick, burn_duration, burn_extend_seconds to magic_missile entry in data/skills.json
- [x] T002 Add burn ("Living Ember") to uncommon tier in data/relics.json

---

## Phase 2 — User Story 1: Acquire the Living Ember Relic

**Story goal**: The relic must exist in the pool, be acquirable, and gate all burn behaviour — no relic = no burn.

**Independent test**: Pick up relic via offer screen; verify it appears in active relics list. Fire a missile without the relic — no burn applied.

- [x] T003 [US1] Add has_burn_relic() -> bool to scripts/managers/RelicManagerImpl.gd after has_chain_relic()
- [x] T004 [US1] Add has_burn_relic() -> bool thin wrapper to autoload/RelicManager.gd after has_chain_relic()
- [x] T005 [P] [US1] Add test_has_burn_relic_false_when_empty, test_has_burn_relic_true_after_pick, test_has_burn_relic_false_for_other_relic to tests/unit/test_relic_deck.gd

---

## Phase 3 — User Story 2: Burn Duration Extends on Re-hit

**Story goal**: Hitting a burning enemy with another missile extends the burn by 2s rather than resetting. First hit applies a fresh 2s burn. Burn ticks every 1s (first tick at t=1s). Kill from burn tick routes through normal kill-credit chain.

**Independent test**: With relic held, apply burn to an enemy (2s). At t=1.5s fire a second missile at same enemy. Confirm burn continues past t=2s and is still ticking at t=3s and t=4s.

- [x] T006 [US2] Create scripts/data_models/BurnEffect.gd — class_name BurnEffect extends RefCounted; fields: remaining_duration, tick_damage, _seconds_until_next_tick; implement apply(), extend(), process(), is_active() per contracts/gdscript-signatures.md
- [x] T007 [P] [US2] Create tests/unit/test_burn_effect.gd — cover: apply() sets state, first tick at t=1.0s (not 0.9s), second tick at t=2.0s, is_active() false after duration expires, extend() adds to remaining_duration, re-hit on active burn extends (no new apply), re-hit on expired burn creates fresh apply, process() returns 0.0 when inactive
- [x] T008 [US2] Add var _burn: BurnEffect = null field and on_burn_hit(tick_dmg, base_duration, extend_seconds) method to scenes/combat/enemies/Enemy.gd; add burn processing block before contact-damage block in _physics_process(delta)
- [x] T009 [US2] Add var _burn_damage_per_tick, _burn_duration, _burn_extend_seconds fields to scenes/player/components/SkillComponent.gd; read from magic_missile JSON entry in _load_skill_data(); pass to projectile.setup()
- [x] T010 [US2] Extend setup() signature in scenes/combat/projectiles/Projectile.gd to accept burn_damage_per_tick, burn_duration, burn_extend_seconds; store as fields; apply burn in _on_body_entered() after primary.take_damage(); apply burn in _try_chain() after chain_target.take_damage()

---

## Phase 4 — User Story 3: Burn Damage Scales with Attack Damage

**Story goal**: Tick damage = `attack_damage_at_application × burn_damage_per_tick`. Value captured at hit time. Changing config produces proportionally different tick damage on next launch.

**Independent test**: Set burn_damage_per_tick to a known value in skills.json; fire a missile dealing known damage; confirm each burn tick deals exactly `attack_damage × burn_damage_fraction`. Change value, verify change takes effect. Revert.

*No new code tasks — this user story is fully satisfied by the data-driven params added in T001 and the setup-time capture in T009/T010. Manual validation only (see Test Plan in plan.md: T3 and T5).*

---

## Phase 5 — Polish & Cross-Cutting

- [x] T011 Run GUT unit tests headless to confirm all BurnEffect and has_burn_relic tests pass: `Godot_v4.6.1-stable_win64.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`
- [ ] T012 Manual T1 — without relic: fire missile, confirm no burn damage after hit
- [ ] T013 Manual T2 — with relic: fire missile at one enemy, confirm HP drops at t≈1s and t≈2s post-hit
- [ ] T014 Manual T3 — with relic: fire two missiles at same enemy 1s apart, confirm burn extends past 2s
- [ ] T015 Manual T4 — enemy killed by burn tick: confirm essence drops and kill counter increments
- [ ] T016 Manual T5 — change burn_damage_per_tick to 0.20 in skills.json, verify doubled tick damage, revert

---

## Dependencies

```
T001 → T009, T010          (burn JSON fields needed before SkillComponent/Projectile reads)
T002 → (none blocking; relic pool loads at run start)
T003 → T004                (impl must exist before wrapper)
T003, T004 → T010          (has_burn_relic() must exist before Projectile calls it)
T006 → T007, T008          (BurnEffect must exist before tests reference it and Enemy uses it)
T008 → T010                (on_burn_hit() must exist before Projectile calls it)
T009 → T010                (SkillComponent setup() call must pass burn params before Projectile receives them)
T001–T010 → T011           (all code complete before regression run)
```

## Parallel Opportunities

- T005 can run in parallel with T003–T004 (test file is independent of wrapper impl)
- T007 can run in parallel with T008–T010 (pure unit tests have no scene dependency)
- T012–T016 are independent manual validations (any order)

## Implementation Strategy

MVP = T001–T010: data in JSON, relic queryable, BurnEffect pure logic, Enemy processes burn, Projectile applies on hit.
Tests = T007 (unit, automated) + T011 (regression).
Manual validation = T012–T016 (in-editor play tests).
