# Research: Run End Screen

## Decision 1: Where to display the results screen

**Decision**: Instantiate `ResultsScreen.tscn` and add it as a child of the Main scene, after freeing the dungeon room. Not a CanvasLayer overlay, not a full scene change.

**Rationale**: Main.gd is the existing scene orchestrator — it already manages the hub room lifecycle using the same pattern (instantiate → add_child → connect signals → free on exit). Reusing this pattern for the results screen keeps scene management consistent and avoids introducing a scene-change system that doesn't exist in the project.

**Alternatives considered**:
- Full `get_tree().change_scene_to_file()` — rejected because it would unload Main.gd (Player, DungeonGenerator, etc.) and require a reload, adding unnecessary complexity.
- CanvasLayer overlay on top of dungeon — rejected by the spec design: dungeon must be freed at `end_run()` time, not kept underneath.

---

## Decision 2: Who frees the current room on run end

**Decision**: `RoomLoader` connects to `RunManager.run_ended` in `_ready()` and frees `_current_room_node` in the handler.

**Rationale**: RoomLoader is the sole owner of `_current_room_node` and already frees it between room transitions. Extending its responsibility to also free it on run end is consistent with the Single Responsibility of room-lifecycle management. RunManager must not reach into RoomLoader's node reference — that would violate SRP.

**Alternatives considered**:
- Main.gd triggers room cleanup — rejected because Main has no reference to `_current_room_node` (it's private to RoomLoader).
- RunManager.end_run() directly frees the room — rejected because RunManager must not hold references to dungeon scene nodes.

---

## Decision 3: How RunSummary is passed to ResultsScreen

**Decision**: `RunManager.end_run()` creates a `RunSummary` snapshot and stores it as `RunManager.run_summary`. Main.gd reads `RunManager.run_summary` when the `run_ended` signal fires and passes it to `ResultsScreen.setup(summary)`.

**Rationale**: Storing the summary on RunManager mirrors how `run_state` and `player_state` are stored — accessible after the run ends until the next `start_run()`. This avoids changing the `run_ended` signal signature and keeps the data accessible to any future consumer. The snapshot is created before scene teardown so it never depends on live dungeon nodes.

**Alternatives considered**:
- Emit `RunSummary` as a parameter of the `run_ended` signal — rejected to avoid changing an existing signal signature and because RunManager already uses the "store on self" pattern for post-run data.
- ResultsScreen reads directly from `RunManager` fields at display time — rejected by FR-010: the screen must read from an immutable snapshot, not live RunManager state.

---

## Decision 4: ExplorationHUD hiding on run end

**Decision**: `ExplorationHUD._ready()` connects `RunManager.run_ended` to `_on_gameplay_ended()` (in addition to the existing `GlobalSignals.gameplay_ended` connection).

**Rationale**: `GlobalSignals.gameplay_ended` is currently only emitted in `Main._on_player_died()`. DevPanel cash-out calls `RunManager.end_run()` directly without emitting `gameplay_ended`, leaving the HUD visible. Connecting directly to `RunManager.run_ended` covers all end-run paths uniformly. The extra connection in `_ready()` is a one-line addition consistent with the existing pattern for `run_started`.

**Alternatives considered**:
- Emit `gameplay_ended` inside `RunManager.end_run()` — rejected because RunManager must not depend on GlobalSignals; that coupling would violate SRP.
- Remove the `gameplay_ended` connection and rely solely on `run_ended` — rejected to avoid breaking whatever else may consume `gameplay_ended` in future.

---

## Decision 5: enemies_slain counter location

**Decision**: New field `enemies_slain: int` on RunManager, incremented in `_on_enemy_defeated()`, reset to `0` in `start_run()`.

**Rationale**: RunManager already tracks `rooms_entered`, `run_currency`, and `cleared_rooms` as run-scoped counters. `enemies_slain` follows the same pattern. It is reset at `start_run()` consistent with all other session state.

**Alternatives considered**:
- Track in RoomSpawner and aggregate on run end — rejected because it would require iterating room nodes at `end_run()` time, which violates the "snapshot before teardown" requirement.
- Track in RunState — rejected because RunState is a snapshot, not a live counter. RunManager is the live counter; RunState is updated when convenient.
