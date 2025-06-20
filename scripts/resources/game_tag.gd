extends Resource
class_name GameTag


# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var game_name : StringName = "":						set=set_game_name
@export_file("*.scn", "*.tscn") var game_path : String = "":	set=set_game_path
@export var poster : Texture2D = null
@export var score_board_banner : Texture2D = null

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _node_instance : ArcadeGame = null


# ------------------------------------------------------------------------------
# Setters / Getters
# ------------------------------------------------------------------------------
func set_game_name(gn : StringName) -> void:
	if game_name != gn:
		game_name = gn
		changed.emit()

func set_game_path(gp : String) -> void:
	if game_path != gp:
		game_path = gp
		_node_instance = null
		changed.emit()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func clear() -> void:
	if _node_instance != null:
		_node_instance.queue_free()
		_node_instance = null

func instance() -> ArcadeGame:
	if _node_instance == null and not game_path.is_empty():
		var scene : Variant = load(game_path)
		if scene is PackedScene:
			var node : Node = scene.instantiate()
			if node is ArcadeGame:
				_node_instance = node
	return _node_instance
