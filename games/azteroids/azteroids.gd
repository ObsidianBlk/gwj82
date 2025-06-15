extends Node2D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ROID_DELAY : Vector2 = Vector2(0.5, 2.0)
const MIN_ROIDS : int = 10

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var active : bool = true
@export var size : Vector2 = Vector2(320.0, 240.0)

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _score : int = 0

var _ship : AztShip = null

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	
	if _ship != null:
		if _EventIs(event, [&"game_up", &"game_down"]):
			_ship.accel_strength(Input.get_axis("game_down", "game_up"))
		if _EventIs(event, [&"game_left", &"game_right"]):
			_ship.turn_strength(Input.get_axis("game_left", "game_right"))
		if event.is_action_pressed("game_act_a"):
			_ship.fire()

func _process(delta: float) -> void:
	if _CountRoids() < MIN_ROIDS:
		_SpawnRoid()
	if _ship == null:
		_SpawnShip()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _EventIs(event : InputEvent, actions : Array[StringName]) -> bool:
	for action : StringName in actions:
		if event.is_action(action): return true
	return false

func _CountRoids() -> int:
	var count : int = 0
	for child in get_children():
		if child is AztRoid:
			count += 1
	return count

func _SpawnShip() -> void:
	if _ship == null:
		_ship = AztShip.new()
		_ship.fired.connect(_on_ship_fired)
		add_child(_ship)

func _SpawnRoid() -> void:
	var hsize : Vector2 = size * 0.5
	var roid : AztRoid = AztRoid.new(true)
	roid.broken.connect(_on_roid_broken.bind(roid))
	
	var roid_pos : Vector2 = Vector2.ZERO
	var roid_targ : Vector2 = Vector2.ZERO
	if randf() < 0.5: # Top/Bottom
		var edge : float = randf()
		var dist : float = hsize.y + roid.radius
		roid_pos = Vector2(
			randf_range(-hsize.x, hsize.x),
			dist if edge < 0.5 else -dist
		)
		roid_targ = Vector2(
			randf_range(-hsize.x, hsize.x),
			-dist if edge < 0.5 else dist
		)
	else: # Left/Right
		var edge : float = randf()
		var dist : float = hsize.x + roid.radius
		roid_pos = Vector2(
			dist if edge < 0.5 else -dist,
			randf_range(-hsize.y, hsize.y)
		)
		roid_targ = Vector2(
			-dist if edge < 0.5 else dist,
			randf_range(-hsize.y, hsize.y)
		)
		
	roid.position = roid_pos
	roid.velocity = roid_pos.direction_to(roid_targ).normalized() * 20.0
	add_child(roid)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_roid_broken(roid : AztRoid) -> void:
	roid.queue_free()
	_score += 1

func _on_ship_fired(bullet_position : Vector2, direction : Vector2) -> void:
	var bullet : AztBullet = AztBullet.new()
	bullet.direction = direction
	bullet.position = bullet_position
	add_child(bullet)

func _on_world_bounds_body_exited(body: Node2D) -> void:
	if body is AztRoid or body is AztBullet:
		body.queue_free()
	# Handle repositioning player ship
