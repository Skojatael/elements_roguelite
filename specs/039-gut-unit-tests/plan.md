# Implementation Plan: Unit Test Suite

**Branch**: `039-gut-unit-tests` | **Date**: 2026-03-12 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/039-gut-unit-tests/spec.md`

## Summary

Add four GUT unit test files covering upgrade cost formula, dungeon layout correctness, relic deck uniqueness/tier exclusion, and boss teleport unlock threshold. Two minimal source refactors enable autoload-free testing: `DungeonGenerator._generate_with()` parameter split and `ExplorationHUD.is_boss_available()` static helper.

## Technical Context

**Language/Version**: GDScript 4.6
**Primary Dependencies**: GUT addon (`addons/gut/`) — already installed
**Storage**: N/A (no persistence; stub data inlined in tests)
**Testing**: GUT framework (`extends GutTest`)
**Target Platform**: Development only (Windows editor); tests do not run on mobile
**Project Type**: Single Godot project
**Performance Goals**: Each test under 1 second (GUT assertion overhead is negligible)
**Constraints**: No autoload dependencies in test code (FR-009); pure function calls only
**Scale/Scope**: 4 test files, ~25 test functions total

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked post-design.*

- **I. Single Responsibility** ✅ — Each test file covers one subject. Source refactors add `_generate_with` (same file, same responsibility) and a static helper to `ExplorationHUD` (same file, same responsibility). No new autoloads.
- **II. Data-Driven Content** ✅ — Test stub data (inline dicts) is not game-balance content; no JSON changes required. Production config values remain in `res://data/`.
- **III. Mobile-First Performance** ✅ N/A — Test code runs only in the editor; no mobile impact.
- **IV. Editor-Centric Workflow** ✅ — No scenes created or modified. No `.tscn` edits.
- **V. Simplicity & YAGNI** ✅ — Refactors are the minimum needed (parameter split, one static function). No new abstractions or base classes introduced.
- **VI. Early Return** ✅ — Test helper `is_boss_available` is a single-expression return. `_generate_with` preserves the existing guard clauses.

**Result**: All principles pass. No complexity tracking required.

## Project Structure

### Documentation (this feature)

```text
specs/039-gut-unit-tests/
├── plan.md              ← this file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code Changes

```text
scripts/dungeon/DungeonGenerator.gd      ← refactor: _generate_with() split
scenes/ui/hud/ExplorationHUD.gd          ← add: static is_boss_available()

tests/unit/
├── test_shard_conversion.gd             ← existing (reference example)
├── test_upgrade_cost.gd                 ← NEW
├── test_dungeon_generation.gd           ← NEW
├── test_relic_deck.gd                   ← NEW
└── test_boss_unlock.gd                  ← NEW
```

## Phase 0: Research

**Completed** — see `research.md`.

Key findings:
- GUT pattern: `extends GutTest`, `test_*` functions, `preload` subject at top of file.
- Autoload problem resolved via two thin source refactors (not mocking).
- `RelicManagerImpl` and `MetaManagerImpl` are already autoload-free.
- Stub data structures defined in `data-model.md`.

## Phase 1: Design

### Source Refactor 1 — DungeonGenerator

**File**: `scripts/dungeon/DungeonGenerator.gd`

Split `_generate()` into a shell and a pure algorithm method:

```gdscript
func _generate() -> void:
    _generate_with(ResourceManager.get_dungeon_config(), MetaManager.is_adventuring_gear_owned)

func _generate_with(config: Dictionary, gear_owned: bool) -> void:
    # existing body of _generate(), replacing local `raw` var with `config`
    # replacing MetaManager.is_adventuring_gear_owned with `gear_owned`
```

Tests call `generator._generate_with(STUB_CONFIG, false)` on an instantiated `DungeonGenerator` node added to the scene tree (`add_child_autofree(generator)`). After the call, `generator.rooms_by_id` and `generator.neighbours_by_id` are inspected.

**Connectivity helper** (inside test file — not in production code):
```gdscript
func _all_reachable(generator: DungeonGenerator) -> bool:
    var visited: Dictionary = {}
    var queue: Array = [generator.start_room_id]
    while not queue.is_empty():
        var id: String = queue.pop_back()
        if visited.has(id): continue
        visited[id] = true
        for n: String in generator.neighbours_by_id.get(id, []):
            queue.append(n)
    return visited.size() == generator.rooms_by_id.size()
```

### Source Refactor 2 — ExplorationHUD

**File**: `scenes/ui/hud/ExplorationHUD.gd`

Add one static method:
```gdscript
static func is_boss_available(cleared_count: int, required: int) -> bool:
    return cleared_count >= required
```

Update `_on_room_cleared_for_boss()` to call it:
```gdscript
if not ExplorationHUD.is_boss_available(RunManager.cleared_rooms.size(), threshold):
    return
```

Tests preload `ExplorationHUD` and call `ExplorationHUD.is_boss_available(n, 6)` directly. No scene instance required.

### Test File Designs

#### test_upgrade_cost.gd
```
preload MetaManagerImpl
var impl: MetaManagerImpl

test_cost_at_level_0_equals_base()      → get_upgrade_cost(0, 50, 1.2) == 50
test_cost_at_level_1()                  → get_upgrade_cost(1, 50, 1.2) == 60
test_cost_at_level_2()                  → get_upgrade_cost(2, 50, 1.2) == 72
test_cost_at_level_3_through_9()        → assert full table [86,103,123,147,176,211,253]
test_cost_at_level_0_any_base()         → get_upgrade_cost(0, 100, 1.2) == 100
test_cost_zero_base()                   → get_upgrade_cost(5, 0, 1.2) == 0
```

#### test_dungeon_generation.gd
```
preload DungeonGenerator
STUB_CONFIG: Dictionary (9 rooms, 2-type pool)

test_room_count_base()                  → rooms_by_id.size() == 9 (no gear)
test_connectivity_multi_seed()          → run 5× with seed_override, all connected
test_neighbour_symmetry()               → for every A→B in neighbours_by_id, B→A exists
test_start_room_always_present()        → start_room_id in rooms_by_id
```

#### test_relic_deck.gd
```
preload RelicManagerImpl
STUB_RELICS, STUB_CONFIG (3 common, 2 rare)

test_no_duplicates_single_pass()        → draw 3 relics, all IDs distinct
test_reshuffle_restores_full_deck()     → draw 3, draw 3 again, second pass also distinct
test_draw_offer_pair_distinct()         → draw_offer()[0].id != draw_offer()[1].id (10× loop)
test_draw_offer_never_returns_rare()    → draw 20 offers, none have tier=="rare"
test_boss_offer_only_rare()             → draw_boss_offer(), all have tier=="rare"
test_boss_offer_excludes_held()         → pick relic_x, draw_boss_offer(), relic_x absent
test_boss_offer_empty_when_all_held()   → hold all rares, draw_boss_offer() returns []
```

#### test_boss_unlock.gd
```
preload ExplorationHUD (for static method access only)

test_unavailable_below_threshold()      → is_boss_available(5, 6) == false
test_available_at_threshold()           → is_boss_available(6, 6) == true
test_available_above_threshold()        → is_boss_available(10, 6) == true
test_unavailable_at_zero()              → is_boss_available(0, 6) == false
test_available_at_zero_threshold()      → is_boss_available(0, 0) == true
```

## Complexity Tracking

*No constitution violations — table not required.*
