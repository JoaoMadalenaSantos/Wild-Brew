extends Node2D

@export var dir_ray_cast: RayCast2D
var current_dir: Vector2

signal interacted_with_interactable(facing_tile: TileMapLayer, global_pos: Vector2, facing_dir: Vector2)

func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("interact") and _is_facing_interactable():
			var facing_tilemap = _get_facing_tilemap()
			emit_signal("interacted_with_interactable", facing_tilemap, global_position, current_dir)
			print("Player: interacted_with_interactable signal sent.")

func _get_facing_tilemap() -> TileMapLayer:
	var overlaping_body = dir_ray_cast.get_collider()
	
	if overlaping_body:
		return overlaping_body
	
	return null

func _is_facing_interactable() -> bool:
	var facing_tilemap = _get_facing_tilemap()
	
	if facing_tilemap != null:
		if facing_tilemap.tile_set.get_physics_layer_collision_layer(0) == 8:
			return true
	
	return false
