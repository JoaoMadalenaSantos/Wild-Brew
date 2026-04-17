extends Camera2D

@export var starting_position: Vector2 = Vector2.ZERO
@export var target: Node = null
@export var speed: float = 10.0

func _ready() -> void:
	print("Camera: Starting position:", starting_position)
	if target:
		global_position = starting_position
	make_current()

func _process(delta: float) -> void:
	if target:
		global_position.x = lerpf(global_position.x, target.global_position.x, delta * speed)
		global_position.y = lerpf(global_position.y, target.global_position.y, delta * speed)
