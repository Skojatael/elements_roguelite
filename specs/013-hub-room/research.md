# Research Notes: Hub Room

**Feature**: 013-hub-room
**Date**: 2026-02-27
**Status**: Complete — all questions resolved (updated after spec correction: button-press activation)

---

## Decision 1: Hub Room Placement in Scene Tree

**Decision**: The hub room is instantiated dynamically as a child of `Main.tscn` in `Main._ready()`, the same way dungeon rooms are added as children of Main by `RoomFactory`. When the Teleport button is pressed, the hub room calls `queue_free()` on itself; the dungeon then loads normally via RunManager → DungeonGenerator → RoomLoader.

**Rationale**:
- `Main.tscn` already owns all runtime scene children (DungeonGenerator, RoomLoader, Player, dungeon rooms). Adding the hub as a sibling to those is consistent with the existing pattern.
- No new entry scene or new autoload is needed — keeping the change minimal and YAGNI-compliant.
- The hub room at world position (0, 0) naturally aligns with the dungeon's center (also 0, 0), so the player is already in the right visual area.

**Alternatives considered**:
- **New entry scene** (`HubScene.tscn` replaces `Main.tscn`): Would require moving DungeonGenerator, RoomLoader, and Player. Over-engineered for an MVP. Rejected.
- **New autoload** (`HubManager`): Hub logic is not globally shared. An autoload is unjustified per SRP. Rejected.

---

## Decision 2: TeleportDoor Activation Mechanism

**Decision**: `TeleportDoor.tscn` contains a Godot `Button` control node with text `"Teleport"`. `TeleportDoor.gd` connects to `$Button.pressed` signal. When pressed — if no run is active — it emits `teleport_activated`. Proximity alone has no effect; the player must explicitly press the button.

**Rationale**:
- The original spec and the user correction both explicitly describe "a button with 'teleport' text on it" that must be pressed — not a walk-through trigger.
- A Godot `Button` node (Control) is the canonical pressable element in Godot 4. It handles both mouse click (desktop dev) and touch events (mobile target) automatically, requiring no custom input handling.
- `Button.pressed` is not a physics callback — it fires from the UI input system, so no `call_deferred` is needed (unlike `body_entered` which comes from a physics flush and caused the Door.gd bug).
- Decouples the visual placeholder (`Button` label text) from future visual replacement: when a graphical asset replaces the placeholder, the `Button` node can be kept for input while the visual is swapped, or the `pressed` signal can be connected from any replacement interactive node.

**Alternatives considered**:
- **Area2D with body_entered (proximity)**: The original plan — rejected in favour of explicit button press per user correction.
- **Area2D with input_event signal**: Area2D can detect touch/click via `input_event(viewport, event, shape_idx)`. More flexible for world-space interaction but requires manual touch vs. mouse handling. Rejected in favour of the simpler `Button` node which handles both automatically.
- **Sprite2D with input_pickable**: More complex, less readable. `Button` is the idiomatic choice. Rejected.

---

## Decision 3: Button Node Type — Control in Node2D Scene

**Decision**: `TeleportDoor.tscn` root is a `Node2D`. The `Button` child is a Godot `Control` node. In Godot 4, Control children of a Node2D render in screen space (not world space) — their on-screen position is set in the Editor and does not move with the Camera2D. This is acceptable for the MVP placeholder.

**Rationale**:
- For a placeholder in a simple hub room, a fixed-position button is entirely functional. The player can see the button, press it, and the run starts. The button's exact world-tracking is irrelevant at this stage.
- When the visual asset is swapped in a future feature, the interaction node can be replaced with a world-space interactive element (e.g., `Area2D` with `input_event`, or a `Sprite2D` with pickable input) if needed.
- No CanvasLayer overhead — a plain `Button` child is the minimum viable interactive element.
- FR-009 ("visual representation MUST be replaceable without changes to interaction logic") is satisfied: the `Button.pressed` → `TeleportDoor.teleport_activated` signal chain is entirely in `TeleportDoor.gd` and is not coupled to any visual node by name (just `$Button`).

**Alternatives considered**:
- **Button inside CanvasLayer on Main**: Cleaner screen-space positioning, but the button would not be a child of TeleportDoor.tscn — breaking the encapsulation. Rejected.
- **World-space Area2D + input_event**: Better world-tracking but more code for the same MVP result. Deferred to future visual replacement iteration.

---

## Decision 4: Signal Ownership — TeleportDoor vs. HubRoom

**Decision**: `TeleportDoor.gd` emits `teleport_activated`. `HubRoom.gd` connects to this signal in `_ready()`, then re-emits `hub_exited` and calls `queue_free()` on itself. `Main.gd` listens to `hub_exited` and triggers the run.

**Rationale**:
- SRP: TeleportDoor is only responsible for detecting button press and signalling activation. It does not know about run state, scene management, or hub room lifecycle.
- HubRoom.gd owns the hub room's lifecycle — it knows when to tear itself down.
- Main.gd connects run start to HUD visibility — it already owns the "start a run" orchestration.
- Signal chain: `Button.pressed` → `TeleportDoor._on_button_pressed()` → `teleport_activated` → `HubRoom._on_teleport_activated()` → `hub_exited` → `Main._on_hub_exited()` → run starts.

**Alternatives considered**:
- **TeleportDoor calls RunManager.start_run() directly**: Mixes scene teardown and run lifecycle in one script. Rejected.
- **Main.gd directly connects to TeleportDoor**: Main would need to reach inside HubRoom to connect to TeleportDoor — prohibited cross-scene path. Rejected.

---

## Decision 5: Main.gd Modification Strategy

**Decision**: Remove lines 21–22 from `Main._ready()` (the `GlobalSignals.gameplay_started.emit()` and `RunManager.start_run("endless")` calls). Add hub room preload, instantiation, and connection in their place. Add `_on_hub_exited()` which contains the removed calls.

**Rationale**:
- The simplest possible change: two lines removed, hub setup code added, a new handler added.
- `GlobalSignals.gameplay_started` shows the ExplorationHUD — this should NOT fire in the hub (hub is not a combat area). Moving it to `_on_hub_exited()` ensures the HUD is only visible during an active run.
- DevPanel's `start_run_pressed` button (line 15) continues to work for development testing.

**Alternatives considered**:
- **Keep gameplay_started.emit() at startup (always show HUD in hub)**: HUD in hub is misleading. Rejected.

---

## Decision 6: HUD Visibility in Hub

**Decision**: The ExplorationHUD is hidden while the player is in the hub. `GlobalSignals.gameplay_started` is not emitted until `_on_hub_exited()` is called.

**Rationale**:
- ExplorationHUD.gd already subscribes to `GlobalSignals.gameplay_started` and hides itself by default. The existing hide-by-default + show-on-signal pattern works automatically.
- No change to ExplorationHUD.gd needed.

---

## Decision 7: No New Data File

**Decision**: No JSON data file or new data model class is needed. The hub room has no balance numbers, no enemy spawn config, and no content to configure outside the Godot Editor.

**Rationale**:
- The hub is a structural scene, not content. No tunable values exist.
- Constitution Principle II (Data-Driven Content) applies to game-balance values. A navigation room with no numbers is not subject to this requirement.
