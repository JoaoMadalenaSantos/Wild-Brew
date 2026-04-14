extends Node2D

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var col_ray_cast_up: RayCast2D = $Collision/RayCastUp
@onready var col_ray_cast_down: RayCast2D = $Collision/RayCastDown
@onready var col_ray_cast_left: RayCast2D = $Collision/RayCastLeft
@onready var col_ray_cast_right: RayCast2D = $Collision/RayCastRight
@onready var int_ray_cast: RayCast2D = $Interaction/RayCast2D

const STEP_DISTANCE: float = 16.0
const SPEED: float = 75.0

var moving_dir: Vector2
var target_pos: Vector2 = global_position

enum PlayerState {
	IDLE,
	WALKING
}

var current_state: PlayerState
var previous_state: PlayerState

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_up"):
			moving_dir = Vector2.UP
			_set_state(PlayerState.WALKING)
		
		if event.is_action_pressed("ui_down"):
			moving_dir = Vector2.DOWN
			_set_state(PlayerState.WALKING)
		
		if event.is_action_pressed("ui_left"):
			moving_dir = Vector2.LEFT
			_set_state(PlayerState.WALKING)
		
		if event.is_action_pressed("ui_right"):
			moving_dir = Vector2.RIGHT
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
			match moving_dir:
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
		
		PlayerState.WALKING:
			_turn_and_move(moving_dir)

func _exit_state(old_state: PlayerState):
	match old_state:
		PlayerState.IDLE:
			pass
		
		PlayerState.WALKING:
			pass

func _process_state(delta):
	match current_state:
		PlayerState.IDLE:
			pass
		
		PlayerState.WALKING:
			if global_position == target_pos:
				match moving_dir:
					Vector2.UP:
						if Input.is_action_pressed("ui_up") and _can_go_in_dir(Vector2.UP):
							_turn_and_move(moving_dir)
						else:
							_set_state(PlayerState.IDLE)
					Vector2.DOWN:
						if Input.is_action_pressed("ui_down") and _can_go_in_dir(Vector2.DOWN):
							_turn_and_move(moving_dir)
						else:
							_set_state(PlayerState.IDLE)
					Vector2.LEFT:
						if Input.is_action_pressed("ui_left") and _can_go_in_dir(Vector2.LEFT):
							_turn_and_move(moving_dir)
						else:
							_set_state(PlayerState.IDLE)
					Vector2.RIGHT:
						if Input.is_action_pressed("ui_right") and _can_go_in_dir(Vector2.RIGHT):
							_turn_and_move(moving_dir)
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

func _turn_and_move(dir: Vector2):
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
	
	if not _can_go_in_dir(dir):
		return
	
	target_pos = global_position + moving_dir * STEP_DISTANCE
	var mov_duration = STEP_DISTANCE / SPEED
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, mov_duration)
