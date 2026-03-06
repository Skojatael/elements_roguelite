# Research: DevPanel Start Boss (031)

## Decision 1 — Reuse _on_boss_teleport_pressed() Directly

**Decision**: `_on_dev_start_boss()` calls `_on_boss_teleport_pressed()` after ensuring a run is active. No logic is duplicated.

**Rationale**: `_on_boss_teleport_pressed()` already encapsulates the full boss spawn flow — door disable, HP scaling, player/camera placement, spawner signal connection. Duplicating that logic would be a Constitution V (YAGNI) violation. The DevPanel handler is purely a precondition wrapper around the existing method.

**Alternatives considered**:
- Inline the full spawn logic in the DevPanel handler — rejected: code duplication.
- Extract boss spawn into a shared helper called by both — rejected: premature abstraction; only two callers and one is trivial.

---

## Decision 2 — start_run() Is Called Synchronously if Needed

**Decision**: If `not RunManager.is_run_active`, call `RunManager.start_run("endless")` before `_on_boss_teleport_pressed()`.

**Rationale**: In Godot 4, signal emissions are synchronous by default (no DEFERRED flag). `start_run()` calls `run_started.emit()` at the end, which synchronously triggers `_on_run_started()` in Main.gd. That clears `_hub_room` and `_results_layer`. By the time `start_run()` returns, the hub is freed and the run is active — safe to immediately call `_on_boss_teleport_pressed()`.

`_room_loader.free_current_room()` (called inside `_on_boss_teleport_pressed()`) has a null guard, so it is safe when `_current_room_node` is null (as it will be at run start).

**Alternatives considered**:
- `call_deferred` for the teleport — rejected: adds a frame of latency for no benefit; synchronous works.

---

## Decision 3 — Guard Conditions

**Decision**: Two guards in `_on_dev_start_boss()`:
1. `if _boss_room_spawner != null: return` — already in boss room (spawner stored on teleport, cleared on room_cleared).
2. `if _boss_victory_layer != null: return` — victory overlay is showing.

**Rationale**: These are the only two states where pressing "Start Boss" would be nonsensical or harmful. Both variables already exist on Main.gd (from feature 030). No new state needed.

`_boss_room_spawner` is set to `spawner` at the start of `_on_boss_teleport_pressed()` and nulled in `_on_boss_room_cleared()`. It correctly represents "boss room is currently active".

**Alternatives considered**:
- A dedicated `_in_boss_room: bool` flag — rejected: `_boss_room_spawner != null` already encodes the same information without extra state.

---

## Decision 4 — Named Method, Not Lambda

**Decision**: Replace the stub lambda with `_on_dev_start_boss` (named method reference), consistent with `_on_dev_get_relic`.

**Rationale**: The handler has guard conditions and multi-statement logic — inlining in a lambda is unreadable and untestable. `_on_dev_get_relic` sets the precedent for non-trivial DevPanel handlers using named methods.
