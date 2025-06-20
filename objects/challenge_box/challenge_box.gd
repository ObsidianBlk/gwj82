extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const ANIM_CLICKED : StringName = &"clicked"
const ANIM_IDLE : StringName = &"idle"

const EMISSION_ON_ENERGY : float = 1.0
const EMISSION_OFF_ENERGY : float = 0.0

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _initials : String = "AAA"
var _locked : bool = false

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _anim: AnimationPlayer = %Anim
@onready var _ceiling_light_bulb: MeshInstance3D = $Button/ceiling_light_bulb/CeilingLight_Bulb
@onready var _letter_box_01: Node3D = %LetterBox_01
@onready var _letter_box_02: Node3D = %LetterBox_02
@onready var _letter_box_03: Node3D = %LetterBox_03


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Relay.challenge_ended.connect(_on_challenge_ended)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _EmitButtonLight(active : bool) -> void:
	if _ceiling_light_bulb == null: return
	var mat : StandardMaterial3D = _ceiling_light_bulb.get_surface_override_material(0)
	if active:
		mat.emission_energy_multiplier = EMISSION_ON_ENERGY
	else:
		mat.emission_energy_multiplier = EMISSION_OFF_ENERGY

func _UpdateInitials() -> void:
	_initials = "%s%s%s"%[
		_letter_box_01.char,
		_letter_box_02.char,
		_letter_box_03.char
	]

func _Clicked() -> void:
	Relay.challenge(_initials)
	_locked = true

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_challenge_ended() -> void:
	_locked = false

func _on_letterbox_changed(_letter : String) -> void:
	_UpdateInitials()

func _on_button_interactable_interacted(payload: Dictionary) -> void:
	if _anim.current_animation != ANIM_CLICKED and not _locked:
		_EmitButtonLight(false)
		_anim.play(ANIM_CLICKED)

func _on_button_interactable_focused() -> void:
	if not _locked:
		_EmitButtonLight(true)

func _on_button_interactable_unfocused() -> void:
	if not _locked:
		_EmitButtonLight(false)
