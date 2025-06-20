extends Node
class_name ArcadeGame


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal activation_changed()
signal score_changed(score : int)
signal play_music(stream : AudioStream)
signal play_ambient(stream : AudioStream)
signal play_sfx(stream : AudioStream)


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var active : bool = true:	set=set_active

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _score : int = 0

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_active(a : bool) -> void:
	if active != a:
		active = a
		activation_changed.emit()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func event_one_of(event : InputEvent, actions : Array[StringName]) -> bool:
	for action : StringName in actions:
		if event.is_action(action): return true
	return false

func prepare() -> void:
	pass # To be updated by games

func get_score() -> int:
	return _score

func update_score(amount : int) -> void:
	var old_score : int = _score
	_score = max(_score + amount, 0)
	if _score != old_score:
		score_changed.emit(_score)

func reset_score() -> void:
	_score = 0
	score_changed.emit(_score)
