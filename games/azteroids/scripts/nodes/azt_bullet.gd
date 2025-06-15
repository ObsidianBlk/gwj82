@tool
extends CharacterBody2D
class_name AztBullet


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const COLLISION_LAYER : int = 2
const COLLISION_MASK : int = 4

const RADIUS : float = 2.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var direction : Vector2 = Vector2.ONE:		set=set_direction
@export var speed : float = 100.0:					set=set_speed

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
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
	collision_layer = COLLISION_LAYER
	collision_mask = COLLISION_MASK
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	var collision : CollisionShape2D = CollisionShape2D.new()
	add_child(collision)
	collision.shape = CircleShape2D.new()
	collision.shape.radius = RADIUS
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color.ANTIQUE_WHITE, true)

func _physics_process(_delta: float) -> void:
	velocity = direction * speed
	move_and_slide()
