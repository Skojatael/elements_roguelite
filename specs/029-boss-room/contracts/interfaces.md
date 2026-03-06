# Contracts & Interfaces: Boss Room

**Feature**: [spec.md](../spec.md)
**Date**: 2026-03-05

---

## EnemyData.gd — rooms_required field

```gdscript
# scripts/data_models/EnemyData.gd
class_name EnemyData
extends Resource

# ... existing fields unchanged ...
var rooms_required: int = 0  # NEW — 0 for non-boss enemies

static func from_dict(data: Dictionary) -> EnemyData:
    # ... existing assertions and field assignments unchanged ...
    d.rooms_required = int(data.get("rooms_required", 0))  # NEW — optional field
    return d
```

---

## Enemy.gd — lookup loop update

`parsed["enemies"]` is now a Dictionary (not an Array). The inner search loop must iterate over category values.

```gdscript
# scenes/combat/enemies/Enemy.gd  — _ready(), replace the lookup block

var enemies_root: Dictionary = parsed.get("enemies", {})
var entry: Dictionary = {}
for category: Variant in enemies_root.values():
    if category is Array:
        for item: Variant in category:
            if item is Dictionary and item.get("id", "") == enemy_type_id:
                entry = item
                break
    if not entry.is_empty():
        break
assert(not entry.is_empty(),
    "Enemy: no entry found in enemies.json for id '%s'" % enemy_type_id)
```

---

## ResourceManagerImpl — get_enemy_rooms_required

`_load_enemy_data()` is updated to iterate the category dictionary rather than a flat array.

```gdscript
# scripts/managers/ResourceManager.gd

# Add to cache fields:
var _enemy_rooms_required_cache: Dictionary = {}

# Full _load_enemy_data() replacement:
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

## Returns the rooms_required value for the given enemy id. Returns 0 for non-boss enemies
## or unknown ids.
func get_enemy_rooms_required(id: String) -> int:
    if not _enemy_ids_loaded:
        _load_enemy_data()
    return _enemy_rooms_required_cache.get(id, 0)
```

---

## ResourceManager autoload — wrapper

```gdscript
# autoload/ResourceManager.gd

func get_enemy_rooms_required(id: String) -> int:
    return _impl.get_enemy_rooms_required(id)
```

---

## RoomLoader — free_current_room

```gdscript
# scripts/dungeon/RoomLoader.gd

## Frees the current room scene and clears RunManager.current_room.
## Called by Main.gd before spawning the boss room to cleanly hand off ownership.
func free_current_room() -> void:
    if _current_room_node != null:
        RunManager.current_room = null
        _current_room_node.queue_free()
        _current_room_node = null
```

---

## ExplorationHUD — boss button signal and logic

```gdscript
# scenes/ui/hud/ExplorationHUD.gd

const BOSS_ENEMY_ID: String = "boss"

## Emitted when the player presses the Teleport to Boss button.
## Main.gd connects to this signal to handle the teleportation.
signal boss_teleport_pressed

@export var _boss_button: Button


func _ready() -> void:
    # ... existing connections unchanged ...
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

---

## Main.gd — boss teleport handler and camera fallback

```gdscript
# scenes/core/Main.gd

const _BOSS_ROOM_DATA := preload("res://data/rooms/BossRoom01.tres")
const BOSS_ROOM_WORLD_POS: Vector2 = Vector2(0.0, -3000.0)

@onready var _room_loader: RoomLoader = $RoomLoader  # NEW


func _ready() -> void:
    # ... existing connections ...
    _exploration_hud.boss_teleport_pressed.connect(_on_boss_teleport_pressed)  # NEW


func _process(_delta: float) -> void:
    if RunManager.current_room != null:
        var room_id: String = (RunManager.current_room as RoomSpawner).room_id
        if _dungeon_gen.rooms_by_id.has(room_id):
            _camera.global_position = _dungeon_gen.rooms_by_id[room_id]["world_pos"]
        else:
            # Boss room (and any future out-of-grid rooms) — use scene position directly
            _camera.global_position = (RunManager.current_room as RoomSpawner).get_parent().global_position


func _on_boss_teleport_pressed() -> void:
    # 1. Free the current dungeon room cleanly
    _room_loader.free_current_room()
    # 2. Compute HP scaling
    var rooms_cleared: int = RunManager.cleared_rooms.size()
    var boss_mult: float = 1.0 + 0.06 * float(rooms_cleared)
    # 3. Spawn boss room
    var context: SpawnContext = SpawnContext.create(self, BOSS_ROOM_WORLD_POS)
    var spawner: RoomSpawner = RunManager.spawn_room(_BOSS_ROOM_DATA, "boss_room", context)
    spawner.difficulty_mult = boss_mult
    # 4. Place player at boss room center
    _player.global_position = BOSS_ROOM_WORLD_POS
    # 5. Snap camera (sustained by _process fallback thereafter)
    _camera.global_position = BOSS_ROOM_WORLD_POS
    print("[Main] boss teleport — rooms_cleared={r} boss_mult={m}".format({"r": rooms_cleared, "m": boss_mult}))
```

---

## ExplorationHUD.tscn — editor task

Add a `Button` node as a child of the ExplorationHUD CanvasLayer:
- **Node name**: `BossButton`
- **Text**: `"Teleport to Boss"` (placeholder — visual design deferred)
- **Assign to export**: `_boss_button` in Inspector

---

## Signal flow summary

```
RunManager.room_cleared
  → ExplorationHUD._on_room_cleared_for_boss()
      → if threshold met: _boss_button.visible = true

Player presses BossButton
  → ExplorationHUD._on_boss_button_pressed()
      → boss_teleport_pressed.emit()
          → Main._on_boss_teleport_pressed()
              → RoomLoader.free_current_room()
              → RunManager.spawn_room(BossRoom01, "boss_room", context)
              → spawner.difficulty_mult = boss_mult
              → player placed at BOSS_ROOM_WORLD_POS
              → camera snapped to BOSS_ROOM_WORLD_POS

Player enters BossRoom01 EntryArea
  → RoomSpawner._on_player_entered()
      → room_entered.emit("boss_room")
      → _spawn_enemies.call_deferred()
          → Enemy instantiated with enemy_type_id="boss"
          → enemy.apply_difficulty(boss_mult)
              → max_health = 40.0 × boss_mult

Enemy defeated
  → RoomSpawner._on_enemy_defeated()
      → room_cleared.emit("boss_room")
          → RunManager.mark_room_cleared("boss_room")
          → RunManager.run_summary reflects rooms_cleared += 1
```
