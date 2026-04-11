# Feature Specification: Forest Boss — Thornback Charger

**Feature ID**: 088
**Feature Name**: forest-boss-thorns
**Status**: Draft
**Created**: 2026-03-29

---

## Overview

Implement the full combat behaviour for `forest_boss_thorns` ("Thornback Charger") as a **dedicated script `ForestBossThorns.gd`**, separate from `Enemy.gd`. The boss has a nine-state machine and three phases. Phase 1 (100–67% HP) focuses on charge attacks and a shield mechanic. Phase 2 (66–34% HP) and Phase 3 (33–0% HP) both add periodic THORNS_ACTIVE windows that temporarily reflect incoming damage, with Phase 3 increasing intensity.

---

## User Scenarios

### US1 — Player enters forest boss room
1. Player teleports to the boss room.
2. Boss begins in IDLE until the player enters detection range.
3. Boss transitions to CHASE and moves toward the player.

### US2 — Charge attack loop (Phase 1)
1. After a cooldown expires while chasing, boss enters WINDUP_CHARGE and telegraphs direction.
2. Boss enters CHARGING: fast linear movement in the locked direction.
3. Charge ends when distance is exhausted or a wall is hit; boss enters RECOVER briefly.
4. RECOVER ends; boss returns to CHASE (or transitions to PHASE_TRANSITION if HP threshold crossed).

### US3 — Shield break and stun
1. Boss spawns with a shield (`shield_hp`). While the shield is active, damage is absorbed by it.
2. When shield HP reaches 0 the shield breaks and the boss enters STUNNED for `shield_stun_duration`.
3. While STUNNED the boss is immobile and takes full damage.
4. STUNNED timer expires; boss returns to CHASE.

### US4 — Phase transitions
1. Boss HP drops to ≤ 67% for the first time — PHASE_TRANSITION fires; boss enters Phase 2.
2. Boss HP later drops to ≤ 33% for the first time — PHASE_TRANSITION fires again; boss enters Phase 3.
3. Each transition: boss briefly freezes with a visual flash, then returns to CHASE with updated behaviour.

### US5 — Thorns active window (Phases 2 and 3)
1. From Phase 2 onward, on a separate cooldown, boss enters THORNS_ACTIVE.
2. During THORNS_ACTIVE the boss's `reflect_amount` is elevated — damage dealt to the boss is partially reflected to the player.
3. A visual cue shows thorns are active.
4. After a fixed duration, THORNS_ACTIVE ends and boss returns to CHASE.
5. In Phase 3 the `thorns_cooldown` is shorter and `thorns_reflect_amount` is higher than Phase 2.

### US6 — Boss death
1. Boss HP reaches 0; boss enters DEAD.
2. Existing `defeated` signal fires, triggering room-cleared and essence reward flow.

---

## Functional Requirements

### Architecture
- FR1: `forest_boss_thorns` is implemented in a **new dedicated script `ForestBossThorns.gd`** (extends `CharacterBody2D`). **No boss logic is added to `Enemy.gd`.** The script reuses `StatsComponent`, `RootComponent`, `PoisonComponent`, `HPBar`, and contact/detection `Area2D` nodes from its own scene.
- FR2: A paired scene **`ForestBossThorns.tscn`** is created in `scenes/combat/enemies/`. It is spawned by the existing `RoomSpawner` with `enemy_type_id = "forest_boss_thorns"`. The `.tres` resource for the boss room is updated to reference this scene.
- FR3: All numeric tuning values are read exclusively from `enemies.json` under `boss.forest.forest_boss_thorns` — no magic numbers in script.

### State machine
- FR4: Boss script declares `enum BossState { IDLE, CHASE, WINDUP_CHARGE, CHARGING, RECOVER, THORNS_ACTIVE, PHASE_TRANSITION, STUNNED, DEAD }`.
- FR5: Only one state is active at a time; transitions are explicit (no implicit fall-through).

### Per-state behaviour
- FR6 IDLE: Boss is stationary. Transitions to CHASE when player enters detection range.
- FR7 CHASE: Boss moves toward player at `move_speed`. Transitions to WINDUP_CHARGE when `charge_attack_cooldown` expires and player is detected.
- FR8 WINDUP_CHARGE: Boss stops moving, locks charge direction toward current player position, shows telegraph visual. After `charge_telegraph_duration` transitions to CHARGING.
- FR9 CHARGING: Boss moves at `move_speed × charge_speed_mult` along the locked direction. Deals `charge_attack_damage` on first contact with player per charge. Ends when `charge_attack_length` distance is exhausted or a wall collision is detected; transitions to RECOVER.
- FR10 RECOVER: Boss is stationary for `recover_duration`. Then transitions to CHASE (or PHASE_TRANSITION if an HP threshold was just crossed and not yet processed).
- FR11 THORNS_ACTIVE: Boss's `reflect_amount` is set to the phase-appropriate reflect value (`thorns_reflect_amount_p2` in phase 2, `thorns_reflect_amount_p3` in phase 3). Boss moves at reduced speed (50% `move_speed`). After `thorns_duration`, reflect is reset to 0 and transitions to CHASE. Only entered in phases 2 and 3, driven by a per-phase cooldown timer.
- FR12 PHASE_TRANSITION: Boss freezes for 1.0 s with a visual colour flash indicating the new phase. Increments `_phase` (1 → 2 → 3). Starts the `thorns_cooldown` timer for the new phase. Transitions to CHASE. Triggered at ≤ 67% HP (phase 2) and ≤ 33% HP (phase 3); each threshold fires exactly once (two guard flags: `_phase2_triggered`, `_phase3_triggered`).
- FR13 STUNNED: Boss is immobile and cannot attack for `shield_stun_duration`. Then transitions to CHASE.
- FR14 DEAD: `defeated` signal emitted. No further state transitions.

