extends ArcadeGame



# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const OBSTACLE_SCENE : PackedScene = preload("res://games/flippy/objects/obstacle/obstacle.tscn")

const GAME_WIDTH : float = 320.0

const BIRD_FELL_AMOUNT : int = 10
const BIRD_CRASHED_AMOUNT : int = 5
const BIRD_SCORED_AMOUNT : int = 1

const BIRD_RESET_HEIGHT : float = -132.0
const BIRD_RESET_X : float = -120.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var spawn_delay : float = 2.0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _resetting : bool = false
var _delay : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _bird: FlippyBird = %Bird
@onready var _ocontainer: Node2D = %OContainer

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if _bird == null or not active or _resetting: return
	
	if event.is_action_pressed("game_act_a"):
		_bird.flap()

func _process(delta: float) -> void:
	if _bird != null:
		_bird.ai_enabled = not active
		
	if _delay > 0.0:
		_delay -= delta
	else:
		_delay = spawn_delay
		_SpawnObstacle()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _ClearObstacles() -> void:
	if _ocontainer == null: return
	for child : Node in _ocontainer.get_children():
		if child is Node2D:
			_ocontainer.remove_child(child)
			child.queue_free()

func _SpawnObstacle() -> void:
	if _ocontainer == null: return
	var o : Node2D = OBSTACLE_SCENE.instantiate()
	o.scored.connect(_on_bird_scored)
	o.position.x = ((GAME_WIDTH * 0.5) + 16.0)
	_ocontainer.add_child(o)

func _Reset() -> void:
	_resetting = true
	_ClearObstacles()
	_bird.velocity = Vector2.ZERO
	_bird.position = Vector2(BIRD_RESET_X, BIRD_RESET_HEIGHT)
	_resetting = false

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_bird_scored() -> void:
	if active:
		update_score(BIRD_SCORED_AMOUNT)

func _on_bird_crashed() -> void:
	if active:
		update_score(-BIRD_CRASHED_AMOUNT)
	_Reset()

func _on_game_region_body_exited(body: Node2D) -> void:
	if body is FlippyBird:
		if active and not _resetting:
			update_score(-BIRD_FELL_AMOUNT)
		_Reset()
