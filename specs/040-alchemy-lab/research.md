# Research: Alchemy Lab (040)

## Decision 1: Scene/Script pattern — reuse Magic Forge exactly

**Decision**: Mirror `MagicForge.gd` / `RestoreForgeOverlay.gd` / `ForgeUpgradeScreen.gd` for the three new scripts (`AlchemyLab.gd`, `RestoreLabOverlay.gd`, `LabUpgradeScreen.gd`). No shared base class.

**Rationale**: Constitution V (YAGNI) prohibits abstractions until two concrete call sites exist *and* the abstraction is clearly needed. The Magic Forge and Alchemy Lab differ in state fields, purchase calls, and config keys — a base class would couple them without simplifying either. Three files each with a single responsibility is cleaner.

**Alternatives considered**: A `BaseHubBuilding` parent class — rejected (no third building planned, and the variation points are not the same between buildings).

---

## Decision 2: Essence gain multiplier injection point

**Decision**: Add `MetaManager.essence_gain_multiplier: float` (computed property) and apply it inside `RunManager._on_enemy_defeated()` as a final multiplier in the essence formula.

**Rationale**: This is the same pattern as `MetaManager.damage_multiplier` applied in `CombatComponent`. Essence is computed per-kill in `_on_enemy_defeated()` — injecting the multiplier there is the minimal change with no new wiring. `RunManager` already imports `MetaManager` (it is an autoload); no new dependency is introduced.

**Alternatives considered**:
- Applying multiplier in `add_currency()` — rejected, too broad (boss rewards also call `add_currency` and should not be affected).
- A `RunManager.essence_multiplier` field set at `start_run()` — rejected, more moving parts than necessary.

Updated essence formula:
```
essence = floori(base × (1 + depth_scale × (depth − 1)) × room_mult × MetaManager.essence_gain_multiplier)
```
At level 0 the multiplier is 1.0 — no change to current behaviour.

---

## Decision 3: MetaState fields

**Decision**: Add two fields to `MetaState`:
- `alchemy_lab_unlocked: bool = false`
- `essence_gain_level: int = 0`

**Rationale**: `alchemy_lab_unlocked` gates the visual state and overlay routing (same pattern as `magic_forge_unlocked`). `essence_gain_level` is needed to compute `essence_gain_multiplier` and to display current level in the upgrade screen. Although it will be 0 in this iteration (button disabled), omitting it would require a save-file migration when purchasing is enabled — adding it now is the lower-cost path and is not speculative (it is required by the current upgrade display logic).

---

## Decision 4: Config key shape

**Decision**: Add `"alchemy_lab"` block to `data/meta_config.json` following the exact shape of `"magic_forge"`:

```json
"alchemy_lab": {
    "name": "Alchemy Lab",
    "cost": 500,
    "upgrades": {
        "essence_gain": {
            "name": "Essence Gain",
            "base_cost": 0,
            "max_levels": 1,
            "essence_per_level": 0.05
        }
    }
}
```

`base_cost: 0` is the sentinel that disables the purchase button. `essence_per_level: 0.05` drives the +5% displayed bonus. All upgrade screen code reads these values — no hardcoded numbers.

---

## Decision 5: No new autoload

**Decision**: All new logic goes through existing autoloads (`MetaManager`, `ResourceManager`, `RunManager`). No new autoload is created.

**Rationale**: Constitution I forbids new autoloads unless a new domain is introduced. The Alchemy Lab is meta-progression (MetaManager's domain). Creating an `AlchemyLabManager` autoload would violate SRP by splitting meta-progression across two autoloads.
