extends CharacterBody2D
class_name FlippyBird


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal crashed()

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const FRAME_FLAP_UP : int = 0
const FRAME_FLAP_DOWN : int = 1

const MAX_ALTITUDE : float = 104

# ------------------------------------------------------------------------------
# Export Variables
# ------------------------------------------------------------------------------
@export var ai_enabled : bool = false
@export var flap_strength : float = 60.0

# ------------------------------------------------------------------------------
# Onready Variables
# ------------------------------------------------------------------------------
@onready var _sprite: Sprite2D = %Sprite
@onready var _gap_watch: FlippyGapWatch = %GapWatch

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	if _sprite != null:
		_sprite.frame = FRAME_FLAP_UP if velocity.y >= 0.0 else FRAME_FLAP_DOWN

func _physics_process(delta: float) -> void:
	if ai_enabled:
		if position.y >= MAX_ALTITUDE:
			flap()
		elif _gap_watch.has_area():
			if position.y > _gap_watch.get_area_position().y:
				flap()
	var gravity_y : float = get_gravity().y * 0.1
	velocity.y = clamp(velocity.y + (gravity_y * delta), -flap_strength, gravity_y)
	move_and_slide()
	_CheckCollision()

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _CheckCollision() -> void:
	var info : KinematicCollision2D = get_last_slide_collision()
	if info and info.get_collider() != null:
		crashed.emit()

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func flap() -> void:
	velocity.y = -flap_strength
