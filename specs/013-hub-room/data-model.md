# Data Model: Hub Room

**Feature**: 013-hub-room
**Date**: 2026-02-27

---

## No New Data Classes

This feature introduces no new GDScript data model classes (`scripts/data_models/`). The hub room is a structural scene — it has no balance numbers, no run state, and no content to model. No JSON data file is needed.

---

## New Scenes

### scenes/hub/TeleportDoor.tscn (NEW — Godot Editor)

**Base class**: `Node2D`
**Script**: `scenes/hub/TeleportDoor.gd`
**Purpose**: In-world interactive placeholder. Contains a pressable `Button` labelled "Teleport". When pressed — if no run is active — emits `teleport_activated`.

**Node hierarchy** (authored in Godot Editor):

```
TeleportDoor (Node2D)
├── ColorRect            ← visual "door" shape placeholder (e.g. 200×300, dark tone)
└── Button               ← Godot Control, text = "Teleport", sized/positioned in Editor
```

Note: `Button` is a Control node and renders in screen space in Godot 4 (not affected by Camera2D). Its on-screen position is configured in the Editor. This is acceptable for the MVP placeholder — the visual will be replaced by a world-space asset in a future iteration.

**Exported fields**: none
**Signal**: `teleport_activated`

---

### scenes/hub/HubRoom.tscn (NEW — Godot Editor)

**Base class**: `Node2D`
**Script**: `scenes/hub/HubRoom.gd`
**Purpose**: The hub room container. Holds the background and TeleportDoor. Owns the hub's lifecycle — tears itself down when the Teleport button fires.

**Node hierarchy** (authored in Godot Editor):

```
HubRoom (Node2D)
├── ColorRect            ← background (1920×1080, same palette as dungeon rooms)
└── TeleportDoor         ← instance of TeleportDoor.tscn, positioned near player start
```

**Signal**: `hub_exited` — emitted just before `queue_free()` so Main can react.

---

## Modified Scripts

### scenes/core/Main.gd (MODIFY)

**Change**: Remove the automatic `GlobalSignals.gameplay_started.emit()` and `RunManager.start_run("endless")` calls from `_ready()`. Add hub room instantiation and `_on_hub_exited()` handler.

```
Before _ready():
  Line 21: GlobalSignals.gameplay_started.emit()   ← REMOVE
  Line 22: RunManager.start_run("endless")          ← REMOVE

After _ready() additions:
  const _HUB_ROOM_SCENE = preload("res://scenes/hub/HubRoom.tscn")
  var _hub_room: Node = null
  Instantiate + add_child + connect hub_room.hub_exited → _on_hub_exited

New method:
  func _on_hub_exited() -> void:
      RunManager.start_run("endless")
      GlobalSignals.gameplay_started.emit()
```

---

## Script Definitions

### TeleportDoor.gd

**File**: `scenes/hub/TeleportDoor.gd`

```gdscript
class_name TeleportDoor
extends Node2D

signal teleport_activated


func _ready() -> void:
    $Button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
    if not RunManager.is_run_active:
        teleport_activated.emit()
```

Note: `Button.pressed` fires from Godot's UI input system — not a physics callback. No `call_deferred` needed.

---

### HubRoom.gd

**File**: `scenes/hub/HubRoom.gd`

```gdscript
class_name HubRoom
extends Node2D

signal hub_exited


func _ready() -> void:
    var teleport: TeleportDoor = get_node("TeleportDoor")
    teleport.teleport_activated.connect(_on_teleport_activated)


func _on_teleport_activated() -> void:
    hub_exited.emit()
    queue_free()
```

---

### Main.gd (diff)

```gdscript
# New constant (top of file)
const _HUB_ROOM_SCENE = preload("res://scenes/hub/HubRoom.tscn")

# New field
var _hub_room: Node = null

# In _ready() — REPLACE lines 21-22 with:
_hub_room = _HUB_ROOM_SCENE.instantiate()
add_child(_hub_room)
_hub_room.hub_exited.connect(_on_hub_exited)

# New method
func _on_hub_exited() -> void:
    RunManager.start_run("endless")
    GlobalSignals.gameplay_started.emit()
```

---

## State Lifecycle

```
Game launch:
  Main._ready()
    → Add HubRoom as child of Main
    → Connect HubRoom.hub_exited
    → Player is in hub at initial scene position
    → No run active (RunManager.is_run_active == false)
    → HUD hidden (gameplay_started not yet emitted)

Hub (player present):
    → Player moves freely via joystick
    → TeleportDoor visible with "Teleport" Button
    → Player can press the Button at any time

Button pressed:
    → TeleportDoor._on_button_pressed() fires
    → RunManager.is_run_active == false → emit teleport_activated
    → HubRoom._on_teleport_activated()
    → hub_exited.emit()    ← Main._on_hub_exited() called synchronously
    → queue_free()         ← HubRoom removed at end of frame

Run starts (Main._on_hub_exited):
    → RunManager.start_run("endless")
    → GlobalSignals.gameplay_started.emit() → ExplorationHUD shown
    → DungeonGenerator._generate() (via run_started signal)
    → RoomLoader._on_layout_ready() → loads StartRoom01
    → RoomLoader._place_player() → player teleported to start room
```
