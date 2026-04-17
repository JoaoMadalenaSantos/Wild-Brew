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

@export var starting_position: Vector2 = Vector2.ZERO
@export var starting_direction: Vector2

const STEP_DISTANCE: float = 16.0
const SPEED: float = 75.0

var current_dir: Vector2
var target_pos: Vector2 = global_position

enum PlayerState {
	IDLE,
	WALKING
}

var current_state: PlayerState
var previous_state: PlayerState

signal entered_entrance(global_pos: Vector2)

func _ready() -> void:
	global_position = starting_position
	current_dir.x = clamp(starting_direction.x, -1.0, 1.0)
	current_dir.y = clamp(starting_direction.y, -1.0, 1.0)
	print("starting player direction: ", current_dir)
	_turn(current_dir)
	
	if level_manager:
		entered_entrance.connect(level_manager.set_level)

func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("walk_up"):
			current_dir = Vector2.UP
			_set_state(PlayerState.WALKING)
		
		if event.is_action_pressed("walk_down"):
			current_dir = Vector2.DOWN
			_set_state(PlayerState.WALKING)
		
		if event.is_action_pressed("walk_left"):
			current_dir = Vector2.LEFT
			_set_state(PlayerState.WALKING)
		
		if event.is_action_pressed("walk_right"):
			current_dir = Vector2.RIGHT
			_set_state(PlayerState.WALKING)

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
			match current_dir:
				Vector2.UP:
					anim_sprite.play("idle_up")
				
				Vector2.DOWN:
					anim_sprite.play("idle_down")
				
				Vector2.LEFT:
					anim_sprite.flip_h = true
					anim_sprite.play("idle_side")
					
				Vector2.RIGHT:
					anim_sprite.flip_h = false
					anim_sprite.play("idle_side")
				
			if _is_on_stairs():
				_set_state(PlayerState.WALKING)
			
			if _is_on_entrance():
				print("Player: Player global position while on entrance: ", global_position)
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
	if ground_detector.get_overlapping_bodies():
		var overlaping_body_list : Array = ground_detector.get_overlapping_bodies()
		
		if overlaping_body_list.size() > 1:
			push_error("Player: Standing in more than one special body so can't decide which obey. Check level design.")
			return null
		else:
			return overlaping_body_list[0]
	
	return null

func _is_on_stairs() -> bool:
	var ground_tile = _get_ground_tile()
	
	if ground_tile != null:
		if ground_tile.tile_set.get_physics_layer_collision_layer(0) == 2:
			print("Player: Standing tile are stairs.")
			return true
	
	return false

func _is_on_entrance() -> bool:
	var ground_tile = _get_ground_tile()
	
	if ground_tile != null:
		if ground_tile.tile_set.get_physics_layer_collision_layer(0) == 4:
			print("Player: Standing tile is entrance.")
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
