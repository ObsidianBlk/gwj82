extends Node3D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal score_changed(score : int)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GROUP_SCENE_CAMERA : StringName = &"SceneCamera"
const GROUP_PLAYER_CAMERA : StringName = &"PlayerCamera"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var game_name : StringName = &"":	set=set_game_name

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _game : ArcadeGame = null
var _game_camera_target_group : StringName = &""

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _game_viewport: SubViewport = %GameViewport
@onready var _camera_transform: Marker3D = %CameraTransform

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_game_name(g : StringName) -> void:
	if game_name != g:
		game_name = g
		_LoadGame()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	if _game == null and not game_name.is_empty():
		_LoadGame.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if _game == null or _game_viewport == null: return
	
	if _game.active:
		if event.is_action_pressed("game_escape"):
			_ReleaseFromMachine()
		else:
			_game_viewport.push_input(event, true)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SetCamTranGroup(grp_name : StringName) -> void:
	if _camera_transform == null: return
	if not _game_camera_target_group.is_empty() and _camera_transform.is_in_group(_game_camera_target_group):
		_camera_transform.remove_from_group(_game_camera_target_group)
		_game_camera_target_group = &""
	
	if not grp_name.is_empty():
		_game_camera_target_group = grp_name
		_camera_transform.add_to_group(grp_name)

func _LoadGame() -> void:
	if _game_viewport == null: return
	if GamePool.has_game(game_name):
		if _game != null:
			_SetCamTranGroup(&"")
			if _game.score_changed.is_connected(_on_game_score_changed):
				_game.score_changed.disconnect(_on_game_score_changed)
			_game_viewport.remove_child(_game)
			_game = null
		var tag : GameTag = GamePool.get_game(game_name)
		_game = tag.instance()
		if _game != null:
			_SetCamTranGroup(&"arcade_machine_%s"%[game_name])
			if not _game.score_changed.is_connected(_on_game_score_changed):
				_game.score_changed.connect(_on_game_score_changed)
			_game_viewport.add_child(_game)
			_game.active = false
	elif not game_name.is_empty():
		_LoadGame.call_deferred()

func _GetSceneCamera() -> ChaseCamera3D:
	var nodes : Array[Node] = get_tree().get_nodes_in_group(GROUP_SCENE_CAMERA)
	for node : Node in nodes:
		if node is ChaseCamera3D:
			return node
	return null

func _ReleaseFromMachine() -> void:
	var cam : ChaseCamera3D = _GetSceneCamera()
	if cam != null:
		_game.active = false
		if not cam.flow_completed.is_connected(_on_camera_flow_completed):
			cam.flow_completed.connect(_on_camera_flow_completed.bind(cam), CONNECT_ONE_SHOT)
		cam.flow_to(GROUP_PLAYER_CAMERA)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func get_score() -> int:
	if _game == null: return 0
	return _game.get_score()

func update_score(amount : int) -> void:
	if _game != null:
		_game.update_score(amount)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_game_score_changed(score : int) -> void:
	score_changed.emit(score)

func _on_component_interactable_focused() -> void:
	print("Play ", game_name)

func _on_component_interactable_unfocused() -> void:
	print("Ignored ", game_name)

func _on_component_interactable_interacted(payload: Dictionary) -> void:
	var cam : ChaseCamera3D = _GetSceneCamera()
	if cam != null:
		if not cam.flow_completed.is_connected(_on_camera_flow_completed):
			cam.flow_completed.connect(_on_camera_flow_completed.bind(cam), CONNECT_ONE_SHOT)
		cam.flow_to(_game_camera_target_group)
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _on_camera_flow_completed(camera : ChaseCamera3D) -> void:
	if camera.target_group == _game_camera_target_group:
		_game.active = true
	elif camera.target_group == GROUP_PLAYER_CAMERA:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
