class_name RoomSpawnConfig
extends Resource

var room_id: String
var spawn_points: Array[SpawnPointData]
var enemy_count_mult: float = 1.0
var essence_mult: float = 1.0
var wave_config: WaveConfig = null
var wave_spawn_points: Array  # Array of Array[SpawnPointData], indexed by wave


static func from_dict(p_room_id: String, data: Dictionary) -> RoomSpawnConfig:
	var cfg := RoomSpawnConfig.new()
	cfg.room_id = p_room_id
	for entry: Variant in data.get("spawn_points", []):
		cfg.spawn_points.append(SpawnPointData.from_dict(entry))
	cfg.enemy_count_mult = float(data.get("enemy_count_mult", 1.0))
	cfg.essence_mult = float(data.get("essence_mult", 1.0))
	return cfg
