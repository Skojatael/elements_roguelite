# Data Model: Boss Continue (Endless Mode)

No new persistent data structures, JSON schemas, or data-model classes are introduced by this feature.

## New Transient State

### `Main._boss_return_room_id: String`

| Attribute   | Value                                      |
|-------------|--------------------------------------------|
| Type        | `String`                                   |
| Owner       | `Main.gd`                                  |
| Default     | `""`                                       |
| Lifetime    | Run-scoped; cleared on `run_started` and `run_ended` |
| Set by      | `_on_boss_teleport_pressed()` — reads `RunManager.current_room.room_id` before the dungeon room is freed |
| Read by     | `_show_boss_victory_overlay()` — passes `not _boss_return_room_id.is_empty()` to `BossVictoryOverlay.setup()` |
|             | `_on_boss_continue_pressed()` — passes value to `RoomLoader.return_to_room()` |

### State Transitions

```
run_started / run_ended
        │
        ▼
_boss_return_room_id = ""      (default — Continue hidden)
        │
        │  player presses boss button AND current_room != null
        ▼
_boss_return_room_id = "<room_id>"   (Continue shown in overlay)
        │
        │  player presses "Continue"
        ▼
RoomLoader.return_to_room(_boss_return_room_id) called
        │
        ▼
_boss_return_room_id = ""      (cleared after use)
```

## No Schema Changes

No `data/*.json` files are modified. No `RunSummary`, `RunState`, or `PlayerState` fields are added — those snapshots are run-end artifacts and are unaffected by mid-run boss returns.
