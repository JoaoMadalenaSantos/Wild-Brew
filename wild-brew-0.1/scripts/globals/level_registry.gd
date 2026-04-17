extends Node

const LEVEL_DATA_DIR: String = "res://resources/level/levels/"

var levels_list: Array[LevelData] = []
var levels_by_id: Dictionary[String, LevelData] = {}

func _ready() -> void:
	load_levels()
	pass

func load_levels():
	var dir = DirAccess.open(LEVEL_DATA_DIR)
	
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		print(file_name)
		if not dir.current_is_dir():
			if file_name.get_extension() == "tres":
				var path := LEVEL_DATA_DIR + file_name
				
				var resource = load(path)
				print(resource)
				
				if resource is LevelData:
					levels_list.append(resource)
					levels_by_id[resource.id] = resource
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	print("LevelRegistry: ", levels_list.size(), " levels loaded.")
	print("LevelRegistry: ", levels_by_id)

func get_level_data_by_id(id: String) -> LevelData:
	return levels_by_id[id]
