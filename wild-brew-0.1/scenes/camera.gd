extends Camera2D

@export var target: Node
@export var speed: float = 10.0

func _process(delta: float) -> void:
	global_position.x = lerpf(global_position.x, target.global_position.x, delta * speed)
	global_position.y = lerpf(global_position.y, target.global_position.y, delta * speed)
