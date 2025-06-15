@tool
extends CharacterBody2D
class_name AztShip


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal fired(bullet_position : Vector2, direction : Vector2)
signal crashed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const COLLISION_LAYER = 1
const COLLISION_MASK = 4

const SIZE : Vector2 = Vector2(16, 8)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var color : Color = Color.MEDIUM_TURQUOISE:	set=set_color
@export var acceleration : float = 10.0
@export var max_decel : float = 0.75
@export var max_speed : float = 80.0
@export var turn_dps : float = 180.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _motion_strength : Vector2 = Vector2.ZERO

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_color(c : Color) -> void:
	if color != c:
		color = c
		queue_redraw()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	collision_layer = COLLISION_LAYER
	collision_mask = COLLISION_MASK
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var collision : CollisionPolygon2D = CollisionPolygon2D.new()
	collision.polygon = _CalcPoints()
	add_child(collision)

func _draw() -> void:
	var points : PackedVector2Array = _CalcPoints()
	points.append(points[0])
	draw_polyline(points, color, 0.5, true)

func _process(delta: float) -> void:
	if not is_equal_approx(_motion_strength.x, 0.0):
		rotation = wrapf(
			rotation + (deg_to_rad(turn_dps) * delta * _motion_strength.x),
			-PI, PI
		)
	if not is_equal_approx(_motion_strength.y, 0.0):
		if _motion_strength.y > 0.0:
			var dir : Vector2 = Vector2.RIGHT.rotated(rotation) * acceleration * _motion_strength.y
			velocity += dir
			if velocity.length() > max_speed:
				velocity = velocity.normalized() * max_speed
		elif _motion_strength.y < 0.0:
			velocity = velocity.slerp(Vector2.ZERO, max_decel * abs(_motion_strength.y))
			if velocity.length() < 0.01:
				velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	move_and_slide()
	_ProcessCollisions()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ProcessCollisions() -> void:
	var info : KinematicCollision2D = get_last_slide_collision()
	if info != null:
		var body : Node2D = info.get_collider()
		if body is AztRoid:
			crashed.emit()


func _CalcPoints(angle : float = 0.0) -> PackedVector2Array:
	var hsize : Vector2 = SIZE * 0.5
	return PackedVector2Array([
		Vector2(hsize.x, 0.0).rotated(angle),
		Vector2(-hsize.x, hsize.y).rotated(angle),
		Vector2(-(hsize.x * 0.75), 0.0).rotated(angle),
		Vector2(-hsize.x, -hsize.y).rotated(angle),
	])

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_rect() -> Rect2:
	var points : PackedVector2Array = _CalcPoints(rotation)
	var mins : Vector2 = Vector2.ZERO
	var maxes : Vector2 = Vector2.ZERO
	var first : bool = true
	for point : Vector2 in points:
		if first:
			mins = point
			maxes = point
		else:
			mins.x = min(mins.x, point.x)
			mins.y = min(mins.y, point.y)
			maxes.x = max(maxes.x, point.x)
			maxes.y = max(maxes.y, point.y)
	return Rect2(global_position, Vector2(maxes.x - mins.x, maxes.y - mins.y))


func turn_strength(s : float) -> void:
	_motion_strength.x = clampf(s, -1.0, 1.0)

func accel_strength(s : float) -> void:
	_motion_strength.y = clampf(s, -1.0, 1.0)

func fire() -> void:
	var pos : Vector2 = (Vector2.RIGHT * SIZE.x * 0.5).rotated(rotation)
	fired.emit(global_position + pos, pos.normalized())
