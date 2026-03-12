# Research: Unit Test Suite (039-gut-unit-tests)

## GUT Framework Conventions

**Decision**: Follow the pattern established in `tests/unit/test_shard_conversion.gd`.

Key conventions:
- File: `extends GutTest`, no `class_name` needed
- Test functions: `func test_<scenario_name>()` prefix — GUT auto-discovers them
- Assertions: `assert_eq(actual, expected, "message")`, `assert_true(cond)`, `assert_false(cond)`
- Preload subject under test at top of file: `const Subject = preload("res://path/to/Subject.gd")`
- Instantiate with `.new()` per test where state isolation is needed
- No `before_each` / `after_each` needed for purely stateless functions

## Autoload Dependency Problem

**Problem**: `DungeonGenerator._generate()` calls `ResourceManager.get_dungeon_config()` and reads `MetaManager.is_adventuring_gear_owned`. `ExplorationHUD._on_room_cleared_for_boss()` calls `ResourceManager.get_enemy_rooms_required()` and reads `RunManager.cleared_rooms`. Tests must not depend on autoloads (FR-009).

**Decision**: Thin refactors to two source files:

1. **`DungeonGenerator`** — extract the algorithm body into `_generate_with(config: Dictionary, gear_owned: bool) -> void`. The existing `_generate()` shell calls `_generate_with(ResourceManager.get_dungeon_config(), MetaManager.is_adventuring_gear_owned)`. Tests call `_generate_with(stub_config, false)` directly. No behavioural change.

2. **`ExplorationHUD`** — extract the threshold condition into a single `static func is_boss_available(cleared_count: int, required: int) -> bool`. `_on_room_cleared_for_boss()` calls it. Tests import `ExplorationHUD` and call `ExplorationHUD.is_boss_available(n, 6)` directly — no scene, no autoload.

**Rationale**: Both refactors are the minimum change that makes tests possible without mocking autoloads. `RelicManagerImpl` and `MetaManagerImpl` are already autoload-free (`build_pool` takes raw dicts; `get_upgrade_cost` is a pure function).

## Stub Data Structure

**RelicManagerImpl stub**: `build_pool(relics_raw, config_raw)` needs:
```gdscript
{
    "relics": {
        "common": { "relic_a": { "name": "A", "effect_stat": "attack_damage", "effect_mult": 1.1 }, ... },
        "rare":   { "relic_x": { "name": "X", "effect_stat": "attack_damage", "effect_mult": 1.2 }, ... },
    }
}
```
Config needs `relic_tier_weights: { "common": 1.0 }` (no rare weight = rare excluded from standard draws).

**DungeonGenerator stub**:
```gdscript
{ "combat_room_pool": ["CombatRoom01", "CombatRoom02"], "base_room_count": 9, "difficulty_scale": 0.12, "expansion_room_count": 4 }
```

## Alternatives Considered

| Option | Decision |
|--------|----------|
| GUT `partial_double()` to stub autoloads in-place | Rejected — adds GUT double complexity; thin refactors are simpler and improve production code |
| Test via full scene with autoloads registered | Rejected — fragile, slow, requires full project context |
| Move generation logic to a `DungeonGeneratorImpl` RefCounted | Rejected (YAGNI) — `_generate_with` parameter split achieves the same testability with fewer lines |
