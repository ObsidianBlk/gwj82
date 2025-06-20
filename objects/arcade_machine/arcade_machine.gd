extends Node3D
class_name ArcadeMachine


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal focused(active : bool)
signal score_changed(score : int)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GROUP_SCENE_CAMERA : StringName = &"SceneCamera"
const GROUP_PLAYER_CAMERA : StringName = &"PlayerCamera"

const MUSIC_FADE_TIME : float = 0.5

const AUDIO_STATIC_RANGE : float = 80.0
const AUDIO_STATIC_MIN : float = -80.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var game_name : StringName = &"":	set=set_game_name

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _game : ArcadeGame = null
var _game_camera_target_group : StringName = &""

var _silence_mode : bool = false
var _volume_music : float = 1.0
var _volume_ambient : float = 1.0
var _volume_sfx : float = 1.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _game_viewport: SubViewport = %GameViewport
@onready var _display: CanvasLayer = %Display
@onready var _camera_transform: Marker3D = %CameraTransform

@onready var _asp_music: AudioStreamPlayer3D = %ASP_Music
@onready var _asp_ambient: AudioStreamPlayer3D = %ASP_Ambient
@onready var _asp_sfx_01: AudioStreamPlayer3D = %ASP_SFX_01
@onready var _asp_sfx_02: AudioStreamPlayer3D = %ASP_SFX_02
@onready var _asp_static: AudioStreamPlayer3D = %ASP_Static

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

func _DisplayVisible(vis : bool) -> void:
	if _display == null: return
	var color : Color = _display.off_color
	if vis:
		color.a = 1.0
	else:
		color.a = 0.0
	_display.off_color = color

func _ClearAudio(asp : AudioStreamPlayer3D) -> void:
	if asp == null: return
	if asp.stream != null:
		asp.stop()
		asp.stream = null

func _ClearGameAudio() -> void:
	_ClearAudio(_asp_music)
	_ClearAudio(_asp_ambient)
	_ClearAudio(_asp_sfx_01)
	_ClearAudio(_asp_sfx_02)


func _UnloadGame() -> void:
	if _game_viewport == null or _game == null: return
	_SetCamTranGroup(&"")
	if _game.score_changed.is_connected(_on_game_score_changed):
		_game.score_changed.disconnect(_on_game_score_changed)
	if _game.play_music.is_connected(_UpdateMusic):
		_game.play_music.disconnect(_UpdateMusic)
	if _game.play_ambient.is_connected(_UpdateAmbient):
		_game.play_ambient.disconnect(_UpdateAmbient)
	if _game.play_sfx.is_connected(_UpdateSFX):
		_game.play_sfx.disconnect(_UpdateSFX)
	_game_viewport.remove_child(_game)
	_game = null
	_ClearGameAudio()
	_DisplayVisible(true)
	update_display(0)
	_on_game_score_changed.call_deferred(0)

func _LoadGame() -> void:
	if _game_viewport == null: return
	_UnloadGame()
	if GamePool.has_game(game_name):
		var tag : GameTag = GamePool.get_game(game_name)
		_game = tag.instance()
		if _game != null:
			_SetCamTranGroup(&"arcade_machine_%s"%[game_name])
			if not _game.score_changed.is_connected(_on_game_score_changed):
				_game.score_changed.connect(_on_game_score_changed)
			if not _game.play_music.is_connected(_UpdateMusic):
				_game.play_music.connect(_UpdateMusic)
			if not _game.play_ambient.is_connected(_UpdateAmbient):
				_game.play_ambient.connect(_UpdateAmbient)
			if not _game.play_sfx.is_connected(_UpdateSFX):
				_game.play_sfx.connect(_UpdateSFX)
			_game_viewport.add_child(_game)
			_game.reset_score()
			_game.prepare()
			_game.active = false
			_DisplayVisible(false)
			_on_game_score_changed.call_deferred(get_score())
		else:
			printerr("Failed to obtain game object for \"", game_name, "\".")
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
		if _game != null:
			_game.active = false
		if not cam.flow_completed.is_connected(_on_camera_flow_completed):
			cam.flow_completed.connect(_on_camera_flow_completed.bind(cam), CONNECT_ONE_SHOT)
		cam.flow_to(GROUP_PLAYER_CAMERA)
		focused.emit(false)

func _TweenAudioTo(asp : AudioStreamPlayer3D, volume : float, duration : float) -> void:
	if asp == null: return
	var tween : Tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(asp, "volume_linear", volume, duration)
	await tween.finished
	if is_equal_approx(volume, 0.0) and not _silence_mode:
		asp.stop()
		asp.stream = null

