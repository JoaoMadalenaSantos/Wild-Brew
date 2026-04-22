extends Node

class_name LevelManager

@onready var gameplay_manager: Node = $"../../../GameplayManager"

@onready var level_container: Node = $"../Level"
@onready var level_node
@onready var dropped_items_container
@onready var dropped_item_scene = load("res://scenes/entities/dropped_item.tscn")

@export var current_level_data: LevelData

signal level_change_started

signal item_collected(item: ItemData)

signal player_move_lock_requested
signal player_move_unlock_requested

func _ready() -> void:
	gameplay_manager.entered_gameplay_state.connect(_on_gameplay_state_entered)
	
	if level_container.get_children().is_empty():
		spawn_level(current_level_data)
	
func set_level(player_pos: Vector2):
	var tilemap_coords: Vector2i = round(player_pos / 16)
	print("LevelManager: Checking if entrance has related destination...")
	
	var portal_index = current_level_data.possible_destinations.find_custom(func(item: Portal):
		return item.tile_coords == tilemap_coords
	)
	
	if portal_index != -1:
		var portal = current_level_data.possible_destinations[portal_index]
		var destination_id = portal.destination_level_id
		current_level_data = LevelRegistry.get_level_data_by_id(destination_id)
		print("LevelManager: Related destination found: ", current_level_data)
		enter_level(portal)
	else:
		print("LevelManager: No destination found for coords: ", tilemap_coords)
	
func enter_level(portal: Portal):
	emit_signal("level_change_started")
	
	await gameplay_manager.gameplay_hidden
	
	for child in level_container.get_children():
		child.queue_free()
	
	spawn_level(current_level_data, portal.starting_pos * 16, portal.starting_dir * 16)
	
func spawn_level(level: LevelData, player_pos: Vector2 = Vector2.ZERO, player_dir: Vector2 = Vector2.ZERO):
	var new_level_node = level.scene.instantiate()
	var player_node = new_level_node.find_child("Player", false)
	player_node.starting_position = player_pos
	player_node.starting_direction = player_dir
	
	var camera_node = new_level_node.find_child("Camera2D", false)
	camera_node.starting_position = player_pos
	
	level_container.add_child(new_level_node)
	
	level_node = level_container.get_child(0)
	dropped_items_container = level_node.find_child("DroppedItems", false)
	# Dai o GameplayManager ouve e repassa para o UIManager que chama diretamente o close() do TransitionScreen

func check_interaction_target(tilemap_interacted: TileMapLayer, player_pos: Vector2, player_dir: Vector2):
	var tilemap_coords: Vector2i = round(player_pos / 16) + player_dir
	var atlas_coords = tilemap_interacted.get_cell_atlas_coords(tilemap_coords)
	var item_data = ItemRegistry.get_item_data_by_atlas_y(atlas_coords.y)
	
	if item_data.collectable:
		tilemap_interacted.set_cell(tilemap_coords, 0, atlas_coords + Vector2i.LEFT)
		
		var quantity_to_drop = randi_range(item_data.drop_quantity_range.x, item_data.drop_quantity_range.y)
		
		while quantity_to_drop != 0:
			spawn_dropped_item(item_data, player_pos + (player_dir * 16) + Vector2(8.0, 4.0))
			quantity_to_drop -= 1
		
	# If not collectable (just interactable) interaction logic goes below...

func spawn_dropped_item(item: ItemData, global_position: Vector2):
	var dropped_item = dropped_item_scene.instantiate()
	dropped_item.item = item
	dropped_item.global_position = global_position
	
	dropped_items_container.add_child(dropped_item)

func _on_gameplay_state_entered(state: GameplayManager.GameplayState):
	match state:
		GameplayManager.GameplayState.IN_INTERFACE:
			emit_signal("player_move_lock_requested")
		
		GameplayManager.GameplayState.IN_LEVEL:
			emit_signal("player_move_unlock_requested")
