extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GROUP_PLAYER : StringName = &"Player"
const MOVE_SPEED : float = 2.0

const WAIT_CHANCE : float = 0.3
const WAIT_TIME_MIN : float = 1.0
const WAIT_TIME_MAX : float = 4.0

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
var _move_tween : Tween = null

#var _target_dest : Vector3 = Vector3.ZERO
var _need_dest : bool = true
var _wait_time : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _ghost: AnimatedSprite3D = %Ghost
@onready var _score_drainer: ScoreDrainer = %ScoreDrainer
@onready var _nav_agent: NavigationAgent3D = %NavAgent

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _process(delta: float) -> void:
	_UpdateGhostVis()
	if _need_dest:
		if _ghost.is_playing():
			_ghost.stop()
		if _wait_time <= 0.0:
			print("Finding destination")
			_FindNewDestination()
		else:
			#print("Wait Time: ", _wait_time)
			_wait_time -= delta
	_UpdatePosition(delta)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdatePosition(delta : float) -> void:
	var pos : Vector3 = _nav_agent.get_next_path_position()
	var direction : Vector3 = global_position.direction_to(pos)
	direction.y = 0.0
	if not _ghost.is_playing():
		if direction.length() > 0.0:
			_ghost.play("default")
	global_position += direction * MOVE_SPEED * delta

func _FindNewDestination() -> void:
	if nav_group == &"" or _nav_agent == null: return
	var dstlist : Array[Node] = get_tree().get_nodes_in_group(nav_group).filter(
		func(item : Node):
			return item is Node3D and not item.global_position.is_equal_approx(_nav_agent.target_position)
	)
	if dstlist.size() <= 1 : return
	var didx : int = randi_range(0, dstlist.size() - 1)
	_nav_agent.target_position = dstlist[didx].global_position
	_need_dest = false

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


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_nav_agent_target_reached() -> void:
	_need_dest = true
	if randf() <= WAIT_CHANCE:
		_wait_time = randf_range(WAIT_TIME_MIN, WAIT_TIME_MAX)
