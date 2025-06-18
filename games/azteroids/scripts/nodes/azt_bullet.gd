@tool
extends Area2D
class_name AztBullet


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const COLLISION_LAYER : int = 2
const COLLISION_MASK : int = 4

const GAME_WIDTH : Vector2 = Vector2(-160, 160)
const GAME_HEIGHT : Vector2 = Vector2(-120, 120)

const RADIUS : float = 2.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var color : Color = Color.ANTIQUE_WHITE:	set=set_color
@export var direction : Vector2 = Vector2.ONE:		set=set_direction
@export var speed : float = 100.0:					set=set_speed

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_color(c : Color) -> void:
	if color != c:
		color = c
		queue_redraw()


func set_direction(d : Vector2) -> void:
	d = d.normalized()
	if not direction.is_equal_approx(d):
		direction = d


func set_speed(s : float) -> void:
	if s >= 1.0 and not is_equal_approx(speed, s):
		speed = s

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = COLLISION_LAYER
	collision_mask = COLLISION_MASK
	
	var collision : CollisionShape2D = CollisionShape2D.new()
	add_child(collision)
	collision.shape = CircleShape2D.new()
	collision.shape.radius = RADIUS
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, color, true, -1.0, true)

func _process(delta: float) -> void:
	position += direction * speed * delta
	if position.x + RADIUS < GAME_WIDTH.x or position.x - RADIUS > GAME_WIDTH.y:
		queue_free()
	if position.y + RADIUS < GAME_HEIGHT.x or position.y - RADIUS > GAME_HEIGHT.y:
		queue_free()

# ------------------------------------------------------------------------------
# Handlers Methods
# ------------------------------------------------------------------------------
func _on_body_entered(body : Node2D) -> void:
	if body is AztRoid:
		body.break_roid()
		queue_free()
