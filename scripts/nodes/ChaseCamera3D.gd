extends Camera3D
class_name ChaseCamera3D


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var target_group : StringName = &""


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _target : WeakRef = weakref(null)


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
