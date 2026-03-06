# Implementation Plan: Boss Room

**Branch**: `029-boss-room` | **Date**: 2026-03-05 | **Spec**: [spec.md](spec.md)

## Summary

Add a data-driven boss encounter accessible via a "Teleport to Boss" button in the run HUD. The boss is a single enemy defined entirely in `enemies.json` (stats + rooms-cleared threshold). HP scales as `base_hp × (1 + 0.06 × rooms_cleared)` using the existing `apply_difficulty()` pathway. The button appears when `cleared_rooms.size() >= rooms_required`. Boss room spawns at a fixed world position outside the dungeon grid; camera tracks it via a new fallback branch in `Main._process()`.

## Technical Context

**Language/Version**: GDScript (Godot 4.6), static typing
**Primary Dependencies**: `enemies.json`, `dungeon_config.json`, `BossRoom01.tres` (pre-existing), `RoomSpawner` (existing), `Enemy` (existing)
**Storage**: N/A — no persistent state changes
**Testing**: Manual — see quickstart.md
**Target Platform**: Android mobile / Windows dev
**Performance Goals**: Negligible — one enemy, one button, one float multiply
**Constraints**: No new autoloads; no new .tscn files except editor task to add button node; no changes to Enemy.gd or RoomSpawner.gd combat logic
**Scale/Scope**: 9 files modified (4 data, 5 scripts); 1 editor scene task

## Constitution Check

- **I. Thin-wrapper rule**: ResourceManagerImpl gains `get_enemy_rooms_required()` (logic); autoload ResourceManager exposes the wrapper. ExplorationHUD script contains show/hide logic; signal flows to Main.gd. ✅
- **II. Data-Driven Content**: All boss stats (`max_health`, `damage`, `damage_cooldown`, `rooms_required`) in `enemies.json`. Boss spawn config in `dungeon_config.json`. Scaling factor 0.06 fixed in code per spec assumption (consistent with essence scaling pattern). ✅
- **III. Mobile-First**: One Button node added to ExplorationHUD. No new CanvasLayers, no scene graph overhead. ✅
- **IV. Editor-Centric**: Boss button added via Godot Editor (export + Inspector). All room scenes pre-exist. ✅
- **V. Simplicity & YAGNI**: Reuses `apply_difficulty()`, `spawn_room()`, `SpawnContext`, existing `RoomSpawner` signals. Camera fallback is 2 lines. `free_current_room()` is 4 lines. No new abstractions. ✅

## Project Structure

### Documentation (this feature)

```text
specs/029-boss-room/
├── plan.md              ← this file
├── research.md          ✅
├── data-model.md        ✅
├── quickstart.md        ✅
├── contracts/
│   └── interfaces.md    ✅
└── tasks.md             ← /speckit.tasks output
```

### Source Changes

```text
data/
├── enemies.json                          [MODIFIED] restructure flat array → category dict + add boss entry
└── dungeon_config.json                   [MODIFIED] add BossRoom01 spawn_config

scripts/data_models/
└── EnemyData.gd                          [MODIFIED] add rooms_required field

scripts/managers/
└── ResourceManager.gd                    [MODIFIED] update _load_enemy_data() for new schema + add method

scripts/dungeon/
└── RoomLoader.gd                         [MODIFIED] add free_current_room()

autoload/
└── ResourceManager.gd                    [MODIFIED] add wrapper method

scenes/combat/enemies/
└── Enemy.gd                              [MODIFIED] update lookup loop for new enemies.json schema

scenes/ui/hud/
└── ExplorationHUD.gd                     [MODIFIED] add boss button signal + logic

scenes/core/
└── Main.gd                               [MODIFIED] boss teleport handler, camera fallback

scenes/ui/hud/
└── ExplorationHUD.tscn                   [MODIFIED — editor task] add BossButton node
```

## Implementation

### Phase 1: Data Layer

**`data/enemies.json`** — full file replacement: restructure `"enemies"` from a flat array to a category dictionary, then add boss entry. Category keys (`"common"`, `"boss"`) are not read by game code; consumers iterate all values via `.values()`.

