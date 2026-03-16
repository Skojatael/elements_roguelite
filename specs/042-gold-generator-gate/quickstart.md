# Quickstart: Gold Generator Gate (042)

## What this feature changes

Adds a one-time shard purchase ("Transmuter", 50 shards) inside the Alchemy Lab upgrade screen. Gold accumulation (in-session and offline) is suppressed until this upgrade is purchased.

## Files touched

| File | Change type |
|------|-------------|
| `data/meta_config.json` | Add `gold_generator` under `alchemy_lab.upgrades` |
| `scripts/data_models/MetaState.gd` | Add `gold_generator_owned: bool` field |
| `scripts/managers/SaveManager.gd` | Serialize / deserialize `gold_generator_owned` |
| `scripts/managers/MetaManager.gd` | Guard `tick_gold` + `apply_offline_gold`; add `purchase_gold_generator()` |
| `autoload/MetaManager.gd` | Add `is_gold_generator_owned` property + `purchase_gold_generator()` delegation |
| `scenes/hub/LabUpgradeScreen.gd` | Add `_transmuter_button` export, handler, `_update_transmuter_button()` |
| `scenes/hub/LabUpgradeScreen.tscn` | Add `TransmuterButton` node (Editor task) |

## Manual verification steps

### Pre-purchase state (gate active)
1. Launch the game with a fresh save (or one without `gold_generator_owned`).
2. Enter the hub — gold display should show **0**.
3. Wait 60 seconds — gold display must remain **0**.
4. Close and reopen the game — gold display must still be **0** (no offline credit).

### Purchase flow
5. Accumulate ≥ 50 shards via runs.
6. Open the Alchemy Lab → upgrade screen.
7. Verify "Transmuter (50 shards)" button is enabled.
8. Press it — shard balance decreases by 50, button shows "Transmuter — ACTIVE" (disabled).
9. Within 1 second, the gold display begins incrementing (or will increment within ~36 s depending on rate).

### Post-purchase state (gate cleared)
10. Close the game, wait ≥ 1 minute, reopen.
11. Gold should have increased by approximately `elapsed_minutes / 60 × 100` (e.g., 1 min → ~1.67, floor = 1).
12. Open Alchemy Lab again — Transmuter still shows "ACTIVE" (no re-purchase offered).

### Affordability guard
13. Start with < 50 shards and open the Alchemy Lab — Transmuter button must be **disabled**.

### Data-driven config check
14. Change `"cost": 50` to `"cost": 999` in `data/meta_config.json`, relaunch.
15. The button text should now read "Transmuter (999 shards)" and require 999 shards to enable — no script edits needed.
16. Revert the change.

## Common pitfalls

- **Don't** add logic to `MetaManager._process()` to gate the tick — the gate belongs in `MetaManagerImpl.tick_gold()`.
- **Don't** hard-code the cost (50) anywhere in scripts — always read from `ResourceManager.get_meta_config()`.
- **Don't** connect `_transmuter_button.pressed` in the Godot Editor signal dock if it's already wired in `_ready()` — double connections cause double purchase attempts.
