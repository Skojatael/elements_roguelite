class_name SkillComponent
extends Node

signal charges_changed(current: int, maximum: int)
signal cooldown_changed(remaining: float, total: float)

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/combat/projectiles/Projectile.tscn")
const _Utilities = preload("res://scripts/Utilities.gd")
const SKILL_ID: String = "magic_missile"

@export var _combat_component: CombatComponent

var _speed: float = 0.0
var _max_distance: float = 0.0
var _max_charges: int = 0
var _current_charges: int = 0
var _chain_damage_mult: float = 1.0
var _burn_damage_per_tick: float = 0.0
var _burn_duration: float = 2.0
var _burn_extend_seconds: float = 2.0
var _cooldown_duration: float = 1.0
var _cooldown_remaining: float = 0.0
var _base_crit_chance: float = 0.0
var _base_crit_multiplier: float = 0.5
var _crit_chance: float = 0.0
var _crit_multiplier: float = 0.5


func _ready() -> void:
	_load_skill_data()
	GlobalSignals.skill_button_pressed.connect(_on_skill_button_pressed)
	RunManager.run_started.connect(func(_m: String) -> void: _reset_charges())
	RunManager.run_started.connect(func(_m: String) -> void: _recompute_crit_stats())
	RelicManager.relic_applied.connect(func(_id: String) -> void: _recompute_crit_stats())
	RelicManager.relics_cleared.connect(func() -> void: _recompute_crit_stats())
	_combat_component.melee_hit_landed.connect(_on_melee_hit_landed)


func _recompute_crit_stats() -> void:
	_crit_chance = minf(1.0, _base_crit_chance + RelicManager.get_stat_addend("crit_chance"))
	_crit_multiplier = _base_crit_multiplier + RelicManager.get_stat_addend("crit_multiplier")


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
		_cooldown_duration = float((entry as Dictionary).get("cooldown", 1.0))
		_chain_damage_mult = float((entry as Dictionary).get("chain_damage_mult", 1.0))
		_burn_damage_per_tick = float((entry as Dictionary).get("burn_damage_per_tick", 0.0))
		_burn_duration = float((entry as Dictionary).get("burn_duration", 2.0))
		_burn_extend_seconds = float((entry as Dictionary).get("burn_extend_seconds", 2.0))
		var crit: Dictionary = ResourceManager.get_player_config().get("crit", {})
		_base_crit_chance = minf(1.0, float(crit.get("crit_chance", 0.0)))
		_base_crit_multiplier = float(crit.get("crit_multiplier", 0.5))
		break
	assert(_speed > 0.0, "SkillComponent: 'speed' missing in skills.json for " + SKILL_ID)
	assert(_max_distance > 0.0, "SkillComponent: 'max_distance' missing in skills.json for " + SKILL_ID)
	assert(_max_charges > 0, "SkillComponent: 'max_charges' must be > 0 in skills.json for " + SKILL_ID)
	_current_charges = _max_charges


func _process(delta: float) -> void:
	if _cooldown_remaining <= 0.0:
		return
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	cooldown_changed.emit(_cooldown_remaining, _cooldown_duration)


func _on_melee_hit_landed() -> void:
	if _current_charges >= _max_charges:
		return
	_current_charges += 1
	charges_changed.emit(_current_charges, _max_charges)


func _reset_charges() -> void:
	_current_charges = _max_charges
	charges_changed.emit(_current_charges, _max_charges)
	_cooldown_remaining = 0.0
	cooldown_changed.emit(0.0, _cooldown_duration)


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
	if _cooldown_remaining > 0.0:
		return
	if _current_charges <= 0:
		return
	if not RunManager.is_run_active:
		return
	if RunManager.current_room == null:
		return
	var target: Enemy = _find_closest_enemy()
	if target == null:
		return
	var damage: float = _Utilities.apply_crit(floorf(_combat_component.attack_damage * 0.75), _crit_chance, _crit_multiplier)
	var room_node: Node = RunManager.current_room.get_parent()
	var projectile: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	room_node.add_child(projectile)
	projectile.global_position = get_parent().global_position
	projectile.setup(target, damage, _speed, _max_distance, _chain_damage_mult,
			_burn_damage_per_tick, _burn_duration, _burn_extend_seconds)
	_current_charges -= 1
	charges_changed.emit(_current_charges, _max_charges)
	_cooldown_remaining = _cooldown_duration
	cooldown_changed.emit(_cooldown_remaining, _cooldown_duration)
