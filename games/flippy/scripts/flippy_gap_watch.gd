extends Area2D
class_name FlippyGapWatch


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _queue : Array[Area2D] = []

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetAreaIndex(area : Area2D) -> int:
	if _queue.size() > 0:
		return _queue.find(area)
	return -1

func _RemoveArea(area : Area2D) -> void:
	var idx : int = _GetAreaIndex(area)
	if idx >= 0:
		_queue.remove_at(idx)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	_queue.clear()

func has_area() -> bool:
	return _queue.size() > 0

func get_area_position() -> Vector2:
	if _queue.size() > 0:
		return _queue[0].global_position
	return Vector2.ZERO

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_area_entered(area : Area2D) -> void:
	var idx : int = _GetAreaIndex(area)
	if idx < 0:
		_queue.append(area)

func _on_area_exited(area : Area2D) -> void:
	_RemoveArea(area)
