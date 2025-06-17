extends ArcadeGame


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const INVADER_SCENE : PackedScene = preload("res://games/planet_defense/objects/pd_invader/pd_invader.tscn")
const CANNON_SCENE : PackedScene = preload("res://games/planet_defense/objects/pd_cannon/pd_cannon.tscn")

const MAX_INVADERS : int = 6
const SCORE_TO_INVADER_INCREASE : int = 10

const INV_SPAWN_DELAY : float = 0.5
const INV_HIT_SCORE : int = 1

const CANNON_HIT_SCORE : int = -5
const CANNON_SPAWN_DELAY : float = 1.0

const GAME_WIDTH : Vector2 = Vector2(-160, 160)
const GAME_HEIGHT : Vector2 = Vector2(-120, 120)

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _inv_spawn_delay : float = INV_SPAWN_DELAY
var _inv_allowed : int = 3
var _inv_score : int = 0 # Mostly tracking how many invaders were hit

var _cannon : WeakRef = weakref(null)

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _inv_container: Node2D = %InvContainer
@onready var _cannon_container: Node2D = %CannonContainer


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_Reset()
	#_inv_container.add_child(INVADER_SCENE.instantiate())

func _unhandled_input(event: InputEvent) -> void:
	if not active: return
	var cannon : Node2D = _cannon.get_ref()
	if cannon == null: return
	
	if event_one_of(event, [&"game_left", &"game_right"]):
		cannon.move(Input.get_axis(&"game_left", &"game_right"))
	if event.is_action_pressed("game_act_a"):
		cannon.fire()

func _process(delta: float) -> void:
	if _inv_spawn_delay <= 0.0:
		_inv_spawn_delay = INV_SPAWN_DELAY
		_SpawnInvader()
	else:
		_inv_spawn_delay -= delta

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _GetInvaderCount() -> int:
	var count : int = 0
	if _inv_container != null:
		for child : Node in _inv_container.get_children():
			if child.has_method(&"_Shoot"):
				count += 1
	return count

func _SpawnInvader() -> void:
	if _inv_container == null: return
	if _GetInvaderCount() < _inv_allowed:
		var invader : Node2D = INVADER_SCENE.instantiate()
		invader.scored.connect(_on_scored)
		_inv_container.add_child(invader)

func _GetCannon(spawn_if_not_exist : bool = false) -> Node2D:
	var cannon : Node2D = _cannon.get_ref()
	if cannon == null and spawn_if_not_exist and _cannon_container != null:
		cannon = CANNON_SCENE.instantiate()
		cannon.hit.connect(_on_cannon_hit)
		cannon.position = Vector2(0.0, GAME_HEIGHT.y - 32)
		_cannon = weakref(cannon)
		_cannon_container.add_child(cannon)
	return cannon

func _Reset() -> void:
	_inv_allowed = 1
	_inv_score = 0
	_GetCannon(true)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_scored() -> void:
	_inv_score += 1
	if active:
		update_score(INV_HIT_SCORE)
	if _inv_score % SCORE_TO_INVADER_INCREASE == 0:
		_inv_allowed += 1

func _on_cannon_hit() -> void:
	if active:
		update_score(CANNON_HIT_SCORE)
	get_tree().create_timer(CANNON_SPAWN_DELAY).timeout.connect(_Reset, CONNECT_ONE_SHOT)
	
