class_name SpawnPointData
extends Resource

var enemy_id: String
var position: Vector2
var radius: float


static func from_dict(data: Dictionary) -> SpawnPointData:
	assert(data.has("enemy_id"), "SpawnPointData: missing field 'enemy_id'")
	assert(data.has("position"), "SpawnPointData: missing field 'position'")
	assert(data.has("radius"), "SpawnPointData: missing field 'radius'")

	var s := SpawnPointData.new()
	s.enemy_id = data["enemy_id"]
	var pos: Dictionary = data["position"]
	s.position = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
	s.radius = float(data["radius"])
	return s
