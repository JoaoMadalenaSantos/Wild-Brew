extends Node2D

class_name PlayerController

@onready var level_manager: Node = $"../../../LevelManager"

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_ray_cast_up: RayCast2D = $Collision/RayCastUp
@onready var col_ray_cast_down: RayCast2D = $Collision/RayCastDown
@onready var col_ray_cast_left: RayCast2D = $Collision/RayCastLeft
@onready var col_ray_cast_right: RayCast2D = $Collision/RayCastRight
@onready var int_ray_cast: RayCast2D = $Interaction/RayCast2D
@onready var ground_detector: Area2D = $GroundDetector
@onready var inventory: Node = $Inventory

@onready var sounds_helper: Node2D = $SoundHelper

@export var starting_position: Vector2 = Vector2.ZERO
@export var starting_direction: Vector2

const STEP_DISTANCE: float = 16.0
const SPEED: float = 75.0

var is_movement_locked: bool = false
var current_dir: Vector2
var target_pos: Vector2 = global_position

enum PlayerState {
	IDLE,
	WALKING
}

var current_state: PlayerState
var previous_state: PlayerState

signal entered_entrance(global_pos: Vector2)

signal interacted_with_interactable(facing_tile: TileMapLayer, global_pos: Vector2, facing_dir: Vector2)

signal player_has_space_for_dropped_item
signal inventory_data_changed(new_inventory_data: Dictionary)

func _ready() -> void:
	if level_manager:
		level_manager.player_move_lock_requested.connect(lock_movement)
		level_manager.player_move_unlock_requested.connect(unlock_movement)
		
		entered_entrance.connect(level_manager.set_level)
		interacted_with_interactable.connect(level_manager.check_interaction_target)
	
	inventory.inventory_data_changed.connect(_on_inventory_data_changed)
	
	global_position = starting_position
	current_dir.x = clamp(starting_direction.x, -1.0, 1.0)
	current_dir.y = clamp(starting_direction.y, -1.0, 1.0)
	_turn(current_dir)
		

func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("walk_up") and not is_movement_locked:
			current_dir = Vector2.UP
			_set_state(PlayerState.WALKING)
		
		if event.is_action_pressed("walk_down") and not is_movement_locked:
			current_dir = Vector2.DOWN
			_set_state(PlayerState.WALKING)
		
		if event.is_action_pressed("walk_left") and not is_movement_locked:
			current_dir = Vector2.LEFT
			_set_state(PlayerState.WALKING)
		
		if event.is_action_pressed("walk_right") and not is_movement_locked:
			current_dir = Vector2.RIGHT
			_set_state(PlayerState.WALKING)
			
		if event.is_action_pressed("interact") and _is_facing_interactable():
			var facing_tilemap = _get_facing_tilemap()
			emit_signal("interacted_with_interactable", facing_tilemap, global_position, current_dir)
			print("Player: interacted_with_interactable signal sent.")

func _process(delta: float) -> void:
	_process_state(delta)
	
func _set_state(new_state: PlayerState):
	if new_state == current_state:
		return
	
	previous_state = current_state
	_exit_state(current_state)
	
	current_state = new_state
	_enter_state(current_state)

func _enter_state(new_state: PlayerState):
	match new_state:
		PlayerState.IDLE:
			_turn(current_dir)
				
			if _is_on_stairs():
				_set_state(PlayerState.WALKING)
			
			if _is_on_entrance():
				emit_signal("entered_entrance", global_position)
				
		PlayerState.WALKING:
			_turn_and_move(current_dir)

func _exit_state(old_state: PlayerState):
	match old_state:
		PlayerState.IDLE:
			pass
		
		PlayerState.WALKING:
			pass

func _process_state(_delta):
	match current_state:
		PlayerState.IDLE:
			pass
		
		PlayerState.WALKING:
			if global_position == target_pos:
				match current_dir:
					Vector2.UP:
						if Input.is_action_pressed("walk_up") and _can_go_in_dir(Vector2.UP):
							_turn_and_move(current_dir)
						else:
							_set_state(PlayerState.IDLE)
					Vector2.DOWN:
						if Input.is_action_pressed("walk_down") and _can_go_in_dir(Vector2.DOWN):
							_turn_and_move(current_dir)
						else:
							_set_state(PlayerState.IDLE)
					Vector2.LEFT:
						if Input.is_action_pressed("walk_left") and _can_go_in_dir(Vector2.LEFT):
							_turn_and_move(current_dir)
						else:
							_set_state(PlayerState.IDLE)
					Vector2.RIGHT:
						if Input.is_action_pressed("walk_right") and _can_go_in_dir(Vector2.RIGHT):
							_turn_and_move(current_dir)
						else:
							_set_state(PlayerState.IDLE)

