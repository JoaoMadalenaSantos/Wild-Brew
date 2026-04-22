extends Control

@onready var gameplay_manager: Node = $"../../../../GameplayRoot/GameplayManager"
@onready var hotbar_container: HBoxContainer = $Inventory/HotBar/SlotLine
@onready var inventory_hotbar_container: HBoxContainer = $Inventory/Backpack/MarginContainer/VBoxContainer/SlotLine0
@onready var backpack_container: MarginContainer = $Inventory/Backpack
@onready var inventory_container: VBoxContainer = $Inventory/Backpack/MarginContainer/VBoxContainer

@onready var sound_helper: Node2D = $SoundHelper

@onready var hotbar_containers_list: Array[Node]
@onready var hotbar_slot_list: Array[Node]
@onready var inventory_container_list: Array[Node]
@onready var inventory_slot_list: Array[Node]
var current_selected_slot: int = 0
var previous_selected_slot: int = 1

var inventory_data: Dictionary = {
	0: {
		0: [null, 0],
		1: [null, 0],
		2: [null, 0],
		3: [null, 0]
	},
	1: {
		0: [null, 0],
		1: [null, 0],
		2: [null, 0],
		3: [null, 0]
	},
	2: {
		0: [null, 0],
		1: [null, 0],
		2: [null, 0],
		3: [null, 0]
	},
	3: {
		0: [null, 0],
		1: [null, 0],
		2: [null, 0],
		3: [null, 0]
	},
}

var inventory_tween: Tween
@export var inventory_tween_duration: float = 1.0

enum HUDState {
	IN_LEVEL,
	IN_INVENTORY
}

var current_hud_state: HUDState = HUDState.IN_LEVEL
var previous_hud_state: HUDState

signal entered_hud_state (new_stata: HUDState)

signal selected_slot_updated(selected_slot: int)

func _ready() -> void:
	hotbar_containers_list.append(hotbar_container)
	hotbar_containers_list.append(inventory_hotbar_container)
	
	inventory_container_list = inventory_container.get_children()
	
	print("HUD: Hotbar slot list is:", hotbar_slot_list)
	
	gameplay_manager.current_slot_changed.connect(update_selected_slot)
	gameplay_manager.inventory_toggle_requested.connect(_on_inventory_toggle_requested)
	gameplay_manager.add_item_in_inventory_request.connect(add_item_to_inventory)
	print(hotbar_slot_list)
	
	update_selected_slot(current_selected_slot)

func _process(delta: float) -> void:
	pass

func _set_hud_state(new_hud_state: HUDState):
	if current_hud_state == new_hud_state:
		return
	
	previous_hud_state = current_hud_state
	_exit_hud_state(current_hud_state)
	current_hud_state = new_hud_state
	_enter_hud_state(current_hud_state)

func _enter_hud_state(new_hud_state: HUDState):
	match new_hud_state:
		HUDState.IN_LEVEL:
			pass
		
		HUDState.IN_INVENTORY:
			toggle_inventory()
	
	emit_signal("entered_hud_state", current_hud_state)

func _exit_hud_state(old_hud_state: HUDState):
	match old_hud_state:
		HUDState.IN_LEVEL:
			pass
		
		HUDState.IN_INVENTORY:
			toggle_inventory()

func _process_hud_state(delta) -> void:
	match current_hud_state:
		HUDState.IN_LEVEL:
			pass
		
		HUDState.IN_INVENTORY:
			pass

func update_selected_slot(new_slot: int):
	previous_selected_slot = current_selected_slot
	
	unpress_all_hotbar_buttons()
	
	current_selected_slot = new_slot
	
	print(current_selected_slot)
	
	for container in hotbar_containers_list:
		hotbar_slot_list = container.get_children()
		var new_button_node = get_button_node_by_slot(new_slot)
		new_button_node.custom_minimum_size = Vector2(24.0, 24.0)
		container.queue_sort()
		container.get_parent().queue_sort()
		new_button_node.toggle_mode = true
		new_button_node.button_pressed = true
		new_button_node.disabled = true
	
	emit_signal("selected_slot_updated", current_selected_slot)
	
	sound_helper.play_audio("ItemSelect", 1.0, -20.0)

func unpress_all_hotbar_buttons():
	for container in hotbar_containers_list:
		hotbar_slot_list = container.get_children()
		for slot in hotbar_slot_list:
			var button_node = slot.find_child("Button", false)
			button_node.custom_minimum_size = Vector2(20.0, 20.0)
			slot.queue_sort()
			slot.get_parent().queue_sort()
			button_node.toggle_mode = false
			button_node.button_pressed = false
			button_node.disabled = false

func get_button_node_by_slot(slot_index: int) -> Node:
	var slot_node = hotbar_slot_list[slot_index]
	var button_node = slot_node.find_child("Button", false)
	
	return button_node

