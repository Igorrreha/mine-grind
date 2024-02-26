extends Node


signal mouse_clicked_at(global_position: Vector2)
signal mouse_idx_clicked_at(idx: int, global_position: Vector2)

signal mouse_clicked_at_floor(global_position: Vector2i)
signal mouse_idx_clicked_at_floor(idx: int, global_position: Vector2i)

signal mouse_clicked()
signal mouse_idx_clicked(idx: int)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var floor = Vector2i(event.global_position.floor())
		
		event = event as InputEventMouseButton
		
		mouse_clicked_at.emit(event.global_position)
		mouse_idx_clicked_at.emit(event.button_index, event.global_position)
		
		mouse_clicked_at_floor.emit(event.global_position.floor())
		mouse_idx_clicked_at_floor.emit(event.button_index, event.global_position.floor())
		
		mouse_clicked.emit()
		mouse_idx_clicked.emit(event.button_index)
