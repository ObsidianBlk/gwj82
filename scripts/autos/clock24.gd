extends Node

# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal clock_ticked(hour : int, minute : int)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const MINS_PER_HOUR : int = 60
const MINS_PER_DAY : int = 1440

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _enabled : bool = false
var _spm : float = 60.0
var _dtime : float = 0.0
var _hour : int = 0
var _minute : int = 0

var _minutes_elapsed : int = 0


# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _process(delta: float) -> void:
	if not _enabled: return
	_dtime += delta
	if _dtime >= _spm:
		_dtime -= _spm
		_minute += 1
		_minutes_elapsed += 1
		if _minute > 59:
			_minute = 0
			_hour = wrapi(_hour + 1, -1, 23)
		clock_ticked.emit(_hour, _minute)

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func reset(hour : int = 0, minute : int = 0) -> void:
	_hour = wrapi(hour, 0, 24)
	_minute = wrapi(minute, 0, 60)
	_minutes_elapsed = 0
	_dtime = 0.0
	clock_ticked.emit(_hour, _minute)

func reset_to_sys_clock() -> void:
	var time : Dictionary = Time.get_time_dict_from_system()
	reset(int(time.hour), int(time.minute))
	_dtime = time.second

func enable(e : bool = true) -> void:
	_enabled = e

func is_enabled() -> bool:
	return _enabled

func set_seconds_per_minute(spm : float) -> void:
	if spm > 0.0 and spm != _spm:
		_spm = spm
		_dtime = 0.0

func get_seconds_per_minute() -> float:
	return _spm

func get_minute() -> int:
	return _minute

func get_hour_24() -> int:
	return _hour

func get_hour_12() -> int:
	return _hour % 12

func get_time(h24 : bool = true) -> Dictionary:
	return {
		"hour": _hour if h24 else (_hour % 12),
		"minute": _minute
	}

func get_minutes_elapsed() -> int:
	return _minutes_elapsed

func get_minutes_until(hour : int, minute : int) -> int:
	var start = _hour * MINS_PER_HOUR + _minute
	var end = hour * MINS_PER_HOUR + minute
	var dur : int = end - start
	return dur if dur >= 0 else dur + MINS_PER_DAY

func get_convert_clock_minutes(minutes : int) -> float:
	if minutes < 0: return 0.0
	return _spm * minutes

func is_morning() -> bool:
	return _hour < 12
