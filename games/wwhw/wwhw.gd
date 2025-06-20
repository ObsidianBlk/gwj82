extends ArcadeGame


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const BG_SPEED : float = 120.0
const BG_BOUNDS : Vector2 = Vector2(-136, 152)

const MILES_TO_MULTIPLIER : int = 4
const SEGS_TO_SCORE : int = 24
const SCORE_DISTANCE : int = 1
const SCORE_CRASH : int = -5

const CAR_SCENES : Array[PackedScene] = [
	preload("res://games/wwhw/objects/car_a/car_a.tscn"),
	preload("res://games/wwhw/objects/car_b/car_b.tscn"),
	preload("res://games/wwhw/objects/car_c/car_c.tscn"),
]

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

func _SpawnHazard() -> void:
	var has_cars : Array[bool] = [
		_LaneHasCar(_lane_left),
		_LaneHasCar(_lane_center),
		_LaneHasCar(_lane_right)
	]
	
	if has_cars.filter(func(oc : bool): return oc).size() <= 1:
		pass

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func prepare() -> void:
	if ambient_stream != null:
		play_ambient.emit(ambient_stream)
	if music_stream != null:
		play_music.emit(music_stream)
