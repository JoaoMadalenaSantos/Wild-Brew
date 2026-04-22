extends Node2D

class_name DroppedItem

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var player_detector: Area2D = $PlayerDetector
@onready var collecting_sound: AudioStreamPlayer2D = $CollectingSound

@export var item: ItemData
@export var spawn_distance_travelled: float
@export var spawn_tween_duration: float = 1.0

signal dropped_item_found_player(self_body: Node2D)

func _ready() -> void:
	if item:
		set_item(item)
	
	var target_global_position: Vector2
	target_global_position.x = global_position.x + randf_range(-spawn_distance_travelled, spawn_distance_travelled)
	target_global_position.y = global_position.y + randf_range(-spawn_distance_travelled, spawn_distance_travelled)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUINT)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", target_global_position, spawn_tween_duration)

func set_item(item: ItemData):
	var atlas_texture = sprite_2d.texture as AtlasTexture
	atlas_texture.region = Rect2(32.0, item.texture_atlas_y, 16.0, 16.0)

func _on_player_detector_area_entered(area: Area2D) -> void:
	var body = area.get_parent()
	
	if body.is_in_group("player") and item:
		dropped_item_found_player.connect(body._on_dropped_item_found_player)
		emit_signal("dropped_item_found_player", self)

func _on_collected():
	collecting_sound.play()
	queue_free()
