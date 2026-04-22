extends Node

const ITEM_DATA_DIR: String = "res://resources/level/item/items/"

var items_list: Array[ItemData] = []
var items_by_id: Dictionary[String, ItemData] = {}

func _ready() -> void:
	load_items()
	pass

func load_items():
	var dir = DirAccess.open(ITEM_DATA_DIR)
	
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.get_extension() == "tres":
				var path := ITEM_DATA_DIR + file_name
				
				var resource = load(path)
				
				if resource is ItemData:
					items_list.append(resource)
					items_by_id[resource.id] = resource
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	print("ItemRegistry: ", items_list.size(), " items loaded. Items: ", items_by_id)

func get_item_data_by_atlas_y(atlas_y: int) -> ItemData:
	for item in items_list:
		if item.texture_atlas_y == atlas_y:
			return item
	
	return null
