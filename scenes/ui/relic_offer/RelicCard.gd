class_name RelicCard
extends Panel

signal relic_selected(relic_id: String)

@export var _name_label: Label
@export var _desc_label: Label
@export var _button: Button

var _relic_id: String = ""


func _ready() -> void:
	assert(_name_label != null, "RelicCard: _name_label not assigned in Inspector")
	assert(_desc_label != null, "RelicCard: _desc_label not assigned in Inspector")
	assert(_button != null, "RelicCard: _button not assigned in Inspector")
	_button.pressed.connect(_on_button_pressed)


func setup(relic: RelicData) -> void:
	_relic_id = relic.id
	_name_label.text = relic.name
	_desc_label.text = relic.description


func _on_button_pressed() -> void:
	relic_selected.emit(_relic_id)
