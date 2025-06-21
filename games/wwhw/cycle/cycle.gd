extends Node2D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal crashed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const EXPLOSION_SCENE : PackedScene = preload("res://games/wwhw/objects/explosion/explosion.tscn")

const BOUNDS : Vector2 = Vector2(-120, 120)
const LANES : Array[float] = [-100.0, 0.0, 100.0]

const RIDER_LEFT : int = 1
const RIDER_CENTER : int = 0
const RIDER_RIGHT : int = 2

const SPEED : float = 260.0

const BOUNCE_DELAY : float = 0.4

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _lane_idx : int = 1
var _tween : Tween = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _rider: Sprite2D = %Rider


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateRider(frame : int) -> void:
	if _rider == null: return
	var frame_count : int = _rider.hframes * _rider.vframes
	if frame >= 0 and frame < frame_count:
		_rider.frame = frame

func _TweenBounce(edge : float) -> void:
	if _tween != null: return

	var from : Vector2 = position
	var to : Vector2 = Vector2(edge, position.y)
	var dist = from.distance_to(to)
	var duration : float = dist / SPEED
	
	var rider_in_frame : int = RIDER_LEFT
	var rider_out_frame : int = RIDER_RIGHT
	if from.x < to.x:
		rider_in_frame = RIDER_RIGHT
		rider_out_frame = RIDER_LEFT
	
	_UpdateRider(rider_in_frame)
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SINE)
	
	_tween.set_parallel(false)
	_tween.tween_property(self, "position", to, duration)
	_tween.tween_callback(_UpdateRider.bind(RIDER_CENTER))
	_tween.tween_interval(BOUNCE_DELAY)
	_tween.tween_callback(_UpdateRider.bind(rider_out_frame))
	_tween.tween_property(self, "position", from, duration)
	_tween.tween_callback(_UpdateRider.bind(RIDER_CENTER))
	_tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)


func _TweenTo(dst : float) -> void:
	if _tween != null: return
	
	var to : Vector2 = Vector2(dst, position.y)
	var dist = position.distance_to(to)
	var duration : float = dist / SPEED
	
	if position.x < dst:
		_UpdateRider(RIDER_RIGHT)
	else:
		_UpdateRider(RIDER_LEFT)
	
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SINE)
	
	_tween.set_parallel(false)
	_tween.tween_property(self, "position", to, duration)
	_tween.tween_callback(_UpdateRider.bind(RIDER_CENTER))
	_tween.finished.connect(_on_tween_finished, CONNECT_ONE_SHOT)

func _Die() -> void:
	crashed.emit()
	var parent : Node = get_parent()
	if parent is Node2D:
		var exp : Node2D = EXPLOSION_SCENE.instantiate()
		exp.position = position
		parent.add_child(exp)
	queue_free()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func move_left() -> void:
	if _tween != null: return
	_lane_idx -= 1
	if _lane_idx < 0:
		_lane_idx = 0
		_TweenBounce(BOUNDS.x)
	else:
		_TweenTo(LANES[_lane_idx])

func move_right() -> void:
	if _tween != null: return
	_lane_idx += 1
	if _lane_idx >= LANES.size():
		_lane_idx = LANES.size() - 1
		_TweenBounce(BOUNDS.y)
	else:
		_TweenTo(LANES[_lane_idx])

func set_lane(lane_idx : int) -> void:
	if lane_idx >= 0 and lane_idx < LANES.size():
		_lane_idx = lane_idx
		position.x = LANES[_lane_idx]

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_tween_finished() -> void:
	_tween = null

func _on_hit_area_area_entered(area: Area2D) -> void:
	_Die.call_deferred()