func toggle_inventory():
	var inventory_current_margin_left = backpack_container.get_theme_constant("margin_left")
	var inventory_target_margin_left: int
	
	match previous_hud_state:
		HUDState.IN_LEVEL:
			inventory_target_margin_left = 1
		
		HUDState.IN_INVENTORY:
			inventory_target_margin_left = -112
	
	
	if inventory_tween:
		inventory_tween.kill()
	
	inventory_tween = create_tween()
	inventory_tween.set_trans(Tween.TRANS_QUINT)
	inventory_tween.set_ease(Tween.EASE_OUT)
	inventory_tween.tween_method(set_inventory_margin_left,
	inventory_current_margin_left,
	inventory_target_margin_left,
	inventory_tween_duration
	)
	
	inventory_tween.finished.connect(func():
		inventory_tween.kill()
	)

func set_inventory_margin_left(value: int):
	backpack_container.add_theme_constant_override("margin_left", value)

func _on_inventory_toggle_requested():
	match current_hud_state:
		HUDState.IN_LEVEL:
			_set_hud_state(HUDState.IN_INVENTORY)
		HUDState.IN_INVENTORY:
			_set_hud_state(previous_hud_state)

func add_item_to_inventory(item: ItemData):
	var slot_coords = get_next_slot_of_item_in_inventory(item)
	
	if slot_coords != null:
		update_inventory_slot_item(slot_coords.x, slot_coords.y, item)
		
		sound_helper.play_audio("ItemCollect", 1.0, -25.0)

func get_next_slot_of_item_in_inventory(item: ItemData):
	var slot_coords
	
	for line in inventory_data:
		for collumn in inventory_data[line]:
			if inventory_data[line][collumn][0] == item and inventory_data[line][collumn][1] < 2:
				slot_coords = Vector2i(line, collumn)
				print("Found slot at: ", slot_coords)
				return slot_coords
	
	# CONTINUAR DAQUI, QUANDO UMA LINHA ACABA O ESPAÇO COLOCAR O ITEM
	# NA PRÓXIMA TA BUGANDO A COLUNA INTEIRA
	
	if slot_coords == null:
		for line in inventory_data:
			for collumn in inventory_data[line]:
				if inventory_data[line][collumn][0] == null:
					slot_coords = Vector2i(line, collumn)
					print("Found slot at: ", slot_coords)
					return slot_coords
	
	if slot_coords == null:
		print("HUD: No space in inventory for item.")

func update_inventory_slot_item(line: int, collumn: int, item: ItemData):
	print("HUD: Adding item ", item, " to line ", line, " and collumn ", collumn)
	
	if inventory_data[line][collumn][0] == item:
		inventory_data[line][collumn][1] += 1
	else:
		inventory_data[line][collumn][0] = item
		inventory_data[line][collumn][1] += 1
	
	update_inventory()
	
func update_inventory():
	for line in inventory_data:
		print("HUD: Updating inventory line ", line)
		if line == 0:
			for container in hotbar_containers_list:
				hotbar_slot_list = container.get_children()
				for slot in hotbar_slot_list:
					var button_node = slot.find_child("Button", false)
					
					var slot_index = hotbar_slot_list.find(slot)
					var item_data: ItemData = inventory_data[line][slot_index][0]
					var item_quantity: int = inventory_data[line][slot_index][1]
					
					print("HUD: Item data in inventory slot line ", line, " and collunm ", slot, " is ", item_data, " and quantity is ", item_quantity)
					
					if item_data:
						if item_quantity == 0:
							item_quantity = 1
						
						var region_y = item_data.texture_atlas_y
						var button_atlas_tex = button_node.icon as AtlasTexture
						button_atlas_tex.region = Rect2(32.0, region_y, 16.0, 16.0)
					
					else:
						if item_quantity > 0:
							item_quantity = 0
					
					var quantity_label_node = button_node.find_child("Quantity", true)
					if item_quantity > 1:
						quantity_label_node.text = str(item_quantity)
		
		else:
				inventory_slot_list = inventory_container_list[line].get_children()
				for slot in inventory_slot_list:
					var button_node = slot.find_child("Button", false)
					
					var slot_index = inventory_slot_list.find(slot)
					var item_data: ItemData = inventory_data[line][slot_index][0]
					var item_quantity: int = inventory_data[line][slot_index][1]
					
					if item_data:
						if item_quantity == 0:
							item_quantity = 1
						
						var region_y = item_data.texture_atlas_y
						var button_atlas_tex = button_node.icon as AtlasTexture
						button_atlas_tex.region = Rect2(32.0, region_y, 16.0, 16.0)
				
					else:
						if item_quantity > 0:
							item_quantity = 0
					
					var quantity_label_node = button_node.find_child("Quantity", true)
					if item_quantity > 1:
						quantity_label_node.text = str(item_quantity)
