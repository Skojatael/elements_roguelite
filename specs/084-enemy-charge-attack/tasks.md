# Tasks: Enemy Charge Attack

**Input**: Design documents from `/specs/084-enemy-charge-attack/`
**Prerequisites**: plan.md ✅, spec.md ✅

**Organization**: Tasks grouped by user story. US1 (telegraph + charge execution) is the MVP; US2 (cooldown cycling) and US3 (data-driven verification) layer on top.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to

---

## Phase 1: Setup

No new directories or project structure required — this feature adds fields and extends an existing script.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Data schema and model changes that all user stories depend on.

**⚠️ CRITICAL**: Both tasks must be complete before Enemy.gd implementation begins.

- [x] T001 [P] Add `charge_attack_damage`, `charge_attack_cooldown`, `charge_attack_length` float fields (default 0.0) to `scripts/data_models/EnemyData.gd` and parse them in `from_dict` via `data.get(key, 0.0)`
- [x] T002 [P] Add `"charge_attack_damage": 10`, `"charge_attack_cooldown": 10`, `"charge_attack_length": 10` to the `forest_boss_thorns` object in `data/enemies.json`

**Checkpoint**: `EnemyData.from_dict` can parse charge fields; `forest_boss_thorns` JSON is valid.

---

## Phase 3: User Story 1 — Enemy Telegraphs and Executes Charge (Priority: P1) 🎯 MVP

**Goal**: Enemy freezes for 2 s with a visible telegraph rectangle, then lunges at 3× speed for `charge_attack_length` pixels, dealing `charge_attack_damage` on contact, then resumes normal AI.

**Independent Test**: Place `forest_boss_thorns` in any room, wait for first charge (set `charge_attack_cooldown` to a low value in JSON temporarily). Observe: freeze → colored rectangle appears → enemy lunges through it → stops → normal movement resumes. Player hit during lunge loses HP equal to `charge_attack_damage`.

### Tests

- [x] T003 [P] [US1] Create `tests/unit/test_enemy_charge_attack.gd`: write GUT test cases verifying that `EnemyData.from_dict` correctly reads all three charge fields from an inline dict, and that an entry with no charge fields produces 0.0 defaults — run these tests first and confirm they pass before proceeding to Enemy.gd changes

### Implementation

- [x] T004 [US1] Extend `EnemyState` enum in `scenes/combat/enemies/Enemy.gd` with `TELEGRAPHING` and `CHARGING` values; add six new instance variables after the `_state` declaration: `_charge_cooldown_remaining: float`, `_telegraph_timer: float`, `_charge_direction: Vector2`, `_charge_distance_remaining: float`, `_telegraph_node: Node2D`, `_charge_hit_delivered: bool`
- [x] T005 [US1] Add `_cancel_charge()` private method to `scenes/combat/enemies/Enemy.gd`: frees `_telegraph_node` if valid (`is_instance_valid` guard), resets `_charge_direction`, `_telegraph_timer`, `_charge_distance_remaining`, `_charge_hit_delivered` to defaults, sets `_state = EnemyState.IDLE`
- [x] T006 [US1] Add `_start_charge_telegraph()` private method to `scenes/combat/enemies/Enemy.gd`: reads `px` size from `_visual.size.x`, locks `_charge_direction` to `(_player_ref.global_position - global_position).normalized()`, creates a `Node2D` added to `get_parent()`, sets its `global_position` to `self.global_position` and `rotation` to `_charge_direction.angle()`, adds a `ColorRect` child sized `Vector2(_data.charge_attack_length, px)` at local offset `Vector2(0.0, -px * 0.5)` with semi-transparent color (e.g. `Color(1, 0.3, 0.3, 0.4)`), stores the node in `_telegraph_node`, resets `_telegraph_timer = 0.0`, sets `_state = EnemyState.TELEGRAPHING`
- [x] T007 [US1] Add `_begin_charge()` private method to `scenes/combat/enemies/Enemy.gd`: sets `_charge_distance_remaining = _data.charge_attack_length`, `_charge_hit_delivered = false`, `_state = EnemyState.CHARGING` (telegraph node left alive so it remains visible during charge)
- [x] T008 [US1] Add `TELEGRAPHING` branch to `_physics_process` in `scenes/combat/enemies/Enemy.gd`: guard `if _state != EnemyState.TELEGRAPHING: …`; set `velocity = Vector2.ZERO` and call `move_and_slide()`; tick `_telegraph_timer += delta`; when `_telegraph_timer >= 2.0` call `_begin_charge()`; return early so remaining physics logic is skipped
- [x] T009 [US1] Add `CHARGING` branch to `_physics_process` in `scenes/combat/enemies/Enemy.gd`: guard `if _state != EnemyState.CHARGING: …`; set `velocity = _charge_direction * _data.move_speed * 3.0` and call `move_and_slide()`; subtract `velocity.length() * delta` from `_charge_distance_remaining`; if `_in_contact` and `_player_stats != null` and `is_instance_valid(_player_stats)` and `not _charge_hit_delivered` then call `_player_stats.take_damage(_data.charge_attack_damage, _stats)` and set `_charge_hit_delivered = true`; when `_charge_distance_remaining <= 0.0` free `_telegraph_node` if valid, reset charge fields, set `_state = EnemyState.PURSUING`; return early
- [x] T010 [US1] Update `_on_lost` callback in `scenes/combat/enemies/Enemy.gd`: before nulling `_player_ref`, if `_state == EnemyState.TELEGRAPHING or _state == EnemyState.CHARGING` call `_cancel_charge()`; ensure early return pattern is preserved

