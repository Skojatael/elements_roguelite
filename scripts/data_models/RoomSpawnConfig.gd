class_name RoomSpawnConfig
extends Resource

var room_id: String
var spawn_points: Array[SpawnPointData]


static func from_dict(p_room_id: String, data: Dictionary) -> RoomSpawnConfig:
	var cfg := RoomSpawnConfig.new()
	cfg.room_id = p_room_id
	for entry: Variant in data.get("spawn_points", []):
		cfg.spawn_points.append(SpawnPointData.from_dict(entry))
	return cfg
