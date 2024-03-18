extends Node


@export var _world_space: WorldSpace

@export var _save_input: InputEventKey
@export var _load_input: InputEventKey

@export var _activate_chunks_on_load: bool


func _input(event: InputEvent) -> void:
	if _load_input.is_match(event)\
	and event.is_pressed() == _load_input.pressed\
	and not event.is_echo()\
	and WorldSpace.has_save(_world_space.id):
		WorldSpace.load_from_save(_world_space.id)
		
		if _activate_chunks_on_load:
			_world_space.activate_chunks_intersects(Rect2i(0, 0, 200, 200))
		
		print("WorldSpace loaded %s" % _world_space.id)
	
	if _save_input.is_match(event)\
	and event.is_pressed() == _save_input.pressed\
	and not event.is_echo():
		WorldSpace.save(_world_space)
		print("WorldSpace saved %s" % _world_space.id)
