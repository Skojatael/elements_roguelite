# Research: Boss Victory Outcome (030)

## Decision 1 — Door Removal Strategy

**Decision**: Disable Door nodes in code inside `_on_boss_teleport_pressed()`, not as an editor task.

**Rationale**: The boss room is spawned via `RunManager.spawn_room()` directly in Main.gd, bypassing `RoomLoader._configure_doors()` entirely. Door nodes inherited from `RoomBase.tscn` remain with their default `monitoring = true` / `visible = true`, meaning the player can walk into them and `door_activated` fires (though no listener is connected for the boss room). Disabling them in code at spawn time is more reliable than an editor task — an editor change on BossRoom01.tscn could be accidentally reverted.

`Door` has `class_name Door`, so `if child is Door` works. After `RunManager.spawn_room()` returns the spawner, `spawner.get_parent()` gives the room node, whose direct children include the four Door instances.

**Alternatives considered**:
- Editor task on BossRoom01.tscn (hide/disable all four Door nodes in Inspector) — rejected because editor scene inheritance state is fragile and undocumented; code is the explicit, reviewable record.
- BossRoom01.tscn not inheriting RoomBase.tscn — rejected: too breaking, loses shared structure.

---

## Decision 2 — Victory Overlay Trigger

**Decision**: In `_on_boss_teleport_pressed()`, store the returned `RoomSpawner` reference and connect its `room_cleared` signal to a new `_on_boss_room_cleared()` method in Main.gd.

**Rationale**: `RoomSpawner.room_cleared(room_id: String)` fires the same frame the last enemy dies. Main.gd already owns the boss spawn lifecycle, so it is the right owner of the victory response. No new autoload needed.

**Alternatives considered**:
- Listen to `RunManager.room_cleared` — rejected: that signal carries no context about which room type was cleared; requires extra state to distinguish boss from regular clears.
- Listen in ExplorationHUD — rejected: ExplorationHUD is a HUD layer not responsible for run-flow decisions (SRP violation).

---

## Decision 3 — Cash Out Wiring

**Decision**: `_on_boss_cash_out_pressed()` calls `RunManager.end_run(RunManager.EndReason.CASH_OUT)` directly, identical to the DevPanel cash-out path (confirmed: Main.gd line 33 `panel.cash_out_pressed.connect(func(): RunManager.end_run(RunManager.EndReason.CASH_OUT))`). The existing `_on_run_ended()` handler in Main.gd then shows ResultsScreen automatically.

**Rationale**: Zero new logic — the overlay is just a user-facing entry point to the same call path already tested by DevPanel.

**Alternatives considered**:
- Route through a new RunManager method — rejected: no reason to add indirection for an identical call.

---

## Decision 4 — "Continue Further" Stub Behaviour

**Decision**: The "Continue Further" button is enabled by default. On press, its text changes to "Coming Soon…" and the button is disabled (preventing double-press). No other feedback.

**Rationale**: The spec requires "visible stub response" — disabling with changed label is the minimal visible signal without additional nodes. Keeps implementation trivial (one method in BossVictoryOverlay.gd).

**Alternatives considered**:
- Disable from the start (greyed-out) — rejected: the spec says the button is an interactive option, not permanently unavailable; greyed-out implies a condition to fulfil rather than future content.
- Show a popup — rejected: extra scene for a stub.

---

## Decision 5 — ExplorationHUD Boss Button Re-Show Bug

**Decision**: Add an early return at the top of `ExplorationHUD._on_room_cleared_for_boss()` when `room_id == "boss_room"`. The current parameter `_room_id` (unused) must be renamed to `room_id` to use it.

**Rationale**: When the boss dies, `RunManager.mark_room_cleared("boss_room")` is called, which re-emits `RunManager.room_cleared("boss_room")`. ExplorationHUD is connected to that signal. Since `_boss_button.visible` is already false (hidden when pressed), the existing guard at the top does NOT prevent re-execution, and the size-threshold check then re-shows the boss button on top of the victory overlay.

**Fix**: One guard clause: `if room_id == "boss_room": return`.

---

## Decision 6 — Overlay Scene Structure

**Decision**: `scenes/ui/boss_victory/BossVictoryOverlay.tscn` — `Control` root (not `CanvasLayer`; the CanvasLayer is created dynamically by Main.gd, same pattern as ResultsScreen and RelicOfferScreen). Two `Button` children. Script: `BossVictoryOverlay.gd` with `class_name BossVictoryOverlay`.

**Rationale**: Consistent with existing ResultsScreen and RelicOfferScreen patterns — Main.gd creates a CanvasLayer, instantiates the screen as its child, and frees the layer on close. This keeps all screen-space layer management in one place.

---

## Decision 7 — Main.gd Overlay Cleanup on run_started

**Decision**: `_on_run_started()` must null-check and free `_boss_victory_layer` if non-null (same pattern as `_results_layer` cleanup). This handles the case where DevPanel "Start Run" is pressed while the victory overlay is still showing.
