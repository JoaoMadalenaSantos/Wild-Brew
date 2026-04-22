extends Control

@onready var ui_manager: Node = $"../../../UIManager"

@onready var color_rect: ColorRect = $ColorRect
@onready var timer: Timer = $Timer

@export var transition_duration: float = 0.5

var current_diameter: float = 0.0
var target_diameter: float = 0.0

signal open_finished
signal close_finished

func _ready() -> void:
	ui_manager.transition_close_requested.connect(close)
	ui_manager.transition_open_requested.connect(open)
	
	open_finished.connect(ui_manager._on_transition_open_finished)
	close_finished.connect(ui_manager._on_transition_close_finished)
	
	
	open()

func _process(delta: float) -> void:
	if current_diameter == target_diameter:
		return
	else:
		color_rect.material.set_shader_parameter("circle_diameter", current_diameter)
		

func open(delay: float = 0.1):
	
	timer.wait_time = delay
	timer.start()
	
	timer.timeout.connect(_on_timer_timeout, CONNECT_ONE_SHOT)
	
func _on_timer_timeout():
	target_diameter = sqrt(get_viewport().size.x ** 2 + get_viewport().size.y ** 2) + 50
	
	var tween = create_tween()
	tween.tween_property(self, "current_diameter", target_diameter, transition_duration)
	
	tween.finished.connect(func():
		emit_signal("open_finished")
		visible = false
	)

func close():
	visible = true
	target_diameter = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "current_diameter", target_diameter, transition_duration)
	
	tween.finished.connect(func():
		emit_signal("close_finished")
	)
