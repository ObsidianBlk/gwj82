extends Node

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GROUP_ARCADE_MACHINE : StringName = &"ArcadeMachine"

const ACTIVE_GAME_SPM : float = 2.0
const NORMAL_CLOCK_SPM : float = 60.0

const LONG_PRESS_DELAY : float = 3.0

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_range(0, 24) var start_hour : int = 0
@export_range(0, 59) var start_minute : int = 0
@export_range(0, 24) var end_hour : int = 6
@export_range(0, 59) var end_minute : int = 0


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _challenge_running : bool = false
var _long_press : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _player: CharacterBody3D = %Player
@onready var _asp_end_challenge_siren: AudioStreamPlayer = %ASP_EndChallengeSiren
@onready var _asp_start_challenge_sound: AudioStreamPlayer = %ASP_StartChallengeSound


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Relay.challenged.connect(_on_challenged)
	Clock24.clock_ticked.connect(_on_clock_ticked)
	if Settings.load() != OK:
		Settings.request_reset()
		Settings.save()
	
	GamePool.load_roms()
	GamePool.game_scan()
	_PrepareArcade.call_deferred()
	Clock24.set_seconds_per_minute(NORMAL_CLOCK_SPM)
	Clock24.reset_to_sys_clock()
	Clock24.enable(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_long_press = LONG_PRESS_DELAY
	elif event.is_action_released("ui_cancel"):
		_long_press = 0.0
		#if _player != null:
		#	_player.active = not _player.active

func _process(delta: float) -> void:
	if _long_press > 0.0:
		_long_press -= delta
		if _long_press <= 0.0:
			get_tree().quit()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _DisconnectArcadeMachines() -> void:
	var nodes : Array[Node] = get_tree().get_nodes_in_group(GROUP_ARCADE_MACHINE)
	for am : Node in nodes:
		if am is ArcadeMachine and not am.game_name.is_empty():
			if am.score_changed.is_connected(_on_arcade_machine_score_changed.bind(am.game_name)):
				am.score_changed.disconnect(_on_arcade_machine_score_changed.bind(am.game_name))
			if am.focused.is_connected(_on_arcade_machine_focused.bind(am.game_name)):
				am.focused.disconnect(_on_arcade_machine_focused.bind(am.game_name))
			am.game_name = &""

func _PopulateGames() -> void:
	var games : Array[StringName] = GamePool.get_games_list()
	if games.size() <= 0: return
	
	var nodes : Array[Node] = get_tree().get_nodes_in_group(GROUP_ARCADE_MACHINE).filter(
		func (item : Node):
			return item is ArcadeMachine
	)
	if nodes.size() <= 0: return
	
	for _i : int in range(games.size()):
		var gidx : int = randi_range(0, games.size() - 1)
		var nidx : int = randi_range(0, nodes.size() - 1)
		
		var am : ArcadeMachine = nodes[nidx]
		nodes.remove_at(nidx)
		
		am.game_name = games[gidx]
		if not am.score_changed.is_connected(_on_arcade_machine_score_changed.bind(games[gidx])):
			am.score_changed.connect(_on_arcade_machine_score_changed.bind(games[gidx]))
		if not am.focused.is_connected(_on_arcade_machine_focused.bind(games[gidx])):
			am.focused.connect(_on_arcade_machine_focused.bind(games[gidx]))
		games.remove_at(gidx)
		
		if nodes.size() <= 0:
			break

func _PrepareArcade(start_challenge : bool = false) -> void:
	_DisconnectArcadeMachines()
	_PopulateGames()
	_UpdateAudioFocus(false)
	var ad : ActiveDisplay = ActiveDisplay.Get_Instance()
	if ad != null:
		ad.display_screen(ActiveDisplay.DISPLAY_SCOREBOARD)
	
	if start_challenge:
		_challenge_running = true
		Clock24.set_seconds_per_minute(ACTIVE_GAME_SPM)
		Clock24.reset(start_hour, start_minute)
		_asp_start_challenge_sound.play()
		var app : Apparition = Apparition.Get_Instance()
		if app != null:
			app.set_action(Apparition.ACTION_APPARATE)
			app.enabled = true


func _TweenAudioBusVolume(bus_name : StringName, target_volume : float, duration : float) -> void:
	var idx : int = AudioServer.get_bus_index(bus_name)
	if idx < 0: return
	var cvol : float = AudioServer.get_bus_volume_linear(idx)
	if is_equal_approx(cvol, target_volume): return
	
	var tween : Tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.tween_method(
		(func (v : float): AudioServer.set_bus_volume_linear(idx, v)),
		cvol, target_volume,
		duration
	)

func _UpdateAudioFocus(machine_focus : bool) -> void:
	if machine_focus:
		_TweenAudioBusVolume(&"MachineMusic", 1.0, 0.25)
		_TweenAudioBusVolume(&"MachineSFX", 1.0, 0.25)
		_TweenAudioBusVolume(&"ArcadeMusic", 0.25, 0.25)
		_TweenAudioBusVolume(&"ArcadeSFX", 0.25, 0.25)
	else:
		_TweenAudioBusVolume(&"MachineMusic", 0.25, 0.25)
		_TweenAudioBusVolume(&"MachineSFX", 0.25, 0.25)
		_TweenAudioBusVolume(&"ArcadeMusic", 1.0, 0.25)
		_TweenAudioBusVolume(&"ArcadeSFX", 1.0, 0.25)

func _GetGradeFromScore(score : int) -> String:
	if score >= 400:
		return "S"
	elif score >= 200:
		return "A"
	elif score >= 140:
		return "B"
	elif score >= 80:
		return "C"
	elif score >= 40:
		return "D"
	return "F"

func _CalculateFinalScore() -> void:
	var count_zero_score : int = 0
	var count_scored_games : int = 0
	var score_total : int = 0
	
	var nodes : Array[Node] = get_tree().get_nodes_in_group(GROUP_ARCADE_MACHINE)
	for node : Node in nodes:
		if node is ArcadeMachine:
			var am : ArcadeMachine = node
			if am.has_game():
				var score : int = am.get_score()
				score_total += score
				if score <= 0:
					count_zero_score += 1
				else:
					count_scored_games += 1
	
	for _i : int in range(count_zero_score):
		score_total = score_total / 2
		
	var ad : ActiveDisplay = ActiveDisplay.Get_Instance()
	if ad != null:
		ad.set_grade(_GetGradeFromScore(score_total))

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_challenged(initials : String) -> void:
	if _challenge_running == false:
		_PrepareArcade(true)

func _on_clock_ticked(hour : int, minute : int) -> void:
	if _challenge_running and hour == end_hour and minute == end_minute:
		_challenge_running = false
		if _asp_end_challenge_siren != null:
			_asp_end_challenge_siren.play()
		var app : Apparition = Apparition.Get_Instance()
		if app != null:
			app.enabled = false
		Clock24.set_seconds_per_minute(NORMAL_CLOCK_SPM)
		Clock24.reset_to_sys_clock()
		_CalculateFinalScore()
		var ad : ActiveDisplay = ActiveDisplay.Get_Instance()
		if ad != null:
			ad.display_screen(ActiveDisplay.DISPLAY_FINAL_GRADE)
		Relay.announce_challenge_ended()

func _on_exit_area_body_entered(body: Node3D) -> void:
	if _player != null and _player == body:
		if Settings.is_dirty():
			Settings.save()
		get_tree().quit()

func _on_arcade_machine_score_changed(score : int, game_name : StringName) -> void:
	var active_display : ActiveDisplay = ActiveDisplay.Get_Instance()
	if active_display != null:
		active_display.set_game_score(game_name, score)

func _on_arcade_machine_focused(active : bool, game_name : StringName) -> void:
	var nodes : Array[Node] = get_tree().get_nodes_in_group(GROUP_ARCADE_MACHINE)
	for node : Node in nodes:
		if node is ArcadeMachine and node.game_name != game_name:
			node.silence_mode(active)
	_UpdateAudioFocus(active)
