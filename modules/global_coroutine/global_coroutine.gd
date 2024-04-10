extends Node


var _operations_queue: Array[Callable]
var _frame_time_limit_msec: int = 13


func add_operation(operation: Callable) -> void:
	_operations_queue.append(operation)


func _process(delta: float) -> void:
	if _operations_queue.is_empty():
		return
	
	var frame_start_time = Time.get_ticks_msec()
	
	while not _operations_queue.is_empty()\
	and Time.get_ticks_msec() - frame_start_time < _frame_time_limit_msec:
		_operations_queue.pop_front().call()
	
	#print(Time.get_ticks_msec() - frame_start_time)
