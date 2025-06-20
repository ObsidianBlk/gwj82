@tool
extends Node3D


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal letter_changed(letter : String)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const CHARACTERS : Array[String] = [
	"A","B","C","D","E","F","G","H","I","J",
	"K","L","M","N","O","P","Q","R","S","T",
	"U","V","W","X","Y","Z",
	"0","1","2","3","4","5","6","7","8","9"
]

const FOCUSED_COLOR : Color = Color.WHITE
const UNFOCUSED_COLOR : Color = Color.BLACK

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export_range(0, 36) var character : int = 0:		set=set_character
@export var char : String:							set=set_char, get=get_char

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _lbl_letter: Label = %LBL_Letter
@onready var _highlight: ColorRect = %Highlight


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_character(c : int) -> void:
	character = wrapi(c, 0, 36)
	_UpdateLabel()
	letter_changed.emit(CHARACTERS[character])

func set_char(c : String) -> void:
	if c.length() != 1: return
	c = c.to_upper()
	var idx : int = CHARACTERS.find(c)
	if idx >= 0:
		character = idx

func get_char() -> String:
	return CHARACTERS[character]

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateLabel()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateLabel() -> void:
	if _lbl_letter == null: return
	_lbl_letter.text = CHARACTERS[character]

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_component_interactable_interacted(payload: Dictionary) -> void:
	character += 1

func _on_component_interactable_focused() -> void:
	if _highlight != null:
		_highlight.color = FOCUSED_COLOR

func _on_component_interactable_unfocused() -> void:
	if _highlight != null:
		_highlight.color = UNFOCUSED_COLOR
