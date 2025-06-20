extends Node


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const GAME_FOLDER : String = "res://games/"
const GAME_TAG_RESOURCE_BASE_NAME : String = "game"

const ROMS_FOLDER : String = "roms"

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _games : Dictionary[StringName, GameTag] = {}


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _FileExists(filename : String, check_remapped : bool = false) -> bool:
	if not FileAccess.file_exists(filename):
		if check_remapped:
			return FileAccess.file_exists("%s.remap"%[filename])
		return false
	return true

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	for tag : GameTag in _games.values():
		tag.clear()
	_games.clear()

func size() -> int:
	return _games.size()

func get_games_list() -> Array[StringName]:
	return _games.keys()

func has_game(game_name : StringName) -> bool:
	return game_name in _games

func get_game(game_name : StringName) -> GameTag:
	if game_name in _games:
		return _games[game_name]
	return null

func get_game_poster(game_name : StringName) -> Texture2D:
	if game_name in _games:
		return _games[game_name].poster
	return null

func get_game_scoreboard_banner(game_name : StringName) -> Texture2D:
	if game_name in _games:
		return _games[game_name].score_board_banner
	return null

func load_roms_from(base_path : String) -> void:
	if DirAccess.dir_exists_absolute(base_path):
		var files : PackedStringArray = DirAccess.get_files_at(base_path)
		for file : String in files:
			if file.get_extension().to_lower() == "pck":
				if not ProjectSettings.load_resource_pack(base_path.path_join(file)):
					printerr("Failed to load ROM file: ", file)

func load_roms() -> void:
	load_roms_from("./".path_join(ROMS_FOLDER))
	load_roms_from("users://".path_join(ROMS_FOLDER))

func game_scan() -> void:
	if DirAccess.dir_exists_absolute(GAME_FOLDER):
		var folders :PackedStringArray = DirAccess.get_directories_at(GAME_FOLDER)
		for folder : String in folders:
			var base_path : String = GAME_FOLDER.path_join(folder)
			var tag_filename : String = base_path.path_join("%s.%s"%[GAME_TAG_RESOURCE_BASE_NAME, "res"])
			if not _FileExists(tag_filename, true):
				tag_filename = base_path.path_join("%s.%s"%[GAME_TAG_RESOURCE_BASE_NAME, "tres"])
				if not _FileExists(tag_filename, true):
					print("Failed to find game tag resource in ", base_path)
					continue
			var tag : Variant = load(tag_filename)
			if tag is GameTag:
				if not tag.game_name in _games:
					_games[tag.game_name] = tag
