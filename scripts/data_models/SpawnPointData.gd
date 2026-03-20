class_name SpawnPointData
extends Resource

var enemy_id: String
var position: Vector2
var radius: float
var enemy_pool: Array  # Array of {enemy_id: String, weight: int}


static func from_dict(data: Dictionary) -> SpawnPointData:
	assert(data.has("position"), "SpawnPointData: missing field 'position'")
	assert(data.has("radius"), "SpawnPointData: missing field 'radius'")

	var s := SpawnPointData.new()
	var pos: Dictionary = data["position"]
	s.position = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
	s.radius = float(data["radius"])

	if data.has("pool"):
		s.enemy_pool = data["pool"]
	else:
		assert(data.has("enemy_id"), "SpawnPointData: missing field 'enemy_id' (and no 'pool')")
		s.enemy_id = data["enemy_id"]
		s.enemy_pool = [{"enemy_id": data["enemy_id"], "weight": 100}]

	return s


func pick_enemy_id() -> String:
	if enemy_pool.is_empty():
		push_warning("SpawnPointData: pick_enemy_id() called on empty pool")
		return ""
	if enemy_pool.size() == 1:
		return enemy_pool[0]["enemy_id"]
	var total_weight: float = 0.0
	for entry: Variant in enemy_pool:
		total_weight += float((entry as Dictionary).get("weight", 0))
	var roll: float = randf() * total_weight
	var accumulated: float = 0.0
	for entry: Variant in enemy_pool:
		accumulated += float((entry as Dictionary).get("weight", 0))
		if roll < accumulated:
			return (entry as Dictionary).get("enemy_id", "")
	return (enemy_pool[enemy_pool.size() - 1] as Dictionary).get("enemy_id", "")
