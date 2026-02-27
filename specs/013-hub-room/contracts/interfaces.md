# Interface Contracts: Hub Room

**Feature**: 013-hub-room
**Date**: 2026-02-27

---

## 1. TeleportDoor.teleport_activated Signal

**Owner**: `TeleportDoor.gd`
**Consumed by**: `HubRoom.gd`

### Contract

```gdscript
signal teleport_activated
```

- Emitted ONLY when ALL of the following are true:
  - The player has pressed the `Button` node inside `TeleportDoor.tscn` (labelled "Teleport").
  - `RunManager.is_run_active == false` at the time of the press.
- MUST NOT emit if a run is already active.
- MUST NOT emit on proximity alone — explicit button press required.
- Fires from Godot's UI input system (`Button.pressed`), not a physics callback. No `call_deferred` required.

### Invariant

TeleportDoor has no awareness of scene teardown, run state transitions, or hub room lifecycle. It fires the signal and its responsibility ends.

---

## 2. HubRoom.hub_exited Signal

**Owner**: `HubRoom.gd`
**Consumed by**: `Main.gd`

### Contract

```gdscript
signal hub_exited
```

- Emitted exactly once, immediately before `HubRoom.queue_free()`.
- Emitted synchronously from `_on_teleport_activated()` — subscribers receive it before the node is freed.
- After `hub_exited` fires, `HubRoom` and `TeleportDoor` are no longer valid references.

### Access Pattern (consumer)

```gdscript
# Correct — connect in Main._ready() after instantiation:
_hub_room.hub_exited.connect(_on_hub_exited)

# _on_hub_exited() runs BEFORE queue_free() processes
# Do NOT access _hub_room after this handler returns
```

---

## 3. Main._on_hub_exited() — Run Start Trigger

**Owner**: `Main.gd`
**Triggered by**: `HubRoom.hub_exited`

### Contract

```gdscript
func _on_hub_exited() -> void:
    RunManager.start_run("endless")
    GlobalSignals.gameplay_started.emit()
```

- MUST call `RunManager.start_run("endless")` first — this emits `run_started`, which triggers `DungeonGenerator._generate()`.
- MUST emit `GlobalSignals.gameplay_started` after `start_run()` — this shows the `ExplorationHUD`.
- `TeleportDoor._on_button_pressed()` guard (`not RunManager.is_run_active`) prevents this being called while a run is active.

---

## 4. RunManager.is_run_active — Read Contract

**Consumer**: `TeleportDoor.gd`

### Contract

- TeleportDoor reads `RunManager.is_run_active` as a read-only guard in `_on_button_pressed()`.
- MUST NOT write to `RunManager` from TeleportDoor directly.
- The check `not RunManager.is_run_active` prevents double-activation if the button is pressed rapidly.

---

## 5. Button.pressed — Input Contract

**Owner**: Godot engine (built-in)
**Connected by**: `TeleportDoor.gd`

### Contract

```gdscript
# In TeleportDoor._ready():
$Button.pressed.connect(_on_button_pressed)
```

- The `Button` node MUST be named `"Button"` exactly in `TeleportDoor.tscn`.
- The `Button` handles both mouse click (Windows dev) and touch events (Android target) automatically.
- The button text MUST be `"Teleport"` (set in Editor Inspector).

---

## 6. Removed Calls in Main._ready()

These two calls are REMOVED from `Main._ready()` as part of this feature:

```gdscript
# BEFORE (lines 21–22 — removed):
GlobalSignals.gameplay_started.emit()   # ← moved to _on_hub_exited()
RunManager.start_run("endless")         # ← moved to _on_hub_exited()
```

After this change, `Main._ready()` no longer starts a run. The run only starts when the player presses the TeleportDoor button.

**DevPanel exception**: `panel.start_run_pressed` (line 15) still calls `RunManager.start_run("endless")` directly. This bypass is intentional for development testing.

---

## 7. HubRoom Node Path Contract

`HubRoom.gd` accesses its `TeleportDoor` child via:

```gdscript
var teleport: TeleportDoor = get_node("TeleportDoor")
```

- The node MUST be named `"TeleportDoor"` exactly in `HubRoom.tscn`.
- `TeleportDoor.gd` accesses its Button child via `$Button` — node MUST be named `"Button"` in `TeleportDoor.tscn`.
