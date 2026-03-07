# Tasks: Boss Entry Position

**Feature**: 035-boss-entry-position
**Generated**: 2026-03-07

## Phase 1 — Core Implementation

- [x] **T001** Add `BOSS_PLAYER_SPAWN_OFFSET` constant to `main.gd` and update player placement line in `_on_boss_teleport_pressed()`.
  - File: `scenes/core/main.gd`
  - Add `const BOSS_PLAYER_SPAWN_OFFSET: Vector2 = Vector2(0.0, 400.0)` after `BOSS_ROOM_WORLD_POS`
  - Change `_player.global_position = BOSS_ROOM_WORLD_POS` → `_player.global_position = BOSS_ROOM_WORLD_POS + BOSS_PLAYER_SPAWN_OFFSET`

## Phase 2 — Validation

- [ ] **T002** Manual validation: teleport to boss room via HUD button, confirm player appears at lower-center of screen.
- [ ] **T003** Manual validation: start a boss run from hub, confirm same spawn position.
- [ ] **T004** Manual validation: use dev panel "Start Boss", confirm same spawn position.
