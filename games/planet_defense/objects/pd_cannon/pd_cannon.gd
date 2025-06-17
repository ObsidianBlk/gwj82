extends Node2D

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal hit()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const LAZER_SCENE : PackedScene = preload("res://games/planet_defense/objects/pd_cannon/pd_cannon_lazer/pd_cannon_lazer.tscn")

# ZOE = (Z)one (O)f (E)ngagement
const ZOE_BOUND : Vector2i = Vector2i(-128, 128)

const ACCEL : float = 90.0
const MAX_SPEED : float = 80.0

const FIRE_DELAY : float = 0.1

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _direction : float = 0.0
var _speed : float = 0.0
var _fire_delay : float = FIRE_DELAY

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if _fire_delay > 0.0:
		_fire_delay -= delta
	
	if is_equal_approx(_direction, 0.0):
		_speed = lerpf(_speed, 0.0, 0.25 * delta)
	else:
		_speed = clampf(_speed + (_direction * ACCEL * delta), -MAX_SPEED, MAX_SPEED)
	position.x += _speed * delta

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func move(strength : float) -> void:
	_direction = clamp(strength, -1.0, 1.0)

func fire() -> void:
	if _fire_delay > 0.0: return
	var parent : Node = get_parent()
	if parent is Node2D:
		var lz : Node2D = LAZER_SCENE.instantiate()
		lz.position = position + Vector2(0.0, -3.0)
		parent.add_child(lz)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_pd_hit_area_hit() -> void:
	hit.emit()
