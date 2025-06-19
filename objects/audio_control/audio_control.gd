extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const VOL_STEP : float = 0.05

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var bus : StringName = &""
@export var volume : float = 0.0:			set=set_volume

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _increase_button: CSGBox3D = %IncreaseButton
@onready var _decrease_button: CSGBox3D = %DecreaseButton


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_volume(v : float) -> void:
	volume = clampf(v, 0.0, 1.0)
	_UpdateProgressBar()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateProgressBar() -> void:
	if _progress_bar != null:
		_progress_bar.value = volume * 100.0

func _ChangeEmitEnergy(material : StandardMaterial3D, energy : float) -> void:
	if material.emission_enabled:
		material.emission_energy_multiplier = energy

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_increase_interact_focused() -> void:
	print("Increase Focused")
	if _increase_button != null:
		_ChangeEmitEnergy(_increase_button.material, 1.0)

func _on_increase_interact_unfocused() -> void:
	if _increase_button != null:
		_ChangeEmitEnergy(_increase_button.material, 0.0)

func _on_increase_interact_interacted(payload: Dictionary) -> void:
	print("Increase Interacted")
	volume = clampf(volume + VOL_STEP, 0.0, 1.0)



func _on_decrease_interact_focused() -> void:
	print("Decrease Focused")
	if _decrease_button != null:
		_ChangeEmitEnergy(_decrease_button.material, 1.0)

func _on_decrease_interact_unfocused() -> void:
	if _decrease_button != null:
		_ChangeEmitEnergy(_decrease_button.material, 0.0)

func _on_decrease_interact_interacted(payload: Dictionary) -> void:
	volume = clampf(volume - VOL_STEP, 0.0, 1.0)
