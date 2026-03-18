# Research: Boss Continue (Endless Mode)

## Overview

This feature is entirely within the existing codebase. No external libraries, APIs, or unfamiliar patterns are involved. All decisions below are resolved from reading the live source code.

---

## Decision 1: How to expose `RoomLoader._load_room` publicly

**Decision**: Add a new public method `return_to_room(room_id: String) -> void` that calls `_load_room(room_id, "")`.

**Rationale**: Caller intent (returning after boss) differs from the internal door-navigation path that also calls `_load_room`. A dedicated public method names the intent, keeps the guard (`_loading` flag) intact, and avoids exposing `entry_direction` to callers who never need it for this use case. A direct rename of `_load_room` to `load_room` would be acceptable but exposes a parameter (`entry_direction`) that the continue path never uses.

**Alternatives considered**:
- Rename `_load_room` → `load_room` and call it directly from `Main.gd` — rejected; leaks an internal parameter and widens the public surface unnecessarily.
- Store the room scene and re-add it rather than reload — rejected; scenes are `queue_free()`'d on boss teleport; no live reference survives.

---

## Decision 2: Where to store the return room ID

**Decision**: `_boss_return_room_id: String` field on `Main.gd`, set in `_on_boss_teleport_pressed()` before `free_current_room()` is called, cleared in both `_on_run_started()` and `_on_run_ended()`.

**Rationale**: `Main.gd` already owns the boss-room lifecycle (`_boss_room_spawner`, `_boss_room_node`, `_boss_victory_layer`). Adding one more field keeps related state co-located. `RunManager` is the wrong place — it has no concept of room scenes, only room IDs and cleared state.

**Alternatives considered**:
- Store on `RoomLoader` — rejected; RoomLoader doesn't know about the boss flow and would gain responsibility for the boss lifecycle.
- Read from `RunManager.run_state.current_room_id` — rejected; `current_room_id` is set when a room is entered (via `RoomSpawner`), not when the boss button is pressed, so it may reflect an older room if the player never triggered entry after clearing.

---

## Decision 3: When to show vs hide the "Continue" button

**Decision**: "Continue" is shown only when `_boss_return_room_id` is non-empty at the time `_show_boss_victory_overlay()` runs. The existing `BossVictoryOverlay.setup(show_continue: bool)` already wires this; `Main.gd` currently passes `run_mode == "endless"`. Replace that condition with `run_mode == "endless" and not _boss_return_room_id.is_empty()`.

**Rationale**: Dev Panel `_on_dev_start_boss()` calls `_on_boss_teleport_pressed()` without a prior dungeon room, so `RunManager.current_room` is null. With the new field defaulting to `""`, the button is automatically hidden in that path with no extra branching.

**Alternatives considered**:
- Always show Continue in endless and handle empty return room with a fallback to hub — rejected; adds complexity and the DevPanel path is a developer tool, not a player path.
