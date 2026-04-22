extends Node2D

@export var ray_cast_up: RayCast2D
@export var ray_cast_down: RayCast2D
@export var ray_cast_left: RayCast2D
@export var ray_cast_right: RayCast2D
@export var ground_detector: Area2D

@export var starting_position: Vector2 = Vector2.ZERO
@export var starting_direction: Vector2
var current_dir: Vector2
var target_pos: Vector2 = global_position

const STEP_DISTANCE: float = 16.0
const SPEED: float = 75.0

var is_movement_locked: bool = false

signal entered_entrance(global_pos: Vector2)

enum MovementState {
	IDLE,
	WALKING
}

var current_state: MovementState
var previous_state: MovementState

func _ready() -> void:
	global_position = starting_position
	current_dir.x = clamp(starting_direction.x, -1.0, 1.0)
	current_dir.y = clamp(starting_direction.y, -1.0, 1.0)
	_turn(current_dir)

func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("walk_up") and not is_movement_locked:
			current_dir = Vector2.UP
			_set_state(MovementState.WALKING)
		
		if event.is_action_pressed("walk_down") and not is_movement_locked:
			current_dir = Vector2.DOWN
			_set_state(MovementState.WALKING)
		
		if event.is_action_pressed("walk_left") and not is_movement_locked:
			current_dir = Vector2.LEFT
			_set_state(MovementState.WALKING)
		
		if event.is_action_pressed("walk_right") and not is_movement_locked:
			current_dir = Vector2.RIGHT
			_set_state(MovementState.WALKING)

func _process(delta: float) -> void:
	_process_state(delta)
	
func _set_state(new_state: MovementState):
	if new_state == current_state:
		return
	
	previous_state = current_state
	_exit_state(current_state)
	
	current_state = new_state
	_enter_state(current_state)

func _enter_state(new_state: MovementState):
	match new_state:
		MovementState.IDLE:
			_turn(current_dir)
				
			if _is_on_stairs():
				_set_state(MovementState.WALKING)
			
			if _is_on_entrance():
				emit_signal("entered_entrance", global_position)
				
		MovementState.WALKING:
			_turn_and_move(current_dir)

func _exit_state(old_state: MovementState):
	match old_state:
		MovementState.IDLE:
			pass
		
		MovementState.WALKING:
			pass

func _process_state(_delta):
	match current_state:
		MovementState.IDLE:
			pass
		
		MovementState.WALKING:
			if global_position == target_pos:
				match current_dir:
					Vector2.UP:
						if Input.is_action_pressed("walk_up") and _can_go_in_dir(Vector2.UP):
							_turn_and_move(current_dir)
						else:
							_set_state(MovementState.IDLE)
					Vector2.DOWN:
						if Input.is_action_pressed("walk_down") and _can_go_in_dir(Vector2.DOWN):
							_turn_and_move(current_dir)
						else:
							_set_state(MovementState.IDLE)
					Vector2.LEFT:
						if Input.is_action_pressed("walk_left") and _can_go_in_dir(Vector2.LEFT):
							_turn_and_move(current_dir)
						else:
							_set_state(MovementState.IDLE)
					Vector2.RIGHT:
						if Input.is_action_pressed("walk_right") and _can_go_in_dir(Vector2.RIGHT):
							_turn_and_move(current_dir)
						else:
							_set_state(MovementState.IDLE)

func _can_go_in_dir(dir: Vector2) -> bool:
	match dir:
		Vector2.UP:
			if ray_cast_up.is_colliding():
				return false
			
		Vector2.DOWN:
			if ray_cast_down.is_colliding():
				return false
			
		Vector2.LEFT:
			if ray_cast_left.is_colliding():
				return false
			
		Vector2.RIGHT:
			if ray_cast_right.is_colliding():
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

func _turn(dir: Vector2):
	match dir:
			Vector2.UP:
				emit_signal("idle_animation_requested", current_dir)
				emit_signal("current_direction_changed", current_dir)
			Vector2.DOWN:
				emit_signal("idle_animation_requested", current_dir)
				emit_signal("current_direction_changed", current_dir)
			Vector2.LEFT:
				emit_signal("idle_animation_requested", current_dir)
				emit_signal("current_direction_changed", current_dir)
			Vector2.RIGHT:
				emit_signal("idle_animation_requested", current_dir)
				emit_signal("current_direction_changed", current_dir)

func _turn_and_move(dir: Vector2):
	if not _can_go_in_dir(dir):
		_turn(dir)
	
	else:
		var footstep_pitch = randf_range(0.6, 1.0)
		var footstep_volume = randf_range(-21, -19)
		emit_signal("audio_play_requested", "Footstep", footstep_pitch, footstep_volume)
		
		match dir:
			Vector2.UP:
				emit_signal("idle_animation_requested", current_dir)
				emit_signal("current_direction_changed", current_dir)
			Vector2.DOWN:
				emit_signal("idle_animation_requested", current_dir)
				emit_signal("current_direction_changed", current_dir)
			Vector2.LEFT:
				emit_signal("idle_animation_requested", current_dir)
				emit_signal("current_direction_changed", current_dir)
			Vector2.RIGHT:
				emit_signal("idle_animation_requested", current_dir)
				emit_signal("current_direction_changed", current_dir)
	
		target_pos = global_position + current_dir * STEP_DISTANCE
		var mov_duration = STEP_DISTANCE / SPEED
		
		var tween = create_tween()
		tween.tween_property(owner, "global_position", target_pos, mov_duration)

func lock_movement():
	is_movement_locked = true
	print("Player.MovementController: Player movement lock set to ", is_movement_locked)
	
func unlock_movement():
	is_movement_locked = false
	print("Player.MovementController: Player movement lock set to ", is_movement_locked)
