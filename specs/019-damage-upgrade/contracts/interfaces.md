# Contracts: Damage Multiplier Upgrade

## MetaState (`scripts/data_models/MetaState.gd`)

```gdscript
class_name MetaState
extends RefCounted

var total_shards: int = 0
var damage_upgrade_level: int = 0    # NEW: 0 = no upgrades purchased
```

---

## MetaManagerImpl (`scripts/managers/MetaManager.gd`)

```gdscript
# NEW methods added to existing MetaManagerImpl:

func get_upgrade_cost(level: int, base_cost: int, scale: float) -> int:
    # Computes cost for transitioning from `level` to level+1.
    # Iterates: cost = floori(float(cost) * scale) starting from base_cost, `level` times.
    # Level 0: returns base_cost unchanged. Level 1: floor(base_cost * scale), etc.

func purchase_damage_upgrade(cost: int, save_manager: Node) -> bool:
    # ATOMIC: checks balance, deducts total_shards, increments damage_upgrade_level, saves.
    # Returns true on success; false if total_shards < cost.
    # On success: total_shards -= cost, damage_upgrade_level += 1, save_meta_state() called once.
    # Caller is responsible for emitting shards_changed after a true return.

func get_damage_multiplier(damage_per_level: float) -> float:
    # Returns 1.0 + float(damage_upgrade_level) * damage_per_level.
    # Pure read — no side effects.
```

---

## MetaManager autoload (`autoload/MetaManager.gd`)

```gdscript
# NEW members added to existing autoload:

var damage_multiplier: float:
    # Computed property. Returns _impl.get_damage_multiplier(damage_per_level from config).
    get

func get_next_upgrade_cost() -> int:
    # Returns the shard cost for the next upgrade level.
    # Reads damage_upgrade config from ResourceManager.get_meta_config().
    # Returns 0 if already at max level (caller should check max level separately).

func purchase_damage_upgrade() -> bool:
    # Reads config, gets current level cost, delegates to _impl.purchase_damage_upgrade().
    # Emits shards_changed(new_total) on success (same pattern as spend()).
    # Returns false if at max level or insufficient balance.
```

---

## SaveManagerImpl (`scripts/managers/SaveManager.gd`)

```gdscript
# Modified save_meta_state and load_meta_state to include damage_upgrade_level:

func save_meta_state(state: MetaState) -> void:
    # Saves: {"total_shards": state.total_shards, "damage_upgrade_level": state.damage_upgrade_level}

func load_meta_state() -> MetaState:
    # Loads total_shards and damage_upgrade_level.
    # Missing "damage_upgrade_level" key defaults to 0 (backward compatible).
```

---

## UpgradeShop (`scenes/hub/UpgradeShop.gd`)

```gdscript
extends Control

@export var _button: Button    # Assigned in Inspector to Button child.

func _ready() -> void
    # Connects _button.pressed to _on_buy_pressed.
    # Connects MetaManager.shards_changed to _on_shards_changed.
    # Calls _update_button().

func _update_button() -> void
    # Reads MetaManager.meta_state.damage_upgrade_level and max_levels from config.
    # If maxed: _button.text = "Damage Multiplier — MAX", _button.disabled = true.
    # Otherwise: _button.text = "Damage Multiplier — {cost} shards".format({...})
    #            _button.disabled = not MetaManager.can_spend(cost)

func _on_buy_pressed() -> void
    # Calls MetaManager.purchase_damage_upgrade().
    # Calls _update_button() regardless of result (cost changes on success; affordability may change).

func _on_shards_changed(_new_total: int) -> void
    # Calls _update_button() to refresh affordability.
```

---

## CombatComponent (`scenes/player/components/CombatComponent.gd`)

```gdscript
# ADDITIONS to existing CombatComponent:

var _base_attack_damage: float    # Cached in _ready() from inspector-assigned attack_damage.

# In _ready(), additionally:
#   _base_attack_damage = attack_damage
#   RunManager.run_started.connect(func(_m: String) -> void: _apply_damage_multiplier())

func _apply_damage_multiplier() -> void:
    # Sets attack_damage = _base_attack_damage * MetaManager.damage_multiplier.
    # Called once per run start.
```

---

## Invariants

- `damage_upgrade_level` is in range `[0, max_levels]` at all times.
- A purchase always atomically decrements `total_shards` AND increments `damage_upgrade_level` — never one without the other.
- `_base_attack_damage` always reflects the Inspector-assigned value, never the multiplied value.
- `UpgradeShop._update_button()` is idempotent and can be called any number of times safely.
- `get_damage_multiplier()` returns exactly `1.0 + float(level) * damage_per_level` — no floor/ceil applied to the multiplier itself.
