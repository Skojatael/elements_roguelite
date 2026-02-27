# Quickstart Validation: Hub Room

**Feature**: 013-hub-room
**Date**: 2026-02-27

All scenarios are manual tests in the Godot Editor using Remote Inspector, the game viewport, and the Output panel.

---

## Scenario 1 — Game Starts in Hub (Not Dungeon)

1. Launch the game.
2. Observe the initial scene in the viewport.
3. Confirm the player is placed inside a hub room — a coloured background is visible but no dungeon corridor geometry, no enemies.
4. In Remote Inspector: confirm `RunManager.is_run_active == false`.
5. In Remote Inspector: confirm `RunManager.run_state.current_room_id == ""`.

**Pass**: Player is in hub; no run is active.

---

## Scenario 2 — Teleport Button is Visible and Labelled

1. Launch the game.
2. Look at the hub room scene in the viewport.
3. Confirm a button labelled "Teleport" is visible on screen.
4. Confirm the button is pressable (not greyed-out or hidden).

**Pass**: "Teleport" button is visible and enabled.

---

## Scenario 3 — Player Can Move Freely in Hub

1. Launch the game.
2. Use the joystick to move the player in all four directions.
3. Confirm movement is smooth and the camera follows the player.
4. Confirm no errors appear in the Output panel.

**Pass**: Movement works normally in the hub.

---

## Scenario 4 — HUD is Hidden in Hub

1. Launch the game.
2. Confirm the ExplorationHUD (joystick, skill buttons) is NOT visible on screen while in the hub.
3. Do NOT press the Teleport button.

**Pass**: HUD hidden during hub; no combat UI visible before run starts.

---

## Scenario 5 — Proximity Alone Does NOT Start the Run

1. Launch the game.
2. Walk the player directly up to the TeleportDoor area.
3. Wait 2–3 seconds without pressing the button.
4. Confirm `RunManager.is_run_active == false` in Remote Inspector.
5. Confirm no `[RunManager] run started` log line in Output.

**Pass**: Proximity has no effect — button press is required.

---

## Scenario 6 — Pressing the Teleport Button Starts the Run

1. Launch the game.
2. Press the "Teleport" button.
3. Confirm in the Output panel: `[RunManager] run started` log line appears.
4. Confirm `RunManager.is_run_active == true` in Remote Inspector.
5. Confirm the hub room is no longer present in the Remote Scene tree.

**Pass**: Run starts on button press.

---

## Scenario 7 — Player is Placed in the Dungeon Start Room

1. Press the Teleport button (Scenario 6).
2. After the transition, confirm the player is inside a dungeon room (visible room background, doors present).
3. Confirm the room is `StartRoom01` (check room type in Remote Inspector or scene tree).
4. Confirm the player is positioned near the room center.

**Pass**: Player arrives in the dungeon's starting room.

---

## Scenario 8 — HUD Appears After Teleport

1. Press the Teleport button.
2. After run starts, confirm the ExplorationHUD (joystick, skill buttons) is now visible.

**Pass**: HUD shown only after run begins; hidden during hub.

---

## Scenario 9 — Dungeon Gameplay Works Normally After Teleport

1. Press the Teleport button.
2. Play through at least one combat room (enter, defeat enemies, clear room).
3. Navigate through a door to a second room.
4. Confirm `RunManager.run_state.cleared_rooms` shows the cleared room.
5. Confirm no errors related to hub, TeleportDoor, or HubRoom in Output.

**Pass**: Full dungeon gameplay unaffected by the hub change.

---

## Scenario 10 — No Errors on Button Press

1. Launch the game.
2. Press the Teleport button.
3. Check the Output panel immediately after transition.
4. Confirm zero errors about signal connections, freed objects, or physics violations.

**Pass**: Clean Output panel after hub → run transition.

---

## Scenario 11 — Guard: Double Press Does Not Start Two Runs

1. Launch the game.
2. Press the Teleport button.
3. Immediately press the Teleport button again (before the run fully loads).
4. Confirm only one `[RunManager] run started` log line in Output.
5. Confirm no errors.

**Pass**: `is_run_active` guard prevents double-activation.

---

## Scenario 12 — DevPanel Still Works

1. Launch the game. Do NOT press the Teleport button.
2. In the DevPanel, press "Start Run".
3. Confirm the run starts normally (Output shows `[RunManager] run started`).
4. Confirm the player is placed in the dungeon start room.

**Pass**: DevPanel bypass still functional in dev mode.

---

## Scenario 13 — No Errors Throughout Full Lifecycle

1. Launch game (hub loads).
2. Move around hub.
3. Press Teleport button.
4. Play through several rooms.
5. Let player die (or call end_run via DevPanel).
6. Check Output for any errors mentioning: `HubRoom`, `TeleportDoor`, `hub_exited`, `teleport_activated`, `start_run`, `is_run_active`.

**Pass**: Zero errors across full hub → run lifecycle.