```json
{
    "enemies": {
        "common": [
            {
                "id": "slime",
                "display_name": "Slime",
                "max_health": 10.0,
                "damage": 1.0,
                "move_speed": 60.0,
                "detection_range": 200.0,
                "damage_cooldown": 0.5,
                "base_essence": 10
            },
            {
                "id": "skeleton",
                "display_name": "Skeleton",
                "max_health": 8.0,
                "damage": 2.0,
                "move_speed": 80.0,
                "detection_range": 250.0,
                "damage_cooldown": 1.0,
                "base_essence": 15
            }
        ],
        "boss": [
            {
                "id": "boss",
                "display_name": "Boss",
                "max_health": 40.0,
                "damage": 5.0,
                "move_speed": 60.0,
                "detection_range": 300.0,
                "damage_cooldown": 2.0,
                "base_essence": 0,
                "rooms_required": 6
            }
        ]
    }
}
```

Note: `damage_cooldown: 2.0` satisfies spec `attack_interval=2` (same field, same semantics as existing enemies).

**`data/dungeon_config.json`** — add `BossRoom01` entry to `spawn_configs`:

```json
"BossRoom01": {
    "spawn_points": [
        { "enemy_id": "boss", "position": { "x": 0, "y": 0 }, "radius": 0 }
    ]
}
```

**`scripts/data_models/EnemyData.gd`** — add `rooms_required` field:

```gdscript
var rooms_required: int = 0  # add after base_essence

# In from_dict(), add after base_essence parse:
d.rooms_required = int(data.get("rooms_required", 0))
```

**`scripts/managers/ResourceManager.gd`** (ResourceManagerImpl) — add cache field, update `_load_enemy_data()` loop for new schema, add method:

```gdscript
# Add field:
var _enemy_rooms_required_cache: Dictionary = {}

# Replace _load_enemy_data() loop body (enemies is now a category dict):
func _load_enemy_data() -> void:
    var file := FileAccess.open("res://data/enemies.json", FileAccess.READ)
    assert(file != null, "ResourceManager: failed to open res://data/enemies.json")
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    file.close()
    assert(parsed is Dictionary, "ResourceManager: enemies.json root must be a Dictionary")

    var enemies_root: Variant = (parsed as Dictionary).get("enemies", {})
    if enemies_root is Dictionary:
        for category: Variant in (enemies_root as Dictionary).values():
            if category is Array:
                for entry: Variant in category:
                    if entry is Dictionary and entry.has("id"):
                        _enemy_ids_cache.append(entry["id"])
                        _enemy_essence_cache[entry["id"]] = float(entry.get("base_essence", 0.0))
                        _enemy_rooms_required_cache[entry["id"]] = int(entry.get("rooms_required", 0))
    _enemy_ids_loaded = true

# Add method:
func get_enemy_rooms_required(id: String) -> int:
    if not _enemy_ids_loaded:
        _load_enemy_data()
    return _enemy_rooms_required_cache.get(id, 0)
```

**`autoload/ResourceManager.gd`** — add wrapper:

```gdscript
func get_enemy_rooms_required(id: String) -> int:
    return _impl.get_enemy_rooms_required(id)
```

**`scenes/combat/enemies/Enemy.gd`** — update `_ready()` lookup to iterate category dict instead of flat array:

```gdscript
# Replace:
#   var enemies_array: Array = parsed["enemies"]
#   for item: Variant in enemies_array:
#       if item is Dictionary and item.get("id", "") == enemy_type_id:
#           entry = item
#           break

# With:
var enemies_root: Dictionary = parsed.get("enemies", {})
for category: Variant in enemies_root.values():
    if category is Array:
        for item: Variant in category:
            if item is Dictionary and item.get("id", "") == enemy_type_id:
                entry = item
                break
    if not entry.is_empty():
        break
```

### Phase 2: Room Lifecycle

**`scripts/dungeon/RoomLoader.gd`** — add public cleanup method:

```gdscript
## Frees the current room scene and clears RunManager.current_room.
## Called by Main.gd before spawning the boss room.
func free_current_room() -> void:
    if _current_room_node != null:
        RunManager.current_room = null
        _current_room_node.queue_free()
        _current_room_node = null
```

### Phase 3: ExplorationHUD — Boss Button

**`scenes/ui/hud/ExplorationHUD.gd`** — add boss button logic:

