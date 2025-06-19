extends Node3D



# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
enum State {CLOSED=0, OPENED=1}

const STATE_OPENED_ANGLE : float = deg_to_rad(122.0)
const STATE_CLOSED_ANGLE : float = 0.0
const CHANGE_DPS : float = deg_to_rad(90.0)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var door_visible : bool = true:				set=set_door_visible
@export var locked : bool = false
@export var initial_state : State = State.CLOSED

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _state : State = State.CLOSED
var _tween : Tween = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _door: CharacterBody3D = %Door
@onready var _door_collision: CollisionShape3D = %DoorCollision

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_door_visible(v : bool) -> void:
	if door_visible != v:
		door_visible = v
		_UpdateDoorVisibility()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_state = initial_state
	match initial_state:
		State.OPENED:
			_door.rotation.y = STATE_OPENED_ANGLE
		State.CLOSED:
			_door.rotation.y = STATE_CLOSED_ANGLE
	_UpdateDoorVisibility()


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _TweenDoor(angle : float) -> void:
	if _door == null: return
	if _tween != null:
		_tween.kill()
		_tween = null
	
	var diff : float = abs(_door.rotation.y - angle)
	var duration : float = diff / CHANGE_DPS

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(_door, "rotation:y", angle, duration)
	_tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)

func _UpdateDoorVisibility() -> void:
	if _door == null or _door_collision == null: return
	_door.visible = door_visible
	_door_collision.disabled = not door_visible

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_tween_finished() -> void:
	_tween = null

func _on_component_interactable_interacted(payload: Dictionary) -> void:
	match _state:
		State.OPENED:
			_state = State.CLOSED
			_TweenDoor(STATE_CLOSED_ANGLE)
		State.CLOSED:
			if not locked:
				_state = State.OPENED
				_TweenDoor(STATE_OPENED_ANGLE)
