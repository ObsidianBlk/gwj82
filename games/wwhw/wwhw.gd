extends ArcadeGame


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CYCLE_SCENE : PackedScene = preload("res://games/wwhw/cycle/cycle.tscn")

const BG_SPEED : float = 300.0
const BG_BOUNDS : Vector2 = Vector2(-136, 152)

const MILES_TO_MULTIPLIER : int = 4
const SEGS_TO_SCORE : int = 24
const SCORE_DISTANCE : int = 1
const SCORE_CRASH : int = -5

const CYCLE_RESPAWN_DELAY : float = 1.0

const CAR_SCENES : Array[PackedScene] = [
	preload("res://games/wwhw/objects/car_a/car_a.tscn"),
	preload("res://games/wwhw/objects/car_b/car_b.tscn"),
	preload("res://games/wwhw/objects/car_c/car_c.tscn"),
]

const HAZARD_LEFT_PAIR : StringName = &"HazLeftPair"
const HAZARD_RIGHT_PAIR : StringName = &"HazRightPair"
const HAZARD_SPLIT_PAIR : StringName = &"HazSplitPair"
const HAZARD_LEFT_SINGLE : StringName = &"HazLeftSingle"
const HAZARD_CENTER_SINGLE : StringName = &"HazCenterSingle"
const HAZARD_RIGHT_SINGLE : StringName = &"HazRightSingle"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var music_stream : AudioStream = null
@export var ambient_stream : AudioStream = null

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _cycle : WeakRef = weakref(null)
var _segment : int = 0
var _miles : int = 0
var _multiplier : int = 1

var _hazards_weighted : WeightedRandomCollection = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _backdrop: Node2D = %Backdrop
@onready var _lane_center: Node2D = %LaneCenter
@onready var _lane_left: Node2D = %LaneLeft
@onready var _lane_right: Node2D = %LaneRight


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_hazards_weighted = WeightedRandomCollection.new()
	_hazards_weighted.add_entry(HAZARD_LEFT_PAIR, 5.0)
	_hazards_weighted.add_entry(HAZARD_RIGHT_PAIR, 5.0)
	_hazards_weighted.add_entry(HAZARD_SPLIT_PAIR, 5.0)
	_hazards_weighted.add_entry(HAZARD_LEFT_SINGLE, 8.0)
	_hazards_weighted.add_entry(HAZARD_RIGHT_SINGLE, 8.0)
	_hazards_weighted.add_entry(HAZARD_CENTER_SINGLE, 8.0)
	_SpawnCycle()

func _unhandled_input(event: InputEvent) -> void:
	if not active : return
	
	var cycle : Node2D = _GetPlayerCycle()
	if cycle == null: return
	
	if event.is_action_pressed("game_left"):
		cycle.move_left()
	elif event.is_action_pressed("game_right"):
		cycle.move_right()

func _process(delta: float) -> void:
	_UpdateBackground(delta)
	if _hazards_weighted != null:
		var haz : StringName = _hazards_weighted.get_random()
		match haz:
			HAZARD_LEFT_PAIR:
				_SpawnLeftCarPair()
			HAZARD_RIGHT_PAIR:
				_SpawnRightCarPair()
			HAZARD_SPLIT_PAIR:
				_SpawnSplitCarPair()
			HAZARD_LEFT_SINGLE:
				if not (_LaneHasCar(_lane_left) or _LaneHasCar(_lane_center)):
					_SpawnCarInLane(_lane_left)
			HAZARD_RIGHT_SINGLE:
				if not (_LaneHasCar(_lane_right) or _LaneHasCar(_lane_center)):
					_SpawnCarInLane(_lane_right)
			HAZARD_CENTER_SINGLE:
				if not _LaneHasCar(_lane_center) and (not _LaneHasCar(_lane_left) or not _LaneHasCar(_lane_right)):
					_SpawnCarInLane(_lane_center)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateBackground(delta : float) -> void:
	if _backdrop == null: return
	var amount : float = BG_SPEED * delta
	for child in _backdrop.get_children():
		if child is Sprite2D:
			child.position.y += amount
			if child.position.y >= BG_BOUNDS.y:
				child.position.y -= BG_BOUNDS.y - BG_BOUNDS.x
				_UpdateSegment()

func _UpdateSegment() -> void:
	if not active: return
	_segment += 1
	if _segment > 0 and _segment % SEGS_TO_SCORE == 0:
		update_score(SCORE_DISTANCE * _multiplier)
		_miles += 1
		if _miles > 0 and _miles % MILES_TO_MULTIPLIER == 0:
			_multiplier += 1

func _GetPlayerCycle() -> Node2D:
	var cycle : Node2D = _cycle.get_ref()
	if cycle == null:
		for child : Node in get_children():
			if child.has_method(&"move_left") and child.has_method(&"move_right"):
				cycle = child
		if cycle != null:
			_cycle = weakref(cycle)
	return cycle

func _LaneHasCar(lane : Node2D) -> bool:
	if lane == null: return false
	for child : Node in lane.get_children():
		if child is WWHWCar:
			return true
	return false

func _IsRoadClear() -> bool:
	return not (_LaneHasCar(_lane_left) or _LaneHasCar(_lane_center) or _LaneHasCar(_lane_right))

func _SpawnCarInLane(lane : Node2D) -> void:
	if lane == null: return
	var car : Node2D = CAR_SCENES[randi_range(0, CAR_SCENES.size() - 1)].instantiate()
	lane.add_child(car)

func _SpawnLeftCarPair() -> int:
	if not _IsRoadClear(): return ERR_ALREADY_IN_USE
	_SpawnCarInLane(_lane_left)
	_SpawnCarInLane(_lane_center)
	return OK

func _SpawnRightCarPair() -> int:
	if not _IsRoadClear(): return ERR_ALREADY_IN_USE
	_SpawnCarInLane(_lane_right)
	_SpawnCarInLane(_lane_center)
	return OK

func _SpawnSplitCarPair() -> int:
	if not _IsRoadClear(): return ERR_ALREADY_IN_USE
	_SpawnCarInLane(_lane_right)
	_SpawnCarInLane(_lane_left)
	return OK

func _SpawnCycle() -> void:
	if _cycle.get_ref() != null: return
	var cycle : Node2D = CYCLE_SCENE.instantiate()
	_cycle = weakref(cycle)
	cycle.crashed.connect(_on_cycle_crashed)
	cycle.position.y = 80.0
	add_child(cycle)
	if not _LaneHasCar(_lane_center):
		cycle.set_lane(1)
	elif not _LaneHasCar(_lane_left):
		cycle.set_lane(0)
	elif not _LaneHasCar(_lane_right):
		cycle.set_lane(2)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func prepare() -> void:
	if ambient_stream != null:
		play_ambient.emit(ambient_stream)
	if music_stream != null:
		play_music.emit(music_stream)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_cycle_crashed() -> void:
	if active:
		update_score(SCORE_CRASH)
	get_tree().create_timer(CYCLE_RESPAWN_DELAY).timeout.connect(
		_SpawnCycle, CONNECT_ONE_SHOT
	)
