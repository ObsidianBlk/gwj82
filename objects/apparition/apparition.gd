extends Node3D
class_name Apparition


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GROUP_PLAYER : StringName = &"Player"
const MOVE_SPEED : float = 2.0

const WAIT_TIME_MIN : float = 1.0
const WAIT_TIME_MAX : float = 4.0

const ACTION_UNKNOWN : StringName = &""
const ACTION_DRAIN : StringName = &"Drain"
const ACTION_MOVE : StringName = &"Move"
const ACTION_APPARATE : StringName = &"Apparate"
const ACTION_RAGE : StringName = &"Rage"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var nav_group : StringName = &""
@export var enabled : bool = false
@export_range(0.0, 20.0) var min_distance : float = 4.0
@export_range(0.0, 20.0) var max_distance : float = 10.0
@export_range(0.0, 1.0) var max_alpha : float = 1.0
@export var always_visible : bool = false

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _lights_out : bool = false
var _player : WeakRef = weakref(null)
var _move_tween : Tween = null

var _action_collection : WeightedRandomCollection = null
var _action : StringName = &""
var _queued_action : StringName = &""

var _poi : Dictionary[StringName, POI] = {}
var _poi_weight : WeightedRandomCollection = null

#var _target_dest : Vector3 = Vector3.ZERO
var _need_dest : bool = true
var _wait_time : float = 0.0

# ------------------------------------------------------------------------------
# Static Variables
# ------------------------------------------------------------------------------
static var _instance : Apparition = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _ghost: AnimatedSprite3D = %Ghost
@onready var _score_drainer: ScoreDrainer = %ScoreDrainer
@onready var _nav_agent: NavigationAgent3D = %NavAgent
@onready var _asp_mumble: AudioStreamPlayer3D = %ASP_Mumble

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_nav_group(ng : StringName) -> void:
	if ng != nav_group:
		nav_group = ng
		_poi.clear()
		if _poi_weight != null:
			_poi_weight.clear()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_action_collection = WeightedRandomCollection.new()
	_action_collection.add_entry(ACTION_DRAIN, 1000.0)
	_action_collection.add_entry(ACTION_MOVE, 200.0)
	_action_collection.add_entry(ACTION_APPARATE, 100.0)
	_action_collection.add_entry(ACTION_RAGE, 5.0)

func _enter_tree() -> void:
	if _instance == null:
		_instance = self

func _exit_tree() -> void:
	if _instance == self:
		_instance = null

func _process(delta: float) -> void:
	if _action != ACTION_APPARATE:
		_UpdateGhostVis()
	if _asp_mumble != null:
		if not enabled and _asp_mumble.playing:
			_asp_mumble.stop()
		elif enabled and not _asp_mumble.playing:
			_asp_mumble.play()
	
	if not enabled: return
	match _action:
		ACTION_UNKNOWN:
			if _action_collection != null:
				_GetNextAction()
			else:
				_action = ACTION_MOVE
		ACTION_MOVE:
			#print("Action MOVE")
			if _need_dest:
				_need_dest = false
				_FindNewDestination()
			else:
				_UpdatePosition(delta)
		ACTION_APPARATE:
			if _need_dest:
				_need_dest = false
				if _move_tween == null:
					_ApparateToDestination()
			elif _move_tween == null:
				_need_dest = true
				_GetNextAction(ACTION_APPARATE)
		ACTION_DRAIN:
			#print("Action DRAIN")
			if _need_dest:
				_need_dest = false
				_score_drainer.start_drain()
				_wait_time = randf_range(WAIT_TIME_MIN, WAIT_TIME_MAX)
			elif _wait_time > 0.0:
				_wait_time -= delta
			else:
				_need_dest = true
				_score_drainer.end_drain()
				_action = ACTION_MOVE
		ACTION_RAGE:
			#print("Action RAGE")
			_action = ACTION_DRAIN

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
	if _poi.size() <= 0:
		_BuildPOIList()
	if _poi.size() <= 0: return

	var poi_name : StringName = _poi_weight.get_random()
	if global_position.is_equal_approx(_poi[poi_name].global_position):
		return
	
	_nav_agent.target_position = _poi[poi_name].global_position
	_need_dest = false

func _ApparateToDestination() -> void:
	if nav_group == &"": return
	if _poi.size() <= 0:
		_BuildPOIList()
	if _poi.size() <= 0: return
	
	var poi_name : StringName = _poi_weight.get_random()
	if global_position.is_equal_approx(_poi[poi_name].global_position):
		return
	
	var mod_color : Color = _ghost.modulate
	var app : Apparition = self
	var dest : Vector3 = _poi[poi_name].global_position
	if is_equal_approx(mod_color.a, 0.0): return
	
	_move_tween = create_tween()
	_move_tween.set_ease(Tween.EASE_IN_OUT)
	_move_tween.set_trans(Tween.TRANS_SINE)
	_move_tween.set_parallel(false)
	_move_tween.tween_property(_ghost, "modulate", Color(0.0, 0.0, 0.0, 0.0), 0.25)
	_move_tween.tween_callback(
		func():
			app.global_position = dest
	)
	_move_tween.tween_interval(0.25)
	_move_tween.tween_property(_ghost, "modulate", mod_color, 0.25)
	await _move_tween.finished
	_move_tween = null

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
	var alpha : float = clampf((dist - min_distance) / total_dist, 0.0, 1.0)
	return alpha

func _UpdateGhostVis() -> void:
	if not enabled:
		_ghost.modulate = Color(0.0, 0.0, 0.0, 0.0)
		return
	
	if always_visible:
		_ghost.modulate = Color(1.0, 1.0, 1.0, 1.0)
		return

	var player = _GetPlayer()
	if player == null:
		_ghost.modulate = Color(1.0, 1.0, 1.0, 0.0)
		return
	var alpha : float = _AlphaFromDistance(global_position, player.global_position)
	_ghost.modulate = Color(1.0, 1.0, 1.0, alpha * max_alpha)

func _BuildPOIList() -> void:
	if _poi.size() > 0:
		_poi.clear()
		if _poi_weight != null:
			_poi_weight.clear()
	
	if nav_group == &"" : return
	var poilist : Array[Node] = get_tree().get_nodes_in_group(nav_group)
	for n : Node in poilist:
		if n is POI and n.weight > 0.0:
			_poi[n.name] = n
	
	if _poi.size() > 0:
		if _poi_weight == null:
			_poi_weight = WeightedRandomCollection.new()
		for poi : POI in _poi.values():
			_poi_weight.add_entry(poi.name, poi.weight)

func _GetNextAction(exclude_action : StringName = &"") -> void:
	if _action_collection == null: return
	var act : StringName = &""
	if not _queued_action.is_empty() and _queued_action != exclude_action:
		act = _queued_action
		_queued_action = &""
	elif exclude_action.is_empty():
		act = _action_collection.get_random()
	else:
		for _i : int in range(10):
			act = _action_collection.get_random()
			if act != exclude_action: break
	_action = act

# ------------------------------------------------------------------------------
# Static Public Methods
# ------------------------------------------------------------------------------
static func Get_Instance() -> Apparition:
	return _instance

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_action(action : StringName) -> void:
	_queued_action = action

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_nav_agent_target_reached() -> void:
	_need_dest = true
	if _action_collection != null:
		_GetNextAction()
	else:
		_action = ACTION_UNKNOWN
