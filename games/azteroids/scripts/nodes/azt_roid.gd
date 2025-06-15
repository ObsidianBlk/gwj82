@tool
extends CharacterBody2D
class_name AztRoid


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal broken()


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const COLLISION_LAYER : int = 4
const COLLISION_MASK : int = 2

const MIN_RADIUS : float = 4.0
const MAX_RADIUS : float = 8.0

const MIN_POINTS : int = 6
const MAX_POINTS : int = 12

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var color : Color = Color.ANTIQUE_WHITE:						set=set_color
@export_range(MIN_RADIUS, MAX_RADIUS) var radius : float = MIN_RADIUS:	set=set_radius
@export_range(MIN_POINTS, MAX_POINTS) var points : int = MIN_POINTS:	set=set_points
@export_range(-PI, PI) var angular_velocity : float = PI * 0.25

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _build_queued : bool = true
var _collision : CollisionPolygon2D = null

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_color(c : Color) -> void:
	if color != c:
		color = c
		queue_redraw()

func set_radius(r : float) -> void:
	if r >= MIN_RADIUS and r <= MAX_RADIUS and not is_equal_approx(radius, r):
		radius = r
		_build_queued = true

func set_points(p : int) -> void:
	if p >= MIN_POINTS and p <= MAX_POINTS and p != points:
		points = p
		_build_queued = true

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _init(randomized : bool = false) -> void:
	if randomized:
		radius = randf_range(MIN_RADIUS, MAX_RADIUS)
		points = randi_range(MIN_POINTS, MAX_POINTS + 1)
		angular_velocity = randf_range(-PI, PI)

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = COLLISION_LAYER
	collision_mask = COLLISION_MASK
	
	_collision = CollisionPolygon2D.new()
	add_child(_collision)

func _draw() -> void:
	if _collision == null: return
	if _collision.polygon.size() < MIN_POINTS: return
	var dpoints = PackedVector2Array(_collision.polygon)
	dpoints.append(dpoints[0])
	draw_polyline(dpoints, color, 0.5, true)

func _process(_delta: float) -> void:
	if _build_queued:
		_BuildRoid()

func _physics_process(delta: float) -> void:
	rotation = wrapf(rotation + angular_velocity * delta, -PI, PI)
	if not Engine.is_editor_hint():
		move_and_slide()
		_CheckCollision()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _CheckCollision() -> void:
	var info : KinematicCollision2D = get_last_slide_collision()
	if info != null:
		var node : Node2D = info.get_collider()
		if node is AztBullet:
			node.queue_free()
			broken.emit()

func _BuildRoid() -> void:
	if _collision == null: return
	_build_queued = false
	
	var min_radius : float = radius * 0.65
	var max_angle : float = (deg_to_rad(360.0)) / (points + 2)
	
	var roid_points : Array[Vector2] = []
	var angle : float = 0.0
	
	for _i : int in range(points + 1):
		var point : Vector2 = (Vector2.UP * randf_range(min_radius, radius)).rotated(angle)
		roid_points.append(point)
		angle += max_angle
	
	_collision.polygon = PackedVector2Array(roid_points)
	queue_redraw()
