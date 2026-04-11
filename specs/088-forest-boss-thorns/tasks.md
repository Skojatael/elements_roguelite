# Tasks: Forest Boss — Thornback Charger (088)

## Phase 1 — Foundational (blocking prerequisites)

- [x] T001 Add `scene_path`, `thorns_reflect_amount_p2`, `thorns_reflect_amount_p3`, `thorns_duration`, `thorns_cooldown_p2`, `thorns_cooldown_p3`, and `recover_duration` fields to the `forest_boss_thorns` entry in `data/enemies.json`
- [x] T002 [P] Add seven new `var` declarations (`scene_path: String`, `thorns_reflect_amount_p2: float`, `thorns_reflect_amount_p3: float`, `thorns_duration: float`, `thorns_cooldown_p2: float`, `thorns_cooldown_p3: float`, `recover_duration: float`) and their `.get()` assignments inside `static func from_dict` in `scripts/data_models/EnemyData.gd`
- [x] T003 [P] Add `tests/unit/test_forest_boss_enemy_data.gd` — GUT unit tests for the new `EnemyData.from_dict` fields: verify each new field is parsed from a full dict, defaults apply when keys are absent, and `scene_path` defaults to `""` for non-boss entries
- [x] T004 Add `func _get_scene_for_enemy(enemy_id: String) -> PackedScene` to `scripts/dungeon/RoomSpawner.gd` that calls `ResourceManager.get_enemy_data(enemy_id)`, loads `data["scene_path"]` if non-empty (returning the `PackedScene`), and falls back to `ENEMY_SCENE`; replace all three `ENEMY_SCENE.instantiate()` call-sites in `_spawn_band_wave`, the legacy wave path, and `_spawn_enemies_legacy` with calls to `_get_scene_for_enemy(resolved_id or sp.enemy_id)`

---

## Phase 2 — US1: Player enters forest boss room

- [x] T005 [US1] Create `scenes/combat/enemies/ForestBossThorns.gd` — `class_name ForestBossThorns extends Enemy`; declare `enum BossState { IDLE, CHASE, WINDUP_CHARGE, CHARGING, RECOVER, THORNS_ACTIVE, PHASE_TRANSITION, STUNNED, DEAD }` and `var _boss_state: BossState = BossState.IDLE`; declare phase tracking vars `_phase: int = 1`, `_phase2_triggered: bool = false`, `_phase3_triggered: bool = false`; declare all timer vars as floats (`_charge_cooldown`, `_telegraph_timer`, `_recover_timer`, `_transition_timer`, `_thorns_timer`, `_thorns_cooldown_remaining`); override `_ready` to call `super._ready()` then `activate_shield()`; override `_on_detected` to set `_boss_state = BossState.CHASE` and initialise `_charge_cooldown`; override `_on_lost` to set `_boss_state = BossState.IDLE`; implement `_physics_process` with a match on `_boss_state` — for now only IDLE (velocity zero) and CHASE (move toward `_player_ref` at `_data.move_speed`, tick `_charge_cooldown`)
- [ ] T006 [US1] **Editor task**: Create `scenes/combat/enemies/ForestBossThorns.tscn` in Godot editor — root node `CharacterBody2D` with script `ForestBossThorns.gd`; add child nodes matching `Enemy.tscn` structure: `StatsComponent` (Node, `StatsComponent.gd`), `ContactArea` (Area2D with `CollisionShape2D` CircleShape2D), `DetectionArea` (Area2D with `CollisionShape2D` CircleShape2D), `ColorRect` named `ColorRect`, `CollisionShape2D` on root (CircleShape2D); assign `_hp_bar` export as null (no HPBar child needed for boss, or add one if desired)

---

## Phase 3 — US2: Charge attack loop

- [x] T007 [US2] Extend `scenes/combat/enemies/ForestBossThorns.gd` — add WINDUP_CHARGE case to `_physics_process`: freeze velocity, tick `_telegraph_timer`, spawn telegraph ColorRect container (same pattern as `Enemy._start_charge_telegraph`), lock `_charge_direction` toward player, after `_data.charge_telegraph_duration` free the container and transition to CHARGING; add CHARGING case: move at `_data.move_speed * _data.charge_speed_mult` along `_charge_direction`, decrement `_charge_distance_remaining`, deliver `_data.charge_attack_damage` to `_player_stats` once per charge (`_charge_hit_delivered` flag), transition to RECOVER on distance exhaustion or `get_last_collision()` non-null; add RECOVER case: freeze, tick `_recover_timer` to `_data.recover_duration`, then transition to CHASE; in CHASE case, trigger WINDUP_CHARGE when `_charge_cooldown <= 0` and player is valid
- [x] T008 [P] [US2] Create `tests/unit/test_forest_boss_charge.gd` — GUT tests for the charge loop: verify CHASE→WINDUP_CHARGE when cooldown expires, WINDUP→CHARGING after `charge_telegraph_duration`, that `_charge_hit_delivered` prevents double-hit, and that CHARGING transitions to RECOVER when `_charge_distance_remaining` reaches zero; use inline enemy data dict with `charge_attack_cooldown`, `charge_telegraph_duration`, `charge_attack_length`, `charge_speed_mult` set to small values

---

