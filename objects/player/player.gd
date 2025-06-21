@tool
extends CharacterBody3D



# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const MAX_GIMBLE_ANGLE = deg_to_rad(70.0)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var active : bool = true:			set=set_active
@export var walk_speed : float = 7.0
@export var turn_dps : float = 180.0
@export_range(0.0, 360.0) var initial_facing : float = 0.0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _move_input : Vector2 = Vector2.ZERO
var _turn_input : Vector2 = Vector2.ZERO

var _mouse_look : bool = false
var _sensitivity : Vector2 = Vector2(0.1, 0.1)

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _faux_cam: Node3D = %FauxCam
@onready var _gimble: Node3D = %Gimble
@onready var _step_cast: RayCast3D = $FauxCam/StepCast
@onready var _interactor: Interactor3D = %Interactor
@onready var _viz: Node3D = %Viz


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_active(a : bool) -> void:
	if active != a:
		active = a
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if not Engine.is_editor_hint():
		_viz.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
	_faux_cam.rotation.y = wrapf(
		_faux_cam.rotation.y + deg_to_rad(initial_facing),
		0.0, 2 * PI
	)

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	if event is InputEventMouseMotion:
		_mouse_look = true
		_turn_input = Vector2(-event.relative.y, -event.relative.x) * _sensitivity
	else:
		if _EventIs(event, PackedStringArray(["arcade_forward", "arcade_backward"])):
			_move_input.y = Input.get_axis("arcade_forward", "arcade_backward")
		elif _EventIs(event, PackedStringArray(["arcade_left", "arcade_right"])):
			_move_input.x = Input.get_axis("arcade_left", "arcade_right")
		elif _EventIs(event, PackedStringArray(["arcade_turn_left", "arcade_turn_right"])):
			_mouse_look = false
			_turn_input.y = Input.get_axis("arcade_turn_right", "arcade_turn_left")
		elif _EventIs(event, PackedStringArray(["arcade_look_up", "arcade_look_down"])):
			_mouse_look = false
			_turn_input.x = Input.get_axis("arcade_look_down", "arcade_look_up")
		elif event.is_action_pressed("arcade_interact"):
			if _interactor != null:
				_interactor.interact()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_UpdateLook(delta)
	if _mouse_look:
		_turn_input = Vector2.ZERO
	
	var gravity : Vector3 = get_gravity()
	var direction : Vector3 = Vector3(_move_input.x, 0.0, _move_input.y).rotated(Vector3.UP, _faux_cam.rotation.y)
	
	velocity = gravity + (direction * walk_speed)
	move_and_slide()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _EventIs(event : InputEvent, actions : PackedStringArray) -> bool:
	for action : StringName in actions:
		if event.is_action(action): return true
	return false

func _UpdateLook(delta : float) -> void:
	if not is_equal_approx(_turn_input.y, 0.0):
		_faux_cam.rotation.y = wrapf(
			_faux_cam.rotation.y + (_turn_input.y * deg_to_rad(turn_dps) * delta),
			0.0, 2 * PI
		)
	
	if not is_equal_approx(_turn_input.x, 0.0):
		_gimble.rotation.x = clampf(
			_gimble.rotation.x + (_turn_input.x * deg_to_rad(turn_dps) * delta),
			-MAX_GIMBLE_ANGLE, MAX_GIMBLE_ANGLE
		)
