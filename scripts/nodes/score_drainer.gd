extends Area3D
class_name ScoreDrainer

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal drain_complete()

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var interval : float = 1.0
@export var drain_amount : int = 5

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _available : Array[ArcadeMachine] = []
var _active_idx : int = -1
var _draining : bool = false

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetArcadeMachineIndex(arc : ArcadeMachine) -> int:
	for idx : int in range(_available.size()):
		if _available[idx] == arc:
			return idx
	return -1

func _Drain() -> void:
	if _active_idx >= 0:
		var am : ArcadeMachine = _available[_active_idx]
		if am.has_game():
			am.update_score(-drain_amount)
		_draining = true
		get_tree().create_timer(interval).timeout.connect(_Drain)
	else: _draining = false

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func has_targets() -> bool:
	return _available.size() > 0

func start_drain() -> void:
	if _active_idx < 0 and _available.size() > 0:
		if _available.size() == 1:
			_active_idx = 0
		else:
			_active_idx = randi_range(0, _available.size() - 1)
		if not _draining:
			_Drain()

func end_drain() -> void:
	_active_idx = -1

func is_draining() -> bool:
	return _active_idx >= 0

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_body_entered(body : Node3D) -> void:
	if body is ArcadeMachine:
		if _GetArcadeMachineIndex(body) < 0:
			_available.append(body)

func _on_body_exited(body : Node3D) -> void:
	if body is ArcadeMachine:
		var idx : int = _GetArcadeMachineIndex(body)
		if idx >= 0:
			_available.remove_at(idx)
			if _active_idx == idx:
				_active_idx = -1
				drain_complete.emit()
