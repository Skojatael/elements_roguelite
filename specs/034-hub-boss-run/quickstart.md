# Quickstart: Hub Boss Run (034)

## Overview

This feature adds a permanently unlockable "Boss Run" button to the hub. Players unlock it by completing 3 endless-mode boss kills and spending 300 shards. Once unlocked, they can teleport directly to the boss (mode `"boss"`), which awards 35 flat shards on cash-out with no relic offer and no effect on endless-mode meta-progression flags.

## Files Changed

| File | Change type | Notes |
|------|------------|-------|
| `data/meta_config.json` | Modified | Add 3 new keys |
| `scripts/data_models/MetaState.gd` | Modified | 2 new fields |
| `scripts/managers/SaveManager.gd` | Modified | Persist 2 new fields |
| `scripts/managers/MetaManager.gd` | Modified | 2 new methods on impl |
| `autoload/MetaManager.gd` | Modified | 2 new properties, 1 new method, 2 modified handlers |
| `scenes/hub/HubRoom.gd` | Modified | New signal + export |
| `scenes/ui/boss_victory/BossVictoryOverlay.gd` | Modified | Add `setup(show_continue: bool)` — hides Continue in boss mode |
| `scenes/core/main.gd` | Modified | Wire hub button, modify boss room cleared + victory overlay handlers |
| `scenes/hub/BossRunShop.gd` | New | Unlock purchase control |
| `scenes/hub/BossRunShop.tscn` | New (Editor) | Control root with Button child |
| `scenes/hub/BossRunButton.gd` | New | Run trigger control |
| `scenes/hub/BossRunButton.tscn` | New (Editor) | Control root with Button child |
| `scenes/hub/HubRoom.tscn` | Modified (Editor) | Add BossRunShop and BossRunButton as children; assign exports |
| `repo_map.md` | Modified | Update affected entries |

## Implementation Order

1. **Data layer** — `meta_config.json`, `MetaState.gd`, `SaveManager.gd` (no dependencies)
2. **Impl logic** — `MetaManagerImpl` new methods (depends on MetaState fields)
3. **Autoload surface** — `autoload/MetaManager.gd` new properties/methods + modified handlers
4. **Hub scripts** — `BossRunShop.gd`, `BossRunButton.gd` (depend on MetaManager surface)
5. **HubRoom wiring** — `HubRoom.gd` new signal + export (depends on BossRunButton class_name)
6. **Main.gd** — new handler + boss room cleared modification (depends on HubRoom signal)
7. **Editor tasks** — create `.tscn` files, add children to HubRoom.tscn, assign exports

## Key Behaviour Contracts

### Boss mode run flow

```
Hub BossRunButton pressed
  → HubRoom.hub_boss_run_pressed emitted + HubRoom.queue_free()
  → Main._on_hub_boss_run_pressed()
      → _hub_room = null
      → RunManager.start_run("boss")
      → GlobalSignals.gameplay_started.emit()
      → _on_boss_teleport_pressed()   ← existing method, unchanged
```

### Boss mode room cleared

```
Boss killed in "boss" mode
  → Main._on_boss_room_cleared()
      → run_mode == "boss": skip essence, skip relic offer
      → _show_boss_victory_overlay()
  → MetaManager._on_room_cleared("boss_room")
      → run_mode != "endless": return immediately
        (neither first_boss_killed nor endless_boss_kill_count change)
```

### Boss mode run ended (cash out)

```
Player presses Cash Out
  → RunManager.end_run(CASH_OUT)
  → MetaManager._on_run_ended(CASH_OUT)
      → run_mode == "boss": add_shards(35), return
        (normal essence→shard conversion skipped)
```

### Endless mode boss kill (unchanged + extended)

```
Boss killed in "endless" mode
  → MetaManager._on_room_cleared("boss_room")
      → run_mode == "endless":
          → record_boss_kill()   ← existing, unchanged
          → increment_endless_boss_kills()   ← new
  → BossRunShop._update_visibility() fires on next hub_entered
```

## Validation Checklist

- [ ] After 4 endless boss kills, BossRunShop is not visible in hub
- [ ] After 3 endless boss kills, BossRunShop becomes visible on hub return
- [ ] BossRunShop purchase with insufficient shards has no effect
- [ ] BossRunShop purchase with sufficient shards deducts 300, shows BossRunButton, hides shop
- [ ] BossRunButton not visible before purchase; visible after purchase persists across sessions
- [ ] BossRunButton press starts run in "boss" mode and teleports to boss room
- [ ] Boss kill in boss mode: no relic offer, victory overlay shown immediately
- [ ] Cash out in boss mode: shard balance increases by exactly 35
- [ ] Death in boss mode: shard balance unchanged
- [ ] Boss mode boss kill: endless_boss_kill_count unchanged, first_boss_killed unchanged
- [ ] Boss mode victory overlay: only Cash Out button is visible (Continue button hidden)
- [ ] Endless mode victory overlay: both Cash Out and Continue buttons visible (unchanged)
- [ ] Dev panel boss run (endless mode): existing behaviour unchanged
