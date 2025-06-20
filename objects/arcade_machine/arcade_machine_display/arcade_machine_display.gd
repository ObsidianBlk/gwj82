@tool
extends CanvasLayer


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal static_changed(level : float)


# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
enum Scary {OFF=-1, SCREEN1=0, SCREEN2=1}

const MIN_DURATION : float = 0.2
const MAX_DURATION : float = 0.8

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var off_color : Color = Color.BLACK:				set=set_off_color
@export var scary_screen : Scary = Scary.OFF:				set=set_scary_screen
@export_range(0.0, 1.0) var min_static : float = 0.0:		set=set_min_static
@export_range(0.0, 1.0) var max_static : float = 0.0:		set=set_max_static


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _static_intensity : float = 0.0:		set=_UpdateScreenStatic
var _tween : Tween = null

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _scary_screen_01: AnimatedTextureRect = %ScaryScreen_01
@onready var _scary_screen_02: AnimatedTextureRect = %ScaryScreen_02
@onready var _screen: ColorRect = %Screen


# ------------------------------------------------------------------------------
# Setters
# ------------------------------------------------------------------------------
func set_off_color(c : Color) -> void:
	if off_color != c:
		off_color = c
		_UpdateScreenColor()

func set_scary_screen(ss : Scary) -> void:
	if scary_screen != ss:
		scary_screen = ss
		_UpdateScaryScreen()
		_UpdateScreenColor()

func set_min_static(ms : float) -> void:
	ms = clampf(ms, 0.0, 1.0)
	if not is_equal_approx(min_static, ms):
		min_static = ms
		if max_static < min_static:
			max_static = min_static

func set_max_static(ms : float) -> void:
	ms = clampf(ms, 0.0, 1.0)
	if not is_equal_approx(max_static, ms):
		max_static = ms
		if min_static > max_static:
			min_static = max_static

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_UpdateScreenColor()
	_UpdateScaryScreen()

func _process(delta: float) -> void:
	if _tween != null: return
	_TweenIntensity()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _UpdateScreenStatic(amount : float) -> void:
	_static_intensity = clampf(amount, 0.0, 1.0)
	static_changed.emit(_static_intensity)
	if _screen != null:
		_screen.material.set_shader_parameter(&"static_alpha", _static_intensity)

func _UpdateScreenColor() -> void:
	var color : Color = off_color
	if not scary_screen == Scary.OFF:
		color.a = 0.0
	
	if _screen != null:
		_screen.material.set_shader_parameter(
			&"primary_color", color
		)

func _UpdateScaryScreen() -> void:
	if _scary_screen_01 == null or _scary_screen_02 == null: return
	_scary_screen_01.visible = scary_screen == Scary.SCREEN1
	_scary_screen_02.visible = scary_screen == Scary.SCREEN2

func _TweenIntensity() -> void:
	if _tween != null: return
	if is_equal_approx(min_static, max_static):
		if not is_equal_approx(_static_intensity, min_static):
			_static_intensity = min_static
		return
	
	var duration : float = randf_range(MIN_DURATION, MAX_DURATION)
	var target_intensity : float = randf_range(min_static, max_static)
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "_static_intensity", target_intensity, duration)
	await _tween.finished
	_tween = null

# ------------------------------------------------------------------------------
# Handler Methods
# ------------------------------------------------------------------------------
