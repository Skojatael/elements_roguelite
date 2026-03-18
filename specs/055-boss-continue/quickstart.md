# Quickstart: Boss Continue (Endless Mode)

## What This Feature Does

After defeating the boss in an endless run, the player can press **Continue** on the victory overlay to return to the dungeon room they left from, keeping the run active.

## Files Changed

| File | Change |
|------|--------|
| `scripts/dungeon/RoomLoader.gd` | Add public `return_to_room(room_id)` method |
| `scenes/core/main.gd` | Add `_boss_return_room_id` field; set on boss teleport; pass to overlay; implement continue handler |

## No New Files

No new scenes, scripts, or data files are needed.

## Implementation Steps (summary)

1. **RoomLoader** — Add `return_to_room(room_id: String) -> void` that calls `_load_room(room_id, "")`.
2. **Main.gd** — Add `var _boss_return_room_id: String = ""`.
3. **Main.gd** — In `_on_run_started()` and `_on_run_ended()`, set `_boss_return_room_id = ""`.
4. **Main.gd** — In `_on_boss_teleport_pressed()`, capture `RunManager.current_room.room_id` into `_boss_return_room_id` before `free_current_room()` is called. Guard: if `RunManager.current_room == null`, leave the field empty.
5. **Main.gd** — In `_show_boss_victory_overlay()`, change `setup(run_mode == "endless")` to `setup(run_mode == "endless" and not _boss_return_room_id.is_empty())`.
6. **Main.gd** — Implement `_on_boss_continue_pressed()`:
   - Free boss room node (`_boss_room_node.queue_free()`, null fields).
   - Free boss victory layer.
   - Show ExplorationHUD.
   - Call `_room_loader.return_to_room(_boss_return_room_id)`.
   - Clear `_boss_return_room_id = ""`.

## Testing

Start endless run → clear 6+ rooms → press boss button → defeat boss → press **Continue** → verify player lands in the room where boss button was pressed, HUD is visible, run is active, essence is unchanged.

Also verify: DevPanel "Start Boss" → defeat boss → Continue button is **not shown**.
