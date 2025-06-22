extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
# NOTE: This is not a good place to put these, but this is also a jam, sooooo...
const SCREEN_JAM : int = 0
const SCREEN_JAM2 : int = 3
const SCREEN_INFO : int = 1
const SCREEN_INFO2 : int = 2

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _info_board_display: CanvasLayer = %InfoBoardDisplay


# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_button_jam_clicked() -> void:
	var idx : int = _info_board_display.get_screen_index()
	if idx == SCREEN_JAM:
		_info_board_display.switch_to(SCREEN_JAM2)
	else:
		_info_board_display.switch_to(SCREEN_JAM)

func _on_button_info_clicked() -> void:
	var idx : int = _info_board_display.get_screen_index()
	if idx == SCREEN_INFO:
		_info_board_display.switch_to(SCREEN_INFO2)
	else:
		_info_board_display.switch_to(SCREEN_INFO)

func _on_button_next_screen_clicked() -> void:
	_info_board_display.switch_next()
