extends Node

class_name GameplayManager
# Cousin nodes
@onready var ui_manager: Node = $"../../UIRoot/UIManager"

# Child nodes
@onready var hud: Control = $"../../UIRoot/UI/HUDLayer/HUD"
@onready var level_manager: Node = $"../Gameplay/LevelRoot/LevelManager"
@onready var gameplay: Node = $"../Gameplay"

var current_selected_slot: int = 0
var is_inventory_opened = false

enum GameplayState {
	PRE_DAY,
	ENTERING_LEVEL,
	IN_LEVEL,
	IN_INTERFACE,
	PAUSED,
	POST_DAY
}

signal entered_gameplay_state(new_state: GameplayState)

signal transition_needed
signal gameplay_hidden

signal current_slot_changed(new_slot: int)
signal inventory_toggle_requested(new_value: bool)

signal add_item_in_inventory_request(item: ItemData)

func _ready() -> void:
	level_manager.level_change_started.connect(_on_level_change_started)
	level_manager.item_collected.connect(_on_level_item_collected)
	
	ui_manager.transition_close_finished.connect(_on_ui_transition_closed_finished)
	
	hud.selected_slot_updated.connect(_on_hud_selected_slot_updated)

var current_gameplay_state: GameplayState = GameplayState.IN_LEVEL
var previous_gameplay_state: GameplayState

func _unhandled_input(event: InputEvent) -> void:
	match current_gameplay_state:
		GameplayState.IN_LEVEL:
			if event.is_action_released("select_next_slot"):
				if current_selected_slot <= 2:
					current_selected_slot += 1
				else:
					current_selected_slot = 0
		
				emit_signal("current_slot_changed", current_selected_slot)
	
			if event.is_action_released("select_previous_slot"):
				if current_selected_slot >= 1:
					current_selected_slot -= 1
				else:
					current_selected_slot = 3
				emit_signal("current_slot_changed", current_selected_slot)
				
			if event.is_action_pressed("select_slot_0"):
				current_selected_slot = 0
				emit_signal("current_slot_changed", current_selected_slot)
			
			if event.is_action_pressed("select_slot_1"):
				current_selected_slot = 1
				emit_signal("current_slot_changed", current_selected_slot)
			
			if event.is_action_pressed("select_slot_2"):
				current_selected_slot = 2
				emit_signal("current_slot_changed", current_selected_slot)
			
			if event.is_action_pressed("select_slot_3"):
				current_selected_slot = 3
				emit_signal("current_slot_changed", current_selected_slot)
			
			if event.is_action_pressed("toggle_inventory"):
				is_inventory_opened = !is_inventory_opened
				emit_signal("inventory_toggle_requested")
				
		GameplayState.IN_INTERFACE:
			pass
	
func _set_gameplay_state(new_gameplay_state: GameplayState):
	if current_gameplay_state == new_gameplay_state:
		return
	
	previous_gameplay_state = current_gameplay_state
	_exit_gameplay_state(current_gameplay_state)
	current_gameplay_state = new_gameplay_state
	_enter_gameplay_state(current_gameplay_state)

func _enter_gameplay_state(new_gameplay_state: GameplayState):
	match new_gameplay_state:
		GameplayState.PRE_DAY:
			pass
		
		GameplayState.ENTERING_LEVEL:
			emit_signal("transition_needed")
		
		GameplayState.IN_LEVEL:
			emit_signal("gameplay_hidden")
			
		GameplayState.IN_INTERFACE:
			pass
			
		GameplayState.PAUSED:
			gameplay.paused = true
			
		GameplayState.POST_DAY:
			pass
	
	emit_signal("entered_gameplay_state", current_gameplay_state)

func _exit_gameplay_state(old_gameplay_state: GameplayState):
	match old_gameplay_state:
		GameplayState.PRE_DAY:
			pass
		
		GameplayState.ENTERING_LEVEL:
			pass
		
		GameplayState.IN_LEVEL:
			pass
			
		GameplayState.IN_INTERFACE:
			pass
			
		GameplayState.PAUSED:
			gameplay.paused = false
			
		GameplayState.POST_DAY:
			pass

func _process_gameplay_state(delta) -> void:
	match current_gameplay_state:
		GameplayState.PRE_DAY:
			pass
		
		GameplayState.ENTERING_LEVEL:
			pass
		
		GameplayState.IN_LEVEL:
			pass
			
		GameplayState.IN_INTERFACE:
			pass
			
		GameplayState.PAUSED:
			pass
			
		GameplayState.POST_DAY:
			pass

func _on_level_change_started():
	_set_gameplay_state(GameplayState.ENTERING_LEVEL)

func _on_level_item_collected(item: ItemData):
	emit_signal("add_item_in_inventory_request", item)
	print("GameplayManager: add_item_in_inventory_request signal sent.")

func _on_ui_transition_closed_finished():
	_set_gameplay_state(GameplayState.IN_LEVEL)

func _on_hud_selected_slot_updated(selected_slot: int):
	current_selected_slot = selected_slot
