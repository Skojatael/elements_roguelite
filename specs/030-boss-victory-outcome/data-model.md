# Data Model: Boss Victory Outcome (030)

No new JSON data or persistent data classes are introduced. This feature is pure UI + signal wiring.

---

## UI Entities

### BossVictoryOverlay

A screen-space panel displayed after the boss is defeated. Owned by Main.gd lifecycle (created and freed alongside its CanvasLayer).

| Field | Type | Description |
|-------|------|-------------|
| `_cash_out_button` | `Button` (@export) | Triggers cash-out run end |
| `_continue_button` | `Button` (@export) | Stub; changes text on press |

**Signals emitted**:
- `cash_out_pressed` — no arguments; emitted once on button press; guarded against double-fire by button's `disabled` state
- `continue_pressed` — no arguments; emitted once; button self-disables after emit

**State transitions**:
```
[hidden] → boss dies → [visible, both buttons enabled]
         → cash_out_button pressed → run_ended (overlay freed by Main.gd)
         → continue_button pressed → continue_button text="Coming Soon…", disabled=true
```

---

## Modified State: Main.gd

Two new tracked references added alongside existing `_results_layer`, `_relic_offer_layer`:

| Field | Type | Description |
|-------|------|-------------|
| `_boss_victory_layer` | `CanvasLayer` | Wraps overlay in screen space; freed on run end or new run start |
| `_boss_victory_overlay` | `BossVictoryOverlay` | The overlay node; null when not shown |
| `_boss_room_spawner` | `RoomSpawner` | Reference stored at boss spawn time to connect `room_cleared` |

---

## No changes to:
- `data/enemies.json`
- `data/dungeon_config.json`
- Any `scripts/data_models/` class
- `RunManager` state or signals
