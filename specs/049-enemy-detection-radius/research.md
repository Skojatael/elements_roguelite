# Research: Enemy Detection Radius (049)

## Q1 — Where does the detection radius get applied?

**Decision**: Inside `Enemy.initialize(data: EnemyData)`, immediately after setting health fields.

**Rationale**: `initialize()` is the single entry point that receives a fully-parsed `EnemyData` instance. It already runs after all `@onready` vars are resolved (called from `_ready()`), so `_detection_area` is guaranteed non-null. No new method or hook is needed.

**Alternatives considered**:
- New `apply_detection_range()` method called from RoomSpawner — rejected: adds unnecessary call sites; `initialize()` is already the place for "apply data to this enemy instance".
- `_ready()` inline — rejected: would duplicate logic already centralised in `initialize()`.

---

## Q2 — How is a CircleShape2D radius set at runtime in Godot 4?

**Decision**: Get the first `CollisionShape2D` child of `_detection_area`, cast its `shape` to `CircleShape2D`, and set `radius`.

```gdscript
var shape_node := _detection_area.get_node("CollisionShape2D") as CollisionShape2D
(shape_node.shape as CircleShape2D).radius = _data.detection_range
```

**Rationale**: `CollisionShape2D.shape` is a `Shape2D` resource. In Godot 4, mutating the `radius` property on the resource instance changes it for that node directly. The shape resource in `DetectionArea`'s `CollisionShape2D` child is the DetectionArea's own instance (not shared across enemy instances when spawned via `instantiate()`), so mutating it is safe.

**Note**: Modifying a shared resource would affect all instances. `PackedScene.instantiate()` creates a deep copy of resources marked as local-to-scene, which is the default for collision shapes — confirmed safe.

**Alternatives considered**:
- `shape_node.shape = CircleShape2D.new()` — rejected: creates a new resource object; unnecessary overhead when we can mutate the existing one.

---

## Q3 — What fallback for invalid detection_range?

**Decision**: If `data.detection_range <= 0`, push a warning and use `300.0` as the fallback radius.

**Rationale**: 300px is large enough for enemies to reliably detect the player entering a room without being unreasonably large (room width ~1920px). The warning is printed to the Godot Output panel so designers are notified immediately.

**Alternatives considered**:
- Assert/crash — rejected: a bad data value shouldn't break a run in progress.
- Silent fallback — rejected: designers would never know the config was ignored.
