class_name DepthTierConfig
extends Resource

var depth_min: int = 1
var depth_max: int = -1
var waves: Array = []
var trigger_threshold: int = 2
var alive_cap: int = 4
var min_spawn_distance: float = 200.0


static func from_dict(data: Dictionary) -> Resource:
	var cfg: Resource = DepthTierConfig.new()
	cfg.depth_min = int(data.get("depth_min", 1))
	cfg.depth_max = int(data.get("depth_max", -1))
	cfg.trigger_threshold = int(data.get("trigger_threshold", 2))
	cfg.alive_cap = int(data.get("alive_cap", 4))
	cfg.min_spawn_distance = float(data.get("min_spawn_distance", 200.0))
	cfg.waves = []
	for v: Variant in data.get("waves", []):
		cfg.waves.append(int(v))
	return cfg


static func find_for_depth(tiers: Array, depth: int) -> Resource:
	for entry: Variant in tiers:
		var tier: Resource = entry as Resource
		if tier == null:
			continue
		if depth < int(tier.get("depth_min")):
			continue
		var dmax: int = int(tier.get("depth_max"))
		if dmax != -1 and depth > dmax:
			continue
		return tier
	return null
