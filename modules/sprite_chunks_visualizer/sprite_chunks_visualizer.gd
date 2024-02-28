class_name SpriteChunksVisualizer
extends Node


@export var _world_space: WorldSpace


func _ready() -> void:
	_world_space.chunk_activated.connect(_show_chunk)
	_world_space.chunk_deactivated.connect(_hide_chunk)


func _show_chunk(chunk: WorldSpaceChunk, chunk_type: WorldSpaceChunkType) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(chunk.map.image)
	sprite.position = chunk.rect.position
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)


func _hide_chunk(chunk: WorldSpaceChunk, chunk_type: WorldSpaceChunkType) -> void:
	pass
