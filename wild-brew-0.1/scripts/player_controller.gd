extends Node2D

class_name PlayerController

@onready var ui_manager: Node = $UIRoot/UIManager
@onready var level_manager: Node = $"../../../LevelManager"

@export var anim_sprite: AnimatedSprite2D
@export var movement_controller: Node2D
@export var interaction_controller: Node2D
@export var inventory: Node
@export var sounds_helper: Node2D

signal inventory_data_changed(new_inventory_data: Dictionary)

func _ready() -> void:
	inventory.inventory_data_changed.connect(_on_inventory_data_changed)
	inventory_data_changed.connect(ui_manager.update_hud_inventory)
		
func _on_dropped_item_found_player(dropped_item: Node2D):
	if inventory.try_adding_item(dropped_item.item, 1):
		dropped_item._on_collected()
		
func _on_inventory_data_changed(new_inventory_data: Dictionary):
	emit_signal("inventory_data_changed", new_inventory_data)
