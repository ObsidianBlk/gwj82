extends Node

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GROUP_ARCADE_MACHINE : StringName = &"ArcadeMachine"

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _player: CharacterBody3D = %Player


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	GamePool.load_roms()
	GamePool.game_scan()
	_PrepareArcade.call_deferred()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _player != null:
			_player.active = not _player.active

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

func _PrepareArcade() -> void:
	_DisconnectArcadeMachines()
	_PopulateGames()


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_exit_area_body_entered(body: Node3D) -> void:
	if _player != null and _player == body:
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
