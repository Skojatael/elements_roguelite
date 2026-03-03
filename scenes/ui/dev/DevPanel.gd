class_name DevPanel
extends CanvasLayer

signal start_run_pressed
signal end_run_pressed
signal cash_out_pressed
signal start_boss_pressed
signal get_relic_pressed

@onready var _btn_start_run: Button = $PanelContainer/VBoxContainer/StartRun
@onready var _btn_end_run: Button = $PanelContainer/VBoxContainer/EndRun
@onready var _btn_cash_out: Button = $PanelContainer/VBoxContainer/CashOut
@onready var _btn_start_boss: Button = $PanelContainer/VBoxContainer/StartBoss
@onready var _btn_get_relic: Button = $PanelContainer/VBoxContainer/GetRelic


func _ready() -> void:
	_btn_start_run.pressed.connect(start_run_pressed.emit)
	_btn_end_run.pressed.connect(end_run_pressed.emit)
	_btn_cash_out.pressed.connect(cash_out_pressed.emit)
	_btn_start_boss.pressed.connect(start_boss_pressed.emit)
	_btn_get_relic.pressed.connect(get_relic_pressed.emit)
