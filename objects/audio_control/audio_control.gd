extends Node3D


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const VOL_STEP : float = 0.05

const SECTION : String = "Volume"

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var bus : StringName = &""
@export_range(0.0, 1.0) var default_volume : float = 1.0:		set=set_default_volume
@export_range(0.0, 1.0) var volume : float = 0.0:				set=set_volume

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _increase_button: CSGBox3D = %IncreaseButton
@onready var _decrease_button: CSGBox3D = %DecreaseButton


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_default_volume(v : float) -> void:
	default_volume = clampf(v, 0.0, 1.0)

func set_volume(v : float) -> void:
	volume = clampf(v, 0.0, 1.0)
	_SetAudioServerVolume()
	_UpdateProgressBar()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	Settings.loaded.connect(_on_settings_loaded)
	Settings.reset.connect(_on_settings_reset)
	Settings.value_changed.connect(_on_settings_value_changed)
	_SetAudioServerVolume()
	_UpdateProgressBar()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _SetAudioServerVolume() -> void:
	var idx : int = AudioServer.get_bus_index(bus)
	if idx >= 0:
		AudioServer.set_bus_volume_linear(idx, volume)

func _UpdateProgressBar() -> void:
	if _progress_bar != null:
		_progress_bar.value = volume * 100.0

func _ChangeEmitEnergy(material : StandardMaterial3D, energy : float) -> void:
	if material.emission_enabled:
		material.emission_energy_multiplier = energy

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
func _on_settings_reset() -> void:
	if bus.is_empty(): return
	Settings.set_value(SECTION, bus, default_volume)

func _on_settings_loaded() -> void:
	if bus.is_empty(): return
	var val : Variant = Settings.get_value(SECTION, bus, default_volume)
	if typeof(val) == TYPE_FLOAT:
		volume = val

func _on_settings_value_changed(section : String, key : String, value : Variant) -> void:
	if bus.is_empty(): return
	if section == SECTION and key == bus:
		if typeof(value) == TYPE_FLOAT:
			volume = value


func _on_increase_interact_focused() -> void:
	if _increase_button != null:
		_ChangeEmitEnergy(_increase_button.material, 1.0)

func _on_increase_interact_unfocused() -> void:
	if _increase_button != null:
		_ChangeEmitEnergy(_increase_button.material, 0.0)

func _on_increase_interact_interacted(payload: Dictionary) -> void:
	if bus.is_empty(): return
	Settings.set_value(SECTION, bus, clampf(volume + VOL_STEP, 0.0, 1.0))



func _on_decrease_interact_focused() -> void:
	if _decrease_button != null:
		_ChangeEmitEnergy(_decrease_button.material, 1.0)

func _on_decrease_interact_unfocused() -> void:
	if _decrease_button != null:
		_ChangeEmitEnergy(_decrease_button.material, 0.0)

func _on_decrease_interact_interacted(payload: Dictionary) -> void:
	if bus.is_empty(): return
	Settings.set_value(SECTION, bus, clampf(volume - VOL_STEP, 0.0, 1.0))
