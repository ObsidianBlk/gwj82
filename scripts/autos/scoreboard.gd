extends Node


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SCOREBOARD_FILENAME : String = "user://scoreboard.json"

# ------------------------------------------------------------------------------
# Class
# ------------------------------------------------------------------------------
class ScoreSheet extends RefCounted:
	var game_name : StringName = &"":	set=set_game_name
	var initials : String = "AAA":		set=set_initials
	var score : int = 0:				set=set_score
	
	func set_game_name(gn : StringName) -> void:
		if game_name.is_empty():
			game_name = gn
	
	func set_initials(i : String) -> void:
		if i.length() > 3:
			i = i.substr(0, 3)
		initials = i.to_upper()
	
	func set_score(s : int) -> void:
		if s != score and s > 0:
			score = s

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _scores : Dictionary[StringName, ScoreSheet] = {}


# ------------------------------------------------------------------------------
# Static Private Methods
# ------------------------------------------------------------------------------
func _DictGetValue(d : Dictionary, key : Variant, default : Variant) -> Variant:
	var dtype : int = typeof(default)
	if key in d:
		var vtype : int = typeof(d[key])
		if dtype == TYPE_NIL or dtype == vtype:
			return d[key]
	return default

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	_scores.clear()

func size() -> int:
	return _scores.size()

func get_games() -> Array[StringName]:
	return _scores.keys()

func has_game(game_name : StringName) -> bool:
	return game_name in _scores

func get_score_sheet(game_name : StringName) -> ScoreSheet:
	if game_name in _scores:
		return _scores[game_name]
	return null

func set_score(game_name : StringName, initials : String, score : int) -> void:
	if score <= 0: return
	var score_sheet : ScoreSheet = null
	if game_name in _scores:
		score_sheet = _scores[game_name]
	else:
		score_sheet = ScoreSheet.new()
		score_sheet.game_name = game_name
		_scores[game_name] = score_sheet
	if score > score_sheet.score:
		score_sheet.initials = initials
		score_sheet.score = score

func load_scoreboard() -> void:
	var file : FileAccess = FileAccess.open(SCOREBOARD_FILENAME, FileAccess.READ)
	if file:
		var data : String = file.get_as_text()
		var json : JSON = JSON.new()
		if json.parse(data) == OK:
			if typeof(json.data) == TYPE_DICTIONARY:
				for key : Variant in json.data:
					if typeof(key) != TYPE_STRING: continue
					if typeof(json.data[key]) != TYPE_DICTIONARY: continue
					var initials : String = _DictGetValue(json.data[key], "i", "")
					var score : float = _DictGetValue(json.data[key], "s", 0.0)
					if score >= 1.0 and not initials.is_empty():
						set_score(key, initials, int(score))

func save_scoreboard() -> void:
	var data : Dictionary = {}
	for game_name : StringName in _scores.keys():
		data[String(game_name)] = {
			"i": _scores[game_name].initials,
			"s": _scores[game_name].score
		}
	var jsonstr : String = JSON.stringify(data, " ")
	if jsonstr.is_empty():
		printerr("No scoreboard data")
		return
	
	var file : FileAccess = FileAccess.open(SCOREBOARD_FILENAME, FileAccess.WRITE)
	if not file:
		printerr("Failed to open Scoreboard JSON file for saving.")
		return
	file.store_string(jsonstr)
