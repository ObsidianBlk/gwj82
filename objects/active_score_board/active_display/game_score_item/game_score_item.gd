extends Control


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DEFAULT_GAME_NAME : String = "Mystery Game"
const SCORE_PADDING : int = 6

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var game_name : String = "":			set=set_game_name
@export var score : int = 0:					set=set_score

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _lbl_game_name: Label = %LBL_GameName
@onready var _trect_banner: TextureRect = %TRECT_Banner
@onready var _lbl_score: Label = %LBL_Score


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_game_name(g : String) -> void:
	if game_name != g:
		game_name = g
		_UpdateLabels()

func set_score(s : int) -> void:
	if s < 0: s = 0
	if s != score:
		score = s
		_UpdateLabels()


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateLabels()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateLabels() -> void:
	if _lbl_game_name != null:
		if game_name.is_empty():
			_trect_banner.texture = null
			_lbl_game_name.text = DEFAULT_GAME_NAME
		else:
			_trect_banner.texture = GamePool.get_game_scoreboard_banner(game_name)
			if _trect_banner.texture == null:
				_lbl_game_name.text = game_name
			else:
				_lbl_game_name.text = ""
	
	if _lbl_score != null:
		_lbl_score.text = ("%d"%[score]).pad_zeros(SCORE_PADDING)
