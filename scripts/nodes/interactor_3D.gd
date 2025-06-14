extends RayCast3D
class_name Interactor3D


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _interactable : Node3D = null

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _physics_process(_delta: float) -> void:
	var obj : Node3D = get_collider()
	if obj != _interactable:
		if _interactable != null and _interactable.has_user_signal(ComponentInteractable.SIGNAL_UNFOCUSED):
			_interactable.emit_signal(ComponentInteractable.SIGNAL_UNFOCUSED)
		if _IsValidInteractable(obj):
			_interactable = obj
			_interactable.emit_signal(ComponentInteractable.SIGNAL_FOCUSED)
		else: _interactable = null

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _IsValidInteractable(interactable : Node3D) -> bool:
	if interactable == null: return false
	if not interactable.has_user_signal(ComponentInteractable.SIGNAL_FOCUSED):
		return false
	if not interactable.has_user_signal(ComponentInteractable.SIGNAL_UNFOCUSED):
		return false
	if not interactable.has_user_signal(ComponentInteractable.SIGNAL_INTERACTED):
		return false
	return true

# ------------------------------------------------------------------------------
# Public Methods
# ------------------------------------------------------------------------------
func interact(payload : Dictionary = {}) -> void:
	if _interactable and _interactable.has_user_signal(ComponentInteractable.SIGNAL_INTERACTED):
		_interactable.emit_signal(ComponentInteractable.SIGNAL_INTERACTED, payload)
