extends ArcadeGame


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SHIP_EXPLOSION : PackedScene = preload("res://games/azteroids/objects/explosion/explosion.tscn")

const ROID_DELAY : Vector2 = Vector2(0.5, 2.0)
const MIN_ROIDS : int = 10

const RESPAWN_DELAY : float = 3.0

const SCORE_ROID : int = 1
const SCORE_CRASH : int = -5

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var size : Vector2 = Vector2(320.0, 240.0)

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _ship : AztShip = null
var _ship_spawn_delay : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _game_container: Node2D = %GameContainer

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	return
	#activation_changed.connect(_on_activation_changed)
	#_on_activation_changed()

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
		if _ship_spawn_delay > 0.0:
			_ship_spawn_delay -= delta
		else:
			_SpawnShip()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _EventIs(event : InputEvent, actions : Array[StringName]) -> bool:
	for action : StringName in actions:
		if event.is_action(action): return true
	return false

func _CountRoids() -> int:
	if _game_container == null: return 0
	var count : int = 0
	for child in _game_container.get_children():
		if child is AztRoid:
			count += 1
	return count

func _SpawnRoid() -> void:
	if _game_container == null: return
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
	_game_container.add_child(roid)

func _SpawnShip() -> void:
	if _ship == null and _game_container != null:
		_ship = AztShip.new()
		_ship.fired.connect(_on_ship_fired)
		_ship.crashed.connect(_on_ship_crashed)
		_game_container.add_child(_ship)

func _RepositionShip() -> void:
	if _ship == null: return
	var hsize : Vector2 = size * 0.5
	var srect : Rect2 = _ship.get_rect()
	var shsize : Vector2 = srect.size * 0.5
	if srect.position.x + shsize.x < -hsize.x:
		_ship.global_position.x = hsize.x + shsize.x
	elif srect.position.x - shsize.x > hsize.x:
		_ship.global_position.x = -(hsize.x + shsize.x)
	
	if srect.position.y + shsize.y < -hsize.y:
		_ship.global_position.y = hsize.y + shsize.y
	elif srect.position.y - shsize.y > hsize.y:
		_ship.global_position.y = -(hsize.y + shsize.y)


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_activation_changed() -> void:
	if _game_container == null: return
	if active:
		_game_container.process_mode = Node.PROCESS_MODE_PAUSABLE
	else:
		_game_container.process_mode = Node.PROCESS_MODE_DISABLED


func _on_roid_broken(roid : AztRoid) -> void:
	roid.queue_free()
	update_score(SCORE_ROID)

func _on_ship_fired(bullet_position : Vector2, direction : Vector2) -> void:
	if _game_container == null: return
	var bullet : AztBullet = AztBullet.new()
	bullet.direction = direction
	bullet.position = bullet_position
	_game_container.add_child(bullet)

func _on_ship_crashed() -> void:
	if _ship == null or _game_container == null: return
	var exp : Node2D = SHIP_EXPLOSION.instantiate()
	exp.direction = _ship.velocity
	exp.position = _ship.global_position
	_game_container.add_child(exp)
	_ship.queue_free()
	_ship = null
	_ship_spawn_delay = RESPAWN_DELAY
	if active:
		update_score(SCORE_CRASH)

func _on_world_bounds_body_exited(body: Node2D) -> void:
	if body is AztRoid or body is AztBullet:
		body.queue_free()
	elif body is AztShip:
		_RepositionShip()
