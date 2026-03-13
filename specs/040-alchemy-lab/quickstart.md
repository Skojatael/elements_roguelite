# Quickstart: Alchemy Lab (040)

## Minimal smoke test (no editor required)

1. Open DevPanel → grant yourself 600 shards (enough to cover 500 restore cost).
2. In the hub, tap the **Alchemy Lab** building:
   - Ruined visual should be showing; restore overlay opens.
   - Restore button shows "500 shards" and is enabled.
3. Confirm restoration:
   - Shard balance drops by 500.
   - Building switches to restored visual and "Alchemy Lab" label.
4. Tap the building again:
   - Upgrade screen opens (not the restore overlay).
   - Essence Gain entry shows "+5% (Lv1)" and a **disabled** button.
5. Restart the game (or reload the scene):
   - Building is still in restored state — persistence confirmed.

## Verify essence multiplier (level 0 = no effect)

With `essence_gain_level = 0`:
- Kill an enemy and observe the `[RunManager] currency +X` print.
- Value should match the existing formula (no change expected at level 0).

## Verify config-driven values

Edit `data/meta_config.json`:
- Change `alchemy_lab.cost` to `100`. Restore overlay should show "100 shards".
- Change `essence_gain.essence_per_level` to `0.10`. Upgrade screen should show "+10%".
No code changes should be needed for these edits to take effect.

## Key files

| File | Role |
|---|---|
| `data/meta_config.json` | Restoration cost + upgrade values |
| `scripts/data_models/MetaState.gd` | `alchemy_lab_unlocked`, `essence_gain_level` fields |
| `scripts/managers/MetaManager.gd` | `purchase_alchemy_lab()`, `essence_gain_multiplier` |
| `scripts/managers/SaveManager.gd` | Save/load of new MetaState fields |
| `autoload/MetaManager.gd` | `is_alchemy_lab_unlocked`, `purchase_alchemy_lab()`, `essence_gain_multiplier` |
| `scripts/managers/RunManager.gd` | Apply `essence_gain_multiplier` in `_on_enemy_defeated()` |
| `scenes/hub/AlchemyLab.gd` | Building controller (ruined/restored routing) |
| `scenes/hub/RestoreLabOverlay.gd` | Restore confirmation dialog |
| `scenes/hub/LabUpgradeScreen.gd` | Upgrade list screen |
| `scenes/hub/AlchemyLab.tscn` | **Editor task** — create scene |
| `scenes/hub/RestoreLabOverlay.tscn` | **Editor task** — create scene |
| `scenes/hub/LabUpgradeScreen.tscn` | **Editor task** — create scene |
| `scenes/hub/HubRoom.tscn` | **Editor task** — add AlchemyLab node |
