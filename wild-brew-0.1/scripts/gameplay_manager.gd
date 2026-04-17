extends Node

@onready var ui_manager: Node = $"../../UIRoot/UIManager"
@onready var level_manager: Node = $"../Gameplay/LevelRoot/LevelManager"

signal transition_needed
signal gameplay_hidden

func _ready() -> void:
	level_manager.level_change_started.connect(_on_level_change_started)
	
	ui_manager.transition_close_finished.connect(_on_ui_transition_closed_finished)

func _on_level_change_started():
	print("GameplayManager: Emitting signal for trasition needed.")
	emit_signal("transition_needed")

func _on_ui_transition_closed_finished():
	emit_signal("gameplay_hidden")
