extends Area3D
class_name ScoreDrainer

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal drain_complete()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DRAIN_TARGET_GAME : StringName = &"Game"
const DRAIN_TARGET_EMPTY : StringName = &"Empty"

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

var _drain_target_collection : WeightedRandomCollection = null

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_drain_target_collection = WeightedRandomCollection.new()
	_drain_target_collection.add_entry(DRAIN_TARGET_GAME, 100.0)
	_drain_target_collection.add_entry(DRAIN_TARGET_EMPTY, 8.0)

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
		_draining = true
		var am : ArcadeMachine = _available[_active_idx]
		if am.has_game():
			if am.get_score() > 0 and not am.is_focused():
				am.update_score(-drain_amount)
				if am.get_score() <= 0:
					_active_idx = -1
					drain_complete.emit()
		else:
			am.update_display(randi_range(1, 2))
		get_tree().create_timer(interval).timeout.connect(_Drain)
	else: _draining = false

func _GetIdxByName(game_name : StringName) -> int:
	for i : int in range(_available.size()):
		if _available[i].game_name == game_name:
			return i
	return -1

func _GetTargetIndex() -> int:
	if _available.size() > 0:
		var _gamed : Array[ArcadeMachine] = _available.filter(
			func (am : ArcadeMachine): return am.has_game() and am.is_focused() and am.get_score() > 0
		)
		var _emptied : Array[ArcadeMachine] = _available.filter(
			func (am : ArcadeMachine): return not (am.has_game() and am.is_focused() and am.get_score() > 0)
		)
		
		if _gamed.size() <= 0 or _emptied.size() <= 0:
			# One or the other is empty, so it doesn't really matter which machine
			# is picked!
			return randi_range(0, _available.size() - 1)
		else:
			# However, if both have machines, then we need to choose our target...
			var list : Array[ArcadeMachine] = _gamed
			if _drain_target_collection.get_random() == DRAIN_TARGET_EMPTY:
				list = _emptied
			var idx : int = randi_range(0, list.size() - 1)
			return _GetIdxByName(list[idx].game_name)
		
	return -1

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
			_active_idx = _GetTargetIndex()
		if not _draining:
			_Drain()

func end_drain() -> void:
	if _active_idx >= 0:
		_available[_active_idx].update_display(0)
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
