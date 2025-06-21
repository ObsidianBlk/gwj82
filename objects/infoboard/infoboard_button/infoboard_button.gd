extends Node3D



# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal clicked()


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const EMISSION_OFF_ENERGY : float = 0.1
const EMISSION_ON_ENERGY : float = 1.0

const ANIM_CLICK : StringName = &"click"

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _info_board_button: MeshInstance3D = $infoboard_button/InfoBoard_Button
@onready var _asp_click: AudioStreamPlayer3D = %ASP_Click
@onready var _anim: AnimationPlayer = %Anim


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateEmission(EMISSION_OFF_ENERGY)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateEmission(energy : float) -> void:
	if _info_board_button == null: return
	var mat : Material = _info_board_button.get_surface_override_material(1)
	if mat is StandardMaterial3D:
		mat.emission_energy_multiplier = energy

func _Clicked() -> void:
	_asp_click.play()
	clicked.emit()

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_component_interactable_interacted(payload: Dictionary) -> void:
	if _anim.current_animation != ANIM_CLICK:
		_anim.play(ANIM_CLICK)

func _on_component_interactable_focused() -> void:
	_UpdateEmission(EMISSION_ON_ENERGY)

func _on_component_interactable_unfocused() -> void:
	_UpdateEmission(EMISSION_OFF_ENERGY)
