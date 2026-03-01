# Contracts: Shard Spending

## MetaManager autoload (`autoload/MetaManager.gd`)

```gdscript
extends Node

# Emitted after any successful mutation of total_shards.
# NOT emitted for zero-amount operations.
signal shards_changed(new_total: int)

# Existing property — unchanged.
var meta_state: MetaState:
    get: return _impl.meta_state

# NEW: Check affordability without modifying balance.
# Returns true if cost >= 0 and meta_state.total_shards >= cost.
# Returns false for negative cost.
func can_spend(cost: int) -> bool

# NEW: Deduct cost from balance. Persists and emits shards_changed on success.
# Returns true if deduction succeeded (balance >= cost and cost >= 0).
# Returns false if insufficient balance or negative cost; balance unchanged.
# spend(0) returns true, no save, no signal.
func spend(cost: int) -> bool

# NEW: Add amount to balance. Persists and emits shards_changed.
# No-op and no signal if amount <= 0.
func add_shards(amount: int) -> void
```

---

## MetaManagerImpl (`scripts/managers/MetaManager.gd`)

```gdscript
class_name MetaManagerImpl
extends RefCounted

var meta_state: MetaState  # Non-null at all times.

# Existing — unchanged.
func load(save_manager: Node) -> void

# REMOVED: on_run_ended() — logic moved to autoload._on_run_ended via add_shards.

# NEW: Add shards and persist. No-op if amount <= 0.
func add_shards(amount: int, save_manager: Node) -> void

# NEW: Pure affordability check. No side effects.
# Returns true if cost >= 0 and meta_state.total_shards >= cost.
func can_spend(cost: int) -> bool

# NEW: Deduct if affordable. Saves on success.
# Returns true and deducts if cost >= 0 and total_shards >= cost.
# Returns false and leaves balance unchanged otherwise.
# spend(0) returns true with no mutation and no save.
func spend(cost: int, save_manager: Node) -> bool
```

---

## Invariants

- `total_shards` is always `>= 0`; `spend` enforces this via the balance guard.
- `shards_changed` is always emitted AFTER the save completes — receivers can assume persistence.
- `can_spend` is always side-effect-free — safe to call from UI render loops.
- Negative cost to `spend` or `can_spend` returns `false` — never treated as a credit.
- Negative amount to `add_shards` is a no-op — never treated as a debit.
- `spend(0)` → `true`, no mutation, no save, no signal.
- `add_shards(0)` → no-op, no signal.
