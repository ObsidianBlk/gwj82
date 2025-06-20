extends Node3D

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const DELIMITER_TOGGLE_TIME : float = 1.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _delimiter : bool = true
var _delimiter_time : float = DELIMITER_TOGGLE_TIME

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _lbl_time: Label = %LBL_Time


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Clock24.clock_ticked.connect(_on_clock_ticked)
	_on_clock_ticked(Clock24.get_hour_24(), Clock24.get_minute())

func _process(delta: float) -> void:
	if _delimiter_time > 0.0:
		_delimiter_time -= delta
	else:
		_delimiter_time = DELIMITER_TOGGLE_TIME
		_delimiter = not _delimiter
		_on_clock_ticked(Clock24.get_hour_24(), Clock24.get_minute())

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_clock_ticked(h : int, m : int) -> void:
	if _lbl_time == null: return
	var hr : String = ("%d"%[h]).pad_zeros(2)
	var mn : String = ("%d"%[m]).pad_zeros(2)
	_lbl_time.text = "%s%s%s"%[hr, ":" if _delimiter else " ", mn]
