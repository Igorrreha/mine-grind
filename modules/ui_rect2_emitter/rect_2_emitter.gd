extends VBoxContainer


signal triggered(rect: Rect2)


@export var _position_x: SpinBox
@export var _position_y: SpinBox
@export var _size_x: SpinBox
@export var _size_y: SpinBox

@export var _button: Button


func _ready() -> void:
	_button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	triggered.emit(Rect2(_position_x.value, _position_y.value, _size_x.value, _size_y.value))