## Phase 4 — US3: Shield break and stun

- [x] T009 [US3] Extend `scenes/combat/enemies/ForestBossThorns.gd` — override `_on_shield_broken()`: set `_boss_state = BossState.STUNNED` and `_stun_remaining = _data.shield_stun_duration`, hide `_shield_visual`; add STUNNED case to `_physics_process`: freeze velocity, decrement `_stun_remaining`, transition to CHASE when timer reaches zero
- [x] T010 [P] [US3] Create `tests/unit/test_forest_boss_shield.gd` — GUT tests: verify shield absorbs damage (HP unchanged while shield HP > 0), overflow damage passes through to HP, `_on_shield_broken` sets `_boss_state == STUNNED`, stun timer expiry transitions to CHASE; also verify STUNNED interrupts any current state (test while in CHARGING)

---

## Phase 5 — US4: Phase transitions

- [x] T011 [US4] Extend `scenes/combat/enemies/ForestBossThorns.gd` — declare constants `PHASE2_THRESHOLD := 0.667` and `PHASE3_THRESHOLD := 0.333`; add a `_check_phase_transition()` helper called from CHASE, RECOVER, and STUNNED states that reads `_stats.current_health / _stats.max_health` and, if ratio ≤ PHASE2_THRESHOLD and not `_phase2_triggered`, sets `_phase2_triggered = true`, increments `_phase` to 2, initialises `_thorns_cooldown_remaining = _data.thorns_cooldown_p2`, and enters PHASE_TRANSITION; same logic for PHASE3_THRESHOLD guarded by `_phase3_triggered`; add PHASE_TRANSITION case: freeze, apply a colour tint on `_visual` to indicate new phase, tick `_transition_timer` to 1.0 s, then restore colour and transition to CHASE
- [x] T012 [P] [US4] Create `tests/unit/test_forest_boss_phases.gd` — GUT tests: verify `_phase2_triggered` fires exactly once when HP crosses ≤ 67%, `_phase3_triggered` fires exactly once when HP crosses ≤ 33%, `_phase` increments to 2 then 3, neither guard flag allows double-fire, PHASE_TRANSITION timer returns to CHASE after 1.0 s

---

## Phase 6 — US5: Thorns active window

- [x] T013 [US5] Extend `scenes/combat/enemies/ForestBossThorns.gd` — in CHASE case, when `_phase >= 2` tick `_thorns_cooldown_remaining`; when it reaches zero enter THORNS_ACTIVE; add THORNS_ACTIVE case: set `_stats.reflect_amount` to `_data.thorns_reflect_amount_p2` if `_phase == 2` else `_data.thorns_reflect_amount_p3`, move at `_data.move_speed * 0.5` toward player, apply a visual tint to indicate thorns, tick `_thorns_timer` to `_data.thorns_duration`; on expiry reset `_stats.reflect_amount = 0.0`, clear tint, reset `_thorns_cooldown_remaining` to `_data.thorns_cooldown_p2` or `_data.thorns_cooldown_p3` based on current phase, transition to CHASE
- [x] T014 [P] [US5] Create `tests/unit/test_forest_boss_thorns_active.gd` — GUT tests: verify THORNS_ACTIVE only entered when `_phase >= 2`, phase 2 sets reflect to `thorns_reflect_amount_p2`, phase 3 sets reflect to `thorns_reflect_amount_p3`, `reflect_amount` resets to 0 after `thorns_duration`, phase 3 cooldown is shorter than phase 2

---

## Phase 7 — US6: Boss death

- [x] T015 [US6] Extend `scenes/combat/enemies/ForestBossThorns.gd` — override `_on_died()`: free telegraph node if valid, set `_boss_state = BossState.DEAD`, reset `_stats.reflect_amount = 0.0`, emit `defeated`, call `queue_free()`; add guard at the top of `_physics_process` returning immediately when `_boss_state == BossState.DEAD`; ensure `_check_phase_transition()` also returns early when DEAD

---

## Phase 8 — Polish

- [ ] T016 Manual validation: enter boss room, verify all nine states are reachable; confirm charge deals damage once per charge; confirm shield absorbs then breaks to STUNNED; confirm phase transitions fire at ≈67% and ≈33% HP exactly once each; confirm THORNS_ACTIVE only appears in phases 2 and 3; confirm boss death triggers essence reward and room-cleared flow; confirm no logic was added to `Enemy.gd`

---

## Dependencies

```
T001 → T002 → T003 (parallel)
T001 → T004
T002 → T004
T004 → T005
T005 → T006 (Editor)
T005 → T007
T007 → T008 (parallel)
T007 → T009
T009 → T010 (parallel)
T009 → T011
T011 → T012 (parallel)
T011 → T013
T013 → T014 (parallel)
T013 → T015
T015 → T016
```

## Parallel opportunities

- T002 and T003 (EnemyData changes + its test) can run in parallel with each other after T001.
- T008, T010, T012, T014 (test tasks) can each run in parallel with the next implementation task once their story's implementation task is complete.

## MVP scope

T001–T006 deliver a spawnable boss with IDLE, CHASE, and correct scene dispatch — enough to verify the boss appears in the boss room and chases the player. Each subsequent phase adds one independently testable behaviour.
