# Data Model: Hub Boss Run (034)

## MetaState — new fields

**File**: `scripts/data_models/MetaState.gd`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `endless_boss_kill_count` | `int` | `0` | Cumulative boss kills from endless-mode runs only. Never decrements. |
| `boss_run_unlocked` | `bool` | `false` | Set permanently after one-time purchase. Gates `BossRunButton` visibility. |

**Invariants**:
- `endless_boss_kill_count >= 0` always.
- `boss_run_unlocked` is write-once (never reset to false).

---

## meta_config.json — new keys

**File**: `data/meta_config.json`

| Key | Type | Value | Description |
|-----|------|-------|-------------|
| `boss_run_kill_threshold` | `int` | `3` | Endless boss kills required before BossRunShop becomes visible. |
| `boss_run_cost` | `int` | `300` | Shard cost for the one-time BossRunShop purchase. |
| `boss_run_shard_award` | `int` | `35` | Flat shard award on boss-mode cash-out. |

---

## MetaState persistence (SaveManager)

**File**: `scripts/managers/SaveManager.gd`

New JSON keys added to save/load (backward compatible — missing keys default to `0` / `false`):

```
"endless_boss_kill_count": <int>
"boss_run_unlocked": <bool>
```

---

## New Hub Scenes

### BossRunShop

**File**: `scenes/hub/BossRunShop.gd` + `scenes/hub/BossRunShop.tscn`

- `class_name BossRunShop extends Control`
- `@export var _button: Button`
- Visibility rule: `endless_boss_kill_count >= threshold AND NOT boss_run_unlocked`
- Refresh triggers: `MetaManager.shards_changed`, `GlobalSignals.hub_entered`
- On press: `MetaManager.purchase_boss_run()` → `_update_visibility()`

### BossRunButton

**File**: `scenes/hub/BossRunButton.gd` + `scenes/hub/BossRunButton.tscn`

- `class_name BossRunButton extends Control`
- `signal boss_run_pressed`
- `@export var _button: Button`
- Visibility rule: `boss_run_unlocked`
- Refresh triggers: `MetaManager.shards_changed`
- Guard on press: `if RunManager.is_run_active: return`

---

## MetaManagerImpl — new methods

**File**: `scripts/managers/MetaManager.gd`

| Method | Signature | Description |
|--------|-----------|-------------|
| `increment_endless_boss_kills` | `(save_manager: Node) -> void` | Increments `endless_boss_kill_count`, saves. Always increments (no cap). |
| `purchase_boss_run` | `(cost: int, save_manager: Node) -> bool` | Deducts cost, sets `boss_run_unlocked = true`, saves. Returns false if insufficient shards or already unlocked. |

---

## MetaManager autoload — new surface

**File**: `autoload/MetaManager.gd`

| Addition | Type | Description |
|----------|------|-------------|
| `is_boss_run_unlocked` | `bool` (property) | Getter: `_impl.meta_state.boss_run_unlocked` |
| `endless_boss_kill_count` | `int` (property) | Getter: `_impl.meta_state.endless_boss_kill_count` |
| `purchase_boss_run()` | `-> bool` | Delegates to impl; emits `shards_changed` on success. |

---

## HubRoom — new signal

**File**: `scenes/hub/HubRoom.gd`

| Addition | Description |
|----------|-------------|
| `signal hub_boss_run_pressed` | Emitted when BossRunButton fires and HubRoom relays the signal. HubRoom queues itself free after emitting (same pattern as `hub_exited`). |
| `@export var _boss_run_button: BossRunButton` | Inspector-assigned. Wired in `_ready()`. |

---

## State Transitions

```
endless run boss kill →  endless_boss_kill_count += 1  (saved)
                       →  first_boss_killed = true if first time (saved)

boss run kill        →  [no counter change]

BossRunShop purchase  →  total_shards -= 300  (saved)
                       →  boss_run_unlocked = true  (saved)
                       →  shards_changed emitted

boss run CASH_OUT     →  total_shards += 35  (via MetaManager._on_run_ended)
                       →  shards_changed emitted

boss run DIED         →  no shard change
```