func _UpdateMusic(stream : AudioStream, volume : float = 1.0) -> void:
	if _asp_music == null: return
	if stream != _asp_music.stream:
		if _asp_music.playing:
			var duration : float = _asp_music.volume_linear * MUSIC_FADE_TIME
			await _TweenAudioTo(_asp_music, 0.0, duration)
		if stream != null:
			volume = clampf(volume, 0.0, 1.0)
			_volume_music = volume
			if not _silence_mode:
				var duration : float = volume * MUSIC_FADE_TIME
				_asp_music.stream = stream
				_asp_music.volume_linear = 0.0
				_asp_music.play()
				_TweenAudioTo(_asp_music, volume, duration)

func _UpdateAmbient(stream : AudioStream, volume : float = 1.0) -> void:
	if _asp_ambient == null: return
	if stream != _asp_ambient.stream:
		if _asp_ambient.playing:
			var duration : float = _asp_ambient.volume_linear * MUSIC_FADE_TIME
			await _TweenAudioTo(_asp_ambient, 0.0, duration)
		if stream != null:
			volume = clampf(volume, 0.0, 1.0)
			_volume_ambient = volume
			if not _silence_mode:
				var duration : float = volume * MUSIC_FADE_TIME
				_asp_ambient.stream = stream
				_asp_ambient.volume_linear = 0.0
				_asp_ambient.play()
				_TweenAudioTo(_asp_ambient, volume, duration)
			

func _AudioStreamProgress(asp : AudioStreamPlayer3D) -> float:
	if asp.stream == null or not asp.playing: return 1.0
	var pos : float = asp.get_playback_position()
	return pos / asp.stream.get_length()

func _UpdateSFX(stream : AudioStream) -> void:
	if _asp_sfx_01 == null or _asp_sfx_02 == null: return
	
	if stream == null:
		_asp_sfx_01.stop()
		_asp_sfx_01.stream = null
		_asp_sfx_02.stop()
		_asp_sfx_02.stream = null
		return
	
	if _silence_mode: return
	
	if _asp_sfx_01.stream == stream:
		if _AudioStreamProgress(_asp_sfx_01) > 0.5:
			_asp_sfx_01.play(0.0)
		return
	elif _asp_sfx_02.stream == stream:
		if _AudioStreamProgress(_asp_sfx_02) > 0.5:
			_asp_sfx_02.play(0.0)
		return
	
	var asp : AudioStreamPlayer3D = _asp_sfx_01
	if _AudioStreamProgress(_asp_sfx_02) > _AudioStreamProgress(_asp_sfx_01):
		asp = _asp_sfx_02
	asp.stop()
	asp.stream = stream
	asp.play()

func silence_mode(enable : bool) -> void:
	if enable != _silence_mode:
		_silence_mode = enable
		if _silence_mode:
			_TweenAudioTo(_asp_music, 0.0, 0.25)
			_TweenAudioTo(_asp_ambient, 0.0, 0.25)
		else:
			_TweenAudioTo(_asp_music, _volume_music, 0.25)
			_TweenAudioTo(_asp_ambient, _volume_ambient, 0.25)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func has_game() -> bool:
	return _game != null

func is_focused() -> bool:
	return Input.mouse_mode == Input.MOUSE_MODE_HIDDEN and not _silence_mode

func get_score() -> int:
	if _game == null: return 0
	return _game.get_score()

func update_score(amount : int) -> void:
	if _game != null:
		_game.update_score(amount)

func update_display(intensity : int) -> void:
	if _display == null: return
	intensity = clampi(intensity, 0, 3)
	match intensity:
		0:
			_display.max_static = 0.0
			_display.scary_screen = -1
		1:
			_display.max_static = 0.5
			_display.scary_screen = -1
		2:
			_display.max_static = 0.8
			_display.min_static = 0.3
			_display.scary_screen = -1
		3:
			_display.max_static = 1.0
			_display.min_static = 0.35
			_display.scary_screen = randi_range(0, 1)

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_game_score_changed(score : int) -> void:
	score_changed.emit(score)

func _on_component_interactable_focused() -> void:
	pass

func _on_component_interactable_unfocused() -> void:
	pass

func _on_component_interactable_interacted(payload: Dictionary) -> void:
	var cam : ChaseCamera3D = _GetSceneCamera()
	if cam != null:
		if not cam.flow_completed.is_connected(_on_camera_flow_completed):
			cam.flow_completed.connect(_on_camera_flow_completed.bind(cam), CONNECT_ONE_SHOT)
		cam.flow_to(_game_camera_target_group)
		focused.emit(true)
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _on_camera_flow_completed(camera : ChaseCamera3D) -> void:
	if camera.target_group == _game_camera_target_group:
		_game.active = true
	elif camera.target_group == GROUP_PLAYER_CAMERA:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_display_static_changed(level: float) -> void:
	if _asp_static != null:
		var volume_range : float = AUDIO_STATIC_RANGE * level
		_asp_static.volume_db = AUDIO_STATIC_MIN + volume_range
