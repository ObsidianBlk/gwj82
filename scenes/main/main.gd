extends Node

@onready var _player: CharacterBody3D = %Player

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _player != null:
			_player.active = not _player.active
