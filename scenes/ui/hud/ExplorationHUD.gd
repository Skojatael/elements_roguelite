extends CanvasLayer

# NOTE: This script requires GlobalSignals to be registered as an autoload.
# In Godot Editor: Project → Project Settings → Autoload
# Add: scenes/shared/GlobalSignals.gd  |  Name: GlobalSignals
# Then attach this script to ExplorationHUD.tscn via the Editor.


func _ready() -> void:
	GlobalSignals.gameplay_started.connect(_on_gameplay_started)
	GlobalSignals.gameplay_ended.connect(_on_gameplay_ended)
	# Hide by default; Main.gd emits gameplay_started which shows the HUD.
	visible = false


func _on_gameplay_started() -> void:
	visible = true


func _on_gameplay_ended() -> void:
	visible = false
