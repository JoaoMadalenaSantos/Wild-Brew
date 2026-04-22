extends Node

@onready var gameplay_manager: Node = $"../../GameplayRoot/GameplayManager"

signal transition_close_requested
signal transition_open_requested(delay_time)
signal transition_open_finished
signal transition_close_finished

signal hud_inventory_update_requested(new_inventory_data: Dictionary)
 
func _ready() -> void:
	gameplay_manager.transition_needed.connect(make_transition)

func make_transition():
	emit_signal("transition_close_requested")
	emit_signal("transition_open_requested", 1.0)

func _on_transition_close_finished():
	emit_signal("transition_close_finished")
	
func _on_transition_open_finished():
	emit_signal("transition_open_finished")
	
func update_hud_inventory(inventory_data: Dictionary):
	emit_signal("hud_inventory_update_requested", inventory_data)