**Checkpoint**: US1 fully functional. With `charge_attack_cooldown` temporarily set to 0 in JSON, enemy immediately telegraphs and charges on player detection.

---

## Phase 4: User Story 2 — Charge Cooldown Cycles (Priority: P2)

**Goal**: Charge cooldown begins on player detection and resets after each charge, producing repeating charges throughout the encounter.

**Independent Test**: Leave `charge_attack_cooldown: 10` in JSON, enter room, observe first charge fires after ~10 s, then another after another ~10 s. Two full cycles confirm the mechanic loops correctly.

### Tests

- [x] T011 [P] [US2] Extend `tests/unit/test_enemy_charge_attack.gd` with test cases for the cooldown reset logic: given an `EnemyData` with `charge_attack_cooldown = 5.0`, verify that the field is accessible and non-zero; add a second test confirming that `charge_attack_cooldown = 0.0` (default) leaves the field at 0.0 (no-charge sentinel)

### Implementation

- [x] T012 [US2] Add cooldown tick to the `PURSUING` movement block in `_physics_process` in `scenes/combat/enemies/Enemy.gd`: after the existing PURSUING guard (around line 270), if `_data.charge_attack_cooldown > 0.0` and `is_instance_valid(_player_ref)`, decrement `_charge_cooldown_remaining -= delta`; when `_charge_cooldown_remaining <= 0.0` call `_start_charge_telegraph()` (charge fires)
- [x] T013 [US2] Update the charge completion block inside the `CHARGING` branch (added in T009) in `scenes/combat/enemies/Enemy.gd`: after setting `_state = EnemyState.PURSUING`, reset `_charge_cooldown_remaining = _data.charge_attack_cooldown` so the next cycle begins immediately

**Checkpoint**: US1 + US2 both functional. Full repeating charge cycle observable in-game.

---

## Phase 5: User Story 3 — Data-Driven Configuration Verified (Priority: P3)

**Goal**: Confirm that all three charge parameters flow end-to-end from `enemies.json` → `EnemyData` → runtime behavior for `forest_boss_thorns`, and that other enemies are unaffected.

**Independent Test**: Edit `charge_attack_damage` to 99 in JSON for `forest_boss_thorns`, confirm player takes 99 damage on charge hit. Revert. Check that a vanilla enemy (e.g. `slime`) has no charge fields in JSON and performs no charge behavior.

