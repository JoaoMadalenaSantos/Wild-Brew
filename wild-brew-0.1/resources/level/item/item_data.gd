extends Resource

class_name ItemData

@export var id: String
@export var texture_atlas_y: int

@export var expirable: bool
@export var expiration_result_item: ItemData

@export var consumable: bool

@export var collectable: bool
@export var drop_quantity_range: Vector2i
@export var max_item_stack: int