```gdscript
const BOSS_ENEMY_ID: String = "boss"

signal boss_teleport_pressed

@export var _boss_button: Button


func _ready() -> void:
    # ... existing code unchanged ...
    _boss_button.visible = false
    _boss_button.pressed.connect(_on_boss_button_pressed)
    RunManager.room_cleared.connect(_on_room_cleared_for_boss)
    RunManager.run_started.connect(func(_m: String) -> void: _boss_button.visible = false)


func _on_room_cleared_for_boss(_room_id: String) -> void:
    if _boss_button.visible:
        return
    var threshold: int = ResourceManager.get_enemy_rooms_required(BOSS_ENEMY_ID)
    if RunManager.cleared_rooms.size() >= threshold:
        _boss_button.visible = true


func _on_boss_button_pressed() -> void:
    _boss_button.visible = false
    boss_teleport_pressed.emit()
```

**`scenes/ui/hud/ExplorationHUD.tscn`** — editor task: add Button node named `BossButton`, assign to `_boss_button` export in Inspector. Text: `"Teleport to Boss"`.

### Phase 4: Main.gd — Teleport and Camera

**`scenes/core/Main.gd`** — four changes:

**1. Preload + constant** (top of file, after existing preloads):
```gdscript
const _BOSS_ROOM_DATA := preload("res://data/rooms/BossRoom01.tres")
const BOSS_ROOM_WORLD_POS: Vector2 = Vector2(0.0, -3000.0)
```

**2. RoomLoader reference** (after existing @onready vars):
```gdscript
@onready var _room_loader: RoomLoader = $RoomLoader
```

**3. Connect boss_teleport_pressed in _ready()** (after existing connections):
```gdscript
_exploration_hud.boss_teleport_pressed.connect(_on_boss_teleport_pressed)
```

**4. Replace _process() camera block** (extend with else fallback):
```gdscript
func _process(_delta: float) -> void:
    if RunManager.current_room != null:
        var room_id: String = (RunManager.current_room as RoomSpawner).room_id
        if _dungeon_gen.rooms_by_id.has(room_id):
            _camera.global_position = _dungeon_gen.rooms_by_id[room_id]["world_pos"]
        else:
            _camera.global_position = (RunManager.current_room as RoomSpawner).get_parent().global_position
```

**5. New method** (add after _on_dev_get_relic):
```gdscript
func _on_boss_teleport_pressed() -> void:
    _room_loader.free_current_room()
    var rooms_cleared: int = RunManager.cleared_rooms.size()
    var boss_mult: float = 1.0 + 0.06 * float(rooms_cleared)
    var context: SpawnContext = SpawnContext.create(self, BOSS_ROOM_WORLD_POS)
    var spawner: RoomSpawner = RunManager.spawn_room(_BOSS_ROOM_DATA, "boss_room", context)
    spawner.difficulty_mult = boss_mult
    _player.global_position = BOSS_ROOM_WORLD_POS
    _camera.global_position = BOSS_ROOM_WORLD_POS
    print("[Main] boss teleport — rooms_cleared={r} boss_mult={m}".format({"r": rooms_cleared, "m": boss_mult}))
```

## Key Design Decisions

### Why `difficulty_mult` for boss HP scaling
The existing `apply_difficulty(mult)` path in Enemy.gd and RoomSpawner already handles `max_health × mult`. Setting `spawner.difficulty_mult = (1.0 + 0.06 × rooms_cleared)` produces exactly the required formula. No new Enemy methods needed.

### Why `damage_cooldown` not `attack_interval`
`damage_cooldown` in Enemy.gd is the time between contact-damage ticks — identical semantics to `attack_interval`. Renaming would break existing enemies; a new field would duplicate semantics. Documented in research.md.

### Why boss room at Vector2(0, -3000)
North of hub (0,0). Dungeon northernmost row is at y=−2400. This position is 600 units clear of the grid, visually "above" the dungeon. Defined as a named constant.

### Why `free_current_room()` on RoomLoader
RoomLoader owns `_current_room_node`. Bypassing this ownership would cause a double-free in `_on_run_ended()`. One 4-line public method is the minimal clean interface.

### Why camera fallback in _process not a one-shot set
The `_process` loop continuously updates the camera. After teleport, the camera snap at the end of `_on_boss_teleport_pressed` handles the initial position, and `_process` sustains it via the else branch. This ensures the camera stays locked to the boss room even if any other code moves it temporarily.
