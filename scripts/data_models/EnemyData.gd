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
var rooms_required: int = 0
var damage_reduction: float = 0.0
var root_duration: float = 0.0
var root_cooldown: float = 0.0
var attack_range: float = 22.0
var poison_duration: float = 0.0
var poison_modifier: float = 0.0
var color: Color = Color.WHITE
var regen_rate: float = 0.0
var heal_amount: float = 0.0
var heal_radius: float = 0.0
var heal_cooldown: float = 5.0


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
	d.rooms_required = int(data.get("rooms_required", 0))
	d.damage_reduction = float(data.get("damage_reduction", 0.0))
	d.root_duration = float(data.get("root_duration", 0.0))
	d.root_cooldown = float(data.get("root_cooldown", 0.0))
	d.attack_range = float(data.get("attack_range", 22.0))
	d.poison_duration = float(data.get("poison_duration", 0.0))
	d.poison_modifier = float(data.get("poison_modifier", 0.0))
	d.color = Color(data.get("color", "#ff12ff"))
	d.regen_rate = float(data.get("regen_rate", 0.0))
	d.heal_amount = float(data.get("heal_amount", 0.0))
	d.heal_radius = float(data.get("heal_radius", 0.0))
	d.heal_cooldown = float(data.get("heal_cooldown", 5.0))
	return d
