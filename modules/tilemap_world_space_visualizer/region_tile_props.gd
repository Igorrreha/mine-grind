@tool

class_name RegionTileProps
extends Resource


@export var atlas_id: int
@export var is_terrain: bool:
	set(v):
		is_terrain = v
		notify_property_list_changed()

var tile_coords: Vector2i
var terrain_id: int


func _get_property_list() -> Array[Dictionary]:
	var properties: Array[Dictionary]
	properties.append({
		"name": "terrain_id",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT if is_terrain else PROPERTY_USAGE_NO_EDITOR,
	})
	properties.append({
		"name": "tile_coords",
		"type": TYPE_VECTOR2I,
		"usage": PROPERTY_USAGE_NO_EDITOR if is_terrain else PROPERTY_USAGE_DEFAULT,
	})

	return properties
