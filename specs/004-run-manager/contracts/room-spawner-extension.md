# Contract: RoomSpawner Extension

**Feature**: 004-run-manager
**File**: `scenes/dungeon/RoomSpawner.gd`
**Date**: 2026-02-21

Minimal additions to the existing RoomSpawner. No existing behaviour changes.

---

## New Signal

```gdscript
signal room_entered(room_id: String)
```

Emitted after all entry guards pass (player group confirmed, room not cleared, not already spawned) — immediately before `_spawn_enemies()` is called.

---

## _ready() Addition

```gdscript
func _ready() -> void:
    # ... existing code unchanged ...
    RunManager.register_room(self)   # ← add this line
```

Called after `_load_config()` and `_entry_area` connection. Order relative to existing lines does not matter.

---

## _on_player_entered() Addition

```gdscript
func _on_player_entered(body: Node2D) -> void:
    # ... existing guards unchanged ...
    room_entered.emit(room_id)   # ← add before _spawn_enemies()
    _spawn_enemies()
```

Emit happens after all guards pass, before spawning.

---

## No Other Changes

- `room_cleared` signal already exists — no modification needed.
- `_on_enemy_defeated` — no modification needed.
- All existing logging preserved.
