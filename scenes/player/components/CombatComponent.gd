class_name CombatComponent
extends Node

## Damage dealt to one enemy per attack hit.
@export var attack_damage: float = 1.0

## Seconds between automatic attack hits.
@export var attack_interval: float = 0.5

@onready var _attack_area: Area2D = $"../AttackArea"

var _overlapping_enemies: Array = []
var _attack_timer: float = 0.0


func _ready() -> void:
	assert(attack_damage > 0.0,
		"CombatComponent: attack_damage must be greater than 0")
	assert(attack_interval > 0.0,
		"CombatComponent: attack_interval must be greater than 0")
	_attack_area.body_entered.connect(_on_body_entered)
	_attack_area.body_exited.connect(_on_body_exited)


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
			(_overlapping_enemies[0] as Enemy).take_damage(attack_damage)
		_attack_timer = attack_interval
