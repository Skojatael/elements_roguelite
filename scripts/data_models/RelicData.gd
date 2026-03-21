class_name RelicData
extends RefCounted

var id: String = ""
var name: String = ""
var tier: String = ""
var domain: String = ""
var tags: Array[String] = []
var effect_stat: String = ""
var effect_mult: float = 1.0
var condition_type: String = ""
var condition_threshold: float = 0.0
var condition_mult: float = 1.0
var description: String = ""
var deck_count: int = 1
var root_chance: float = 0.0
var root_duration: float = 0.0
var poison_chance: float = 0.0
var poison_duration: float = 0.0
var poison_modifier: float = 0.0


static func from_dict(data: Dictionary) -> RelicData:
	var r := RelicData.new()
	r.id = str(data.get("id", ""))
	r.name = str(data.get("name", ""))
	r.tier = str(data.get("tier", "common"))
	r.domain = str(data.get("domain", "neutral"))
	for t: Variant in data.get("tags", []):
		r.tags.append(str(t))
	r.effect_stat = str(data.get("effect_stat", ""))
	r.effect_mult = float(data.get("effect_mult", 1.0))
	r.condition_type = str(data.get("condition_type", ""))
	r.condition_threshold = float(data.get("condition_threshold", 0.0))
	r.condition_mult = float(data.get("condition_mult", 1.0))
	r.description = str(data.get("description", ""))
	r.deck_count = int(data.get("deck_count", 1))
	r.root_chance = float(data.get("root_chance", 0.0))
	r.root_duration = float(data.get("root_duration", 0.0))
	r.poison_chance = float(data.get("poison_chance", 0.0))
	r.poison_duration = float(data.get("poison_duration", 0.0))
	r.poison_modifier = float(data.get("poison_modifier", 0.0))
	return r
