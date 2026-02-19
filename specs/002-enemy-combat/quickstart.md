# Quickstart: Enemy Combat System Validation

**Feature**: `002-enemy-combat`
**Date**: 2026-02-19
**Prerequisites**: Feature fully implemented per tasks.md

---

## Setup

1. Open `project.godot` in Godot 4.6.
2. Confirm `Project → Project Settings → Input Devices → Pointing → Emulate Touch From Mouse` is enabled.
3. Set the main scene to `scenes/core/Main.tscn` (or a dedicated test scene with one enemy pre-placed).

---

## Validation Steps

### Step 1 — Enemy Loads from Data (FR-009, US4)

1. Open `data/enemies.json` and confirm at least one enemy type entry exists with all required fields.
2. Run the project and open the Godot Output panel.
3. **Expected**: No errors referencing `EnemyData` or `enemies.json`. Enemy node initialises without assertion failures.

### Step 2 — Enemy Takes Damage and Dies (FR-001, FR-002, FR-003, US1)

1. Run the project and position the player so CombatComponent's `AttackArea` overlaps the enemy.
2. Wait several attack intervals.
3. **Expected**: After enough hits matching `enemy.max_health / attack_damage`, the enemy disappears from the scene. No error in Output.

### Step 3 — Player Takes Contact Damage (FR-004, FR-005, US2)

1. Run the project and walk the player into a stationary enemy.
2. Observe player health (if a health display exists) or add a `print(stats.current_health)` temporarily.
3. **Expected**: Player health decreases by `enemy.damage` no more than once per `damage_cooldown` seconds. Health does not drop below 0.

### Step 4 — Run Ends on Player Death (FR-006, US2)

1. Set `StatsComponent.max_health` to a small value (e.g., `3`) temporarily via the Inspector.
2. Walk the player into an enemy and wait.
3. **Expected**: When health reaches 0, `GlobalSignals.gameplay_ended` fires and the HUD hides (ExplorationHUD responds to `gameplay_ended`).

### Step 5 — Enemy Pursues and Stops (FR-007, FR-008, US3)

1. Place the enemy far from the player's start position (outside detection range).
2. Run the project and move the player toward the enemy slowly.
3. **Expected**: Enemy remains stationary until the player crosses `detection_range`. Enemy then moves toward the player.
4. Move the player away beyond `detection_range`.
5. **Expected**: Enemy stops moving and remains idle.

### Step 6 — Multiple Enemies (FR-010, SC-004)

1. Place 10 enemies pre-positioned in the room.
2. Run the project on device or in editor.
3. **Expected**: All 10 enemies track the player independently; no visible frame-rate drop; defeating one does not affect others.

### Step 7 — Data-Driven Stats (SC-005, US4)

1. Stop the project. Open `data/enemies.json` and change `"max_health"` from `3.0` to `5.0`.
2. Re-run the project and repeat Step 2.
3. **Expected**: Enemy now requires 5 hits to defeat (with `attack_damage = 1.0`). No code was changed.

---

## Acceptance Checklist

- [ ] Enemy initialises from `enemies.json` without errors
- [ ] Enemy dies after `max_health / attack_damage` hits and is removed from the scene
- [ ] Player health decreases on enemy contact, respecting the damage cooldown
- [ ] Player health reaching 0 triggers `GlobalSignals.gameplay_ended`
- [ ] Enemy pursuit activates on player entry and deactivates on player exit from detection range
- [ ] 10 simultaneous enemies perform without visible slowdown
- [ ] Editing `enemies.json` stats is reflected in the next run with no code changes
