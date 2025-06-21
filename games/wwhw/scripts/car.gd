extends Area2D
class_name WWHWCar


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const EXPLOSION_SCENE : PackedScene = preload("res://games/wwhw/objects/explosion/explosion.tscn")
const BOUNDS : Vector2 = Vector2(-120, 120)

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var speed : float = 160.0
@export var height : float = 0.0


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	area_entered.connect(_on_area_entered)
	position.y = BOUNDS.x

func _process(delta: float) -> void:
	position.y += speed * delta
	if position.y > BOUNDS.y + height:
		die()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func die(explode : bool = false) -> void:
	if explode:
		var parent : Node = get_parent()
		if parent is Node2D:
			var exp : Node2D = EXPLOSION_SCENE.instantiate()
			exp.position = position + Vector2(0.0, -10.0)
			parent.add_child(exp)
	queue_free()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_area_entered(area : Area2D) -> void:
	die(true)
