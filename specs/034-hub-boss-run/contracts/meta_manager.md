# Contract: MetaManager — Boss Run additions (034)

## autoload/MetaManager.gd

### New computed properties

```gdscript
var is_boss_run_unlocked: bool
    # get: _impl.meta_state.boss_run_unlocked
    # Preconditions: none
    # Side effects: none

var endless_boss_kill_count: int
    # get: _impl.meta_state.endless_boss_kill_count
    # Preconditions: none
    # Side effects: none
```

### New method

```gdscript
func purchase_boss_run() -> bool
    # Purchases the Boss Run unlock if affordable and not already unlocked.
    # Returns true if the purchase succeeded (shards deducted, flag set, saved).
    # Returns false if: already unlocked OR insufficient shards.
    # Side effects on success: total_shards -= boss_run_cost; boss_run_unlocked = true; save; shards_changed.emit()
    # Side effects on failure: none.
```

### Modified: _on_room_cleared(room_id)

```gdscript
# room_id == "boss_room" branch — new guard:
#   if RunManager.run_mode != "endless": return  (no counter update, no flag update)
#   else: record_boss_kill() + increment_endless_boss_kills()
```

### Modified: _on_run_ended(reason)

```gdscript
# Boss mode early branch (checked before existing essence logic):
#   if RunManager.run_mode == "boss":
#       if reason == CASH_OUT: add_shards(boss_run_shard_award)
#       return  (skips essence→shard conversion entirely)
```

---

## scripts/managers/MetaManager.gd (MetaManagerImpl)

### New method: increment_endless_boss_kills

```gdscript
func increment_endless_boss_kills(save_manager: Node) -> void
    # Increments meta_state.endless_boss_kill_count by 1 and saves.
    # No cap — can be called many times.
    # Preconditions: none
    # Side effects: endless_boss_kill_count += 1; save_meta_state called.
```

### New method: purchase_boss_run

```gdscript
func purchase_boss_run(cost: int, save_manager: Node) -> bool
    # Atomic: checks already-unlocked guard, checks affordability, deducts, sets flag, saves.
    # Returns false if boss_run_unlocked already true (idempotent no-op).
    # Returns false if total_shards < cost.
    # Returns true on success.
    # Preconditions: cost >= 0
    # Side effects on success: total_shards -= cost; boss_run_unlocked = true; save_meta_state called.
```
