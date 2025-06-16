extends Node2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal scored()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const MIN_GAP : int = 16
const MAX_GAP : int = 128

const GAME_HEIGHT : int = 240
const GAME_WIDTH : int = 320
const MIN_POLE_HEIGHT : int = 8

const TRAVEL_SPEED : float = 32.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _upper_pole: AnimatableBody2D = %UpperPole
@onready var _lower_pole: AnimatableBody2D = %LowerPole
@onready var _detect_zone: Area2D = %DetectZone
@onready var _dz_collision: CollisionShape2D = %DZCollision

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_Setup()

func _physics_process(delta: float) -> void:
	position.x -= TRAVEL_SPEED * delta
	if position.x < -((float(GAME_WIDTH) * 0.5) + 16.0):
		queue_free.call_deferred()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _Setup() -> void:
	if _lower_pole == null or _upper_pole == null or _detect_zone == null or _dz_collision == null:
		return
	
	var hheight : float = float(GAME_HEIGHT) * 0.5
	var gap : int = randi_range(MIN_GAP, MAX_GAP)
	var min_pole_height : int = (-hheight) + MIN_POLE_HEIGHT
	var max_pole_height : int = hheight - MIN_POLE_HEIGHT - gap
	var pole_height : int = randi_range(MIN_POLE_HEIGHT, max_pole_height)
	
	_lower_pole.position.y = float(pole_height)
	_upper_pole.position.y = _lower_pole.position.y - float(gap)
	_detect_zone.position.y = _lower_pole.position.y - (float(gap) * 0.5)
	_dz_collision.shape.size.y = float(gap)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_detect_zone_body_exited(body: Node2D) -> void:
	if body is FlippyBird:
		scored.emit()
