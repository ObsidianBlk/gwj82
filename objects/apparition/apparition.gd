extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GROUP_PLAYER : StringName = &"Player"
const MOVE_SPEED : float = 2.0


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var nav_group : StringName = &""
@export_range(0.0, 20.0) var min_distance : float = 4.0
@export_range(0.0, 20.0) var max_distance : float = 10.0
@export var always_visible : bool = false

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _lights_out : bool = false
var _player : WeakRef = weakref(null)
var _target_dest : Vector3 = Vector3.ZERO
var _move_tween : Tween = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _ghost: AnimatedSprite3D = %Ghost
@onready var _score_drainer: ScoreDrainer = %ScoreDrainer

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _process(delta: float) -> void:
	_UpdateGhostVis()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _FindNewDestination() -> void:
	if nav_group == &"": return
	var dstlist : Array[Node3D] = get_tree().get_nodes_in_group(nav_group).filter(
		func(item : Node):
			return item is Node3D and not item.global_position.is_equal_approx(_target_dest)
	)
	if dstlist.size() <= 1 : return
	var didx : int = randi_range(0, dstlist.size() - 1)
	_target_dest = dstlist[didx].global_position

func _GetPlayer() -> Node3D:
	var player : Node3D = _player.get_ref()
	if player == null:
		var plist : Array = get_tree().get_nodes_in_group(GROUP_PLAYER)
		if plist.size() > 0:
			player = plist[0]
			_player = weakref(player)
	return player

func _DistanceTo2D(from : Vector3, to : Vector3) -> float:
	return Vector2(from.x, from.z).distance_to(Vector2(to.x, to.z))

func _AlphaFromDistance(from : Vector3, to : Vector3) -> float:
	var dist = _DistanceTo2D(from, to)
	var total_dist : float = max_distance - min_distance
	if total_dist == 0.0: return 0.0
	return clampf((dist - min_distance) / total_dist, 0.0, 1.0)

func _UpdateGhostVis() -> void:
	if always_visible:
		_ghost.modulate = Color(1.0, 1.0, 1.0, 1.0)
		return
		
	if _lights_out:
		var player = _GetPlayer()
		if player == null:
			_ghost.modulate = Color(1.0, 1.0, 1.0, 0.0)
			return
		var alpha : float = _AlphaFromDistance(global_position, player.global_position)
		_ghost.modulate = Color(1.0, 1.0, 1.0, alpha)
	else:
		_ghost.modulate = Color(1.0, 1.0, 1.0, 0.0)
