extends Node
class_name ComponentInteractable


# ------------------------------------------------------------------------------
# Signals
# ------------------------------------------------------------------------------
signal focused()
signal unfocused()
signal interacted(payload : Dictionary)

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
const SIGNAL_FOCUSED : StringName = &"interactable_focused"
const SIGNAL_UNFOCUSED : StringName = &"interactable_unfocused"
const SIGNAL_INTERACTED : StringName = &"interactable_interacted"


# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
var _parent : Node = null

# ------------------------------------------------------------------------------
# Override Methods
# ------------------------------------------------------------------------------
func _ready() -> void:
	_parent = get_parent()
	if _parent != null:
		if _parent.is_node_ready():
			_ConnectToParent()
		else:
			_parent.ready.connect(_ConnectToParent, CONNECT_ONE_SHOT)

# ------------------------------------------------------------------------------
# Private Methods
# ------------------------------------------------------------------------------
func _AddUserSignal(parent: Node3D, sig_name : StringName, handler : Callable) -> void:
	if not parent.has_user_signal(sig_name):
		parent.add_user_signal(sig_name)
		parent.connect(sig_name, handler)

func _ConnectToParent() -> void:
	if _parent == null: return
	_AddUserSignal(_parent, SIGNAL_FOCUSED, _handle_focus)
	_AddUserSignal(_parent, SIGNAL_UNFOCUSED, _handle_unfocus)
	_AddUserSignal(_parent, SIGNAL_INTERACTED, _handle_interacted)

func _handle_focus() -> void:
	focused.emit()

func _handle_unfocus() -> void:
	unfocused.emit()

func _handle_interacted(payload : Dictionary = {}) -> void:
	interacted.emit(payload)
