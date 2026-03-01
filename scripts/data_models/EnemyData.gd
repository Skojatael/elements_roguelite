class_name EnemyData
extends Resource

var id: String
var display_name: String
var max_health: float
var damage: float
var move_speed: float
var detection_range: float
var damage_cooldown: float
var base_essence: float


static func from_dict(data: Dictionary) -> EnemyData:
	assert(data.has("id"), "EnemyData: missing field 'id'")
	assert(data.has("display_name"), "EnemyData: missing field 'display_name'")
	assert(data.has("max_health"), "EnemyData: missing field 'max_health'")
	assert(data.has("damage"), "EnemyData: missing field 'damage'")
	assert(data.has("move_speed"), "EnemyData: missing field 'move_speed'")
	assert(data.has("detection_range"), "EnemyData: missing field 'detection_range'")
	assert(data.has("damage_cooldown"), "EnemyData: missing field 'damage_cooldown'")

	var d := EnemyData.new()
	d.id = data["id"]
	d.display_name = data["display_name"]
	d.max_health = float(data["max_health"])
	d.damage = float(data["damage"])
	d.move_speed = float(data["move_speed"])
	d.detection_range = float(data["detection_range"])
	d.damage_cooldown = float(data["damage_cooldown"])
	d.base_essence = float(data.get("base_essence", 0.0))
	return d