func _can_go_in_dir(dir: Vector2) -> bool:
	match dir:
		Vector2.UP:
			if col_ray_cast_up.is_colliding():
				return false
			
		Vector2.DOWN:
			if col_ray_cast_down.is_colliding():
				return false
			
		Vector2.LEFT:
			if col_ray_cast_left.is_colliding():
				return false
			
		Vector2.RIGHT:
			if col_ray_cast_right.is_colliding():
				return false
				
	return true

func _get_ground_tile() -> TileMapLayer:
	var overlaping_body_list : Array = ground_detector.get_overlapping_bodies()
	
	if overlaping_body_list:
		if overlaping_body_list.size() > 1:
			push_error("Player: Standing in more than one special body so can't decide which obey. Check level design.")
			return null
		else:
			return overlaping_body_list[0]
	
	return null

func _get_facing_tilemap() -> TileMapLayer:
	var overlaping_body = int_ray_cast.get_collider()
	
	if overlaping_body:
		return overlaping_body
	
	return null

func _is_on_stairs() -> bool:
	var ground_tile = _get_ground_tile()
	
	if ground_tile != null:
		if ground_tile.tile_set.get_physics_layer_collision_layer(0) == 2:
			return true
	
	return false

func _is_on_entrance() -> bool:
	var ground_tile = _get_ground_tile()
	
	if ground_tile != null:
		if ground_tile.tile_set.get_physics_layer_collision_layer(0) == 4:
			return true
	
	return false

func _is_facing_interactable() -> bool:
	var facing_tilemap = _get_facing_tilemap()
	
	if facing_tilemap != null:
		if facing_tilemap.tile_set.get_physics_layer_collision_layer(0) == 8:
			return true
	
	return false

func _turn(dir: Vector2):
	match dir:
			Vector2.UP:
				anim_sprite.play("idle_up")
				int_ray_cast.target_position = Vector2(0.0, -17.0)
			Vector2.DOWN:
				anim_sprite.play("idle_down")
				int_ray_cast.target_position = Vector2(0.0, 17.0)
			Vector2.LEFT:
				anim_sprite.flip_h = true
				anim_sprite.play("idle_side")
				int_ray_cast.target_position = Vector2(-17.0, 0.0)
			Vector2.RIGHT:
				anim_sprite.flip_h = false
				anim_sprite.play("idle_side")
				int_ray_cast.target_position = Vector2(17.0, 0.0)

func _turn_and_move(dir: Vector2):
	if not _can_go_in_dir(dir):
		_turn(dir)
	
	else:
		var footstep_pitch = randf_range(0.6, 1.0)
		var footstep_volume = randf_range(-21, -19)
		sounds_helper.play_audio("Footstep", footstep_pitch, footstep_volume)
		
		match dir:
			Vector2.UP:
				anim_sprite.play("walk_up")
				int_ray_cast.target_position = Vector2(0.0, -17.0)
			Vector2.DOWN:
				anim_sprite.play("walk_down")
				int_ray_cast.target_position = Vector2(0.0, 17.0)
			Vector2.LEFT:
				anim_sprite.flip_h = true
				anim_sprite.play("walk_side")
				int_ray_cast.target_position = Vector2(-17.0, 0.0)
			Vector2.RIGHT:
				anim_sprite.flip_h = false
				anim_sprite.play("walk_side")
				int_ray_cast.target_position = Vector2(17.0, 0.0)
	
		target_pos = global_position + current_dir * STEP_DISTANCE
		var mov_duration = STEP_DISTANCE / SPEED
		
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_pos, mov_duration)

func lock_movement():
	is_movement_locked = true
	print("PlayerController: Player movement lock set to ", is_movement_locked)
	
func unlock_movement():
	is_movement_locked = false
	print("PlayerController: Player movement lock set to ", is_movement_locked)
		
func _on_dropped_item_found_player(dropped_item: Node2D):
	if not dropped_item.has_method("_on_player_has_space_in_inventory"):
		return
	
	var slot_for_item = inventory.find_space_for_item(dropped_item.item)
	
	if slot_for_item.is_empty():
		return
	
	player_has_space_for_dropped_item.connect(dropped_item._on_player_has_space_in_inventory)
	emit_signal("player_has_space_for_dropped_item")
	
	inventory.try_adding_item(dropped_item.item, 1)
		
func _on_inventory_data_changed(new_inventory_data: Dictionary):
	emit_signal("inventory_data_changed", new_inventory_data)
