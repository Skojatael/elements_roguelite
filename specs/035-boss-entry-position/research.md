# Research: Boss Entry Position

**Feature**: 035-boss-entry-position
**Date**: 2026-03-07

## Finding 1 — Current player placement in boss teleport

**Decision**: Player is currently placed at `BOSS_ROOM_WORLD_POS` (the boss room origin, `Vector2(0, -3000)`).

**Location**: `scenes/core/main.gd`, line 233:
```gdscript
_player.global_position = BOSS_ROOM_WORLD_POS
```

**Change required**: Replace with `BOSS_ROOM_WORLD_POS + Vector2(0.0, 400.0)`.

---

## Finding 2 — Entry path coverage

All three entry paths (HUD teleport button, hub boss-run shortcut, dev panel shortcut) converge on `_on_boss_teleport_pressed()` in `main.gd`:

- HUD button → `_exploration_hud.boss_teleport_pressed` → `_on_boss_teleport_pressed()`
- Hub boss-run → `_on_hub_boss_run_pressed()` → calls `_on_boss_teleport_pressed()`
- Dev panel → `_on_dev_start_boss()` → calls `_on_boss_teleport_pressed()`

A single change to the player position line in `_on_boss_teleport_pressed()` covers all three paths.

---

## Finding 3 — Constant vs inline value

**Decision**: Introduce a named constant `BOSS_PLAYER_SPAWN_OFFSET: Vector2 = Vector2(0.0, 400.0)` in `main.gd`, following the existing pattern of `BOSS_ROOM_WORLD_POS`.

**Rationale**: Layout/structural positional constants in this project are already hardcoded (`BOSS_ROOM_WORLD_POS`, `ENTRY_OFFSET`, `SPACING_X`, `SPACING_Y`). These are not balance/content values (Principle II only prohibits hardcoded enemy stats, skill values, dungeon parameters, or upgrade costs). A named constant self-documents intent and matches established convention.

**Alternatives considered**:
- Inline `Vector2(0.0, 400.0)`: works, but magic number with no context.
- JSON in `dungeon_config.json`: over-engineering for a fixed UX layout position (YAGNI — Principle V).

---

## Finding 4 — Camera remains unchanged

The camera is set to `BOSS_ROOM_WORLD_POS` on the same function (line 234). This should NOT change — the room center is the correct camera target. The player offset is relative to the room origin but the camera stays centered on it, which is the desired framing.

---

## Summary

Single change: `_player.global_position = BOSS_ROOM_WORLD_POS` → `_player.global_position = BOSS_ROOM_WORLD_POS + BOSS_PLAYER_SPAWN_OFFSET`.
New constant: `const BOSS_PLAYER_SPAWN_OFFSET: Vector2 = Vector2(0.0, 400.0)`.
File touched: `scenes/core/main.gd` only.
