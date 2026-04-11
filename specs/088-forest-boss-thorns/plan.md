# Implementation Plan: Forest Boss — Thornback Charger (088)

## Decisions

### D1 — ForestBossThorns extends Enemy, not CharacterBody2D
`RoomSpawner` always calls `ENEMY_SCENE.instantiate()` and types the result as `Enemy`. All three spawn paths (`_spawn_band_wave`, `_spawn_enemies_legacy`, legacy wave) share this pattern. Therefore `ForestBossThorns` must extend `Enemy` so RoomSpawner can handle it as an `Enemy` instance and connect `defeated` / call `apply_difficulty()` without changes to those call-sites.

No logic is added to `Enemy.gd`. The boss overrides `_physics_process`, `_on_detected`, `_on_lost`, `_on_died`, and `_on_shield_broken` entirely.

### D2 — Scene dispatch via scene_path in enemies.json
`RoomSpawner` currently hardcodes `ENEMY_SCENE` for every spawn. To allow the boss to use its own scene (`ForestBossThorns.tscn`) without hardcoding enemy IDs in `RoomSpawner`, a `scene_path` optional field is added to `enemies.json` and `EnemyData`. A new helper `_get_scene_for_enemy(id) -> PackedScene` in `RoomSpawner` returns `load(data["scene_path"])` if set, otherwise `ENEMY_SCENE`. All three spawn paths use this helper.

### D3 — Phase thresholds are constants in ForestBossThorns.gd
The two transition thresholds (0.667 and 0.333) are fixed game-design values, not per-enemy tuning knobs, so they are declared as script constants (`PHASE2_THRESHOLD = 0.667`, `PHASE3_THRESHOLD = 0.333`). All other timing/damage values remain in enemies.json.

### D4 — PHASE_TRANSITION is a timed pause, not a new coroutine
The 1.0 s freeze uses a `_transition_timer` float decremented in `_physics_process`, keeping the code in a single update function. No coroutines or Timers needed.

### D5 — Thorns interrupt handling
THORNS_ACTIVE is interrupted by shield break (`_on_shield_broken` enters STUNNED regardless of current state) or death (`_on_died`). Normal damage does not interrupt it. This is consistent with FR20 and uses the existing `_on_shield_broken` override.

---

## Schema Changes

### enemies.json — `boss.forest.forest_boss_thorns`
Six new tuning fields and one scene dispatch field are added to the existing entry. All are optional with defaults in `EnemyData.from_dict`.

| Field | Value | Purpose |
|---|---|---|
| `scene_path` | `"res://scenes/combat/enemies/ForestBossThorns.tscn"` | Tells RoomSpawner to load the boss scene |
| `thorns_reflect_amount_p2` | `0.3` | Reflect fraction in THORNS_ACTIVE phase 2 |
| `thorns_reflect_amount_p3` | `0.5` | Reflect fraction in THORNS_ACTIVE phase 3 |
| `thorns_duration` | `3.0` | Seconds THORNS_ACTIVE lasts (both phases) |
| `thorns_cooldown_p2` | `10.0` | Cooldown between THORNS_ACTIVE windows in phase 2 |
| `thorns_cooldown_p3` | `6.0` | Cooldown between THORNS_ACTIVE windows in phase 3 |
| `recover_duration` | `0.6` | Seconds boss pauses in RECOVER after a charge |

### EnemyData.gd
Seven new optional fields are appended to the class and populated with defaults in `from_dict`. All non-boss enemies omit these fields, so defaults apply and existing behaviour is unaffected.

---

## Affected Files

### `data/enemies.json` — modified (lines ~119–136)
Add `scene_path` plus six thorns/recover fields to the `forest_boss_thorns` entry.

### `scripts/data_models/EnemyData.gd` — modified (lines 31–88)
Append seven new `var` declarations (`scene_path`, `thorns_reflect_amount_p2`, `thorns_reflect_amount_p3`, `thorns_duration`, `thorns_cooldown_p2`, `thorns_cooldown_p3`, `recover_duration`) and their corresponding `.get()` lines in `from_dict`.

### `scripts/dungeon/RoomSpawner.gd` — modified (lines 391–432)
Add private helper `_get_scene_for_enemy(enemy_id: String) -> PackedScene` that reads `ResourceManager.get_enemy_data(enemy_id)`, checks for `scene_path`, and returns the loaded scene or `ENEMY_SCENE` as fallback. Replace the three direct `ENEMY_SCENE.instantiate()` calls in `_spawn_band_wave` (line 343), the legacy wave path (line 391), and `_spawn_enemies_legacy` (line 422) with calls to this helper.

### `scenes/combat/enemies/ForestBossThorns.gd` — NEW
Boss script extending `Enemy`. Declares `enum BossState { IDLE, CHASE, WINDUP_CHARGE, CHARGING, RECOVER, THORNS_ACTIVE, PHASE_TRANSITION, STUNNED, DEAD }` and `_boss_state: BossState`. Overrides `_physics_process` with a full nine-state dispatch. Inherits `initialize`, `take_damage`, `activate_shield`, `apply_difficulty`, contact/detection area wiring, and HP bar setup from `Enemy` — none of those methods need changes. Overrides `_on_detected` (→ CHASE), `_on_lost` (→ IDLE), `_on_shield_broken` (→ STUNNED regardless of current state), and `_on_died` (→ DEAD, emits `defeated`, queues free). State-local timers (`_charge_cooldown`, `_telegraph_timer`, `_recover_timer`, `_transition_timer`, `_thorns_timer`, `_thorns_cooldown_remaining`) are `float` vars ticked in `_physics_process`. Phase tracking uses `_phase: int` (starts at 1) and two guard bools `_phase2_triggered`, `_phase3_triggered`. Telegraph and thorns visuals are ColorRect children added/removed dynamically (same pattern as `Enemy._start_charge_telegraph`).

### `scenes/combat/enemies/ForestBossThorns.tscn` — NEW (Editor task)
Scene inheriting or mirroring `Enemy.tscn` structure, with the root script replaced by `ForestBossThorns.gd`. Must have: `StatsComponent` child, `ContactArea` (Area2D + CollisionShape2D), `DetectionArea` (Area2D + CollisionShape2D), `ColorRect` visual, `HPBar` export assigned. Spawned by `RoomSpawner` when `scene_path` resolves to this file.

---

## No constitution violations
No new autoloads. No new cross-system patterns. No new scene types beyond a single enemy subclass. Thin-wrapper rule unaffected.
