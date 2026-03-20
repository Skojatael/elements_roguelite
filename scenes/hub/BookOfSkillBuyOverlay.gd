class_name BookOfSkillBuyOverlay
extends Control

signal buy_pressed
signal maybe_later_pressed

@export var _buy_button: Button
@export var _later_button: Button
@export var _cost_label: Label

var _cost: int = 0


func _ready() -> void:
	_cost = ResourceManager.get_meta_config().get("book_of_skill", {}).get("cost", 250)
	_cost_label.text = "You've decided to put your experiences into writing. This will definitely help you in future exploration."
	_update_button()
	MetaManager.shards_changed.connect(func(_n: int) -> void: _update_button())
	_later_button.text = "Maybe Later"
	_buy_button.text = "Spend {cost} shards to create a Book of Skill".format(
		{"cost": _cost}
	)
	_buy_button.pressed.connect(func() -> void: buy_pressed.emit())
	_later_button.pressed.connect(func() -> void: maybe_later_pressed.emit())


func _update_button() -> void:
	_buy_button.disabled = not MetaManager.can_spend(_cost)
