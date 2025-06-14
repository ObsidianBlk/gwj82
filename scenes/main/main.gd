extends Node


# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _player: CharacterBody3D = %Player


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	GamePool.load_roms()
	GamePool.game_scan()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _player != null:
			_player.active = not _player.active
