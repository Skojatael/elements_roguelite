class_name SkillComponent
extends Node

signal charges_changed(current: int, maximum: int)

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectiles/Projectile.tscn")
const SKILL_ID: String = "magic_missile"

@export var _combat_component: CombatComponent

var _speed: float = 0.0
var _max_distance: float = 0.0
var _max_charges: int = 0
var _current_charges: int = 0


func _ready() -> void:
	_load_skill_data()
	GlobalSignals.skill_button_pressed.connect(_on_skill_button_pressed)
	RunManager.run_started.connect(func(_m: String) -> void: _reset_charges())
	_combat_component.melee_hit_landed.connect(_on_melee_hit_landed)


func _load_skill_data() -> void:
	var skills: Array = ResourceManager.get_skills()
	for entry: Variant in skills:
		if not entry is Dictionary:
			continue
		if (entry as Dictionary).get("id", "") != SKILL_ID:
			continue
		_speed = float((entry as Dictionary).get("speed", 0.0))
		_max_distance = float((entry as Dictionary).get("max_distance", 0.0))
		_max_charges = int((entry as Dictionary).get("max_charges", 3))
		break
	assert(_speed > 0.0, "SkillComponent: 'speed' missing in skills.json for " + SKILL_ID)
	assert(_max_distance > 0.0, "SkillComponent: 'max_distance' missing in skills.json for " + SKILL_ID)
	assert(_max_charges > 0, "SkillComponent: 'max_charges' must be > 0 in skills.json for " + SKILL_ID)
	_current_charges = _max_charges


func _on_melee_hit_landed() -> void:
	if _current_charges >= _max_charges:
		return
	_current_charges += 1
	charges_changed.emit(_current_charges, _max_charges)


func _reset_charges() -> void:
	_current_charges = _max_charges
	charges_changed.emit(_current_charges, _max_charges)


func _find_closest_enemy() -> Enemy:
	if RunManager.current_room == null:
		return null
	var room_node: Node = RunManager.current_room.get_parent()
	var closest: Enemy = null
	var closest_dist: float = INF
	for child: Node in room_node.get_children():
		if not child is Enemy:
			continue
		if not is_instance_valid(child):
			continue
		var dist: float = get_parent().global_position.distance_to((child as Enemy).global_position)
		if dist >= closest_dist:
			continue
		closest = child as Enemy
		closest_dist = dist
	return closest


func _on_skill_button_pressed() -> void:
	if _current_charges <= 0:
		return
	if not RunManager.is_run_active:
		return
	if RunManager.current_room == null:
		return
	var target: Enemy = _find_closest_enemy()
	if target == null:
		return
	var damage: float = floorf(_combat_component.attack_damage * 0.75)
	var room_node: Node = RunManager.current_room.get_parent()
	var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	room_node.add_child(projectile)
	projectile.global_position = get_parent().global_position
	projectile.setup(target, damage, _speed, _max_distance)
	_current_charges -= 1
	charges_changed.emit(_current_charges, _max_charges)
