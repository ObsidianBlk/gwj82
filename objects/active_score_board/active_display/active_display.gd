extends Control
class_name ActiveDisplay


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GSI : PackedScene = preload("res://objects/active_score_board/active_display/game_score_item/game_score_item.tscn")

# ------------------------------------------------------------------------------
# Private Static Variables
# ------------------------------------------------------------------------------
static var _instance : ActiveDisplay

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _game_items : Dictionary[StringName, Control] = {}

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _score_list: HFlowContainer = %ScoreList

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	pass

func _enter_tree() -> void:
	if _instance == null:
		_instance = self

func _exit_tree() -> void:
	if _instance == self:
		_instance = null

# ------------------------------------------------------------------------------
# Public Static Methods
# ------------------------------------------------------------------------------
static func Get_Instance() -> ActiveDisplay:
	return _instance

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func set_game_score(game_name : StringName, score : int) -> void:
	if _score_list == null: return
	if not game_name in _game_items:
		var gsi : Control = GSI.instantiate()
		_game_items[game_name] = gsi
		gsi.game_name = game_name
		_score_list.add_child(gsi)
	_game_items[game_name].score = score

func get_games() -> Array[StringName]:
	return _game_items.keys()

func has_game(game_name : StringName) -> bool:
	return game_name in _game_items
