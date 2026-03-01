# Data Model: Shard Spending

## No new data entities

This feature introduces no new data structures. It extends the existing `MetaState` mutation
surface and adds a signal to the existing `MetaManager` autoload.

---

## Mutated entity: MetaState

| Field          | Type  | Mutation          | Guard                              |
|----------------|-------|-------------------|------------------------------------|
| `total_shards` | `int` | `+= amount` (add) | `amount > 0`                       |
| `total_shards` | `int` | `-= cost` (spend) | `cost >= 0` and `total_shards >= cost` |

**Invariant**: `total_shards >= 0` at all times. The spend guard enforces this.

---

## New signal

| Signal                              | Emitter                 | When emitted                                          |
|-------------------------------------|-------------------------|-------------------------------------------------------|
| `shards_changed(new_total: int)`    | `autoload/MetaManager`  | After any successful mutation (`add_shards` or `spend`) that changes `total_shards`. NOT emitted for zero-amount operations. |

---

## New methods on MetaManagerImpl (`scripts/managers/MetaManager.gd`)

| Method                                              | Return   | Side effects                           |
|-----------------------------------------------------|----------|----------------------------------------|
| `add_shards(amount: int, save_manager: Node) -> void` | —       | Mutates `meta_state.total_shards`, calls `save_manager.save_meta_state()`. No-op if `amount <= 0`. |
| `can_spend(cost: int) -> bool`                       | bool    | None — pure read.                      |
| `spend(cost: int, save_manager: Node) -> bool`       | bool    | On success: mutates, saves. On failure: no change. |

## New/modified methods on autoload MetaManager (`autoload/MetaManager.gd`)

| Method / signal                   | Behaviour                                                                                  |
|-----------------------------------|--------------------------------------------------------------------------------------------|
| `signal shards_changed(new_total: int)` | Declared on the autoload; emitted after `add_shards` (amount > 0) and after successful `spend`. |
| `add_shards(amount: int) -> void` | Delegates to `_impl.add_shards(amount, SaveManager)`; emits `shards_changed` if `amount > 0`. |
| `can_spend(cost: int) -> bool`    | Delegates to `_impl.can_spend(cost)`.                                                      |
| `spend(cost: int) -> bool`        | Delegates to `_impl.spend(cost, SaveManager)`; emits `shards_changed` if result is `true` and `cost > 0`. |
| `_on_run_ended` (modified)        | Computes `earned = summary.essence_cashed_out / divisor`; calls `add_shards(earned)` — signal fires naturally. Removes call to removed `impl.on_run_ended`. |

---

## State transition

```
total_shards [N]
    │
    ├── add_shards(amount > 0) ──→ total_shards [N + amount]  → save → emit shards_changed(N + amount)
    │
    ├── spend(cost, balance >= cost, cost > 0) ──→ total_shards [N - cost]  → save → emit shards_changed(N - cost)
    │
    ├── spend(cost, balance < cost) ──→ total_shards [N]  (unchanged, return false)
    │
    └── spend(0) or add_shards(0) ──→ total_shards [N]  (no-op, no save, no signal)
```

---

## Persistence

Every successful mutation calls `SaveManager.save_meta_state(meta_state)` before the signal
is emitted. Emission order: mutate → save → emit. Callers that react to `shards_changed` can
assume the value is already persisted.

---

## Existing code removed

| Location                              | Removed                          | Reason                                          |
|---------------------------------------|----------------------------------|-------------------------------------------------|
| `scripts/managers/MetaManager.gd`     | `on_run_ended()` method          | Logic moved to autoload `_on_run_ended` + `add_shards` |
