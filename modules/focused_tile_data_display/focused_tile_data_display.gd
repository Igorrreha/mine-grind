extends TextureRect


@export var _focused_tile_selector: FocusedTileSelector
@export var _tilemap: TileMap


func _ready() -> void:
	_focused_tile_selector.focused_tile_chaged.connect(_on_focused_tile_changed)


func _on_focused_tile_changed(tile_coords: Vector2i) -> void:
	var atlas_coords = _tilemap.get_cell_atlas_coords(1, tile_coords)
	var source_id = _tilemap.get_cell_source_id(1, tile_coords)
	
	if source_id == -1:
		(texture as AtlasTexture).atlas = null
		return
	
	var source = _tilemap.tile_set.get_source(source_id) as TileSetAtlasSource
	var tile_texture_region = source.get_tile_texture_region(atlas_coords)
	var atlas_texture = (texture as AtlasTexture)
	atlas_texture.atlas = source.texture
	atlas_texture.region = tile_texture_region