### Tests

- [x] T014 [P] [US3] Extend `tests/unit/test_enemy_charge_attack.gd` with a test that reads `data/enemies.json` directly (via `FileAccess`), finds `forest_boss_thorns`, and asserts `charge_attack_damage == 10`, `charge_attack_cooldown == 10`, `charge_attack_length == 10`; add a second test that finds `slime` and asserts all three charge fields are absent (defaulting to 0.0 via `EnemyData.from_dict`)

**Checkpoint**: All three user stories complete. Full feature functional and data-configurable.

---

## Phase 6: Polish & Validation

- [ ] T015 Manual editor validation: open a test room in Godot, add `forest_boss_thorns`, enter play mode, verify the full sequence — cooldown → freeze → semi-transparent rectangle appears for 2 s → enemy lunges at 3× speed → stops at rectangle edge → resumes normal AI → cycles again
- [ ] T016 Verify no charge behavior on existing enemies: confirm `slime`, `skeleton`, and any other non-charge enemy IDs in `enemies.json` lack charge fields and show no new behavior in-game

---

## Dependencies & Execution Order

### Phase Dependencies

- **Foundational (Phase 2)**: No dependencies — start immediately
- **US1 (Phase 3)**: Depends on T001, T002 (EnemyData fields + JSON data must exist before Enemy.gd references them)
- **US2 (Phase 4)**: Depends on Phase 3 complete (cooldown tick plugs into the existing PURSUING + charge completion blocks)
- **US3 (Phase 5)**: Depends on T001, T002 (data model must parse correctly); test is readable independently
- **Polish (Phase 6)**: Depends on Phases 3–5 complete

### Within Each Phase

- T001 and T002 are parallel (different files)
- T003 is parallel with T004 (different files; test file vs Enemy.gd)
- T004 → T005 → T006 → T007 → T008 → T009 → T010 are sequential (all modify Enemy.gd, each builds on the previous)
- T011 is parallel with T012 (test file vs Enemy.gd)
- T012 → T013 sequential (T013 modifies the block added by T009/T012)
- T014 is parallel with T015 (test file vs manual testing)

---

## Parallel Example: Phase 2

```
T001 — EnemyData.gd (field additions)
T002 — enemies.json (forest_boss_thorns params)
Both can be done simultaneously (different files).
```

## Parallel Example: Phase 3

```
T003 — tests/unit/test_enemy_charge_attack.gd (GUT tests for EnemyData parsing)
T004 — scenes/combat/enemies/Enemy.gd (enum + fields)
Both can start in parallel; T005 onwards wait for T004.
```

---

## Implementation Strategy

### MVP (User Story 1 Only)

1. Complete Phase 2 (T001, T002)
2. Complete Phase 3 (T003–T010)
3. **STOP and VALIDATE**: set `charge_attack_cooldown` to 2 in JSON; confirm full telegraph + charge sequence in play mode
4. Revert test value; proceed to Phase 4

### Incremental Delivery

1. Phase 2 → Foundation ready (data layer correct)
2. Phase 3 → Core charge mechanic playable (MVP)
3. Phase 4 → Cycling charges observable in long fights
4. Phase 5 → Data-driven nature verified and regression-protected by tests
5. Phase 6 → Validation complete; feature shippable

---

## Notes

- `charge_attack_cooldown == 0.0` is the opt-out sentinel — enemies without the field in JSON will never enter TELEGRAPHING/CHARGING states; the cooldown tick check guards on `> 0.0`
- Telegraph node is parented to the room (`get_parent()`), not to the enemy — it stays static while the enemy lunges through it
- One-shot charge damage uses the existing `_in_contact` / `_player_stats` contact system; the `_charge_hit_delivered` flag prevents frame-by-frame re-application
- `_cancel_charge()` fires on player-lost from any charge state — cooldown does NOT auto-reset on cancel, so the next detection restarts from `charge_attack_cooldown`
