# Research: Shard Spending

## Decision 1: Signal placement — autoload Node, not impl RefCounted

**Decision**: `signal shards_changed(new_total: int)` is declared on `autoload/MetaManager.gd`
(a `Node`), not on `MetaManagerImpl` (a `RefCounted`).

**Rationale**: Godot 4 signals on `RefCounted` objects can be connected to, but `RefCounted`
instances lack the stable identity and lifecycle management that `Node` autoloads provide.
Consumers connect to `MetaManager.shards_changed` via the autoload singleton — the same
pattern used everywhere else in the project (e.g. `RunManager.run_started`). The impl emits
no signal; the autoload emits after each delegated call that changes the balance.

**Alternatives considered**:
- Signal on `MetaManagerImpl`: Works in isolation but breaks the project's established pattern
  of connecting to autoload signals. Would force callers to obtain a RefCounted reference.
- `GlobalSignals.shards_changed`: Adds a dependency to GlobalSignals for a MetaManager-specific
  event. SRP violation — GlobalSignals owns cross-system events; this event is MetaManager-owned.

---

## Decision 2: on_run_ended refactoring — autoload computes, delegates to add_shards

**Decision**: Remove `MetaManagerImpl.on_run_ended()`. The autoload's `_on_run_ended()` handler
computes `earned = summary.essence_cashed_out / divisor` directly (one line), then calls
`add_shards(earned)` on itself. This means the signal fires naturally through the existing
`add_shards` path, with no duplicate save/emit logic.

**Rationale**: `add_shards` encapsulates the mutate-save-emit pattern. Having `on_run_ended`
bypass it would mean maintaining two code paths that both touch `total_shards`. Removing
`on_run_ended` from the impl and routing through `add_shards` follows DRY and ensures FR-007
(run-end triggers shards_changed) is satisfied automatically. The one-line computation
(`essence / divisor`) in the autoload handler is coordination, not algorithmic logic — it
reads a config value and passes a computed int to a delegating call. This is within the
thin-wrapper mandate.

**Alternatives considered**:
- Keep `impl.on_run_ended` and also emit signal in the autoload after the call: Autoload cannot
  know if the call actually changed the balance (e.g. if summary is null or earned == 0),
  leading to spurious or missed emissions.
- Have `impl.on_run_ended` call `add_shards` internally: Requires impl to hold a reference to
  save_manager and emit logic, which couples impl to the autoload's coordination concern.

---

## Decision 3: Zero-amount edge case behaviour

**Decision**:
- `spend(0)` → returns `true`, no balance change, no save, no signal.
- `add_shards(0)` → no-op, no save, no signal.
- `can_spend(0)` → always `true` (0 <= any non-negative balance).
- Negative cost passed to `spend()` / `can_spend()`: `can_spend` returns `false` (fails `cost >= 0` guard);
  `spend` delegates to `can_spend`, so also returns `false`.
- Negative amount passed to `add_shards()`: no-op (amount guard catches <= 0).

**Rationale**: Zero-spend is a degenerate but valid call — it should never fail, but it also
changes nothing, so saving and signalling would be spurious overhead. The spec explicitly
states `spend(0)` succeeds silently and `add_shards(0)` does not emit the signal. Negative
value rejection is required by FR-008.

**Alternatives considered**:
- Emit signal for spend(0) even though balance unchanged: Spec says no — "does not fire for
  zero-amount grants." Spend(0) is analogous.
- push_error for negative values: Unhelpful in production; silent rejection with a correct
  return value is sufficient for callers to guard their UI.
