extends Camera3D
class_name ChaseCamera3D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal flow_completed()
signal flow_canceled()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const TWEEN_DIST_PER_SECOND : float = 2.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var target_group : StringName = &""


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _target : WeakRef = weakref(null)
var _tween : Tween = null


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_target_group(tg : StringName) -> void:
	if target_group != tg:
		_target = weakref(null)
		target_group = tg

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _tween != null: return # The tween is taking control
	
	var target : Node3D = _GetTargetNode()
	if target == null: return
	global_position = target.global_position
	global_basis = target.global_basis
	#global_position = target.global_position


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetTargetNode() -> Node3D:
	var target : Node3D = _target.get_ref()
	if target == null and not target_group.is_empty():
		var nodes : Array[Node] = get_tree().get_nodes_in_group(target_group)
		for node : Node in nodes:
			if node is Node3D:
				target = node
				_target = weakref(node)
				break
	return target

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func flow_to(group : StringName) -> void:
	if target_group == group or group.is_empty(): return
	var nodes : Array[Node] = get_tree().get_nodes_in_group(group)
	for node : Node in nodes:
		if node is Node3D:
			if _tween != null:
				_tween.kill()
				_tween = null
				flow_canceled.emit()
			
			target_group = group
			_target = weakref(node)
			
			var dist : float = global_position.distance_to(node.global_position)
			var duration : float = dist / TWEEN_DIST_PER_SECOND
			
			_tween = get_tree().create_tween()
			_tween.set_ease(Tween.EASE_IN_OUT)
			_tween.set_trans(Tween.TRANS_QUAD)
			
			_tween.set_parallel(true)
			_tween.tween_property(self, "global_position", node.global_position, duration)
			_tween.tween_property(self, "global_basis", node.global_basis, duration)
			
			_tween.finished.connect(_on_tween_finished)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_tween_finished() -> void:
	_tween = null
	flow_completed.emit()
