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
	_PopulateGames.call_deferred()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _player != null:
			_player.active = not _player.active

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
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
		games.remove_at(gidx)
		
		if nodes.size() <= 0:
			break

func _on_exit_area_body_entered(body: Node3D) -> void:
	if _player != null and _player == body:
		get_tree().quit()
