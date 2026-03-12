# Quickstart: Running the Unit Tests

## Prerequisites

- Godot 4.6 Editor open with `project.godot`
- GUT addon installed and enabled (`addons/gut/`)

## Running All Tests

1. Open **GUT Panel** in the Godot Editor (bottom dock tab, or via `Scene → GUT`)
2. Click **Run All** to execute every test file under `res://tests/`
3. A green bar with `0 failures, 0 errors` is the passing state

## Running a Single File

In the GUT panel, click the file icon next to the file you want to run:

| File | What it tests |
|------|--------------|
| `tests/unit/test_upgrade_cost.gd` | `MetaManagerImpl.get_upgrade_cost` cost table |
| `tests/unit/test_dungeon_generation.gd` | Connectivity and room count |
| `tests/unit/test_relic_deck.gd` | No duplicates, rare exclusion from standard offers, boss offers |
| `tests/unit/test_boss_unlock.gd` | Threshold check boundaries |

## Source Refactors Required Before Tests Pass

Two source files must be updated (see plan.md Phase 1 tasks):

1. **`scripts/dungeon/DungeonGenerator.gd`**: `_generate()` must delegate to `_generate_with(config, gear_owned)`.
2. **`scenes/ui/hud/ExplorationHUD.gd`**: Add `static func is_boss_available(cleared_count: int, required: int) -> bool`.

Tests will fail to compile until these are in place.

## Expected Output (passing)

```
Running tests/unit/test_upgrade_cost.gd
  PASS test_cost_at_level_0_equals_base
  PASS test_cost_at_level_1
  ... (10 assertions)
Running tests/unit/test_dungeon_generation.gd
  PASS test_room_count_base
  PASS test_connectivity_run_1
  ... (5 runs × connectivity + count)
Running tests/unit/test_relic_deck.gd
  PASS test_no_duplicates_single_pass
  PASS test_reshuffle_restores_full_deck
  PASS test_draw_offer_pair_distinct
  PASS test_draw_offer_never_returns_rare
  PASS test_boss_offer_only_rare
  PASS test_boss_offer_excludes_held_relic
Running tests/unit/test_boss_unlock.gd
  PASS test_unavailable_below_threshold
  PASS test_available_at_threshold
  PASS test_available_above_threshold
  PASS test_unavailable_at_zero
```
