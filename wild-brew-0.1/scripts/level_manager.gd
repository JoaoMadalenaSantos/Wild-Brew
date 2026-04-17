extends Node

class_name LevelManager

@onready var gameplay_manager: Node = $"../../../GameplayManager"
@onready var level_container: Node = $"../Level"

@export var current_level_data: LevelData

signal level_change_started

func _ready() -> void:
	
	
	if level_container.get_children().is_empty():
		spawn_level(current_level_data)
	
func set_level(global_pos: Vector2):
	print("LevelManager: Setting level for entrance...")
	var tilemap_coords: Vector2i = round(global_pos / 16)
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
	# Dai o GameplayManager ouve e repassa para o UIManager que chama diretamente o close() do TransitionScreen
