extends Node

var inventory_layout := Vector2i(3, 1)
var inventory_data: Dictionary = {}

signal inventory_data_changed(new_inventory_data: Dictionary)

func _ready() -> void:
	_setup_inventory_data()
	print("PlayerInventory: Inventory data is ", inventory_data)
	
func _setup_inventory_data():
	var inventory_line: Dictionary = {}
	
	var line: int = 0
	var collumn: int = 0
	
	while line != inventory_layout.y:
		inventory_data[line] = {}
		
		if collumn == inventory_layout.y:
			collumn == 0
		
		while collumn != inventory_layout.x:
			inventory_data[line][collumn] = [null, 0]
			collumn += 1
			
		line += 1

func find_space_for_item(item: ItemData) -> Array:
	# First try to find if theres a slot filled with the item already in inventory
	for line in inventory_data:
		for collumn in inventory_data[line]:
			var slot = inventory_data[line][collumn]
			
			if slot[0] == item and slot[1] < item.max_item_stack:
				return [line, collumn]
	
	# If not, tries to find an empty slot
	for line in inventory_data:
		for collumn in inventory_data[line]:
			var slot = inventory_data[line][collumn]
			
			if slot[0] == null and slot[1] == 0:
				return [line, collumn]
	
	return []
				
func try_adding_item(item: ItemData, quantity: int):
	var slot_for_item: Array
	var quantity_to_add = quantity
	
	while true:
		slot_for_item = find_space_for_item(item)
		
		if slot_for_item.is_empty():
			break
		
		if quantity_to_add == 0:
			break
		
		var current_quantity = inventory_data[slot_for_item[0]][slot_for_item[1]][1]
		var new_quantity = current_quantity + quantity_to_add
		
		if new_quantity > item.max_item_stack:
			set_slot(item, item.max_item_stack, slot_for_item[0], slot_for_item[1])
			var quantity_added = item.max_item_stack - current_quantity
			quantity_to_add -= quantity_added
		else:
			set_slot(item, new_quantity, slot_for_item[0], slot_for_item[1])
			quantity_to_add = 0
	
	emit_signal("inventory_data_changed", inventory_data)

func set_slot(item: ItemData, quantity: int, line: int, collumn: int):
	if not item.collectable:
		return
	
	if quantity < 1:
		return
	
	if not inventory_data.has(line):
		return
	
	if not inventory_data[line].has(collumn):
		return
	
	inventory_data[line][collumn][0] = item
	
	if quantity > item.max_item_stack:
		inventory_data[line][collumn][1] = item.max_item_stack
	else:
		inventory_data[line][collumn][1] = quantity
		
		
