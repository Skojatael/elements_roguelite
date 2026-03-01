# Research: Damage Multiplier Upgrade

## Decision 1: Where damage multiplier is applied — CombatComponent self-contained

**Decision**: `CombatComponent.gd` caches its Inspector-assigned `attack_damage` as
`_base_attack_damage` in `_ready()`, connects to `RunManager.run_started`, and re-applies
the multiplier each time a run begins:
`attack_damage = _base_attack_damage * MetaManager.damage_multiplier`.

**Rationale**: CombatComponent already owns `attack_damage`. Making it responsible for
applying the meta-progression modifier to its own field keeps the component self-contained
and follows the project's pattern of components connecting to RunManager signals directly
(same pattern as ExplorationHUD connecting to gameplay_started/gameplay_ended). No other
file needs to coordinate between MetaManager and CombatComponent.

**Alternatives considered**:
- Apply in Main._on_run_started(): Would require adding `_combat: CombatComponent` to
  Main.gd and importing a public `apply_damage_multiplier()` method on CombatComponent,
  coupling Main to both MetaManager and CombatComponent for one concern. Adds noise to
  Main.gd which is already handling several coordination responsibilities.
- Apply in StatsComponent: StatsComponent manages health only — no damage field exists
  there. Wrong component.

---

## Decision 2: Upgrade purchase ownership — MetaManagerImpl owns atomic purchase

**Decision**: A single `MetaManagerImpl.purchase_damage_upgrade(cost, save_manager)` method
performs the atomic sequence: check balance, deduct shards, increment level, save — in one
call with one save. The autoload handles config lookup, cost computation, and signal
emission around the delegate call.

**Rationale**: Using `spend()` then a separate level increment would produce two saves per
purchase (spend saves shards; increment saves level). Between those two saves the state is
partially written. A single impl method that mutates both fields and saves once guarantees
atomicity. Shard balance is decremented before level increments in the same mutation to
keep the invariant consistent on save. The `shards_changed` signal is emitted from the
autoload after the delegate returns (same pattern as spend/add_shards from feature 018).

**Alternatives considered**:
- Call `MetaManager.spend()` then mutate `meta_state.damage_upgrade_level` from UpgradeShop:
  Requires UpgradeShop to call SaveManager directly; two saves; UpgradeShop knows too much.
- Expose separate `increment_damage_level()` in impl and call after spend(): Two-save problem
  remains.

---

## Decision 3: Cost computation placement — impl method, called by autoload

**Decision**: `MetaManagerImpl.get_upgrade_cost(level, base_cost, scale)` computes the
cost for a given level using `cost = floori(float(prev_cost) * scale)` iterated `level`
times from `base_cost`. The autoload reads config and delegates cost lookup to this method.
UpgradeShop calls `MetaManager.get_next_upgrade_cost()` (autoload wrapper) for display.

**Rationale**: Cost computation is algorithmic logic (iteration + floor) — belongs in impl per
thin-wrapper rule. The autoload supplies config values from ResourceManager and delegates.
UpgradeShop doesn't need to know the formula; it just calls one method.

**Pre-computed cost table** (base=50, scale=1.2, floor at each step):

| Level transition | Cost |
|-----------------|------|
| 0 → 1           | 50   |
| 1 → 2           | 60   |
| 2 → 3           | 72   |
| 3 → 4           | 86   |
| 4 → 5           | 103  |
| 5 → 6           | 123  |
| 6 → 7           | 147  |
| 7 → 8           | 176  |
| 8 → 9           | 211  |
| 9 → 10          | 253  |

Total shards to max: 1281.

**Alternatives considered**:
- Pre-compute table in meta_config.json: Redundant — derivable from formula params; would
  need updating whenever base_cost or scale changes.
- Compute in UpgradeShop: Logic leak into UI component; UpgradeShop must know the formula.

---

## Decision 4: MetaState extension and save format

**Decision**: Add `damage_upgrade_level: int = 0` to `MetaState`. Save format becomes
`{"total_shards": N, "damage_upgrade_level": N}`. `SaveManagerImpl.load_meta_state()` uses
`.get("damage_upgrade_level", 0)` so existing saves without the field load cleanly at
level 0.

**Rationale**: MetaState already owns all persistent meta-progression data. Adding one int
field is the minimum change. Backward-compatible load via `.get(..., 0)` default means no
migration needed for existing saves.

**Alternatives considered**:
- Separate save file for upgrade data: Overkill for one int field; increases I/O surface.

---

## Decision 5: UpgradeShop — co-located component in scenes/hub/

**Decision**: `scenes/hub/UpgradeShop.gd` extends `Control`, with `@export var _button: Button`.
Node hierarchy added to `HubRoom.tscn` in Editor. Connects to `MetaManager.shards_changed`
in `_ready()` to reactively update affordability. Co-located because it is exclusively a
component of HubRoom.tscn (same exception as ShardDisplay.gd).

**Rationale**: Follows the established co-located component pattern. The button only exists
in the hub; no standalone .tscn needed (YAGNI). Connecting to `shards_changed` ensures
the button enables/disables correctly if shards change for any reason (run-end conversion,
future grants) without polling.

**Alternatives considered**:
- Standalone UpgradeShop.tscn: YAGNI — only used in HubRoom. Adds file overhead.
- Put logic in HubRoom.gd: SRP violation — HubRoom manages hub lifecycle, not upgrade UI.
