extends Control
class_name ActiveDisplay


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GSI : PackedScene = preload("res://objects/active_score_board/active_display/game_score_item/game_score_item.tscn")

const DISPLAY_SCOREBOARD : StringName = &"ScoreBoard"
const DISPLAY_FINAL_GRADE : StringName = &"FinalGrade"

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
@onready var _scoreboard: MarginContainer = %Scoreboard
@onready var _final_grade: MarginContainer = %FinalGrade

@onready var _score_list: HFlowContainer = %ScoreList
@onready var _lbl_grade: Label = %LBL_Grade

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	display_screen(DISPLAY_SCOREBOARD)

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

func set_grade(grade : String) -> void:
	_lbl_grade.text = grade

func display_screen(screen_name : StringName) -> void:
	_scoreboard.visible = (screen_name == DISPLAY_SCOREBOARD)
	_final_grade.visible = (screen_name == DISPLAY_FINAL_GRADE)
