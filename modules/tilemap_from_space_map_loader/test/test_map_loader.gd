extends Node


@export var _map_loader: TileMapFromSpaceMapLoader
@export var _map: SpaceMap


func _ready() -> void:
	await _map.use_texture_image()
	_map_loader.load_map(_map)
