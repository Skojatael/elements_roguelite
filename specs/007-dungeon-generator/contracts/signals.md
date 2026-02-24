# Signal Contracts: Dungeon Generator

**Feature**: 007-dungeon-generator
**Date**: 2026-02-23

---

## New Signal: RunManager.run_started

**Owner**: `autoload/RunManager.gd`

```gdscript
signal run_started(mode: String)
```

### Emission

| Property | Value |
|----------|-------|
| Emitted in | `RunManager.start_run(mode)` |
| Timing | After all session state is reset; last line of `start_run()` |
| Parameter `mode` | The mode string passed to `start_run()` (`"endless"` or `"boss"`) |

### Consumer

| Property | Value |
|----------|-------|
| Connected by | `DungeonGenerator._ready()` |
| Connection | `RunManager.run_started.connect(_on_run_started)` |
| Handler signature | `func _on_run_started(_mode: String) -> void` |
| Handler action | Calls `_generate()` |

### Invariants

- Signal MUST fire every time `start_run()` is called, including re-starts.
- Existing `run_ended(reason)` signal is unchanged.
- All prior `start_run()` callers (Main.gd DevPanel, Main.gd `_ready()`) are unaffected — they do not listen to `run_started`.

---

## Existing Signal: RoomSpawner.room_entered (unchanged)

```gdscript
signal room_entered(room_id: String)
```

Connected by `RunManager.spawn_room()` (006-room-factory). DungeonGenerator does not interact with this signal directly.

---

## Existing Signal: RoomSpawner.room_cleared (unchanged)

```gdscript
signal room_cleared(room_id: String)
```

Connected by `RunManager.spawn_room()` (006-room-factory). DungeonGenerator does not interact with this signal directly.
