extends CanvasLayer

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const AUTO_SWITCH_DELAY : float = 30.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _screen_idx : int = 0
var _switch_delay : float = AUTO_SWITCH_DELAY

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _main_container: MarginContainer = %MainContainer
@onready var _screens : Array[Control] = [
	%Screen_Arcade,
	%Screen_Jam,
	%Screen_Info,
]

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_AddPosterScreens()
	for screen : Control in _screens:
		screen.visible = false
	_screens[_screen_idx].visible = true

func _process(delta: float) -> void:
	if _switch_delay > 0.0:
		_switch_delay -= delta
	else:
		switch_next()


# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _AddPosterScreens() -> void:
	if _main_container == null: return
	for game_name : StringName in GamePool.get_games_list():
		var poster : Texture2D = GamePool.get_game_poster(game_name)
		if poster == null: continue
		var tr : TextureRect = TextureRect.new()
		tr.texture = poster
		tr.visible = false
		_screens.append(tr)
		add_child(tr)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func switch_next() -> void:
	if not is_node_ready(): return
	switch_to(wrapi(_screen_idx + 1, 0, _screens.size()))

func switch_to(idx : int) -> void:
	if not is_node_ready(): return
	# TODO: Maybe tween a fade between the two indicies
	if not (idx >= 0 and idx < _screens.size()): return
	if _screen_idx != idx:
		_screens[_screen_idx].visible = false
		_screen_idx = idx
		_screens[_screen_idx].visible = true
	_switch_delay = AUTO_SWITCH_DELAY
