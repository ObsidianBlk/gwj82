extends Node2D

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal scored()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const LAZER_SCENE : PackedScene = preload("res://games/planet_defense/objects/pd_invader/ps_inv_lazers/pd_inv_lazers.tscn")

const GAME_WIDTH : int = 320
const GAME_HEIGHT : int = 240

# ZOE = (Z)one (O)f (E)ngagement
const ZOE_WIDTH_RANGE : Vector2i = Vector2i(-128, 128)
const ZOE_HEIGHT_RANGE : Vector2i = Vector2i(20, -88)
const ZOE_MAX_POINTS : int = 3

const SIZE : Vector2i = Vector2i(16, 8)
const PPS : float = 60.0

const HOVER_DELAY : float = 0.5

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _points : Array[Vector2] = []
var _tween : Tween = null

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	position = _GetSpawnPoint()
	var zoes : int = randi_range(1, ZOE_MAX_POINTS)
	for _i in range(zoes):
		_points.append(_GetZOEPoint())
	_points.append(_GetExitPoint())
	_TweenTo.call_deferred()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetSpawnPoint() -> Vector2:
	var hw : int = int(floor(float(GAME_WIDTH) * 0.5))
	var hh : int = int(floor(float(GAME_HEIGHT) * 0.5))
	return Vector2(
		float(randi_range(-hw, hw)),
		-float(hh + SIZE.y)
	)

func _GetExitPoint() -> Vector2:
	var hw : int = int(floor(float(GAME_WIDTH) * 0.5))
	var hh : int = int(floor(float(GAME_HEIGHT) * 0.5))
	var y : float = float(randi_range(0.0, -(hh + SIZE.y)))
	if randf() < 0.5:
		return Vector2(-float(hw + SIZE.x), y)
	return Vector2(float(hw + SIZE.x), y)

func _GetZOEPoint() -> Vector2:
	var x : float = float(randi_range(ZOE_WIDTH_RANGE.x, ZOE_WIDTH_RANGE.y))
	var y : float = float(randi_range(ZOE_HEIGHT_RANGE.x, ZOE_HEIGHT_RANGE.y))
	return Vector2(x, y)

func _TweenTo() -> void:
	if _tween != null or _points.size() <= 0: return
	
	var dest : Vector2 = _points[0]
	var dist : float = position.distance_to(dest)
	var duration : float = dist / PPS
	
	_tween = create_tween()
	if _points.size() == 1:
		_tween.set_ease(Tween.EASE_IN)
	else:
		_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "position", dest, duration)
	_tween.finished.connect(_on_tween_finished)

func _Shoot() -> void:
	var parent : Node = get_parent()
	if parent is Node2D:
		var lz : Node2D = LAZER_SCENE.instantiate()
		lz.position = position + Vector2(0.0, -3.0)
		parent.add_child(lz)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_tween_finished() -> void:
	_tween = null
	if _points.size() > 0:
		_points.pop_front()
		if _points.size() <= 0:
			queue_free()
			return
		get_tree().create_timer(HOVER_DELAY).timeout.connect(_on_timeout, CONNECT_ONE_SHOT)

func _on_timeout() -> void:
	_Shoot()
	get_tree().create_timer(HOVER_DELAY).timeout.connect(_TweenTo, CONNECT_ONE_SHOT)

func _on_hit_area_hit() -> void:
	scored.emit()
