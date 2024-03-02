extends Node


signal mouse_clicked_at(global_position: Vector2)
signal mouse_idx_clicked_at(idx: int, global_position: Vector2)

signal mouse_clicked()
signal mouse_idx_clicked(idx: int)

signal lmb_clicked_at(global_position: Vector2i)
signal rmb_clicked_at(global_position: Vector2i)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		event = event as InputEventMouseButton
		
		mouse_clicked_at.emit(event.global_position)
		mouse_idx_clicked_at.emit(event.button_index, event.global_position)
		
		mouse_clicked.emit()
		mouse_idx_clicked.emit(event.button_index)
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			lmb_clicked_at.emit(event.global_position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			rmb_clicked_at.emit(event.global_position)
