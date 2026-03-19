# Quickstart: Relic Deck Count

## What this feature does

Adds a `deck_count` integer to every relic entry in `data/relics.json`. The number controls how many copies of that relic exist in the per-tier draw pool. Relics with higher counts appear more often in offers. Also renames the `sharp_edge` relic ID to `common_damage`.

## Files changed

| File | Change |
|---|---|
| `data/relics.json` | Add `deck_count` to all entries; rename `sharp_edge` → `common_damage` |
| `scripts/data_models/RelicData.gd` | Add `deck_count: int = 1` field; parse in `from_dict` |
| `scripts/managers/RelicManagerImpl.gd` | Add `_build_expanded_deck` helper; use it in `build_pool`, `_draw_one_from_tier`, `draw_offer` |

## No scene / editor work required

This feature is purely data + script. No `.tscn` files are modified and no Godot Editor steps are needed.

## Verification

1. Open DevPanel, start a run, trigger multiple relic offers.
2. Confirm `common_damage` (Whetstone) appears more frequently than `common_regen` (Regeneration Stone) across many offers.
3. Confirm `sharp_edge` never appears (would show as a missing-relic error or simply not appear).
4. Run `tests/unit/` if unit tests exist for `RelicManagerImpl`.
