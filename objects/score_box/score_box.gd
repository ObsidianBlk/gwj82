@tool
extends HBoxContainer

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var score : int = 0:						set=set_score
@export var score_digits: int = 1:					set=set_score_digits
@export var color_title : Color = Color.WHITE:		set=set_color_title
@export var color_value : Color = Color.WHITE:		set=set_color_value


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _lbl_title: Label = %LBL_Title
@onready var _lbl_value: Label = %LBL_Value


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_score(s : int) -> void:
	if s != score:
		score = s
		_UpdateValueText()

func set_score_digits(d : int) -> void:
	if d >= 1 and d != score_digits:
		score_digits = d
		_UpdateValueText()

func set_color_title(c : Color) -> void:
	if color_title != c:
		color_title = c
		_UpdateColors()

func set_color_value(c : Color) -> void:
	if color_value != c:
		color_value = c
		_UpdateColors()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateValueText()
	_UpdateColors()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateValueText() -> void:
	if _lbl_value != null:
		_lbl_value.text = ("%d"%[score]).pad_zeros(score_digits)

func _UpdateColors() -> void:
	if _lbl_title != null:
		_lbl_title.modulate = color_title
	if _lbl_value != null:
		_lbl_value.modulate = color_value
