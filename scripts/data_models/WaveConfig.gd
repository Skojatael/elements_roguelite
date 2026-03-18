class_name WaveConfig
extends Resource

var waves: Array[int] = []
var trigger_threshold: int = 1
var alive_cap: int = 4
var min_spawn_distance: float = 200.0


static func from_dict(data: Dictionary) -> Resource:
	var cfg := WaveConfig.new()
	cfg.trigger_threshold = int(data.get("trigger_threshold", 1))
	cfg.alive_cap = int(data.get("alive_cap", 4))
	cfg.min_spawn_distance = float(data.get("min_spawn_distance", 200.0))
	cfg.waves = []
	for v: Variant in data.get("waves", []):
		cfg.waves.append(int(v))
	return cfg