### Shield
- FR15: Shield is initialised to `shield_hp` at spawn. Incoming damage is applied to the shield first; any overflow goes to boss HP.
- FR16: Shield HP reaching 0 interrupts any current state (except DEAD) and forces STUNNED.
- FR17: Shield does not regenerate after breaking.
- FR18: Shield visual (existing `_shield_visual` ColorRect pattern) is shown while shield HP > 0 and hidden once broken.

### Phases 2 and 3
- FR19: Phase 2 activates once at ≤ 67% HP; Phase 3 activates once at ≤ 33% HP. Each activation starts its `thorns_cooldown` timer immediately so the boss will enter THORNS_ACTIVE after the first cooldown.
- FR20: THORNS_ACTIVE cannot be interrupted by normal damage. It can be interrupted by shield break (→ STUNNED) or death.
- FR21: Phase 3 has a shorter `thorns_cooldown` and higher `thorns_reflect_amount` than Phase 2, making the thorns window more frequent and more punishing.

### Data fields (added to enemies.json `forest_boss_thorns` entry)
| Field | Default | Purpose |
|---|---|---|
| `thorns_reflect_amount_p2` | 0.3 | Reflect fraction during THORNS_ACTIVE in phase 2 |
| `thorns_reflect_amount_p3` | 0.5 | Reflect fraction during THORNS_ACTIVE in phase 3 |
| `thorns_duration` | 3.0 | Seconds THORNS_ACTIVE lasts (both phases) |
| `thorns_cooldown_p2` | 10.0 | Seconds between THORNS_ACTIVE activations in phase 2 |
| `thorns_cooldown_p3` | 6.0 | Seconds between THORNS_ACTIVE activations in phase 3 |
| `recover_duration` | 0.6 | Seconds in RECOVER after a charge |

---

## Success Criteria

- SC1: All nine states are reachable in a single boss fight without errors.
- SC2: Charge attack deals damage to the player exactly once per charge.
- SC3: Shield absorbs damage correctly; boss enters STUNNED immediately on shield break.
- SC4: PHASE_TRANSITION fires exactly twice per fight — once at ≤ 67% HP and once at ≤ 33% HP. Neither fires more than once.
- SC5: THORNS_ACTIVE only occurs in phases 2 and 3. Phase 3 thorns activate more frequently and reflect more damage than phase 2.
- SC6: Boss death triggers `defeated` signal and the existing room-cleared / essence reward pipeline.
- SC7: No logic from `ForestBossThorns.gd` is added to `Enemy.gd`.

---

## Key Entities

| Entity | Location | Notes |
|---|---|---|
| `ForestBossThorns.gd` | `scenes/combat/enemies/` | New boss script |
| `ForestBossThorns.tscn` | `scenes/combat/enemies/` | New boss scene |
| `enemies.json` | `data/` | Add 5 new fields to `forest_boss_thorns` entry |
| `EnemyData.gd` | `scripts/data_models/` | Add optional fields: `thorns_reflect_amount_p2`, `thorns_reflect_amount_p3`, `thorns_duration`, `thorns_cooldown_p2`, `thorns_cooldown_p3`, `recover_duration` |

---

## Assumptions

- A1: `ForestBossThorns.tscn` is assigned as the scene resource in the existing forest boss room `.tres` (or a new `ForestBossRoom01.tres`); the `RoomSpawner` handles instantiation as normal.
- A2: Contact damage to the player during THORNS_ACTIVE uses the existing contact-area system; reflect is handled by the existing `StatsComponent.reflect_amount` pathway.
- A3: Charge wall detection uses `KinematicCollision2D` from `move_and_slide()` (same as `enemy-charge-attack` spec).
- A4: THORNS_ACTIVE and the charge attack are independent cooldowns; they can queue but not overlap.
- A5: The boss is not affected by root during CHARGING (same immunity rule as `enemy-charge-attack`).

---

## Out of Scope

- Second boss or other domain bosses.
- Animated sprites — visual feedback uses ColorRect colour changes as placeholder.
- Network/multiplayer considerations.
