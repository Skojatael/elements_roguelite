class_name CombatComponent
extends Node

signal melee_hit_landed

## Damage dealt to one enemy per attack hit.
@export var attack_damage: float = 1.0

## Seconds between automatic attack hits.
@export var attack_interval: float = 0.5

const _Utilities = preload("res://scripts/Utilities.gd")

@onready var _attack_area: Area2D = $"../AttackArea"
@onready var _stats_component: StatsComponent = $"../StatsComponent"

var _overlapping_enemies: Array = []
var _attack_timer: float = 0.0
var _base_attack_damage: float = 0.0
var _base_attack_interval: float = 0.0
var _base_crit_chance: float = 0.0
var _base_crit_multiplier: float = 0.5
var _crit_chance: float = 0.0
var _crit_multiplier: float = 0.5


func _ready() -> void:
	var combat: Dictionary = ResourceManager.get_player_config().get("combat", {})
	_base_attack_damage = float(combat.get("attack_damage", attack_damage))
	_base_attack_interval = float(combat.get("attack_interval", attack_interval))
	assert(_base_attack_damage > 0.0,
		"CombatComponent: attack_damage must be greater than 0")
	assert(_base_attack_interval > 0.0,
		"CombatComponent: attack_interval must be greater than 0")
	var crit: Dictionary = ResourceManager.get_player_config().get("crit", {})
	_base_crit_chance = minf(1.0, float(crit.get("crit_chance", 0.0)))
	_base_crit_multiplier = float(crit.get("crit_multiplier", 0.5))
	RunManager.run_started.connect(func(_m: String) -> void: _recompute_stats())
	RelicManager.relic_applied.connect(func(_id: String) -> void: _recompute_stats())
	RelicManager.relics_cleared.connect(func() -> void: _recompute_stats())
	_attack_area.body_entered.connect(_on_body_entered)
	_attack_area.body_exited.connect(_on_body_exited)


func _recompute_stats() -> void:
	attack_damage = _base_attack_damage * MetaManager.damage_multiplier \
		* RelicManager.get_stat_mult("attack_damage")
	attack_interval = _base_attack_interval / RelicManager.get_stat_mult("attack_speed")
	_crit_chance = minf(1.0, _base_crit_chance + RelicManager.get_stat_addend("crit_chance"))
	_crit_multiplier = _base_crit_multiplier + RelicManager.get_stat_addend("crit_multiplier")


func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		_overlapping_enemies.append(body)


func _on_body_exited(body: Node2D) -> void:
	_overlapping_enemies.erase(body)


func _physics_process(delta: float) -> void:
	if _overlapping_enemies.is_empty():
		return

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		# Clean up any freed enemies, then attack the first valid one.
		_overlapping_enemies = _overlapping_enemies.filter(
			func(e: Enemy) -> bool: return is_instance_valid(e)
		)
		if not _overlapping_enemies.is_empty():
			var target: Enemy = _overlapping_enemies[0] as Enemy
			var attacker_ratio: float = _stats_component.current_health / _stats_component.max_health
			var dmg: float = _Utilities.apply_crit(attack_damage \
				* RelicManager.get_hit_damage_mult(target.get_hp_ratio(), attacker_ratio), \
				_crit_chance, _crit_multiplier)
			target.take_damage(dmg)
		melee_hit_landed.emit()
		_attack_timer = attack_interval
