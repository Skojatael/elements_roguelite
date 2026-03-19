class_name RelicData
extends RefCounted

var id: String = ""
var name: String = ""
var tier: String = ""
var tags: Array[String] = []
var effect_stat: String = ""
var effect_mult: float = 1.0
var description: String = ""
var deck_count: int = 1


static func from_dict(data: Dictionary) -> RelicData:
	var r := RelicData.new()
	r.id = str(data.get("id", ""))
	r.name = str(data.get("name", ""))
	r.tier = str(data.get("tier", "common"))
	for t: Variant in data.get("tags", []):
		r.tags.append(str(t))
	r.effect_stat = str(data.get("effect_stat", ""))
	r.effect_mult = float(data.get("effect_mult", 1.0))
	r.description = str(data.get("description", ""))
	r.deck_count = int(data.get("deck_count", 1))
	return r
