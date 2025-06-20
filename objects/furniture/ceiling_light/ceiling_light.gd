@tool
extends Area3D
class_name CeilingLight


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const MAX_FLICKER_VALUE : float = 100000000

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var color : Color = Color.ANTIQUE_WHITE:				set=set_color
@export_range(0.0, 1.0) var brightness : float = 1.0:			set=set_brightness
@export_range(0.0, 16.0) var light_energy : float = 1.0:		set=set_light_energy
@export_range(0.0, 180.0) var light_angle : float = 50.0:		set=set_light_angle
@export_range(0.0, 16.0) var emission_energy : float = 1.0:		set=set_emission_energy
@export_range(0.0, 1.0) var max_volume : float = 1.0:			set=set_max_volume
@export_range(0.0, 1.0) var max_flicker_intensity : float = 0.0
@export var enable_flicker : bool = false

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _brightness_multiplier : float = 1.0:	set=_set_brightness_multiplier
var _flicker_value : float = 0.0

var _short_flicker_duration : float = 0.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _spot_light: SpotLight3D = %SpotLight
@onready var _ceiling_light_bulb: MeshInstance3D = $ceiling_light_bulb/CeilingLight_Bulb
@onready var _asp: AudioStreamPlayer3D = %ASP

@onready var _noise : FastNoiseLite = FastNoiseLite.new()

# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_brightness(b : float) -> void:
	b = clampf(b, 0.0, 1.0)
	if not is_equal_approx(brightness, b):
		brightness = b
		_UpdateBrightness()

func set_light_energy(e : float) -> void:
	e = clampf(e, 0.0, 16.0)
	if not is_equal_approx(light_energy, e):
		light_energy = e
		_UpdateBrightness()

func set_light_angle(a : float) -> void:
	a = clampf(a, 0.0, 180.0)
	if not is_equal_approx(light_angle, a):
		light_angle = a
		_UpdateBrightness()

func set_emission_energy(e : float) -> void:
	e = clampf(e, 0.0, 16.0)
	if not is_equal_approx(emission_energy, e):
		emission_energy = e
		_UpdateBrightness()

func set_max_volume(v : float) -> void:
	v = clampf(v, 0.0, 1.0)
	if not is_equal_approx(max_volume, v):
		max_volume = v
		_UpdateBrightness()

func set_color(c : Color) -> void:
	if color != c:
		color = c
		_UpdateColor()

func set_enable_flicker(e : bool) -> void:
	if enable_flicker != e:
		enable_flicker = e
		if not enable_flicker:
			# This will reset the brightness when flickering is disabled.
			_UpdateBrightness()

func _set_brightness_multiplier(m : float) -> void:
	m = clampf(m, 0.0, 1.0)
	if not is_equal_approx(_brightness_multiplier, m):
		_brightness_multiplier = m
		if enable_flicker:
			_UpdateBrightness()

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateColor()
	_UpdateBrightness()

func _process(delta: float) -> void:
	if _short_flicker_duration > 0.0:
		_short_flicker_duration -= delta
		if _short_flicker_duration <= 0.0:
			enable_flicker = false

func _physics_process(delta: float) -> void:
	if _noise == null: return
	_flicker_value += 0.9876
	if _flicker_value > MAX_FLICKER_VALUE:
		_flicker_value -= MAX_FLICKER_VALUE
	#var noise : float = ((_noise.get_noise_1d(_flicker_value) + 1.0) * 0.25) + 0.5
	var noise : float = (_noise.get_noise_1d(_flicker_value) + 1.0) * 0.5
	_brightness_multiplier = 1.0 - (noise * max_flicker_intensity)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateColor() -> void:
	if _spot_light != null:
		_spot_light.light_color = color
	if _ceiling_light_bulb != null:
		var mat : StandardMaterial3D = _ceiling_light_bulb.get_surface_override_material(0)
		if mat != null:
			mat.albedo_color = color
			mat.emission = color

func _UpdateBrightness() -> void:
	var multiplier : float = _brightness_multiplier if enable_flicker else 1.0
	if _spot_light != null:
		var energy : float = light_energy * brightness * multiplier
		var angle : float = light_angle * brightness * multiplier
		_spot_light.light_energy = energy
		_spot_light.spot_angle = angle
	if _ceiling_light_bulb != null:
		var mat : StandardMaterial3D = _ceiling_light_bulb.get_surface_override_material(0)
		if mat != null:
			var energy : float = emission_energy * brightness * multiplier
			mat.emission_energy_multiplier = energy
	if _asp != null:
		# Yes, This is not a light object, but it's attenuated same as the brightness,
		# so here it sits!
		var volume = max_volume * brightness * multiplier
		#print("Volume: ", linear_to_db(volume))
		_asp.volume_linear = volume

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func short_flicker(duration : float) -> void:
	if _short_flicker_duration > 0.0: return
	enable_flicker = true
	_short_flicker_duration = duration
